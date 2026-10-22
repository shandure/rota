import Foundation

/// Month-grid arithmetic for the Month screen and the widget (§4.1).
public extension RotaEngine {
    /// The month grid always has six rows so the layout never jumps between months.
    static let monthGridRows = 6

    /// Local midnight on the first day of the month containing `date`.
    static func startOfMonth(containing date: Date, calendar: Calendar = .current) -> Date {
        let day = canonicalDay(date, calendar: calendar)
        let components = calendar.dateComponents([.year, .month], from: day)
        return calendar.date(from: components) ?? day
    }

    /// The 42-day interval (end exclusive) shown for the month containing `date`:
    /// starts on the first day of the week (`calendar.firstWeekday`) on or before the 1st.
    static func monthGrid(containing date: Date, calendar: Calendar = .current) -> DateInterval {
        let first = startOfMonth(containing: date, calendar: calendar)
        let weekday = calendar.component(.weekday, from: first)
        let offset = (weekday - calendar.firstWeekday + 7) % 7
        let start = calendar.date(byAdding: .day, value: -offset, to: first) ?? first
        let end = calendar.date(byAdding: .day, value: 7 * monthGridRows, to: start) ?? start
        return DateInterval(start: start, end: end)
    }

    /// Weekday initials in grid order, e.g. M T W T F S S for a Monday week start.
    static func weekdayInitials(calendar: Calendar = .current) -> [String] {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        return (0..<7).map { symbols[(calendar.firstWeekday - 1 + $0) % 7] }
    }

    /// Counts for the summary strip (§4.1): "14 shifts · 8 nights · 16 off".
    struct Summary: Hashable, Sendable {
        /// Worked shifts (`ShiftType.isWorked`): Off, Holiday and Sick excluded.
        public let shifts: Int
        public let nights: Int
        /// Everything not worked, so `shifts + off` is the number of days counted.
        public let off: Int

        public init(shifts: Int, nights: Int, off: Int) {
            self.shifts = shifts
            self.nights = nights
            self.off = off
        }
    }

    static func summary(of entries: [DayShift]) -> Summary {
        var shifts = 0, nights = 0, off = 0
        for entry in entries {
            if entry.shift.isWorked {
                shifts += 1
                if entry.shift.kind == .night { nights += 1 }
            } else {
                off += 1
            }
        }
        return Summary(shifts: shifts, nights: nights, off: off)
    }
}
