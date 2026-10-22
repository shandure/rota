import XCTest
import RotaCore

#if canImport(EventKit)
import EventKit

/// Writes real events into the simulator's calendar store (CI grants access with
/// `simctl privacy grant calendar`). Skips when access is not granted.
@MainActor
final class CalendarExporterTests: XCTestCase {
    private var exporter: CalendarExporter!
    private var defaults: UserDefaults!
    private var strangerCalendar: EKCalendar?

    override func setUp() async throws {
        defaults = UserDefaults(suiteName: "rota.calendar.tests")!
        defaults.removePersistentDomain(forName: "rota.calendar.tests")
        exporter = CalendarExporter(store: EKEventStore(), defaults: defaults)
        guard await exporter.requestAccess() else {
            throw XCTSkip("Calendar access not granted on this simulator")
        }
    }

    override func tearDown() async throws {
        if let strangerCalendar {
            try? exporter.store.removeCalendar(strangerCalendar, commit: true)
        }
        try? exporter.removeCalendars(except: nil)
    }

    func testSyncRewriteAndRemoveNeverTouchOtherCalendars() throws {
        let store = exporter.store
        let cal = Fixtures.london
        let today = Fixtures.day(2026, 1, 1)
        let window = DateInterval(start: today, end: Fixtures.day(2026, 2, 1))

        // A calendar the user made themselves, with the same name as the pattern.
        let stranger = EKCalendar(for: .event, eventStore: store)
        stranger.title = "Ward 7"
        stranger.source = store.defaultCalendarForNewEvents?.source ?? store.sources.first { $0.sourceType == .local }!
        try store.saveCalendar(stranger, commit: true)
        strangerCalendar = stranger
        let dentist = EKEvent(eventStore: store)
        dentist.calendar = stranger
        dentist.title = "Dentist"
        dentist.startDate = Fixtures.day(2026, 1, 7).addingTimeInterval(10 * 3600)
        dentist.endDate = dentist.startDate.addingTimeInterval(3600)
        try store.save(dentist, span: .thisEvent, commit: true)

        // First sync.
        var pattern = Fixtures.pattern()
        try exporter.sync(pattern, from: today, calendar: cal)
        let ours = try XCTUnwrap(exporter.existingCalendar(for: pattern.id))
        XCTAssertNotEqual(ours.calendarIdentifier, stranger.calendarIdentifier, "must create its own calendar, not reuse the stranger's")
        XCTAssertEqual(ours.title, "Ward 7")

        var january = exporter.ownEvents(in: window, of: pattern.id, calendar: ours)
        XCTAssertEqual(january.count, 15)
        let night = try XCTUnwrap(january.first { $0.title == "Ward 7 · Night" && cal.isDate($0.startDate, inSameDayAs: Fixtures.day(2026, 1, 7)) })
        XCTAssertEqual(night.endDate, Fixtures.day(2026, 1, 8).addingTimeInterval(7 * 3600))
        XCTAssertFalse(night.isAllDay)

        // Change an override and rename the pattern: events are rewritten, not duplicated.
        pattern.overrides = [OverrideSnapshot(date: Fixtures.day(2026, 1, 5), shift: .holiday)]
        pattern.name = "Ward 8"
        try exporter.sync(pattern, from: today, calendar: cal)
        let renamed = try XCTUnwrap(exporter.existingCalendar(for: pattern.id))
        XCTAssertEqual(renamed.calendarIdentifier, ours.calendarIdentifier)
        XCTAssertEqual(renamed.title, "Ward 8")
        january = exporter.ownEvents(in: window, of: pattern.id, calendar: renamed)
        XCTAssertEqual(january.count, 15)   // holiday replaced a day shift
        let holiday = try XCTUnwrap(january.first { $0.title == "Holiday" })
        XCTAssertTrue(holiday.isAllDay)
        XCTAssertTrue(january.filter { $0.title.hasPrefix("Ward 7") }.isEmpty, "old titles rewritten")

        // The stranger's event is untouched throughout.
        let strangerEvents = store.events(matching: store.predicateForEvents(withStart: window.start, end: window.end, calendars: [stranger]))
        XCTAssertEqual(strangerEvents.map(\.title), ["Dentist"])

        // Turn off: our calendar goes, the stranger's stays.
        try exporter.removeCalendar(for: pattern.id)
        XCTAssertNil(exporter.existingCalendar(for: pattern.id))
        XCTAssertNil(store.calendar(withIdentifier: ours.calendarIdentifier))
        XCTAssertNotNil(store.calendar(withIdentifier: stranger.calendarIdentifier))
        let stillThere = store.events(matching: store.predicateForEvents(withStart: window.start, end: window.end, calendars: [stranger]))
        XCTAssertEqual(stillThere.map(\.title), ["Dentist"])
    }
}
#endif
