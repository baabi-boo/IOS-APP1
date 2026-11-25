import Foundation
import Observation
import StoreKit

/// StoreKit 2 wrapper for Dewy+ (monthly, yearly and lifetime unlock).
@MainActor
@Observable
final class PurchaseManager {
    enum Plan: String, CaseIterable, Identifiable {
        case yearly = "dewy.plus.yearly"
        case monthly = "dewy.plus.monthly"
        case lifetime = "dewy.plus.lifetime"

        var id: String { rawValue }

        var title: String {
            switch self {
            case .yearly: "Yearly"
            case .monthly: "Monthly"
            case .lifetime: "Lifetime"
            }
        }

        /// Shown until the App Store responds (or in demo mode).
        var fallbackPrice: String {
            switch self {
            case .yearly: "$19.99"
            case .monthly: "$2.99"
            case .lifetime: "$39.99"
            }
        }

        var cadence: String {
            switch self {
            case .yearly: "/ year"
            case .monthly: "/ month"
            case .lifetime: "once"
            }
        }

        var detail: String {
            switch self {
            case .yearly: "3 days free, then $1.67/mo"
            case .monthly: "Cancel anytime"
            case .lifetime: "Pay once, sip forever"
            }
        }

        var badge: String? {
            switch self {
            case .yearly: "SAVE 44%"
            case .monthly: nil
            case .lifetime: "BEST DEAL"
            }
        }
    }

    private(set) var products: [String: Product] = [:]
    private(set) var purchasedIDs: Set<String> = []
    private(set) var isPurchasing = false
    var errorMessage: String?

    @ObservationIgnored private var updatesTask: Task<Void, Never>?
    private let forcedPremium = LaunchOptions.forcePremium

    var isPremium: Bool { forcedPremium || !purchasedIDs.isEmpty }

    init() {
        updatesTask = Task { [weak self] in
            for await result in StoreKit.Transaction.updates {
                await self?.handle(result)
            }
        }
    }

    func start() async {
        guard !LaunchOptions.isDemo else { return }
        await loadProducts()
        await refreshEntitlements()
    }

    func price(for plan: Plan) -> String {
        products[plan.rawValue]?.displayPrice ?? plan.fallbackPrice
    }

    func loadProducts() async {
        do {
            let loaded = try await Product.products(for: Plan.allCases.map(\.rawValue))
            products = Dictionary(uniqueKeysWithValues: loaded.map { ($0.id, $0) })
        } catch {
            errorMessage = "Couldn't reach the App Store."
        }
    }

    func refreshEntitlements() async {
        var ids = Set<String>()
        for await result in StoreKit.Transaction.currentEntitlements {
            if case .verified(let transaction) = result, transaction.revocationDate == nil {
                ids.insert(transaction.productID)
            }
        }
        purchasedIDs = ids
    }

    /// Returns `true` when the purchase completed and Dewy+ is unlocked.
    func purchase(_ plan: Plan) async -> Bool {
        guard let product = products[plan.rawValue] else {
            errorMessage = "This plan isn't available right now. Please try again in a moment."
            return false
        }
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                guard case .verified(let transaction) = verification else { return false }
                purchasedIDs.insert(transaction.productID)
                await transaction.finish()
                return true
            case .pending, .userCancelled:
                return false
            @unknown default:
                return false
            }
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func restore() async {
        do {
            try await AppStore.sync()
        } catch {
            errorMessage = "Restore failed: \(error.localizedDescription)"
        }
        await refreshEntitlements()
    }

    private func handle(_ result: VerificationResult<StoreKit.Transaction>) async {
        guard case .verified(let transaction) = result else { return }
        if transaction.revocationDate == nil {
            purchasedIDs.insert(transaction.productID)
        } else {
            purchasedIDs.remove(transaction.productID)
        }
        await transaction.finish()
    }
}
