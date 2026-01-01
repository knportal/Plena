//
//  SubscriptionPaywallView.swift
//  Plena
//
//  Paywall overlay component
//

import SwiftUI
import StoreKit

@MainActor
struct SubscriptionPaywallView: View {
    let feature: PremiumFeature
    @Binding var isPresented: Bool
    @StateObject private var viewModel: SubscriptionViewModel

    init(feature: PremiumFeature, isPresented: Binding<Bool>, subscriptionService: SubscriptionServiceProtocol? = nil) {
        self.feature = feature
        self._isPresented = isPresented
        // Create subscription service on main actor if not provided
        let service = subscriptionService ?? SubscriptionService()
        _viewModel = StateObject(wrappedValue: SubscriptionViewModel(subscriptionService: service))
    }

    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }

            // Content card
            VStack(spacing: 24) {
                // Close button
                HStack {
                    Spacer()
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                }

                // Icon
                Image(systemName: "lock.fill")
                    .font(.system(size: 50))
                    .foregroundColor(Color("PlenaPrimary"))

                // Title
                VStack(spacing: 8) {
                    Text("Premium Feature")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("\(feature.displayName) is only available with a Premium subscription.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }

                // Feature list
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(PremiumFeature.allCases.prefix(4)), id: \.self) { premiumFeature in
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(premiumFeature.displayName)
                                .font(.subheadline)
                            Spacer()
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)

                // Subscription options
                if viewModel.hasPremium {
                    Text("You already have Premium!")
                        .font(.headline)
                        .foregroundColor(.green)
                        .padding()
                } else {
                    VStack(spacing: 12) {
                        // Show both monthly and annual if available
                        if let monthly = viewModel.monthlyProduct {
                            Button(action: {
                                Task {
                                    await viewModel.purchase(monthly)
                                    if viewModel.hasPremium {
                                        isPresented = false
                                    }
                                }
                            }) {
                                VStack(spacing: 4) {
                                    Text("Get Premium Monthly")
                                        .font(.headline)
                                    Text(monthly.displayPrice)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemGray6))
                                .foregroundColor(.primary)
                                .cornerRadius(12)
                            }
                            .disabled(viewModel.isLoading || viewModel.purchaseInProgress)
                        }

                        if let annual = viewModel.annualProduct {
                            Button(action: {
                                Task {
                                    await viewModel.purchase(annual)
                                    if viewModel.hasPremium {
                                        isPresented = false
                                    }
                                }
                            }) {
                                VStack(spacing: 4) {
                                    Text("Get Premium Annual")
                                        .font(.headline)
                                    Text(annual.displayPrice)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Text("BEST VALUE")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.orange)
                                        .cornerRadius(4)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color("PlenaPrimary"))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .disabled(viewModel.isLoading || viewModel.purchaseInProgress)
                        }

                        Button(action: {
                            Task {
                                await viewModel.restorePurchases()
                                if viewModel.hasPremium {
                                    isPresented = false
                                }
                            }
                        }) {
                            Text("Restore Purchases")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                        .disabled(viewModel.isLoading)
                    }
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            .padding(24)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(radius: 20)
            .padding(32)
        }
        .task {
            // Refresh subscription status and load products when view appears
            await viewModel.subscriptionService.checkSubscriptionStatus()
            await viewModel.loadProducts()

            // Auto-dismiss if user already has premium
            if viewModel.hasPremium {
                // Small delay to ensure UI updates
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
                isPresented = false
            }
        }
        .onChange(of: viewModel.hasPremium) { oldValue, newValue in
            // Auto-dismiss when premium status changes to true
            if newValue && !oldValue {
                isPresented = false
            }
        }
        .overlay {
            if viewModel.isLoading || viewModel.purchaseInProgress {
                ProgressView()
                    .scaleEffect(1.5)
            }
        }
    }
}

#Preview {
    SubscriptionPaywallView(feature: .readinessScore, isPresented: .constant(true))
}

