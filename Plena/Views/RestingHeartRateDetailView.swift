//
//  RestingHeartRateDetailView.swift
//  Plena
//
//  Detail view for Resting Heart Rate contributor
//

import SwiftUI
import Charts

struct RestingHeartRateDetailView: View {
    @StateObject private var viewModel: RestingHeartRateDetailViewModel
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
        _viewModel = StateObject(wrappedValue: RestingHeartRateDetailViewModel(storageService: storageService))
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

                // Link to Data Tab
                dataTabLinkSection
            }
            .padding()
        }
        .navigationTitle("Resting Heart Rate")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadData(for: date)
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 12) {
            // Large value display
            if let currentHR = viewModel.currentRestingHR {
                VStack(spacing: 4) {
                    Text("\(Int(currentHR))")
                        .font(.system(size: 64, weight: .bold))
                        .foregroundColor(.primary)

                    Text("bpm")
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
                if let baseline = viewModel.baselineHR {
                    CalculationRow(
                        label: "Baseline",
                        value: "\(Int(baseline)) bpm",
                        description: "Average from last 7 days"
                    )
                }

                if let current = viewModel.currentRestingHR {
                    CalculationRow(
                        label: "Current",
                        value: "\(Int(current)) bpm",
                        description: "Average from last 3 sessions (first 2 min)"
                    )
                }

                if let deviation = viewModel.deviation {
                    CalculationRow(
                        label: "Deviation",
                        value: String(format: "%.1f bpm", deviation),
                        description: "Difference from baseline"
                    )
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
                    // Baseline reference line
                    if let baseline = viewModel.baselineHR {
                        RuleMark(y: .value("Baseline", baseline))
                            .foregroundStyle(.green.opacity(0.6))
                            .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                            .annotation(position: .top, alignment: .trailing) {
                                Text("Baseline: \(Int(baseline))")
                                    .font(.caption2)
                                    .foregroundColor(.green)
                                    .padding(4)
                                    .background(Color(.systemBackground))
                                    .cornerRadius(4)
                            }
                    }

                    // Trend line
                    ForEach(Array(viewModel.trendData.enumerated()), id: \.offset) { index, point in
                        LineMark(
                            x: .value("Day", point.date, unit: .day),
                            y: .value("HR", point.value)
                        )
                        .foregroundStyle(.blue)
                        .lineStyle(StrokeStyle(lineWidth: 2.5))
                        .interpolationMethod(.catmullRom)

                        // Data points
                        PointMark(
                            x: .value("Day", point.date, unit: .day),
                            y: .value("HR", point.value)
                        )
                        .foregroundStyle(.blue)
                        .symbolSize(60)
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

            Text("Your resting heart rate is measured during the first 2 minutes of meditation sessions, when your body is in a natural resting state. A stable resting heart rate that's close to your personal baseline indicates good recovery and readiness.")
                .font(.body)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                BulletPoint(text: "Lower deviation from baseline = better recovery")
                BulletPoint(text: "Consistent resting HR indicates stable nervous system")
                BulletPoint(text: "Large deviations may indicate stress or insufficient recovery")
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
                    range: "≤5 bpm deviation",
                    description: "Very stable, excellent recovery"
                )

                ThresholdRow(
                    status: .good,
                    range: "≤10 bpm deviation",
                    description: "Stable, good recovery"
                )

                ThresholdRow(
                    status: .payAttention,
                    range: "≤15 bpm deviation",
                    description: "Some variability, monitor closely"
                )

                ThresholdRow(
                    status: .poor,
                    range: ">15 bpm deviation",
                    description: "High variability, consider rest"
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

    // MARK: - Data Tab Link

    private var dataTabLinkSection: some View {
        Button(action: {
            tabCoordinator.navigateToDataTab(sensor: .heartRate)
        }) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title3)

                VStack(alignment: .leading, spacing: 4) {
                    Text("View in Data Tab")
                        .font(.headline)

                    Text("See detailed heart rate trends and analysis")
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

// MARK: - Supporting Views

struct CalculationRow: View {
    let label: String
    let value: String
    let description: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary.opacity(0.8))
            }

            Spacer()

            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
        }
    }
}

struct BulletPoint: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .foregroundColor(.secondary)
            Text(text)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
}

struct ThresholdRow: View {
    let status: ReadinessStatus
    let range: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Status indicator
            Circle()
                .fill(status.color)
                .frame(width: 12, height: 12)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(status.rawValue)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(range)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(description)
                    .font(.caption2)
                    .foregroundColor(.secondary.opacity(0.8))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    NavigationStack {
        RestingHeartRateDetailView(
            contributor: ReadinessContributor(
                name: "Resting heart rate",
                value: "64 bpm",
                status: .optimal,
                score: 1.0
            ),
            date: Date()
        )
        .environmentObject(TabCoordinator())
    }
}

