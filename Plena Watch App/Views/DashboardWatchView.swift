//
//  DashboardWatchView.swift
//  Plena Watch App
//
//  Simplified dashboard view for Apple Watch
//

import SwiftUI

struct DashboardWatchView: View {
    @StateObject private var viewModel: DashboardViewModel

    init(
        storageService: SessionStorageServiceProtocol = CoreDataStorageService(),
        healthKitService: HealthKitServiceProtocol? = nil
    ) {
        _viewModel = StateObject(wrappedValue: DashboardViewModel(
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
                } else {
                    // Sessions Count
                    StatCardWatch(
                        value: "\(viewModel.sessionCount)",
                        label: "Sessions",
                        icon: "calendar",
                        color: Color("PlenaPrimary")
                    )

                    // Current Streak
                    StatCardWatch(
                        value: "\(viewModel.currentStreak)",
                        label: "Day Streak",
                        icon: "flame.fill",
                        color: .orange
                    )

                    // Total Time
                    StatCardWatch(
                        value: viewModel.totalHoursFormatted.isEmpty ? "0 min" : viewModel.totalHoursFormatted,
                        label: "Total Time",
                        icon: "clock.fill",
                        color: Color("PlenaSecondary")
                    )

                    // Average Duration
                    StatCardWatch(
                        value: viewModel.averageDurationFormatted ?? "0 min",
                        label: "Avg Duration",
                        icon: "clock.arrow.circlepath",
                        color: .blue
                    )
                }
            }
            .padding()
        }
        .navigationTitle("Dashboard")
        .task {
            await viewModel.loadSessions()
        }
        .onAppear {
            // Refresh when view appears
            Task {
                await viewModel.loadSessions()
            }
        }
    }
}

// MARK: - Watch Stat Card

struct StatCardWatch: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Color("TextPrimaryColor"))
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)

                Text(label)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(Color("TextSecondaryColor").opacity(0.9))
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color("CardBackgroundColor"))
        )
    }
}

#Preview {
    NavigationStack {
        DashboardWatchView()
    }
}



