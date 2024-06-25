
import Foundation

// https://github.com/OpenTTD/OpenTTD/blob/master/src/timer/timer_game_common.cpp

/// Used to represent game dates, game date components, perform operations on game dates, and convert between `Date`. Use via `current` static property.
public struct GameCalendar {
    
    /// Components used to represent game date
    public enum Component: Hashable {
        case year(Int),     ///< Year (0...)
             month(Int),    ///< Month (0..11)
             day(Int)       ///< Day (1..31)
    }
    
    /// Current game calendar
    public static let current = GameCalendar()
    
    private init() {}
}

//MARK: -

public extension GameCalendar {
    
    /// Checks if given game date is valid.
    /// Date is valid if it fits between 1st Jan year 0 and 31st Dec year 5000000
    func isValid(_ date: GameDate) -> Bool {
        (Self.start...Self.end).contains(date.rawValue)
    }
    
    /// Creates game date from `Date`
    func gameDate(from date: Date) -> GameDate {
        gameDate(from: Self.calendar.dateComponents(in: Self.timeZone, from: date))
    }
    
    /// Creates game date from `DateComponents`
    func gameDate(from dateComponents: DateComponents) -> GameDate {
        gameDate(from: [dateComponents])
    }
    
    /// Creates game date from set of `DateComponents`
    func gameDate(from dateComponents: Set<DateComponents>) -> GameDate {
        let components = components(from: dateComponents)
        let totalDays = components.reduce(0, { $0 + days(till: $1) })
        return GameDate(rawValue: GameDate.RawValue(totalDays))
    }

    /// Returns `Date` from game date or `nil` if date couldn't be created
    func date(from gameDate: GameDate) -> Date? {
        Self.calendar.date(from: dateComponents(from: components(from: gameDate)))
    }
    
    /// Returns `Date` from game calendar components or `nil` if date coudn't be created
    func date(from component: GameCalendar.Component) -> Date? {
        Self.calendar.date(from: dateComponents(from: [component]))
    }
    
    /// Returns `Date` from set of game calendar components or `nil` if date couldn't be created
    func date(from components: Set<GameCalendar.Component>) -> Date? {
        Self.calendar.date(from: dateComponents(from: components))
    }
}

//MARK: -

public extension GameCalendar {
    
    /// Checks if component is leap. Returns `false` for components other than `.year`
    func isLeap(_ component: GameCalendar.Component) -> Bool {
        if case .year(let year) = component {
            return year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)
        }
        return false
    }
    
    /// Returns number of leap years till given component. Returns `0` for components other than `.year`
    func leapYears(till component: GameCalendar.Component) -> Int {
        if case .year(let year) = component {
            guard year > 0 else { return 0 }
            let prevYear = year - 1
            return prevYear / 4 - prevYear / 100 + prevYear / 400 + 1
        }
        return 0
    }
    
    /// Returns number of days that passed till given component, excluding the component
    func days(till component: GameCalendar.Component) -> Int {
        switch component {
        case .year(let year):
            return Self.daysInYear * year + leapYears(till: .year(year))
        case .month(let month):
            guard month <= Self.daysInMonth.count else { return Self.daysInYear }
            return Int(Self.daysInMonth.prefix(upTo: month).reduce(0, +))
        case .day(let day):
            return day - 1
        }
    }
    
    /// Returns set of components from date components, or empty set given no matching components found.
    func components(from dateComponents: Set<DateComponents>) -> Set<GameCalendar.Component> {
        var components: Set<GameCalendar.Component> = []
        dateComponents.forEach { dateComponent in
            if let year = dateComponent.year {
                components.insert(component: .year(year))
            }
            if let month = dateComponent.month {
                components.insert(component: .month(month - 1))
            }
            if let day = dateComponent.day {
                components.insert(component: .day(day))
            }
        }
        return components
    }
    
    /// Returns date components from set of game calendar components
    func dateComponents(from components: Set<GameCalendar.Component>) -> DateComponents {
        var dateComponents = DateComponents(timeZone: Self.timeZone)
        components.forEach { component in
            if case .year(let year) = component {
                dateComponents.year = year
            }
            if case .month(let month) = component {
                dateComponents.month = month + 1
            }
            if case .day(let day) = component {
                dateComponents.day = day
            }
        }
        return dateComponents
    }

    /// Returns set of game calendar components from game date
    func components(from gameDate: GameDate) -> Set<GameCalendar.Component> {
        // Account for game counting from 0
        let totalDays = Int(gameDate.rawValue + 1)
        
        // Following code is more or less re-implementation of how the game does it:
        
        // There are 97 leap years in 400 years
        var year = 400 * (totalDays / (Self.daysInYear * 400 + 97));
        var day = totalDays % (Self.daysInYear * 400 + 97);
        
        if day >= Self.daysInYear * 100 + 25 {
            // There are 25 leap years in the first 100 years after every 400th year, as every 400th year is a leap year
            year += 100
            day -= Self.daysInYear * 100 + 25
            
            // There are 24 leap years in the next couple of 100 years
            year += 100 * (day / (Self.daysInYear * 100 + 24))
            day = day % (Self.daysInYear * 100 + 24)
        }
        
        if !isLeap(.year(year)) && day >= Self.daysInYear * 4 {
            // The first 4th year of the century is not always a leap year
            year += 4
            day -= Self.daysInYear * 4
        }
        
        // There is 1 leap year every 4 years
        year += 4 * (day / (Self.daysInYear * 4 + 1))
        day = day % (Self.daysInYear * 4 + 1)
        
        // The last (max 3) years to account for; the first one can be, but is not necessarily a leap year
        while day >= days(in: year) {
            day -= days(in: year)
            year += 1
        }
        
        // Count months in current year
        var month = 0
        let isLeap = isLeap(.year(year))
        while day > days(in: month, isLeap: isLeap) {
            day -= days(in: month, isLeap: isLeap)
            month += 1
        }
        
        return [.year(year), .month(month), .day(day)]
    }
}

//MARK: -

internal extension GameCalendar {
    
    static let start: GameDate.RawValue = 0                ///< 1st Jan of year 0
    static let end: GameDate.RawValue = 1_826_212_865      ///< 31st Dec of year 5_000_000
    static let startComponents: Set<GameCalendar.Component> = [.year(0), .month(0), .day(1)]
    static let daysInMonth = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    static let daysInLeapYear = 366
    static let daysInYear = 365
}

private extension GameCalendar {
    
    static let calendar = Calendar.current
    static let timeZone = TimeZone.gmt
    
    func days(in month: Int, isLeap: Bool) -> Int {
        Self.daysInMonth[month] + Int(isLeap && month == 1)
    }
    
    func days(in year: Int) -> Int {
        isLeap(.year(year)) ? Self.daysInLeapYear : Self.daysInYear
    }
}

private extension Set<GameCalendar.Component> {
    
    /// Inserts new component into the set only if there's no component of the same type already present
    /// i.e. it won't add `.year(x)` if there's already `.year(y)` in the set, regardless of associated value
    mutating func insert(component: GameCalendar.Component) {
        guard !(contains { if case component = $0 { return true }; return false }) else { return }
        insert(component)
    }
}
