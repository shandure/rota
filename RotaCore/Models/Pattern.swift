import Foundation

#if canImport(SwiftData)
import SwiftData

/// A repeating shift pattern (§3). Persisted with SwiftData in the shared App Group container.
@Model
public final class Pattern {
    public var id: UUID
    /// Max `Limits.maxPatternNameLength` chars, e.g. "Ward 7".
    public var name: String
    /// Start of day; the day cycle index 0 falls on.
    public var startDate: Date
    /// Ordered; repeats forever. Max `Limits.maxCycleLength`.
    public var cycle: [ShiftType]
    public var createdAt: Date
    /// Only one pattern is active at a time; it drives the widget.
    public var isActive: Bool
    @Relationship(deleteRule: .cascade, inverse: \Override.pattern)
    public var overrides: [Override]

    public init(id: UUID = UUID(),
                name: String,
                startDate: Date,
                cycle: [ShiftType],
                createdAt: Date,
                isActive: Bool = false,
                overrides: [Override] = []) {
        self.id = id
        self.name = name
        self.startDate = startDate
        self.cycle = cycle
        self.createdAt = createdAt
        self.isActive = isActive
        self.overrides = overrides
    }

    /// Plain-value copy for `RotaEngine` and the widget.
    public var snapshot: PatternSnapshot {
        PatternSnapshot(id: id,
                        name: name,
                        startDate: startDate,
                        cycle: cycle,
                        overrides: overrides.map(\.snapshot))
    }
}
#endif
