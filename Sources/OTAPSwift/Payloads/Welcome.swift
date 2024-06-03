
import Foundation

// https://github.com/OpenTTD/OpenTTD/blob/c85481564f1f4b709f960184cd55cd6643968116/src/network/network_admin.cpp#L170

public struct Welcome: ReadablePayload {
    public let serverName: String
    public let networkRevision: String
    public let isDedicated: Bool
    public let mapName: String
    public let mapSeed: UInt32
    public let landscape: UInt8
    public let startingYear: UInt32
    public let mapSizeX: UInt16
    public let mapSizeY: UInt16
    public let reader: Reader
    
    public init(data: Data) throws {
        guard data.count >= 0 else {
            throw OTAPError.expectedMoreData
        }

        self.reader = Reader(data: data)
        self.serverName = try self.reader.readString()
        self.networkRevision = try self.reader.readString()
        self.isDedicated = try self.reader.readBool()
        self.mapName = try self.reader.readString()
        self.mapSeed = try self.reader.readUInt32()
        self.landscape = try self.reader.readByte()
        self.startingYear = try self.reader.readUInt32()
        self.mapSizeX = try self.reader.readUInt16()
        self.mapSizeY = try self.reader.readUInt16()
    }
}
