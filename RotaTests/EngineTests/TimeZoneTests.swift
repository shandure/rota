import XCTest
import RotaCore

/// Changing the device time zone must not move any shift to a different calendar day.
/// Day-stamps written in one zone are read back in another; `RotaEngine.canonicalDay`
/// snaps them to the nearest local midnight. The guarantee holds for any pair of zones
/// less than 12 hours apart, which covers UTC−10 … UTC+12 against the UK. (A UK-written
/// stamp read at UTC+13, e.g. New Zealand summer time in a UK winter, is the known limit.)
final class TimeZoneTests: XCTestCase {
    let london = Fixtures.london
    /// Zones used with January fixtures (UK on GMT): offsets −10 … +11.
    let zones = ["Asia/Tokyo", "America/New_York", "America/Los_Angeles", "Pacific/Honolulu",
                 "Australia/Sydney", "Asia/Kolkata", "Asia/Dubai", "Europe/Athens", "Europe/London"]
    /// Zones used with August fixtures (UK on BST): includes New Zealand on NZST (+12, i.e. 11 hours ahead).
    let augustZones = ["Asia/Tokyo", "America/New_York", "Pacific/Honolulu", "Pacific/Auckland",
                       "Australia/Sydney", "Asia/Kolkata", "Europe/London"]

    func testCanonicalDay_identityForLocalMidnight() {
        let d = Fixtures.day(2026, 1, 5)
        XCTAssertEqual(RotaEngine.canonicalDay(d, calendar: london), d)
    }

    func testCanonicalDay_snapsForeignMidnightsToSameCalendarDay() {
        // 5 Jan 2026 00:00 London, read in every zone, must still be 5 Jan.
        let stamp = Fixtures.day(2026, 1, 5, in: london)
        for zone in zones {
            let cal = Fixtures.calendar(zone)
            let day = RotaEngine.canonicalDay(stamp, calendar: cal)
            XCTAssertEqual(Fixtures.ymd(day, in: cal), [2026, 1, 5], zone)
            XCTAssertEqual(day, Fixtures.day(2026, 1, 5, in: cal), zone)
        }
    }

    func testCanonicalDay_snapsStampsWrittenAbroadBackToLondon() {
        for zone in augustZones {
            let foreign = Fixtures.calendar(zone)
            let stamp = Fixtures.day(2026, 8, 14, in: foreign)   // written during BST
            let day = RotaEngine.canonicalDay(stamp, calendar: london)
            XCTAssertEqual(Fixtures.ymd(day, in: london), [2026, 8, 14], zone)
        }
    }

    func testPatternCreatedInLondon_readInAnyZone_sameShiftEveryDay() {
        let p = Fixtures.pattern(overrides: [
            OverrideSnapshot(date: Fixtures.day(2026, 2, 14, in: london), shift: .holiday, note: "Valentine's"),
        ])
        // Compare 1 Jan – 30 Apr 2026, which spans the UK March clock change.
        let expected = RotaEngine.shifts(in: DateInterval(start: Fixtures.day(2026, 1, 1), end: Fixtures.day(2026, 5, 1)),
                                         for: p, calendar: london)
        XCTAssertEqual(expected.count, 120)

        for zone in zones {
            let cal = Fixtures.calendar(zone)
            for e in expected {
                let ymd = Fixtures.ymd(e.date, in: london)
                let localDay = Fixtures.day(ymd[0], ymd[1], ymd[2], in: cal)
                let got = RotaEngine.entry(on: localDay, for: p, calendar: cal)
                XCTAssertEqual(got.shift, e.shift, "\(zone) \(ymd)")
                XCTAssertEqual(got.isOverride, e.isOverride, "\(zone) \(ymd)")
                XCTAssertEqual(got.note, e.note, "\(zone) \(ymd)")
            }
            // The override resolves to Holiday in every zone.
            XCTAssertEqual(RotaEngine.shift(on: Fixtures.day(2026, 2, 14, in: cal), for: p, calendar: cal), .holiday, zone)
        }
    }

    func testPatternCreatedAbroad_readInLondon() {
        for zone in zones {
            let foreign = Fixtures.calendar(zone)
            let p = PatternSnapshot(name: "Abroad",
                                    startDate: Fixtures.day(2026, 1, 5, in: foreign),
                                    cycle: Fixtures.twoDayTwoNightFourOff,
                                    overrides: [OverrideSnapshot(date: Fixtures.day(2026, 1, 20, in: foreign), shift: .sick)])
            XCTAssertEqual(RotaEngine.shift(on: Fixtures.day(2026, 1, 5), for: p, calendar: london), .day, zone)
            XCTAssertEqual(RotaEngine.shift(on: Fixtures.day(2026, 1, 7), for: p, calendar: london), .night, zone)
            XCTAssertEqual(RotaEngine.shift(on: Fixtures.day(2026, 1, 9), for: p, calendar: london), .off, zone)
            XCTAssertEqual(RotaEngine.shift(on: Fixtures.day(2026, 1, 20), for: p, calendar: london), .sick, zone)
            XCTAssertEqual(RotaEngine.shift(on: Fixtures.day(2026, 1, 19), for: p, calendar: london), .off, zone)
        }
    }

    func testNextShift_sameDayInEveryZone() {
        let p = Fixtures.pattern()
        for zone in zones {
            let cal = Fixtures.calendar(zone)
            let next = RotaEngine.nextShift(after: Fixtures.day(2026, 1, 8, in: cal), for: p, calendar: cal)
            XCTAssertEqual(next.map { Fixtures.ymd($0.date, in: cal) }, [2026, 1, 13], zone)
        }
    }

    func testShiftsInInterval_sameLabelsInEveryZone() {
        let p = Fixtures.pattern()
        let reference = Fixtures.labels(RotaEngine.shifts(in: Fixtures.month(2026, 10), for: p, calendar: london))
        for zone in zones {
            let cal = Fixtures.calendar(zone)
            let labels = Fixtures.labels(RotaEngine.shifts(in: Fixtures.month(2026, 10, in: cal), for: p, calendar: cal))
            XCTAssertEqual(labels, reference, zone)
        }
    }
}
