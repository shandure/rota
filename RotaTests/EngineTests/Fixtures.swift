import Foundation
import RotaCore

/// Fixed-date fixtures. Never use `Date()` in tests.
enum Fixtures {
    /// UK calendar: Monday week start, Europe/London (GMT/BST).
    static let london = calendar("Europe/London")

    static func calendar(_ timeZone: String) -> Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: timeZone)!
        c.locale = Locale(identifier: "en_GB")
        c.firstWeekday = 2
        return c
    }

    /// Local midnight for y/m/d in `calendar`.
    static func day(_ year: Int, _ month: Int, _ day: Int, in calendar: Calendar = london) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    static func ymd(_ date: Date, in calendar: Calendar = london) -> [Int] {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return [c.year!, c.month!, c.day!]
    }

    static func adding(_ days: Int, to date: Date, in calendar: Calendar = london) -> Date {
        calendar.date(byAdding: .day, value: days, to: date)!
    }

    /// Whole-month interval, end exclusive.
    static func month(_ year: Int, _ month: Int, in calendar: Calendar = london) -> DateInterval {
        let start = day(year, month, 1, in: calendar)
        let end = calendar.date(byAdding: .month, value: 1, to: start)!
        return DateInterval(start: start, end: end)
    }

    // MARK: Cycles

    /// 2 days, 2 nights, 4 off — the spec's reference pattern.
    static let twoDayTwoNightFourOff: [ShiftType] = [.day, .day, .night, .night, .off, .off, .off, .off]

    /// A 56-cell cycle where cell i is distinguishable: label "C<i>".
    static let fiftySix: [ShiftType] = (0..<56).map {
        ShiftType(kind: .custom, label: "C\($0)", colorHex: "#FF6B6B")
    }

    /// Monday 5 January 2026 is a known Day-1 of the reference rota.
    static let referenceStart = day(2026, 1, 5)

    static func pattern(start: Date = referenceStart,
                        cycle: [ShiftType] = twoDayTwoNightFourOff,
                        overrides: [OverrideSnapshot] = []) -> PatternSnapshot {
        PatternSnapshot(name: "Ward 7", startDate: start, cycle: cycle, overrides: overrides)
    }

    /// Compact labels for comparing against a hand-written rota: D N L E O HOL SICK.
    static func labels(_ entries: [DayShift]) -> String {
        entries.map { e in
            switch e.shift.kind {
            case .day: return "D"
            case .night: return "N"
            case .late: return "L"
            case .early: return "E"
            case .off: return "O"
            case .custom: return e.shift.label
            }
        }.joined(separator: " ")
    }
}
