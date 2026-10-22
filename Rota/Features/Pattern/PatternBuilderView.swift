import SwiftUI
import SwiftData
import RotaCore

/// Create or edit a pattern (§4.2). Presented as a `.large` sheet.
struct PatternBuilderView: View {
    enum Mode: Identifiable {
        case create
        case edit(Pattern)

        var id: String {
            switch self {
            case .create: return "create"
            case .edit(let pattern): return pattern.id.uuidString
            }
        }
    }

    let mode: Mode

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Pattern.createdAt) private var patterns: [Pattern]

    @State private var name: String
    @State private var cells: [CycleCell]
    @State private var startDate: Date
    @State private var showingTimes = false
    @State private var showingCustomSheet = false
    @State private var confirmingDelete = false
    @FocusState private var nameFocused: Bool

    private var calendar: Calendar { .current }
    private var today: Date { calendar.startOfDay(for: .now) }

    init(mode: Mode) {
        self.mode = mode
        switch mode {
        case .create:
            _name = State(initialValue: "")
            _cells = State(initialValue: [])
            _startDate = State(initialValue: Calendar.current.startOfDay(for: .now))
        case .edit(let pattern):
            _name = State(initialValue: pattern.name)
            _cells = State(initialValue: pattern.cycle.map { CycleCell(shift: $0) })
            _startDate = State(initialValue: pattern.startDate)
        }
    }

    // MARK: Derived

    private var isCreate: Bool { if case .create = mode { return true } else { return false } }
    private var editingPattern: Pattern? { if case .edit(let p) = mode { return p } else { return nil } }
    private var cycle: [ShiftType] { cells.map(\.shift) }
    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var canSave: Bool { !trimmedName.isEmpty && !cells.isEmpty }

    private var selectedPreset: Preset? {
        if let match = Preset.matching(cycle) { return match }
        return cells.isEmpty ? nil : .custom
    }

    /// Distinct timed shift types in the cycle, in first-appearance order.
    private var timedTypes: [ShiftType] {
        var seen: [ShiftType] = []
        for shift in cycle where !shift.isOff && !seen.contains(where: { $0.kind == shift.kind && $0.label == shift.label }) {
            seen.append(shift)
        }
        return seen
    }

    private var previewEntries: [DayShift] {
        let snapshot = PatternSnapshot(name: trimmedName,
                                       startDate: calendar.startOfDay(for: startDate),
                                       cycle: cycle)
        return RotaEngine.shifts(in: RotaEngine.previewInterval(from: today, calendar: calendar),
                                 for: snapshot, calendar: calendar)
    }

    // MARK: Body

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Ward 7", text: $name)
                        .focused($nameFocused)
                        .textInputAutocapitalization(.words)
                        .onChange(of: name) { _, value in
                            if value.count > Limits.maxPatternNameLength {
                                name = String(value.prefix(Limits.maxPatternNameLength))
                            }
                        }
                }

                Section("Start from a preset") {
                    PresetChips(selected: selectedPreset) { apply($0) }
                        .listRowInsets(EdgeInsets())
                }

                Section("Cycle") {
                    CycleEditor(cells: $cells) { showingCustomSheet = true }
                        .padding(.vertical, Spacing.s4)
                }

                Section {
                    DisclosureGroup("Shift times", isExpanded: $showingTimes) {
                        if timedTypes.isEmpty {
                            Text("Add a shift to the cycle first.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        ForEach(timedTypes, id: \.self) { shift in
                            timeRow(for: shift)
                        }
                    }
                } footer: {
                    Text("Used for the Calendar export and the widget. Shifts that end before they start cross midnight.")
                }

                Section("Start date") {
                    DatePicker("Pattern started", selection: $startDate, displayedComponents: .date)
                    Text("Pick any date you know the pattern's first day fell on.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Preview: next 14 days") {
                    if cells.isEmpty {
                        Text("Add shifts to the cycle to see a preview.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        PreviewStrip(entries: previewEntries, calendar: calendar)
                            .listRowInsets(EdgeInsets(top: Spacing.s4, leading: Spacing.screen, bottom: Spacing.s4, trailing: 0))
                    }
                }

                if let pattern = editingPattern {
                    Section {
                        Button("Delete pattern", role: .destructive) { confirmingDelete = true }
                            .frame(maxWidth: .infinity)
                            .confirmationDialog("Delete \(pattern.name)?",
                                                isPresented: $confirmingDelete,
                                                titleVisibility: .visible) {
                                Button("Delete pattern", role: .destructive) { delete(pattern) }
                            } message: {
                                Text("Its overrides and notes are deleted too.")
                            }
                    }
                }
            }
            .navigationTitle(isCreate ? "New pattern" : "Edit pattern")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                }
            }
            .sheet(isPresented: $showingCustomSheet) {
                CustomShiftSheet { shift in
                    if cells.count < Limits.maxCycleLength { cells.append(CycleCell(shift: shift)) }
                }
            }
            .onAppear {
                if isCreate { nameFocused = true }
            }
        }
        .presentationDetents([.large])
    }

    // MARK: Shift times

    private func timeRow(for shift: ShiftType) -> some View {
        HStack(spacing: Spacing.s8) {
            Text(shift.label)
                .frame(minWidth: Spacing.s32 + Spacing.s16, alignment: .leading)
            Spacer(minLength: 0)
            DatePicker("\(shift.label) start",
                       selection: timeBinding(for: shift, keyPath: \.startMinute, fallback: 9 * 60),
                       displayedComponents: .hourAndMinute)
                .labelsHidden()
            Text("to").foregroundStyle(.secondary)
            DatePicker("\(shift.label) end",
                       selection: timeBinding(for: shift, keyPath: \.endMinute, fallback: 17 * 60),
                       displayedComponents: .hourAndMinute)
                .labelsHidden()
        }
    }

    /// Binds a `DatePicker` to the minutes-after-midnight of every cell of this shift type.
    private func timeBinding(for shift: ShiftType,
                             keyPath: WritableKeyPath<ShiftType, Int?>,
                             fallback: Int) -> Binding<Date> {
        Binding {
            let minutes = cells.first { $0.shift.kind == shift.kind && $0.shift.label == shift.label }?.shift[keyPath: keyPath] ?? fallback
            return calendar.date(bySettingHour: minutes / 60, minute: minutes % 60, second: 0, of: today) ?? today
        } set: { date in
            let components = calendar.dateComponents([.hour, .minute], from: date)
            let minutes = (components.hour ?? 0) * 60 + (components.minute ?? 0)
            for index in cells.indices where cells[index].shift.kind == shift.kind && cells[index].shift.label == shift.label {
                cells[index].shift[keyPath: keyPath] = minutes
            }
        }
    }

    // MARK: Actions

    private func apply(_ preset: Preset) {
        cells = preset.cycle.map { CycleCell(shift: $0) }
    }

    private func save() {
        let day = calendar.startOfDay(for: startDate)
        switch mode {
        case .create:
            // Second-pattern paywall gate arrives in Step 6.
            let pattern = Pattern(name: trimmedName, startDate: day, cycle: cycle, createdAt: .now, isActive: true)
            for existing in patterns { existing.isActive = false }
            context.insert(pattern)
        case .edit(let pattern):
            pattern.name = trimmedName
            pattern.startDate = day
            pattern.cycle = cycle
            // Overrides are untouched (§4.2: saving an edited pattern keeps existing overrides).
        }
        try? context.save()
        dismiss()
    }

    private func delete(_ pattern: Pattern) {
        let wasActive = pattern.isActive
        context.delete(pattern)
        if wasActive, let next = patterns.first(where: { $0.persistentModelID != pattern.persistentModelID }) {
            next.isActive = true
        }
        try? context.save()
        dismiss()
    }
}
