
import Foundation
import BitByteData

public protocol Payload {
    var size: Int { get }
    var data: Data { get }
}

public extension Payload {
    var size: Int { data.count }
}

//MARK: -

public protocol WritablePayload: Payload {
    var writer: Writer { get }
}

public extension WritablePayload {
    var size: Int { writer.size }
    var data: Data { writer.data }
}

//MARK: -

public protocol ReadablePayload: Payload {
    var reader: Reader { get }
    init(data: Data) throws
}

public extension ReadablePayload {
    var size: Int { reader.size }
    var data: Data { reader.data }
}

//MARK: -

public struct Reader {
    public var data: Data { reader.data }
    public var size: Int { reader.size }
    private let reader: LittleEndianByteReader
    
    public init(data: Data) {
        self.reader = LittleEndianByteReader(data: data)
    }
    
    internal func canRead(numBytes: Int) -> Bool {
        return numBytes <= reader.bytesLeft
    }
    
    internal func readBool() throws -> Bool {
        try readByte() != 0
    }
    
    internal func readByte() throws -> UInt8 {
        guard canRead(numBytes: MemoryLayout<UInt8>.size) else {
            throw OTAPError.expectedMoreData
        }
        return reader.byte()
    }
    
    internal func readUInt16() throws -> UInt16 {
        guard canRead(numBytes: MemoryLayout<UInt16>.size) else {
            throw OTAPError.expectedMoreData
        }
        return reader.uint16()
    }
    
    internal func readUInt32() throws -> UInt32 {
        guard canRead(numBytes: MemoryLayout<UInt32>.size) else {
            throw OTAPError.expectedMoreData
        }
        return reader.uint32()
    }
    
    internal func readUInt64() throws -> UInt64 {
        guard canRead(numBytes: MemoryLayout<UInt64>.size) else {
            throw OTAPError.expectedMoreData
        }
        return reader.uint64()
    }
    
    internal func readString() throws -> String {
        var chars: [UInt8] = []
        var char: UInt8
        repeat {
            char = try readByte()
            chars.append(char)
        } while (char != 0)

        return String(cString: chars)
    }
}

//MARK: -

public struct Writer {
    public private(set) var data: Data = Data()
    public var size: Int { data.count }
    
    internal mutating func append(bool: Bool) {
        append(byte: bool ? 1 : 0)
    }

    internal mutating func append(byte: UInt8) {
        data.append(byte)
    }

    internal mutating func append(int: any UnsignedInteger) {
        let size = MemoryLayout.size(ofValue: int)
        for i in 0..<size {
            data.append(UInt8(int) >> (8 * i))
        }
    }
    
    internal mutating func append(string: String, maxBytes: Int? = nil) {
        if let stringData = string.data(using: .utf8) {
            data.append(contentsOf: [UInt8](stringData.prefix(maxBytes ?? stringData.count)))
        }
        data.append(0)
    }
}
