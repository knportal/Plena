//
//  RecoveryIndexDetailViewModel.swift
//  PlenaShared
//
//  ViewModel for Recovery Index detail view
//

import Foundation

@MainActor
class RecoveryIndexDetailViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Calculated values
    @Published var averageSessionsPerDay: Double?
    @Published var sessionsPerDay: [Int] = [] // Array of 7 days, most recent first
    @Published var status: ReadinessStatus?
    @Published var trendData: [(date: Date, value: Double)] = [] // Sessions per day for chart

    private let storageService: SessionStorageServiceProtocol
    private let calendar = Calendar.current

    init(storageService: SessionStorageServiceProtocol = CoreDataStorageService()) {
        self.storageService = storageService
    }

    func loadData(for date: Date) async {
        isLoading = true
        errorMessage = nil

        do {
            // Load sessions from last 7 days
            guard let weekStart = calendar.date(byAdding: .day, value: -7, to: date) else {
                throw DetailViewError.invalidDate
            }

            let allSessions = try storageService.loadSessions(startDate: weekStart, endDate: date)

            guard !allSessions.isEmpty else {
                throw DetailViewError.insufficientData
            }

            // Calculate sessions per day for last 7 days
            var sessionsPerDayArray: [Int] = []
            var trendDataArray: [(date: Date, value: Double)] = []

            for i in 0..<7 {
                guard let checkDate = calendar.date(byAdding: .day, value: -i, to: date) else { continue }
                let dayStart = calendar.startOfDay(for: checkDate)
                let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? checkDate

                let dayCount = allSessions.filter { session in
                    session.startDate >= dayStart && session.startDate < dayEnd
                }.count

                sessionsPerDayArray.append(dayCount)
                trendDataArray.append((date: dayStart, value: Double(dayCount)))
            }

            sessionsPerDay = sessionsPerDayArray.reversed() // Most recent first
            trendData = trendDataArray.reversed() // Most recent first

            // Calculate average
            let totalSessions = sessionsPerDayArray.reduce(0, +)
            averageSessionsPerDay = Double(totalSessions) / Double(sessionsPerDayArray.count)

            // Determine status based on average sessions per day
            if let avg = averageSessionsPerDay {
                if avg >= 1.0 && avg <= 2.0 {
                    status = .optimal
                } else if (avg >= 0.5 && avg < 1.0) || (avg > 2.0 && avg <= 3.0) {
                    status = .higher
                } else {
                    status = .moderate
                }
            }

        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
