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
    @Published var showPaywall = false

    let storageService: SessionStorageServiceProtocol
    let healthKitService: HealthKitServiceProtocol?
    private let readinessService: ReadinessScoreServiceProtocol
    private let featureGateService: FeatureGateServiceProtocol?

    // Track the last date we loaded data for to prevent reloading the same date
    private var lastLoadedDate: Date?

    init(
        storageService: SessionStorageServiceProtocol = CoreDataStorageService(),
        healthKitService: HealthKitServiceProtocol? = nil,
        readinessService: ReadinessScoreServiceProtocol = ReadinessScoreService(),
        featureGateService: FeatureGateServiceProtocol? = nil
    ) {
        self.storageService = storageService
        self.healthKitService = healthKitService
        self.readinessService = readinessService
        self.featureGateService = featureGateService
    }

    /// Check if user has access to readiness score
    var hasAccess: Bool {
        featureGateService?.hasAccess(to: .readinessScore) ?? true // Default to true if no service
    }

    // MARK: - Data Loading

    func loadReadinessScore(for date: Date) async {
        // Guard against concurrent loads - if already loading, return early
        if isLoading {
            return
        }

        // Guard against reloading the same date if we already have data
        if let lastDate = lastLoadedDate,
           Calendar.current.isDate(date, inSameDayAs: lastDate),
           readinessScore != nil {
            return
        }

        // Check premium access (async to ensure fresh status)
        if let featureGate = featureGateService {
            let hasAccess = await featureGate.checkAccess(to: .readinessScore)
            if !hasAccess {
                showPaywall = true
                isLoading = false
                return
            }
        }

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
            lastLoadedDate = date // Track that we've loaded data for this date

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

