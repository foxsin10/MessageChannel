@propertyWrapper
public struct Relaying<M: Message> {
    private let sender: CurrentValueSubject<M?, Never>
    public let combinator: Combinator

    public var wrappedValue: M? { sender.value }
    public var projectedValue: Relaying<M> { self }

    public var publisher: AnyPublisher<M, Never> {
        sender.compactMap { $0 }
            .eraseToAnyPublisher()
    }

    public init(
        wrappdeValue: M,
        receivingingIn receivingChannel: MessageDispatchChannel? = nil,
        relayingIn relayingChannel: MessageDispatchChannel
    ) {

        let sender = CurrentValueSubject<M?, Never>(nil)
        let combinator = Combinator(
            wrappedValue: MessageReceiver<M>(),
            hook: { [sender] message in
                sender.send(message)
            },
            dispatchingIn: relayingChannel,
            receivingIn: receivingChannel
        )

        self.combinator = combinator
        self.sender = sender
    }
}
