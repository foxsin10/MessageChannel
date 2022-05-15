import SwiftUI
import struct OrderedCollections.OrderedDictionary

public final class MessageChannel {
    private var receiverMap = OrderedDictionary<String, AnyReceiver>()

    /// Receivers registerd in channel
    public var receivers: [AnyReceiver] {
        receiverMap.values.map { $0 }
    }

    /// Register an `AnyReceiver` in channel
    /// - Parameter receiver: an `AnyReceiver` instance will be registered in channel
    public func register(_ receiver: AnyReceiver) {
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

extension MessageChannel {
    public func remove(_ receiver: AnyReceiver) {
        removeValue(for: receiver.receiverIdentifier)
    }
}

fileprivate struct MessageChannelKey: EnvironmentKey {
    static var defaultValue = MessageChannel()
}

extension EnvironmentValues {
    public var messageChannel: MessageChannel { self[MessageChannelKey.self] }
}
