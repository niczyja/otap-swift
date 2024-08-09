
import Foundation

// https://github.com/OpenTTD/OpenTTD/blob/19ca4089a13edde4e69fd98111b597cd575df13a/src/network/network_admin.cpp#L135

public struct ServerError: ReadablePayload {
    public let error: NetworkError
    public let reader: Reader
    
    public init(data: Data) throws {
        guard data.count == 1 else {
            throw OTAPPacketError.malformedPayload
        }
        
        self.reader = Reader(data: data)
        self.error = NetworkError(rawValue: try self.reader.readByte()) ?? .general
    }
}
