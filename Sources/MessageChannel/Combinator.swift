/// An object tha resend the message, which is received by it's receiver, to hold channel
@propertyWrapper
public struct Combinator {
    public var wrappedValue: AnyReceiver { receiver }
    public var projectedValue: Combinator { self }

    private let channel: MessageDispatchChannel
    public let receiver: AnyReceiver

    /// Combinator initializer
    /// - Parameters:
    ///   - wrappedValue: messager
    ///   - receiverChannel: the channel from which messager receive message.
    ///   this can not equals to dispatchChannel
    ///   - dispatchChannel: the channel messager re-dispatch message to
    public init<M: Message>(
        wrappedValue: MessageReceiver<M>,
        hook: @escaping (M) -> Void = { _ in },
        dispatchingIn dispatchChannel: MessageDispatchChannel,
        receivingIn receiverChannel: MessageDispatchChannel? = nil
    ) {
        // if receiverChannel == dispatchChannel will cause function call overflow
        // so we just do assert
        assert(receiverChannel != dispatchChannel, "Dispatch and receive message in the same channel")
        wrappedValue.dispatch(to: dispatchChannel, hook: hook)
        self.receiver = AnyReceiver(wrappedValue, autoRegister: true, channel: receiverChannel)
        self.channel = dispatchChannel
    }

    public func register() {
        receiver.register()
    }

    public func removeAll() {
        channel.removeAll()
    }

    public func removeFromReceivingChannel() {
        receiver.removeFromChannel()
    }

    public func removeValue(for key: String) {
        channel.removeValue(for: key)
    }

    public func remove(_ messager: Messager) {
        channel.removeValue(for: messager.receiverIdentifier)
    }

    public func send<M: Message>(_ message: M) {
        channel.send(message)
    }
}

extension Combinator: Hashable {}
