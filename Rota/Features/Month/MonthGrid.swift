import SwiftUI
import RotaCore

/// Weekday initials plus the 7-column, 6-row day grid for one month (§4.1).
struct MonthGrid: View {
    let month: Date
    let entries: [DayShift]
    let today: Date
    let calendar: Calendar
    let onSelect: (DayShift) -> Void

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: Spacing.gridGap), count: 7)
    }

    var body: some View {
        VStack(spacing: Spacing.s8) {
            HStack(spacing: Spacing.gridGap) {
                ForEach(Array(RotaEngine.weekdayInitials(calendar: calendar).enumerated()), id: \.offset) { _, initial in
                    Text(initial)
                        .font(Typography.weekday)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .accessibilityHidden(true)

            LazyVGrid(columns: columns, spacing: Spacing.gridGap) {
                ForEach(entries, id: \.date) { entry in
                    Button {
                        onSelect(entry)
                    } label: {
                        DayCell(entry: entry,
                                isToday: calendar.isDate(entry.date, inSameDayAs: today),
                                isInVisibleMonth: calendar.isDate(entry.date, equalTo: month, toGranularity: .month),
                                calendar: calendar)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .dynamicTypeSize(...Typography.gridMaxDynamicType)
    }
}
