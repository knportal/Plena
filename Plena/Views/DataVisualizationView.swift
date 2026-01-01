//
//  DataVisualizationView.swift
//  Plena
//
//  Created on [Date]
//

import SwiftUI
import Combine

struct DataVisualizationView: View {
    @StateObject private var viewModel: DataVisualizationViewModel
    @StateObject private var settingsViewModel: SettingsViewModel
    @State private var showSwipeHint = true
    @State private var showPaywall = false
    @EnvironmentObject var tabCoordinator: TabCoordinator
    private let subscriptionService: SubscriptionService

    init(storageService: SessionStorageServiceProtocol = CoreDataStorageService()) {
        // Initialize subscription services
        let subscriptionService = SubscriptionService()
        let featureGateService = FeatureGateService(subscriptionService: subscriptionService)

        self.subscriptionService = subscriptionService
        _settingsViewModel = StateObject(wrappedValue: SettingsViewModel(featureGateService: featureGateService))
        _viewModel = StateObject(wrappedValue: DataVisualizationViewModel(
            storageService: storageService,
            featureGateService: featureGateService
        ))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    timeRangeSelector

                    // New metric selector with icons and subtitles
                    MetricSelectorView(
                        selectedMetric: $viewModel.selectedSensor,
                        enabledMetrics: enabledSensors
                    )
                    .padding(.horizontal, 16)
                    .onChange(of: settingsViewModel.heartRateEnabled) {
                        updateSelectedSensorIfNeeded()
                    }
                    .onChange(of: settingsViewModel.hrvEnabled) {
                        updateSelectedSensorIfNeeded()
                    }
                    .onChange(of: settingsViewModel.respiratoryRateEnabled) {
                        updateSelectedSensorIfNeeded()
                    }
                    .onChange(of: settingsViewModel.vo2MaxEnabled) {
                        updateSelectedSensorIfNeeded()
                    }
                    .onChange(of: settingsViewModel.temperatureEnabled) {
                        updateSelectedSensorIfNeeded()
                    }

                    // Trend insight card (only for supported metrics)
                    if isSupportedMetric(viewModel.selectedSensor) {
                        TrendInsightCard(trendStats: viewModel.trendStats)
                            .padding(.horizontal)
                    }

                    // View mode toggle (only for supported metrics)
                    if isSupportedMetric(viewModel.selectedSensor) {
                        ViewModeToggle(viewMode: $viewModel.viewMode)
                            .padding(.horizontal)
                    }

                    // Temperature info banner
                    if viewModel.selectedSensor == .temperature {
                        temperatureInfoBanner
                            .padding(.horizontal)
                    }

                    // VO₂ Max info banner
                    if viewModel.selectedSensor == .vo2Max {
                        vo2MaxInfoBanner
                            .padding(.horizontal)
                    }

                    // Chart content
                    graphContent
                        .padding(.horizontal)

                    // Zone chips (only for supported metrics in consistency mode)
                    if isSupportedMetric(viewModel.selectedSensor) && viewModel.viewMode == .consistency {
                        ZoneChipsView(zoneSummaries: viewModel.zoneSummaries)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Data Visualization")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showPaywall) {
                SubscriptionPaywallView(
                    feature: .extendedTimeRanges,
                    isPresented: $showPaywall
                )
            }
            .onReceive(
                subscriptionService.subscriptionStatus
                    .map { $0.isPremium }
                    .removeDuplicates()
                    .eraseToAnyPublisher()
            ) { isPremium in
                // Auto-dismiss paywall if user gains premium access
                if isPremium && showPaywall {
                    showPaywall = false
                }
            }
            .onChange(of: viewModel.showPaywall) { oldValue, newValue in
                if newValue {
                    showPaywall = true
                    viewModel.showPaywall = false
                }
            }
            .task {
                await viewModel.loadSessions()
                // Sync temperature unit from settings
                viewModel.temperatureUnit = settingsViewModel.temperatureUnit
            }
            .onChange(of: settingsViewModel.temperatureUnit) { oldValue, newValue in
                viewModel.temperatureUnit = newValue
            }
            .onChange(of: tabCoordinator.selectedSensor) { oldValue, newValue in
                if let sensor = newValue {
                    // Update the view model's selected sensor
                    viewModel.selectedSensor = sensor
                    // Reload data for the new sensor
                    Task {
                        await viewModel.reloadForTimeRange()
                    }
                    // Clear the selected sensor after a delay to ensure the view updates
                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 second delay
                        tabCoordinator.selectedSensor = nil
                    }
                }
            }
            .onChange(of: tabCoordinator.selectedTab) { oldValue, newValue in
                // When Data tab is selected, check for pending sensor
                if newValue == 3, let sensor = tabCoordinator.selectedSensor {
                    viewModel.selectedSensor = sensor
                    Task {
                        await viewModel.reloadForTimeRange()
                    }
                }
            }
            .onAppear {
                // Refresh subscription status when view appears
                Task {
                    await subscriptionService.checkSubscriptionStatus()
                }
                // Check for pending sensor selection when view appears
                if let sensor = tabCoordinator.selectedSensor {
                    viewModel.selectedSensor = sensor
                    Task {
                        await viewModel.reloadForTimeRange()
                    }
                }
            }
            .onChange(of: tabCoordinator.selectedTab) { oldValue, newValue in
                // Refresh subscription status when switching to this tab
                if newValue == 3 { // Data Visualization tab
                    Task {
                        await subscriptionService.checkSubscriptionStatus()
                    }
                }
            }
            .onChange(of: showPaywall) { oldValue, newValue in
                // When paywall is dismissed, check if user now has access
                if oldValue == true && newValue == false {
                    Task {
                        await subscriptionService.checkSubscriptionStatus()

                        // Get current subscription status
                        let status = subscriptionService.currentSubscriptionStatus()

                        if status.isPremium {
                            // User purchased - reload with current time range
                            await viewModel.reloadForTimeRange()
                        } else {
                            // User didn't purchase - reset to free tier to prevent infinite loop
                            if viewModel.selectedTimeRange == .month || viewModel.selectedTimeRange == .year {
                                viewModel.selectedTimeRange = .week
                            }
                        }
                    }
                }
            }
        }
    }

    /// Checks if metric is supported in enhanced visualization
    /// VO2 Max is supported for trend tracking and zone summaries
    /// (uses latest value per session since it doesn't change during sessions)
    private func isSupportedMetric(_ metric: SensorType) -> Bool {
        switch metric {
        case .hrv, .heartRate, .respiratoryRate, .vo2Max:
            return true
        case .temperature:
            return false // Not yet supported
        }
    }

    // MARK: - View Components

    private var timeRangeSelector: some View {
        Picker("Time Range", selection: $viewModel.selectedTimeRange) {
            // Show all time ranges - access will be checked when loading
            ForEach([TimeRange.day, TimeRange.week, TimeRange.month, TimeRange.year], id: \.self) { range in
                Text(range.rawValue).tag(range)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 4)
        .onChange(of: viewModel.selectedTimeRange) {
            Task {
                // Refresh subscription status first to ensure it's up to date
                await subscriptionService.checkSubscriptionStatus()

                // Check access after refresh
                let status = subscriptionService.currentSubscriptionStatus()
                let isPremium = status.isPremium

                // Don't show paywall if user already has premium
                if isPremium {
                    // User has premium - just reload
                    await viewModel.reloadForTimeRange()
                    // Ensure paywall is dismissed if it was showing
                    if showPaywall {
                        showPaywall = false
                    }
                } else if (viewModel.selectedTimeRange == .month || viewModel.selectedTimeRange == .year) {
                    // Trying to select premium range without access - show paywall and reset
                    showPaywall = true
                    // Reset to week to prevent getting stuck
                    viewModel.selectedTimeRange = .week
                } else {
                    // Selecting free tier - reload
                    await viewModel.reloadForTimeRange()
                    if viewModel.showPaywall {
                        showPaywall = true
                    }
                }
            }
        }
    }

    private var enabledSensors: [SensorType] {
        SensorType.allCases.filter { settingsViewModel.isSensorEnabled($0) }
    }

    private func updateSelectedSensorIfNeeded() {
        if !enabledSensors.contains(viewModel.selectedSensor) {
            // Current sensor is disabled, switch to first enabled sensor
            if let firstEnabled = enabledSensors.first {
                viewModel.selectedSensor = firstEnabled
            }
        }
    }


    @ViewBuilder
    private var graphContent: some View {
        // Check if selected sensor is enabled
        if !settingsViewModel.isSensorEnabled(viewModel.selectedSensor) {
            VStack(spacing: 10) {
                Image(systemName: "eye.slash")
                    .font(.largeTitle)
                    .foregroundColor(.secondary)
                Text("This sensor is disabled in Settings")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .frame(height: 200)
        } else if viewModel.isLoading {
            ProgressView("Loading data...")
                .frame(height: 200)
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
            .frame(height: 200)
        } else {
            // Show enhanced visualization for supported metrics, or existing view for others
            if isSupportedMetric(viewModel.selectedSensor) {
                enhancedGraphView
            } else {
                legacyGraphView
            }
        }
    }

    /// Enhanced graph view with consistency/trend toggle
    @ViewBuilder
    private var enhancedGraphView: some View {
        VStack(spacing: 12) {
            // Chart explanation
            chartExplanation
                .padding(.horizontal, 4)

            if viewModel.viewMode == .consistency {
                // Consistency chart (bars)
                ConsistencyChartView(
                    periodScores: viewModel.periodScores,
                    timeRange: viewModel.selectedTimeRange
                )
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.secondarySystemBackground))
                )

                // Stats row (min/max/avg) - only for consistency mode
                statsRow
            } else {
                // Trend chart (line graph) - already includes stats row
                GraphView(
                    dataPoints: viewModel.currentSensorDataPoints(),
                    sensorRange: viewModel.currentSensorRange,
                    sensorName: viewModel.selectedSensor.rawValue,
                    unit: unitForSensor(viewModel.selectedSensor),
                    trend: viewModel.calculateTrend(),
                    timeRange: viewModel.selectedTimeRange
                )
            }
        }
    }

    /// Chart explanation text based on sensor and view mode
    private var chartExplanation: some View {
        Text(explanationText(for: viewModel.selectedSensor, mode: viewModel.viewMode))
            .font(.caption)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Returns explanation text for the chart
    private func explanationText(for sensor: SensorType, mode: ViewMode) -> String {
        switch (sensor, mode) {
        case (.hrv, .consistency):
            return "Bar height shows % of time in calm zone. Bar color shows the dominant zone (the zone with most time) for that period."
        case (.hrv, .trend):
            return "Line shows HRV values over time. Higher values indicate better recovery capacity."

        case (.heartRate, .consistency):
            return "Bar height shows % of time in calm zone. Bar color shows the dominant zone (the zone with most time) for that period."
        case (.heartRate, .trend):
            return "Line shows heart rate over time. Lower values during sessions indicate calmer state."

        case (.respiratoryRate, .consistency):
            return "Bar height shows % of time in calm zone. Bar color shows the dominant zone (the zone with most time) for that period."
        case (.respiratoryRate, .trend):
            return "Line shows breathing rate over time. Slower, steadier breathing indicates deeper calm."

        case (.vo2Max, .consistency):
            return "Bar shows VO2 Max zone for each period. Higher fitness (green) = better cardiovascular health."
        case (.vo2Max, .trend):
            return "Line shows VO2 Max over time. Higher values indicate improving cardiovascular fitness."

        default:
            return ""
        }
    }

    /// Legacy graph view for unsupported metrics
    private var legacyGraphView: some View {
        graphViewWithSwipe
    }

    /// Temperature info banner explaining sleep measurement
    private var temperatureInfoBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "moon.zzz.fill")
                .font(.title3)
                .foregroundColor(.blue)

            VStack(alignment: .leading, spacing: 4) {
                Text("Temperature Data")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text("Body temperature is typically measured during sleep on Apple Watch. Data shown here reflects readings from your sleep periods.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
    }

    /// VO₂ Max info banner explaining workout measurement
    private var vo2MaxInfoBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "figure.run")
                .font(.title3)
                .foregroundColor(.orange)

            VStack(alignment: .leading, spacing: 4) {
                Text("VO₂ Max Data")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text("VO₂ Max is calculated from your workout and exercise sessions. Data shown here reflects your cardiovascular fitness measurements from activities like running, cycling, and other intense exercises.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }

    /// Stats row showing min/max/avg
    private var statsRow: some View {
        HStack(spacing: 20) {
            if let min = viewModel.minValue() {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Min")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(Int(min)) \(unitForSensor(viewModel.selectedSensor))")
                        .font(.body)
                }
            }

            Spacer()

            if let avg = viewModel.averageValue() {
                VStack(alignment: .center, spacing: 2) {
                    Text("Avg")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(Int(avg)) \(unitForSensor(viewModel.selectedSensor))")
                        .font(.body)
                }
            }

            Spacer()

            if let max = viewModel.maxValue() {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Max")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(Int(max)) \(unitForSensor(viewModel.selectedSensor))")
                        .font(.body)
                }
            }
        }
        .padding(.top, 8)
    }

    private var graphViewWithSwipe: some View {
        ZStack {
            ScrollView {
                GraphView(
                    dataPoints: viewModel.currentSensorDataPoints(),
                    sensorRange: viewModel.currentSensorRange,
                    sensorName: viewModel.selectedSensor.rawValue,
                    unit: unitForSensor(viewModel.selectedSensor),
                    trend: viewModel.calculateTrend(),
                    timeRange: viewModel.selectedTimeRange
                )
                .padding(.bottom, 60)
            }
            .simultaneousGesture(swipeGesture)

            if showSwipeHint {
                swipeHints
            }
        }
    }

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 30)
            .onEnded { value in
                let horizontalAmount = value.translation.width
                let verticalAmount = abs(value.translation.height)

                if abs(horizontalAmount) > 50 && abs(horizontalAmount) > verticalAmount * 2 {
                    withAnimation {
                        showSwipeHint = false
                    }

                    if horizontalAmount > 0 {
                        switchToPreviousTimeRange()
                    } else {
                        switchToNextTimeRange()
                    }
                }
            }
    }

    private var swipeHints: some View {
        HStack {
            SwipeChevron(direction: .left)
                .padding(.leading, 8)

            Spacer()

            SwipeChevron(direction: .right)
                .padding(.trailing, 8)
        }
        .padding(.top, 100)
        .opacity(showSwipeHint ? 1 : 0)
        .animation(.easeInOut(duration: 0.3), value: showSwipeHint)
    }

    private func switchToNextTimeRange() {
        let allCases = TimeRange.allCases
        guard let currentIndex = allCases.firstIndex(of: viewModel.selectedTimeRange) else { return }

        let nextIndex = (currentIndex + 1) % allCases.count
        viewModel.selectedTimeRange = allCases[nextIndex]
    }

    private func switchToPreviousTimeRange() {
        let allCases = TimeRange.allCases
        guard let currentIndex = allCases.firstIndex(of: viewModel.selectedTimeRange) else { return }

        let previousIndex = (currentIndex - 1 + allCases.count) % allCases.count
        viewModel.selectedTimeRange = allCases[previousIndex]
    }

    private func unitForSensor(_ sensor: SensorType) -> String {
        switch sensor {
        case .heartRate:
            return "BPM"
        case .hrv:
            return "ms"
        case .respiratoryRate:
            return "/min"
        case .vo2Max:
            return "mL/kg/min"
        case .temperature:
            return viewModel.temperatureUnit.rawValue
        }
    }
}

