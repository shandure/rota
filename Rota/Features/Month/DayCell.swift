import SwiftUI
import RotaCore

/// One day in the month grid (§4.1).
struct DayCell: View {
    let entry: DayShift
    let isToday: Bool
    let isInVisibleMonth: Bool
    let calendar: Calendar

    private var shift: ShiftType { entry.shift }
    private var dayNumber: String { String(calendar.component(.day, from: entry.date)) }

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: Radius.cell)
                .fill(Palette.fill(for: shift))

            Text(dayNumber)
                .font(Typography.dateNumber)
                .foregroundStyle(shift.isOff ? Color.secondary : Palette.label(for: shift))
                .padding(Spacing.s4)

            if !shift.isOff {
                Text(shift.label)
                    .font(Typography.cellLabel)
                    .foregroundStyle(Palette.label(for: shift))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, Spacing.s4)
            }

            if entry.isOverride {
                Circle()
                    .fill(Palette.dot(for: shift))
                    .frame(width: Spacing.s8, height: Spacing.s8)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(Spacing.s4)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .overlay {
            if isToday {
                RoundedRectangle(cornerRadius: Radius.cell)
                    .strokeBorder(Color.primary, lineWidth: 2)
            }
        }
        .opacity(isInVisibleMonth ? 1 : 0.3)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
        .accessibilityAddTraits(.isButton)
    }

    /// "Thursday 23 October, Night shift, 19:00 to 07:00"
    private var accessibilityText: String {
        var parts = [entry.date.formatted(.dateTime.weekday(.wide).day().month(.wide)), shift.spokenName]
        if let times = shift.spokenTimeRange { parts.append(times) }
        if isToday { parts.append("today") }
        return parts.joined(separator: ", ")
    }
}
