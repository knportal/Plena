//
//  HRVBalanceDetailViewModel.swift
//  PlenaShared
//
//  ViewModel for HRV Balance detail view
//

import Foundation

@MainActor
class HRVBalanceDetailViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Calculated values
    @Published var currentHRV: Double?
    @Published var baselineHRV: Double?
    @Published var percentChange: Double?
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

            // Calculate baseline HRV from all recent sessions
            let allHRVSamples = allSessions.flatMap { $0.hrvSamples }
            guard !allHRVSamples.isEmpty else {
                throw DetailViewError.insufficientData
            }

            baselineHRV = allHRVSamples.reduce(0.0) { $0 + $1.sdnn } / Double(allHRVSamples.count)

            // Get current HRV (from today's sessions or most recent)
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            let daySessions = allSessions.filter { $0.startDate >= dayStart && $0.startDate < dayEnd }

            let currentSamples = daySessions.isEmpty
                ? Array(allSessions.sorted { $0.startDate > $1.startDate }.prefix(1).flatMap { $0.hrvSamples })
                : daySessions.flatMap { $0.hrvSamples }

            guard !currentSamples.isEmpty, let baseline = baselineHRV else {
                throw DetailViewError.insufficientData
            }

            currentHRV = currentSamples.reduce(0.0) { $0 + $1.sdnn } / Double(currentSamples.count)
            percentChange = ((currentHRV! - baseline) / baseline) * 100

            // Determine status based on percent change
            if percentChange! >= 5 {
                status = .optimal
            } else if percentChange! >= -5 {
                status = .good
            } else if percentChange! >= -15 {
                status = .payAttention
            } else {
                status = .poor
            }

            // Build 7-day trend data
            var dailyHRVs: [(date: Date, value: Double)] = []

            // Group sessions by day
            var sessionsByDay: [Date: [MeditationSession]] = [:]
            for session in allSessions {
                let dayStart = calendar.startOfDay(for: session.startDate)
                sessionsByDay[dayStart, default: []].append(session)
            }

            // Calculate average HRV for each day
            for dayOffset in stride(from: 6, through: 0, by: -1) {
                guard let dayDate = calendar.date(byAdding: .day, value: -dayOffset, to: date) else { continue }
                let dayStart = calendar.startOfDay(for: dayDate)

                guard let daySessions = sessionsByDay[dayStart], !daySessions.isEmpty else { continue }

                let dayHRVSamples = daySessions.flatMap { $0.hrvSamples }
                if !dayHRVSamples.isEmpty {
                    let avg = dayHRVSamples.reduce(0.0) { $0 + $1.sdnn } / Double(dayHRVSamples.count)
                    dailyHRVs.append((date: dayStart, value: avg))
                }
            }

            trendData = dailyHRVs

        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
