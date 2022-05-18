import SwiftUI
/// An object tha resend the message, which is received by it's receiver, to hold channel
public struct Combinator {
    private let channel: MessageDispatchChannel
    public let receiver: AnyReceiver

    /// Combinator initializer
    /// - Parameters:
    ///   - wrappedValue: messager
    ///   - receiverChannel: the channel from which messager receive message.
    ///   this can not equals to dispatchChannel
    ///   - dispatchChannel: the channel messager re-dispatch message to
    public init<M: Message>(
        _ wrappedValue: MessageReceiver<M> = .init(),
        hook: @escaping (M) -> Void = { _ in },
        dispatchingIn dispatchChannel: MessageDispatchChannel,
        receivingIn receiverChannel: MessageDispatchChannel? = nil
    ) {
        // if receiverChannel == dispatchChannel will cause function call overflow
        // so we just do assert
        assert(receiverChannel != dispatchChannel, "Dispatch and receive message in the same channel")
        wrappedValue.hookOnReceive {
            dispatchChannel.send($0)
        }
        
        receiver = wrappedValue
            .eraseToAnyReceiver(in: receiverChannel, autoRegister: false)

        channel = dispatchChannel
        channel.ensureRelaying()

        let registerChannel: MessageDispatchChannel = {
            @Environment(\.messageChannel)
            var globalChannel;
            return receiverChannel ?? globalChannel
        }()
        registerChannel.register(.combinator(self))
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

    public func send<M: Message>(
        _ message: M,
        _ file: StaticString = #file,
        _ line: Int = #line
    ) {
        channel.send(message, file, line)
    }
}

extension Combinator: Hashable {}
