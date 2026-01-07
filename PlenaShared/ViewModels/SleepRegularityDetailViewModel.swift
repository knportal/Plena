//
//  SleepRegularityDetailViewModel.swift
//  PlenaShared
//
//  ViewModel for Sleep Regularity detail view
//

import Foundation

@MainActor
class SleepRegularityDetailViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Calculated values
    @Published var standardDeviation: Double? // In hours
    @Published var averageBedtime: Date?
    @Published var status: ReadinessStatus?
    @Published var trendData: [(date: Date, value: Double)] = [] // Bedtime hours per day

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
            // Get sleep data for last 7 days to analyze bedtime consistency
            guard let weekStart = calendar.date(byAdding: .day, value: -7, to: date) else {
                throw DetailViewError.invalidDate
            }

            let sleepPeriods = try await healthKitService.fetchSleepAnalysis(startDate: weekStart, endDate: date)
            guard sleepPeriods.count >= 3 else {
                throw DetailViewError.insufficientData
            }

            // Extract bedtimes (start times) for each day
            // Group periods by day and take the earliest bedtime for each day
            var bedtimesByDay: [Date: Date] = [:] // day start -> earliest bedtime

            for period in sleepPeriods {
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
            guard bedtimes.count >= 3 else {
                throw DetailViewError.insufficientData
            }

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

            standardDeviation = stdDev

            // Calculate average bedtime (use mean hour to create a representative date)
            if let firstBedtime = bedtimes.first {
                let dayStart = calendar.startOfDay(for: firstBedtime)
                if let avgBedtime = calendar.date(bySettingHour: Int(meanHour), minute: Int((meanHour - Double(Int(meanHour))) * 60), second: 0, of: dayStart) {
                    averageBedtime = avgBedtime
                }
            }

            // Determine status based on standard deviation
            if stdDev <= 0.5 { // 30 minutes
                status = .optimal
            } else if stdDev <= 1.0 { // 1 hour
                status = .higher
            } else if stdDev <= 2.0 { // 2 hours
                status = .moderate
            } else {
                status = .lower
            }

            // Build trend data (bedtime hours for each day)
            var bedtimeTrend: [(date: Date, value: Double)] = []
            for (dayStart, bedtime) in bedtimesByDay.sorted(by: { $0.key < $1.key }) {
                let hour = Double(calendar.component(.hour, from: bedtime))
                let minute = Double(calendar.component(.minute, from: bedtime))
                let bedtimeHour = hour + minute / 60.0
                bedtimeTrend.append((date: dayStart, value: bedtimeHour))
            }

            trendData = bedtimeTrend

        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func formatBedtime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    func formatBedtimeHour(_ hour: Double) -> String {
        let hourInt = Int(hour)
        let minuteInt = Int((hour - Double(hourInt)) * 60)
        let formatter = DateFormatter()
        formatter.timeStyle = .short

        let calendar = Calendar.current
        if let date = calendar.date(bySettingHour: hourInt, minute: minuteInt, second: 0, of: Date()) {
            return formatter.string(from: date)
        }
        return String(format: "%d:%02d", hourInt, minuteInt)
    }
}
