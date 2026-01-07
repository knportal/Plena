//
//  ReadinessView.swift
//  Plena
//
//  Main readiness score dashboard view
//

import SwiftUI
import Combine
import CoreData

struct ReadinessView: View {
    @StateObject private var viewModel: ReadinessViewModel

    @State private var showPaywall = false
    private let subscriptionService: SubscriptionService

    init(
        storageService: SessionStorageServiceProtocol = CoreDataStorageService(),
        healthKitService: HealthKitServiceProtocol? = nil
    ) {
        // Initialize subscription services
        let subscriptionService = SubscriptionService()
        let featureGateService = FeatureGateService(subscriptionService: subscriptionService)

        self.subscriptionService = subscriptionService
        _viewModel = StateObject(wrappedValue: ReadinessViewModel(
            storageService: storageService,
            healthKitService: healthKitService,
            featureGateService: featureGateService
        ))
    }

    // MARK: - View Components

    private var dateSelector: some View {
        HStack(spacing: 16) {
            Button(action: {
                viewModel.selectYesterday()
            }) {
                HStack(spacing: 4) {
                    Text("Yesterday")
                        .font(.subheadline)
                        .fontWeight(viewModel.isYesterday ? .semibold : .regular)
                    if viewModel.isYesterday {
                        Image(systemName: "calendar")
                            .font(.caption)
                    }
                }
                .foregroundColor(viewModel.isYesterday ? .primary : .secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(viewModel.isYesterday ? Color(.systemGray5) : Color.clear)
                )
            }

            Button(action: {
                viewModel.selectToday()
            }) {
                HStack(spacing: 4) {
                    Text("Today")
                        .font(.subheadline)
                        .fontWeight(viewModel.isToday ? .semibold : .regular)
                    if viewModel.isToday {
                        Image(systemName: "calendar")
                            .font(.caption)
                    }
                }
                .foregroundColor(viewModel.isToday ? .primary : .secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(viewModel.isToday ? Color(.systemGray5) : Color.clear)
                )
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    @ViewBuilder
    private var contentView: some View {
        if viewModel.isLoading {
            ProgressView("Calculating readiness...")
                .frame(maxWidth: .infinity, minHeight: 400)
        } else if let error = viewModel.errorMessage {
            VStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.largeTitle)
                    .foregroundColor(.orange)
                Text(error)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .frame(maxWidth: .infinity, minHeight: 400)
        } else if let score = viewModel.readinessScore {
            scoreContent(score: score)
        } else {
            VStack(spacing: 10) {
                Image(systemName: "chart.bar.doc.horizontal")
                    .font(.largeTitle)
                    .foregroundColor(.secondary)
                Text("No readiness data available")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .frame(maxWidth: .infinity, minHeight: 400)
        }
    }

    private func scoreContent(score: ReadinessScore) -> some View {
        VStack(spacing: 24) {
            // Score Card
            ReadinessScoreCard(
                score: score,
                changeFromYesterday: viewModel.scoreChange
            )
            .padding(.horizontal, 16)

            // Contributors Section
            VStack(alignment: .leading, spacing: 16) {
                Text("Contributors")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.horizontal)

                VStack(spacing: 0) {
                    ForEach(Array(score.contributors.enumerated()), id: \.element.id) { index, contributor in
                        NavigationLink(value: contributor) {
                            ReadinessContributorRow(contributor: contributor)
                        }
                        .buttonStyle(PlainButtonStyle())

                        if index < score.contributors.count - 1 {
                            Divider()
                                .padding(.leading, 58) // Align with content
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                )
                .padding(.horizontal)
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    dateSelector
                    contentView
                }
                .padding(.vertical)
            }
            .navigationTitle("Daily Trend Score")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showPaywall) {
                SubscriptionPaywallView(
                    feature: PremiumFeature.readinessScore,
                    isPresented: $showPaywall
                )
            }
            .onChange(of: viewModel.showPaywall) { oldValue, newValue in
                if newValue {
                    showPaywall = true
                    viewModel.showPaywall = false
                }
            }
            .onChange(of: showPaywall) { oldValue, newValue in
                // When paywall is dismissed, check if user now has access
                if oldValue == true && newValue == false {
                    Task {
                        await subscriptionService.checkSubscriptionStatus()

                        // Get current subscription status
                        let status = subscriptionService.currentSubscriptionStatus()

                        if status.isPremium {
                            // User purchased - reload readiness score
                            await viewModel.loadReadinessScore(for: viewModel.selectedDate)
                        }
                    }
                }
            }
            .onReceive(
                subscriptionService.subscriptionStatus
                    .map { $0.isPremium }
                    .removeDuplicates()
                    .eraseToAnyPublisher()
            ) { isPremium in
                // Auto-dismiss paywall if user gains premium access
                if isPremium && showPaywall {
                    showPaywall = false
                }
                // Reload data when premium is detected (only if we don't already have data and not loading)
                if isPremium && viewModel.readinessScore == nil && !viewModel.isLoading {
                    Task {
                        await viewModel.loadReadinessScore(for: viewModel.selectedDate)
                    }
                }
            }
            .onAppear {
                // Refresh subscription status FIRST, then check access
                Task {
                    // Give StoreKit a moment to process any recent transactions
                    try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds

                    await subscriptionService.checkSubscriptionStatus()

                    // Check access after refresh
                    let status = subscriptionService.currentSubscriptionStatus()
                    if !status.isPremium {
                        showPaywall = true
                    } else if viewModel.readinessScore == nil && !viewModel.isLoading {
                        // User has premium - load data (only if we don't already have it)
                        await viewModel.loadReadinessScore(for: viewModel.selectedDate)
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SubscriptionStatusChangedToPremium"))) { _ in
                // When subscription status changes to premium (from any source), refresh and load
                Task {
                    await subscriptionService.checkSubscriptionStatus()
                    let status = subscriptionService.currentSubscriptionStatus()
                    if status.isPremium {
                        showPaywall = false
                        // Only load if we don't already have data and not loading
                        if viewModel.readinessScore == nil && !viewModel.isLoading {
                            await viewModel.loadReadinessScore(for: viewModel.selectedDate)
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    // Back button is handled by NavigationStack
                    EmptyView()
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // TODO: Share readiness score
                    }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .navigationDestination(for: ReadinessContributor.self) { contributor in
                contributorDetailView(for: contributor)
            }
            .task {
                // Wait a bit to allow onAppear to complete first
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

                // Only load if we haven't already loaded in onAppear
                // This prevents double-loading
                if viewModel.readinessScore == nil && !viewModel.isLoading {
                    // Check status one more time before loading
                    await subscriptionService.checkSubscriptionStatus()
                    let status = subscriptionService.currentSubscriptionStatus()
                    if status.isPremium {
                        await viewModel.loadReadinessScore(for: viewModel.selectedDate)
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .NSPersistentStoreRemoteChange)) { _ in
                // Reload readiness score when Core Data changes (e.g., new session saved)
                print("🔄 Readiness: Detected Core Data store change, refreshing...")
                Task {
                    await viewModel.reload()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)) { notification in
                // Reload when any context saves (catches Watch saves)
                if let savedContext = notification.object as? NSManagedObjectContext,
                   savedContext !== CoreDataStack.shared.mainContext {
                    print("🔄 Readiness: Detected save from other context, refreshing...")
                    CoreDataStack.shared.mainContext.refreshAllObjects()
                    Task {
                        await viewModel.reload()
                    }
                }
            }
        }
    }

    // MARK: - Detail View Routing

    @ViewBuilder
    private func contributorDetailView(for contributor: ReadinessContributor) -> some View {
        switch contributor.name {
        case "Resting heart rate":
            RestingHeartRateDetailView(
                contributor: contributor,
                date: viewModel.selectedDate,
                storageService: viewModel.storageService
            )
        case "HRV balance":
            HRVBalanceDetailView(
                contributor: contributor,
                date: viewModel.selectedDate,
                storageService: viewModel.storageService
            )
        case "Body temperature":
            BodyTemperatureDetailView(
                contributor: contributor,
                date: viewModel.selectedDate,
                storageService: viewModel.storageService,
                healthKitService: viewModel.healthKitService
            )
        case "Recovery index":
            RecoveryIndexDetailView(
                contributor: contributor,
                date: viewModel.selectedDate,
                storageService: viewModel.storageService
            )
        case "Sleep":
            SleepStatusDetailView(
                contributor: contributor,
                date: viewModel.selectedDate,
                storageService: viewModel.storageService,
                healthKitService: viewModel.healthKitService
            )
        case "Sleep balance":
            SleepBalanceDetailView(
                contributor: contributor,
                date: viewModel.selectedDate,
                storageService: viewModel.storageService,
                healthKitService: viewModel.healthKitService
            )
        case "Sleep regularity":
            SleepRegularityDetailView(
                contributor: contributor,
                date: viewModel.selectedDate,
                storageService: viewModel.storageService,
                healthKitService: viewModel.healthKitService
            )
        default:
            // Placeholder for other contributors - will implement later
            VStack {
                Text("Detail view for \(contributor.name)")
                    .font(.headline)
                Text("Coming soon")
                    .foregroundColor(.secondary)
            }
            .navigationTitle(contributor.name)
        }
    }
}

#Preview {
    ReadinessView()
}

