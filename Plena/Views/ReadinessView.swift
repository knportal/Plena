//
//  ReadinessView.swift
//  Plena
//
//  Main readiness score dashboard view
//

import SwiftUI

struct ReadinessView: View {
    @StateObject private var viewModel: ReadinessViewModel

    init(
        storageService: SessionStorageServiceProtocol = CoreDataStorageService(),
        healthKitService: HealthKitServiceProtocol? = nil
    ) {
        _viewModel = StateObject(wrappedValue: ReadinessViewModel(
            storageService: storageService,
            healthKitService: healthKitService
        ))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Date Selector
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
                .padding(.vertical)
            }
            .navigationTitle("Readiness")
            .navigationBarTitleDisplayMode(.inline)
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
                await viewModel.loadReadinessScore(for: viewModel.selectedDate)
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

