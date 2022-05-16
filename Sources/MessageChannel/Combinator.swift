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

    public func register(to channel: MessageDispatchChannel) {
        guard channel != self.channel else {
            runtimeWarning("should not register to self hold channel")
            return
        }
        channel.register(.combinator(self))
    }

    public func removeAll() {
        channel.removeAll()
    }

    public func removeValue(for key: String) {
        channel.removeValue(for: key)
    }

    public func remove(_ messager: Messager) {
        channel.removeValue(for: messager.receiverIdentifier)
    }
}

extension Combinator: Hashable {}
