//
//  SleepBalanceDetailView.swift
//  Plena
//
//  Detail view for Sleep Balance contributor
//

import SwiftUI
import Charts

struct SleepBalanceDetailView: View {
    @StateObject private var viewModel: SleepBalanceDetailViewModel
    @EnvironmentObject var tabCoordinator: TabCoordinator
    let contributor: ReadinessContributor
    let date: Date

    init(
        contributor: ReadinessContributor,
        date: Date,
        storageService: SessionStorageServiceProtocol = CoreDataStorageService(),
        healthKitService: HealthKitServiceProtocol? = nil
    ) {
        self.contributor = contributor
        self.date = date
        _viewModel = StateObject(wrappedValue: SleepBalanceDetailViewModel(
            storageService: storageService,
            healthKitService: healthKitService
        ))
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
            }
            .padding()
        }
        .navigationTitle("Sleep Balance")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadData(for: date)
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 12) {
            // Large value display
            if let cv = viewModel.coefficientOfVariation {
                VStack(spacing: 4) {
                    Text(String(format: "%.2f", cv))
                        .font(.system(size: 64, weight: .bold))
                        .foregroundColor(.primary)

                    Text("CV")
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
                if let avg = viewModel.averageSleepHours {
                    CalculationRow(
                        label: "Average Sleep",
                        value: String(format: "%.1f hours", avg),
                        description: "7-day average duration"
                    )
                }

                if let stdDev = viewModel.standardDeviation {
                    CalculationRow(
                        label: "Standard Deviation",
                        value: String(format: "%.2f hours", stdDev),
                        description: "Variability in sleep duration"
                    )
                }

                if let cv = viewModel.coefficientOfVariation {
                    CalculationRow(
                        label: "Coefficient of Variation",
                        value: String(format: "%.3f", cv),
                        description: "Lower = more consistent"
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
                    // Average reference line
                    if let avg = viewModel.averageSleepHours {
                        RuleMark(y: .value("Average", avg))
                            .foregroundStyle(.green.opacity(0.6))
                            .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                            .annotation(position: .top, alignment: .trailing) {
                                Text("Avg: \(String(format: "%.1f", avg))h")
                                    .font(.caption2)
                                    .foregroundColor(.green)
                                    .padding(4)
                                    .background(Color(.systemBackground))
                                    .cornerRadius(4)
                            }
                    }

                    // Trend bars
                    ForEach(Array(viewModel.trendData.enumerated()), id: \.offset) { index, point in
                        BarMark(
                            x: .value("Day", point.date, unit: .day),
                            y: .value("Hours", point.value)
                        )
                        .foregroundStyle(.blue)
                        .cornerRadius(4)
                    }
                }
                .frame(height: 220)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let doubleValue = value.as(Double.self) {
                                Text(String(format: "%.1f", doubleValue))
                            }
                        }
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

            Text("Sleep balance measures the consistency of your sleep duration. A lower coefficient of variation (CV) indicates more consistent sleep patterns, which supports better recovery and readiness. Highly variable sleep durations can disrupt your body's recovery processes.")
                .font(.body)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                BulletPoint(text: "Lower CV = more consistent sleep")
                BulletPoint(text: "Consistent duration supports recovery")
                BulletPoint(text: "High variability may indicate schedule issues")
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
                    range: "CV ≤ 0.15",
                    description: "Very consistent sleep duration"
                )

                ThresholdRow(
                    status: .higher,
                    range: "CV ≤ 0.25",
                    description: "Good consistency"
                )

                ThresholdRow(
                    status: .moderate,
                    range: "CV ≤ 0.35",
                    description: "Moderate variability"
                )

                ThresholdRow(
                    status: .lower,
                    range: "CV > 0.35",
                    description: "High variability, consider schedule changes"
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
}

#Preview {
    NavigationStack {
        SleepBalanceDetailView(
            contributor: ReadinessContributor(
                name: "Sleep balance",
                value: "Optimal",
                status: .optimal,
                score: 1.0
            ),
            date: Date()
        )
        .environmentObject(TabCoordinator())
    }
}
