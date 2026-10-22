import Foundation
import PostHog
import RotaCore

/// The events in §8. Properties are counts, flags and fixed identifiers only:
/// never pattern names, notes, dates or shift times.
enum AnalyticsEvent {
    case appOpened(patternCount: Int, hasPurchased: Bool, calendarSyncOn: Bool)
    case patternCreated(cycleLength: Int, preset: String, distinctShiftKinds: Int)
    case patternEdited(cycleLength: Int)
    case patternDeleted(ageDays: Int)
    case overrideSet(kind: String, hasNote: Bool)
    case monthChanged(direction: MonthDirection)
    case paywallShown(trigger: PaywallTrigger)
    case purchaseCompleted(price: String)
    case purchaseRestored
    case calendarSyncToggled(on: Bool, permissionGranted: Bool)

    enum MonthDirection: String { case forward, back, today }

    var name: String {
        switch self {
        case .appOpened: return "app_opened"
        case .patternCreated: return "pattern_created"
        case .patternEdited: return "pattern_edited"
        case .patternDeleted: return "pattern_deleted"
        case .overrideSet: return "override_set"
        case .monthChanged: return "month_changed"
        case .paywallShown: return "paywall_shown"
        case .purchaseCompleted: return "purchase_completed"
        case .purchaseRestored: return "purchase_restored"
        case .calendarSyncToggled: return "calendar_sync_toggled"
        }
    }

    var properties: [String: Any] {
        switch self {
        case let .appOpened(patternCount, hasPurchased, calendarSyncOn):
            return ["pattern_count": patternCount, "has_purchased": hasPurchased, "calendar_sync_on": calendarSyncOn]
        case let .patternCreated(cycleLength, preset, distinctShiftKinds):
            return ["cycle_length": cycleLength, "preset": preset, "distinct_shift_kinds": distinctShiftKinds]
        case let .patternEdited(cycleLength):
            return ["cycle_length": cycleLength]
        case let .patternDeleted(ageDays):
            return ["age_days": ageDays]
        case let .overrideSet(kind, hasNote):
            return ["kind": kind, "has_note": hasNote]
        case let .monthChanged(direction):
            return ["direction": direction.rawValue]
        case let .paywallShown(trigger):
            return ["trigger": trigger.rawValue]
        case let .purchaseCompleted(price):
            return ["price": price]
        case .purchaseRestored:
            return [:]
        case let .calendarSyncToggled(on, permissionGranted):
            return ["on": on, "permission_granted": permissionGranted]
        }
    }

    /// The `kind` value for `override_set`: day/night/late/early/off/custom/holiday/sick.
    static func overrideKind(for shift: ShiftType) -> String {
        if shift.isSameType(as: .holiday) { return "holiday" }
        if shift.isSameType(as: .sick) { return "sick" }
        return shift.kind.rawValue
    }
}

/// One `track` function (§Structure). PostHog is only started with a key from the build
/// setting `POSTHOG_API_KEY`; it stays off in tests, demo launches, and unkeyed builds.
enum Analytics {
    static let host = "https://eu.i.posthog.com"
    private(set) static var isEnabled = false

    static func start() {
        guard !PurchaseManager.isRunningTests, !DemoData.isRequested,
              let key = Bundle.main.object(forInfoDictionaryKey: "PostHogAPIKey") as? String,
              !key.isEmpty else { return }
        let config = PostHogConfig(apiKey: key, host: host)
        config.captureApplicationLifecycleEvents = false
        config.captureScreenViews = false
        PostHogSDK.shared.setup(config)
        isEnabled = true
    }

    static func track(_ event: AnalyticsEvent) {
        guard isEnabled else { return }
        PostHogSDK.shared.capture(event.name, properties: event.properties)
    }
}
