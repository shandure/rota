import Foundation

/// One widget timeline entry's data (§4.6): the day, its shift, the next worked shift,
/// and the 7-day strip starting on that day.
public struct WidgetDay: Hashable, Sendable, Identifiable {
    public let date: Date
    public let today: DayShift
    public let next: DayShift?
    public let week: [DayShift]

    public var id: Date { date }

    public init(date: Date, today: DayShift, next: DayShift?, week: [DayShift]) {
        self.date = date
        self.today = today
        self.next = next
        self.week = week
    }
}

public extension RotaEngine {
    static let widgetDaysAhead = 7

    /// One `WidgetDay` per calendar day from `today`, for `count` days. Each entry's week strip
    /// starts on its own day so the medium widget always shows "today and the next six".
    static func widgetDays(from today: Date,
                           count: Int = widgetDaysAhead,
                           for pattern: PatternSnapshot,
                           calendar: Calendar = .current) -> [WidgetDay] {
        let start = canonicalDay(today, calendar: calendar)
        guard let end = calendar.date(byAdding: .day, value: count + widgetDaysAhead, to: start) else { return [] }
        let entries = shifts(in: DateInterval(start: start, end: end), for: pattern, calendar: calendar)
        guard entries.count >= count + widgetDaysAhead - 1 else { return [] }

        return (0..<count).map { offset in
            let day = entries[offset]
            let week = Array(entries[offset..<min(offset + widgetDaysAhead, entries.count)])
            return WidgetDay(date: day.date,
                             today: day,
                             next: nextShift(after: day.date, for: pattern, calendar: calendar),
                             week: week)
        }
    }
}
