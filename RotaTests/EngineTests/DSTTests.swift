import XCTest
import RotaCore

/// UK clock changes in 2026: forward on Sun 29 March (23-hour day), back on Sun 25 October (25-hour day).
/// No shift may move to the wrong day across either weekend.
final class DSTTests: XCTestCase {
    let cal = Fixtures.london

    func testFixtureCalendarActuallyObservesDST() {
        let tz = cal.timeZone
        XCTAssertFalse(tz.isDaylightSavingTime(for: Fixtures.day(2026, 3, 28)))
        XCTAssertTrue(tz.isDaylightSavingTime(for: Fixtures.day(2026, 3, 30)))
        XCTAssertTrue(tz.isDaylightSavingTime(for: Fixtures.day(2026, 10, 24)))
        XCTAssertFalse(tz.isDaylightSavingTime(for: Fixtures.day(2026, 10, 26)))
        // The short and long days.
        XCTAssertEqual(Fixtures.day(2026, 3, 30).timeIntervalSince(Fixtures.day(2026, 3, 29)), 23 * 3600)
        XCTAssertEqual(Fixtures.day(2026, 10, 26).timeIntervalSince(Fixtures.day(2026, 10, 25)), 25 * 3600)
    }

    func testDaysBetweenAcrossSpringForward() {
        XCTAssertEqual(RotaEngine.daysBetween(Fixtures.day(2026, 3, 28), Fixtures.day(2026, 3, 29), calendar: cal), 1)
        XCTAssertEqual(RotaEngine.daysBetween(Fixtures.day(2026, 3, 29), Fixtures.day(2026, 3, 30), calendar: cal), 1)
        XCTAssertEqual(RotaEngine.daysBetween(Fixtures.day(2026, 3, 28), Fixtures.day(2026, 3, 30), calendar: cal), 2)
        XCTAssertEqual(RotaEngine.daysBetween(Fixtures.day(2026, 3, 30), Fixtures.day(2026, 3, 28), calendar: cal), -2)
    }

    func testDaysBetweenAcrossFallBack() {
        XCTAssertEqual(RotaEngine.daysBetween(Fixtures.day(2026, 10, 24), Fixtures.day(2026, 10, 25), calendar: cal), 1)
        XCTAssertEqual(RotaEngine.daysBetween(Fixtures.day(2026, 10, 25), Fixtures.day(2026, 10, 26), calendar: cal), 1)
        XCTAssertEqual(RotaEngine.daysBetween(Fixtures.day(2026, 10, 24), Fixtures.day(2026, 10, 26), calendar: cal), 2)
    }

    func testCycleIndexIncrementsByOneAcrossMarchWeekend() {
        // Pattern starts 1 March 2026, so index on March d is (d - 1) mod 8.
        let p = Fixtures.pattern(start: Fixtures.day(2026, 3, 1))
        for d in 26...31 {
            let idx = RotaEngine.cycleIndex(on: Fixtures.day(2026, 3, d), startDate: p.startDate, cycleLength: 8, calendar: cal)
            XCTAssertEqual(idx, (d - 1) % 8, "March \(d)")
        }
        XCTAssertEqual(RotaEngine.cycleIndex(on: Fixtures.day(2026, 4, 1), startDate: p.startDate, cycleLength: 8, calendar: cal), 31 % 8)
    }

    func testReferenceRotaAcrossOctoberWeekend() {
        // 5 Jan → 25 Oct 2026 is 293 days; 293 mod 8 = 5.
        let p = Fixtures.pattern()
        XCTAssertEqual(RotaEngine.daysBetween(p.startDate, Fixtures.day(2026, 10, 25), calendar: cal), 293)
        XCTAssertEqual(RotaEngine.shift(on: Fixtures.day(2026, 10, 23), for: p, calendar: cal), .night) // 291 → 3
        XCTAssertEqual(RotaEngine.shift(on: Fixtures.day(2026, 10, 24), for: p, calendar: cal), .off)   // 292 → 4
        XCTAssertEqual(RotaEngine.shift(on: Fixtures.day(2026, 10, 25), for: p, calendar: cal), .off)   // 293 → 5
        XCTAssertEqual(RotaEngine.shift(on: Fixtures.day(2026, 10, 26), for: p, calendar: cal), .off)   // 294 → 6
        XCTAssertEqual(RotaEngine.shift(on: Fixtures.day(2026, 10, 27), for: p, calendar: cal), .off)   // 295 → 7
        XCTAssertEqual(RotaEngine.shift(on: Fixtures.day(2026, 10, 28), for: p, calendar: cal), .day)   // 296 → 0
    }

