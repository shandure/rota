import SwiftUI
import RotaCore

/// Chip row for overriding a day (§4.3): the pattern's shift types, then Off, Holiday and Sick.
/// The selected chip carries the same 2pt primary ring as today's cell in the month grid.
struct OverrideChips: View {
    let choices: [ShiftType]
    let selected: ShiftType
    let onSelect: (ShiftType) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.s8) {
                ForEach(choices, id: \.self) { shift in
                    let isSelected = shift.isSameType(as: selected)
                    Button {
                        onSelect(shift)
                    } label: {
                        Text(shift.displayName)
                            .font(Typography.cellLabel)
                            .lineLimit(1)
                            .padding(.horizontal, Spacing.s12)
                            .padding(.vertical, Spacing.s8)
                            .background(Palette.fill(for: shift), in: RoundedRectangle(cornerRadius: Radius.cell))
                            .overlay {
                                RoundedRectangle(cornerRadius: Radius.cell)
                                    .strokeBorder(isSelected ? Color.primary : (shift.isOff ? Color.secondary : Color.clear),
                                                  lineWidth: isSelected ? 2 : 1)
                            }
                            .foregroundStyle(shift.isOff ? Color.secondary : Palette.label(for: shift))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(isSelected ? "\(shift.spokenName), selected" : shift.spokenName)
                    .accessibilityHint(isSelected ? "" : "Changes this day to \(shift.spokenName)")
                }
            }
            .padding(.vertical, Spacing.s4)
        }
    }
}
