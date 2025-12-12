//
//  MeditationSessionViewModel.swift
//  PlenaShared
//
//  Created on [Date]
//

import Foundation
import Combine
import SwiftUI

@MainActor
class MeditationSessionViewModel: ObservableObject {
    @Published var currentSession: MeditationSession?
    @Published var isTracking: Bool = false
    @Published var countdown: Int?
    @Published var sessionSummary: SessionSummary?
    @Published var errorMessage: String?

    // Real-time sensor values
    @Published var currentHeartRate: Double?
    @Published var currentHRV: Double?
    @Published var currentRespiratoryRate: Double?
    @Published var currentVO2Max: Double?
    @Published var currentTemperature: Double?

    // Zone classifications
    @Published var currentHeartRateZone: StressZone?
    @Published var currentHRVZone: StressZone?

    // Availability tracking for UI indicators
    @Published var vo2MaxAvailable: Bool = false
    @Published var temperatureAvailable: Bool = false
    @Published var baselineVO2Max: Double?

    // Connection status tracking - last update time for each sensor
    @Published var lastHeartRateUpdate: Date?
    @Published var lastHRVUpdate: Date?
    @Published var lastRespiratoryRateUpdate: Date?

    // Watch connectivity status (iOS only)
    #if os(iOS)
    @Published var watchConnectionStatus: WatchConnectionStatus = .notSupported
    @Published var isWatchReachable: Bool = false
    private let watchConnectivityService: WatchConnectivityServiceProtocol
    private var watchConnectivityCancellables = Set<AnyCancellable>()
    #endif

    private let healthKitService: HealthKitServiceProtocol
    private let storageService: SessionStorageServiceProtocol
    private let zoneClassifier: ZoneClassifierProtocol

    // Sample rate limiting to prevent memory issues
    // Track last sample timestamp for each sensor type to limit collection rate
    private var lastHeartRateSampleTime: Date?
    private var lastHRVSampleTime: Date?
    private var lastRespiratoryRateSampleTime: Date?
    private var lastVO2MaxSampleTime: Date?
    private var lastTemperatureSampleTime: Date?

    // Minimum interval between samples (1 second) to prevent unbounded memory growth
    private let minimumSampleInterval: TimeInterval = 1.0

    // Stale data threshold - if no update in 10 seconds, consider data stale
    private let staleDataThreshold: TimeInterval = 10.0

    // Timer to trigger view updates for stale data detection
    private var staleDataCheckTimer: Timer?
    @Published private var staleDataCheckTrigger: Int = 0

    init(
        healthKitService: HealthKitServiceProtocol,
        storageService: SessionStorageServiceProtocol = CoreDataStorageService(),
        zoneClassifier: ZoneClassifierProtocol = ZoneClassifier()
    ) {
        self.healthKitService = healthKitService
        self.storageService = storageService
        self.zoneClassifier = zoneClassifier
        #if os(iOS)
        // Initialize watch connectivity service on iOS
        let watchConnectivityService = WatchConnectivityService.shared
        self.watchConnectivityService = watchConnectivityService

        // Subscribe to watch connectivity updates
        watchConnectivityService.connectionStatusPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: &$watchConnectionStatus)

