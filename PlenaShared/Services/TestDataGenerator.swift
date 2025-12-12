//
//  TestDataGenerator.swift
//  PlenaShared
//
//  Service to generate test meditation session data for development and testing
//

import Foundation

class TestDataGenerator {

    /// Generates a realistic meditation session with optional sensor samples
    static func generateSession(
        daysAgo: Int,
        hour: Int = 9,
        durationMinutes: Double,
        includeSensorData: Bool = true
    ) -> MeditationSession {
        let calendar = Calendar.current
        let now = Date()

        // Calculate start date
        guard let daysBack = calendar.date(byAdding: .day, value: -daysAgo, to: now),
              let startDate = calendar.date(bySettingHour: hour, minute: Int.random(in: 0...59), second: 0, of: daysBack) else {
            return MeditationSession()
        }

        let endDate = startDate.addingTimeInterval(durationMinutes * 60.0)

        var session = MeditationSession(startDate: startDate)
        session.endDate = endDate

        if includeSensorData {
            // Generate realistic sensor samples throughout the session
            let samplesPerMinute = 1.0 // One sample per minute
            let totalSamples = Int(durationMinutes * samplesPerMinute)

            // Generate heart rate samples (typically 50-80 BPM during meditation)
            var heartRateSamples: [HeartRateSample] = []
            let baseHeartRate = Double.random(in: 55...70)

            // Generate HRV samples (typically 20-60ms)
            var hrvSamples: [HRVSample] = []
            let baseHRV = Double.random(in: 25...45)

            // Generate respiratory rate samples (typically 10-18 breaths/min)
            var respiratorySamples: [RespiratoryRateSample] = []
            let baseRespiratoryRate = Double.random(in: 12...16)

            // Generate VO2 Max samples (typically 35-55 mL/kg/min during rest/meditation)
            var vo2MaxSamples: [VO2MaxSample] = []
            let baseVO2Max = Double.random(in: 38...48)

            // Generate temperature samples (typically 36.5-37.2°C, slightly decreases during meditation)
            var temperatureSamples: [TemperatureSample] = []
            let baseTemperature = Double.random(in: 36.6...37.0) // Celsius

            for i in 0..<totalSamples {
                let sampleOffset = Double(i) / samplesPerMinute * 60.0
                let sampleTime = startDate.addingTimeInterval(sampleOffset)

                // Heart rate gradually decreases during meditation
                let progress = Double(i) / Double(totalSamples)
                let heartRate = baseHeartRate - (progress * 5.0) + Double.random(in: -3...3)

                heartRateSamples.append(HeartRateSample(
                    timestamp: sampleTime,
                    value: max(45, min(85, heartRate))
                ))

                // HRV typically increases during meditation
                let hrv = baseHRV + (progress * 10.0) + Double.random(in: -5...5)
                hrvSamples.append(HRVSample(
                    timestamp: sampleTime,
                    sdnn: max(15, min(65, hrv))
                ))

                // Respiratory rate gradually decreases
                let respiratoryRate = baseRespiratoryRate - (progress * 2.0) + Double.random(in: -1...1)
                respiratorySamples.append(RespiratoryRateSample(
                    timestamp: sampleTime,
                    value: max(8, min(20, respiratoryRate))
                ))

                // VO2 Max remains relatively stable or slightly decreases during meditation
                let vo2Max = baseVO2Max - (progress * 2.0) + Double.random(in: -2...2)
                vo2MaxSamples.append(VO2MaxSample(
                    timestamp: sampleTime,
                    value: max(30, min(55, vo2Max))
                ))

                // Temperature slightly decreases as body relaxes during meditation
                let temperature = baseTemperature - (progress * 0.2) + Double.random(in: -0.1...0.1)
                temperatureSamples.append(TemperatureSample(
                    timestamp: sampleTime,
                    value: max(36.0, min(37.5, temperature))
                ))
            }

            session.heartRateSamples = heartRateSamples
            session.hrvSamples = hrvSamples
            session.respiratoryRateSamples = respiratorySamples
            session.vo2MaxSamples = vo2MaxSamples
            session.temperatureSamples = temperatureSamples
        }

        return session
    }

