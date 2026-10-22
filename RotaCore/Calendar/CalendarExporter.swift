import Foundation

#if canImport(EventKit)
import EventKit

/// Writes a pattern's shifts to a calendar of its own (§4.4, §5).
///
/// The app's calendar for each pattern is remembered by its EventKit identifier in the App
/// Group defaults. The exporter only ever deletes that calendar and events carrying its own
/// `rota://` URL, so a user's existing calendar that happens to share the name is never touched.
public final class CalendarExporter {
    public enum ExporterError: LocalizedError {
        case accessDenied
        case noCalendarSource

        public var errorDescription: String? {
            switch self {
            case .accessDenied: return "Calendar access was not allowed."
            case .noCalendarSource: return "No calendar account is available to write to."
            }
        }
    }

    private static let calendarIDsKey = "calendarIDsByPattern"

    public let store: EKEventStore
    private let defaults: UserDefaults

    public init(store: EKEventStore = EKEventStore(),
                defaults: UserDefaults = UserDefaults(suiteName: AppGroup.id) ?? .standard) {
        self.store = store
        self.defaults = defaults
    }

    // MARK: Access

    public var hasAccess: Bool {
        EKEventStore.authorizationStatus(for: .event) == .fullAccess
    }

    /// Asks for full calendar access (needed to create a calendar and delete our own events).
    public func requestAccess() async -> Bool {
        if hasAccess { return true }
        return (try? await store.requestFullAccessToEvents()) ?? false
    }

    // MARK: Sync

    /// Rewrites `pattern`'s events from `today` for the next 12 months. One commit at the end.
    public func sync(_ pattern: PatternSnapshot, from today: Date, calendar: Calendar = .current) throws {
        guard hasAccess else { throw ExporterError.accessDenied }
        let ekCalendar = try ensureCalendar(for: pattern)

        let window = CalendarPlanner.interval(from: today, calendar: calendar)
        for event in ownEvents(in: window, of: pattern.id, calendar: ekCalendar) {
            try store.remove(event, span: .thisEvent, commit: false)
        }
        for planned in CalendarPlanner.events(for: pattern, from: today, calendar: calendar) {
            let event = EKEvent(eventStore: store)
            event.calendar = ekCalendar
            event.title = planned.title
            event.startDate = planned.start
            event.endDate = planned.end
            event.isAllDay = planned.isAllDay
            event.url = planned.url
            try store.save(event, span: .thisEvent, commit: false)
        }
        try store.commit()
    }

    /// Deletes the app's calendar for `patternID`, if it made one. Other calendars are never touched.
    public func removeCalendar(for patternID: UUID) throws {
        var ids = calendarIDs
        defer {
            ids.removeValue(forKey: patternID.uuidString)
            calendarIDs = ids
        }
        guard let ekCalendar = existingCalendar(for: patternID) else { return }
        try store.removeCalendar(ekCalendar, commit: true)
    }

    /// Deletes every calendar the app made except the one for `keep`.
    public func removeCalendars(except keep: UUID?) throws {
        for key in calendarIDs.keys {
            guard let id = UUID(uuidString: key), id != keep else { continue }
            try removeCalendar(for: id)
        }
    }

    /// The app's own calendar for `patternID`, if it still exists.
    public func existingCalendar(for patternID: UUID) -> EKCalendar? {
        guard let identifier = calendarIDs[patternID.uuidString] else { return nil }
        return store.calendar(withIdentifier: identifier)
    }

    /// Events in `window` that the app wrote for `patternID`.
    public func ownEvents(in window: DateInterval, of patternID: UUID, calendar: EKCalendar) -> [EKEvent] {
        let predicate = store.predicateForEvents(withStart: window.start, end: window.end, calendars: [calendar])
        return store.events(matching: predicate).filter { CalendarPlanner.patternID(from: $0.url) == patternID }
    }

    // MARK: Private

    private var calendarIDs: [String: String] {
        get { defaults.dictionary(forKey: Self.calendarIDsKey) as? [String: String] ?? [:] }
        set { defaults.set(newValue, forKey: Self.calendarIDsKey) }
    }

    /// Finds the app's calendar for the pattern, renaming it if the pattern was renamed, or creates it.
    private func ensureCalendar(for pattern: PatternSnapshot) throws -> EKCalendar {
        if let existing = existingCalendar(for: pattern.id) {
            if existing.title != pattern.name {
                existing.title = pattern.name
                try store.saveCalendar(existing, commit: true)
            }
            return existing
        }
        let created = EKCalendar(for: .event, eventStore: store)
        created.title = pattern.name
        created.source = try preferredSource()
        try store.saveCalendar(created, commit: true)
        var ids = calendarIDs
        ids[pattern.id.uuidString] = created.calendarIdentifier
        calendarIDs = ids
        return created
    }

    private func preferredSource() throws -> EKSource {
        if let source = store.defaultCalendarForNewEvents?.source, source.sourceType != .birthdays, source.sourceType != .subscribed {
            return source
        }
        if let iCloud = store.sources.first(where: { $0.sourceType == .calDAV && $0.title.lowercased().contains("icloud") }) {
            return iCloud
        }
        if let local = store.sources.first(where: { $0.sourceType == .local }) {
            return local
        }
        throw ExporterError.noCalendarSource
    }
}
#endif
