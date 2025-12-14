//
//  DashboardView.swift
//  Plena
//
//  Main dashboard view showing meditation session statistics
//

import SwiftUI
import Charts

struct DashboardView: View {
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
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Time Range Selector
                    Picker("Time Range", selection: $viewModel.selectedTimeRange) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .onChange(of: viewModel.selectedTimeRange) {
                        Task {
                            await viewModel.reloadForTimeRange()
                        }
                    }

                    if viewModel.isLoading {
                        ProgressView("Loading statistics...")
                            .frame(maxWidth: .infinity, minHeight: 200)
                    } else if let error = viewModel.errorMessage {
                        VStack(spacing: 10) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.largeTitle)
                                .foregroundColor(Color("WarningColor"))
                            Text(error)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding()
                        }
                        .frame(maxWidth: .infinity, minHeight: 200)
                    } else {
                        // Stat Cards Grid
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)
                        ], spacing: 12) {
                            // Total Sessions Card
                            StatCard(
                                value: "\(viewModel.sessionCount)",
                                label: "Sessions",
                                subtitle: formatComparisonSubtitle(viewModel.compareToPrevious()),
                                icon: "calendar",
                                trend: viewModel.compareToPrevious()?.trend
                            )

                            // Total Time Card
                            StatCard(
                                value: viewModel.totalHoursFormatted,
                                label: "Total Time",
                                subtitle: viewModel.averageDurationFormatted.map { "Avg: \($0)" },
                                icon: "clock"
                            )

                            // Current Streak Card
                            StatCard(
                                value: "\(viewModel.currentStreak) days",
                                label: "Streak",
                                subtitle: viewModel.currentStreak > 0 ? "Keep it up! 🔥" : "Start your streak",
                                icon: "flame.fill",
                                trend: viewModel.currentStreak > 0 ? .improving : nil
                            )

                            // Average Duration Card
                            StatCard(
                                value: viewModel.averageDurationFormatted ?? "--",
                                label: "Avg Duration",
                                subtitle: formatComparisonSubtitle(viewModel.compareTotalMinutes(), unit: "min"),
                                icon: "clock.arrow.circlepath",
                                trend: viewModel.compareTotalMinutes()?.trend
                            )
                        }
                        .padding(.horizontal)

                        // Charts Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Trends")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .padding(.horizontal)

                            // Session Frequency Chart
                            if viewModel.selectedTimeRange == .day {
                                // For day view, use timeline view
                                let timelineSessions = viewModel.timelineSessionDataPoints()
                                if !timelineSessions.isEmpty {
                                    SessionFrequencyChart(
                                        dataPoints: [],
                                        timeRange: viewModel.selectedTimeRange,
                                        timelineSessions: timelineSessions
                                    )
                                    .padding(.horizontal)
                                }
                            } else if !viewModel.sessionFrequencyDataPoints().isEmpty {
                                // For other time ranges, use regular bar chart
                                SessionFrequencyChart(
                                    dataPoints: viewModel.sessionFrequencyDataPoints(),
                                    timeRange: viewModel.selectedTimeRange,
                                    timelineSessions: nil
                                )
                                .padding(.horizontal)
                            }

                            // Duration Trend Chart
                            if !viewModel.durationTrendDataPoints().isEmpty {
                                DurationTrendChart(
                                    dataPoints: viewModel.durationTrendDataPoints(),
                                    timeRange: viewModel.selectedTimeRange
                                )
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)

                        // Insights Section
                        if viewModel.sessionCount > 0 {
                            InsightsSection(viewModel: viewModel)
                                .padding(.horizontal)
                                .padding(.bottom)
                        }
                    }
                }
                .padding(.top, 8)
                .padding(.bottom)
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                // Pull-to-refresh support
                await viewModel.loadSessions()
            }
            .task {
                await viewModel.loadSessions()
            }
            #if os(iOS)
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                // Refresh when app comes to foreground (user switches from Watch app)
                Task {
                    await viewModel.loadSessions()
                }
            }
            #endif
        }
    }

    // MARK: - Helper Methods

    private func formatComparisonSubtitle(_ comparison: PeriodComparison?, unit: String = "") -> String? {
        guard let comparison = comparison else { return nil }

        if comparison.change == 0 {
            return "→ Same as previous"
        }

        let change = abs(comparison.change)
        let percent = abs(comparison.percentChange)

        let trendIcon: String
        switch comparison.trend {
        case .improving:
            trendIcon = "↑"
        case .declining:
            trendIcon = "↓"
        case .stable:
            trendIcon = "→"
        }

        let changeText: String
        if comparison.change >= 100 || comparison.change <= -100 {
            changeText = String(format: "%.0f", change)
        } else if comparison.change >= 1 || comparison.change <= -1 {
            changeText = String(format: "%.1f", change)
        } else {
            changeText = String(format: "%.2f", change)
        }

        if !unit.isEmpty {
            return "\(trendIcon) \(changeText) \(unit) vs previous"
        } else {
            return "\(trendIcon) \(String(format: "%.0f", percent))% vs previous"
        }
    }
}

// MARK: - Insights Section

struct InsightsSection: View {
    @ObservedObject var viewModel: DashboardViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Insights")
                .font(.largeTitle)
                .fontWeight(.bold)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // Longest Session
                    if let longest = viewModel.longestSession {
                        InsightCard(
                            title: "Longest Session",
                            value: String(format: "%.0f min", longest.duration),
                            subtitle: formatDate(longest.date),
                            icon: "trophy.fill",
                            color: .orange
                        )
                    }

                    // Best Time of Day
                    if let bestTime = viewModel.bestTimeOfDay {
                        InsightCard(
                            title: "Best Time",
                            value: bestTime.time.rawValue,
                            subtitle: String(format: "%.0f%%", bestTime.percentage),
                            icon: "clock.fill",
                            color: .blue
                        )
                    }

                    // Sessions This Week
                    if viewModel.sessionsThisWeek > 0 {
                        InsightCard(
                            title: "This Week",
                            value: "\(viewModel.sessionsThisWeek)",
                            subtitle: "sessions",
                            icon: "calendar.badge.clock",
                            color: .green
                        )
                    }

                    // Sessions Per Week
                    if let perWeek = viewModel.sessionsPerWeek {
                        InsightCard(
                            title: "Per Week",
                            value: String(format: "%.1f", perWeek),
                            subtitle: "average",
                            icon: "chart.bar.fill",
                            color: .purple
                        )
                    }

                    // HRV Insights
                    ForEach(viewModel.hrvInsights(), id: \.message) { insight in
                        HRVInsightCard(insight: insight)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Insight Card

struct InsightCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(width: 140, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
}

// MARK: - HRV Insight Card

struct HRVInsightCard: View {
    let insight: DashboardViewModel.HRVInsight

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: iconName)
                .font(.title2)
                .foregroundColor(insight.trend.color)

            Text(insight.message)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)

            Text(insightTypeLabel)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(width: 180, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }

    private var iconName: String {
        switch insight.type {
        case .weeklyTrend:
            return "chart.line.uptrend.xyaxis"
        case .recentSessions:
            return "heart.text.square.fill"
        }
    }

    private var insightTypeLabel: String {
        switch insight.type {
        case .weeklyTrend:
            return "Weekly Trend"
        case .recentSessions:
            return "Recent Sessions"
        }
    }
}

#Preview {
    DashboardView()
}

