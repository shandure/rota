import XCTest
import RotaCore

/// Override merge: overrides win, carry notes, and are skipped/used correctly by nextShift.
final class OverrideTests: XCTestCase {
    let cal = Fixtures.london

    func testOverrideReplacesCycleShift() {
        // 7 Jan 2026 is cycle index 2 → night. Override to holiday.
        let holiday = OverrideSnapshot(date: Fixtures.day(2026, 1, 7), shift: .holiday, note: "Skiing")
        let p = Fixtures.pattern(overrides: [holiday])

        let e = RotaEngine.entry(on: Fixtures.day(2026, 1, 7), for: p, calendar: cal)
        XCTAssertEqual(e.shift, .holiday)
        XCTAssertTrue(e.isOverride)
        XCTAssertEqual(e.note, "Skiing")

        // Neighbours untouched.
        XCTAssertEqual(RotaEngine.shift(on: Fixtures.day(2026, 1, 6), for: p, calendar: cal), .day)
        XCTAssertEqual(RotaEngine.shift(on: Fixtures.day(2026, 1, 8), for: p, calendar: cal), .night)
        XCTAssertFalse(RotaEngine.entry(on: Fixtures.day(2026, 1, 8), for: p, calendar: cal).isOverride)
    }

    func testOverrideToOff() {
        let swap = OverrideSnapshot(date: Fixtures.day(2026, 1, 5), shift: .off, note: "Swapped with Sam")
        let p = Fixtures.pattern(overrides: [swap])
        let e = RotaEngine.entry(on: Fixtures.day(2026, 1, 5), for: p, calendar: cal)
        XCTAssertTrue(e.shift.isOff)
        XCTAssertTrue(e.isOverride)
    }

    func testOverrideBeforeStartDate() {
        let o = OverrideSnapshot(date: Fixtures.day(2025, 12, 25), shift: .late)
        let p = Fixtures.pattern(overrides: [o])
        XCTAssertEqual(RotaEngine.shift(on: Fixtures.day(2025, 12, 25), for: p, calendar: cal), .late)
    }

    func testRemovingOverrideRestoresCycle() {
        let o = OverrideSnapshot(date: Fixtures.day(2026, 1, 7), shift: .sick)
        var p = Fixtures.pattern(overrides: [o])
        XCTAssertEqual(RotaEngine.shift(on: Fixtures.day(2026, 1, 7), for: p, calendar: cal), .sick)
        p.overrides = []
        XCTAssertEqual(RotaEngine.shift(on: Fixtures.day(2026, 1, 7), for: p, calendar: cal), .night)
    }

    func testShiftsInIntervalMarksOverrides() {
        let o = OverrideSnapshot(date: Fixtures.day(2026, 1, 10), shift: .early, note: "Cover")
        let p = Fixtures.pattern(overrides: [o])
        let entries = RotaEngine.shifts(in: Fixtures.month(2026, 1), for: p, calendar: cal)
        let flagged = entries.filter(\.isOverride)
        XCTAssertEqual(flagged.count, 1)
        XCTAssertEqual(flagged.first?.date, Fixtures.day(2026, 1, 10))
        XCTAssertEqual(flagged.first?.shift, .early)
        XCTAssertEqual(flagged.first?.note, "Cover")
    }

    func testOverrideDoesNotMatchAdjacentDays() {
        // An override at exact midnight must not bleed into the previous or next day.
        let o = OverrideSnapshot(date: Fixtures.day(2026, 1, 10), shift: .early)
        let p = Fixtures.pattern(overrides: [o])
        XCTAssertEqual(RotaEngine.shift(on: Fixtures.day(2026, 1, 9), for: p, calendar: cal), .off)
        XCTAssertEqual(RotaEngine.shift(on: Fixtures.day(2026, 1, 11), for: p, calendar: cal), .off)
    }

    // MARK: nextShift

    func testNextShift_skipsOffDays() {
        // 8 Jan is night (index 3); 9–12 off; 13 Jan is day.
        let p = Fixtures.pattern()
        let next = RotaEngine.nextShift(after: Fixtures.day(2026, 1, 8), for: p, calendar: cal)
        XCTAssertEqual(next?.date, Fixtures.day(2026, 1, 13))
        XCTAssertEqual(next?.shift, .day)
    }

    func testNextShift_isStrictlyAfter() {
        let p = Fixtures.pattern()
        let next = RotaEngine.nextShift(after: Fixtures.day(2026, 1, 5), for: p, calendar: cal)
        XCTAssertEqual(next?.date, Fixtures.day(2026, 1, 6))
    }

    func testNextShift_usesOverrideOnAnOffDay() {
        let o = OverrideSnapshot(date: Fixtures.day(2026, 1, 10), shift: .late)
        let p = Fixtures.pattern(overrides: [o])
        let next = RotaEngine.nextShift(after: Fixtures.day(2026, 1, 8), for: p, calendar: cal)
        XCTAssertEqual(next?.date, Fixtures.day(2026, 1, 10))
        XCTAssertEqual(next?.shift, .late)
        XCTAssertTrue(next?.isOverride ?? false)
    }

    func testNextShift_skipsHolidayAndSickOverrides() {
        // 13 Jan would be the next day shift; mark it holiday and 14 Jan sick → 15 Jan (night).
        let p = Fixtures.pattern(overrides: [
            OverrideSnapshot(date: Fixtures.day(2026, 1, 13), shift: .holiday),
            OverrideSnapshot(date: Fixtures.day(2026, 1, 14), shift: .sick),
        ])
        let next = RotaEngine.nextShift(after: Fixtures.day(2026, 1, 8), for: p, calendar: cal)
        XCTAssertEqual(next?.date, Fixtures.day(2026, 1, 15))
        XCTAssertEqual(next?.shift, .night)
    }

    func testNextShift_nilWhenNothingIsWorked() {
        let p = Fixtures.pattern(cycle: [.off])
        XCTAssertNil(RotaEngine.nextShift(after: Fixtures.referenceStart, for: p, calendar: cal))
    }

    func testNextShift_respectsSearchLimit() {
        let far = OverrideSnapshot(date: Fixtures.adding(400, to: Fixtures.referenceStart), shift: .day)
        let p = Fixtures.pattern(cycle: [.off], overrides: [far])
        XCTAssertNil(RotaEngine.nextShift(after: Fixtures.referenceStart, for: p, calendar: cal, within: 366))
        XCTAssertEqual(RotaEngine.nextShift(after: Fixtures.referenceStart, for: p, calendar: cal, within: 500)?.shift, .day)
    }
}
