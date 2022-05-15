import Foundation

public protocol Message {
    var plainText: String { get }
}

extension Message {
    public var plainText: String { "\(self)" }
}

extension Message {
    /// Identifier for Message's type
    public static var identifyKey: String { "\(Self.self)" }
}
