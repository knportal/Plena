//
//  SleepStatusDetailView.swift
//  Plena
//
//  Detail view for Sleep Status contributor
//

import SwiftUI
import Charts

struct SleepStatusDetailView: View {
    @StateObject private var viewModel: SleepStatusDetailViewModel
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
        _viewModel = StateObject(wrappedValue: SleepStatusDetailViewModel(
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
        .navigationTitle("Sleep")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadData(for: date)
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 12) {
            // Large value display
            if let sleepHours = viewModel.currentSleepHours {
                VStack(spacing: 4) {
                    Text(String(format: "%.1f", sleepHours))
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
            Text("Sleep Details")
                .font(.title2)
                .fontWeight(.bold)

            VStack(spacing: 12) {
                if let sleepHours = viewModel.currentSleepHours {
                    CalculationRow(
                        label: "Total Sleep",
                        value: String(format: "%.1f hours", sleepHours),
                        description: "Last night's sleep duration"
                    )
                }

                if let bedtime = viewModel.lastNightBedtime {
                    let formatter = DateFormatter()
                    formatter.timeStyle = .short

                    CalculationRow(
                        label: "Bedtime",
                        value: formatter.string(from: bedtime),
                        description: "Sleep start time"
                    )
                }

                if let wakeTime = viewModel.lastNightWakeTime {
                    let formatter = DateFormatter()
                    formatter.timeStyle = .short

                    CalculationRow(
                        label: "Wake Time",
                        value: formatter.string(from: wakeTime),
                        description: "Sleep end time"
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

            Chart {
                // Optimal range reference (7-9 hours)
                RuleMark(yStart: .value("Optimal Start", 7.0), yEnd: .value("Optimal End", 9.0))
                    .foregroundStyle(.green.opacity(0.2))
                    .annotation(position: .top, alignment: .trailing) {
                        Text("Optimal: 7-9h")
                            .font(.caption2)
                            .foregroundColor(.green)
                            .padding(4)
                            .background(Color(.systemBackground))
                            .cornerRadius(4)
                    }

                // Trend line
                ForEach(Array(viewModel.trendData.enumerated()), id: \.offset) { index, point in
                    LineMark(
                        x: .value("Day", point.date, unit: .day),
                        y: .value("Hours", point.value)
                    )
                    .foregroundStyle(.blue)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
                    .interpolationMethod(.catmullRom)

                    // Data points
                    PointMark(
                        x: .value("Day", point.date, unit: .day),
                        y: .value("Hours", point.value)
                    )
                    .foregroundStyle(.blue)
                    .symbolSize(60)
                }
            }
            .frame(height: 220)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisValueLabel(format: .number.precision(.fractionLength(1)).suffix("h"))
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.weekday(.abbreviated))
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

            Text("Sleep is fundamental to recovery and readiness. Quality sleep duration (7-9 hours for most adults) supports physical recovery, cognitive function, and overall readiness. Too little or too much sleep can negatively impact your readiness for meditation and daily activities.")
                .font(.body)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                BulletPoint(text: "7-9 hours = optimal recovery and readiness")
                BulletPoint(text: "Consistent sleep duration supports better outcomes")
                BulletPoint(text: "Too little sleep may reduce recovery benefits")
                BulletPoint(text: "Too much sleep may indicate underlying issues")
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
                    range: "7-9 hours",
                    description: "Optimal recovery and readiness"
                )

                ThresholdRow(
                    status: .good,
                    range: "6-7 or 9-10 hours",
                    description: "Good sleep duration"
                )

                ThresholdRow(
                    status: .payAttention,
                    range: "5-6 or 10-11 hours",
                    description: "Monitor sleep patterns"
                )

                ThresholdRow(
                    status: .poor,
                    range: "<5 or >11 hours",
                    description: "Consider improving sleep habits"
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
        SleepStatusDetailView(
            contributor: ReadinessContributor(
                name: "Sleep",
                value: "8.5 hours",
                status: .optimal,
                score: 1.0
            ),
            date: Date()
        )
        .environmentObject(TabCoordinator())
    }
}

