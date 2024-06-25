
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
        let testValues: [any UnsignedInteger & FixedWidthInteger] = [
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

        for value in testValues {
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

//MARK: - GameCalendar

final class GameCalendarTests: XCTestCase {
    
    /// This can be helpful: https://en.wikipedia.org/wiki/Leap_year#Gregorian_calendar
    ///
    /// It's intentional that `.year(0)` is leap, but `leapYears(till: .year(0) == 0`, see:
    /// https://github.com/OpenTTD/OpenTTD/blob/master/src/timer/timer_game_common.h
    
    func testIsLeap() throws {
        let testData: [(GameCalendar.Component, Bool)] = [
            (.year(0), true), (.year(4), true), (.year(42), false),
            (.year(100), false), (.year(400), true), (.year(1600), true),
            (.year(1700), false), (.year(1900), false), (.year(2000), true),
            (.day(4), false), (.month(4), false)
        ]
        
        for (component, expectedValue) in testData {
            XCTAssertEqual(GameCalendar.current.isLeap(component), expectedValue)
        }
    }
    
    func testLeapYearsTill() throws {
        let testData: [(GameCalendar.Component, Int)] = [
            (.year(0), 0), (.year(1), 1), (.year(4), 1), (.year(5), 2),
            (.year(400), 97), (.year(2_000_000_000), 485_000_000),
            (.day(4), 0), (.month(4), 0)
        ]
        
        for (component, expectedValue) in testData {
            XCTAssertEqual(GameCalendar.current.leapYears(till: component), expectedValue)
        }
    }
    
    func testDaysTill() throws {
        let testData: [(GameCalendar.Component, Int)] = [
            (.day(0), -1), (.day(1), 0), (.day(42), 41),
            (.month(0), 0), (.month(1), 31), (.month(2), 59), (.month(11), 334), (.month(12), 365), (.month(13), 365), (.month(42), 365),
            (.year(0), 0), (.year(1), 366), (.year(4), 1_461), (.year(1950), 712_223), (.year(5_000_000), 1_826_212_500)
        ]
        
        for (component, expectedValue) in testData {
            XCTAssertEqual(GameCalendar.current.days(till: component), expectedValue)
        }
    }

    func testComponentsFromDateComponents() throws {
        let testData: [(Set<DateComponents>, Set<GameCalendar.Component>)] = [
            // Single components
            ([.init(year: 0)], [.year(0)]), ([.init(year: 1970)], [.year(1970)]), ([.init(year: 2001)], [.year(2001)]),
            ([.init(month: 1)], [.month(0)]), ([.init(month: 6)], [.month(5)]), ([.init(month: 12)], [.month(11)]),
            ([.init(day: 1)], [.day(1)]), ([.init(day: 13)], [.day(13)]), ([.init(day: 31)], [.day(31)]),
            // Pairs of components
            ([.init(year: 1970, month: 1)], [.year(1970), .month(0)]), ([.init(year: 2001, month: 12)], [.year(2001), .month(11)]),
            ([.init(year: 1970), .init(month: 11)], [.year(1970), .month(10)]), ([.init(year: 2020), .init(month: 2)], [.year(2020), .month(1)]),
            ([.init(day: 2), .init(month: 2)], [.day(2), .month(1)]), ([.init(year: 1410, day: 31)], [.year(1410), .day(31)]),
            // Triplets
            ([.init(year: 2137, month: 2, day: 31)], [.year(2137), .month(1), .day(31)]),
            ([.init(year: 0, month: 1, day: 1)], [.year(0), .month(0), .day(1)]),
            ([.init(year: 1950, month: 12, day: 31)], [.year(1950), .month(11), .day(31)]),
        ]

        for (components, expectedValue) in testData {
            let result = GameCalendar.current.components(from: components)
            XCTAssertEqual(result, expectedValue)
        }
    }
    
    func testDateComponentsFromComponents() throws {
        let testData: [(Set<GameCalendar.Component>, DateComponents)] = [
            ([.day(1)], .init(timeZone: .gmt, day: 1)), ([.day(29)], .init(timeZone: .gmt, day: 29)),
            ([.month(1)], .init(timeZone: .gmt, month: 2)), ([.month(11)], .init(timeZone: .gmt, month: 12)),
            ([.year(1)], .init(timeZone: .gmt, year: 1)), ([.year(2001)], .init(timeZone: .gmt, year: 2001)),
            ([.year(1950), .month(0), .day(1)], .init(timeZone: .gmt, year: 1950, month: 1, day: 1)),
            ([.year(2000), .month(1), .day(29)], .init(timeZone: .gmt, year: 2000, month: 2, day: 29)),
            ([.month(3), .day(31)], .init(timeZone: .gmt, month: 4, day: 31))
        ]
        
        for (components, expectedValue) in testData {
            let result = GameCalendar.current.dateComponents(from: components)
            XCTAssertEqual(result, expectedValue)
        }
    }
    
    func testComponentsFromGameDate() throws {
        let testData: [(GameDate, Set<GameCalendar.Component>)] = [
            (GameDate(rawValue: 0), [.year(0), .month(0), .day(1)]),
            (GameDate(rawValue: 366), [.year(1), .month(0), .day(1)]),
            (GameDate(rawValue: 712223), [.year(1950), .month(0), .day(1)]),
            (GameDate(rawValue: 719528), [.year(1970), .month(0), .day(1)]),
            (GameDate(rawValue: 730851), [.year(2001), .month(0), .day(1)]),
            (GameDate(rawValue: 730544), [.year(2000), .month(1), .day(29)]),
            (GameDate(rawValue: 514992), [.year(1410), .month(0), .day(1)]),
            (GameDate(rawValue: 780524), [.year(2137), .month(0), .day(1)])
        ]
        
        for (gameDate, expectedValue) in testData {
            let result = GameCalendar.current.components(from: gameDate)
            XCTAssertEqual(result, expectedValue)
        }
    }

    func testGameDateFromDate() throws {
        let date1970 = Date(timeIntervalSince1970: 0)
        let gameDate1 = GameCalendar.current.gameDate(from: date1970)
        XCTAssertEqual(gameDate1.rawValue, 719528)
        
        let date2001 = Date(timeIntervalSinceReferenceDate: 0)
        let gameDate2 = GameCalendar.current.gameDate(from: date2001)
        XCTAssertEqual(gameDate2.rawValue, 730851)
    }
    
    func testDateFromGameDate() throws {
        let gameDate1 = GameDate(rawValue: 719528)
        let date1970 = Date(timeIntervalSince1970: 0)
        XCTAssertEqual(GameCalendar.current.date(from: gameDate1), date1970)

        let gameDate2 = GameDate(rawValue: 730851)
        let date2001 = Date(timeIntervalSinceReferenceDate: 0)
        XCTAssertEqual(GameCalendar.current.date(from: gameDate2), date2001)
    }
}

//MARK: - GameDate

final class GameDateTests: XCTestCase {
    
    func testDateComparators() throws {
        let date = GameDate(rawValue: 42)
        let sameDate = GameDate(rawValue: 42)
        let laterDate = GameDate(rawValue: 420)

        XCTAssertEqual(date, sameDate)
        XCTAssertNotEqual(date, laterDate)
        XCTAssertGreaterThan(laterDate, date)
        XCTAssertGreaterThanOrEqual(laterDate, date)
        XCTAssertGreaterThanOrEqual(sameDate, date)
        XCTAssertLessThan(date, laterDate)
        XCTAssertLessThanOrEqual(date, laterDate)
        XCTAssertLessThanOrEqual(date, sameDate)
    }
    
    func testDateOperators() throws {
        let oneDate = GameDate(rawValue: 1920)
        let otherDate = GameDate(rawValue: 217)
        let ultimateDate = GameDate(rawValue: 2137)
        
        XCTAssertEqual(oneDate + otherDate, ultimateDate)
        XCTAssertEqual(ultimateDate - otherDate, oneDate)
    }
}
