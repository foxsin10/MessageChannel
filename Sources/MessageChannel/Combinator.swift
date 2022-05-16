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

    public func register(_ receiver: Messager) {
        channel.register(receiver)
    }

    public func removeAll() {
        channel.removeAll()
    }

    public func removeValue(for key: String) {
        channel.removeValue(for: key)
    }

    public func remove(_ receiver: AnyReceiver) {
        channel.remove(receiver)
    }
}

extension Combinator: Hashable {}