    /// Generates multiple sessions over a date range with realistic patterns
    static func generateSessions(
        daysBack: Int,
        averageSessionsPerWeek: Double = 5.0,
        averageDurationMinutes: Double = 18.0,
        durationVariation: Double = 5.0,
        includeSensorData: Bool = true
    ) -> [MeditationSession] {
        var sessions: [MeditationSession] = []

        // Calculate total weeks
        let weeks = Double(daysBack) / 7.0
        let totalSessions = Int(weeks * averageSessionsPerWeek)

        // Common meditation times (morning and evening are most popular)
        let timePreferences: [(hour: Int, weight: Int)] = [
            (7, 3),   // Early morning
            (9, 5),   // Morning (most popular)
            (12, 2),  // Midday
            (18, 4),  // Evening
            (20, 3),  // Late evening
            (22, 1)   // Night
        ]

        // Generate sessions with some realistic patterns
        for _ in 0..<totalSessions {
            // Distribute sessions across the date range
            let dayOffset = Int.random(in: 0..<daysBack)

            // Weighted random time selection
            let totalWeight = timePreferences.reduce(0) { $0 + $1.weight }
            var randomWeight = Int.random(in: 0..<totalWeight)
            var selectedTime = timePreferences[0].hour

            for timePref in timePreferences {
                randomWeight -= timePref.weight
                if randomWeight <= 0 {
                    selectedTime = timePref.hour
                    break
                }
            }

            // Duration varies around average
            let duration = averageDurationMinutes + Double.random(in: -durationVariation...durationVariation)

            // Occasional longer sessions
            let finalDuration = Double.random(in: 0...100) < 10 ? duration * 1.5 : duration

            let session = generateSession(
                daysAgo: dayOffset,
                hour: selectedTime,
                durationMinutes: max(5, finalDuration), // Minimum 5 minutes
                includeSensorData: includeSensorData
            )

            sessions.append(session)
        }

        // Sort by date (newest first)
        return sessions.sorted { $0.startDate > $1.startDate }
    }

    /// Generates test data with realistic patterns:
    /// - More sessions in recent weeks (building habit)
    /// - Some streak patterns
    /// - Varied durations
    static func generateRealisticTestData(
        includeSensorData: Bool = true
    ) -> [MeditationSession] {
        var allSessions: [MeditationSession] = []
        let calendar = Calendar.current
        let now = Date()

        // Common meditation times (morning and evening are most popular)
        let timePreferences: [(hour: Int, weight: Int)] = [
            (7, 3),   // Early morning
            (9, 5),   // Morning (most popular)
            (12, 2),  // Midday
            (18, 4),  // Evening
            (20, 3),  // Late evening
            (22, 1)   // Night
        ]

        let totalWeight = timePreferences.reduce(0) { $0 + $1.weight }

        // Generate sessions for the past 30 days with increasing frequency
        for dayOffset in (0..<30).reversed() {
            guard calendar.date(byAdding: .day, value: -dayOffset, to: now) != nil else { continue }

            // More frequent in recent days (building habit)
            let sessionsToday: Int
            if dayOffset < 7 {
                // Last 7 days: 60% chance of session each day
                sessionsToday = Double.random(in: 0...100) < 60 ? 1 : 0
            } else if dayOffset < 14 {
                // Days 7-14: 40% chance
                sessionsToday = Double.random(in: 0...100) < 40 ? 1 : 0
            } else {
                // Days 14-30: 30% chance
                sessionsToday = Double.random(in: 0...100) < 30 ? 1 : 0
            }

            // Create session(s) for this day
            for _ in 0..<sessionsToday {
                // Weighted random time selection
                var randomWeight = Int.random(in: 0..<totalWeight)
                var selectedTime = timePreferences[0].hour

                for timePref in timePreferences {
                    randomWeight -= timePref.weight
                    if randomWeight <= 0 {
                        selectedTime = timePref.hour
                        break
                    }
                }

                // Duration: longer in recent days
                let baseDuration: Double
                if dayOffset < 7 {
                    baseDuration = Double.random(in: 18...25)
                } else if dayOffset < 14 {
                    baseDuration = Double.random(in: 15...22)
                } else {
                    baseDuration = Double.random(in: 10...18)
                }

                let session = generateSession(
                    daysAgo: dayOffset,
                    hour: selectedTime,
                    durationMinutes: baseDuration,
                    includeSensorData: includeSensorData
                )

                allSessions.append(session)
            }
        }

        return allSessions.sorted { $0.startDate > $1.startDate }
    }

