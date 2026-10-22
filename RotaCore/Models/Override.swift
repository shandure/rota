import Foundation

#if canImport(SwiftData)
import SwiftData

/// Replaces the cycle's shift on one date (holiday, swap, sick) (§3).
@Model
public final class Override {
    public var id: UUID
    /// Start of day.
    public var date: Date
    public var shift: ShiftType
    /// Max `Limits.maxNoteLength` chars.
    public var note: String?
    public var pattern: Pattern?

    public init(id: UUID = UUID(),
                date: Date,
                shift: ShiftType,
                note: String? = nil,
                pattern: Pattern? = nil) {
        self.id = id
        self.date = date
        self.shift = shift
        self.note = note
        self.pattern = pattern
    }

    public var snapshot: OverrideSnapshot {
        OverrideSnapshot(id: id, date: date, shift: shift, note: note)
    }
}
#endif
