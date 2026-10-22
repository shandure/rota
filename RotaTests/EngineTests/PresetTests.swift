import XCTest
import RotaCore

/// Presets are prefilled cycles; check lengths, contents and the 14-day preview they produce.
final class PresetTests: XCTestCase {
    let cal = Fixtures.london

    func testCycleLengths() {
        XCTAssertEqual(Preset.fourOnFourOff.cycle.count, 8)
        XCTAssertEqual(Preset.twoDayTwoNightFourOff.cycle.count, 8)
        XCTAssertEqual(Preset.monToFri.cycle.count, 7)
        XCTAssertEqual(Preset.continental.cycle.count, 14)
        XCTAssertEqual(Preset.threeOnThreeOff.cycle.count, 6)
        XCTAssertEqual(Preset.fiveTwoFiveThree.cycle.count, 15)
        XCTAssertEqual(Preset.custom.cycle.count, 0)
        for preset in Preset.allCases {
            XCTAssertLessThanOrEqual(preset.cycle.count, Limits.maxCycleLength, preset.name)
        }
    }

    func testTwoDayTwoNightFourOffMatchesFixture() {
        XCTAssertEqual(Preset.twoDayTwoNightFourOff.cycle, Fixtures.twoDayTwoNightFourOff)
    }

    func testContinentalShape() {
        let p = Fixtures.pattern(start: Fixtures.day(2026, 1, 5), cycle: Preset.continental.cycle)
        let entries = RotaEngine.shifts(in: DateInterval(start: Fixtures.day(2026, 1, 5), end: Fixtures.day(2026, 1, 19)),
                                        for: p, calendar: cal)
        XCTAssertEqual(Fixtures.labels(entries), "D D O O D D D O O D D O O O")
    }

    func testMonToFriFromAMonday() {
        let p = Fixtures.pattern(start: Fixtures.day(2026, 1, 5), cycle: Preset.monToFri.cycle)
        let week = RotaEngine.shifts(in: DateInterval(start: Fixtures.day(2026, 1, 5), end: Fixtures.day(2026, 1, 12)),
                                     for: p, calendar: cal)
        XCTAssertEqual(Fixtures.labels(week), "D D D D D O O")
        // The weekend before the start is off too.
        XCTAssertEqual(RotaEngine.shift(on: Fixtures.day(2026, 1, 3), for: p, calendar: cal), .off)
        XCTAssertEqual(RotaEngine.shift(on: Fixtures.day(2026, 1, 2), for: p, calendar: cal), .day)
    }

    func testFourteenDayPreviewFromAKnownDate() {
        // Builder preview: next 14 days from Thu 1 Jan 2026 for 2D 2N 4 off starting Mon 5 Jan.
        let p = Fixtures.pattern(cycle: Preset.twoDayTwoNightFourOff.cycle)
        let today = Fixtures.day(2026, 1, 1)
        let preview = RotaEngine.shifts(in: DateInterval(start: today, end: Fixtures.adding(14, to: today)), for: p, calendar: cal)
        XCTAssertEqual(preview.count, 14)
        XCTAssertEqual(Fixtures.labels(preview), "O O O O D D N N O O O O D D")
    }

    func testMatching() {
        XCTAssertEqual(Preset.matching(Fixtures.twoDayTwoNightFourOff), .twoDayTwoNightFourOff)
        XCTAssertEqual(Preset.matching([.day, .day, .day, .day, .off, .off, .off, .off]), .fourOnFourOff)
        XCTAssertNil(Preset.matching([]))
        XCTAssertNil(Preset.matching([.late]))
    }

    func testAnalyticsNamesContainNoUserText() {
        for preset in Preset.allCases {
            XCTAssertFalse(preset.analyticsName.contains(" "), preset.analyticsName)
            XCTAssertEqual(preset.analyticsName, preset.analyticsName.lowercased())
        }
    }
}
