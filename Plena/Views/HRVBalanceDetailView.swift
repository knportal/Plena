//
//  HRVBalanceDetailView.swift
//  Plena
//
//  Detail view for HRV Balance contributor
//

import SwiftUI
import Charts

struct HRVBalanceDetailView: View {
    @StateObject private var viewModel: HRVBalanceDetailViewModel
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
        _viewModel = StateObject(wrappedValue: HRVBalanceDetailViewModel(storageService: storageService))
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
        .navigationTitle("HRV Balance")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadData(for: date)
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 12) {
            // Large value display
            if let currentHRV = viewModel.currentHRV {
                VStack(spacing: 4) {
                    Text("\(Int(currentHRV))")
                        .font(.system(size: 64, weight: .bold))
                        .foregroundColor(.primary)

                    Text("ms")
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
                if let baseline = viewModel.baselineHRV {
                    CalculationRow(
                        label: "Baseline",
                        value: "\(Int(baseline)) ms",
                        description: "Average from last 7 days"
                    )
                }

                if let current = viewModel.currentHRV {
                    CalculationRow(
                        label: "Current",
                        value: "\(Int(current)) ms",
                        description: "Average from today's sessions"
                    )
                }

                if let percentChange = viewModel.percentChange {
                    CalculationRow(
                        label: "Change",
                        value: String(format: "%.1f%%", percentChange),
                        description: percentChange >= 0 ? "Above baseline" : "Below baseline"
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
                    if let baseline = viewModel.baselineHRV {
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
                            y: .value("HRV", point.value)
                        )
                        .foregroundStyle(.blue)
                        .lineStyle(StrokeStyle(lineWidth: 2.5))
                        .interpolationMethod(.catmullRom)

                        // Data points
                        PointMark(
                            x: .value("Day", point.date, unit: .day),
                            y: .value("HRV", point.value)
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

            Text("HRV (Heart Rate Variability) balance measures how your current HRV compares to your baseline. Higher HRV indicates better recovery capacity and autonomic nervous system balance. When your HRV is above baseline, it suggests good recovery and readiness.")
                .font(.body)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                BulletPoint(text: "Higher HRV = better recovery capacity")
                BulletPoint(text: "Above baseline = optimal readiness")
                BulletPoint(text: "Below baseline may indicate stress or fatigue")
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
                    range: "≥5% above baseline",
                    description: "Excellent recovery, optimal readiness"
                )

                ThresholdRow(
                    status: .higher,
                    range: "Within ±5% of baseline",
                    description: "Good balance, stable recovery"
                )

                ThresholdRow(
                    status: .moderate,
                    range: "5-15% below baseline",
                    description: "Some stress, monitor closely"
                )

                ThresholdRow(
                    status: .lower,
                    range: ">15% below baseline",
                    description: "High stress, consider rest"
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
            tabCoordinator.navigateToDataTab(sensor: .hrv)
        }) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title3)

                VStack(alignment: .leading, spacing: 4) {
                    Text("View in Data Tab")
                        .font(.headline)

                    Text("See detailed HRV trends and analysis")
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
        HRVBalanceDetailView(
            contributor: ReadinessContributor(
                name: "HRV balance",
                value: "Higher",
                status: .higher,
                score: 0.75
            ),
            date: Date()
        )
        .environmentObject(TabCoordinator())
    }
}
