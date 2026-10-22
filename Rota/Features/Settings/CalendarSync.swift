import Foundation
import SwiftData
import RotaCore

/// Owns the "Add shifts to Calendar" preference and keeps the active pattern's calendar in
/// step with the data (§4.4). Injected from `RotaApp`; views call `dataChanged()` after saves.
@MainActor
@Observable
final class CalendarSync {
    static let enabledKey = "calendarSyncEnabled"

    private let container: ModelContainer
    private let exporter: CalendarExporter
    private let defaults = UserDefaults.standard

    private(set) var isEnabled: Bool
    private(set) var isWorking = false
    private(set) var lastError: String?

    init(container: ModelContainer, exporter: CalendarExporter = CalendarExporter()) {
        self.container = container
        self.exporter = exporter
        isEnabled = defaults.bool(forKey: Self.enabledKey)
    }

    /// Requests access and writes the active pattern. Returns false if access was refused.
    func enable() async -> Bool {
        lastError = nil
        guard await exporter.requestAccess() else {
            lastError = "Calendar access was not allowed. You can allow it in Settings, Privacy & Security, Calendars."
            Analytics.track(.calendarSyncToggled(on: true, permissionGranted: false))
            return false
        }
        Analytics.track(.calendarSyncToggled(on: true, permissionGranted: true))
        setEnabled(true)
        await resync()
        return lastError == nil
    }

    /// Deletes the app's calendars and turns the preference off.
    func disable() {
        lastError = nil
        Analytics.track(.calendarSyncToggled(on: false, permissionGranted: exporter.hasAccess))
        setEnabled(false)
        do {
            try exporter.removeCalendars(except: nil)
        } catch {
            lastError = error.localizedDescription
        }
    }

    /// Call after any pattern or override change. No-op unless sync is on.
    func dataChanged() {
        guard isEnabled else { return }
        Task { await resync() }
    }

    // MARK: Private

    private func setEnabled(_ value: Bool) {
        isEnabled = value
        defaults.set(value, forKey: Self.enabledKey)
    }

    private func resync() async {
        isWorking = true
        defer { isWorking = false }
        let active = activePattern()
        do {
            try exporter.removeCalendars(except: active?.id)
            if let active {
                try exporter.sync(active, from: Calendar.current.startOfDay(for: .now))
            }
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func activePattern() -> PatternSnapshot? {
        let descriptor = FetchDescriptor<Pattern>(sortBy: Pattern.listOrder)
        guard let patterns = try? container.mainContext.fetch(descriptor) else { return nil }
        return (patterns.first { $0.isActive } ?? patterns.first)?.snapshot
    }
}
