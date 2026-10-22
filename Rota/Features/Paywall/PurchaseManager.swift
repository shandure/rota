import Foundation
import StoreKit
import RotaCore

/// StoreKit 2 wrapper for the one non-consumable unlock (§2, §4.5).
@MainActor
@Observable
final class PurchaseManager {
    static let productID = "com.yourname.rota.unlock"
    /// Shown until the App Store price has loaded.
    static let fallbackPrice = "£4.99"

    enum Outcome: Equatable {
        case purchased, cancelled, pending
    }

    enum PurchaseError: LocalizedError {
        case productUnavailable
        case unverified

        var errorDescription: String? {
            switch self {
            case .productUnavailable: return "The App Store is not available right now."
            case .unverified: return "The purchase could not be verified."
            }
        }
    }

    private(set) var isUnlocked: Bool
    private(set) var product: Product?
    /// The last error from loading the product, for diagnostics.
    private(set) var lastLoadError: Error?
    private var updatesTask: Task<Void, Never>?

    init() {
        isUnlocked = Entitlement.isUnlocked
        updatesTask = Task { [weak self] in await self?.listenForTransactions() }
    }

    var priceText: String { product?.displayPrice ?? Self.fallbackPrice }

    /// Loads the product and refreshes the entitlement. Safe to call more than once.
    func load() async {
        if product == nil {
            do {
                product = try await Product.products(for: [Self.productID]).first
                lastLoadError = nil
            } catch {
                lastLoadError = error
            }
        }
        await refreshEntitlement()
    }

    /// Re-reads current entitlements from StoreKit.
    func refreshEntitlement() async {
        var unlocked = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.productID,
               transaction.revocationDate == nil {
                unlocked = true
            }
        }
        setUnlocked(unlocked)
    }

    func purchase() async throws -> Outcome {
        guard let product else { throw PurchaseError.productUnavailable }
        switch try await product.purchase() {
        case .success(let verification):
            guard case .verified(let transaction) = verification else { throw PurchaseError.unverified }
            await transaction.finish()
            setUnlocked(true)
            return .purchased
        case .userCancelled:
            return .cancelled
        case .pending:
            return .pending
        @unknown default:
            return .cancelled
        }
    }

    func restore() async throws {
        try await AppStore.sync()
        await refreshEntitlement()
    }

    // MARK: Private

    private func listenForTransactions() async {
        for await result in Transaction.updates {
            guard case .verified(let transaction) = result else { continue }
            if transaction.productID == Self.productID {
                setUnlocked(transaction.revocationDate == nil)
            }
            await transaction.finish()
        }
    }

    private func setUnlocked(_ value: Bool) {
        isUnlocked = value
        Entitlement.isUnlocked = value
    }
}
