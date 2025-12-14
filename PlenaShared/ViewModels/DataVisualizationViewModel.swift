//
//  DataVisualizationViewModel.swift
//  PlenaShared
//
//  Created on [Date]
//

import Foundation
import Combine
import SwiftUI

@MainActor
class DataVisualizationViewModel: ObservableObject {
    @Published var sessions: [MeditationSession] = []
    @Published var selectedTimeRange: TimeRange = .day
    @Published var selectedSensor: SensorType = .heartRate {
        didSet {
            // Invalidate cached computed properties when sensor changes
            invalidateCachedProperties()
        }
    }
    @Published var temperatureUnit: TemperatureUnit = .fahrenheit // Default to Fahrenheit
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - New Properties for Enhanced Visualization

    /// View mode: Consistency (bars) or Trend (line chart)
    @Published var viewMode: ViewMode = .trend {
        didSet {
            // Invalidate cached computed properties when view mode changes
            _cachedPeriodScores = nil
        }
    }

    // Service dependencies
    private let storageService: SessionStorageServiceProtocol
    private let baselineService: BaselineCalculationServiceProtocol
    private let aggregationService: MetricAggregationServiceProtocol
    private let zoneClassifier: ZoneClassifierProtocol

    // Cached baselines (recalculated when sessions change)
    private var _cachedHRVBaseline: Double?
    private var _cachedRestingHR: Double?

    // Cached computed properties (invalidated when dependencies change)
    private var _cachedPeriodScores: [PeriodScore]?
    private var _cachedZoneSummaries: [ZoneSummary]?
    private var _cachedTrendStats: TrendStats?

    init(
        storageService: SessionStorageServiceProtocol = CoreDataStorageService(),
        baselineService: BaselineCalculationServiceProtocol = BaselineCalculationService(),
        aggregationService: MetricAggregationServiceProtocol = MetricAggregationService(),
        zoneClassifier: ZoneClassifierProtocol = ZoneClassifier()
    ) {
        self.storageService = storageService
        self.baselineService = baselineService
        self.aggregationService = aggregationService
        self.zoneClassifier = zoneClassifier

        // Set default view mode based on initial time range
        self.viewMode = defaultViewMode(for: selectedTimeRange)
    }

    /// Returns default view mode for a time range
    private func defaultViewMode(for timeRange: TimeRange) -> ViewMode {
        switch timeRange {
        case .day, .year:
            return .trend
        case .week, .month:
            return .consistency
        }
    }

