import Foundation

/// The category of a shift. `custom` is used for user-defined types and for
/// the built-in Holiday and Sick absences (§4.3).
public enum ShiftKind: String, Codable, CaseIterable, Sendable {
    case day, night, late, early, off, custom
}
