import XCTest
@testable import MessageChannel
import SwiftUI

final class MessageChannelTests: XCTestCase {
    enum A: Message {
        case ping
        case pong
    }

    enum B: Message {
        case hello
        case goodbye
    }

    enum C: Message {
        case carry
    }

    func testExample() throws {
        @Environment(\.messageChannel)
        var channel

        var textMessage: String = ""
        XCTAssert(channel.receivers.isEmpty)

        // propertywrapper use auto register on default
        @AnyReceiver
        var messager = MessageReceiver<A> { message in
            print("propertyWrapper receive:", message)
            textMessage = message.plainText
        }

        channel.send(A.pong)

        XCTAssert(channel.receivers.count == 1)
        XCTAssert(textMessage == A.pong.plainText)

        channel.remove($messager)
        XCTAssert(channel.receivers.isEmpty)

        // C -> B -> A
        $messager
            .pullback { (m: B) -> A? in
                switch m {
                case .goodbye: return .ping
                case .hello: return .pong
                }
            }
            .pullback { (m: C) -> B? in
                switch m {
                case .carry: return .goodbye
                }
            }
            .register()

        channel.send(C.carry)
        XCTAssert(textMessage == A.ping.plainText)

        // convenience initializer don't use autoregister on default
        MessageReceiver<B> { message in
            print("mess receive:", message.plainText)
        }
        .eraseToAnyReceiver()
        .register()
        channel.send(B.goodbye)
    }

    func testDellocatingGraph() {
        func testGraph() {
            let graph = MessageChannelGraph()
            graph.channel.send(B.goodbye)

            XCTAssert(graphMessage?.plainText == B.goodbye.plainText)
        }

        testGraph()
    }

    func testDellocatingNode() {
        func testGraph() {
            let graph = MessageChannelNode()
            graph.channel.send(B.goodbye)

            XCTAssert(nodeMessage?.plainText == B.goodbye.plainText)
        }

        testGraph()
    }
}

var graphMessage: MessageChannelTests.B?
final class MessageChannelGraph {
    typealias B = MessageChannelTests.B

    @AnyReceiver
    var messager: AnyObject

    @Environment(\.messageChannel)
    var channel

    init() {
        _messager = .init(wrappedValue: MessageReceiver<B> {
            graphMessage = $0
        })
    }
    
    deinit { $messager.removeFromChannel() }
}

var nodeMessage: MessageChannelTests.B?
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
