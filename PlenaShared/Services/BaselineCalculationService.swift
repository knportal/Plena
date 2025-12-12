//
//  BaselineCalculationService.swift
//  PlenaShared
//
//  Service for calculating user baselines for personalized zone classification
//

import Foundation

/// Protocol for baseline calculation (for testability)
protocol BaselineCalculationServiceProtocol {
    /// Calculates 30-day rolling median HRV baseline
    func calculateHRVBaseline(from sessions: [MeditationSession]) -> Double?

    /// Calculates resting heart rate from recent sessions
    func calculateRestingHeartRate(from sessions: [MeditationSession]) -> Double?
}

/// Service for calculating user baselines from historical session data
struct BaselineCalculationService: BaselineCalculationServiceProtocol {

    // MARK: - HRV Baseline Calculation

    /// Calculates 30-day rolling median HRV baseline
    /// - Parameter sessions: Array of meditation sessions
    /// - Returns: Median HRV (SDNN) in milliseconds, or nil if insufficient data
    func calculateHRVBaseline(from sessions: [MeditationSession]) -> Double? {
        let calendar = Calendar.current
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date()) ?? Date()

        // Filter to last 30 days
        let recentSessions = sessions.filter { session in
            session.startDate >= thirtyDaysAgo
        }

        // Extract all HRV values from recent sessions
        let hrvValues = recentSessions.flatMap { session in
            session.hrvSamples.map { $0.sdnn }
        }

        guard !hrvValues.isEmpty else { return nil }

        // Calculate median
        let sorted = hrvValues.sorted()
        let count = sorted.count

        if count % 2 == 0 {
            // Even number of values - average the two middle values
            let mid1 = sorted[count / 2 - 1]
            let mid2 = sorted[count / 2]
            return (mid1 + mid2) / 2.0
        } else {
            // Odd number of values - return middle value
            return sorted[count / 2]
        }
    }

    // MARK: - Resting Heart Rate Calculation

    /// Calculates resting heart rate from recent sessions
    /// Uses the lowest 10th percentile of heart rate values as resting HR estimate
    /// - Parameter sessions: Array of meditation sessions
    /// - Returns: Estimated resting heart rate in BPM, or nil if insufficient data
    func calculateRestingHeartRate(from sessions: [MeditationSession]) -> Double? {
        let calendar = Calendar.current
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date()) ?? Date()

        // Filter to last 30 days
        let recentSessions = sessions.filter { session in
            session.startDate >= thirtyDaysAgo
        }

        // Extract all heart rate values from recent sessions
        let heartRateValues = recentSessions.flatMap { session in
            session.heartRateSamples.map { $0.value }
        }

        guard !heartRateValues.isEmpty else { return nil }

        // Calculate 10th percentile (lowest values) as resting HR estimate
        let sorted = heartRateValues.sorted()
        let percentileIndex = max(0, Int(Double(sorted.count) * 0.1))
        let restingHR = sorted[percentileIndex]

        // Also consider the minimum value as a sanity check
        let minHR = sorted.first ?? restingHR

        // Return the lower of the two (more conservative estimate)
        return min(restingHR, minHR)
    }
}
