//
//  SleepRegularityDetailView.swift
//  Plena
//
//  Detail view for Sleep Regularity contributor
//

import SwiftUI
import Charts

struct SleepRegularityDetailView: View {
    @StateObject private var viewModel: SleepRegularityDetailViewModel
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
        _viewModel = StateObject(wrappedValue: SleepRegularityDetailViewModel(
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
        .navigationTitle("Sleep Regularity")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadData(for: date)
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 12) {
            // Large value display
            if let stdDev = viewModel.standardDeviation {
                VStack(spacing: 4) {
                    Text(String(format: "%.1f", stdDev))
                        .font(.system(size: 64, weight: .bold))
                        .foregroundColor(.primary)

                    Text("hours")
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
                if let avgBedtime = viewModel.averageBedtime {
                    CalculationRow(
                        label: "Average Bedtime",
                        value: viewModel.formatBedtime(avgBedtime),
                        description: "Typical sleep start time"
                    )
                }

                if let stdDev = viewModel.standardDeviation {
                    CalculationRow(
                        label: "Standard Deviation",
                        value: String(format: "%.2f hours", stdDev),
                        description: "Variability in bedtime timing"
                    )
                }

                if let stdDev = viewModel.standardDeviation {
                    let minutes = Int(stdDev * 60)
                    CalculationRow(
                        label: "Variability",
                        value: "\(minutes) minutes",
                        description: "Average deviation from mean bedtime"
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
                    // Average bedtime reference line
                    if let avgBedtime = viewModel.averageBedtime {
                        let calendar = Calendar.current
                        let avgHour = Double(calendar.component(.hour, from: avgBedtime)) + Double(calendar.component(.minute, from: avgBedtime)) / 60.0

                        RuleMark(y: .value("Average", avgHour))
                            .foregroundStyle(.green.opacity(0.6))
                            .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                            .annotation(position: .top, alignment: .trailing) {
                                Text("Avg: \(viewModel.formatBedtime(avgBedtime))")
                                    .font(.caption2)
                                    .foregroundColor(.green)
                                    .padding(4)
                                    .background(Color(.systemBackground))
                                    .cornerRadius(4)
                            }
                    }

                    // Trend line (bedtime hours)
                    ForEach(Array(viewModel.trendData.enumerated()), id: \.offset) { index, point in
                        PointMark(
                            x: .value("Day", point.date, unit: .day),
                            y: .value("Bedtime", point.value)
                        )
                        .foregroundStyle(.blue)
                        .symbolSize(60)

                        LineMark(
                            x: .value("Day", point.date, unit: .day),
                            y: .value("Bedtime", point.value)
                        )
                        .foregroundStyle(.blue)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        .interpolationMethod(.catmullRom)
                    }
                }
                .frame(height: 220)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let doubleValue = value.as(Double.self) {
                                Text(viewModel.formatBedtimeHour(doubleValue))
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

            Text("Sleep regularity measures the consistency of your bedtime schedule. A regular sleep schedule helps regulate your circadian rhythm and supports better recovery. Irregular bedtimes can disrupt your body's natural sleep-wake cycle.")
                .font(.body)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                BulletPoint(text: "Regular bedtime = better circadian rhythm")
                BulletPoint(text: "Consistent schedule supports recovery")
                BulletPoint(text: "Irregular timing can disrupt sleep quality")
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
                    range: "≤30 min deviation",
                    description: "Very regular bedtime schedule"
                )

                ThresholdRow(
                    status: .higher,
                    range: "≤1 hour deviation",
                    description: "Good schedule consistency"
                )

                ThresholdRow(
                    status: .moderate,
                    range: "≤2 hours deviation",
                    description: "Moderate variability"
                )

                ThresholdRow(
                    status: .lower,
                    range: ">2 hours deviation",
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
        SleepRegularityDetailView(
            contributor: ReadinessContributor(
                name: "Sleep regularity",
                value: "Optimal",
                status: .optimal,
                score: 1.0
            ),
            date: Date()
        )
        .environmentObject(TabCoordinator())
    }
}
