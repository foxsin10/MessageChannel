@propertyWrapper
public struct Receiving<M: Message> {
    public var wrappedValue: M? { messageSender.value }
    public var projectedValue: Receiving<M> { self }

    private let messageSender: CurrentValueSubject<M?, Never>
    public let receiver: AnyReceiver

    public var publisher: AnyPublisher<M, Never> {
        messageSender
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }

    public init(
        wrappedValue: M? = nil,
        in channel: MessageDispatchChannel? = nil
    ) {
        let sender = CurrentValueSubject<M?, Never>(wrappedValue)
        let receiver = MessageReceiver<M> { [sender] in sender.send($0) }
            .eraseToAnyReceiver(in: channel, autoRegister: true)

        self.messageSender = sender
        self.receiver = receiver
    }
}