    func testReferenceRotaAcrossMarchWeekend() {
        // 5 Jan → 29 Mar 2026 is 83 days; 83 mod 8 = 3 → night.
        let p = Fixtures.pattern()
        XCTAssertEqual(RotaEngine.daysBetween(p.startDate, Fixtures.day(2026, 3, 29), calendar: cal), 83)
        XCTAssertEqual(RotaEngine.shift(on: Fixtures.day(2026, 3, 27), for: p, calendar: cal), .day)   // 81 → 1
        XCTAssertEqual(RotaEngine.shift(on: Fixtures.day(2026, 3, 28), for: p, calendar: cal), .night) // 82 → 2
        XCTAssertEqual(RotaEngine.shift(on: Fixtures.day(2026, 3, 29), for: p, calendar: cal), .night) // 83 → 3
        XCTAssertEqual(RotaEngine.shift(on: Fixtures.day(2026, 3, 30), for: p, calendar: cal), .off)   // 84 → 4
    }

    func testMonthEnumerationHasOneEntryPerDayAtLocalMidnight() {
        let p = Fixtures.pattern()
        for (m, expectedCount) in [(3, 31), (10, 31)] {
            let entries = RotaEngine.shifts(in: Fixtures.month(2026, m), for: p, calendar: cal)
            XCTAssertEqual(entries.count, expectedCount, "month \(m)")
            for (i, e) in entries.enumerated() {
                XCTAssertEqual(Fixtures.ymd(e.date), [2026, m, i + 1], "month \(m) day \(i + 1)")
                XCTAssertEqual(cal.component(.hour, from: e.date), 0, "month \(m) day \(i + 1) not at midnight")
            }
            XCTAssertEqual(Set(entries.map(\.date)).count, expectedCount, "duplicate day in month \(m)")
        }
    }

    func testOverrideOnClockChangeDay() {
        let p = Fixtures.pattern(overrides: [
            OverrideSnapshot(date: Fixtures.day(2026, 3, 29), shift: .holiday),
            OverrideSnapshot(date: Fixtures.day(2026, 10, 25), shift: .sick),
        ])
        XCTAssertEqual(RotaEngine.shift(on: Fixtures.day(2026, 3, 29), for: p, calendar: cal), .holiday)
        XCTAssertEqual(RotaEngine.shift(on: Fixtures.day(2026, 3, 28), for: p, calendar: cal), .night)
        XCTAssertEqual(RotaEngine.shift(on: Fixtures.day(2026, 3, 30), for: p, calendar: cal), .off)
        XCTAssertEqual(RotaEngine.shift(on: Fixtures.day(2026, 10, 25), for: p, calendar: cal), .sick)
        XCTAssertEqual(RotaEngine.shift(on: Fixtures.day(2026, 10, 24), for: p, calendar: cal), .off)
        XCTAssertEqual(RotaEngine.shift(on: Fixtures.day(2026, 10, 26), for: p, calendar: cal), .off)
    }

    func testNextShiftAcrossClockChange() {
        // 28 Mar night → next worked is 29 Mar night (the 23-hour day).
        let p = Fixtures.pattern()
        let next = RotaEngine.nextShift(after: Fixtures.day(2026, 3, 28), for: p, calendar: cal)
        XCTAssertEqual(next?.date, Fixtures.day(2026, 3, 29))
        // 25 Oct off → next worked is 28 Oct day, across the 25-hour day.
        let next2 = RotaEngine.nextShift(after: Fixtures.day(2026, 10, 25), for: p, calendar: cal)
        XCTAssertEqual(next2?.date, Fixtures.day(2026, 10, 28))
        XCTAssertEqual(next2?.shift, .day)
    }

    func testStartDateInSummerEvaluatedInWinterAndViceVersa() {
        // Start in BST, query in GMT: 1 Jul 2026 → 5 Jan 2027 is 188 days; 188 mod 8 = 4 → off; 7 Jan → 6 → off; 9 Jan → 0 → day.
        let summer = Fixtures.pattern(start: Fixtures.day(2026, 7, 1))
        XCTAssertEqual(RotaEngine.daysBetween(summer.startDate, Fixtures.day(2027, 1, 5), calendar: cal), 188)
        XCTAssertEqual(RotaEngine.shift(on: Fixtures.day(2027, 1, 9), for: summer, calendar: cal), .day)
        // Start in GMT, query in BST: 5 Jan → 1 Jul 2026 is 177 days; 177 mod 8 = 1 → day.
        let winter = Fixtures.pattern()
        XCTAssertEqual(RotaEngine.daysBetween(winter.startDate, Fixtures.day(2026, 7, 1), calendar: cal), 177)
        XCTAssertEqual(RotaEngine.shift(on: Fixtures.day(2026, 7, 1), for: winter, calendar: cal), .day)
    }
}
