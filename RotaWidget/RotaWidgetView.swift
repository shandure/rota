import SwiftUI
import WidgetKit
import RotaCore

/// Chooses the layout for the family, and blurs it with "Unlock in app" when not purchased (§4.6).
struct RotaWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: RotaEntry

    var body: some View {
        if entry.isUnlocked {
            content
        } else {
            content
                .blur(radius: 6)
                .overlay {
                    Text("Unlock in app")
                        .font(.headline)
                        .padding(.horizontal, Spacing.s12)
                        .padding(.vertical, Spacing.s8)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: Radius.cell))
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Rota widget. Unlock in app.")
        }
    }

    @ViewBuilder
    private var content: some View {
        if let day = entry.day {
            switch family {
            case .systemMedium:
                MediumWidgetView(patternName: entry.patternName ?? "", day: day)
            default:
                SmallWidgetView(day: day)
            }
        } else {
            Text("Set up your rota in the app")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

/// Small: date in caption, today's shift as a large pill, then "Next: Day · Fri".
struct SmallWidgetView: View {
    let day: WidgetDay

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s8) {
            Text(day.date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)))
                .font(Typography.weekday)
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
            ShiftPill(shift: day.today.shift)
            Spacer(minLength: 0)
            Text(nextText)
                .font(Typography.summary)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private var nextText: String {
        guard let next = day.next else { return "No shifts ahead" }
        return "Next: \(next.shift.displayName) · \(next.date.formatted(.dateTime.weekday(.abbreviated)))"
    }

    private var accessibilityText: String {
        var parts = [day.date.formatted(.dateTime.weekday(.wide).day().month(.wide)), day.today.shift.spokenName]
        if let times = day.today.shift.spokenTimeRange { parts.append(times) }
        parts.append(nextText.replacingOccurrences(of: " · ", with: ", "))
        return parts.joined(separator: ", ")
    }
}

/// Medium: pattern name top-left, then a 7-day strip starting today.
struct MediumWidgetView: View {
    let patternName: String
    let day: WidgetDay

    private let calendar = Calendar.current

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s8) {
            Text(patternName)
                .font(Typography.weekday.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
            HStack(spacing: Spacing.s4) {
                ForEach(day.week) { entry in
                    VStack(spacing: Spacing.s4) {
                        Text(RotaEngine.weekdayInitial(for: entry.date, calendar: calendar))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(String(calendar.component(.day, from: entry.date)))
                            .font(Typography.dateNumber)
                            .foregroundStyle(entry.date == day.date ? Color.primary : Color.secondary)
                        ZStack {
                            RoundedRectangle(cornerRadius: Radius.cell)
                                .fill(Palette.fill(for: entry.shift))
                            if entry.shift.isOff {
                                RoundedRectangle(cornerRadius: Radius.cell)
                                    .strokeBorder(Color.secondary.opacity(0.3))
                            }
                            Text(entry.shift.isOff ? "" : entry.shift.label)
                                .font(Typography.cellLabel)
                                .foregroundStyle(Palette.label(for: entry.shift))
                                .lineLimit(1)
                                .minimumScaleFactor(0.6)
                                .padding(.horizontal, 2)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: Spacing.s32 + Spacing.s4)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(entry.date.formatted(.dateTime.weekday(.wide).day())), \(entry.shift.spokenName)")
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

/// The large coloured pill with the shift label (§4.6 small widget, §6 radius 8).
struct ShiftPill: View {
    let shift: ShiftType

    var body: some View {
        Text(shift.displayName)
            .font(Typography.detailPill)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .foregroundStyle(shift.isOff ? Color.secondary : Palette.label(for: shift))
            .padding(.horizontal, Spacing.s12)
            .padding(.vertical, Spacing.s8)
            .frame(maxWidth: .infinity)
            .background(Palette.fill(for: shift), in: RoundedRectangle(cornerRadius: Radius.cell))
            .overlay {
                if shift.isOff {
                    RoundedRectangle(cornerRadius: Radius.cell).strokeBorder(Color.secondary.opacity(0.3))
                }
            }
    }
}
