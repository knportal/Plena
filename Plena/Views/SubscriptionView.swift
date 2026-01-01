//
//  SubscriptionView.swift
//  Plena
//
//  Subscription purchase and management view
//

import SwiftUI
import StoreKit
import Combine

@MainActor
struct SubscriptionView: View {
    @StateObject private var viewModel: SubscriptionViewModel
    @Environment(\.dismiss) private var dismiss

    init(subscriptionService: SubscriptionServiceProtocol) {
        _viewModel = StateObject(wrappedValue: SubscriptionViewModel(subscriptionService: subscriptionService))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 60))
                            .foregroundColor(Color("PlenaPrimary"))

                        Text("Upgrade to Premium")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("Unlock advanced features and insights")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 32)

                    // Current Status
                    if viewModel.hasPremium {
                        VStack(spacing: 8) {
                            Text("You're subscribed to Premium")
                                .font(.headline)
                                .foregroundColor(.green)

                            if let expirationDate = viewModel.expirationDate {
                                Text("Renews on \(expirationDate, style: .date)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            if let currentID = viewModel.currentProductID {
                                if currentID == SubscriptionProduct.monthly {
                                    Text("Monthly Plan")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                } else if currentID == SubscriptionProduct.annual {
                                    Text("Annual Plan")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(12)
                    }

                    // Features List
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Premium Features")
                            .font(.headline)

                        ForEach(PremiumFeature.allCases, id: \.self) { feature in
                            FeatureRow(feature: feature)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Subscription Options
                    if !viewModel.hasPremium {
                        // Show all options for new subscribers
                        VStack(spacing: 16) {
                            if let monthly = viewModel.monthlyProduct {
                                SubscriptionProductCard(
                                    product: monthly,
                                    isRecommended: false
                                ) {
                                    Task {
                                        await viewModel.purchase(monthly)
                                    }
                                }
                            }

                            if let annual = viewModel.annualProduct {
                                SubscriptionProductCard(
                                    product: annual,
                                    isRecommended: true
                                ) {
                                    Task {
                                        await viewModel.purchase(annual)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    } else if viewModel.canUpgradeToAnnual {
                        // Show upgrade option for monthly subscribers
                        VStack(spacing: 16) {
                            Text("Upgrade to Annual")
                                .font(.headline)
                                .padding(.top)

                            Text("Save 50% with annual billing")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            if let annual = viewModel.annualProduct {
                                SubscriptionProductCard(
                                    product: annual,
                                    isRecommended: true
                                ) {
                                    Task {
                                        await viewModel.purchase(annual)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Restore Purchases
                    Button(action: {
                        Task {
                            await viewModel.restorePurchases()
                        }
                    }) {
                        Text("Restore Purchases")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    .padding(.top, 8)

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding()
                    }
                }
                .padding()
            }
            .navigationTitle("Subscription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await viewModel.loadProducts()
            }
            .onChange(of: viewModel.subscriptionStatus) { oldValue, newValue in
                // Refresh subscription status when it changes (e.g., after upgrade)
                Task {
                    await viewModel.subscriptionService.checkSubscriptionStatus()
                }
            }
            .onChange(of: viewModel.currentProductID) { oldValue, newValue in
                // Force view refresh when product ID changes (e.g., monthly to annual upgrade)
                // This ensures the UI updates immediately when upgrade is detected
            }
            .onReceive(viewModel.currentProductIDPublisher) { productID in
                // Force view update when product ID changes (e.g., monthly to annual upgrade)
                // The view will automatically update because canUpgradeToAnnual depends on currentProductID
            }
            .disabled(viewModel.isLoading || viewModel.purchaseInProgress)
            .overlay {
                if viewModel.isLoading || viewModel.purchaseInProgress {
                    ProgressView()
                        .scaleEffect(1.5)
                }
            }
        }
    }
}

// MARK: - Feature Row

struct FeatureRow: View {
    let feature: PremiumFeature

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)

            VStack(alignment: .leading, spacing: 4) {
                Text(feature.displayName)
                    .font(.body)

                Text(feature.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

// MARK: - Subscription Product Card

struct SubscriptionProductCard: View {
    let product: Product
    let isRecommended: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(product.displayName)
                        .font(.headline)

                    Spacer()

                    if isRecommended {
                        Text("BEST VALUE")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange)
                            .cornerRadius(4)
                    }
                }

                Text(product.displayPrice)
                    .font(.title2)
                    .fontWeight(.bold)

                if product.id == SubscriptionProduct.annual {
                    Text("Save 50% vs monthly")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isRecommended ? Color("PlenaPrimary").opacity(0.1) : Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isRecommended ? Color("PlenaPrimary") : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SubscriptionView(subscriptionService: SubscriptionService())
}

