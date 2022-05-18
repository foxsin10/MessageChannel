@propertyWrapper
public struct Receiving<M: Message> {
    public var wrappedValue: M? { sender.value }
    public var projectedValue: Receiving<M> { self }

    private let sender: CurrentValueSubject<M?, Never>
    public let receiver: AnyReceiver

    public var publisher: AnyPublisher<M, Never> {
        sender
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }

    public init(
        wrappedValue: M? = nil,
        in channel: MessageDispatchChannel? = nil
    ) {
        let sender = CurrentValueSubject<M?, Never>(nil)
        let receiver = MessageReceiver<M> { [sender] in sender.send($0) }
            .eraseToAnyReceiver(in: channel, autoRegister: true)

        self.sender = sender
        self.receiver = receiver
    }
}
