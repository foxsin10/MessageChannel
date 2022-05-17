/// A protocol witness class for `Value`
public final class MessageReceiver<Value> {
    /// Callback when receive value
    public private(set) var onReceive: (Value) -> Void

    /// Identifier
    public lazy private(set) var identifier = ObjectIdentifier(self)

    public init(onReceive: @escaping (Value) -> Void = { _ in }) {
        self.onReceive = onReceive
    }

    /// Register flag.
    ///
    /// After register, receiver can receive message.
    public private(set) var canReceiveMessage: Bool = false

    /// Update `canReceiveMessage`
    ///
    /// will be called after register finish
    public func registerFinish() {
        canReceiveMessage = true
    }

    @inlinable
    public func reserve<B>(_ f: @escaping (B) -> Value?) -> MessageReceiver<B> {
        MessageReceiver<B>.init { b in
            guard let value = f(b) else {
                return
            }
            self.onReceive(value)
        }
    }
}

extension MessageReceiver where Value: Message {
    /// The Identifier will be used for register key
    public var registerKey: String {
        "\(Value.identifyKey)-\(identifier)"
    }

    public func dispatch(to channel: MessageDispatchChannel, hook: @escaping (Value) -> Void = { _ in }) {
        self.onReceive = { message in
            hook(message)
            channel.send(message)
        }
    }
}

extension MessageReceiver: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }

    public static func == (lhs: MessageReceiver, rhs: MessageReceiver) -> Bool {
        lhs.identifier == rhs.identifier
    }
}

public extension MessageReceiver where Value: Message {
    /// Return an AnyReceiver
    /// - Parameter channel: the channel AnyReceiver will be registered in
    /// - Returns: AnyReceiver
    @inlinable
    func eraseToAnyReceiver(
        in channel: MessageDispatchChannel? = nil,
        autoRegister: Bool = false
    ) -> AnyReceiver {
        AnyReceiver(self, autoRegister: autoRegister, channel: channel)
    }
}


/// This is not a thread safe type, we should only use this class on the same thread or actor
/// A propertyWrapper that erase the receiver type
@propertyWrapper
public struct AnyReceiver {
    public var wrappedValue: AnyObject { receiver }
    public var projectedValue: AnyReceiver { self }

    /// Identifier from MessageReceiver<M>
    public let receiverIdentifier: String

    private let receiver: AnyObject
    private let channel: MessageDispatchChannel

    private(set) var registerFinish: () -> Void

    public init<M: Message>(
        wrappedValue: MessageReceiver<M>,
        autoRegister: Bool = true,
        receiverChannel: MessageDispatchChannel? = nil
    ) {
        self.receiver = wrappedValue
        self.receiverIdentifier = wrappedValue.registerKey
        self.registerFinish = { [weak wrappedValue] in
            wrappedValue?.registerFinish()
        }

        self.channel = {
            if let channel = receiverChannel {
                return channel
            } else {
                @Environment(\.messageChannel)
                var channel
                return channel
            }
        }()

        if autoRegister {
            self.channel.register(.receiver(self))
        }
    }

    @discardableResult
    public func reserve<B: Message, V: Message>(_ f: @escaping (B) -> V?) -> AnyReceiver {
        AnyReceiver(
            wrappedValue: MessageReceiver<B> { b in
                guard let v = f(b) else {
                    return
                }
                (self.receiver as? MessageReceiver<V>)?.onReceive(v)
            },
            autoRegister: false,
            receiverChannel: self.channel
        )
    }

    public func register() {
        channel.register(.receiver(self))
    }

    /// Remove from MessageChannel
    public func removeFromChannel() {
        channel.remove(self)
    }

    func receive<M: Message>(_ message: M) {
        // As receiverIdentifier equals to MessageReceiver's registerKey,
        // if receiverIdentifier contains M.identifyKey, it means receiver is an instance of MessageReceiver<M>
        // otherwise we can just return
        guard receiverIdentifier.contains(M.identifyKey) else {
            return
        }

        let consumer = unsafeBitCast(receiver, to: MessageReceiver<M>.self)
        // if the consumer is already registered, receive message
        // otherwise just return
        guard consumer.canReceiveMessage else {
            return
        }
        consumer.onReceive(message)
    }
}

public extension AnyReceiver {
    @inlinable
    init<M: Message>(
        _ wrappedValue: MessageReceiver<M>,
        autoRegister: Bool = false,
        channel: MessageDispatchChannel? = nil
    ) {
        self.init(wrappedValue: wrappedValue, autoRegister: autoRegister, receiverChannel: channel)
    }
}

extension AnyReceiver: Hashable {
    public static func == (lhs: AnyReceiver, rhs: AnyReceiver) -> Bool {
        lhs.receiverIdentifier == rhs.receiverIdentifier &&
        lhs.channel == rhs.channel
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(receiverIdentifier)
        hasher.combine(channel.identifier)
    }
}
