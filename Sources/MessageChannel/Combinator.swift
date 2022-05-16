import Foundation

/// An object tha resend the message, which is received by it's receiver, to hold channel
public struct Combinator {
    private let channel: MessageDispatchChannel
    public let receiver: AnyReceiver

    public init<M: Message>(
        wrappedValue: MessageReceiver<M>,
        channel: MessageDispatchChannel
    ) {
        self.channel = channel
        self.receiver = .init(
            wrappedValue: .init { (message: M) in
                channel.send(message)
            }
        )
    }
}

extension Combinator: Hashable {}
