public enum Messager {
    case receiver(AnyReceiver)
    case combinator(Combinator)

    public var messager: AnyReceiver {
        switch self {
        case .receiver(let anyReceiver): return anyReceiver
        case .combinator(let combinator): return combinator.receiver
        }
    }

    public var receiverIdentifier: String {
        switch self {
        case .receiver(let anyReceiver): return anyReceiver.receiverIdentifier
        case .combinator(let combinator): return combinator.receiver.receiverIdentifier
        }
    }

    public func registerFinish() {
        switch self {
        case .receiver(let anyReceiver):
            anyReceiver.registerFinish()

        case .combinator(let combinator):
            combinator.receiver.registerFinish()
        }
    }

    public func receive<M: Message>(_ message: M) {
        switch self {
        case .receiver(let anyReceiver):
            anyReceiver.receive(message)

        case .combinator(let combinator):
            combinator.receiver.receive(message)
        }
    }
}

extension Messager: Hashable {}
