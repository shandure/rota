import Foundation

#if canImport(SwiftData)
/// Convenience overloads taking the SwiftData `Pattern` directly (§7 step 1 API).
public extension RotaEngine {
    static func shift(on date: Date, for pattern: Pattern, calendar: Calendar = .current) -> ShiftType {
        shift(on: date, for: pattern.snapshot, calendar: calendar)
    }

    static func entry(on date: Date, for pattern: Pattern, calendar: Calendar = .current) -> DayShift {
        entry(on: date, for: pattern.snapshot, calendar: calendar)
    }

    static func shifts(in interval: DateInterval, for pattern: Pattern, calendar: Calendar = .current) -> [DayShift] {
        shifts(in: interval, for: pattern.snapshot, calendar: calendar)
    }

    static func nextShift(after date: Date,
                          for pattern: Pattern,
                          calendar: Calendar = .current,
                          within limit: Int = 366) -> DayShift? {
        nextShift(after: date, for: pattern.snapshot, calendar: calendar, within: limit)
    }
}
#endif
