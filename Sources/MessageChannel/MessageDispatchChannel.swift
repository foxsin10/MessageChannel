import struct OrderedCollections.OrderedDictionary

public final class MessageDispatchChannel {
    public enum Mode {
        case dispatching
        case relaying
    }

    fileprivate var receiverMap = OrderedDictionary<String, Messager>()

    public lazy private(set) var identifier = ObjectIdentifier(self)

    public private(set) var tracing: Traceable

    public private(set) var mode: Mode

    public init(
        mode: Mode = .dispatching,
        traing: any Traceable = SimpleTracing()
    ) {
        self.tracing = traing
        self.mode = mode

        // make lazy storge be initialized
        #if Tracing
        _ = identifier
        #endif
    }

    /// Receivers registerd in channel
    public var receivers: [AnyReceiver] {
        receiverMap.values.map { $0.messager }
    }

    /// Register an `AnyReceiver` in channel
    /// - Parameter receiver: an `AnyReceiver` instance will be registered in channel
    func register(_ receiver: Messager) {
        receiverMap[receiver.receiverIdentifier] = receiver
        receiver.registerFinish()
    }

    public func removeAll() {
        receiverMap.removeAll()
    }

    public func removeValue(for key: String) {
        receiverMap.removeValue(forKey: key)
    }

    public func replace(_ tracing: any Traceable) {
        self.tracing = tracing
    }

    public func send<M: Message>(
        _ messge: M,
        _ file: StaticString = #file,
        _ line: Int = #line
    ) {
        tracing.record(message: messge, from: self, file, line)
        for (_, receiver) in receiverMap {
            receiver.receive(messge)
        }
    }
}

extension MessageDispatchChannel: Hashable {
    public static func == (lhs: MessageDispatchChannel, rhs: MessageDispatchChannel) -> Bool {
        lhs.identifier == rhs.identifier
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
}

extension MessageDispatchChannel {
    /// To identify the channel is dispatching or relaying
    func ensureRelaying() {
        mode = .relaying
    }

    public func remove(_ receiver: Messager) {
        removeValue(for: receiver.receiverIdentifier)
    }

    public func remove(_ receiver: AnyReceiver) {
        removeValue(for: receiver.receiverIdentifier)
    }

    public func remove(_ combinator: Combinator) {
        removeValue(for: combinator.receiver.receiverIdentifier)
    }

    public func contains(_ element: Messager) -> Bool {
        receiverMap.keys.contains(element.receiverIdentifier)
    }

    public func contains(_ element: Combinator) -> Bool {
        contains(element.receiver)
    }

    public func contains(_ element: AnyReceiver) -> Bool {
        receiverMap.keys.contains(element.receiverIdentifier)
    }
}

extension MessageDispatchChannel {
    #if Tracing
    var channelMap: String {
        var content = ""

        content.write("channel id: \(identifier)".inserIndent(by: 4))
        content.write("\n")
        for value in self.receiverMap.values {
            switch value {
            case let .receiver(receiver):
                content.write(
                    "receiver: \(receiver.receiverIdentifier)"
                        .inserIndent(by: 4)
                )

            case let .combinator(combinator):
                content.write(
                    "combinator: [channel: \(combinator.channelIdentifier), receiver: \(combinator.receiver.receiverIdentifier)]"
                        .inserIndent(by: 4)
                )
            }
            content.write("\n")
        }

        return content
    }
    #endif
}

fileprivate struct MessageChannelKey: EnvironmentKey {
    static var defaultValue = MessageDispatchChannel()
}

extension EnvironmentValues {
    public var messageChannel: MessageDispatchChannel { self[MessageChannelKey.self] }
}