        watchConnectivityService.isWatchReachablePublisher
            .receive(on: DispatchQueue.main)
            .assign(to: &$isWatchReachable)
        #endif
    }

    func startSession() async {
        // Clear any previous summary and errors
        sessionSummary = nil
        errorMessage = nil

        // Reset sample rate limiting timestamps
        lastHeartRateSampleTime = nil
        lastHRVSampleTime = nil
        lastRespiratoryRateSampleTime = nil
        lastVO2MaxSampleTime = nil
        lastTemperatureSampleTime = nil

        // Countdown: 3, 2, 1
        for i in (1...3).reversed() {
            countdown = i
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        }
        countdown = nil

        // Request HealthKit authorization first, before starting session
        do {
            try await healthKitService.requestAuthorization()
        } catch {
            // Handle authorization error
            let errorDescription = error.localizedDescription
            print("Error requesting HealthKit authorization: \(error)")
            print("Error details: \(errorDescription)")
            if let healthKitError = error as? HealthKitError {
                switch healthKitError {
                case .notAvailable:
                    errorMessage = "HealthKit not available on this device"
                case .notAuthorized:
                    errorMessage = "HealthKit permission denied. Please enable in Settings > Health > Data Access & Devices > Plena"
                case .notImplemented:
                    errorMessage = "Feature not implemented"
                }
            } else {
                errorMessage = "HealthKit error: \(errorDescription)"
            }
            // Don't start session if authorization fails
            return
        }

        // Create session and mark as tracking only after successful authorization
        currentSession = MeditationSession()
        isTracking = true

        // Start timer to check for stale data every second
        startStaleDataCheckTimer()

        // Start monitoring watch connectivity (iOS only)
        #if os(iOS)
        watchConnectivityService.startMonitoring()
        #endif

        // Start queries - if any fail, clean up and stop tracking
        do {
            // Fetch baseline VO2 Max at session start for context
            Task {
                if let baseline = try? await healthKitService.fetchLatestVO2Max() {
                    await MainActor.run {
                        self.baselineVO2Max = baseline
                        self.vo2MaxAvailable = true
                    }
                }
            }

            // Start real-time sensor queries
            try healthKitService.startHeartRateQuery { [weak self] heartRate in
                Task { @MainActor in
                    guard let self = self else { return }
                    self.currentHeartRate = heartRate
                    self.lastHeartRateUpdate = Date()
                    self.currentHeartRateZone = self.zoneClassifier.classifyHeartRate(heartRate, baseline: nil)
                    self.addHeartRateSample(heartRate)
                }
            }

            // Start periodic polling as fallback (every 3 seconds) to ensure updates even if anchored query doesn't fire
            try healthKitService.startPeriodicHeartRateQuery(interval: 3.0) { [weak self] heartRate in
                Task { @MainActor in
                    guard let self = self else { return }
                    // Only update if we haven't received a more recent update from the anchored query
                    let now = Date()
                    if self.lastHeartRateUpdate == nil || now.timeIntervalSince(self.lastHeartRateUpdate!) > 2.0 {
                        self.currentHeartRate = heartRate
                        self.lastHeartRateUpdate = now
                        self.currentHeartRateZone = self.zoneClassifier.classifyHeartRate(heartRate, baseline: nil)
                        self.addHeartRateSample(heartRate)
                    }
                }
            }

            try healthKitService.startHRVQuery { [weak self] sdnn in
                Task { @MainActor in
                    guard let self = self else { return }
                    self.currentHRV = sdnn
                    self.lastHRVUpdate = Date()
                    self.currentHRVZone = self.zoneClassifier.classifyHRV(sdnn, age: nil, baseline: nil)
                    self.addHRVSample(sdnn)
                }
            }

            // Start periodic polling as fallback (every 5 seconds) for HRV
            try healthKitService.startPeriodicHRVQuery(interval: 5.0) { [weak self] sdnn in
                Task { @MainActor in
                    guard let self = self else { return }
                    let now = Date()
                    if self.lastHRVUpdate == nil || now.timeIntervalSince(self.lastHRVUpdate!) > 4.0 {
                        self.currentHRV = sdnn
                        self.lastHRVUpdate = now
                        self.currentHRVZone = self.zoneClassifier.classifyHRV(sdnn, age: nil, baseline: nil)
                        self.addHRVSample(sdnn)
                    }
                }
            }

            try healthKitService.startRespiratoryRateQuery { [weak self] rate in
                Task { @MainActor in
                    guard let self = self else { return }
                    self.currentRespiratoryRate = rate
                    self.lastRespiratoryRateUpdate = Date()
                    self.addRespiratoryRateSample(rate)
                }
            }

            // Start periodic polling as fallback (every 5 seconds) for respiratory rate
            try healthKitService.startPeriodicRespiratoryRateQuery(interval: 5.0) { [weak self] rate in
                Task { @MainActor in
                    guard let self = self else { return }
                    let now = Date()
                    if self.lastRespiratoryRateUpdate == nil || now.timeIntervalSince(self.lastRespiratoryRateUpdate!) > 4.0 {
                        self.currentRespiratoryRate = rate
                        self.lastRespiratoryRateUpdate = now
                        self.addRespiratoryRateSample(rate)
                    }
                }
            }

            // Start VO2 Max query (may not update frequently as it's typically calculated from workouts)
            var vo2MaxQueryStarted = false
            do {
                try healthKitService.startVO2MaxQuery { [weak self] vo2Max in
                    Task { @MainActor in
                        self?.currentVO2Max = vo2Max
                        self?.vo2MaxAvailable = true
                        self?.addVO2MaxSample(vo2Max)
                    }
                }
                vo2MaxQueryStarted = true
            } catch {
                print("VO2 Max real-time query not available: \(error)")
            }

            // Start periodic VO2 Max query as fallback (every 30 seconds)
            if !vo2MaxQueryStarted {
                try? healthKitService.startPeriodicVO2MaxQuery(interval: 30.0) { [weak self] vo2Max in
                    Task { @MainActor in
                        self?.currentVO2Max = vo2Max
                        self?.vo2MaxAvailable = true
                        self?.addVO2MaxSample(vo2Max)
                    }
                }
            }

            // Start temperature query (may not be available on all devices)
            var temperatureQueryStarted = false
            do {
                try healthKitService.startTemperatureQuery { [weak self] temperature in
                    Task { @MainActor in
                        self?.currentTemperature = temperature
                        self?.temperatureAvailable = true
                        self?.addTemperatureSample(temperature)
                    }
                }
                temperatureQueryStarted = true
            } catch {
                print("Temperature real-time query not available: \(error)")
            }

            // Start periodic temperature query as fallback (every 30 seconds)
            if !temperatureQueryStarted {
                try? healthKitService.startPeriodicTemperatureQuery(interval: 30.0) { [weak self] temperature in
                    Task { @MainActor in
                        self?.currentTemperature = temperature
                        self?.temperatureAvailable = true
                        self?.addTemperatureSample(temperature)
                    }
                }
            }

            // Also try to fetch latest temperature at start
            Task {
                if let temperature = try? await healthKitService.fetchLatestTemperature() {
                    await MainActor.run {
                        self.currentTemperature = temperature
                        self.temperatureAvailable = true
                        self.addTemperatureSample(temperature)
                    }
                }
            }
        } catch {
            // Handle error - clean up and stop tracking
            let errorDescription = error.localizedDescription
            print("Error starting session queries: \(error)")
            print("Error details: \(errorDescription)")
            // Stop all queries that might have started
            healthKitService.stopAllQueries()
            // Reset session state
            isTracking = false
            currentSession = nil
            countdown = nil
            errorMessage = "Failed to start session: \(errorDescription)"
        }
    }

    func stopSession() {
        guard var session = currentSession else { return }

        // Stop all HealthKit queries (includes periodic tasks)
        healthKitService.stopAllQueries()

        // Stop stale data check timer
        stopStaleDataCheckTimer()

        // Stop monitoring watch connectivity (iOS only)
        #if os(iOS)
        watchConnectivityService.stopMonitoring()
        #endif

        session.endDate = Date()
        currentSession = session
        isTracking = false

        // Calculate and show session summary
        sessionSummary = calculateSummary(from: session)

        // Clear real-time values
        currentHeartRate = nil
        currentHRV = nil
        currentRespiratoryRate = nil
        currentVO2Max = nil
        currentTemperature = nil
        currentHeartRateZone = nil
        currentHRVZone = nil
        baselineVO2Max = nil
        vo2MaxAvailable = false
        temperatureAvailable = false

        // Clear update timestamps
        lastHeartRateUpdate = nil
        lastHRVUpdate = nil
        lastRespiratoryRateUpdate = nil

        // Save session to local storage
        do {
            try storageService.saveSession(session)
        } catch {
            print("Error saving session to local storage: \(error)")
        }

        // Save mindful session to HealthKit for trend tracking
        // This runs asynchronously and doesn't block UI
        Task {
            do {
                let endDate = session.endDate ?? Date()
                try await healthKitService.saveMindfulSession(
                    startDate: session.startDate,
                    endDate: endDate
                )
                print("Successfully saved mindful session to HealthKit")
            } catch {
                // Log error but don't fail - local storage is primary
                print("Error saving mindful session to HealthKit: \(error)")
            }
        }
    }

    func dismissSummary() {
        sessionSummary = nil
    }

    /// Loads the most recent session if it was completed recently (within the last 5 minutes)
    /// and calculates its summary. This helps restore the summary after app restart.
    func loadRecentSessionSummaryIfNeeded() {
        // Only load if we don't already have a summary or current session
        guard sessionSummary == nil, currentSession == nil, !isTracking else { return }

        Task {
            do {
                let allSessions = try storageService.loadAllSessions()
                // Get the most recent completed session
                if let recentSession = allSessions.first(where: { $0.endDate != nil }),
                   let endDate = recentSession.endDate,
                   Date().timeIntervalSince(endDate) < 300 { // Within last 5 minutes
                    // Calculate and set summary
                    await MainActor.run {
                        sessionSummary = calculateSummary(from: recentSession)
                    }
                }
            } catch {
                // Silently fail - this is a nice-to-have feature
                print("Error loading recent session summary: \(error)")
            }
        }
    }

    // MARK: - Connection Status Helpers

    /// Returns true if heart rate data is stale (no update in threshold time)
    var isHeartRateStale: Bool {
        // Access staleDataCheckTrigger to ensure this computed property is re-evaluated
        _ = staleDataCheckTrigger
        guard let lastUpdate = lastHeartRateUpdate else {
            return currentHeartRate != nil // If we have data but no timestamp, consider it stale
        }
        return Date().timeIntervalSince(lastUpdate) > staleDataThreshold
    }

    /// Returns true if HRV data is stale (no update in threshold time)
    var isHRVStale: Bool {
        // Access staleDataCheckTrigger to ensure this computed property is re-evaluated
        _ = staleDataCheckTrigger
        guard let lastUpdate = lastHRVUpdate else {
            return currentHRV != nil // If we have data but no timestamp, consider it stale
        }
        return Date().timeIntervalSince(lastUpdate) > staleDataThreshold
    }

    /// Returns true if respiratory rate data is stale (no update in threshold time)
    var isRespiratoryRateStale: Bool {
        // Access staleDataCheckTrigger to ensure this computed property is re-evaluated
        _ = staleDataCheckTrigger
        guard let lastUpdate = lastRespiratoryRateUpdate else {
            return currentRespiratoryRate != nil // If we have data but no timestamp, consider it stale
        }
        return Date().timeIntervalSince(lastUpdate) > staleDataThreshold
    }

    /// Returns whether any enabled sensor has active (non-stale) data
    /// - Parameter settings: SettingsViewModel to check which sensors are enabled
    /// - Returns: true if at least one enabled sensor has recent data
    func hasActiveSensorData(settings: SettingsViewModel) -> Bool {
        // Check if any enabled sensor has recent (non-stale) data
        if settings.heartRateEnabled {
            if let _ = currentHeartRate, !isHeartRateStale {
                return true
            }
        }

        if settings.hrvEnabled {
            if let _ = currentHRV, !isHRVStale {
                return true
            }
        }

        if settings.respiratoryRateEnabled {
            if let _ = currentRespiratoryRate, !isRespiratoryRateStale {
                return true
            }
        }

        return false
    }

    /// Returns whether any sensors are enabled
    /// - Parameter settings: SettingsViewModel to check which sensors are enabled
    /// - Returns: true if at least one sensor is enabled
    func hasEnabledSensors(settings: SettingsViewModel) -> Bool {
        return settings.heartRateEnabled || settings.hrvEnabled || settings.respiratoryRateEnabled
    }

    /// Starts a timer to periodically check for stale data and trigger view updates
    private func startStaleDataCheckTimer() {
        stopStaleDataCheckTimer()
        staleDataCheckTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.staleDataCheckTrigger += 1
            }
        }
    }

    /// Stops the stale data check timer
    private func stopStaleDataCheckTimer() {
        staleDataCheckTimer?.invalidate()
        staleDataCheckTimer = nil
    }

    // MARK: - Private Helpers

    /// Adds a heart rate sample with rate limiting to prevent memory issues
    private func addHeartRateSample(_ value: Double) {
        let now = Date()
        if let lastTime = lastHeartRateSampleTime,
           now.timeIntervalSince(lastTime) < minimumSampleInterval {
            return // Skip this sample - too soon since last one
        }

        guard var session = currentSession else { return }
        let sample = HeartRateSample(timestamp: now, value: value)
        session.heartRateSamples.append(sample)
        currentSession = session
        lastHeartRateSampleTime = now
    }

    /// Adds an HRV sample with rate limiting to prevent memory issues
    private func addHRVSample(_ sdnn: Double) {
        let now = Date()
        if let lastTime = lastHRVSampleTime,
           now.timeIntervalSince(lastTime) < minimumSampleInterval {
            return // Skip this sample - too soon since last one
        }

        guard var session = currentSession else { return }
        let sample = HRVSample(timestamp: now, sdnn: sdnn)
        session.hrvSamples.append(sample)
        currentSession = session
        lastHRVSampleTime = now
    }

    /// Adds a respiratory rate sample with rate limiting to prevent memory issues
    private func addRespiratoryRateSample(_ value: Double) {
        let now = Date()
        if let lastTime = lastRespiratoryRateSampleTime,
           now.timeIntervalSince(lastTime) < minimumSampleInterval {
            return // Skip this sample - too soon since last one
        }

        guard var session = currentSession else { return }
        let sample = RespiratoryRateSample(timestamp: now, value: value)
        session.respiratoryRateSamples.append(sample)
        currentSession = session
        lastRespiratoryRateSampleTime = now
    }

    /// Adds a VO2 Max sample with rate limiting to prevent memory issues
    private func addVO2MaxSample(_ value: Double) {
        let now = Date()
        if let lastTime = lastVO2MaxSampleTime,
           now.timeIntervalSince(lastTime) < minimumSampleInterval {
            return // Skip this sample - too soon since last one
        }

        guard var session = currentSession else { return }
        let sample = VO2MaxSample(timestamp: now, value: value)
        session.vo2MaxSamples.append(sample)
        currentSession = session
        lastVO2MaxSampleTime = now
    }

    /// Adds a temperature sample with rate limiting to prevent memory issues
    private func addTemperatureSample(_ value: Double) {
        let now = Date()
        if let lastTime = lastTemperatureSampleTime,
           now.timeIntervalSince(lastTime) < minimumSampleInterval {
            return // Skip this sample - too soon since last one
        }

        guard var session = currentSession else { return }
        let sample = TemperatureSample(timestamp: now, value: value)
        session.temperatureSamples.append(sample)
        currentSession = session
        lastTemperatureSampleTime = now
    }

    private func calculateSummary(from session: MeditationSession) -> SessionSummary {
        // Calculate average heart rate
        let averageHeartRate: Double?
        if !session.heartRateSamples.isEmpty {
            let sum = session.heartRateSamples.reduce(0.0) { $0 + $1.value }
            averageHeartRate = sum / Double(session.heartRateSamples.count)
        } else {
            averageHeartRate = nil
        }

        // Calculate lowest heart rate
        let lowestHeartRate = session.heartRateSamples.map { $0.value }.min()

        // Calculate HRV change (start → end)
        let hrvStart = session.hrvSamples.first?.sdnn
        let hrvEnd = session.hrvSamples.last?.sdnn
        let hrvChange: Double?
        if let start = hrvStart, let end = hrvEnd {
            hrvChange = end - start
        } else {
            hrvChange = nil
        }

        // Calculate average respiratory rate
        let averageRespiratoryRate: Double?
        if !session.respiratoryRateSamples.isEmpty {
            let sum = session.respiratoryRateSamples.reduce(0.0) { $0 + $1.value }
            averageRespiratoryRate = sum / Double(session.respiratoryRateSamples.count)
        } else {
            averageRespiratoryRate = nil
        }

        // Calculate respiratory rate trend
        let respiratoryRateTrend: SessionSummary.RespiratoryRateTrend
        if session.respiratoryRateSamples.count >= 3 {
            // Split samples into first half and second half
            let midpoint = session.respiratoryRateSamples.count / 2
            let firstHalf = session.respiratoryRateSamples[..<midpoint]
            let secondHalf = session.respiratoryRateSamples[midpoint...]

            let firstHalfAvg = firstHalf.reduce(0.0) { $0 + $1.value } / Double(firstHalf.count)
            let secondHalfAvg = secondHalf.reduce(0.0) { $0 + $1.value } / Double(secondHalf.count)

            let difference = secondHalfAvg - firstHalfAvg
            let threshold = 0.5 // breaths per minute threshold

            if difference < -threshold {
                respiratoryRateTrend = .decreasing
            } else if difference > threshold {
                respiratoryRateTrend = .increasing
            } else {
                respiratoryRateTrend = .stable
            }
        } else {
            respiratoryRateTrend = .insufficientData
        }

        return SessionSummary(
            averageHeartRate: averageHeartRate,
            lowestHeartRate: lowestHeartRate,
            hrvStart: hrvStart,
            hrvEnd: hrvEnd,
            hrvChange: hrvChange,
            averageRespiratoryRate: averageRespiratoryRate,
            respiratoryRateTrend: respiratoryRateTrend
        )
    }
}

