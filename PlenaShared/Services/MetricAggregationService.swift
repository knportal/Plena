//
//  MetricAggregationService.swift
//  PlenaShared
//
//  Service for aggregating session data into period scores and zone summaries
//

import Foundation

/// Protocol for metric aggregation (for testability)
protocol MetricAggregationServiceProtocol {
    /// Creates session metric summary from a meditation session
    func createSessionMetricSummary(
        session: MeditationSession,
        metric: SensorType,
        hrvBaseline: Double?,
        restingHR: Double?,
        zoneClassifier: ZoneClassifierProtocol
    ) -> SessionMetricSummary?

    /// Groups sessions by period based on time range
    func groupSessionsByPeriod(
        sessions: [MeditationSession],
        timeRange: TimeRange
    ) -> [String: [MeditationSession]]

    /// Creates period score from grouped sessions
    func createPeriodScore(
        label: String,
        date: Date,
        sessions: [MeditationSession],
        metric: SensorType,
        hrvBaseline: Double?,
        restingHR: Double?,
        zoneClassifier: ZoneClassifierProtocol
    ) -> PeriodScore?

    /// Creates zone summaries from sessions
    func createZoneSummaries(
        sessions: [MeditationSession],
        metric: SensorType,
        hrvBaseline: Double?,
        restingHR: Double?,
        zoneClassifier: ZoneClassifierProtocol
    ) -> [ZoneSummary]

    /// Creates trend stats comparing current period to previous period
    func createTrendStats(
        currentSessions: [MeditationSession],
        previousSessions: [MeditationSession],
        metric: SensorType
    ) -> TrendStats
}

/// Service for aggregating meditation session data into visualization metrics
struct MetricAggregationService: MetricAggregationServiceProtocol {

    // MARK: - Session Metric Summary

    /// Creates session metric summary from a meditation session
    /// - Parameters:
    ///   - session: Meditation session to analyze
    ///   - metric: Sensor type to analyze (HRV, Heart Rate, or Respiration)
    ///   - hrvBaseline: Optional HRV baseline for personalized classification
    ///   - restingHR: Optional resting heart rate for personalized classification
    ///   - zoneClassifier: Zone classifier instance
    /// - Returns: SessionMetricSummary or nil if session has no data for the metric
    func createSessionMetricSummary(
        session: MeditationSession,
        metric: SensorType,
        hrvBaseline: Double?,
        restingHR: Double?,
        zoneClassifier: ZoneClassifierProtocol
    ) -> SessionMetricSummary? {
        // Get samples for the metric
        let samples: [(timestamp: Date, value: Double)]
        switch metric {
        case .hrv:
            samples = session.hrvSamples.map { ($0.timestamp, $0.sdnn) }
        case .heartRate:
            samples = session.heartRateSamples.map { ($0.timestamp, $0.value) }
        case .respiratoryRate:
            samples = session.respiratoryRateSamples.map { ($0.timestamp, $0.value) }
        default:
            return nil // VO2Max and Temperature not supported in Stage 2
        }

        guard !samples.isEmpty else { return nil }

        // Calculate average value
        let avgValue = samples.reduce(0.0) { $0 + $1.value } / Double(samples.count)

        // Calculate zone fractions
        var zoneTime: [StressZone: Double] = [.calm: 0, .optimal: 0, .elevatedStress: 0]

        // Classify each sample and accumulate time in each zone
        // For simplicity, we'll treat each sample as equal time weight
        // In a more sophisticated implementation, we could weight by actual time intervals
        for sample in samples {
            let zone: StressZone
            switch metric {
            case .hrv:
                zone = zoneClassifier.classifyHRV(sample.value, age: nil, baseline: hrvBaseline)
            case .heartRate:
                zone = zoneClassifier.classifyHeartRate(sample.value, baseline: restingHR)
            case .respiratoryRate:
                zone = zoneClassifier.classifyRespiratoryRate(sample.value)
            default:
                continue
            }
            zoneTime[zone, default: 0] += 1.0
        }

        // Convert counts to fractions
        let totalSamples = Double(samples.count)
        let zoneFractions: [StressZone: Double] = [
            .calm: zoneTime[.calm]! / totalSamples,
            .optimal: zoneTime[.optimal]! / totalSamples,
            .elevatedStress: zoneTime[.elevatedStress]! / totalSamples
        ]

        // Determine dominant zone
        let dominantZone = zoneFractions.max(by: { $0.value < $1.value })?.key ?? .optimal

        return SessionMetricSummary(
            sessionID: session.id,
            date: session.startDate,
            metric: metric,
            avgValue: avgValue,
            zoneFractions: zoneFractions,
            dominantZone: dominantZone
        )
    }

