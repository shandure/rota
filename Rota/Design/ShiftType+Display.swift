import Foundation
import RotaCore

/// Presentation helpers for shifts: 24-hour times and VoiceOver wording.
extension ShiftType {
    /// "19:00–07:00", or nil for Off and all-day absences.
    var timeRangeText: String? {
        guard let start = startTime, let end = endTime else { return nil }
        return "\(Self.clock(start))–\(Self.clock(end))"
    }

    /// "19:00 to 07:00" for VoiceOver.
    var spokenTimeRange: String? {
        guard let start = startTime, let end = endTime else { return nil }
        return "\(Self.clock(start)) to \(Self.clock(end))"
    }

    /// "Night", "Off", "Holiday", "Sick", or the custom label: the name shown outside a grid cell.
    var displayName: String {
        if isOff { return "Off" }
        if isSameType(as: .holiday) { return "Holiday" }
        if isSameType(as: .sick) { return "Sick" }
        return label
    }

    /// "Night shift", "Off", "Holiday", "Sick", or the custom label.
    var spokenName: String {
        if isOff || isAbsence || kind == .custom { return displayName }
        return "\(label) shift"
    }

    /// Day Detail pill text: "Night · 19:00–07:00", or just the name for untimed shifts.
    var pillText: String {
        if let times = timeRangeText { return "\(displayName) · \(times)" }
        return displayName
    }

    private static func clock(_ components: DateComponents) -> String {
        String(format: "%02d:%02d", components.hour ?? 0, components.minute ?? 0)
    }
}
