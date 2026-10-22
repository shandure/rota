import Foundation

/// One event the exporter will write (§5).
public struct PlannedEvent: Hashable, Sendable {
    /// The rota day the event belongs to (a night that crosses midnight still belongs to its start day).
    public let day: Date
    public let title: String
    public let start: Date
    public let end: Date
    public let isAllDay: Bool
    /// `rota://pattern/<id>/<yyyy-mm-dd>`, so the app can find and delete its own events.
    public let url: URL

    public init(day: Date, title: String, start: Date, end: Date, isAllDay: Bool, url: URL) {
        self.day = day
        self.title = title
        self.start = start
        self.end = end
        self.isAllDay = isAllDay
        self.url = url
    }
}

/// Pure planning for the Calendar export (§5). No EventKit here, so it runs anywhere.
public enum CalendarPlanner {
    public static let urlScheme = "rota"
    public static let monthsAhead = 12

    /// "2026-10-23" for the calendar day of `date`.
    public static func dayString(_ date: Date, calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: RotaEngine.canonicalDay(date, calendar: calendar))
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    /// `rota://pattern/<id>/<yyyy-mm-dd>`
    public static func eventURL(patternID: UUID, day: Date, calendar: Calendar = .current) -> URL {
        URL(string: "\(urlScheme)://pattern/\(patternID.uuidString)/\(dayString(day, calendar: calendar))")!
    }

    /// The pattern id from an event URL the app wrote, or nil for any other URL.
    public static func patternID(from url: URL?) -> UUID? {
        guard let url, url.scheme == urlScheme, url.host == "pattern" else { return nil }
        let parts = url.pathComponents.filter { $0 != "/" }
        guard parts.count == 2 else { return nil }
        return UUID(uuidString: parts[0])
    }

    /// Today through `months` months ahead (end exclusive).
    public static func interval(from today: Date, months: Int = monthsAhead, calendar: Calendar = .current) -> DateInterval {
        let start = RotaEngine.canonicalDay(today, calendar: calendar)
        let end = calendar.date(byAdding: .month, value: months, to: start) ?? start
        return DateInterval(start: start, end: end)
    }

    /// Every event for `pattern` in the window. Off days produce nothing; Holiday and Sick
    /// produce all-day events; everything else is timed from the shift's start and end.
    public static func events(for pattern: PatternSnapshot,
                              from today: Date,
                              months: Int = monthsAhead,
                              calendar: Calendar = .current) -> [PlannedEvent] {
        let window = interval(from: today, months: months, calendar: calendar)
        return RotaEngine.shifts(in: window, for: pattern, calendar: calendar).compactMap { entry in
            event(for: entry, pattern: pattern, calendar: calendar)
        }
    }

    static func event(for entry: DayShift, pattern: PatternSnapshot, calendar: Calendar) -> PlannedEvent? {
        let shift = entry.shift
        guard !shift.isOff else { return nil }
        let day = entry.date
        let url = eventURL(patternID: pattern.id, day: day, calendar: calendar)
        guard let nextDay = calendar.date(byAdding: .day, value: 1, to: day) else { return nil }

        if shift.isAbsence {
            let title = shift.isSameType(as: .holiday) ? "Holiday" : "Sick"
            return PlannedEvent(day: day, title: title, start: day, end: nextDay, isAllDay: true, url: url)
        }

        let title = "\(pattern.name) · \(shift.label)"
        guard let startMinute = shift.startMinute, let endMinute = shift.endMinute,
              let start = calendar.date(bySettingHour: startMinute / 60, minute: startMinute % 60, second: 0, of: day),
              let end = calendar.date(bySettingHour: endMinute / 60, minute: endMinute % 60, second: 0,
                                      of: shift.crossesMidnight ? nextDay : day) else {
            return PlannedEvent(day: day, title: title, start: day, end: nextDay, isAllDay: true, url: url)
        }
        return PlannedEvent(day: day, title: title, start: start, end: end, isAllDay: false, url: url)
    }
}
