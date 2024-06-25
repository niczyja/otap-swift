
import Foundation

// https://github.com/OpenTTD/OpenTTD/blob/master/src/timer/timer_game_common.cpp

public struct GameDate: RawRepresentable {
    
    public let rawValue: UInt32
    
    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    public static let min = GameDate(rawValue: GameCalendar.start)
    public static let max = GameDate(rawValue: GameCalendar.end)
}

//MARK: -

extension GameDate: Comparable {
    
    @inlinable public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    @inlinable public static func + (lhs: Self, rhs: Self) -> Self {
        GameDate(rawValue: lhs.rawValue + rhs.rawValue)
    }

    @inlinable public static func - (lhs: Self, rhs: Self) -> Self {
        GameDate(rawValue: lhs.rawValue - rhs.rawValue)
    }
}

//MARK: -

extension GameDate: CustomStringConvertible {

    public var description: String {
        GameCalendar.current.date(from: self)?.description ?? "invalid"
    }
}
