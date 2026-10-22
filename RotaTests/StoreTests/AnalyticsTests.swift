import XCTest
import RotaCore
@testable import Rota

/// Event names and properties match §8, and nothing identifying can be sent.
final class AnalyticsTests: XCTestCase {
    private let allEvents: [AnalyticsEvent] = [
        .appOpened(patternCount: 2, hasPurchased: false, calendarSyncOn: true),
        .patternCreated(cycleLength: 8, preset: Preset.twoDayTwoNightFourOff.analyticsName, distinctShiftKinds: 3),
        .patternEdited(cycleLength: 9),
        .patternDeleted(ageDays: 40),
        .overrideSet(kind: AnalyticsEvent.overrideKind(for: .holiday), hasNote: true),
        .monthChanged(direction: .today),
        .paywallShown(trigger: .secondPattern),
        .purchaseCompleted(price: "£4.99"),
        .purchaseRestored,
        .calendarSyncToggled(on: true, permissionGranted: false),
    ]

    func testNamesAndPropertyKeysMatchTheSpec() {
        let expected: [String: Set<String>] = [
            "app_opened": ["pattern_count", "has_purchased", "calendar_sync_on"],
            "pattern_created": ["cycle_length", "preset", "distinct_shift_kinds"],
            "pattern_edited": ["cycle_length"],
            "pattern_deleted": ["age_days"],
            "override_set": ["kind", "has_note"],
            "month_changed": ["direction"],
            "paywall_shown": ["trigger"],
            "purchase_completed": ["price"],
            "purchase_restored": [],
            "calendar_sync_toggled": ["on", "permission_granted"],
        ]
        XCTAssertEqual(Set(allEvents.map(\.name)), Set(expected.keys))
        for event in allEvents {
            XCTAssertEqual(Set(event.properties.keys), expected[event.name], event.name)
        }
    }

    func testPropertyValuesAreOnlyNumbersBoolsAndFixedStrings() {
        let allowedStrings: Set<String> = Set(Preset.allCases.map(\.analyticsName))
            .union(["day", "night", "late", "early", "off", "custom", "holiday", "sick"])
            .union(["forward", "back", "today"])
            .union(["second_pattern", "calendar", "widget", "settings"])
            .union(["£4.99"])
        for event in allEvents {
            for (key, value) in event.properties {
                switch value {
                case is Int, is Bool:
                    continue
                case let text as String:
                    XCTAssertTrue(allowedStrings.contains(text), "\(event.name).\(key) = \(text)")
                default:
                    XCTFail("\(event.name).\(key) has unexpected type \(type(of: value))")
                }
            }
        }
    }

    func testOverrideKindMapping() {
        XCTAssertEqual(AnalyticsEvent.overrideKind(for: .day), "day")
        XCTAssertEqual(AnalyticsEvent.overrideKind(for: .night), "night")
        XCTAssertEqual(AnalyticsEvent.overrideKind(for: .off), "off")
        XCTAssertEqual(AnalyticsEvent.overrideKind(for: .holiday), "holiday")
        XCTAssertEqual(AnalyticsEvent.overrideKind(for: .sick), "sick")
        XCTAssertEqual(AnalyticsEvent.overrideKind(for: ShiftType(kind: .custom, label: "TWI", colorHex: "#FF6B6B")), "custom")
    }

    func testAnalyticsStaysOffUnderTests() {
        Analytics.start()
        XCTAssertFalse(Analytics.isEnabled)
        Analytics.track(.purchaseRestored)   // must be a no-op, not a crash
    }
}
