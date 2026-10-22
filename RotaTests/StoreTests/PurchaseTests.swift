import XCTest
import StoreKitTest
import RotaCore
@testable import Rota

/// Purchase and restore against Apple's local StoreKit test session, using Rota.storekit.
/// Apple platforms only; the Linux package build does not compile this folder.
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

    func testProductLoadsWithLocalPriceAndStartsLocked() async {
        let manager = PurchaseManager()
        await manager.load()
        XCTAssertEqual(manager.product?.id, PurchaseManager.productID)
        XCTAssertEqual(manager.priceText, "£4.99")
        XCTAssertFalse(manager.isUnlocked)
    }

    func testPurchaseUnlocksAndPersists() async throws {
        let manager = PurchaseManager()
        await manager.load()

        let outcome = try await manager.purchase()
        XCTAssertEqual(outcome, .purchased)
        XCTAssertTrue(manager.isUnlocked)
        XCTAssertTrue(Entitlement.isUnlocked)

        // Next launch: a fresh manager starts from the cached entitlement and StoreKit agrees.
        let fresh = PurchaseManager()
        XCTAssertTrue(fresh.isUnlocked)
        await fresh.load()
        XCTAssertTrue(fresh.isUnlocked)
    }

    func testEntitlementComesBackAfterCacheIsLost() async throws {
        let manager = PurchaseManager()
        await manager.load()
        _ = try await manager.purchase()

        // Simulate a reinstall: cache gone, transaction still on the account.
        Entitlement.isUnlocked = false
        let fresh = PurchaseManager()
        XCTAssertFalse(fresh.isUnlocked)
        await fresh.refreshEntitlement()
        XCTAssertTrue(fresh.isUnlocked)
    }

    func testRestoreWithoutPurchaseStaysLocked() async throws {
        let manager = PurchaseManager()
        await manager.load()
        try await manager.restore()
        XCTAssertFalse(manager.isUnlocked)
    }
}
