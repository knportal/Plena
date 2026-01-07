//
//  BodyTemperatureDetailViewModel.swift
//  PlenaShared
//
//  ViewModel for Body Temperature detail view
//

import Foundation

@MainActor
class BodyTemperatureDetailViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Calculated values
    @Published var currentTemperature: Double?
    @Published var baselineTemperature: Double?
    @Published var deviation: Double?
    @Published var status: ReadinessStatus?
    @Published var trendData: [(date: Date, value: Double)] = []
    @Published var temperatureUnit: TemperatureUnit = .fahrenheit

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

        do {
            // Load sessions from last 7 days for baseline and trend
            guard let weekStart = calendar.date(byAdding: .day, value: -7, to: date) else {
                throw DetailViewError.invalidDate
            }

            let allSessions = try storageService.loadSessions(startDate: weekStart, endDate: date)

            // Calculate baseline from all recent sessions
            let allTemps = allSessions.flatMap { $0.temperatureSamples }.map { $0.value }
            guard !allTemps.isEmpty else {
                throw DetailViewError.insufficientData
            }

            baselineTemperature = allTemps.reduce(0.0, +) / Double(allTemps.count)

            // Get current temperature (from today's sessions or HealthKit or most recent)
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            let daySessions = allSessions.filter { $0.startDate >= dayStart && $0.startDate < dayEnd }

            var latestTemp: Double?

            // Try HealthKit first
            if let healthKitService = healthKitService {
                latestTemp = try? await healthKitService.fetchLatestTemperature()
            }

            // Fallback to session data
            if latestTemp == nil {
                let dayTemps = daySessions.flatMap { $0.temperatureSamples }
                if !dayTemps.isEmpty {
                    latestTemp = dayTemps.max(by: { $0.timestamp < $1.timestamp })?.value
                } else {
                    // Use most recent from all sessions
                    let allDayTemps = allSessions.flatMap { $0.temperatureSamples }
                    if !allDayTemps.isEmpty {
                        latestTemp = allDayTemps.max(by: { $0.timestamp < $1.timestamp })?.value
                    }
                }
            }

            guard let temp = latestTemp, let baseline = baselineTemperature else {
                throw DetailViewError.insufficientData
            }

            currentTemperature = temp
            deviation = abs(temp - baseline)

            // Determine status based on deviation (in Celsius)
            if deviation! <= 0.3 {
                status = .optimal
            } else if deviation! <= 0.6 {
                status = .higher
            } else if deviation! <= 1.0 {
                status = .moderate
            } else {
                status = .lower
            }

            // Build 7-day trend data
            var dailyTemps: [(date: Date, value: Double)] = []

            // Group sessions by day
            var sessionsByDay: [Date: [MeditationSession]] = [:]
            for session in allSessions {
                let dayStart = calendar.startOfDay(for: session.startDate)
                sessionsByDay[dayStart, default: []].append(session)
            }

            // Calculate average temperature for each day
            for dayOffset in stride(from: 6, through: 0, by: -1) {
                guard let dayDate = calendar.date(byAdding: .day, value: -dayOffset, to: date) else { continue }
                let dayStart = calendar.startOfDay(for: dayDate)

                guard let daySessions = sessionsByDay[dayStart], !daySessions.isEmpty else { continue }

                let dayTemps = daySessions.flatMap { $0.temperatureSamples }
                if !dayTemps.isEmpty {
                    let avg = dayTemps.reduce(0.0) { $0 + $1.value } / Double(dayTemps.count)
                    dailyTemps.append((date: dayStart, value: avg))
                }
            }

            trendData = dailyTemps

        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Temperature Conversion Helpers

    func formatTemperature(_ celsius: Double) -> String {
        switch temperatureUnit {
        case .fahrenheit:
            let fahrenheit = (celsius * 9.0 / 5.0) + 32.0
            return String(format: "%.1f", fahrenheit)
        case .celsius:
            return String(format: "%.1f", celsius)
        }
    }

    func temperatureUnitSymbol() -> String {
        temperatureUnit.rawValue
    }
}
