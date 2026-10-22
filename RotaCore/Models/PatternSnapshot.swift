import Foundation

/// A plain-value copy of an `Override` (§3), used by `RotaEngine`.
public struct OverrideSnapshot: Hashable, Sendable, Identifiable {
    public var id: UUID
    /// Start of day, in the time zone it was created in (see `RotaEngine.canonicalDay`).
    public var date: Date
    public var shift: ShiftType
    public var note: String?

    public init(id: UUID = UUID(), date: Date, shift: ShiftType, note: String? = nil) {
        self.id = id
        self.date = date
        self.shift = shift
        self.note = note
    }
}

/// A plain-value copy of a `Pattern` (§3). `RotaEngine` works on this so the
/// engine has no SwiftData dependency and can be tested anywhere Foundation runs.
/// The widget reads the same shape.
public struct PatternSnapshot: Hashable, Sendable, Identifiable {
    public var id: UUID
    public var name: String
    /// Start of day; the day cycle index 0 falls on.
    public var startDate: Date
    /// Ordered; repeats forever. Max `Limits.maxCycleLength`.
    public var cycle: [ShiftType]
    public var overrides: [OverrideSnapshot]

    public init(id: UUID = UUID(),
                name: String,
                startDate: Date,
                cycle: [ShiftType],
                overrides: [OverrideSnapshot] = []) {
        self.id = id
        self.name = name
        self.startDate = startDate
        self.cycle = cycle
        self.overrides = overrides
    }
}

/// Hard limits from the spec (§3).
public enum Limits {
    public static let maxCycleLength = 56
    public static let maxPatternNameLength = 30
    public static let maxCustomLabelLength = 6
    public static let maxNoteLength = 60
}