    func loadSessions() async {
        isLoading = true
        errorMessage = nil

        do {
            // Use date-range query for better performance with large datasets
            let (startDate, endDate) = selectedTimeRange.dateRange
            sessions = try storageService.loadSessions(startDate: startDate, endDate: endDate)

            // Recalculate baselines when sessions change
            await recalculateBaselines()

            // Invalidate cached computed properties
            invalidateCachedProperties()
        } catch {
            errorMessage = "Failed to load sessions: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Recalculates baselines from all available sessions (not just current time range)
    /// Uses limited session loading (last 30 days) to prevent excessive memory usage
    private func recalculateBaselines() async {
        // Load sessions for baseline calculation (last 30 days)
        // Note: This loads full sessions with samples which is needed for baseline calculation
        // but is limited to 30 days to manage memory usage
        let calendar = Calendar.current
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date()) ?? Date()

        do {
            let baselineSessions = try storageService.loadSessions(startDate: thirtyDaysAgo, endDate: Date())
            _cachedHRVBaseline = baselineService.calculateHRVBaseline(from: baselineSessions)
            _cachedRestingHR = baselineService.calculateRestingHeartRate(from: baselineSessions)
        } catch {
            // If baseline calculation fails, continue without baselines (will use fallback thresholds)
            _cachedHRVBaseline = nil
            _cachedRestingHR = nil
        }
    }

    /// Invalidates cached computed properties
    private func invalidateCachedProperties() {
        _cachedPeriodScores = nil
        _cachedZoneSummaries = nil
        _cachedTrendStats = nil
    }

    /// Reloads sessions when time range changes
    func reloadForTimeRange() async {
        // Update default view mode for new time range
        viewMode = defaultViewMode(for: selectedTimeRange)
        await loadSessions()
    }

    // MARK: - Filtered Data

    var filteredSessions: [MeditationSession] {
        // Sessions are already filtered by date range, but apply additional filtering if needed
        sessions
    }

    // MARK: - Sensor Data Extraction

    func heartRateDataPoints() -> [(date: Date, value: Double)] {
        filteredSessions.flatMap { session in
            session.heartRateSamples.map { (date: $0.timestamp, value: $0.value) }
        }.sorted { $0.date < $1.date }
    }

    func hrvDataPoints() -> [(date: Date, value: Double)] {
        filteredSessions.flatMap { session in
            session.hrvSamples.map { (date: $0.timestamp, value: $0.sdnn) }
        }.sorted { $0.date < $1.date }
    }

    func respiratoryRateDataPoints() -> [(date: Date, value: Double)] {
        filteredSessions.flatMap { session in
            session.respiratoryRateSamples.map { (date: $0.timestamp, value: $0.value) }
        }.sorted { $0.date < $1.date }
    }

    func vo2MaxDataPoints() -> [(date: Date, value: Double)] {
        filteredSessions.flatMap { session in
            session.vo2MaxSamples.map { (date: $0.timestamp, value: $0.value) }
        }.sorted { $0.date < $1.date }
    }

    func temperatureDataPoints() -> [(date: Date, value: Double)] {
        let points = filteredSessions.flatMap { session in
            session.temperatureSamples.map { (date: $0.timestamp, value: $0.value) }
        }.sorted { $0.date < $1.date }

        // Convert from Celsius (stored) to display unit
        return points.map { (date: $0.date, value: convertTemperature($0.value, to: temperatureUnit)) }
    }

    // MARK: - Temperature Conversion

    /// Converts temperature from Celsius (stored) to display unit
    private func convertTemperature(_ celsius: Double, to unit: TemperatureUnit) -> Double {
        switch unit {
        case .fahrenheit:
            return (celsius * 9/5) + 32
        case .celsius:
            return celsius
        }
    }

    /// Converts temperature from display unit back to Celsius (for storage)
    private func convertTemperatureToCelsius(_ value: Double, from unit: TemperatureUnit) -> Double {
        switch unit {
        case .fahrenheit:
            return (value - 32) * 5/9
        case .celsius:
            return value
        }
    }

    func currentSensorDataPoints() -> [(date: Date, value: Double)] {
        switch selectedSensor {
        case .heartRate:
            return heartRateDataPoints()
        case .hrv:
            return hrvDataPoints()
        case .respiratoryRate:
            return respiratoryRateDataPoints()
        case .vo2Max:
            return vo2MaxDataPoints()
        case .temperature:
            return temperatureDataPoints()
        }
    }

    // MARK: - Range Calculations

    func sensorRange(for sensor: SensorType) -> SensorRange {
        switch sensor {
        case .heartRate:
            // Typical resting heart rate: 60-100 BPM
            // Below: < 60, Normal: 60-100, Above: > 100
            return SensorRange(
                above: 100...200,
                normal: 60...100,
                below: 30...60
            )
        case .hrv:
            // Typical HRV SDNN: 20-60ms for most people
            // Below: < 20, Normal: 20-60, Above: > 60
            return SensorRange(
                above: 60...200,
                normal: 20...60,
                below: 0...20
            )
        case .respiratoryRate:
            // Typical respiratory rate: 12-20 breaths/min
            // Below: < 12, Normal: 12-20, Above: > 20
            return SensorRange(
                above: 20...40,
                normal: 12...20,
                below: 0...12
            )
        case .vo2Max:
            // VO2 Max ranges vary by age/gender, but typical ranges:
            // Below: < 35 (poor), Normal: 35-55 (average to good), Above: > 55 (excellent)
            return SensorRange(
                above: 55...100,
                normal: 35...55,
                below: 15...35
            )
        case .temperature:
            // Body temperature ranges in Celsius
            // Normal: 36.5-37.5°C (97.7-99.5°F)
            // Below: < 36.5°C (< 97.7°F) - hypothermia
            // Above: > 37.5°C (> 99.5°F) - fever
            let celsiusRange = SensorRange(
                above: 37.5...42.0,
                normal: 36.5...37.5,
                below: 32.0...36.5
            )

            // Convert to display unit (Fahrenheit default)
            return SensorRange(
                above: convertTemperature(celsiusRange.above.lowerBound, to: temperatureUnit)...convertTemperature(celsiusRange.above.upperBound, to: temperatureUnit),
                normal: convertTemperature(celsiusRange.normal.lowerBound, to: temperatureUnit)...convertTemperature(celsiusRange.normal.upperBound, to: temperatureUnit),
                below: convertTemperature(celsiusRange.below.lowerBound, to: temperatureUnit)...convertTemperature(celsiusRange.below.upperBound, to: temperatureUnit)
            )
        }
    }

    var currentSensorRange: SensorRange {
        sensorRange(for: selectedSensor)
    }

    // MARK: - Statistics

    func averageValue() -> Double? {
        let dataPoints = currentSensorDataPoints()
        guard !dataPoints.isEmpty else { return nil }
        let sum = dataPoints.reduce(0.0) { $0 + $1.value }
        return sum / Double(dataPoints.count)
    }

    func minValue() -> Double? {
        let dataPoints = currentSensorDataPoints()
        return dataPoints.map { $0.value }.min()
    }

    func maxValue() -> Double? {
        let dataPoints = currentSensorDataPoints()
        return dataPoints.map { $0.value }.max()
    }

    // MARK: - Trend Calculation

    /// Calculates the trend by comparing recent data (last 25%) with earlier data (first 25%)
    /// Returns nil if there's insufficient data to calculate a trend
    func calculateTrend() -> Trend? {
        let dataPoints = currentSensorDataPoints()
        guard dataPoints.count >= 4 else { return nil }

        // Split data into first 25% and last 25%
        let firstQuarterCount = max(1, dataPoints.count / 4)
        let lastQuarterCount = max(1, dataPoints.count / 4)

        let firstQuarter = Array(dataPoints.prefix(firstQuarterCount))
        let lastQuarter = Array(dataPoints.suffix(lastQuarterCount))

        let earlierAverage = firstQuarter.reduce(0.0) { $0 + $1.value } / Double(firstQuarter.count)
        let recentAverage = lastQuarter.reduce(0.0) { $0 + $1.value } / Double(lastQuarter.count)

        // Calculate percentage change
        let change = recentAverage - earlierAverage
        let percentChange = abs(change / earlierAverage) * 100

        // Consider stable if change is less than 2%
        guard percentChange >= 2.0 else { return .stable }

        // Determine if change is improving based on sensor type
        let isImproving: Bool
        switch selectedSensor {
        case .hrv, .vo2Max:
            // Higher HRV and VO2 Max are better
            isImproving = change > 0
        case .heartRate, .respiratoryRate:
            // Lower values are better
            isImproving = change < 0
        case .temperature:
            // Temperature should be stable (closer to normal range is better)
            // For trend, we'll consider moving toward normal range as improving
            let normalMidpoint = (sensorRange(for: .temperature).normal.lowerBound + sensorRange(for: .temperature).normal.upperBound) / 2.0
            let earlierDistance = abs(earlierAverage - normalMidpoint)
            let recentDistance = abs(recentAverage - normalMidpoint)
            isImproving = recentDistance < earlierDistance
        }

        return isImproving ? .improving : .declining
    }

    // MARK: - Session Statistics (for trend tracking over time)

    /// Returns the total number of sessions in the current time range
    var sessionCount: Int {
        filteredSessions.count
    }

    /// Returns the total meditation time in minutes for the current time range
    var totalMinutes: Double {
        filteredSessions.reduce(0.0) { $0 + $1.duration / 60.0 }
    }

    /// Returns the average session duration in minutes
    var averageDuration: Double? {
        guard !filteredSessions.isEmpty else { return nil }
        return totalMinutes / Double(filteredSessions.count)
    }

    /// Returns the number of sessions per week (calculated from current time range)
    var sessionsPerWeek: Double? {
        let (startDate, endDate) = selectedTimeRange.dateRange
        let days = endDate.timeIntervalSince(startDate) / 86400.0 // seconds in a day
        guard days > 0 else { return nil }

        let weeks = days / 7.0
        guard weeks > 0 else { return nil }

        return Double(sessionCount) / weeks
    }

    // MARK: - Enhanced Visualization Properties

    /// Period scores for consistency chart (bars)
    var periodScores: [PeriodScore] {
        // Only calculate for supported metrics
        guard isSupportedMetric(selectedSensor) else { return [] }

        if let cached = _cachedPeriodScores {
            return cached
        }

        // Group sessions by period
        let grouped = aggregationService.groupSessionsByPeriod(
            sessions: filteredSessions,
            timeRange: selectedTimeRange
        )

        if selectedSensor == .vo2Max {
            let totalSessions = filteredSessions.count
            let sessionsWithVO2Max = filteredSessions.filter { !$0.vo2MaxSamples.isEmpty }
            print("📊 VO2 Max periodScores calculation: \(totalSessions) total sessions, \(sessionsWithVO2Max.count) with VO2 Max data, \(grouped.count) periods")
        }

        // Create period scores
        var scores: [PeriodScore] = []
        let calendar = Calendar.current

        for (label, periodSessions) in grouped.sorted(by: { $0.key < $1.key }) {
            // Get the start date of the period
            let periodDate: Date
            if let firstSession = periodSessions.first {
                switch selectedTimeRange {
                case .day:
                    // Use hour start
                    let hour = calendar.component(.hour, from: firstSession.startDate)
                    periodDate = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: firstSession.startDate) ?? firstSession.startDate
                case .week, .month:
                    // Use day start
                    periodDate = calendar.startOfDay(for: firstSession.startDate)
                case .year:
                    // Use month start
                    let components = calendar.dateComponents([.year, .month], from: firstSession.startDate)
                    periodDate = calendar.date(from: components) ?? firstSession.startDate
                }
            } else {
                continue
            }

            if let score = aggregationService.createPeriodScore(
                label: label,
                date: periodDate,
                sessions: periodSessions,
                metric: selectedSensor,
                hrvBaseline: _cachedHRVBaseline,
                restingHR: _cachedRestingHR,
                zoneClassifier: zoneClassifier
            ) {
                scores.append(score)
            } else if selectedSensor == .vo2Max {
                // Debug: Check why VO2 Max period score is nil
                let sessionsWithVO2Max = periodSessions.filter { !$0.vo2MaxSamples.isEmpty }
                print("⚠️ VO2 Max Period Score: \(label) - \(periodSessions.count) sessions, \(sessionsWithVO2Max.count) with VO2 Max data")
            }
        }

        // Sort by date
        scores.sort { $0.date < $1.date }

        _cachedPeriodScores = scores
        return scores
    }

