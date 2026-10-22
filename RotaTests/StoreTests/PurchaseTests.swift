import XCTest
import StoreKitTest
import RotaCore
@testable import Rota

/// Purchase and restore against Apple's local StoreKit test session, using Rota.storekit.
/// Apple platforms only; the Linux package build does not compile this folder.
///
/// Every StoreKit await is wrapped in `withTimeout` so a stalled StoreKit call fails the test
/// by name instead of hanging the CI job.
@MainActor
final class PurchaseTests: XCTestCase {
    private var session: SKTestSession!

    override func setUpWithError() throws {
        session = try SKTestSession(configurationFileNamed: "Rota")
        session.disableDialogs = true
        session.clearTransactions()
        session.storefront = "GBR"
        session.locale = Locale(identifier: "en_GB")
        Entitlement.isUnlocked = false
    }

    override func tearDown() {
        session.clearTransactions()
        Entitlement.isUnlocked = false
    }

    func testProductLoadsWithLocalPriceAndStartsLocked() async throws {
        let manager = try await loadedManager()
        XCTAssertEqual(manager.product?.id, PurchaseManager.productID)
        XCTAssertEqual(manager.priceText, "£4.99")
        XCTAssertFalse(manager.isUnlocked)
    }

    func testPurchaseUnlocksAndPersists() async throws {
        let manager = try await loadedManager()

        let outcome = try await withTimeout { try await manager.purchase() }
        XCTAssertEqual(outcome, .purchased)
        XCTAssertTrue(manager.isUnlocked)
        XCTAssertTrue(Entitlement.isUnlocked)

        // Next launch: a fresh manager starts from the cached entitlement and StoreKit agrees.
        let fresh = PurchaseManager()
        XCTAssertTrue(fresh.isUnlocked)
        try await withTimeout { await fresh.load() }
        XCTAssertTrue(fresh.isUnlocked)
    }

    func testEntitlementComesBackAfterCacheIsLost() async throws {
        let manager = try await loadedManager()
        _ = try await withTimeout { try await manager.purchase() }

        // Simulate a reinstall: cache gone, transaction still on the account.
        Entitlement.isUnlocked = false
        let fresh = PurchaseManager()
        XCTAssertFalse(fresh.isUnlocked)
        try await withTimeout { await fresh.refreshEntitlement() }
        XCTAssertTrue(fresh.isUnlocked)
    }

    // MARK: Helpers

    /// A manager whose product has loaded. The test session can take a moment to serve
    /// products after it is created, so this polls for up to ~10 seconds.
    private func loadedManager() async throws -> PurchaseManager {
        let manager = PurchaseManager()
        for _ in 0..<20 {
            try await withTimeout { await manager.load() }
            if manager.product != nil { return manager }
            try await Task.sleep(for: .milliseconds(500))
        }
        XCTFail("StoreKit test session never served \(PurchaseManager.productID)")
        return manager
    }

    private struct TimedOut: Error {}

    /// Runs `operation` and fails if it has not returned within `seconds`.
    private func withTimeout<T: Sendable>(seconds: Double = 20,
                                          _ operation: @escaping @Sendable () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask { try await operation() }
            group.addTask {
                try await Task.sleep(for: .seconds(seconds))
                throw TimedOut()
            }
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
}