    // MARK: - Period Grouping

    /// Groups sessions by period based on time range
    /// - Parameters:
    ///   - sessions: Array of meditation sessions
    ///   - timeRange: Time range (Day, Week, Month, Year)
    /// - Returns: Dictionary mapping period labels to sessions
    func groupSessionsByPeriod(
        sessions: [MeditationSession],
        timeRange: TimeRange
    ) -> [String: [MeditationSession]] {
        let calendar = Calendar.current
        var grouped: [String: [MeditationSession]] = [:]
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")

        switch timeRange {
        case .day:
            // Group by hour
            formatter.dateFormat = "ha"
            for session in sessions {
                let hour = calendar.component(.hour, from: session.startDate)
                guard let hourDate = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: session.startDate) else { continue }
                let label = formatter.string(from: hourDate).replacingOccurrences(of: " ", with: "")
                grouped[label, default: []].append(session)
            }

        case .week:
            // Group by day
            formatter.dateFormat = "E" // Day abbreviation (Mon, Tue, etc.)
            for session in sessions {
                let label = formatter.string(from: session.startDate)
                grouped[label, default: []].append(session)
            }

        case .month:
            // Group by week (W1, W2, W3, W4, W5)
            let (startDate, endDate) = timeRange.dateRange
            var currentDate = calendar.startOfDay(for: startDate)
            var weekNumber = 1

            while currentDate <= endDate {
                let weekEnd = calendar.date(byAdding: .day, value: 7, to: currentDate) ?? endDate
                let weekSessions = sessions.filter { session in
                    session.startDate >= currentDate && session.startDate < weekEnd
                }

                if !weekSessions.isEmpty {
                    grouped["W\(weekNumber)", default: []].append(contentsOf: weekSessions)
                }

                currentDate = weekEnd
                weekNumber += 1
            }

        case .year:
            // Group by month
            formatter.dateFormat = "MMM"
            for session in sessions {
                let label = formatter.string(from: session.startDate)
                grouped[label, default: []].append(session)
            }
        }

