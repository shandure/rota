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

    /// "Night shift", "Off", "Holiday", "Sick", or the custom label.
    var spokenName: String {
        if isOff { return "Off" }
        if self == .holiday { return "Holiday" }
        if self == .sick { return "Sick" }
        return kind == .custom ? label : "\(label) shift"
    }

    private static func clock(_ components: DateComponents) -> String {
        String(format: "%02d:%02d", components.hour ?? 0, components.minute ?? 0)
    }
}
