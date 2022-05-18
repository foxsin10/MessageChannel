import CustomDump
import Foundation

public protocol Traceable {
    func record<M: Message>(
        message: M,
        from channel: MessageDispatchChannel,
        _ file: StaticString,
        _ line: Int
    )
    func enable()
    func disable()

    var isEnabled: Bool { get }
}

private let printerQueue = {
    DispatchQueue(
        label: "io.MessageChannel.printerQueue",
        qos: .background
    )
}()

public struct SimpleTracing {
    public private(set) var printer: (String) -> Void

    private let wrapped = WrappedConfig()
    private let queue: DispatchQueue

    public init(
        _ printer: @escaping (String) -> Void = { print($0) },
        queue: DispatchQueue
    ) {
        self.printer = printer
        self.queue = queue
    }

    public init(
        _ printer: @escaping (String) -> Void = { print($0) }
    ) {
        self.init(printer, queue: printerQueue)
    }
}

extension SimpleTracing: Traceable {
    public var isEnabled: Bool { wrapped.isEnabled }

    public func enable() {
        wrapped.isEnabled = true
    }

    public func disable() {
        wrapped.isEnabled = false
    }

    public func record<M>(
        message: M,
        from channel: MessageDispatchChannel,
        _ file: StaticString,
        _ line: Int
    ) where M : Message {
        #if Tracing
        guard wrapped.isEnabled else {
            return
        }

        queue.async {
            var messageContent = ""
            customDump(message, to: &messageContent, indent: 4)

            var chennelContent = ""
            customDump(channel, to: &chennelContent, indent: 4)

            self.printer(
            """
            [MessageChannel]
            \(chennelContent)
            [message]
            \(messageContent)
            [file]
                \(file)
            [line] \(line)\n
            """
           )
        }

        #endif
    }
}

extension String {
    func inserIndent(by count: Int) -> String {
        if self.isEmpty {
            return self
        }

        if self.starts(with: "\n") {
            let content = self.dropFirst()
            let indent = String(repeating: " ", count: count)
            return "\n\(indent)\(content)"
        } else {
            return "\(String(repeating: " ", count: count))\(self)"
        }
    }
}

extension SimpleTracing {
    final class WrappedConfig {
        var isEnabled: Bool = false

        init() {}
    }
}
