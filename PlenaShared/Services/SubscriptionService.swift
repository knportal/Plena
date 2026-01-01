//
//  SubscriptionService.swift
//  PlenaShared
//
//  StoreKit 2 subscription management service
//

import Foundation
import StoreKit
import Combine

@MainActor
protocol SubscriptionServiceProtocol {
    var subscriptionStatus: CurrentValueSubject<SubscriptionStatus, Never> { get }
    var isLoading: CurrentValueSubject<Bool, Never> { get }
    var currentProductID: CurrentValueSubject<String?, Never> { get }

    func loadProducts() async throws -> [Product]
    func purchase(_ product: Product) async throws -> Transaction?
    func restorePurchases() async throws
    func checkSubscriptionStatus() async
    func currentSubscriptionStatus() -> SubscriptionStatus
    func clearCache() // For testing/debugging
}

@MainActor
class SubscriptionService: SubscriptionServiceProtocol {
    private(set) var subscriptionStatus = CurrentValueSubject<SubscriptionStatus, Never>(.notSubscribed)
    private(set) var isLoading = CurrentValueSubject<Bool, Never>(false)
    private(set) var currentProductID = CurrentValueSubject<String?, Never>(nil)

    private var updateListenerTask: Task<Void, Error>?

    // Cache keys for UserDefaults
    private enum CacheKeys {
        static let lastVerifiedTimestamp = "subscription_last_verified_timestamp"
        static let cachedStatus = "subscription_cached_status"
        static let cachedExpirationDate = "subscription_cached_expiration_date"
        static let cachedProductID = "subscription_cached_product_id" // Persist productID across instances
    }

    init() {
        // Load cached productID from UserDefaults to persist across instances
        if let cachedProductID = UserDefaults.standard.string(forKey: CacheKeys.cachedProductID),
           SubscriptionProduct.all.contains(cachedProductID) {
            currentProductID.send(cachedProductID)
        }

        // Start listening for transaction updates
        updateListenerTask = listenForTransactions()

        // Load initial subscription status
        Task {
            await checkSubscriptionStatus()
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Product Loading

    func loadProducts() async throws -> [Product] {
        isLoading.send(true)
        defer { isLoading.send(false) }

        do {
            let products = try await Product.products(for: SubscriptionProduct.all)
            return products
        } catch {
            throw SubscriptionError.productLoadFailed(error)
        }
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async throws -> Transaction? {
        // Store the product ID we're purchasing (critical for upgrades where transaction might have different productID)
        let purchasedProductID = product.id
        isLoading.send(true)
        defer { isLoading.send(false) }

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)

                // CRITICAL: For upgrades, StoreKit may return the original subscription's transaction
                // We must use the product ID we actually purchased, not the transaction's productID
                let productIDToUse: String
                if transaction.productID != purchasedProductID {
                    productIDToUse = purchasedProductID
                } else {
                    productIDToUse = transaction.productID
                }

                await transaction.finish()

                // CRITICAL: Immediately update product ID from what we actually purchased
                // For upgrades, this is the annual productID, not the monthly transaction's productID
                if SubscriptionProduct.all.contains(productIDToUse) {
                    currentProductID.send(productIDToUse)
                    // Persist to UserDefaults immediately so it survives across service instances
                    UserDefaults.standard.set(productIDToUse, forKey: CacheKeys.cachedProductID)
                }

                // Check status, but the productID we just set should take precedence
                await checkSubscriptionStatus()

                // CRITICAL: Always ensure the purchased productID is set, especially for upgrades
                // This handles cases where checkSubscriptionStatus might not find it yet
                if SubscriptionProduct.all.contains(productIDToUse) {
                    let currentID = currentProductID.value
                    if currentID != productIDToUse {
                        currentProductID.send(productIDToUse)
                        UserDefaults.standard.set(productIDToUse, forKey: CacheKeys.cachedProductID)
                    }
                }
                return transaction
            case .userCancelled:
                throw SubscriptionError.userCancelled
            case .pending:
                throw SubscriptionError.purchasePending
            @unknown default:
                throw SubscriptionError.unknownPurchaseResult
            }
        } catch let error as SubscriptionError {
            throw error
        } catch {
            throw SubscriptionError.purchaseFailed(error)
        }
    }

    // MARK: - Restore Purchases

    func restorePurchases() async throws {
        isLoading.send(true)
        defer { isLoading.send(false) }

        try await AppStore.sync()
        await checkSubscriptionStatus()
    }

