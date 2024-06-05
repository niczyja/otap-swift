
import Foundation

// https://github.com/OpenTTD/OpenTTD/blob/c85481564f1f4b709f960184cd55cd6643968116/src/network/network_admin.cpp#L170

public struct Welcome: ReadablePayload {
    public let server: Server
    public let reader: Reader
    
    public init(data: Data) throws {
        guard data.count >= 0 else {
            throw OTAPError.expectedMoreData
        }

        self.reader = Reader(data: data)

        let serverName = try self.reader.readString()
        let serverRevision = try self.reader.readString()
        let isDedicated = try self.reader.readBool()
        let mapName = try self.reader.readString()
        let mapSeed = try self.reader.readUInt32()
        let landscape = try self.reader.readByte()
        let startingYear = try self.reader.readUInt32()
        let mapSizeX = try self.reader.readUInt16()
        let mapSizeY = try self.reader.readUInt16()

        self.server = Server(name: serverName,
                             revision: serverRevision,
                             isDedicated: isDedicated,
                             startingYear: startingYear,
                             map: Server.Map(name: mapName,
                                             seed: mapSeed,
                                             landscape: landscape,
                                             sizeX: mapSizeX,
                                             sizeY: mapSizeY))
    }
}
