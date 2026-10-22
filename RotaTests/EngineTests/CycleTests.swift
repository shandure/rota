import XCTest
import RotaCore

/// Cycle lengths 1, 2, 8, 56 and the hand-written reference rota.
final class CycleTests: XCTestCase {
    let cal = Fixtures.london

    func testCycleLengthOne_everyDayIsTheSameShift() {
        let p = Fixtures.pattern(cycle: [.late])
        for offset in [-400, -1, 0, 1, 7, 365] {
            let d = Fixtures.adding(offset, to: Fixtures.referenceStart)
            XCTAssertEqual(RotaEngine.shift(on: d, for: p, calendar: cal), .late, "offset \(offset)")
            XCTAssertEqual(RotaEngine.cycleIndex(on: d, startDate: p.startDate, cycleLength: 1, calendar: cal), 0)
        }
    }

    func testCycleLengthTwo_alternates() {
        let p = Fixtures.pattern(cycle: [.day, .off])
        let s = Fixtures.referenceStart
        XCTAssertEqual(RotaEngine.shift(on: s, for: p, calendar: cal), .day)
        XCTAssertEqual(RotaEngine.shift(on: Fixtures.adding(1, to: s), for: p, calendar: cal), .off)
        XCTAssertEqual(RotaEngine.shift(on: Fixtures.adding(2, to: s), for: p, calendar: cal), .day)
        XCTAssertEqual(RotaEngine.shift(on: Fixtures.adding(-1, to: s), for: p, calendar: cal), .off)
        XCTAssertEqual(RotaEngine.shift(on: Fixtures.adding(-2, to: s), for: p, calendar: cal), .day)
    }

    func testCycleLengthEight_matchesHandWrittenRota() {
        // Start Mon 5 Jan 2026. Hand-written: 2 days, 2 nights, 4 off, repeating.
        let p = Fixtures.pattern()
        let interval = DateInterval(start: Fixtures.day(2026, 1, 5), end: Fixtures.day(2026, 1, 21))
        let entries = RotaEngine.shifts(in: interval, for: p, calendar: cal)
        XCTAssertEqual(entries.count, 16)
        XCTAssertEqual(Fixtures.labels(entries),
                       "D D N N O O O O D D N N O O O O")
    }

    func testCycleLengthEight_wholeJanuaryCountsByHand() {
        // 1–4 Jan precede the start and fall on the off tail of the previous cycle.
        let p = Fixtures.pattern()
        let entries = RotaEngine.shifts(in: Fixtures.month(2026, 1), for: p, calendar: cal)
        XCTAssertEqual(entries.count, 31)
        XCTAssertEqual(Fixtures.labels(entries),
                       "O O O O " +                 // 1–4 Jan
                       "D D N N O O O O " +         // 5–12
                       "D D N N O O O O " +         // 13–20
                       "D D N N O O O O " +         // 21–28
                       "D D N")                     // 29–31
        XCTAssertEqual(entries.filter { $0.shift.kind == .day }.count, 8)
        XCTAssertEqual(entries.filter { $0.shift.kind == .night }.count, 7)
        XCTAssertEqual(entries.filter { $0.shift.isOff }.count, 16)
    }

    func testCycleLengthFiftySix_wrapsExactly() {
        let p = Fixtures.pattern(cycle: Fixtures.fiftySix)
        let s = Fixtures.referenceStart
        XCTAssertEqual(RotaEngine.shift(on: s, for: p, calendar: cal).label, "C0")
        XCTAssertEqual(RotaEngine.shift(on: Fixtures.adding(55, to: s), for: p, calendar: cal).label, "C55")
        XCTAssertEqual(RotaEngine.shift(on: Fixtures.adding(56, to: s), for: p, calendar: cal).label, "C0")
        XCTAssertEqual(RotaEngine.shift(on: Fixtures.adding(57, to: s), for: p, calendar: cal).label, "C1")
        XCTAssertEqual(RotaEngine.shift(on: Fixtures.adding(-1, to: s), for: p, calendar: cal).label, "C55")
        XCTAssertEqual(RotaEngine.shift(on: Fixtures.adding(-56, to: s), for: p, calendar: cal).label, "C0")
        XCTAssertEqual(RotaEngine.shift(on: Fixtures.adding(-57, to: s), for: p, calendar: cal).label, "C55")
        XCTAssertEqual(Fixtures.fiftySix.count, Limits.maxCycleLength)
    }

    func testStartDateIsIndexZero() {
        let p = Fixtures.pattern()
        let e = RotaEngine.entry(on: p.startDate, for: p, calendar: cal)
        XCTAssertEqual(e.shift, .day)
        XCTAssertFalse(e.isOverride)
        XCTAssertNil(e.note)
        XCTAssertEqual(e.date, p.startDate)
    }

    func testShiftsInInterval_isConsecutiveAndAgreesWithSingleLookup() {
        let p = Fixtures.pattern()
        let entries = RotaEngine.shifts(in: Fixtures.month(2026, 2), for: p, calendar: cal)
        XCTAssertEqual(entries.count, 28)
        for (i, e) in entries.enumerated() {
            XCTAssertEqual(e.date, Fixtures.day(2026, 2, i + 1), "day \(i + 1)")
            XCTAssertEqual(e.shift, RotaEngine.shift(on: e.date, for: p, calendar: cal), "day \(i + 1)")
        }
    }

    func testPatternExtendsBackwards_threeMonthsBeforeStart() {
        // Definition of done: start three months ago, every day must match.
        // Start 5 Jan 2026; check Mon 13 Oct 2025, which is 84 days (10.5 cycles) earlier → index 4 → off,
        // and 12 Oct → index 3 → night.
        let p = Fixtures.pattern()
        XCTAssertEqual(RotaEngine.daysBetween(p.startDate, Fixtures.day(2025, 10, 13), calendar: cal), -84)
        XCTAssertEqual(RotaEngine.shift(on: Fixtures.day(2025, 10, 13), for: p, calendar: cal), .off)
        XCTAssertEqual(RotaEngine.shift(on: Fixtures.day(2025, 10, 12), for: p, calendar: cal), .night)
        XCTAssertEqual(RotaEngine.shift(on: Fixtures.day(2025, 10, 9), for: p, calendar: cal), .day)
    }
}
