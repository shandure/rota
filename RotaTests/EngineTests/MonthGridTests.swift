import XCTest
import RotaCore

/// Month grid bounds, weekday headers and the summary strip counts.
final class MonthGridTests: XCTestCase {
    let london = Fixtures.london

    func testStartOfMonth() {
        XCTAssertEqual(RotaEngine.startOfMonth(containing: Fixtures.day(2026, 10, 25), calendar: london), Fixtures.day(2026, 10, 1))
        XCTAssertEqual(RotaEngine.startOfMonth(containing: Fixtures.day(2026, 10, 1), calendar: london), Fixtures.day(2026, 10, 1))
    }

    func testGridForMondayWeekStart() {
        // 1 Oct 2026 is a Thursday → grid starts Mon 28 Sep and runs 42 days to 9 Nov (exclusive).
        let grid = RotaEngine.monthGrid(containing: Fixtures.day(2026, 10, 14), calendar: london)
        XCTAssertEqual(grid.start, Fixtures.day(2026, 9, 28))
        XCTAssertEqual(grid.end, Fixtures.day(2026, 11, 9))
        XCTAssertEqual(RotaEngine.daysBetween(grid.start, grid.end, calendar: london), 42)
    }

    func testGridWhenMonthStartsOnWeekStart() {
        // 1 Feb 2027 is a Monday → no leading days.
        let grid = RotaEngine.monthGrid(containing: Fixtures.day(2027, 2, 1), calendar: london)
        XCTAssertEqual(grid.start, Fixtures.day(2027, 2, 1))
        XCTAssertEqual(grid.end, Fixtures.day(2027, 3, 15))
    }

    func testGridForSundayWeekStart() {
        var sunday = london
        sunday.firstWeekday = 1
        let grid = RotaEngine.monthGrid(containing: Fixtures.day(2026, 10, 14), calendar: sunday)
        XCTAssertEqual(grid.start, Fixtures.day(2026, 9, 27))
    }

    func testGridAcrossClockChangeHasFortyTwoConsecutiveDays() {
        let p = Fixtures.pattern()
        for month in [3, 10] {
            let grid = RotaEngine.monthGrid(containing: Fixtures.day(2026, month, 15), calendar: london)
            let entries = RotaEngine.shifts(in: grid, for: p, calendar: london)
            XCTAssertEqual(entries.count, 42, "month \(month)")
            for i in 1..<entries.count {
                XCTAssertEqual(RotaEngine.daysBetween(entries[i - 1].date, entries[i].date, calendar: london), 1, "month \(month) index \(i)")
            }
        }
    }

    func testWeekdayInitials() {
        XCTAssertEqual(RotaEngine.weekdayInitials(calendar: london), ["M", "T", "W", "T", "F", "S", "S"])
        var sunday = london
        sunday.firstWeekday = 1
        XCTAssertEqual(RotaEngine.weekdayInitials(calendar: sunday), ["S", "M", "T", "W", "T", "F", "S"])
    }

    func testSummaryCountsForJanuary() {
        // Hand count from CycleTests: 8 days + 7 nights worked, 16 off.
        let p = Fixtures.pattern()
        let summary = RotaEngine.summary(of: RotaEngine.shifts(in: Fixtures.month(2026, 1), for: p, calendar: london))
        XCTAssertEqual(summary, RotaEngine.Summary(shifts: 15, nights: 7, off: 16))
    }

    func testSummaryExcludesHolidayAndSick() {
        let p = Fixtures.pattern(overrides: [
            OverrideSnapshot(date: Fixtures.day(2026, 1, 5), shift: .holiday),   // was a day
            OverrideSnapshot(date: Fixtures.day(2026, 1, 7), shift: .sick),      // was a night
        ])
        let summary = RotaEngine.summary(of: RotaEngine.shifts(in: Fixtures.month(2026, 1), for: p, calendar: london))
        XCTAssertEqual(summary, RotaEngine.Summary(shifts: 13, nights: 6, off: 18))
    }
}
