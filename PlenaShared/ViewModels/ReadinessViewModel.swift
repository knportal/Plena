//
//  ReadinessViewModel.swift
//  PlenaShared
//
//  ViewModel for readiness score feature
//

import Foundation
import Combine

@MainActor
class ReadinessViewModel: ObservableObject {
    @Published var readinessScore: ReadinessScore?
    @Published var yesterdayScore: ReadinessScore?
    @Published var selectedDate: Date = Date()
    @Published var isLoading = false
    @Published var errorMessage: String?

    let storageService: SessionStorageServiceProtocol
    let healthKitService: HealthKitServiceProtocol?
    private let readinessService: ReadinessScoreServiceProtocol

    init(
        storageService: SessionStorageServiceProtocol = CoreDataStorageService(),
        healthKitService: HealthKitServiceProtocol? = nil,
        readinessService: ReadinessScoreServiceProtocol = ReadinessScoreService()
    ) {
        self.storageService = storageService
        self.healthKitService = healthKitService
        self.readinessService = readinessService
    }

    // MARK: - Data Loading

    func loadReadinessScore(for date: Date) async {
        isLoading = true
        errorMessage = nil

        do {
            // Load all sessions (we need historical data for baselines)
            let allSessions = try storageService.loadAllSessions()

            // Calculate readiness for selected date
            let score = await readinessService.calculateReadinessScore(
                for: date,
                sessions: allSessions,
                healthKitService: healthKitService
            )

            readinessScore = score

            // Also load yesterday's score for comparison
            if let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: date) {
                let yesterdayScore = await readinessService.calculateReadinessScore(
                    for: yesterday,
                    sessions: allSessions,
                    healthKitService: healthKitService
                )
                self.yesterdayScore = yesterdayScore
            }

        } catch {
            errorMessage = "Failed to load readiness score: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func reload() async {
        await loadReadinessScore(for: selectedDate)
    }

    // MARK: - Date Navigation

    func selectToday() {
        selectedDate = Date()
        Task {
            await loadReadinessScore(for: selectedDate)
        }
    }

    func selectYesterday() {
        if let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) {
            selectedDate = yesterday
            Task {
                await loadReadinessScore(for: selectedDate)
            }
        }
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }

    var isYesterday: Bool {
        Calendar.current.isDate(selectedDate, inSameDayAs: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date())
    }

    // MARK: - Comparison

    var scoreChange: Double? {
        guard let today = readinessScore,
              let yesterday = yesterdayScore else { return nil }
        return today.overallScore - yesterday.overallScore
    }

    var scoreChangeFormatted: String? {
        guard let change = scoreChange else { return nil }
        let sign = change >= 0 ? "+" : ""
        return String(format: "%@%.0f", sign, change)
    }
}

