
import Foundation

// https://github.com/OpenTTD/OpenTTD/blob/46d7586ab187848c50e0f3dc212d853e69d79c54/src/network/network_admin.cpp#L566

public struct Pong: ReadablePayload {
    public let id: UInt32
    public let reader: Reader
    
    public init(data: Data) throws {
        guard data.count == 4 else {
            throw OTAPPacketError.malformedPayload
        }
        
        self.reader = Reader(data: data)
        self.id = try self.reader.readUInt32()
    }
}
