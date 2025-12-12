//
//  ReadinessScoreService.swift
//  PlenaShared
//
//  Service for calculating daily readiness scores from meditation session data
//

import Foundation

protocol ReadinessScoreServiceProtocol {
    func calculateReadinessScore(
        for date: Date,
        sessions: [MeditationSession],
        healthKitService: HealthKitServiceProtocol?
    ) async -> ReadinessScore
}

class ReadinessScoreService: ReadinessScoreServiceProtocol {
    private let calendar = Calendar.current

    // MARK: - Main Calculation

    func calculateReadinessScore(
        for date: Date,
        sessions: [MeditationSession],
        healthKitService: HealthKitServiceProtocol?
    ) async -> ReadinessScore {
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? date

        // Filter sessions for the target date
        let daySessions = sessions.filter { session in
            session.startDate >= dayStart && session.startDate < dayEnd
        }

        // Get recent sessions for baseline calculations
        let recentSessions = getRecentSessions(upTo: date, from: sessions)

        // Calculate each contributor
        var contributors: [ReadinessContributor] = []

        // Resting Heart Rate
        if let restingHR = calculateRestingHeartRate(from: recentSessions) {
            contributors.append(restingHR)
        }

        // HRV Balance
        if let hrvBalance = calculateHRVBalance(currentSessions: daySessions, recentSessions: recentSessions) {
            contributors.append(hrvBalance)
        }

        // Body Temperature
        if let temperature = await calculateBodyTemperature(healthKitService: healthKitService, recentSessions: recentSessions) {
            contributors.append(temperature)
        }

        // Recovery Index
        if let recovery = calculateRecoveryIndex(for: date, from: recentSessions) {
            contributors.append(recovery)
        }

        // Sleep metrics (from HealthKit)
        if let sleepStatus = await calculateSleepStatus(for: date, healthKitService: healthKitService) {
            contributors.append(sleepStatus)
        } else {
            contributors.append(calculateSleepStatusPlaceholder())
        }

        if let sleepBalance = await calculateSleepBalance(for: date, healthKitService: healthKitService) {
            contributors.append(sleepBalance)
        } else {
            contributors.append(calculateSleepBalancePlaceholder())
        }

        if let sleepRegularity = await calculateSleepRegularity(for: date, healthKitService: healthKitService) {
            contributors.append(sleepRegularity)
        } else {
            contributors.append(calculateSleepRegularityPlaceholder())
        }

        // Calculate overall score from contributors
        let overallScore = calculateOverallScore(from: contributors)

        return ReadinessScore(
            date: date,
            overallScore: overallScore,
            contributors: contributors
        )
    }

    // MARK: - Helper Methods

    private func getRecentSessions(upTo date: Date, from allSessions: [MeditationSession]) -> [MeditationSession] {
        let cutoffDate = calendar.date(byAdding: .day, value: -7, to: date) ?? date
        return allSessions.filter { $0.startDate >= cutoffDate && $0.startDate <= date }
            .sorted { $0.startDate > $1.startDate }
    }

    // MARK: - Contributor Calculations

    /// Calculate resting heart rate from recent sessions
    private func calculateRestingHeartRate(from sessions: [MeditationSession]) -> ReadinessContributor? {
        guard !sessions.isEmpty else { return nil }

        // Get last 3 sessions
        let recent = Array(sessions.prefix(3))

        // Extract heart rate from first 2 minutes of each session (resting state)
        var restingRates: [Double] = []

        for session in recent {
            let twoMinutesLater = session.startDate.addingTimeInterval(120)
            let earlySamples = session.heartRateSamples.filter { sample in
                sample.timestamp >= session.startDate && sample.timestamp <= twoMinutesLater
            }

            if !earlySamples.isEmpty {
                let avg = earlySamples.reduce(0.0) { $0 + $1.value } / Double(earlySamples.count)
                restingRates.append(avg)
            }
        }

        guard !restingRates.isEmpty else { return nil }

        let avgRestingHR = restingRates.reduce(0.0, +) / Double(restingRates.count)

        // Calculate baseline from all recent sessions
        let allRecentHRs = sessions.flatMap { $0.heartRateSamples }.map { $0.value }
        guard !allRecentHRs.isEmpty else { return nil }

        let baseline = allRecentHRs.reduce(0.0, +) / Double(allRecentHRs.count)

        // Determine status based on deviation from baseline
        let deviation = abs(avgRestingHR - baseline)
        let status: ReadinessStatus
        let score: Double

        if deviation <= 5 {
            status = .optimal
            score = 1.0
        } else if deviation <= 10 {
            status = .good
            score = 0.75
        } else if deviation <= 15 {
            status = .payAttention
            score = 0.5
        } else {
            status = .poor
            score = 0.25
        }

        return ReadinessContributor(
            name: "Resting heart rate",
            value: String(format: "%.0f bpm", avgRestingHR),
            status: status,
            score: score
        )
    }

