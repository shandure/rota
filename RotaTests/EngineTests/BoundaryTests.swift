import XCTest
import RotaCore

/// Edge cases: empty cycles, negative modulo, empty intervals, mid-day inputs, limits, built-ins.
final class BoundaryTests: XCTestCase {
    let cal = Fixtures.london

    func testEmptyCycleResolvesToOff() {
        let p = Fixtures.pattern(cycle: [])
        let e = RotaEngine.entry(on: Fixtures.referenceStart, for: p, calendar: cal)
        XCTAssertTrue(e.shift.isOff)
        XCTAssertFalse(e.isOverride)
        XCTAssertNil(RotaEngine.nextShift(after: Fixtures.referenceStart, for: p, calendar: cal))
    }

    func testEmptyCycleStillHonoursOverrides() {
        let p = Fixtures.pattern(cycle: [], overrides: [OverrideSnapshot(date: Fixtures.day(2026, 1, 6), shift: .day)])
        XCTAssertEqual(RotaEngine.nextShift(after: Fixtures.referenceStart, for: p, calendar: cal)?.shift, .day)
    }

    func testNegativeModulo() {
        let s = Fixtures.referenceStart
        func idx(_ offset: Int, _ n: Int) -> Int {
            RotaEngine.cycleIndex(on: Fixtures.adding(offset, to: s), startDate: s, cycleLength: n, calendar: cal)
        }
        XCTAssertEqual(idx(-1, 8), 7)
        XCTAssertEqual(idx(-8, 8), 0)
        XCTAssertEqual(idx(-9, 8), 7)
        XCTAssertEqual(idx(-1000, 8), 0)      // 1000 = 125 × 8
        XCTAssertEqual(idx(-1000, 56), 8)     // 1000 = 17 × 56 + 48 → 56 − 48
        XCTAssertEqual(idx(1000, 56), 48)
        XCTAssertEqual(idx(-1, 1), 0)
    }

    func testDaysBetweenSignAndZero() {
        let a = Fixtures.day(2026, 1, 5), b = Fixtures.day(2026, 1, 10)
        XCTAssertEqual(RotaEngine.daysBetween(a, b, calendar: cal), 5)
        XCTAssertEqual(RotaEngine.daysBetween(b, a, calendar: cal), -5)
        XCTAssertEqual(RotaEngine.daysBetween(a, a, calendar: cal), 0)
    }

    func testEmptyIntervalYieldsNothing() {
        let p = Fixtures.pattern()
        let d = Fixtures.day(2026, 1, 5)
        XCTAssertTrue(RotaEngine.shifts(in: DateInterval(start: d, end: d), for: p, calendar: cal).isEmpty)
    }

    func testIntervalStartingMidDayIncludesThatDay() {
        let p = Fixtures.pattern()
        let noon = Fixtures.day(2026, 1, 5).addingTimeInterval(12 * 3600)
        let entries = RotaEngine.shifts(in: DateInterval(start: noon, end: Fixtures.day(2026, 1, 7)), for: p, calendar: cal)
        XCTAssertEqual(entries.map(\.date), [Fixtures.day(2026, 1, 5), Fixtures.day(2026, 1, 6)])
    }

    func testIntervalEndIsExclusive() {
        let p = Fixtures.pattern()
        let entries = RotaEngine.shifts(in: DateInterval(start: Fixtures.day(2026, 1, 5), end: Fixtures.day(2026, 1, 6)),
                                        for: p, calendar: cal)
        XCTAssertEqual(entries.count, 1)
    }

    func testCanonicalDaySnapsNearMidnight() {
        let d = Fixtures.day(2026, 1, 5)
        XCTAssertEqual(RotaEngine.canonicalDay(d.addingTimeInterval(-5 * 3600), calendar: cal), d)   // 19:00 the night before
        XCTAssertEqual(RotaEngine.canonicalDay(d.addingTimeInterval(1 * 3600), calendar: cal), d)    // 01:00
        XCTAssertEqual(RotaEngine.canonicalDay(d.addingTimeInterval(11 * 3600), calendar: cal), d)   // 11:00
        XCTAssertEqual(RotaEngine.canonicalDay(d.addingTimeInterval(-11 * 3600), calendar: cal), d)  // 13:00 the day before
    }

