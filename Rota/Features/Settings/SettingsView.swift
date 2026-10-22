import SwiftUI
import SwiftData
import RotaCore

/// Settings (§4.4). A plain list; presented as a sheet from the month screen's gear.
struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: Pattern.listOrder) private var patterns: [Pattern]
    @Environment(PurchaseManager.self) private var purchases
    @Environment(CalendarSync.self) private var calendarSync

    @State private var paywall: PaywallTrigger?
    @State private var editingPattern: Pattern?

    private var isUnlocked: Bool { purchases.isUnlocked }

    var body: some View {
        NavigationStack {
            List {
                patternsSection
                CalendarSyncSection(isUnlocked: isUnlocked) { paywall = .calendar }
                widgetSection
                unlockSection
                AboutSection()
            }
            .onAppear {
                if DemoData.opensPaywall { paywall = .settings }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .fullScreenCover(item: $paywall) { trigger in
                PaywallView(trigger: trigger)
            }
            .sheet(item: $editingPattern) { pattern in
                PatternBuilderView(mode: .edit(pattern))
            }
        }
    }

    // MARK: Patterns

    private var patternsSection: some View {
        Section {
            ForEach(patterns) { pattern in
                Button {
                    activate(pattern)
                } label: {
                    HStack {
                        Text(pattern.name)
                        Spacer()
                        if pattern.isActive {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Color.accentColor)
                                .accessibilityHidden(true)
                        }
                    }
                }
                .foregroundStyle(.primary)
                .accessibilityLabel(pattern.isActive ? "\(pattern.name), active" : pattern.name)
                .accessibilityHint(pattern.isActive ? "" : "Makes this the active pattern")
                .swipeActions(edge: .leading) {
                    Button("Edit") { editingPattern = pattern }
                        .tint(.accentColor)
                }
            }
            .onDelete(perform: delete)
            .onMove(perform: move)

            if patterns.isEmpty {
                Text("No patterns yet")
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Patterns")
        } footer: {
            if !patterns.isEmpty {
                Text("Tap to switch. Swipe right to edit, left to delete.")
            }
        }
    }

    private func activate(_ pattern: Pattern) {
        for p in patterns { p.isActive = (p.persistentModelID == pattern.persistentModelID) }
        try? context.save()
        WidgetReloader.reload()
        calendarSync.dataChanged()
    }

    private func delete(at offsets: IndexSet) {
        let doomed = offsets.map { patterns[$0] }
        let deletingActive = doomed.contains { $0.isActive }
        for pattern in doomed { context.delete(pattern) }
        if deletingActive, let next = patterns.first(where: { p in !doomed.contains { $0.persistentModelID == p.persistentModelID } }) {
            next.isActive = true
        }
        try? context.save()
        WidgetReloader.reload()
        calendarSync.dataChanged()
    }

    private func move(from source: IndexSet, to destination: Int) {
        var ordered = patterns
        ordered.move(fromOffsets: source, toOffset: destination)
        for (index, pattern) in ordered.enumerated() { pattern.sortOrder = index }
        try? context.save()
        WidgetReloader.reload()
    }

    // MARK: Widget

    private var widgetSection: some View {
        Section("Widget") {
            if isUnlocked {
                NavigationLink("Add the widget") { WidgetExplainerView() }
            } else {
                Button("Add the widget") { paywall = .widget }
                    .foregroundStyle(.primary)
                    .accessibilityHint("Requires the unlock")
            }
        }
    }

    // MARK: Unlock

    private var unlockSection: some View {
        Section {
            if isUnlocked {
                Label("Unlocked, thank you.", systemImage: "checkmark.seal")
            } else {
                Button("Unlock everything — \(purchases.priceText)") { paywall = .settings }
                    .foregroundStyle(.primary)
            }
        }
    }
}
