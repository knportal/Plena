//
//  SleepBalanceDetailViewModel.swift
//  PlenaShared
//
//  ViewModel for Sleep Balance detail view
//

import Foundation

@MainActor
class SleepBalanceDetailViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Calculated values
    @Published var coefficientOfVariation: Double?
    @Published var averageSleepHours: Double?
    @Published var standardDeviation: Double?
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
            // Get sleep data for last 7 days
            guard let weekStart = calendar.date(byAdding: .day, value: -7, to: date) else {
                throw DetailViewError.invalidDate
            }

            var sleepDurations: [Double] = []
            var currentDate = weekStart
            var dailySleep: [(date: Date, value: Double)] = []

            while currentDate < date {
                if let sleep = try? await healthKitService.fetchSleepForDate(currentDate) {
                    let hours = sleep.durationInHours
                    sleepDurations.append(hours)
                    dailySleep.append((date: calendar.startOfDay(for: currentDate), value: hours))
                }
                guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                    break
                }
                currentDate = nextDate
            }

            guard sleepDurations.count >= 3 else {
                throw DetailViewError.insufficientData
            }

            // Calculate coefficient of variation for sleep duration
            let mean = sleepDurations.reduce(0.0, +) / Double(sleepDurations.count)
            guard mean > 0 else {
                throw DetailViewError.insufficientData
            }

            let variance = sleepDurations.map { pow($0 - mean, 2) }.reduce(0.0, +) / Double(sleepDurations.count)
            let stdDev = sqrt(variance)
            let cv = stdDev / mean

            averageSleepHours = mean
            standardDeviation = stdDev
            coefficientOfVariation = cv

            // Determine status based on coefficient of variation
            if cv <= 0.15 {
                status = .optimal
            } else if cv <= 0.25 {
                status = .good
            } else if cv <= 0.35 {
                status = .payAttention
            } else {
                status = .poor
            }

            trendData = dailySleep.sorted { $0.date < $1.date }

        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