    /// Calculate HRV balance (current vs baseline)
    private func calculateHRVBalance(
        currentSessions: [MeditationSession],
        recentSessions: [MeditationSession]
    ) -> ReadinessContributor? {
        guard !recentSessions.isEmpty else { return nil }

        // Calculate baseline HRV from recent sessions
        let allHRVSamples = recentSessions.flatMap { $0.hrvSamples }
        guard !allHRVSamples.isEmpty else { return nil }

        let baseline = allHRVSamples.reduce(0.0) { $0 + $1.sdnn } / Double(allHRVSamples.count)

        // Calculate current HRV (from today's sessions or most recent)
        let currentSamples = currentSessions.isEmpty
            ? Array(recentSessions.prefix(1).flatMap { $0.hrvSamples })
            : currentSessions.flatMap { $0.hrvSamples }

        guard !currentSamples.isEmpty else { return nil }

        let current = currentSamples.reduce(0.0) { $0 + $1.sdnn } / Double(currentSamples.count)

        // Determine status based on comparison to baseline
        let percentChange = ((current - baseline) / baseline) * 100
        let status: ReadinessStatus
        let score: Double

        if percentChange >= 5 {
            status = .optimal
            score = 1.0
        } else if percentChange >= -5 {
            status = .good
            score = 0.75
        } else if percentChange >= -15 {
            status = .payAttention
            score = 0.5
        } else {
            status = .poor
            score = 0.25
        }

        return ReadinessContributor(
            name: "HRV balance",
            value: status.rawValue,
            status: status,
            score: score
        )
    }

    /// Calculate body temperature status
    private func calculateBodyTemperature(
        healthKitService: HealthKitServiceProtocol?,
        recentSessions: [MeditationSession]
    ) async -> ReadinessContributor? {
        // Try to get latest temperature from HealthKit first
        var latestTemp: Double?

        if let healthKitService = healthKitService {
            latestTemp = try? await healthKitService.fetchLatestTemperature()
        }

        // Fallback to session data
        if latestTemp == nil {
            let tempSamples = recentSessions.flatMap { $0.temperatureSamples }
            if !tempSamples.isEmpty {
                latestTemp = tempSamples.max(by: { $0.timestamp < $1.timestamp })?.value
            }
        }

        guard let temperature = latestTemp else { return nil }

        // Calculate baseline from recent sessions
        let allTemps = recentSessions.flatMap { $0.temperatureSamples }.map { $0.value }
        guard !allTemps.isEmpty else { return nil }

        let baseline = allTemps.reduce(0.0, +) / Double(allTemps.count)

        // Normal body temperature range: 97.0-99.0°F (36.1-37.2°C)
        // We'll work in Celsius for calculations
        let deviation = abs(temperature - baseline)
        let status: ReadinessStatus
        let score: Double

        if deviation <= 0.3 { // ~0.5°F
            status = .optimal
            score = 1.0
        } else if deviation <= 0.6 { // ~1.0°F
            status = .good
            score = 0.75
        } else if deviation <= 1.0 { // ~1.8°F
            status = .payAttention
            score = 0.5
        } else {
            status = .poor
            score = 0.25
        }

        return ReadinessContributor(
            name: "Body temperature",
            value: status.rawValue,
            status: status,
            score: score
        )
    }

