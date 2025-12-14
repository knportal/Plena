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
            Text("Calculation Breakdown")
                .font(.title2)
                .fontWeight(.bold)

            VStack(spacing: 12) {
                if let current = viewModel.currentSleepHours {
                    CalculationRow(
                        label: "Last Night",
                        value: String(format: "%.1f hours", current),
                        description: "Sleep duration for selected date"
                    )
                }

                if let average = viewModel.averageSleepHours {
                    CalculationRow(
                        label: "7-Day Average",
                        value: String(format: "%.1f hours", average),
                        description: "Average sleep over last week"
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

            Text("Sleep is fundamental to recovery and readiness. Adequate sleep (7-9 hours) supports physical and mental recovery, while insufficient or excessive sleep can negatively impact your readiness for meditation and daily activities.")
                .font(.body)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                BulletPoint(text: "7-9 hours = optimal recovery")
                BulletPoint(text: "Consistent sleep supports better readiness")
                BulletPoint(text: "Too little sleep impairs recovery")
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
                    description: "Ideal sleep duration for recovery"
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
                    description: "May indicate sleep issues"
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
                value: "7.5 hours",
                status: .optimal,
                score: 1.0
            ),
            date: Date()
        )
        .environmentObject(TabCoordinator())
    }
}
