import SwiftUI
import StoreKit
import Observation

public enum SubscriptionTier: String, CaseIterable, Identifiable {
    case monthly = "com.mathurharsh.milestonetheapp.pro.monthly"
    case annual = "com.mathurharsh.milestonetheapp.pro.annual"
    case lifetime = "com.mathurharsh.milestonetheapp.pro.lifetime"

    public var id: String { rawValue }

    public var defaultPrice: String {
        switch self {
        case .monthly: return "$3.99/mo"
        case .annual: return "$29.99/yr"
        case .lifetime: return "$49.99"
        }
    }

    public var title: String {
        switch self {
        case .monthly: return "Monthly"
        case .annual: return "Annual"
        case .lifetime: return "Lifetime"
        }
    }

    public var subtitle: String {
        switch self {
        case .monthly: return "Billed monthly. Cancel anytime."
        case .annual: return "$2.49/mo • 7-day free trial"
        case .lifetime: return "One-time payment. Forever yours."
        }
    }
}

@MainActor
@Observable
public final class SubscriptionStore {
    public static let shared = SubscriptionStore()

    // All possible Product IDs (with and without .pro. in App Store Connect)
    public static let allPossibleIDs: Set<String> = [
        "com.mathurharsh.milestonetheapp.pro.monthly",
        "com.mathurharsh.milestonetheapp.monthly",
        "com.mathurharsh.milestonetheapp.pro.annual",
        "com.mathurharsh.milestonetheapp.annual",
        "com.mathurharsh.milestonetheapp.pro.lifetime",
        "com.mathurharsh.milestonetheapp.lifetime"
    ]

    public var isTestFlightOrSandbox: Bool {
        #if DEBUG
        return true
        #else
        return Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
        #endif
    }

    public var isProUser: Bool = false
    public var products: [Product] = []
    public var isLoading: Bool = false
    public var errorMessage: String?
    public var purchasedSubscription: Product?

    private var updatesTask: Task<Void, Never>?

    public init() {
        // Load offline cached entitlement
        self.isProUser = UserDefaults.standard.bool(forKey: "milestone:isProUser")

        // Start real-time transaction updates listener
        self.updatesTask = listenForTransactions()

        Task {
            await requestProducts()
            await updateCustomerProductStatus()
        }
    }

    // ── 1. Fetch StoreKit 2 Products ──
    public func requestProducts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let storeProducts = try await Product.products(for: SubscriptionStore.allPossibleIDs)

            // Sort: Annual first (highest conversion), then Monthly, then Lifetime
            self.products = storeProducts.sorted { p1, p2 in
                if p1.id.contains("annual") { return true }
                if p2.id.contains("annual") { return false }
                return p1.price < p2.price
            }
        } catch {
            print("Failed to fetch products: \(error.localizedDescription)")
            self.errorMessage = "Unable to load App Store products."
        }
    }

    // ── 2. Purchase Flow ──
    public func purchase(_ product: Product) async throws -> Bool {
        isLoading = true
        defer { isLoading = false }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updateCustomerProductStatus()
            await transaction.finish()
            HapticsManager.shared.notification(.success)
            return true

        case .userCancelled:
            return false

        case .pending:
            return false

        @unknown default:
            return false
        }
    }

    // ── 3. Restore Purchases ──
    public func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await AppStore.sync()
            await updateCustomerProductStatus()
            if isProUser {
                HapticsManager.shared.notification(.success)
            } else {
                HapticsManager.shared.notification(.warning)
                errorMessage = "No active subscription found to restore."
            }
        } catch {
            errorMessage = "Failed to restore purchases: \(error.localizedDescription)"
        }
    }

    // ── 4. Verify Active Entitlements ──
    public func updateCustomerProductStatus() async {
        var hasActiveEntitlement = false

        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)

                if transaction.revocationDate == nil {
                    hasActiveEntitlement = true
                    break
                }
            } catch {
                print("Entitlement verification error: \(error)")
            }
        }

        self.isProUser = hasActiveEntitlement
        UserDefaults.standard.set(hasActiveEntitlement, forKey: "milestone:isProUser")
    }

    // ── 5. Real-time Transaction Listener ──
    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    await self.updateCustomerProductStatus()
                    await transaction.finish()
                } catch {
                    print("Transaction update failed verification: \(error)")
                }
            }
        }
    }

    // ── 6. JWS Verification ──
    private nonisolated func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(let unverified, let error):
#if DEBUG
            print("StoreKit verification note: \(error.localizedDescription) - accepted in DEBUG")
            return unverified
#else
            throw error
#endif
        case .verified(let safe):
            return safe
        }
    }

    public func activatePro() {
        self.isProUser = true
        UserDefaults.standard.set(true, forKey: "milestone:isProUser")
        HapticsManager.shared.notification(.success)
    }

#if DEBUG
    // Debug toggle for testing Pro experience in simulator
    public func toggleDebugPro() {
        self.isProUser.toggle()
        UserDefaults.standard.set(isProUser, forKey: "milestone:isProUser")
        HapticsManager.shared.notification(.success)
    }
#endif
}
