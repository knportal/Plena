//
//  ReadinessWatchView.swift
//  Plena Watch App
//
//  Simplified readiness score view for Apple Watch
//

import SwiftUI

struct ReadinessWatchView: View {
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
        ScrollView {
            VStack(spacing: 16) {
                if viewModel.isLoading {
                    ProgressView()
                        .padding()
                } else if let error = viewModel.errorMessage {
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.title2)
                            .foregroundColor(Color("WarningColor"))
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else if let score = viewModel.readinessScore {
                    // Main Score Display
                    VStack(spacing: 8) {
                        Text("\(Int(score.overallScore))")
                            .font(.system(size: 56, weight: .bold))
                            .foregroundColor(score.status.color)

                        Text("Readiness")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        // Change from yesterday
                        if let change = viewModel.scoreChange {
                            HStack(spacing: 4) {
                                Image(systemName: change >= 0 ? "arrow.up" : "arrow.down")
                                    .font(.caption2)
                                Text("\(change >= 0 ? "+" : "")\(Int(change))")
                                    .font(.caption)
                            }
                            .foregroundColor(change >= 0 ? Color("SuccessColor") : Color("WarningColor"))
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color("CardBackgroundColor"))
                    )

                    // Top Contributors (simplified)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Top Contributors")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 4)

                        ForEach(Array(score.contributors.prefix(3)), id: \.id) { contributor in
                            ContributorRowWatch(contributor: contributor)
                        }
                    }
                    .padding(.horizontal, 4)
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "chart.bar.doc.horizontal")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("No data available")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
            }
            .padding()
        }
        .navigationTitle("Readiness")
        .task {
            await viewModel.loadReadinessScore(for: viewModel.selectedDate)
        }
    }

    // Removed - now using score.status.color to match iPhone
}

// MARK: - Contributor Row

struct ContributorRowWatch: View {
    let contributor: ReadinessContributor

    var body: some View {
        HStack(spacing: 8) {
            // Contributor icon
            Image(systemName: iconForContributor(contributor.name))
                .font(.caption)
                .foregroundColor(contributorColor)
                .frame(width: 20)

            // Contributor name
            Text(contributor.name)
                .font(.caption)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Contributor status
            Text(contributor.status.rawValue)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(contributorColor)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color("CardBackgroundColor"))
        )
    }

    private var contributorColor: Color {
        switch contributor.status {
        case .optimal:
            return Color("SuccessColor")
        case .good:
            return .blue
        case .payAttention:
            return .orange
        case .poor:
            return Color("WarningColor")
        case .noData:
            return .gray
        }
    }

    private func iconForContributor(_ name: String) -> String {
        switch name.lowercased() {
        case "resting heart rate":
            return "heart.fill"
        case "hrv balance":
            return "waveform.path.ecg"
        case "body temperature":
            return "thermometer"
        case "recovery index":
            return "arrow.triangle.2.circlepath"
        case "sleep", "sleep balance", "sleep regularity":
            return "moon.fill"
        default:
            return "circle.fill"
        }
    }
}

#Preview {
    NavigationStack {
        ReadinessWatchView()
    }
}