// MARK: - Sensor Card

struct SensorCard: View {
    let sensor: SensorType
    let isSelected: Bool
    let unit: String
    let index: Int
    let action: () -> Void

    @State private var hasAppeared = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                // Icon - prominent in center
                Image(systemName: iconForSensor(sensor))
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(isSelected ? colorForSensor(sensor) : .primary)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(isSelected ? colorForSensor(sensor).opacity(0.15) : Color.primary.opacity(0.08))
                    )

                // Sensor name - compact, removed unit text
                Text(sensor.rawValue)
                    .font(.system(size: 9, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(width: 60, height: 60)
            .padding(8)
            .background(
                // Circular glassmorphic background
                Circle()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Circle()
                            .stroke(
                                isSelected ? colorForSensor(sensor) : Color.clear,
                                lineWidth: isSelected ? 2 : 0
                            )
                    )
                    .shadow(
                        color: isSelected ? colorForSensor(sensor).opacity(0.3) : .black.opacity(0.1),
                        radius: isSelected ? 8 : 3,
                        x: 0,
                        y: isSelected ? 2 : 1
                    )
            )
            .scaleEffect(isSelected ? 1.1 : (hasAppeared ? 1.0 : 0.85))
            .opacity(hasAppeared ? 1.0 : 0.0)
            .offset(x: hasAppeared ? 0 : 20)
        }
        .buttonStyle(.plain)
        .onAppear {
            // Staggered animation - triggers when card appears
            if !hasAppeared {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75).delay(Double(index) * 0.05)) {
                    hasAppeared = true
                }
            }
        }
    }

    private func iconForSensor(_ sensor: SensorType) -> String {
        switch sensor {
        case .heartRate:
            return "heart.fill"
        case .hrv:
            return "waveform.path.ecg"
        case .respiratoryRate:
            return "wind"
        case .vo2Max:
            return "figure.run"
        case .temperature:
            return "thermometer"
        }
    }

    private func colorForSensor(_ sensor: SensorType) -> Color {
        switch sensor {
        case .heartRate:
            return .red
        case .hrv:
            return .blue
        case .respiratoryRate:
            return .green
        case .vo2Max:
            return .orange
        case .temperature:
            return .purple
        }
    }
}

// MARK: - Swipe Chevron Indicator

struct SwipeChevron: View {
    enum Direction {
        case left, right
    }

    let direction: Direction
    @State private var isAnimating = false

    var body: some View {
        Image(systemName: direction == .left ? "chevron.left" : "chevron.right")
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.blue.opacity(0.6))
            .padding(8)
            .background(
                Circle()
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 1)
            )
            .offset(x: direction == .left ? (isAnimating ? -4 : 0) : (isAnimating ? 4 : 0))
            .opacity(isAnimating ? 0.4 : 0.8)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
            }
    }
}

#Preview {
    DataVisualizationView()
}

