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
    ///   - metric: Sensor type to analyze (HRV, Heart Rate, Respiration, or VO2 Max)
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
        // Handle VO2 Max separately - use latest value per session (doesn't change during session)
        if metric == .vo2Max {
            // Check if we have any VO2 Max samples
            guard !session.vo2MaxSamples.isEmpty else {
                print("⚠️ VO2 Max createSessionMetricSummary: Session \(session.id.uuidString.prefix(8)) has no VO2 Max samples")
                return nil
            }

            // Get VO2 Max value - since it doesn't change during a session, we can use any sample
            // For consistency, use the average of all samples in the session
            let vo2MaxValue = session.vo2MaxSamples.map { $0.value }.reduce(0.0, +) / Double(session.vo2MaxSamples.count)

            print("✅ VO2 Max createSessionMetricSummary: Session \(session.id.uuidString.prefix(8)) - \(session.vo2MaxSamples.count) samples, avg value: \(String(format: "%.1f", vo2MaxValue))")

            let zone = zoneClassifier.classifyVO2Max(vo2MaxValue)

            print("   Zone classification: \(zone) for VO2 Max \(String(format: "%.1f", vo2MaxValue))")

            // For VO2 Max, assign 100% to the zone of the latest value
            let zoneFractions: [StressZone: Double] = [
                .calm: zone == .calm ? 1.0 : 0.0,
                .optimal: zone == .optimal ? 1.0 : 0.0,
                .elevatedStress: zone == .elevatedStress ? 1.0 : 0.0
            ]

            print("   Zone fractions: calm=\(zoneFractions[.calm] ?? 0), optimal=\(zoneFractions[.optimal] ?? 0), stress=\(zoneFractions[.elevatedStress] ?? 0)")

            return SessionMetricSummary(
                sessionID: session.id,
                date: session.startDate,
                metric: metric,
                avgValue: vo2MaxValue,
                zoneFractions: zoneFractions,
                dominantZone: zone
            )
        }

        // Get samples for the metric (HRV, Heart Rate, Respiratory Rate)
        let samples: [(timestamp: Date, value: Double)]
        switch metric {
        case .hrv:
            samples = session.hrvSamples.map { ($0.timestamp, $0.sdnn) }
        case .heartRate:
            samples = session.heartRateSamples.map { ($0.timestamp, $0.value) }
        case .respiratoryRate:
            samples = session.respiratoryRateSamples.map { ($0.timestamp, $0.value) }
        default:
            return nil // Temperature not supported
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

        guard !sessionSummaries.isEmpty else {
            if metric == .vo2Max {
                let sessionsWithVO2Max = sessions.filter { !$0.vo2MaxSamples.isEmpty }
                print("⚠️ VO2 Max createPeriodScore: \(label) - \(sessions.count) sessions, \(sessionsWithVO2Max.count) with VO2 Max samples, 0 session summaries created")
            }
            return nil
        }

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

        // For VO2 Max, calculate score based on actual values within zones
        // For other metrics, use calm fraction
        let calmFraction: Double
        let calmScore: Double
        let zone: StressZone

        if metric == .vo2Max {
            // VO2 Max: Calculate score based on actual values, not just zone membership
            // Higher VO2 Max = better, so we want to show the actual value range
            // Score should reflect: < 35 = 0-33, 35-55 = 34-84, > 55 = 85-100
            var totalScore: Double = 0
            var count: Double = 0

            for summary in sessionSummaries {
                let vo2Value = summary.avgValue
                let sessionScore: Double

                if vo2Value < 35 {
                    // Elevated stress: 0-33% (poor fitness)
                    sessionScore = (vo2Value / 35.0) * 33.0
                } else if vo2Value <= 55 {
                    // Optimal: 34-84% (map 35-55 to 34-84)
                    let normalized = (vo2Value - 35.0) / (55.0 - 35.0) // 0.0 to 1.0
                    sessionScore = 34.0 + (normalized * 50.0) // 34 to 84
                } else {
                    // Calm: 85-100% (excellent fitness, map 55+ to 85-100)
                    let normalized = min((vo2Value - 55.0) / 20.0, 1.0) // Cap at 75 (55+20)
                    sessionScore = 85.0 + (normalized * 15.0) // 85 to 100
                }

                totalScore += sessionScore
                count += 1
            }

            calmScore = count > 0 ? totalScore / count : 0.0
            calmFraction = calmScore / 100.0 // For compatibility

            // Determine zone based on average VO2 Max value
            let avgVO2Max = sessionSummaries.map { $0.avgValue }.reduce(0.0, +) / Double(sessionSummaries.count)
            zone = zoneClassifier.classifyVO2Max(avgVO2Max)
        } else {
            // HRV/Heart Rate: only calm is good
            calmFraction = totalCalm / total
            calmScore = calmFraction * 100.0

            // Determine dominant zone for bar color
            if calmFraction >= 0.6 {
                zone = .calm
            } else if calmFraction >= 0.3 {
                zone = .optimal
            } else {
                zone = .elevatedStress
            }
        }

        if metric == .vo2Max {
            let goodFraction = (totalCalm + totalNeutral) / total
            print("✅ VO2 Max createPeriodScore: \(label) - \(sessionSummaries.count) summaries, goodFraction: \(String(format: "%.2f", goodFraction)) (calm=\(String(format: "%.2f", totalCalm)), optimal=\(String(format: "%.2f", totalNeutral)), stress=\(String(format: "%.2f", totalStress))), score: \(String(format: "%.1f", calmScore)), zone: \(zone)")
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
        case .hrv, .vo2Max:
            preferredDirectionUp = true // Higher HRV and VO2 Max are better
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
        } else if metric == .vo2Max {
            // For VO2 Max, show absolute change with one decimal
            let absChange = abs(currAvg - prevAvg)
            let direction = currAvg > prevAvg ? "+" : "-"
            deltaText = "\(direction)\(String(format: "%.1f", absChange)) \(unitForMetric(metric)) vs last period"
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
    /// For VO2 Max, uses latest value per session (since it doesn't change during session)
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
        case .vo2Max:
            // For VO2 Max, use latest value per session
            allValues = sessions.compactMap { session in
                session.vo2MaxSamples.sorted(by: { $0.timestamp > $1.timestamp }).first?.value
            }
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
        case .vo2Max:
            return "mL/kg/min"
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
        case .vo2Max:
            return "Your cardiovascular fitness is improving."
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
        case .vo2Max:
            return "Cardiovascular fitness was lower this period — consider adding more aerobic activity."
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
        case .vo2Max:
            return "Your cardiovascular fitness is maintaining its current level."
        default:
            return "Your metrics are stable."
        }
    }
}


