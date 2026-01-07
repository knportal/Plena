//
//  SleepStatusDetailViewModel.swift
//  PlenaShared
//
//  ViewModel for Sleep Status detail view
//

import Foundation

@MainActor
class SleepStatusDetailViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Calculated values
    @Published var currentSleepHours: Double?
    @Published var averageSleepHours: Double?
    @Published var status: ReadinessStatus?
    @Published var trendData: [(date: Date, value: Double)] = [] // Sleep hours per day

    private let storageService: SessionStorageServiceProtocol
    private let healthKitService: HealthKitServiceProtocol?
    private let calendar = Calendar.current

    init(
        storageService: SessionStorageServiceProtocol = CoreDataStorageService(),
        healthKitService: HealthKitServiceProtocol? = nil
    ) {
        self.storageService = storageService
        self.healthKitService = healthKitService
    }

    func loadData(for date: Date) async {
        isLoading = true
        errorMessage = nil

        guard let healthKitService = healthKitService else {
            errorMessage = "HealthKit service not available"
            isLoading = false
            return
        }

        do {
            // Get sleep for the selected date
            if let sleep = try? await healthKitService.fetchSleepForDate(date) {
                currentSleepHours = sleep.durationInHours
            }

            // Get sleep data for last 7 days for trend and average
            guard let weekStart = calendar.date(byAdding: .day, value: -7, to: date) else {
                throw DetailViewError.invalidDate
            }

            let sleepPeriods = try await healthKitService.fetchSleepAnalysis(startDate: weekStart, endDate: date)

            guard !sleepPeriods.isEmpty else {
                throw DetailViewError.insufficientData
            }

            // Calculate average sleep hours
            let totalHours = sleepPeriods.reduce(0.0) { $0 + $1.durationInHours }
            averageSleepHours = totalHours / Double(sleepPeriods.count)

            // Determine status based on current sleep hours
            if let hours = currentSleepHours {
                if hours >= 7.0 && hours <= 9.0 {
                    status = .optimal
                } else if (hours >= 6.0 && hours < 7.0) || (hours > 9.0 && hours <= 10.0) {
                    status = .higher
                } else if (hours >= 5.0 && hours < 6.0) || (hours > 10.0 && hours <= 11.0) {
                    status = .moderate
                } else {
                    status = .lower
                }
            }

            // Build 7-day trend data
            var dailySleep: [(date: Date, value: Double)] = []

            // Group sleep periods by day
            var sleepByDay: [Date: [SleepAnalysis]] = [:]
            for sleep in sleepPeriods {
                let dayStart = calendar.startOfDay(for: sleep.startDate)
                sleepByDay[dayStart, default: []].append(sleep)
            }

            // Calculate total sleep hours for each day
            for dayOffset in stride(from: 6, through: 0, by: -1) {
                guard let dayDate = calendar.date(byAdding: .day, value: -dayOffset, to: date) else { continue }
                let dayStart = calendar.startOfDay(for: dayDate)

                guard let daySleeps = sleepByDay[dayStart], !daySleeps.isEmpty else { continue }

                // Sum all sleep periods for the day
                let totalHours = daySleeps.reduce(0.0) { $0 + $1.durationInHours }
                dailySleep.append((date: dayStart, value: totalHours))
            }

            trendData = dailySleep

        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
