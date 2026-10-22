import SwiftUI
import RotaCore

/// The next 14 days as a compact strip of coloured cells with weekday initials (§4.2 step 6).
/// This is the trust moment: it is what stops people getting the start date wrong.
struct PreviewStrip: View {
    let entries: [DayShift]
    let calendar: Calendar

    private static let cellWidth: CGFloat = 40
    private static let cellHeight: CGFloat = 44

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.s4) {
                ForEach(entries) { entry in
                    VStack(spacing: Spacing.s4) {
                        Text(RotaEngine.weekdayInitial(for: entry.date, calendar: calendar))
                            .font(Typography.weekday)
                            .foregroundStyle(.secondary)
                        ZStack {
                            RoundedRectangle(cornerRadius: Radius.cell)
                                .fill(Palette.fill(for: entry.shift))
                            VStack(spacing: 0) {
                                Text(String(calendar.component(.day, from: entry.date)))
                                    .font(Typography.dateNumber)
                                if !entry.shift.isOff {
                                    Text(entry.shift.label)
                                        .font(Typography.cellLabel)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.7)
                                }
                            }
                            .foregroundStyle(entry.shift.isOff ? Color.secondary : Palette.label(for: entry.shift))
                            .padding(.horizontal, Spacing.s4)
                        }
                        .frame(width: Self.cellWidth, height: Self.cellHeight)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(accessibilityText(for: entry))
                }
            }
            .padding(.vertical, Spacing.s4)
        }
    }

    private func accessibilityText(for entry: DayShift) -> String {
        "\(entry.date.formatted(.dateTime.weekday(.wide).day().month(.wide))), \(entry.shift.spokenName)"
    }
}
