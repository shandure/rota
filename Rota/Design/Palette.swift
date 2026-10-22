import SwiftUI
import RotaCore

/// Shift colours (§6). Text and backgrounds use system semantic colours.
enum Palette {
    static let day = Color(hex: ShiftType.day.colorHex)
    static let night = Color(hex: ShiftType.night.colorHex)
    static let late = Color(hex: ShiftType.late.colorHex)
    static let early = Color(hex: ShiftType.early.colorHex)
    static let holiday = Color(hex: ShiftType.holiday.colorHex)
    static let sick = Color(hex: ShiftType.sick.colorHex)

    /// Fills whose white label fails contrast; they get black text instead (§6).
    private static let darkLabelFills: Set<String> = ["#FFD43B", "#38D9A9"]

    /// Cell / pill fill. Off days have no fill.
    static func fill(for shift: ShiftType) -> Color {
        shift.isOff ? .clear : Color(hex: shift.colorHex)
    }

    /// Label colour on top of `fill(for:)`.
    static func label(for shift: ShiftType) -> Color {
        darkLabelFills.contains(shift.colorHex.uppercased()) ? .black : .white
    }

    /// The override dot colour; an Off override has no shift colour so uses secondary.
    static func dot(for shift: ShiftType) -> Color {
        shift.isOff ? .secondary : Color(hex: shift.colorHex)
    }
}

extension Color {
    /// Parses "#RRGGBB" (sRGB). Unparseable input yields clear.
    init(hex: String) {
        var text = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.hasPrefix("#") { text.removeFirst() }
        guard text.count == 6, let value = UInt64(text, radix: 16) else {
            self = .clear
            return
        }
        self.init(.sRGB,
                  red: Double((value >> 16) & 0xFF) / 255,
                  green: Double((value >> 8) & 0xFF) / 255,
                  blue: Double(value & 0xFF) / 255,
                  opacity: 1)
    }
}
