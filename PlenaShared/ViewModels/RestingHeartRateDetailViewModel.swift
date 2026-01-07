//
//  RestingHeartRateDetailViewModel.swift
//  PlenaShared
//
//  ViewModel for Resting Heart Rate detail view
//

import Foundation

@MainActor
class RestingHeartRateDetailViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Calculated values
    @Published var currentRestingHR: Double?
    @Published var baselineHR: Double?
    @Published var deviation: Double?
    @Published var status: ReadinessStatus?
    @Published var trendData: [(date: Date, value: Double)] = []

    private let storageService: SessionStorageServiceProtocol
    private let calendar = Calendar.current

    init(storageService: SessionStorageServiceProtocol = CoreDataStorageService()) {
        self.storageService = storageService
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
            let allHRs = allSessions.flatMap { $0.heartRateSamples }.map { $0.value }
            guard !allHRs.isEmpty else {
                throw DetailViewError.insufficientData
            }

            baselineHR = allHRs.reduce(0.0, +) / Double(allHRs.count)

            // Get last 3 sessions for current resting HR
            let recentSessions = Array(allSessions.sorted { $0.startDate > $1.startDate }.prefix(3))
            var restingRates: [Double] = []

            for session in recentSessions {
                let twoMinutesLater = session.startDate.addingTimeInterval(120)
                let earlySamples = session.heartRateSamples.filter { sample in
                    sample.timestamp >= session.startDate && sample.timestamp <= twoMinutesLater
                }

                if !earlySamples.isEmpty {
                    let avg = earlySamples.reduce(0.0) { $0 + $1.value } / Double(earlySamples.count)
                    restingRates.append(avg)
                }
            }

            guard !restingRates.isEmpty, let baseline = baselineHR else {
                throw DetailViewError.insufficientData
            }

            currentRestingHR = restingRates.reduce(0.0, +) / Double(restingRates.count)
            deviation = abs(currentRestingHR! - baseline)

            // Determine status
            if deviation! <= 5 {
                status = .optimal
            } else if deviation! <= 10 {
                status = .higher
            } else if deviation! <= 15 {
                status = .moderate
            } else {
                status = .lower
            }

            // Build 7-day trend data
            var dailyRestingHRs: [(date: Date, value: Double)] = []

            // Group sessions by day
            var sessionsByDay: [Date: [MeditationSession]] = [:]
            for session in allSessions {
                let dayStart = calendar.startOfDay(for: session.startDate)
                sessionsByDay[dayStart, default: []].append(session)
            }

            // Calculate resting HR for each day
            for dayOffset in stride(from: 6, through: 0, by: -1) {
                guard let dayDate = calendar.date(byAdding: .day, value: -dayOffset, to: date) else { continue }
                let dayStart = calendar.startOfDay(for: dayDate)

                guard let daySessions = sessionsByDay[dayStart], !daySessions.isEmpty else { continue }

                // Get first session of the day and calculate resting HR from first 2 minutes
                let firstSession = daySessions.min(by: { $0.startDate < $1.startDate })!
                let twoMinutesLater = firstSession.startDate.addingTimeInterval(120)
                let earlySamples = firstSession.heartRateSamples.filter { sample in
                    sample.timestamp >= firstSession.startDate && sample.timestamp <= twoMinutesLater
                }

                if !earlySamples.isEmpty {
                    let avg = earlySamples.reduce(0.0) { $0 + $1.value } / Double(earlySamples.count)
                    dailyRestingHRs.append((date: dayStart, value: avg))
                }
            }

            trendData = dailyRestingHRs

        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

enum DetailViewError: LocalizedError {
    case invalidDate
    case insufficientData

    var errorDescription: String? {
        switch self {
        case .invalidDate:
            return "Invalid date provided"
        case .insufficientData:
            return "Insufficient data to calculate resting heart rate"
        }
    }
}










