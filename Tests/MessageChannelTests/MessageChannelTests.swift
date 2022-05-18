import XCTest
@testable import MessageChannel

import Combine
import SwiftUI

fileprivate var graphMessage: MessageChannelTests.B?
fileprivate var nodeMessage: MessageChannelTests.B?

final class MessageChannelTests: XCTestCase {
    enum A: Message {
        case ping
        case pong
    }

    enum B: Message {
        case hello
        case goodbye
        case fear
    }

    enum C: Message {
        case carry
    }

    func testAnyReceiver() throws {
        func releaseAfterTest() {
            var channel: MessageDispatchChannel? = MessageDispatchChannel()
            channel?.tracing.enable()

            var textMessage: String = ""
            XCTAssert(channel?.receivers.isEmpty ?? false)

            // propertywrapper use auto register on default
            let messager = MessageReceiver<A> { message in

                textMessage = message.plainText
            }
            .eraseToAnyReceiver(in: channel!)
            .register()

            channel?.send(A.pong)

            XCTAssert(channel?.receivers.count == 1)
            XCTAssert(textMessage == A.pong.plainText)

            channel?.remove(messager)
            XCTAssert(channel?.receivers.isEmpty ?? false)

            // C -> B -> A
            // here we register a new AnyReceiver into channel
            messager
                .reserve { (m: B) -> A? in
                    switch m {
                    case .goodbye: return .ping
                    case .hello: return .pong
                    default: return nil
                    }
                }
                .reserve { (m: C) -> B? in
                    switch m {
                    case .carry: return .goodbye
                    }
                }
                .register()

            channel?.send(C.carry)
            XCTAssert(textMessage == A.ping.plainText)

            // convenience initializer don't use autoregister on default
            MessageReceiver<B> { message in

            }
            .eraseToAnyReceiver(in: channel)
            .register()
            
            channel?.send(B.goodbye)
            channel?.removeAll()
            channel = nil
        }

        releaseAfterTest()
    }

    func testChannel() throws {
        defer { graphMessage = nil }
        final class MessageChannelGraph {
            typealias B = MessageChannelTests.B

            var messager: AnyReceiver

            init() {
                messager = AnyReceiver(wrappedValue: MessageReceiver<B> {
                    graphMessage = $0
                })
            }

            deinit { messager.removeFromChannel() }
        }

        func run() {
            @Environment(\.messageChannel)
            var channel

            let graph = MessageChannelGraph()
            _ = graph.messager.receiverIdentifier
            channel.send(B.goodbye)

            XCTAssert(graphMessage?.plainText == B.goodbye.plainText)
        }

        run()
    }

    func testDellocatingNode() throws {
        @Environment(\.messageChannel)
        var channel

        let receivers = channel.receivers.count
        defer { nodeMessage = nil }
        final class MessageChannelNode {
            typealias B = MessageChannelTests.B
            var messager: MessageReceiver<B>

            @Environment(\.messageChannel)
            var channel

            init() {
                messager = MessageReceiver<B> { nodeMessage = $0 }
                messager
                    .eraseToAnyReceiver()
                    .register()
            }

            deinit { channel.removeValue(for: messager.registerKey) }
        }

        func testGraph() {
            let graph = MessageChannelNode()
            graph.channel.send(B.goodbye)

            XCTAssert(nodeMessage?.plainText == B.goodbye.plainText)
        }

        testGraph()
        XCTAssert(receivers == channel.receivers.count)
    }

    func testReceiving() throws {
        @Environment(\.messageChannel)
        var channel;
        let count = channel.receivers.count
        var storage: Set<AnyCancellable> = []

        @Receiving(in: channel)
        var message: B?

        var receiveMessage: B?
        $message
            .publisher
            .sink { m in
                receiveMessage = m
            }
            .store(in: &storage)

        channel.send(B.hello)
        XCTAssert(channel.receivers.isEmpty == false)

        $message.receiver.removeFromChannel()

        XCTAssert(receiveMessage?.plainText == B.hello.plainText)
        XCTAssert(count == channel.receivers.count)
    }

    func testRelaying() throws {
        var storage: Set<AnyCancellable> = []
        @Environment(\.messageChannel)
        var messageChannel;

        // enable/disable traing log
        messageChannel.tracing.enable();defer { messageChannel.tracing.disable() }

        let channel = MessageDispatchChannel()
        channel.tracing.enable()

        XCTAssert(messageChannel.receivers.isEmpty)
        XCTAssert(channel.receivers.isEmpty)

        @Relaying(relayingIn: channel)
        var relayMessage: B?

        XCTAssert(messageChannel.receivers.count == 1)
        XCTAssert(messageChannel.contains($relayMessage.combinator))

        var testMessage: B?
        MessageReceiver<B> { message in
            testMessage = message
        }
        .reserve { (m: A) -> B? in
            switch m {
            case .ping: return B.hello
            case .pong: return .goodbye
            }
        }
        .eraseToAnyReceiver(in: channel)
        .register()

        var receivingMessage: B?
        @Receiving(in: channel)
        var receiveMessage: B?

        $receiveMessage
            .publisher
            .sink { message in
                receivingMessage = message
            }
            .store(in: &storage)

        messageChannel.send(B.goodbye)
        XCTAssert(testMessage?.plainText != B.goodbye.plainText)
        XCTAssert(receivingMessage?.plainText == B.goodbye.plainText)

        channel.send(A.pong)
        XCTAssert(testMessage?.plainText == B.goodbye.plainText)
        XCTAssert(receivingMessage?.plainText == B.goodbye.plainText)

        $relayMessage.send(B.fear)
        XCTAssert(testMessage?.plainText != B.fear.plainText)
        XCTAssert(receivingMessage?.plainText == B.fear.plainText)

        let ex = expectation(description: "dump")
        // for dump tracing log
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            ex.fulfill()
        }
        wait(for: [ex], timeout: 30)
    }
}