    /// Calculate recovery index based on session frequency and patterns
    private func calculateRecoveryIndex(for date: Date, from sessions: [MeditationSession]) -> ReadinessContributor? {
        guard !sessions.isEmpty else { return nil }

        // Analyze session frequency over last 7 days
        let calendar = Calendar.current
        var sessionsPerDay: [Int] = []

        for i in 0..<7 {
            guard let checkDate = calendar.date(byAdding: .day, value: -i, to: date) else { continue }
            let dayStart = calendar.startOfDay(for: checkDate)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? checkDate

            let dayCount = sessions.filter { session in
                session.startDate >= dayStart && session.startDate < dayEnd
            }.count

            sessionsPerDay.append(dayCount)
        }

        let avgSessionsPerDay = Double(sessionsPerDay.reduce(0, +)) / Double(sessionsPerDay.count)

        // Optimal: 1-2 sessions per day
        // Good: 0.5-1 or 2-3 sessions per day
        // Pay attention: <0.5 or >3 sessions per day
        let status: ReadinessStatus
        let score: Double

        if avgSessionsPerDay >= 1.0 && avgSessionsPerDay <= 2.0 {
            status = .optimal
            score = 1.0
        } else if (avgSessionsPerDay >= 0.5 && avgSessionsPerDay < 1.0) || (avgSessionsPerDay > 2.0 && avgSessionsPerDay <= 3.0) {
            status = .good
            score = 0.75
        } else {
            status = .payAttention
            score = 0.5
        }

        return ReadinessContributor(
            name: "Recovery index",
            value: status.rawValue,
            status: status,
            score: score
        )
    }

    /// Calculate sleep status from HealthKit sleep data
    private func calculateSleepStatus(
        for date: Date,
        healthKitService: HealthKitServiceProtocol?
    ) async -> ReadinessContributor? {
        guard let healthKitService = healthKitService else { return nil }

        guard let sleep = try? await healthKitService.fetchSleepForDate(date) else {
            return nil
        }

        let hours = sleep.durationInHours

        // Optimal: 7-9 hours
        // Good: 6-7 or 9-10 hours
        // Pay attention: 5-6 or 10-11 hours
        // Poor: <5 or >11 hours
        let status: ReadinessStatus
        let score: Double

        if hours >= 7.0 && hours <= 9.0 {
            status = .optimal
            score = 1.0
        } else if (hours >= 6.0 && hours < 7.0) || (hours > 9.0 && hours <= 10.0) {
            status = .good
            score = 0.75
        } else if (hours >= 5.0 && hours < 6.0) || (hours > 10.0 && hours <= 11.0) {
            status = .payAttention
            score = 0.5
        } else {
            status = .poor
            score = 0.25
        }

        return ReadinessContributor(
            name: "Sleep",
            value: String(format: "%.1f hours", hours),
            status: status,
            score: score
        )
    }

    /// Calculate sleep balance (consistency of sleep duration over recent days)
    private func calculateSleepBalance(
        for date: Date,
        healthKitService: HealthKitServiceProtocol?
    ) async -> ReadinessContributor? {
        guard let healthKitService = healthKitService else { return nil }

        // Get sleep data for last 7 days
        guard let weekStart = calendar.date(byAdding: .day, value: -7, to: date) else {
            return nil
        }

        var sleepDurations: [Double] = []
        var currentDate = weekStart

        while currentDate < date {
            if let sleep = try? await healthKitService.fetchSleepForDate(currentDate) {
                sleepDurations.append(sleep.durationInHours)
            }
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                break
            }
            currentDate = nextDate
        }

        guard sleepDurations.count >= 3 else { return nil } // Need at least 3 days of data

        // Calculate coefficient of variation for sleep duration
        let mean = sleepDurations.reduce(0.0, +) / Double(sleepDurations.count)
        guard mean > 0 else { return nil }

        let variance = sleepDurations.map { pow($0 - mean, 2) }.reduce(0.0, +) / Double(sleepDurations.count)
        let stdDev = sqrt(variance)
        let coefficientOfVariation = stdDev / mean

        // Lower CV = more consistent = better
        // For sleep, CV < 0.15 is very consistent, < 0.25 is good, < 0.35 is acceptable
        let status: ReadinessStatus
        let score: Double

        if coefficientOfVariation <= 0.15 {
            status = .optimal
            score = 1.0
        } else if coefficientOfVariation <= 0.25 {
            status = .good
            score = 0.75
        } else if coefficientOfVariation <= 0.35 {
            status = .payAttention
            score = 0.5
        } else {
            status = .poor
            score = 0.25
        }

