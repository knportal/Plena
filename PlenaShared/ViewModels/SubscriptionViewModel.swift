//
//  SubscriptionViewModel.swift
//  PlenaShared
//
//  ViewModel for subscription management
//

import Foundation
import Combine
import StoreKit

@MainActor
class SubscriptionViewModel: ObservableObject {
    @Published var products: [Product] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var purchaseInProgress = false
    @Published var subscriptionStatus: SubscriptionStatus = .notSubscribed
    @Published var currentProductID: String? = nil // Make this @Published so view can observe changes

    let subscriptionService: SubscriptionServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    init(subscriptionService: SubscriptionServiceProtocol) {
        self.subscriptionService = subscriptionService

        // Observe subscription status changes
        subscriptionService.subscriptionStatus
            .receive(on: DispatchQueue.main)
            .assign(to: &$subscriptionStatus)

        subscriptionService.isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: &$isLoading)

        // Refresh products when subscription status changes to ensure UI updates
        subscriptionService.subscriptionStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.loadProducts()
                }
            }
            .store(in: &cancellables)

        // Observe current product ID changes and update @Published property
        subscriptionService.currentProductID
            .receive(on: DispatchQueue.main)
            .sink { [weak self] productID in
                // Update @Published property to trigger view updates
                self?.currentProductID = productID
            }
            .store(in: &cancellables)

        // Initialize currentProductID from service
        currentProductID = subscriptionService.currentProductID.value
    }

    func loadProducts() async {
        isLoading = true
        errorMessage = nil

        do {
            let loadedProducts = try await subscriptionService.loadProducts()
            products = loadedProducts.sorted { product1, product2 in
                // Sort monthly before annual
                if product1.id == SubscriptionProduct.monthly {
                    return true
                }
                if product2.id == SubscriptionProduct.monthly {
                    return false
                }
                return product1.id < product2.id
            }

            // Check if no products were loaded (e.g., invalid product IDs)
            if products.isEmpty {
                errorMessage = "No subscription products available. Please check your connection and try again."
            }
        } catch {
            errorMessage = "Failed to load subscription products: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func purchase(_ product: Product) async {
        purchaseInProgress = true
        errorMessage = nil

        do {
            // Check if this is an upgrade (purchasing annual while having monthly)
            let isUpgrade = hasPremium &&
                           currentProductID == SubscriptionProduct.monthly &&
                           product.id == SubscriptionProduct.annual

            _ = try await subscriptionService.purchase(product)
            // Force refresh subscription status after purchase to get updated product ID
            await subscriptionService.checkSubscriptionStatus()

            if isUpgrade {
                // For upgrades, give StoreKit time to process the upgrade transaction
                // Check status multiple times with increasing delays
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                await subscriptionService.checkSubscriptionStatus()

                try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
                await subscriptionService.checkSubscriptionStatus()

                // One more check after a longer delay to ensure StoreKit has processed everything
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                await subscriptionService.checkSubscriptionStatus()
            } else {
                // For new purchases, just wait a moment
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                await subscriptionService.checkSubscriptionStatus()
            }
        } catch {
            if let subscriptionError = error as? SubscriptionError {
                switch subscriptionError {
                case .userCancelled:
                    // User cancelled, don't show error
                    break
                default:
                    errorMessage = subscriptionError.localizedDescription
                }
            } else {
                errorMessage = error.localizedDescription
            }
        }

        purchaseInProgress = false
    }

    func restorePurchases() async {
        isLoading = true
        errorMessage = nil

        do {
            try await subscriptionService.restorePurchases()
        } catch {
            errorMessage = "Failed to restore purchases: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Get monthly product
    var monthlyProduct: Product? {
        products.first { $0.id == SubscriptionProduct.monthly }
    }

    /// Get annual product
    var annualProduct: Product? {
        products.first { $0.id == SubscriptionProduct.annual }
    }

    /// Current tier
    var currentTier: SubscriptionTier {
        subscriptionStatus.tier
    }

    /// Whether user has premium
    var hasPremium: Bool {
        subscriptionStatus.isPremium
    }

    /// Subscription expiration date if subscribed
    var expirationDate: Date? {
        switch subscriptionStatus {
        case .subscribed(_, let expirationDate):
            return expirationDate
        default:
            return nil
        }
    }

    // currentProductID is now @Published property above, no need for computed property

    /// Publisher for current product ID changes
    var currentProductIDPublisher: AnyPublisher<String?, Never> {
        subscriptionService.currentProductID.eraseToAnyPublisher()
    }

    /// Whether user can upgrade (has monthly, can upgrade to annual)
    var canUpgradeToAnnual: Bool {
        guard hasPremium,
              let currentID = currentProductID,
              currentID == SubscriptionProduct.monthly,
              annualProduct != nil else {
            return false
        }
        return true
    }
}