    // MARK: - Cache Management (for testing)

    /// Clear all cached subscription data (useful for testing)
    func clearCache() {
        UserDefaults.standard.removeObject(forKey: CacheKeys.lastVerifiedTimestamp)
        UserDefaults.standard.removeObject(forKey: CacheKeys.cachedStatus)
        UserDefaults.standard.removeObject(forKey: CacheKeys.cachedExpirationDate)
        UserDefaults.standard.removeObject(forKey: CacheKeys.cachedProductID)
        currentProductID.send(nil)
    }

    // MARK: - Subscription Status Checking

    func checkSubscriptionStatus() async {
        var highestStatus: SubscriptionStatus = .notSubscribed
        var activePremiumProductIDs: [String] = []
        var latestExpirationDate: Date? = nil
        var mostRecentTransactionDate: Date? = nil
        var mostRecentProductID: String? = nil

        // First pass: Collect all active premium subscription product IDs from currentEntitlements
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)

                // Check if this is a subscription product
                if SubscriptionProduct.all.contains(transaction.productID) {
                    let tier = SubscriptionProduct.tier(for: transaction.productID)

                    // Check expiration
                    if let expirationDate = transaction.expirationDate {
                        if expirationDate > Date() {
                            // Active subscription
                            if tier.isPremium {
                                activePremiumProductIDs.append(transaction.productID)
                                // Track the latest expiration date
                                if latestExpirationDate == nil || expirationDate > latestExpirationDate! {
                                    latestExpirationDate = expirationDate
                                    highestStatus = .subscribed(tier: tier, expirationDate: expirationDate)
                                }
                                // Track the most recent purchase (for upgrades)
                                if mostRecentTransactionDate == nil || transaction.purchaseDate > mostRecentTransactionDate! {
                                    mostRecentTransactionDate = transaction.purchaseDate
                                    mostRecentProductID = transaction.productID
                                }
                            }
                        } else {
                            // Expired
                            if case .notSubscribed = highestStatus {
                                highestStatus = .expired
                            }
                        }
                    } else {
                        // No expiration (shouldn't happen for subscriptions, but handle it)
                        if tier.isPremium {
                            activePremiumProductIDs.append(transaction.productID)
                            if latestExpirationDate == nil {
                                highestStatus = .subscribed(tier: tier, expirationDate: nil)
                            }
                            if mostRecentTransactionDate == nil || transaction.purchaseDate > mostRecentTransactionDate! {
                                mostRecentTransactionDate = transaction.purchaseDate
                                mostRecentProductID = transaction.productID
                            }
                        }
                    }
                }
            } catch {
                print("⚠️ Failed to verify transaction: \(error)")
            }
        }

        // Second pass: Choose the best product ID
        // Priority: 1) ProductID from recent purchase (if set), 2) Annual if it exists, 3) Monthly
        var foundProductID: String? = nil

        // First, check if we have a productID from a recent purchase (set immediately after purchase)
        // This takes precedence to handle timing issues where the purchase hasn't appeared in currentEntitlements yet
        let currentID = currentProductID.value

        if let currentID = currentID,
           SubscriptionProduct.all.contains(currentID) {
            // If the purchased productID is annual, ALWAYS use it (upgrade scenario)
            // This is critical - if user just purchased annual, use it regardless of what's in entitlements
            if currentID == SubscriptionProduct.annual {
                foundProductID = SubscriptionProduct.annual
            } else if !activePremiumProductIDs.contains(currentID) {
                // Recent purchase that hasn't appeared in currentEntitlements yet
                foundProductID = currentID
            } else {
                // CurrentID is in active entitlements - use it (handles case where purchase was processed quickly)
                foundProductID = currentID
            }
        }

        // If we didn't find a recent purchase productID, use the active entitlements
        if foundProductID == nil {
            // Always prefer annual if it exists (for upgrades, annual should replace monthly)
            if activePremiumProductIDs.contains(SubscriptionProduct.annual) {
                foundProductID = SubscriptionProduct.annual
            } else if activePremiumProductIDs.contains(SubscriptionProduct.monthly) {
                foundProductID = SubscriptionProduct.monthly
            } else if let mostRecent = mostRecentProductID {
                // Fallback to most recent if available
                foundProductID = mostRecent
            }
        }

        // Update current product ID after checking all transactions
        // CRITICAL: Only update if we found a productID AND it's "better" than what we have
        // This preserves a recently purchased annual productID even if entitlements haven't updated yet
        if let foundProductID = foundProductID {
            let existingProductID = currentProductID.value
            if existingProductID != foundProductID {
                // Only update if the found productID is "better" (annual > monthly)
                let shouldUpdate: Bool
                if foundProductID == SubscriptionProduct.annual {
                    // Always update to annual
                    shouldUpdate = true
                } else if existingProductID == SubscriptionProduct.annual {
                    // Don't downgrade from annual to monthly
                    shouldUpdate = false
                } else {
                    // Both are monthly or neither is set - update
                    shouldUpdate = true
                }

                if shouldUpdate {
                    currentProductID.send(foundProductID)
                    // Persist to UserDefaults so it survives across service instances
                    UserDefaults.standard.set(foundProductID, forKey: CacheKeys.cachedProductID)
                }
            }
        }

        // Update status
        subscriptionStatus.send(highestStatus)

        // Cache the status
        cacheSubscriptionStatus(highestStatus)

        // Post notification when status changes to premium
        if highestStatus.isPremium {
            NotificationCenter.default.post(
                name: NSNotification.Name("SubscriptionStatusChangedToPremium"),
                object: nil
            )
        }
    }

    func currentSubscriptionStatus() -> SubscriptionStatus {
        return subscriptionStatus.value
    }

    // MARK: - Transaction Verification

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw SubscriptionError.verificationFailed(error)
        case .verified(let safe):
            return safe
        }
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() -> Task<Void, Error> {
        return Task { @MainActor in
            for await result in Transaction.updates {
                do {
                    let transaction = try checkVerified(result)

                    // Check if this is one of our subscription products
                    if SubscriptionProduct.all.contains(transaction.productID) {
                        await checkSubscriptionStatus()
                    }

                    await transaction.finish()
                } catch {
                    print("⚠️ Transaction update verification failed: \(error)")
                }
            }
        }
    }

    // MARK: - Caching

    private func cacheSubscriptionStatus(_ status: SubscriptionStatus) {
        let timestamp = Date().timeIntervalSince1970
        UserDefaults.standard.set(timestamp, forKey: CacheKeys.lastVerifiedTimestamp)

        switch status {
        case .subscribed(let tier, let expirationDate):
            UserDefaults.standard.set(tier.rawValue, forKey: CacheKeys.cachedStatus)
            if let expirationDate = expirationDate {
                UserDefaults.standard.set(expirationDate, forKey: CacheKeys.cachedExpirationDate)
            } else {
                UserDefaults.standard.removeObject(forKey: CacheKeys.cachedExpirationDate)
            }
        case .expired:
            UserDefaults.standard.set("expired", forKey: CacheKeys.cachedStatus)
        case .notSubscribed, .revoked:
            UserDefaults.standard.set("notSubscribed", forKey: CacheKeys.cachedStatus)
            UserDefaults.standard.removeObject(forKey: CacheKeys.cachedExpirationDate)
        }
    }

    private func loadCachedStatus() -> SubscriptionStatus? {
        guard let cachedStatusString = UserDefaults.standard.string(forKey: CacheKeys.cachedStatus) else {
            return nil
        }

        switch cachedStatusString {
        case "expired":
            return .expired
        case "notSubscribed":
            return .notSubscribed
        default:
            // Try to parse as tier
            if let tier = SubscriptionTier(rawValue: cachedStatusString) {
                let expirationDate = UserDefaults.standard.object(forKey: CacheKeys.cachedExpirationDate) as? Date
                return .subscribed(tier: tier, expirationDate: expirationDate)
            }
            return nil
        }
    }
}

// MARK: - Subscription Errors

enum SubscriptionError: LocalizedError {
    case productLoadFailed(Error)
    case purchaseFailed(Error)
    case purchasePending
    case userCancelled
    case verificationFailed(Error)
    case unknownPurchaseResult

    var errorDescription: String? {
        switch self {
        case .productLoadFailed(let error):
            return "Failed to load products: \(error.localizedDescription)"
        case .purchaseFailed(let error):
            return "Purchase failed: \(error.localizedDescription)"
        case .purchasePending:
            return "Purchase is pending approval"
        case .userCancelled:
            return "Purchase was cancelled"
        case .verificationFailed(let error):
            return "Transaction verification failed: \(error.localizedDescription)"
        case .unknownPurchaseResult:
            return "Unknown purchase result"
        }
    }
}

