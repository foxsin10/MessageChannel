import SwiftUI
import struct OrderedCollections.OrderedDictionary

public final class MessageDispatchChannel {
    private var receiverMap = OrderedDictionary<String, Messager>()

    public lazy private(set) var identifier = ObjectIdentifier(self)

    public init() {}

    /// Receivers registerd in channel
    public var receivers: [AnyReceiver] {
        receiverMap.values.map { $0.messager }
    }

    /// Register an `AnyReceiver` in channel
    /// - Parameter receiver: an `AnyReceiver` instance will be registered in channel
    public func register(_ receiver: Messager) {
        receiverMap[receiver.receiverIdentifier] = receiver
        receiver.registerFinish()
    }

    public func removeAll() {
        receiverMap.removeAll()
    }

    public func removeValue(for key: String) {
        receiverMap.removeValue(forKey: key)
    }

    public func send<M: Message>(_ messge: M) {
        for (_, receiver) in receiverMap {
            receiver.receive(messge)
        }
    }
}

extension MessageDispatchChannel: Hashable {
    public static func == (lhs: MessageDispatchChannel, rhs: MessageDispatchChannel) -> Bool {
        lhs.identifier == rhs.identifier
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
}

extension MessageDispatchChannel {
    public func remove(_ receiver: AnyReceiver) {
        removeValue(for: receiver.receiverIdentifier)
    }
}

fileprivate struct MessageChannelKey: EnvironmentKey {
    static var defaultValue = MessageDispatchChannel()
}

extension EnvironmentValues {
    public var messageChannel: MessageDispatchChannel { self[MessageChannelKey.self] }
}
