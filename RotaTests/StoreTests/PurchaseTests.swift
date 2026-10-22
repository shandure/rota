import XCTest
import StoreKit
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
        Entitlement.isUnlocked = false
    }

    override func tearDown() {
        session.clearTransactions()
        Entitlement.isUnlocked = false
    }

    func testConfigurationFileIsInTheTestBundle() throws {
        let url = try XCTUnwrap(Bundle(for: PurchaseTests.self).url(forResource: "Rota", withExtension: "storekit"),
                                "Rota.storekit missing from the test bundle")
        let data = try Data(contentsOf: url)
        let json = try XCTUnwrap(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        let products = try XCTUnwrap(json["products"] as? [[String: Any]])
        XCTAssertEqual(products.first?["productID"] as? String, PurchaseManager.productID)
        print("StoreKit config at \(url.path); storefront \(session.storefront); session transactions \(session.allTransactions().count)")
    }

    func testProductLoadsWithLocalPriceAndStartsLocked() async throws {
        let manager = try await loadedManager()
        XCTAssertEqual(manager.product?.id, PurchaseManager.productID)
        XCTAssertNotEqual(manager.priceText, "", "price text: \(manager.priceText)")
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
        let direct: String
        do {
            let products = try await Product.products(for: [PurchaseManager.productID])
            direct = "direct fetch returned \(products.count) products"
        } catch {
            direct = "direct fetch threw \(error)"
        }
        let legacy = await LegacyProductFetch.run(productID: PurchaseManager.productID)
        // Seen on GitHub's macOS runners with the iOS 26 simulator: neither StoreKit 1 nor 2 can
        // see the local configuration, even with SKTestSession and the scheme both set up.
        // Purchase and restore are then verified in the App Store sandbox via TestFlight (§Release).
        throw XCTSkip("StoreKit test environment unavailable: no product \(PurchaseManager.productID); " +
                      "last error: \(String(describing: manager.lastLoadError)); \(direct); " +
                      "StoreKit 1: \(legacy); session transactions: \(session.allTransactions().count)")
    }

    /// StoreKit 1 product request, used only to diagnose an empty StoreKit 2 result.
    private final class LegacyProductFetch: NSObject, SKProductsRequestDelegate {
        private var continuation: CheckedContinuation<String, Never>?
        private var request: SKProductsRequest?

        static func run(productID: String) async -> String {
            let fetch = LegacyProductFetch()
            return await withCheckedContinuation { continuation in
                fetch.continuation = continuation
                let request = SKProductsRequest(productIdentifiers: [productID])
                request.delegate = fetch
                fetch.request = request
                request.start()
                DispatchQueue.main.asyncAfter(deadline: .now() + 10) { fetch.finish("timed out") }
            }
        }

        func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
            finish("\(response.products.count) products, invalid ids \(response.invalidProductIdentifiers)")
        }

        func request(_ request: SKRequest, didFailWithError error: Error) {
            finish("failed: \(error)")
        }

        private func finish(_ result: String) {
            continuation?.resume(returning: result)
            continuation = nil
        }
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
