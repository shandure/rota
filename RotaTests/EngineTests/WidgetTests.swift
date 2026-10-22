import XCTest
import RotaCore

/// Widget timeline data: one entry per day, week strip starting on that day, next worked shift.
final class WidgetTests: XCTestCase {
    let cal = Fixtures.london

    func testSevenEntriesEachStartingOnItsOwnDay() {
        let p = Fixtures.pattern()
        let days = RotaEngine.widgetDays(from: Fixtures.day(2026, 1, 5), for: p, calendar: cal)
        XCTAssertEqual(days.count, 7)
        for (i, day) in days.enumerated() {
            XCTAssertEqual(day.date, Fixtures.day(2026, 1, 5 + i), "entry \(i)")
            XCTAssertEqual(day.week.count, 7, "entry \(i)")
            XCTAssertEqual(day.week.first?.date, day.date, "entry \(i) week should start on its day")
            XCTAssertEqual(day.today, day.week.first, "entry \(i)")
        }
    }

    func testWeekStripMatchesMonthViewForNextSevenDays() {
        // Definition of done: widget matches the month view for the next 7 days.
        let p = Fixtures.pattern(overrides: [OverrideSnapshot(date: Fixtures.day(2026, 1, 7), shift: .holiday)])
        let today = Fixtures.day(2026, 1, 5)
        let widget = RotaEngine.widgetDays(from: today, for: p, calendar: cal).first!
        let month = RotaEngine.shifts(in: DateInterval(start: today, end: Fixtures.adding(7, to: today)), for: p, calendar: cal)
        XCTAssertEqual(widget.week, month)
        XCTAssertEqual(Fixtures.labels(widget.week), "D D HOL N O O O")
    }

    func testNextIsTheNextWorkedShift() {
        let p = Fixtures.pattern()
        let days = RotaEngine.widgetDays(from: Fixtures.day(2026, 1, 8), for: p, calendar: cal)
        // 8 Jan night → next worked is Tue 13 Jan day; from 9 Jan (off) it is still 13 Jan.
        XCTAssertEqual(days[0].next?.date, Fixtures.day(2026, 1, 13))
        XCTAssertEqual(days[0].next?.shift, .day)
        XCTAssertEqual(days[1].next?.date, Fixtures.day(2026, 1, 13))
        // From 13 Jan (day) → 14 Jan (day).
        XCTAssertEqual(days[5].date, Fixtures.day(2026, 1, 13))
        XCTAssertEqual(days[5].next?.date, Fixtures.day(2026, 1, 14))
    }

    func testAcrossClockChange() {
        let p = Fixtures.pattern()
        let days = RotaEngine.widgetDays(from: Fixtures.day(2026, 3, 26), for: p, calendar: cal)
        XCTAssertEqual(days.map { Fixtures.ymd($0.date).last! }, [26, 27, 28, 29, 30, 31, 1])
        XCTAssertEqual(days[3].week.map { Fixtures.ymd($0.date).last! }, [29, 30, 31, 1, 2, 3, 4])
    }

    func testEmptyCycleGivesOffDaysAndNoNext() {
        let p = Fixtures.pattern(cycle: [])
        let days = RotaEngine.widgetDays(from: Fixtures.day(2026, 1, 5), for: p, calendar: cal)
        XCTAssertEqual(days.count, 7)
        XCTAssertTrue(days.allSatisfy { $0.today.shift.isOff && $0.next == nil })
    }
}