        return ReadinessContributor(
            name: "Sleep balance",
            value: status.rawValue,
            status: status,
            score: score
        )
    }

    /// Calculate sleep regularity (consistency of sleep schedule/timing)
    private func calculateSleepRegularity(
        for date: Date,
        healthKitService: HealthKitServiceProtocol?
    ) async -> ReadinessContributor? {
        guard let healthKitService = healthKitService else { return nil }

        // Get sleep data for last 7 days to analyze bedtime consistency
        guard let weekStart = calendar.date(byAdding: .day, value: -7, to: date) else {
            return nil
        }

        let sleepPeriods = try? await healthKitService.fetchSleepAnalysis(startDate: weekStart, endDate: date)
        guard let periods = sleepPeriods, periods.count >= 3 else { return nil }

        // Extract bedtimes (start times) for each day
        // Group periods by day and take the earliest bedtime for each day
        var bedtimesByDay: [Date: Date] = [:] // day start -> earliest bedtime

        for period in periods {
            let dayStart = calendar.startOfDay(for: period.startDate)

            // Keep the earliest sleep start time for each day
            if let existingBedtime = bedtimesByDay[dayStart] {
                if period.startDate < existingBedtime {
                    bedtimesByDay[dayStart] = period.startDate
                }
            } else {
                bedtimesByDay[dayStart] = period.startDate
            }
        }

        let bedtimes = Array(bedtimesByDay.values).sorted()

        guard bedtimes.count >= 3 else { return nil }

        // Calculate standard deviation of bedtimes (in hours)
        let hourComponents = bedtimes.map { date in
            let hour = Double(calendar.component(.hour, from: date))
            let minute = Double(calendar.component(.minute, from: date))
            return hour + minute / 60.0
        }
        let sum = hourComponents.reduce(0.0, +)
        let meanHour = sum / Double(hourComponents.count)
        let squaredDifferences = hourComponents.map { pow($0 - meanHour, 2) }
        let sumSquaredDiffs = squaredDifferences.reduce(0.0, +)
        let variance = sumSquaredDiffs / Double(hourComponents.count)
        let stdDev = sqrt(variance)

        // Lower std dev = more regular = better
        // < 30 minutes is optimal, < 1 hour is good, < 2 hours is acceptable
        let status: ReadinessStatus
        let score: Double

        if stdDev <= 0.5 { // 30 minutes
            status = .optimal
            score = 1.0
        } else if stdDev <= 1.0 { // 1 hour
            status = .good
            score = 0.75
        } else if stdDev <= 2.0 { // 2 hours
            status = .payAttention
            score = 0.5
        } else {
            status = .poor
            score = 0.25
        }

        return ReadinessContributor(
            name: "Sleep regularity",
            value: status.rawValue,
            status: status,
            score: score
        )
    }

    // Placeholder methods for when sleep data is unavailable
    private func calculateSleepStatusPlaceholder() -> ReadinessContributor {
        return ReadinessContributor(
            name: "Sleep",
            value: "No data",
            status: .noData,
            score: 0.0,
            progress: 0.0
        )
    }

    private func calculateSleepBalancePlaceholder() -> ReadinessContributor {
        return ReadinessContributor(
            name: "Sleep balance",
            value: "No data",
            status: .noData,
            score: 0.0,
            progress: 0.0
        )
    }

    private func calculateSleepRegularityPlaceholder() -> ReadinessContributor {
        return ReadinessContributor(
            name: "Sleep regularity",
            value: "No data",
            status: .noData,
            score: 0.0,
            progress: 0.0
        )
    }

    /// Calculate overall score from contributors
    private func calculateOverallScore(from contributors: [ReadinessContributor]) -> Double {
        // Filter out contributors with no data
        let contributorsWithData = contributors.filter { $0.status != .noData }

        guard !contributorsWithData.isEmpty else { return 0 }

        // Weighted average of all contributors with data
        let totalScore = contributorsWithData.reduce(0.0) { $0 + $1.score }
        let averageScore = totalScore / Double(contributorsWithData.count)

        // Convert to 0-100 scale
        return averageScore * 100
    }
}

