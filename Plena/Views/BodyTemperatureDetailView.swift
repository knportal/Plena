//
//  BodyTemperatureDetailView.swift
//  Plena
//
//  Detail view for Body Temperature contributor
//

import SwiftUI
import Charts

struct BodyTemperatureDetailView: View {
    @StateObject private var viewModel: BodyTemperatureDetailViewModel
    @StateObject private var settingsViewModel = SettingsViewModel()
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
        _viewModel = StateObject(wrappedValue: BodyTemperatureDetailViewModel(
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

                // Link to Data Tab
                dataTabLinkSection
            }
            .padding()
        }
        .navigationTitle("Body Temperature")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadData(for: date)
            // Sync temperature unit from settings
            viewModel.temperatureUnit = settingsViewModel.temperatureUnit
        }
        .onChange(of: settingsViewModel.temperatureUnit) { _, newValue in
            viewModel.temperatureUnit = newValue
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 12) {
            // Large value display
            if let currentTemp = viewModel.currentTemperature {
                VStack(spacing: 4) {
                    Text(viewModel.formatTemperature(currentTemp))
                        .font(.system(size: 64, weight: .bold))
                        .foregroundColor(.primary)

                    Text(viewModel.temperatureUnitSymbol())
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
                if let baseline = viewModel.baselineTemperature {
                    CalculationRow(
                        label: "Baseline",
                        value: "\(viewModel.formatTemperature(baseline)) \(viewModel.temperatureUnitSymbol())",
                        description: "Average from last 7 days"
                    )
                }

                if let current = viewModel.currentTemperature {
                    CalculationRow(
                        label: "Current",
                        value: "\(viewModel.formatTemperature(current)) \(viewModel.temperatureUnitSymbol())",
                        description: "Latest reading from today"
                    )
                }

                if let deviation = viewModel.deviation {
                    CalculationRow(
                        label: "Deviation",
                        value: String(format: "%.2f°C", deviation),
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
                    if let baseline = viewModel.baselineTemperature {
                        RuleMark(y: .value("Baseline", baseline))
                            .foregroundStyle(.green.opacity(0.6))
                            .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                            .annotation(position: .top, alignment: .trailing) {
                                Text("Baseline: \(viewModel.formatTemperature(baseline))")
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
                            y: .value("Temperature", point.value)
                        )
                        .foregroundStyle(.blue)
                        .lineStyle(StrokeStyle(lineWidth: 2.5))
                        .interpolationMethod(.catmullRom)

                        // Data points
                        PointMark(
                            x: .value("Day", point.date, unit: .day),
                            y: .value("Temperature", point.value)
                        )
                        .foregroundStyle(.blue)
                        .symbolSize(60)
                    }
                }
                .frame(height: 220)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let doubleValue = value.as(Double.self) {
                                Text(viewModel.formatTemperature(doubleValue))
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

            Text("Body temperature is a key indicator of recovery and health. A stable temperature close to your personal baseline suggests good recovery. Significant deviations may indicate illness, stress, or insufficient recovery.")
                .font(.body)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                BulletPoint(text: "Stable temperature = good recovery")
                BulletPoint(text: "Small deviations are normal")
                BulletPoint(text: "Large deviations may indicate illness or stress")
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
                    range: "≤0.3°C deviation",
                    description: "Very stable, excellent recovery"
                )

                ThresholdRow(
                    status: .higher,
                    range: "≤0.6°C deviation",
                    description: "Stable, good recovery"
                )

                ThresholdRow(
                    status: .moderate,
                    range: "≤1.0°C deviation",
                    description: "Some variability, monitor closely"
                )

                ThresholdRow(
                    status: .lower,
                    range: ">1.0°C deviation",
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
            tabCoordinator.navigateToDataTab(sensor: .temperature)
        }) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title3)

                VStack(alignment: .leading, spacing: 4) {
                    Text("View in Data Tab")
                        .font(.headline)

                    Text("See detailed temperature trends and analysis")
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
        BodyTemperatureDetailView(
            contributor: ReadinessContributor(
                name: "Body temperature",
                value: "Higher",
                status: .higher,
                score: 0.75
            ),
            date: Date()
        )
        .environmentObject(TabCoordinator())
    }
}