    /// Zone summaries for zone chips
    var zoneSummaries: [ZoneSummary] {
        // Only calculate for supported metrics
        guard isSupportedMetric(selectedSensor) else {
            return StressZone.allCases.map { ZoneSummary(zone: $0, percentage: 0) }
        }

        if let cached = _cachedZoneSummaries {
            return cached
        }

        let summaries = aggregationService.createZoneSummaries(
            sessions: filteredSessions,
            metric: selectedSensor,
            hrvBaseline: _cachedHRVBaseline,
            restingHR: _cachedRestingHR,
            zoneClassifier: zoneClassifier
        )

        _cachedZoneSummaries = summaries
        return summaries
    }

    /// Trend stats for insight header
    var trendStats: TrendStats? {
        // Only calculate for supported metrics
        guard isSupportedMetric(selectedSensor) else { return nil }

        if let cached = _cachedTrendStats {
            return cached
        }

        // Get previous period sessions for comparison
        let (currentStart, currentEnd) = selectedTimeRange.dateRange
        let duration = currentEnd.timeIntervalSince(currentStart)
        let previousEnd = currentStart
        let previousStart = previousEnd.addingTimeInterval(-duration)

        let previousSessions: [MeditationSession]
        do {
            previousSessions = try storageService.loadSessions(startDate: previousStart, endDate: previousEnd)
        } catch {
            previousSessions = []
        }

        let stats = aggregationService.createTrendStats(
            currentSessions: filteredSessions,
            previousSessions: previousSessions,
            metric: selectedSensor
        )

        _cachedTrendStats = stats
        return stats
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
}

