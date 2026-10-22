import XCTest
import RotaCore

/// Calendar export planning (§5): titles, timed vs all-day, nights ending next day, URLs, DST.
final class CalendarPlannerTests: XCTestCase {
    let cal = Fixtures.london

    private func januaryEvents(overrides: [OverrideSnapshot] = []) -> [PlannedEvent] {
        let p = Fixtures.pattern(overrides: overrides)
        return CalendarPlanner.events(for: p, from: Fixtures.day(2026, 1, 1), months: 1, calendar: cal)
    }

    func testOffDaysProduceNoEventAndWorkedDaysOneEach() {
        let events = januaryEvents()
        XCTAssertEqual(events.count, 15)   // 8 days + 7 nights in January (see CycleTests)
        XCTAssertFalse(events.contains { Fixtures.ymd($0.day) == [2026, 1, 9] })   // an off day
    }

    func testDayShiftIsTimedWithinItsDay() {
        let event = januaryEvents().first { Fixtures.ymd($0.day) == [2026, 1, 5] }!
        XCTAssertEqual(event.title, "Ward 7 · Day")
        XCTAssertFalse(event.isAllDay)
        XCTAssertEqual(event.start, Fixtures.day(2026, 1, 5).addingTimeInterval(7 * 3600))
        XCTAssertEqual(event.end, Fixtures.day(2026, 1, 5).addingTimeInterval(19 * 3600))
    }

    func testNightShiftEndsTheNextDay() {
        let event = januaryEvents().first { Fixtures.ymd($0.day) == [2026, 1, 7] }!
        XCTAssertEqual(event.title, "Ward 7 · Night")
        XCTAssertEqual(event.start, Fixtures.day(2026, 1, 7).addingTimeInterval(19 * 3600))
        XCTAssertEqual(event.end, Fixtures.day(2026, 1, 8).addingTimeInterval(7 * 3600))
        XCTAssertEqual(Fixtures.ymd(event.day), [2026, 1, 7], "belongs to the day it starts on")
    }

    func testHolidayAndSickAreAllDay() {
        let events = januaryEvents(overrides: [
            OverrideSnapshot(date: Fixtures.day(2026, 1, 5), shift: .holiday),
            OverrideSnapshot(date: Fixtures.day(2026, 1, 9), shift: .sick),     // was an off day
        ])
        let holiday = events.first { Fixtures.ymd($0.day) == [2026, 1, 5] }!
        XCTAssertEqual(holiday.title, "Holiday")
        XCTAssertTrue(holiday.isAllDay)
        XCTAssertEqual(holiday.start, Fixtures.day(2026, 1, 5))
        XCTAssertEqual(holiday.end, Fixtures.day(2026, 1, 6))

        let sick = events.first { Fixtures.ymd($0.day) == [2026, 1, 9] }!
        XCTAssertEqual(sick.title, "Sick")
        XCTAssertTrue(sick.isAllDay)
        XCTAssertEqual(events.count, 16)   // 15 worked minus the holiday, plus holiday and sick
    }

    func testOverrideToOffRemovesTheEvent() {
        let events = januaryEvents(overrides: [OverrideSnapshot(date: Fixtures.day(2026, 1, 5), shift: .off)])
        XCTAssertEqual(events.count, 14)
        XCTAssertNil(events.first { Fixtures.ymd($0.day) == [2026, 1, 5] })
    }

    func testEventURLRoundTrip() {
        let p = Fixtures.pattern()
        let url = CalendarPlanner.eventURL(patternID: p.id, day: Fixtures.day(2026, 10, 23), calendar: cal)
        XCTAssertEqual(url.absoluteString, "rota://pattern/\(p.id.uuidString)/2026-10-23")
        XCTAssertEqual(CalendarPlanner.patternID(from: url), p.id)
        XCTAssertNil(CalendarPlanner.patternID(from: URL(string: "https://example.com/pattern/x/y")))
        XCTAssertNil(CalendarPlanner.patternID(from: nil))
        let events = CalendarPlanner.events(for: p, from: Fixtures.day(2026, 1, 1), months: 1, calendar: cal)
        XCTAssertTrue(events.allSatisfy { CalendarPlanner.patternID(from: $0.url) == p.id })
        XCTAssertEqual(Set(events.map(\.url)).count, events.count, "one URL per day")
    }

    func testTwelveMonthWindow() {
        let window = CalendarPlanner.interval(from: Fixtures.day(2026, 10, 22), calendar: cal)
        XCTAssertEqual(window.start, Fixtures.day(2026, 10, 22))
        XCTAssertEqual(window.end, Fixtures.day(2027, 10, 22))
        let p = Fixtures.pattern()
        let events = CalendarPlanner.events(for: p, from: Fixtures.day(2026, 10, 22), calendar: cal)
        XCTAssertTrue(events.allSatisfy { $0.day >= window.start && $0.day < window.end })
        XCTAssertEqual(events.count, RotaEngine.shifts(in: window, for: p, calendar: cal).filter { $0.shift.isWorked }.count)
    }

    func testNightsAcrossClockChangesUseWallClockTimes() {
        let p = Fixtures.pattern()
        let march = CalendarPlanner.events(for: p, from: Fixtures.day(2026, 3, 28), months: 1, calendar: cal)
        let shortNight = march.first { Fixtures.ymd($0.day) == [2026, 3, 28] }!   // 19:00 GMT → 07:00 BST
        XCTAssertEqual(shortNight.end.timeIntervalSince(shortNight.start), 11 * 3600)
        XCTAssertEqual(cal.component(.hour, from: shortNight.end), 7)

        let october = CalendarPlanner.events(for: p, from: Fixtures.day(2026, 10, 23), months: 1, calendar: cal)
        let longNight = october.first { Fixtures.ymd($0.day) == [2026, 10, 23] }!    // night per DSTTests
        XCTAssertEqual(cal.component(.hour, from: longNight.start), 19)
        XCTAssertEqual(cal.component(.hour, from: longNight.end), 7)
        // 23 Oct → 24 Oct is a normal 24h day; the 25h day is 25 Oct, when the rota is off.
        XCTAssertEqual(longNight.end.timeIntervalSince(longNight.start), 12 * 3600)
    }

    func testCustomShiftWithoutTimesIsAllDay() {
        let twi = ShiftType(kind: .custom, label: "TWI", colorHex: "#FF6B6B")
        let p = Fixtures.pattern(cycle: [twi])
        let event = CalendarPlanner.events(for: p, from: Fixtures.day(2026, 1, 5), months: 1, calendar: cal).first!
        XCTAssertTrue(event.isAllDay)
        XCTAssertEqual(event.title, "Ward 7 · TWI")
    }
}
