import SwiftUI
import SwiftData
import UIKit
import RotaCore

/// One day: what the rota says, and the override controls (§4.3). Medium sheet.
/// Every change saves immediately; there is no save button.
struct DayDetailView: View {
    let date: Date
    let pattern: Pattern

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var note = ""

    private var calendar: Calendar { .current }
    private var day: Date { RotaEngine.canonicalDay(date, calendar: calendar) }

    /// The stored override for this day, if any.
    private var override: Override? {
        pattern.overrides.first { RotaEngine.canonicalDay($0.date, calendar: calendar) == day }
    }

    /// What the cycle alone gives for this day.
    private var cycleShift: ShiftType {
        let plain = PatternSnapshot(id: pattern.id, name: pattern.name, startDate: pattern.startDate, cycle: pattern.cycle)
        return RotaEngine.shift(on: day, for: plain, calendar: calendar)
    }

    private var currentShift: ShiftType { override?.shift ?? cycleShift }

    /// The pattern's distinct worked shift types in cycle order, then Off, Holiday, Sick.
    private var choices: [ShiftType] {
        var result: [ShiftType] = []
        for shift in pattern.cycle where !shift.isOff && !result.contains(where: { $0.isSameType(as: shift) }) {
            result.append(shift)
        }
        return result + [.off, .holiday, .sick]
    }

    private var trimmedNote: String? {
        let text = note.trimmingCharacters(in: .whitespacesAndNewlines)
        return text.isEmpty ? nil : text
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: Spacing.s16) {
                header
                OverrideChips(choices: choices, selected: currentShift) { select($0) }
                TextField("Swapped with Sam", text: $note)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: note) { _, value in
                        if value.count > Limits.maxNoteLength {
                            note = String(value.prefix(Limits.maxNoteLength))
                        } else {
                            applyNote()
                        }
                    }
                    .accessibilityLabel("Note")
                if override != nil {
                    Button("Reset to pattern") { reset() }
                        .font(.footnote)
                }
                Spacer(minLength: 0)
            }
            .padding(Spacing.screen)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear { note = override?.note ?? "" }
        }
        .presentationDetents([.medium])
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.s8) {
            Text(day.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                .font(.headline)
            Text(currentShift.pillText)
                .font(Typography.detailPill)
                .foregroundStyle(currentShift.isOff ? Color.secondary : Palette.label(for: currentShift))
                .padding(.horizontal, currentShift.isOff ? 0 : Spacing.s16)
                .padding(.vertical, currentShift.isOff ? 0 : Spacing.s12)
                .background(Palette.fill(for: currentShift), in: RoundedRectangle(cornerRadius: Radius.cell))
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: Actions

    /// Chip tap: an override exists exactly when the shift differs from the cycle or a note is set.
    private func select(_ shift: ShiftType) {
        if shift.isSameType(as: cycleShift) && trimmedNote == nil {
            deleteOverride()
        } else {
            upsert(shift: shift.isSameType(as: cycleShift) ? cycleShift : shift)
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        save()
    }

    private func applyNote() {
        if let existing = override {
            existing.note = trimmedNote
            if trimmedNote == nil && existing.shift.isSameType(as: cycleShift) {
                deleteOverride()
            }
        } else if trimmedNote != nil {
            upsert(shift: cycleShift)
        }
        save()
    }

    private func reset() {
        deleteOverride()
        note = ""
        save()
    }

    private func upsert(shift: ShiftType) {
        if let existing = override {
            existing.shift = shift
            existing.note = trimmedNote
        } else {
            context.insert(Override(date: day, shift: shift, note: trimmedNote, pattern: pattern))
        }
    }

    private func deleteOverride() {
        if let existing = override { context.delete(existing) }
    }

    private func save() {
        try? context.save()
    }
}