        return grouped
    }

    // MARK: - Period Score

    /// Creates period score from grouped sessions
    /// - Parameters:
    ///   - label: Period label (e.g., "Mon", "W1", "Dec")
    ///   - date: Start date of the period
    ///   - sessions: Sessions in this period
    ///   - metric: Sensor type
    ///   - hrvBaseline: Optional HRV baseline
    ///   - restingHR: Optional resting HR
    ///   - zoneClassifier: Zone classifier instance
    /// - Returns: PeriodScore or nil if no valid sessions
    func createPeriodScore(
        label: String,
        date: Date,
        sessions: [MeditationSession],
        metric: SensorType,
        hrvBaseline: Double?,
        restingHR: Double?,
        zoneClassifier: ZoneClassifierProtocol
    ) -> PeriodScore? {
        guard !sessions.isEmpty else { return nil }

        // Create session summaries for all sessions in period
        let sessionSummaries = sessions.compactMap { session in
            createSessionMetricSummary(
                session: session,
                metric: metric,
                hrvBaseline: hrvBaseline,
                restingHR: restingHR,
                zoneClassifier: zoneClassifier
            )
        }

        guard !sessionSummaries.isEmpty else { return nil }

        // Calculate weighted calm fraction across all sessions
        var totalCalm: Double = 0
        var totalNeutral: Double = 0
        var totalStress: Double = 0

        for summary in sessionSummaries {
            totalCalm += summary.zoneFractions[.calm] ?? 0
            totalNeutral += summary.zoneFractions[.optimal] ?? 0
            totalStress += summary.zoneFractions[.elevatedStress] ?? 0
        }

        let total = max(totalCalm + totalNeutral + totalStress, 0.0001)
        let calmFraction = totalCalm / total

        // Calm score 0-100
        let calmScore = calmFraction * 100.0

        // Determine dominant zone for bar color
        let zone: StressZone
        if calmFraction >= 0.6 {
            zone = .calm
        } else if calmFraction >= 0.3 {
            zone = .optimal
        } else {
            zone = .elevatedStress
        }

        return PeriodScore(
            label: label,
            date: date,
            score: calmScore,
            zone: zone
        )
    }

    // MARK: - Zone Summary

    /// Creates zone summaries from sessions
    /// - Parameters:
    ///   - sessions: Array of meditation sessions
    ///   - metric: Sensor type
    ///   - hrvBaseline: Optional HRV baseline
    ///   - restingHR: Optional resting HR
    ///   - zoneClassifier: Zone classifier instance
    /// - Returns: Array of ZoneSummary sorted by zone
    func createZoneSummaries(
        sessions: [MeditationSession],
        metric: SensorType,
        hrvBaseline: Double?,
        restingHR: Double?,
        zoneClassifier: ZoneClassifierProtocol
    ) -> [ZoneSummary] {
        // Create session summaries
        let sessionSummaries = sessions.compactMap { session in
            createSessionMetricSummary(
                session: session,
                metric: metric,
                hrvBaseline: hrvBaseline,
                restingHR: restingHR,
                zoneClassifier: zoneClassifier
            )
        }

        guard !sessionSummaries.isEmpty else {
            // Return empty summaries if no data
            return StressZone.allCases.map { ZoneSummary(zone: $0, percentage: 0) }
        }

        // Calculate total time in each zone
        var totalCalm: Double = 0
        var totalNeutral: Double = 0
        var totalStress: Double = 0

        for summary in sessionSummaries {
            totalCalm += summary.zoneFractions[.calm] ?? 0
            totalNeutral += summary.zoneFractions[.optimal] ?? 0
            totalStress += summary.zoneFractions[.elevatedStress] ?? 0
        }

        let total = max(totalCalm + totalNeutral + totalStress, 0.0001)

        // Create zone summaries
        return [
            ZoneSummary(zone: .calm, percentage: (totalCalm / total) * 100),
            ZoneSummary(zone: .optimal, percentage: (totalNeutral / total) * 100),
            ZoneSummary(zone: .elevatedStress, percentage: (totalStress / total) * 100)
        ]
    }

    // MARK: - Trend Stats

    /// Creates trend stats comparing current period to previous period
    /// - Parameters:
    ///   - currentSessions: Sessions in current period
    ///   - previousSessions: Sessions in previous period
    ///   - metric: Sensor type
    /// - Returns: TrendStats with comparison
    func createTrendStats(
        currentSessions: [MeditationSession],
        previousSessions: [MeditationSession],
        metric: SensorType
    ) -> TrendStats {
        // Calculate average values for current and previous periods
        let currentAvg = calculateAverageValue(sessions: currentSessions, metric: metric)
        let previousAvg = calculateAverageValue(sessions: previousSessions, metric: metric)

        // If no previous data, return tracking started message
        guard let prevAvg = previousAvg, prevAvg > 0 else {
            return TrendStats.trackingStarted
        }

        guard let currAvg = currentAvg, currAvg > 0 else {
            return TrendStats(
                statusText: "No data",
                deltaText: "",
                description: "No sessions in this period yet."
            )
        }

        // Calculate percentage change
        let rawDelta = ((currAvg - prevAvg) / prevAvg) * 100.0

        // Determine if higher is better based on metric
        let preferredDirectionUp: Bool
        switch metric {
        case .hrv:
            preferredDirectionUp = true // Higher HRV is better
        case .heartRate, .respiratoryRate:
            preferredDirectionUp = false // Lower is better (within healthy range)
        default:
            preferredDirectionUp = true
        }

        // Effective delta (positive = improving)
        let effectiveDelta = preferredDirectionUp ? rawDelta : -rawDelta

        // Format delta text
        let deltaText: String
        if abs(rawDelta) < 0.1 {
            deltaText = ""
        } else if metric == .heartRate || metric == .respiratoryRate {
            // For HR and Respiration, show absolute change
            let absChange = abs(currAvg - prevAvg)
            let direction = currAvg < prevAvg ? "-" : "+"
            deltaText = "\(direction)\(Int(absChange)) \(unitForMetric(metric)) vs last period"
        } else {
            // For HRV, show percentage
            deltaText = String(format: "%+.0f%% vs last period", rawDelta)
        }

        // Determine status and description
        let (status, description): (String, String)
        if effectiveDelta > 5 {
            status = "Improving"
            description = improvementDescription(for: metric)
        } else if effectiveDelta < -5 {
            status = "Mixed"
            description = mixedDescription(for: metric)
        } else {
            status = "Stable"
            description = stableDescription(for: metric)
        }

        return TrendStats(
            statusText: status,
            deltaText: deltaText,
            description: description
        )
    }

    // MARK: - Helper Methods

    /// Calculates average value for sessions for a given metric
    private func calculateAverageValue(sessions: [MeditationSession], metric: SensorType) -> Double? {
        guard !sessions.isEmpty else { return nil }

        let allValues: [Double]
        switch metric {
        case .hrv:
            allValues = sessions.flatMap { $0.hrvSamples.map { $0.sdnn } }
        case .heartRate:
            allValues = sessions.flatMap { $0.heartRateSamples.map { $0.value } }
        case .respiratoryRate:
            allValues = sessions.flatMap { $0.respiratoryRateSamples.map { $0.value } }
        default:
            return nil
        }

        guard !allValues.isEmpty else { return nil }
        return allValues.reduce(0.0, +) / Double(allValues.count)
    }

    /// Returns unit string for metric
    private func unitForMetric(_ metric: SensorType) -> String {
        switch metric {
        case .hrv:
            return "ms"
        case .heartRate:
            return "bpm"
        case .respiratoryRate:
            return "/min"
        default:
            return ""
        }
    }

    /// Returns improvement description for metric
    private func improvementDescription(for metric: SensorType) -> String {
        switch metric {
        case .hrv:
            return "Your nervous system is showing stronger recovery."
        case .heartRate:
            return "Your heart is spending more time in a calm range."
        case .respiratoryRate:
            return "Your breathing is slower and more consistent during sessions."
        default:
            return "Your metrics are improving."
        }
    }

    /// Returns mixed/declining description for metric
    private func mixedDescription(for metric: SensorType) -> String {
        switch metric {
        case .hrv:
            return "Recovery was lower this period — consider more gentle days."
        case .heartRate:
            return "Heart rate was elevated more often — stress or busy days may be affecting you."
        case .respiratoryRate:
            return "Breathing was less steady this period — shorter or more distracted sessions."
        default:
            return "Metrics were lower this period."
        }
    }

    /// Returns stable description for metric
    private func stableDescription(for metric: SensorType) -> String {
        switch metric {
        case .hrv:
            return "Your recovery pattern is holding steady."
        case .heartRate:
            return "Your session heart rate stayed in a similar range."
        case .respiratoryRate:
            return "Your breathing patterns remained consistent."
        default:
            return "Your metrics are stable."
        }
    }
}
