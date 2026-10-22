import Foundation

/// One kind of shift as it appears in a cycle or an override (§3).
///
/// Times are stored as minutes after midnight (`startMinute` / `endMinute`) because SwiftData
/// cannot persist `DateComponents` inside a struct. `startTime` / `endTime` expose them as the
/// spec's hour+minute components.
public struct ShiftType: Codable, Hashable, Sendable {
    public var kind: ShiftKind
    /// "Day", "Night", "Off", or user text for `.custom` (max `Limits.maxCustomLabelLength`).
    public var label: String
    public var colorHex: String
    /// Minutes after midnight. `nil` for `.off` and for all-day absences.
    public var startMinute: Int?
    /// Minutes after midnight. May be less than or equal to `startMinute`, meaning the shift crosses midnight.
    public var endMinute: Int?

    public init(kind: ShiftKind,
                label: String,
                colorHex: String,
                startTime: DateComponents? = nil,
                endTime: DateComponents? = nil) {
        self.kind = kind
        self.label = label
        self.colorHex = colorHex
        self.startMinute = startTime.flatMap(Self.minutes)
        self.endMinute = endTime.flatMap(Self.minutes)
    }

    /// Hour + minute. `nil` for `.off` and for all-day absences.
    public var startTime: DateComponents? {
        get { startMinute.map(Self.components) }
        set { startMinute = newValue.flatMap(Self.minutes) }
    }

    /// Hour + minute. May be earlier than `startTime`, meaning the shift crosses midnight.
    public var endTime: DateComponents? {
        get { endMinute.map(Self.components) }
        set { endMinute = newValue.flatMap(Self.minutes) }
    }

    /// Builds an hour+minute component for `startTime` / `endTime`.
    public static func time(_ hour: Int, _ minute: Int = 0) -> DateComponents {
        DateComponents(hour: hour, minute: minute)
    }

    private static func minutes(_ components: DateComponents) -> Int? {
        guard let hour = components.hour else { return nil }
        return hour * 60 + (components.minute ?? 0)
    }

    private static func components(_ minutes: Int) -> DateComponents {
        DateComponents(hour: minutes / 60, minute: minutes % 60)
    }

    // MARK: Derived

    public var isOff: Bool { kind == .off }

    /// Holiday and Sick are stored as `.custom` overrides but are not worked shifts.
    public var isAbsence: Bool {
        kind == .custom && (label == ShiftType.holiday.label || label == ShiftType.sick.label)
    }

    /// True for anything the user actually turns up for. Drives summary counts
    /// and the widget's "Next:" line.
    public var isWorked: Bool { !isOff && !isAbsence }

    /// Same kind and label, ignoring times and colour. Used to match an override against the
    /// cycle's shift and to pick the selected chip in Day Detail.
    public func isSameType(as other: ShiftType) -> Bool {
        kind == other.kind && label == other.label
    }

    /// True when the end is not after the start (e.g. Night 19:00–07:00).
    public var crossesMidnight: Bool {
        guard let start = startMinute, let end = endMinute else { return false }
        return end <= start
    }

    // MARK: Built-ins (§4.2 defaults, §6 palette)

    public static let day = ShiftType(kind: .day, label: "Day", colorHex: "#FFA94D",
                                      startTime: time(7), endTime: time(19))
    public static let night = ShiftType(kind: .night, label: "Night", colorHex: "#4C6EF5",
                                        startTime: time(19), endTime: time(7))
    public static let late = ShiftType(kind: .late, label: "Late", colorHex: "#F783AC",
                                       startTime: time(13), endTime: time(21))
    public static let early = ShiftType(kind: .early, label: "Early", colorHex: "#38D9A9",
                                        startTime: time(6), endTime: time(14))
    public static let off = ShiftType(kind: .off, label: "Off", colorHex: "")
    public static let holiday = ShiftType(kind: .custom, label: "HOL", colorHex: "#9775FA")
    public static let sick = ShiftType(kind: .custom, label: "SICK", colorHex: "#868E96")

    /// Colours a user-defined custom type may pick from (§6).
    public static let customPalette = ["#FF6B6B", "#FFD43B", "#69DB7C", "#4DABF7"]
}
