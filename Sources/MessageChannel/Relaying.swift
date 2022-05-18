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
        wrappdeValue: M? = nil,
        receivingingIn receivingChannel: MessageDispatchChannel? = nil,
        relayingIn relayingChannel: MessageDispatchChannel
    ) {

        let sender = CurrentValueSubject<M?, Never>(nil)
        let combinator = Combinator(
            MessageReceiver<M>(),
            hook: { [sender] message in
                sender.send(message)
            },
            dispatchingIn: relayingChannel,
            receivingIn: receivingChannel
        )

        self.combinator = combinator
        self.sender = sender
    }

    public func send(
        _ message: M,
        _ file: StaticString = #file,
        _ line: Int = #line
    ) {
        combinator.send(message, file, line)
    }
}
