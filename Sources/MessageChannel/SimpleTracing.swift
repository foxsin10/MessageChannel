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
    func chose(tracingLevel: TracingLevel)

    var isEnabled: Bool { get }

    var tracingLevel: TracingLevel { get }
}

public enum TracingLevel {
    case pretty
    case verbose
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

    public var tracingLevel: TracingLevel { wrapped.traceingLevel }

    public func enable() {
        wrapped.isEnabled = true
    }

    public func disable() {
        wrapped.isEnabled = false
    }

    public func chose(tracingLevel: TracingLevel) {
        wrapped.traceingLevel = tracingLevel
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

            let channelInfo: String = {
                switch tracingLevel {
                case .pretty:
                    return channel.channelMap
                case .verbose:
                    var info = ""
                    customDump(channel, to: &info, indent: 4)
                    return info
                }
            }()

            self.printer(
            """
            [file] \(file.prettyerString()) [line] \(line)
            [Message]
            \(messageContent)
            [MessageChannel]
            \(channelInfo)
            """
           )
        }
        #endif
    }
}

extension SimpleTracing {
    final class WrappedConfig {
        var isEnabled: Bool = false
        var traceingLevel: TracingLevel = .pretty
        init() {}
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

extension StaticString {
    func prettyerString() -> String {
        var fileComponents = "\(self)".components(separatedBy: "/")
        let fileName = fileComponents.popLast()
        let nearestPath = fileComponents.popLast()

        return [nearestPath, fileName].compactMap { $0 }.reduce(into: "", {
            if $0.isEmpty {
                $0 = $1
            } else {
                $0 = $0 + "/" + $1
            }
        })
    }
}
