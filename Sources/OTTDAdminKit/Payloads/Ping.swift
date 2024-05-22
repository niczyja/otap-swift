
import Foundation

// https://github.com/OpenTTD/OpenTTD/blob/46d7586ab187848c50e0f3dc212d853e69d79c54/src/network/network_admin.cpp#L518

public struct Ping: WritablePayload {
    public private(set) var writer: Writer
    
    public init(id: UInt32) throws {
        self.writer = Writer()
        self.writer.append(int: id)         ///< to identify matching pong response
    }
}
