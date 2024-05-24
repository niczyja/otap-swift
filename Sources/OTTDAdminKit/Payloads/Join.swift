
import Foundation

// https://github.com/OpenTTD/OpenTTD/blob/c85481564f1f4b709f960184cd55cd6643968116/src/network/network_admin.cpp#L630

public struct Join: WritablePayload {
    public static let maxPasswordLength = 32
    public static let maxNameLength = 24
    public static let maxVersionLength = 32

    public private(set) var writer: Writer

    public init(name: String, password: String, version: String) throws {
        self.writer = Writer()
        self.writer.append(string: password, maxBytes: Self.maxPasswordLength)
        self.writer.append(string: name, maxBytes: Self.maxNameLength)
        self.writer.append(string: version, maxBytes: Self.maxVersionLength)
    }
}