    /// Adds test data to storage service
    static func populateTestData(
        storageService: SessionStorageServiceProtocol,
        includeSensorData: Bool = true
    ) throws {
        let testSessions = generateRealisticTestData(includeSensorData: includeSensorData)

        for session in testSessions {
            try storageService.saveSession(session)
        }
    }

    /// Clears all existing sessions (use with caution!)
    static func clearAllSessions(
        storageService: SessionStorageServiceProtocol
    ) throws {
        let allSessions = try storageService.loadAllSessions()
        for session in allSessions {
            try storageService.deleteSession(session)
        }
    }

    /// Generates test data specifically designed to show HRV insights
    /// Ensures:
    /// - At least 3 sessions in current week with HRV data
    /// - At least 3 sessions in previous week with HRV data
    /// - At least 3 sessions in recent days for recent sessions insight
    /// - Each session has at least 3 HRV samples (sessions are 15+ minutes)
    static func generateHRVInsightsTestData() -> [MeditationSession] {
        var sessions: [MeditationSession] = []
        let calendar = Calendar.current
        let now = Date()

        // Get current week start
        guard let currentWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) else {
            return []
        }

        // Get previous week dates
        guard let previousWeekEnd = calendar.date(byAdding: .day, value: -1, to: currentWeekStart),
              calendar.date(byAdding: .day, value: -7, to: previousWeekEnd) != nil else {
            return []
        }

        // Generate sessions for previous week (at least 4 to ensure 3+ with HRV)
        for dayOffset in 7..<14 {
            guard calendar.date(byAdding: .day, value: -dayOffset, to: now) != nil else { continue }

            // Create 1-2 sessions per day in previous week
            let sessionsToday = dayOffset == 7 || dayOffset == 10 ? 2 : 1 // More sessions on some days

            for sessionIndex in 0..<sessionsToday {
                let hour = 9 + (sessionIndex * 6) // 9am or 3pm
                let duration = Double.random(in: 15...25) // 15-25 minutes ensures 15+ HRV samples

                let session = generateSession(
                    daysAgo: dayOffset,
                    hour: hour,
                    durationMinutes: duration,
                    includeSensorData: true
                )
                sessions.append(session)
            }
        }

        // Generate sessions for current week (at least 4 to ensure 3+ with HRV)
        // Make current week show improvement (higher HRV)
        for dayOffset in 0..<7 {
            guard calendar.date(byAdding: .day, value: -dayOffset, to: now) != nil else { continue }

            // More sessions in recent days (last 3 days)
            let sessionsToday = dayOffset < 3 ? 2 : 1

            for sessionIndex in 0..<sessionsToday {
                let hour = 9 + (sessionIndex * 6) // 9am or 3pm
                let duration = Double.random(in: 15...25) // 15-25 minutes ensures 15+ HRV samples

                var session = generateSession(
                    daysAgo: dayOffset,
                    hour: hour,
                    durationMinutes: duration,
                    includeSensorData: true
                )

                // Boost HRV values for current week to show improvement trend
                // Increase base HRV by 12% to ensure positive trend (meets 5% threshold)
                session.hrvSamples = session.hrvSamples.map { sample in
                    HRVSample(
                        id: sample.id,
                        timestamp: sample.timestamp,
                        sdnn: sample.sdnn * 1.12 // 12% increase to show improvement
                    )
                }

                sessions.append(session)
            }
        }

        // Sort by date (newest first)
        return sessions.sorted { $0.startDate > $1.startDate }
    }
}

