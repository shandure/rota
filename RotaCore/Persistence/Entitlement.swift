import Foundation

/// The cached unlock state, shared with the widget through the App Group's UserDefaults.
/// StoreKit remains the source of truth; `PurchaseManager` refreshes this on launch and on
/// every transaction update.
public enum Entitlement {
    public static let key = "isUnlocked"

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: AppGroup.id) ?? .standard
    }

    public static var isUnlocked: Bool {
        get { defaults.bool(forKey: key) }
        set { defaults.set(newValue, forKey: key) }
    }
}
