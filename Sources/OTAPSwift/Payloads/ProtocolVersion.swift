
import Foundation

// https://github.com/OpenTTD/OpenTTD/blob/c85481564f1f4b709f960184cd55cd6643968116/src/network/network_admin.cpp#L150

public struct ProtocolVersion: ReadablePayload {
    public let version: UInt8
    public private(set) var updates: GameServer.Updates = [:]
    public let reader: Reader
    
    public init(data: Data) throws {
        guard data.count >= 1 else {
            throw OTAPPacketError.expectedMoreData
        }
        
        self.reader = Reader(data: data)
        self.version = try self.reader.readByte()
        
        while (try self.reader.readBool()) {
            guard let updateType = GameServer.Update(rawValue: try self.reader.readUInt16()) else {
                throw OTAPPacketError.malformedPayload
            }

            updates[updateType] = GameServer.Update.Frequency(rawValue: try self.reader.readUInt16())
        }
    }
}