    func testOverridesAreKeyedByDayNotInstant() {
        // Two override objects on the same day: the engine must treat them as one key (last wins).
        let a = OverrideSnapshot(date: Fixtures.day(2026, 1, 7), shift: .holiday)
        let b = OverrideSnapshot(date: Fixtures.day(2026, 1, 7).addingTimeInterval(3600), shift: .sick)
        let p = Fixtures.pattern(overrides: [a, b])
        let e = RotaEngine.entry(on: Fixtures.day(2026, 1, 7), for: p, calendar: cal)
        XCTAssertTrue(e.isOverride)
        XCTAssertTrue(e.shift.isAbsence)
    }

    func testLimits() {
        XCTAssertEqual(Limits.maxCycleLength, 56)
        XCTAssertEqual(Limits.maxPatternNameLength, 30)
        XCTAssertEqual(Limits.maxCustomLabelLength, 6)
        XCTAssertEqual(Limits.maxNoteLength, 60)
    }

    func testBuiltInShiftTypesMatchSpec() {
        XCTAssertEqual(ShiftType.day.colorHex, "#FFA94D")
        XCTAssertEqual(ShiftType.night.colorHex, "#4C6EF5")
        XCTAssertEqual(ShiftType.late.colorHex, "#F783AC")
        XCTAssertEqual(ShiftType.early.colorHex, "#38D9A9")
        XCTAssertEqual(ShiftType.holiday.colorHex, "#9775FA")
        XCTAssertEqual(ShiftType.sick.colorHex, "#868E96")
        XCTAssertEqual(ShiftType.customPalette, ["#FF6B6B", "#FFD43B", "#69DB7C", "#4DABF7"])

        XCTAssertEqual(ShiftType.day.startTime, ShiftType.time(7));    XCTAssertEqual(ShiftType.day.endTime, ShiftType.time(19))
        XCTAssertEqual(ShiftType.night.startTime, ShiftType.time(19)); XCTAssertEqual(ShiftType.night.endTime, ShiftType.time(7))
        XCTAssertEqual(ShiftType.late.startTime, ShiftType.time(13));  XCTAssertEqual(ShiftType.late.endTime, ShiftType.time(21))
        XCTAssertEqual(ShiftType.early.startTime, ShiftType.time(6));  XCTAssertEqual(ShiftType.early.endTime, ShiftType.time(14))
        XCTAssertNil(ShiftType.off.startTime)
        XCTAssertNil(ShiftType.holiday.startTime)

        XCTAssertEqual(ShiftType.holiday.label, "HOL")
        XCTAssertEqual(ShiftType.sick.label, "SICK")
        XCTAssertLessThanOrEqual(ShiftType.holiday.label.count, Limits.maxCustomLabelLength)
        XCTAssertLessThanOrEqual(ShiftType.sick.label.count, Limits.maxCustomLabelLength)
    }

    func testShiftTypeDerivedFlags() {
        XCTAssertTrue(ShiftType.night.crossesMidnight)
        XCTAssertFalse(ShiftType.day.crossesMidnight)
        XCTAssertFalse(ShiftType.off.crossesMidnight)

        XCTAssertTrue(ShiftType.off.isOff)
        XCTAssertTrue(ShiftType.holiday.isAbsence)
        XCTAssertTrue(ShiftType.sick.isAbsence)
        XCTAssertFalse(ShiftType.holiday.isWorked)
        XCTAssertFalse(ShiftType.off.isWorked)
        XCTAssertTrue(ShiftType.day.isWorked)

        let custom = ShiftType(kind: .custom, label: "TWI", colorHex: "#FFD43B",
                               startTime: .init(hour: 15), endTime: .init(hour: 23))
        XCTAssertTrue(custom.isWorked)
        XCTAssertFalse(custom.isAbsence)
        XCTAssertFalse(custom.crossesMidnight)
    }

    func testShiftTypeRoundTripsThroughCodable() throws {
        let cycle = Fixtures.twoDayTwoNightFourOff + [.holiday, .sick]
        let data = try JSONEncoder().encode(cycle)
        let decoded = try JSONDecoder().decode([ShiftType].self, from: data)
        XCTAssertEqual(decoded, cycle)
    }
}
