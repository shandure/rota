import XCTest
import RotaCore

#if canImport(SwiftData)
import SwiftData

/// The "kill the app and relaunch" check from the spec, automated: data written to an on-disk
/// SwiftData store must come back intact when the store is reopened.
/// Apple platforms only; the Linux package build does not compile this folder.
@MainActor
final class PersistenceTests: XCTestCase {
    private var storeURL: URL!

    override func setUp() {
        storeURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("rota-test-\(UUID().uuidString).store")
    }

    override func tearDown() {
        for suffix in ["", "-shm", "-wal"] {
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: storeURL.path + suffix))
        }
    }

    private func openStore() throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: Store.schema, url: storeURL)
        return try ModelContainer(for: Store.schema, configurations: [configuration])
    }

    func testPatternAndHolidayOverrideSurviveReopeningTheStore() throws {
        let holidayDay = Fixtures.day(2026, 10, 27)   // a Day shift in the reference rota
        var twilight = ShiftType(kind: .custom, label: "TWI", colorHex: "#FFD43B",
                                 startTime: ShiftType.time(15, 30), endTime: ShiftType.time(23))
        twilight.endTime = ShiftType.time(23, 15)

        // Launch 1: create the pattern and set the override.
        do {
            let container = try openStore()
            let context = container.mainContext
            let pattern = Pattern(name: "Ward 7",
                                  startDate: Fixtures.referenceStart,
                                  cycle: Fixtures.twoDayTwoNightFourOff + [twilight],
                                  createdAt: Fixtures.referenceStart,
                                  isActive: true)
            context.insert(pattern)
            context.insert(Override(date: holidayDay, shift: .holiday, note: "Cornwall", pattern: pattern))
            try context.save()
        }

        // Launch 2: reopen and read back.
        let reopened = try openStore()
        let patterns = try reopened.mainContext.fetch(FetchDescriptor<Pattern>())
        XCTAssertEqual(patterns.count, 1)
        let pattern = try XCTUnwrap(patterns.first)

        XCTAssertEqual(pattern.name, "Ward 7")
        XCTAssertTrue(pattern.isActive)
        XCTAssertEqual(pattern.cycle.count, 9)
        XCTAssertEqual(Array(pattern.cycle.prefix(8)), Fixtures.twoDayTwoNightFourOff)
        XCTAssertEqual(pattern.cycle[2].startTime, ShiftType.time(19))
        XCTAssertEqual(pattern.cycle[2].endTime, ShiftType.time(7))
        XCTAssertEqual(pattern.cycle[8].startTime, ShiftType.time(15, 30))
        XCTAssertEqual(pattern.cycle[8].endTime, ShiftType.time(23, 15))
        XCTAssertEqual(pattern.cycle[8].colorHex, "#FFD43B")

        XCTAssertEqual(pattern.overrides.count, 1)
        let entry = RotaEngine.entry(on: holidayDay, for: pattern, calendar: Fixtures.london)
        XCTAssertEqual(entry.shift, .holiday)
        XCTAssertTrue(entry.isOverride)
        XCTAssertEqual(entry.note, "Cornwall")

        // The month dot shows and the summary strip excludes the holiday (definition of done).
        let october = RotaEngine.shifts(in: Fixtures.month(2026, 10), for: pattern, calendar: Fixtures.london)
        XCTAssertEqual(october.filter(\.isOverride).count, 1)
        let summary = RotaEngine.summary(of: october)
        let plain = pattern.snapshotWithoutOverrides
        let plainSummary = RotaEngine.summary(of: RotaEngine.shifts(in: Fixtures.month(2026, 10), for: plain, calendar: Fixtures.london))
        let underlying = RotaEngine.shift(on: holidayDay, for: plain, calendar: Fixtures.london)
        let lost = underlying.isWorked ? 1 : 0
        XCTAssertEqual(summary.shifts, plainSummary.shifts - lost)
        XCTAssertEqual(summary.off, plainSummary.off + lost)
    }

    func testDeletingPatternCascadesToOverrides() throws {
        let container = try openStore()
        let context = container.mainContext
        let pattern = Pattern(name: "Temp", startDate: Fixtures.referenceStart,
                              cycle: [.day, .off], createdAt: Fixtures.referenceStart)
        context.insert(pattern)
        context.insert(Override(date: Fixtures.day(2026, 2, 2), shift: .sick, pattern: pattern))
        try context.save()
        XCTAssertEqual(try context.fetch(FetchDescriptor<Override>()).count, 1)

        context.delete(pattern)
        try context.save()
        XCTAssertEqual(try context.fetch(FetchDescriptor<Pattern>()).count, 0)
        XCTAssertEqual(try context.fetch(FetchDescriptor<Override>()).count, 0)
    }
}

private extension Pattern {
    var snapshotWithoutOverrides: PatternSnapshot {
        PatternSnapshot(id: id, name: name, startDate: startDate, cycle: cycle)
    }
}
#endif
