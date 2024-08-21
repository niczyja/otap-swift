
import Foundation

// https://github.com/OpenTTD/OpenTTD/blob/a288644e2058e0c4007bb76aa9ab6c97cf623871/src/network/network_admin.cpp#L207

struct DateResponse: ReadablePayload {
    public let rawDate: UInt32
    public let reader: Reader
    
    init(data: Data) throws {
        guard data.count == 4 else {
            throw OTAPPacketError.malformedPayload
        }
        
        self.reader = Reader(data: data)
        self.rawDate = try self.reader.readUInt32()
    }
}
