//
//  RecoveryIndexDetailView.swift
//  Plena
//
//  Detail view for Recovery Index contributor
//

import SwiftUI
import Charts

struct RecoveryIndexDetailView: View {
    @StateObject private var viewModel: RecoveryIndexDetailViewModel
    @EnvironmentObject var tabCoordinator: TabCoordinator
    let contributor: ReadinessContributor
    let date: Date

    init(
        contributor: ReadinessContributor,
        date: Date,
        storageService: SessionStorageServiceProtocol = CoreDataStorageService()
    ) {
        self.contributor = contributor
        self.date = date
        _viewModel = StateObject(wrappedValue: RecoveryIndexDetailViewModel(storageService: storageService))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header Section
                headerSection

                // Calculation Breakdown
                calculationSection

                // 7-Day Trend Chart
                if !viewModel.trendData.isEmpty {
                    trendChartSection
                }

                // Educational Content
                educationalSection

                // Thresholds
                thresholdsSection

                // Link to Dashboard Tab
                dashboardTabLinkSection
            }
            .padding()
        }
        .navigationTitle("Recovery Index")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadData(for: date)
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 12) {
            // Large value display
            if let avgSessions = viewModel.averageSessionsPerDay {
                VStack(spacing: 4) {
                    Text(String(format: "%.1f", avgSessions))
                        .font(.system(size: 64, weight: .bold))
                        .foregroundColor(.primary)

                    Text("sessions/day")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            } else {
                Text("--")
                    .font(.system(size: 64, weight: .bold))
                    .foregroundColor(.secondary)
            }

            // Status badge
            if let status = viewModel.status, status.shouldShowBadge {
                Text(status.rawValue)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(status.color)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(status.color.opacity(0.15))
                    )
            }

            // Score contribution
            Text("Contributes \(Int(contributor.score * 100))% to readiness")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }

    // MARK: - Calculation Section

    private var calculationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Calculation Breakdown")
                .font(.title2)
                .fontWeight(.bold)

            VStack(spacing: 12) {
                if let avgSessions = viewModel.averageSessionsPerDay {
                    CalculationRow(
                        label: "Average",
                        value: String(format: "%.1f sessions/day", avgSessions),
                        description: "Over last 7 days"
                    )
                }

                if !viewModel.sessionsPerDay.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Sessions Per Day")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        HStack(spacing: 8) {
                            ForEach(Array(viewModel.sessionsPerDay.enumerated()), id: \.offset) { index, count in
                                VStack(spacing: 4) {
                                    Text("\(count)")
                                        .font(.headline)
                                        .fontWeight(.semibold)

                                    Text(dayLabel(for: index))
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(.tertiarySystemBackground))
                                )
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private func dayLabel(for index: Int) -> String {
        let calendar = Calendar.current
        let dayOffset = 6 - index // Most recent is index 0, so we go back 6 days
        guard let dayDate = calendar.date(byAdding: .day, value: -dayOffset, to: date) else {
            return "Day \(index + 1)"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "E" // Abbreviated weekday
        return formatter.string(from: dayDate)
    }

    // MARK: - Trend Chart Section

    private var trendChartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("7-Day Trend")
                .font(.title2)
                .fontWeight(.bold)

            if viewModel.trendData.isEmpty {
                Text("No trend data available")
                    .foregroundColor(.secondary)
                    .frame(height: 200)
            } else {
                Chart {
                    // Optimal range reference (1-2 sessions per day)
                    RuleMark(yStart: .value("Optimal Start", 1.0), yEnd: .value("Optimal End", 2.0))
                        .foregroundStyle(.green.opacity(0.2))
                        .annotation(position: .top, alignment: .trailing) {
                            Text("Optimal: 1-2")
                                .font(.caption2)
                                .foregroundColor(.green)
                                .padding(4)
                                .background(Color(.systemBackground))
                                .cornerRadius(4)
                        }

                    // Trend line (bar chart would be better, but using line for consistency)
                    ForEach(Array(viewModel.trendData.enumerated()), id: \.offset) { index, point in
                        BarMark(
                            x: .value("Day", point.date, unit: .day),
                            y: .value("Sessions", point.value)
                        )
                        .foregroundStyle(.blue)
                        .cornerRadius(4)
                    }
                }
                .frame(height: 220)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { value in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }

    // MARK: - Educational Section

    private var educationalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Why This Matters")
                .font(.title2)
                .fontWeight(.bold)

            Text("Recovery index measures your meditation session frequency. Consistent, moderate frequency (1-2 sessions per day) indicates good recovery patterns and sustainable practice. Too few or too many sessions may suggest imbalanced recovery.")
                .font(.body)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                BulletPoint(text: "1-2 sessions/day = optimal recovery pattern")
                BulletPoint(text: "Consistent frequency supports better readiness")
                BulletPoint(text: "Too many sessions may indicate overtraining")
                BulletPoint(text: "Too few sessions may indicate insufficient recovery focus")
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }

    // MARK: - Thresholds Section

    private var thresholdsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Status Thresholds")
                .font(.title2)
                .fontWeight(.bold)

            VStack(spacing: 12) {
                ThresholdRow(
                    status: .optimal,
                    range: "1-2 sessions/day",
                    description: "Ideal frequency for recovery"
                )

                ThresholdRow(
                    status: .good,
                    range: "0.5-1 or 2-3 sessions/day",
                    description: "Good recovery pattern"
                )

                ThresholdRow(
                    status: .payAttention,
                    range: "<0.5 or >3 sessions/day",
                    description: "May indicate imbalanced recovery"
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }

    // MARK: - Dashboard Tab Link

    private var dashboardTabLinkSection: some View {
        Button(action: {
            tabCoordinator.selectedTab = 1 // Dashboard tab index
        }) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.title3)

                VStack(alignment: .leading, spacing: 4) {
                    Text("View in Dashboard")
                        .font(.headline)

                    Text("See detailed session statistics and trends")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    NavigationStack {
        RecoveryIndexDetailView(
            contributor: ReadinessContributor(
                name: "Recovery index",
                value: "Optimal",
                status: .optimal,
                score: 1.0
            ),
            date: Date()
        )
        .environmentObject(TabCoordinator())
    }
}
