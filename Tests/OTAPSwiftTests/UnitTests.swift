
import XCTest
@testable import OTAPSwift

//MARK: - PacketType

final class PacketTypeTests: XCTestCase {
    
    func testPacketTypeEnumValues() throws {
        XCTAssertEqual(PacketType.Request.join.rawValue, 0)
        XCTAssertEqual(PacketType.Request.externalChat.rawValue, 8)
        XCTAssertEqual(PacketType.Response.full.rawValue, 100)
        XCTAssertEqual(PacketType.Response.cmdLogging.rawValue, 127)
        XCTAssertEqual(PacketType.invalid.rawValue, 255)
    }
    
    func testPacketLengthConsts() throws {
        XCTAssertEqual(PacketType.encodedByteLength, 1)
        XCTAssertEqual(PacketType.encodedSizeLength, 2)
        XCTAssertEqual(Packet.Header.encodedLength, 3)
    }
}

//MARK: - NetworkError

final class NetworkErrorTests: XCTestCase {
    
    func testNetworkErrorEnumValues() throws {
        XCTAssertEqual(NetworkError.general.rawValue, 0)
        XCTAssertEqual(NetworkError.notAuthorized.rawValue, 6)
        XCTAssertEqual(NetworkError.cheater.rawValue, 13)
        XCTAssertEqual(NetworkError.notOnAllowList.rawValue, 21)
    }
}

//MARK: - PayloadWriter

final class PayloadWriterTests: XCTestCase {
    
    func testAppendByte() throws {
        let byte: UInt8 = 42
        var writer = Writer()
        writer.append(byte: byte)
        
        XCTAssertTrue(writer.data[0] == byte)
        XCTAssertTrue(writer.data.count == 1)
    }

    func testAppendBool() throws {
        var trueWriter = Writer()
        trueWriter.append(bool: true)
        XCTAssertTrue(trueWriter.data[0] == UInt8(1))
        XCTAssertTrue(trueWriter.data.count == 1)
        
        var falseWriter = Writer()
        falseWriter.append(bool: false)
        XCTAssertTrue(falseWriter.data[0] == UInt8(0))
        XCTAssertTrue(falseWriter.data.count == 1)
    }
    
    func testAppendInt() throws {
        let values: [any UnsignedInteger & FixedWidthInteger] = [
            UInt8.min, UInt16.min, UInt32.min, UInt64.min, UInt.min,
            UInt8.max, UInt16.max, UInt32.max, UInt64.max, UInt.max,
            UInt8(42), UInt16(32_123), UInt32(64_567), UInt64(42_345_678), UInt(123_456)
        ]
        
        func test<I>(_ value: I) throws where I: UnsignedInteger & FixedWidthInteger {
            let size = MemoryLayout<I>.size
            var writer = Writer()
            writer.append(int: value)
            
            XCTAssertTrue(writer.data.count == size)
            XCTAssertTrue(writer.data[0..<size].withUnsafeBytes { $0.bindMemory(to: I.self)[0] } == value.littleEndian)
        }

        for value in values {
            try test(value)
        }
    }
    
    func testAppendString() throws {
        let testData: [(String, Data)] = [
            ("test", Data([116, 101, 115, 116, 0])),
            ("0", Data([48, 0])),
            ("\0", Data([92, 48, 0])),
            ("Dog‼🐶", Data([68, 111, 103, 226, 128, 188, 240, 159, 144, 182, 0]))
        ]

        for (value, expected) in testData {
            var writer = Writer()
            writer.append(string: value)
            
            XCTAssertTrue(writer.data == expected)
        }
    }
}

