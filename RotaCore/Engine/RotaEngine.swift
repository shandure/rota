import Foundation

/// The resolved shift for one calendar day.
public struct DayShift: Hashable, Sendable, Identifiable {
    /// Start of day in the calendar the engine was asked with.
    public let date: Date
    public var id: Date { date }
    public let shift: ShiftType
    /// True when an `Override` supplied the shift instead of the cycle.
    public let isOverride: Bool
    /// The override's note, if any.
    public let note: String?

    public init(date: Date, shift: ShiftType, isOverride: Bool, note: String?) {
        self.date = date
        self.shift = shift
        self.isOverride = isOverride
        self.note = note
    }
}

/// Every date calculation in the app goes through here (Non-negotiable 1).
///
/// Inputs are **day-stamps**: values produced by `Calendar.startOfDay(for:)`.
/// The UI never passes a raw `Date()`; it passes `Calendar.current.startOfDay(for: .now)`.
///
/// Rule (§3): shift on day D = override for D if present, else
/// `cycle[(daysBetween(startDate, D) mod cycle.count)]`, with negative modulo handled
/// so the pattern extends backwards before `startDate`.
public enum RotaEngine {

    // MARK: Day arithmetic

    /// Snaps a day-stamp to the nearest local midnight in `calendar`.
    ///
    /// A day-stamp written as start-of-day in one time zone is a different instant from
    /// start-of-day in another. Re-reading it after the device changes zone would move it
    /// to the previous or next calendar day (e.g. London 00:00 is 19:00 the day before in
    /// New York). Snapping to the *nearest* midnight keeps the same calendar day for any
    /// zone within 12 hours of the one it was written in. For a day-stamp written in the
    /// current zone this is the identity.
    public static func canonicalDay(_ date: Date, calendar: Calendar = .current) -> Date {
        let start = calendar.startOfDay(for: date)
        guard let next = calendar.date(byAdding: .day, value: 1, to: start) else { return start }
        let sinceStart = date.timeIntervalSince(start)
        let untilNext = next.timeIntervalSince(date)
        return sinceStart <= untilNext ? start : next
    }

    /// Whole calendar days from `from` to `to` (negative when `to` is earlier).
    /// Calendrical, so DST days of 23 or 25 hours still count as exactly one day.
    public static func daysBetween(_ from: Date, _ to: Date, calendar: Calendar = .current) -> Int {
        let a = canonicalDay(from, calendar: calendar)
        let b = canonicalDay(to, calendar: calendar)
        return calendar.dateComponents([.day], from: a, to: b).day ?? 0
    }

    /// Index into the cycle for `date`, in `0..<cycleLength`, for any date before or after `startDate`.
    public static func cycleIndex(on date: Date,
                                  startDate: Date,
                                  cycleLength: Int,
                                  calendar: Calendar = .current) -> Int {
        precondition(cycleLength > 0, "cycleLength must be positive")
        let delta = daysBetween(startDate, date, calendar: calendar)
        return ((delta % cycleLength) + cycleLength) % cycleLength
    }

    // MARK: Resolution

    /// The shift on `date`, with override information.
    public static func entry(on date: Date,
                             for pattern: PatternSnapshot,
                             calendar: Calendar = .current) -> DayShift {
        let day = canonicalDay(date, calendar: calendar)
        let overrides = overrideIndex(for: pattern, calendar: calendar)
        return entry(onCanonical: day, pattern: pattern, overrides: overrides, calendar: calendar)
    }

    /// The shift on `date` (§7 step 1 API).
    public static func shift(on date: Date,
                             for pattern: PatternSnapshot,
                             calendar: Calendar = .current) -> ShiftType {
        entry(on: date, for: pattern, calendar: calendar).shift
    }

    /// One entry per calendar day whose start lies in `interval` (end exclusive), in date order.
    /// `interval.start` is taken to mean the day containing it.
    public static func shifts(in interval: DateInterval,
                              for pattern: PatternSnapshot,
                              calendar: Calendar = .current) -> [DayShift] {
        let overrides = overrideIndex(for: pattern, calendar: calendar)
        var day = calendar.startOfDay(for: interval.start)
        var result: [DayShift] = []
        while day < interval.end {
            result.append(entry(onCanonical: day, pattern: pattern, overrides: overrides, calendar: calendar))
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return result
    }

    /// The first worked shift strictly after `date`, searching up to `limit` days ahead.
    /// Off days, Holiday and Sick are skipped (`ShiftType.isWorked`).
    public static func nextShift(after date: Date,
                                 for pattern: PatternSnapshot,
                                 calendar: Calendar = .current,
                                 within limit: Int = 366) -> DayShift? {
        let overrides = overrideIndex(for: pattern, calendar: calendar)
        var day = canonicalDay(date, calendar: calendar)
        for _ in 0..<max(limit, 0) {
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { return nil }
            day = next
            let candidate = entry(onCanonical: day, pattern: pattern, overrides: overrides, calendar: calendar)
            if candidate.shift.isWorked { return candidate }
        }
        return nil
    }

    // MARK: Private

    private static func overrideIndex(for pattern: PatternSnapshot,
                                      calendar: Calendar) -> [Date: OverrideSnapshot] {
        var index: [Date: OverrideSnapshot] = [:]
        index.reserveCapacity(pattern.overrides.count)
        for override in pattern.overrides {
            index[canonicalDay(override.date, calendar: calendar)] = override
        }
        return index
    }

    private static func entry(onCanonical day: Date,
                              pattern: PatternSnapshot,
                              overrides: [Date: OverrideSnapshot],
                              calendar: Calendar) -> DayShift {
        if let override = overrides[day] {
            return DayShift(date: day, shift: override.shift, isOverride: true, note: override.note)
        }
        guard !pattern.cycle.isEmpty else {
            return DayShift(date: day, shift: .off, isOverride: false, note: nil)
        }
        let index = cycleIndex(on: day,
                               startDate: pattern.startDate,
                               cycleLength: pattern.cycle.count,
                               calendar: calendar)
        return DayShift(date: day, shift: pattern.cycle[index], isOverride: false, note: nil)
    }
}
