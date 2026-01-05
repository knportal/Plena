//
//  MeditationSessionViewModel.swift
//  PlenaShared
//
//  Created on [Date]
//

import Foundation
import Combine
import SwiftUI
import OSLog
#if os(watchOS)
import HealthKit
#if canImport(WatchKit)
import WatchKit
#endif
#endif

@MainActor
class MeditationSessionViewModel: ObservableObject {
    // MARK: - Logging
    private let logger = Logger(subsystem: "com.plena.app", category: "MeditationSession")

    @Published var currentSession: MeditationSession?
    @Published var isTracking: Bool = false
    @Published var countdown: Int?
    @Published var sessionSummary: SessionSummary?
    @Published var errorMessage: String?

    // Session timer for iPhone display
    @Published var sessionElapsedTime: TimeInterval = 0
    private var sessionTimer: Timer?

    // Flag to indicate if session was started remotely from iPhone (for background watch collection)
    @Published var isRemoteSession: Bool = false

    // Loading state while waiting for post-session package (iPhone only)
    #if os(iOS)
    @Published var isWaitingForSessionPackage: Bool = false
    #endif

    // Real-time sensor values
    @Published var currentHeartRate: Double?
    @Published var currentHRV: Double?
    @Published var currentRespiratoryRate: Double?
    @Published var currentVO2Max: Double?
    @Published var currentTemperature: Double?

    // Track previous values to detect stale data
    private var previousHeartRate: Double?
    private var previousHRV: Double?
    private var previousRespiratoryRate: Double?

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

    // Device state tracking
    @Published var isDeviceOnWrist: Bool = true

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
    private let featureGateService: FeatureGateServiceProtocol?
    private let deviceStateService: DeviceStateServiceProtocol
    private let workoutSessionService: WorkoutSessionServiceProtocol

    @Published var showPaywall = false

    // Sample rate limiting to prevent memory issues
    // Track last sample timestamp for each sensor type to limit collection rate
    private var lastHeartRateSampleTime: Date?
    private var lastHRVSampleTime: Date?
    private var lastRespiratoryRateSampleTime: Date?
    private var lastVO2MaxSampleTime: Date?
    private var lastTemperatureSampleTime: Date?

    // Minimum interval between samples (1 second) to prevent unbounded memory growth
    private let minimumSampleInterval: TimeInterval = 1.0
    // HRV updates less frequently, so use longer interval to optimize for long sessions
    private let minimumHRVSampleInterval: TimeInterval = 5.0 // HRV: every 5 seconds max

    // Stale data threshold - if no update in 20 seconds, consider data stale (for UI indicators)
    // This is used for showing "No recent updates" on individual sensor cards
    private let staleDataThreshold: TimeInterval = 20.0

    // Very stale threshold - if no update in 60 seconds, sensors are likely not working
    // This is used for the main "watch off wrist" warning
    private let veryStaleDataThreshold: TimeInterval = 60.0

    // No data threshold - if we've never received data after this time, show warning
    // This catches cases where sensors never started providing data
    private let noDataThreshold: TimeInterval = 45.0

    // Track when session started to detect if we've never received data
    private var sessionStartTime: Date?

    // Timer to trigger view updates for stale data detection
    private var staleDataCheckTimer: Timer?
    @Published private var staleDataCheckTrigger: Int = 0

    #if os(watchOS)
    // Live sample sending state
    private var lastLiveSampleSentTimes: [LiveSensorSample.SensorType: Date] = [:]
    private let minimumLiveSampleInterval: TimeInterval = 1.0 // 1 second per sensor
    #endif

    #if os(iOS)
    // Live sample receiving state
    @Published var isReceivingLiveDataFromWatch: Bool = false
    private var lastLiveSampleReceivedTime: Date?
    private let liveDataTimeout: TimeInterval = 15.0 // If no live data for 15 seconds, assume watch stopped sending (increased from 5s to handle gaps)
    private var liveDataTimeoutTimer: Timer?
    #endif

    init(
        healthKitService: HealthKitServiceProtocol,
        storageService: SessionStorageServiceProtocol = CoreDataStorageService(),
        zoneClassifier: ZoneClassifierProtocol = ZoneClassifier(),
        featureGateService: FeatureGateServiceProtocol? = nil,
        deviceStateService: DeviceStateServiceProtocol = DeviceStateService(),
        workoutSessionService: WorkoutSessionServiceProtocol = WorkoutSessionService()
    ) {
        self.healthKitService = healthKitService
        self.storageService = storageService
        self.zoneClassifier = zoneClassifier
        self.featureGateService = featureGateService
        self.deviceStateService = deviceStateService
        self.workoutSessionService = workoutSessionService

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

        // Register post-session package handler (no live samples during session)
        print("📱 iPhone: Registering post-session package handler")
        watchConnectivityService.onSessionPackageReceived { [weak self] package in
            Task { @MainActor in
                guard let self = self else { return }
                print("📱 iPhone: Received post-session package for session \(package.sessionId)")

                // Clear loading state
                self.isWaitingForSessionPackage = false

                // Merge package data into current session if it matches
                if let session = self.currentSession, session.id == package.sessionId {
                    var updatedSession = session
                    package.merge(into: &updatedSession)
                    self.currentSession = updatedSession

                    // Recalculate summary with complete data
                    self.sessionSummary = self.calculateSummary(from: updatedSession)

                    // Save to storage
                    do {
                        try self.storageService.saveSession(updatedSession)
                        print("✅ Session saved with post-session data")
                    } catch {
                        print("⚠️ Error saving session with post-session data: \(error)")
                    }
                } else {
                    // Session doesn't match - create new session from package
                    var newSession = MeditationSession(id: package.sessionId, startDate: package.startDate)
                    newSession.endDate = package.endDate
                    package.merge(into: &newSession)
                    self.currentSession = newSession

                    // Calculate and show summary
                    self.sessionSummary = self.calculateSummary(from: newSession)

                    // Save to storage
                    do {
                        try self.storageService.saveSession(newSession)
                        print("✅ New session saved from post-session package")
                    } catch {
                        print("⚠️ Error saving session from package: \(error)")
                    }
                }
            }
        }
        #elseif os(watchOS)
        // On watchOS, we need access to WatchConnectivityService to send sessions
        // Create a dummy protocol conformance for watchOS
        // The actual service will be accessed via WatchConnectivityService.shared
        #endif

        // Subscribe to device state updates (after all stored properties are initialized)
        deviceStateService.isDeviceOnWristPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: &$isDeviceOnWrist)

        #if os(iOS)
        // Listen for watch session start notifications
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("WatchSessionStarted"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor in
                guard let self = self else { return }
                guard let userInfo = notification.userInfo,
                      let sessionId = userInfo["sessionId"] as? UUID,
                      let startDate = userInfo["startDate"] as? Date else {
                    print("⚠️ iPhone: Invalid WatchSessionStarted notification")
                    return
                }

                print("📱 iPhone: Watch session started - starting iPhone timer display")

                // Create session and start tracking
                self.currentSession = MeditationSession(id: sessionId, startDate: startDate)
                self.isTracking = true
                self.sessionElapsedTime = 0
                self.startSessionTimer()
            }
        }

        // Listen for watch session end notifications
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("WatchSessionEnded"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor in
                guard let self = self else { return }
                // If we're tracking a session, stop it (Watch ended the session)
                if self.isTracking {
                    print("📱 iPhone: Watch session ended - stopping iPhone session display")
                    // Stop the timer and wait for post-session package
                    self.isTracking = false
                    self.stopSessionTimer()
                    self.isWaitingForSessionPackage = true
                    // Don't call stopSession() here - we want to wait for the package
                    // The package handler will update the session and show summary
                }
            }
        }
        #endif
    }

    deinit {
        #if os(iOS)
        NotificationCenter.default.removeObserver(self)
        #endif
    }

    /// Start workout session from external request (e.g., from iPhone via WatchConnectivity)
    /// This allows the watch app to start its workout session when requested by iPhone
    func startWorkoutSessionFromRequest() async {
        #if os(watchOS)
        print("📱 Watch: Received workout session start request from iPhone")
        do {
            try await workoutSessionService.startSession()
            print("✅ Watch: Workout session started successfully from iPhone request")
        } catch {
            print("⚠️ Watch: Failed to start workout session from iPhone request: \(error)")
        }
        #endif
    }

    func startSession(isRemote: Bool = false) async {
        // Set remote session flag (true when started from iPhone, watch runs in background)
        self.isRemoteSession = isRemote

        // Clear any previous summary and errors
        sessionSummary = nil
        errorMessage = nil

        // Reset sample rate limiting timestamps
        lastHeartRateSampleTime = nil
        lastHRVSampleTime = nil
        lastRespiratoryRateSampleTime = nil
        lastVO2MaxSampleTime = nil
        lastTemperatureSampleTime = nil

        // Reset previous values for stale detection
        previousHeartRate = nil
        previousHRV = nil
        previousRespiratoryRate = nil

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
                    errorMessage = "HealthKit is not available on this device. HealthKit requires a physical iPhone with iOS 8.0 or later."
                case .notAuthorized:
                    errorMessage = "HealthKit permissions are required to track your biometrics. Please enable Heart Rate, HRV (SDNN), and Respiratory Rate in Settings → Privacy & Security → Health → Plena"
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
        var session = MeditationSession()

        // Initialize metadata with device information
        #if os(watchOS)
        session.metadata?.deviceType = "watch"
        #if canImport(WatchKit)
        session.metadata?.watchModel = WKInterfaceDevice.current().name
        #endif
        #else
        session.metadata?.deviceType = "iphone"
        #endif

        currentSession = session
        sessionStartTime = Date()
        isTracking = true
        sessionElapsedTime = 0

        // Notify iPhone that session started (watchOS only)
        #if os(watchOS)
        if let session = currentSession {
            Task {
                do {
                    try await WatchConnectivityService.shared.notifyIPhoneSessionStarted(
                        sessionId: session.id,
                        startDate: session.startDate
                    )
                    print("✅ Notified iPhone that session started")
                } catch {
                    print("⚠️ Failed to notify iPhone of session start: \(error)")
                    // Don't fail - session continues on watch
                }
            }
        }
        #endif

        // Start session timer for display (both iOS and watchOS)
        startSessionTimer()

        // Start timer to check for stale data every second (watchOS only)
        #if os(watchOS)
        startStaleDataCheckTimer()
        #endif

        // Start workout session to trigger active HRV measurements
        // This ensures Apple Watch actively measures HRV during the session
        Task {
            do {
                #if os(watchOS)
                // Set up statistics handler to receive data from workout builder
                if let workoutService = workoutSessionService as? WorkoutSessionService {
                    workoutService.setStatisticsHandler { [weak self] quantityType, statistics in
                        Task { @MainActor in
                            guard let self = self else { return }

                            let identifier = quantityType.identifier

                            // Process Heart Rate statistics (primary source from builder)
                            if identifier == HKQuantityTypeIdentifier.heartRate.rawValue {
                                if let mostRecent = statistics.mostRecentQuantity() {
                                    let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
                                    let heartRate = mostRecent.doubleValue(for: heartRateUnit)
                                    print("📊 Workout builder HR: \(String(format: "%.1f", heartRate)) BPM")
                                    self.updateHeartRate(heartRate)
                                }
                            }

                            // Process HRV statistics if available
                            if identifier == HKQuantityTypeIdentifier.heartRateVariabilitySDNN.rawValue {
                                if let mostRecent = statistics.mostRecentQuantity() {
                                    let hrvUnit = HKUnit.secondUnit(with: .milli)
                                    let hrv = mostRecent.doubleValue(for: hrvUnit)
                                    print("📊 Workout builder HRV: \(String(format: "%.1f", hrv)) ms")
                                    self.currentHRV = hrv
                                    self.lastHRVUpdate = Date()
                                    self.currentHRVZone = self.zoneClassifier.classifyHRV(hrv, age: nil, baseline: nil)
                                    self.addHRVSample(hrv)
                                }
                            }

                            // Process Respiratory Rate statistics if available
                            if identifier == HKQuantityTypeIdentifier.respiratoryRate.rawValue {
                                if let mostRecent = statistics.mostRecentQuantity() {
                                    let respiratoryUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
                                    let rate = mostRecent.doubleValue(for: respiratoryUnit)
                                    print("📊 Workout builder Respiratory Rate: \(String(format: "%.1f", rate)) /min")
                                    self.currentRespiratoryRate = rate
                                    self.lastRespiratoryRateUpdate = Date()
                                    self.addRespiratoryRateSample(rate)
                                }
                            }
                        }
                    }
                }
                #endif

                try await workoutSessionService.startSession()
                print("✅ Workout session started - HRV will be actively measured")

                // Request watch app to start its workout session and meditation session
                #if os(iOS)
                if let watchConnectivity = watchConnectivityService as? WatchConnectivityService {
                    Task {
                        do {
                            try await watchConnectivity.requestWatchStartWorkoutSession()
                            print("✅ Watch app requested to start workout session")

                            // Also request watch to start its meditation session
                            try await watchConnectivity.requestWatchStartMeditationSession()
                            print("✅ Watch app requested to start meditation session")
                        } catch {
                            print("⚠️ Failed to request watch session: \(error)")
                            // Don't fail - watch might not be reachable or on wrist
                        }
                    }
                }
                #endif
            } catch {
                print("⚠️ Failed to start workout session: \(error)")
                // Don't fail the entire session if workout session fails
                // Sensors may still work, just not as actively
            }
        }

        // Start monitoring device state (watch on wrist detection)
        deviceStateService.startMonitoring()

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

            #if os(watchOS)
            // Start real-time sensor queries (WATCH ONLY - iPhone just shows timer)
            print("⌚️ Watch: Starting all sensor queries (HR, HRV, Respiratory, etc.)")
            try healthKitService.startHeartRateQuery { [weak self] heartRate in
                Task { @MainActor in
                    guard let self = self else { return }
                    #if os(watchOS)
                    print("📊 Watch: Heart rate anchored query callback: \(heartRate) BPM")
                    #endif
                    self.updateHeartRate(heartRate)
                    // No live sample sending during session - data stays on watch
                }
            }

            // Start periodic polling as fallback (every 2 seconds) to ensure updates even if anchored query doesn't fire
            // Reduced interval for more frequent real-time updates
            try healthKitService.startPeriodicHeartRateQuery(interval: 2.0) { [weak self] heartRate in
                Task { @MainActor in
                    guard let self = self else { return }
                    #if os(watchOS)
                    print("📊 Watch: Heart rate periodic query callback: \(heartRate) BPM")
                    #endif
                    self.updateHeartRate(heartRate)
                    // No live sample sending during session - data stays on watch
                }
            }

            try healthKitService.startHRVQuery { [weak self] sdnn, sampleTimestamp in
                Task { @MainActor in
                    guard let self = self else { return }

                    // Track that HRV callback was received
                    if var session = self.currentSession {
                        if session.metadata?.hrvInitialCallbackReceived == false {
                            session.metadata?.hrvInitialCallbackReceived = true
                            print("📊 Analytics: First HRV callback received")
                        }
                        session.metadata?.hrvUpdateCallbacksReceived += 1
                        self.currentSession = session
                    }

                    // Only accept HRV samples that fall within the current session timeframe
                    // This prevents capturing old samples from before the session started
                    if let session = self.currentSession {
                        let sessionStart = session.startDate
                        let sessionEnd = session.endDate ?? Date()

                        // Only accept samples within session timeframe (with small buffer for timing)
                        if sampleTimestamp < sessionStart.addingTimeInterval(-10) || sampleTimestamp > sessionEnd.addingTimeInterval(10) {
                            #if os(watchOS)
                            print("⏭️ HRV sample rejected (outside session timeframe): \(String(format: "%.1f", sdnn)) ms at \(sampleTimestamp), session: \(sessionStart) to \(sessionEnd)")
                            #endif
                            return
                        }
                    }

                    // Log HRV callback
                    self.logger.debug("HRV handler callback - sdnn: \(sdnn), sampleTimestamp: \(sampleTimestamp.timeIntervalSince1970), hasCurrentSession: \(self.currentSession != nil), isTracking: \(self.isTracking)")

                    #if os(watchOS)
                    print("✅ Watch: HRV anchored query callback (within session): \(sdnn) ms")
                    #endif
                    self.currentHRV = sdnn
                    self.lastHRVUpdate = Date()
                    self.currentHRVZone = self.zoneClassifier.classifyHRV(sdnn, age: nil, baseline: nil)
                    self.addHRVSample(sdnn)
                    // No live sample sending during session - data stays on watch
                }
            }

            // Start periodic polling as fallback (every 5 seconds) for HRV
            try healthKitService.startPeriodicHRVQuery(interval: 5.0) { [weak self] sdnn, sampleTimestamp in
                Task { @MainActor in
                    guard let self = self else { return }

                    // Track periodic query success
                    if var session = self.currentSession {
                        session.metadata?.hrvPeriodicQueriesSuccessful += 1
                        self.currentSession = session
                    }

                    // Only accept HRV samples that fall within the current session timeframe
                    if let session = self.currentSession {
                        let sessionStart = session.startDate
                        let sessionEnd = session.endDate ?? Date()

                        // Only accept samples within session timeframe (with small buffer for timing)
                        if sampleTimestamp < sessionStart.addingTimeInterval(-10) || sampleTimestamp > sessionEnd.addingTimeInterval(10) {
                            #if os(watchOS)
                            print("⏭️ HRV periodic sample rejected (outside session timeframe): \(String(format: "%.1f", sdnn)) ms")
                            #endif
                            return
                        }
                    }

                    let now = Date()

                    // Always update timestamp when we receive data from HealthKit
                    // HRV values can be stable - that's normal and valid
                    let shouldUpdate: Bool
                    if let lastUpdate = self.lastHRVUpdate {
                        let timeSinceUpdate = now.timeIntervalSince(lastUpdate)
                        let valueChanged = self.previousHRV == nil || abs(self.previousHRV! - sdnn) > 1.0

                        // Update if: value changed OR it's been more than 2 seconds (HRV updates less frequently)
                        shouldUpdate = valueChanged || timeSinceUpdate >= 2.0
                    } else {
                        // First reading - always update
                        shouldUpdate = true
                    }

                    if shouldUpdate {
                        #if os(watchOS)
                        print("✅ Watch: HRV periodic query callback (within session): \(sdnn) ms")
                        #endif
                        self.currentHRV = sdnn
                        self.lastHRVUpdate = now
                        self.previousHRV = sdnn
                        self.currentHRVZone = self.zoneClassifier.classifyHRV(sdnn, age: nil, baseline: nil)
                        self.addHRVSample(sdnn)
                        #if os(watchOS)
                        self.sendLiveSampleIfNeeded(sensorType: .hrv, value: sdnn)
                        #endif
                    }
                }
            }

            // Mark that HRV query was started
            if var session = currentSession {
                session.metadata?.hrvQueryStarted = true
                currentSession = session
            }

            try healthKitService.startRespiratoryRateQuery { [weak self] rate in
                Task { @MainActor in
                    guard let self = self else { return }
                    #if os(watchOS)
                    print("📊 Watch: Respiratory rate anchored query callback: \(rate) /min")
                    #endif
                    self.currentRespiratoryRate = rate
                    self.lastRespiratoryRateUpdate = Date()
                    self.addRespiratoryRateSample(rate)
                    // No live sample sending during session - data stays on watch
                }
            }

            // Start periodic polling as fallback (every 5 seconds) for respiratory rate
            try healthKitService.startPeriodicRespiratoryRateQuery(interval: 5.0) { [weak self] rate in
                Task { @MainActor in
                    guard let self = self else { return }
                    let now = Date()

                    // Always update timestamp when we receive data from HealthKit
                    // Respiratory rate can be stable - that's normal during meditation
                    let shouldUpdate: Bool
                    if let lastUpdate = self.lastRespiratoryRateUpdate {
                        let timeSinceUpdate = now.timeIntervalSince(lastUpdate)
                        let valueChanged = self.previousRespiratoryRate == nil || abs(self.previousRespiratoryRate! - rate) > 0.5

                        // Update if: value changed OR it's been more than 2 seconds
                        shouldUpdate = valueChanged || timeSinceUpdate >= 2.0
                    } else {
                        // First reading - always update
                        shouldUpdate = true
                    }

                    if shouldUpdate {
                        #if os(watchOS)
                        print("📊 Watch: Respiratory rate periodic query callback: \(rate) /min")
                        #endif
                        self.currentRespiratoryRate = rate
                        self.lastRespiratoryRateUpdate = now
                        self.previousRespiratoryRate = rate
                        self.addRespiratoryRateSample(rate)
                        #if os(watchOS)
                        self.sendLiveSampleIfNeeded(sensorType: .respiratoryRate, value: rate)
                        #endif
                    }
                }
            }

            // Start VO2 Max query (may not update frequently as it's typically calculated from workouts)
            // Only if user has premium access
            var vo2MaxQueryStarted = false
            if featureGateService?.hasAccess(to: PremiumFeature.advancedSensors) ?? true {
                do {
                    try healthKitService.startVO2MaxQuery { [weak self] vo2Max in
                        Task { @MainActor in
                            self?.currentVO2Max = vo2Max
                            self?.vo2MaxAvailable = true
                            self?.addVO2MaxSample(vo2Max)
                            // No live sample sending during session - data stays on watch
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
                            // No live sample sending during session - data stays on watch
                        }
                    }
                }
            }

            // Start temperature query (may not be available on all devices)
            // Only if user has premium access
            var temperatureQueryStarted = false
            if featureGateService?.hasAccess(to: PremiumFeature.advancedSensors) ?? true {
                do {
                    try healthKitService.startTemperatureQuery { [weak self] temperature in
                        Task { @MainActor in
                            self?.currentTemperature = temperature
                            self?.temperatureAvailable = true
                            self?.addTemperatureSample(temperature)
                            // No live sample sending during session - data stays on watch
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
                            // No live sample sending during session - data stays on watch
                        }
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
                        // No live sample sending during session - data stays on watch
                    }
                }
            }
            #endif // os(watchOS)

            #if os(iOS)
            // iPhone: Only timer display, no sensor collection (Watch handles all sensors)
            print("📱 iPhone: Session started - showing timer only (watch handles sensors)")
            #endif
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

        // Stop workout session
        Task {
            do {
                try await workoutSessionService.stopSession()
                print("✅ Workout session stopped")

                // After workout ends, query for HRV samples that may have been written
                // HealthKit often writes HRV samples after the workout completes
                #if os(watchOS)
                if let sessionEnd = session.endDate {
                    // Wait a moment for HealthKit to write any pending HRV samples
                    try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds

                    do {
                        let hrvSamples = try await healthKitService.fetchHRVSamples(
                            startDate: session.startDate,
                            endDate: sessionEnd
                        )

                        if !hrvSamples.isEmpty {
                            print("✅ Found \(hrvSamples.count) HRV samples after workout end")

                            // Add HRV samples to the session
                            Task { @MainActor in
                                guard var updatedSession = self.currentSession else { return }
                                let now = Date()

                                // Track post-workout samples found
                                updatedSession.metadata?.hrvPostWorkoutSamplesFound = hrvSamples.count
                                print("📊 Analytics: Post-workout found \(hrvSamples.count) HRV samples")

                                for hrvValue in hrvSamples {
                                    // Check if we already have this sample (avoid duplicates)
                                    let sample = HRVSample(timestamp: now, sdnn: hrvValue)
                                    updatedSession.hrvSamples.append(sample)
                                }

                                self.currentSession = updatedSession

                                // Recalculate summary with new HRV data
                                #if os(watchOS)
                                self.sessionSummary = self.calculateSummary(from: updatedSession)
                                #endif

                                // Save updated session
                                do {
                                    try self.storageService.saveSession(updatedSession)
                                    print("✅ Session updated with post-workout HRV samples")
                                } catch {
                                    print("⚠️ Failed to save session with HRV samples: \(error)")
                                }
                            }
                        } else {
                            print("⚠️ No HRV samples found after workout end")
                        }
                    } catch {
                        print("⚠️ Failed to fetch HRV samples after workout: \(error)")
                    }
                }
                #endif
            } catch {
                print("⚠️ Failed to stop workout session: \(error)")
            }
        }

        // Stop monitoring device state
        deviceStateService.stopMonitoring()

        // Stop monitoring watch connectivity (iOS only)
        #if os(iOS)
        watchConnectivityService.stopMonitoring()
        #endif

        session.endDate = Date()

        // Finalize metadata before saving
        if let endDate = session.endDate {
            // Copy metadata to local variable to avoid overlapping access
            var metadata = session.metadata
            metadata?.durationSeconds = Int(endDate.timeIntervalSince(session.startDate))
            metadata?.hrvSampleCount = session.hrvSamples.count
            metadata?.hrvDataAvailable = !session.hrvSamples.isEmpty
            session.metadata = metadata
            print("📊 Analytics: Session ended - HRV available: \(metadata?.hrvDataAvailable ?? false), samples: \(session.hrvSamples.count)")
        }

        currentSession = session
        isTracking = false


        // On iPhone, don't show summary immediately - wait for post-session package
        // The package handler will calculate and show the summary with complete data
        #if os(iOS)
        // Set loading state while waiting for package
        isWaitingForSessionPackage = true

        // Capture session for timeout handler
        let sessionToSave = session

        // Set a timeout to fall back to local summary if no package arrives
        Task {
            // Wait 10 seconds for package
            try? await Task.sleep(nanoseconds: 10_000_000_000)

            // If still waiting after 10 seconds, show local summary
            await MainActor.run {
                if self.isWaitingForSessionPackage {
                    print("⏱️ Timeout waiting for watch package (10s) - showing local summary")
                    self.isWaitingForSessionPackage = false

                    // If we have no sensor data, it means watch wasn't collecting
                    if sessionToSave.heartRateSamples.isEmpty &&
                       sessionToSave.hrvSamples.isEmpty &&
                       sessionToSave.respiratoryRateSamples.isEmpty {
                        print("⚠️ No sensor data collected - session was iPhone-only")
                    }

                    self.sessionSummary = self.calculateSummary(from: sessionToSave)
                }
            }
        }

        // Request Watch to stop session and send package
        Task {
            do {
                if let watchConnectivity = watchConnectivityService as? WatchConnectivityService {
                    // Check if watch is reachable before requesting
                    if self.isWatchReachable {
                        try await watchConnectivity.requestWatchStopSession()
                        print("✅ Requested Watch to stop session and send package")
                    } else {
                        print("⚠️ Watch not reachable - showing local summary immediately")
                        // Watch not reachable, show local summary now
                        await MainActor.run {
                            self.isWaitingForSessionPackage = false
                            self.sessionSummary = self.calculateSummary(from: sessionToSave)
                        }
                    }
                }
            } catch {
                print("⚠️ Failed to request Watch to stop session: \(error)")
                // If request failed, show summary from local data
                await MainActor.run {
                    self.isWaitingForSessionPackage = false
                    self.sessionSummary = self.calculateSummary(from: sessionToSave)
                }
            }
        }
        #else
        // On Watch, calculate summary immediately (Watch has all the data)
        sessionSummary = calculateSummary(from: session)
        #endif


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

        // Clear session start time
        sessionStartTime = nil

        // Stop session timer (both iOS and watchOS)
        stopSessionTimer()

        // Clear live data state
        #if os(iOS)
        isReceivingLiveDataFromWatch = false
        lastLiveSampleReceivedTime = nil
        stopLiveDataTimeoutMonitoring()
        #endif

        #if os(watchOS)
        lastLiveSampleSentTimes.removeAll()
        #endif

        // Save session to local storage
        do {
            try storageService.saveSession(session)
            print("✅ Session saved to local storage")
        } catch {
            print("Error saving session to local storage: \(error)")
        }

        // Send session package to iPhone via WatchConnectivity (watchOS only)
        #if os(watchOS)
        Task {
            do {
                let watchConnectivity = WatchConnectivityService.shared
                let package = SessionSyncPackage(from: session)

                // Notify iPhone that session ended (so it can stop timer)
                // This is sent before the package to ensure iPhone stops its display quickly
                try? await watchConnectivity.notifyIPhoneSessionEnded(sessionId: session.id)

                // Send complete session package
                try await watchConnectivity.sendSessionPackage(package)
                print("✅ Session package sent to iPhone")
            } catch {
                print("⚠️ Failed to send session package to iPhone via WatchConnectivity: \(error)")
                // Don't fail - local storage is primary, sync is secondary
            }
        }
        #endif

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

    /// Force show local summary (for when user doesn't want to wait for watch data)
    func forceShowLocalSummary() {
        #if os(iOS)
        guard isWaitingForSessionPackage, let session = currentSession else { return }

        print("👤 User requested local summary - stopping wait for watch package")
        isWaitingForSessionPackage = false
        sessionSummary = calculateSummary(from: session)
        #endif
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

    /// Returns true if sensors are not receiving data (watch likely off wrist or not working)
    /// - Parameter settings: SettingsViewModel to check which sensors are enabled
    /// - Returns: true if sensors are not receiving data
    func isWatchLikelyOffWrist(settings: SettingsViewModel) -> Bool {
        guard hasEnabledSensors(settings: settings) else { return false }

        guard let sessionStart = sessionStartTime else { return false }
        let sessionDuration = Date().timeIntervalSince(sessionStart)

        // Check if we've never received any data after reasonable time
        if sessionDuration >= noDataThreshold {
            var hasReceivedAnyData = false

            if settings.heartRateEnabled, currentHeartRate != nil {
                hasReceivedAnyData = true
            }
            if settings.hrvEnabled, currentHRV != nil {
                hasReceivedAnyData = true
            }
            if settings.respiratoryRateEnabled, currentRespiratoryRate != nil {
                hasReceivedAnyData = true
            }

            // If we've never received any data after 45 seconds, sensors aren't working
            if !hasReceivedAnyData {
                return true
            }
        }

        // Check if all enabled sensors have been silent for a very long time (60+ seconds)
        // This catches cases where sensors stopped working mid-session
        var allSensorsVeryStale = true

        if settings.heartRateEnabled {
            if let lastUpdate = lastHeartRateUpdate {
                let age = Date().timeIntervalSince(lastUpdate)
                if age < veryStaleDataThreshold {
                    allSensorsVeryStale = false
                }
            } else if currentHeartRate == nil {
                // No data yet, but check if we've waited long enough
                if sessionDuration < noDataThreshold {
                    allSensorsVeryStale = false
                }
            } else {
                // We have data but no timestamp - this shouldn't happen, but be conservative
                allSensorsVeryStale = false
            }
        }

        if settings.hrvEnabled {
            if let lastUpdate = lastHRVUpdate {
                let age = Date().timeIntervalSince(lastUpdate)
                if age < veryStaleDataThreshold {
                    allSensorsVeryStale = false
                }
            } else if currentHRV == nil {
                // HRV can take longer to appear, so only check if heart rate is also stale
                // This prevents false positives when HRV just hasn't appeared yet
                if settings.heartRateEnabled, let hrUpdate = lastHeartRateUpdate {
                    let hrAge = Date().timeIntervalSince(hrUpdate)
                    if hrAge < veryStaleDataThreshold {
                        allSensorsVeryStale = false
                    }
                } else if !settings.heartRateEnabled {
                    // Only HRV enabled, check if we've waited long enough
                    if sessionDuration < noDataThreshold {
                        allSensorsVeryStale = false
                    }
                }
            } else {
                allSensorsVeryStale = false
            }
        }

        if settings.respiratoryRateEnabled {
            if let lastUpdate = lastRespiratoryRateUpdate {
                let age = Date().timeIntervalSince(lastUpdate)
                if age < veryStaleDataThreshold {
                    allSensorsVeryStale = false
                }
            } else if currentRespiratoryRate == nil {
                // Respiratory rate can take longer to appear, similar to HRV
                if settings.heartRateEnabled, let hrUpdate = lastHeartRateUpdate {
                    let hrAge = Date().timeIntervalSince(hrUpdate)
                    if hrAge < veryStaleDataThreshold {
                        allSensorsVeryStale = false
                    }
                } else if !settings.heartRateEnabled {
                    // Only respiratory rate enabled, check if we've waited long enough
                    if sessionDuration < noDataThreshold {
                        allSensorsVeryStale = false
                    }
                }
            } else {
                allSensorsVeryStale = false
            }
        }

        return allSensorsVeryStale
    }

    /// Returns true if sensors have very stale data (used for main warning)
    /// This is now handled by isWatchLikelyOffWrist, but kept for backward compatibility
    var hasVeryStaleData: Bool {
        // This property is deprecated - use isWatchLikelyOffWrist instead
        // But we'll keep it simple for now to avoid breaking existing code
        _ = staleDataCheckTrigger // Trigger view update

        // Only check if we have data that's very stale
        // Don't trigger on "no data yet" - that's handled by isWatchLikelyOffWrist
        if let lastUpdate = lastHeartRateUpdate,
           Date().timeIntervalSince(lastUpdate) > veryStaleDataThreshold {
            return true
        }

        if let lastUpdate = lastHRVUpdate,
           Date().timeIntervalSince(lastUpdate) > veryStaleDataThreshold {
            return true
        }

        if let lastUpdate = lastRespiratoryRateUpdate,
           Date().timeIntervalSince(lastUpdate) > veryStaleDataThreshold {
            return true
        }

        return false
    }

    /// Returns the age of the most recent sensor data update in seconds
    /// - Returns: Age in seconds, or nil if no data available
    var mostRecentDataAge: TimeInterval? {
        var timestamps: [Date] = []

        if let hrUpdate = lastHeartRateUpdate {
            timestamps.append(hrUpdate)
        }
        if let hrvUpdate = lastHRVUpdate {
            timestamps.append(hrvUpdate)
        }
        if let respUpdate = lastRespiratoryRateUpdate {
            timestamps.append(respUpdate)
        }

        guard let mostRecent = timestamps.max() else {
            return nil
        }

        return Date().timeIntervalSince(mostRecent)
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

    #if os(iOS)
    /// Monitors if we're still receiving live data from watch
    /// If no data received for liveDataTimeout seconds, assume watch stopped sending
    private func startLiveDataTimeoutMonitoring() {
        stopLiveDataTimeoutMonitoring()
        liveDataTimeoutTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                guard self.isReceivingLiveDataFromWatch else { return }

                if let lastReceived = self.lastLiveSampleReceivedTime {
                    let timeSinceLastSample = Date().timeIntervalSince(lastReceived)
                    // Only stop if we're not tracking (session ended) or if it's been a very long time (30s)
                    // This prevents false positives during normal gaps in sensor readings
                    if timeSinceLastSample > self.liveDataTimeout {
                        if !self.isTracking || timeSinceLastSample > 30.0 {
                            self.isReceivingLiveDataFromWatch = false
                            print("⚠️ Stopped receiving live data from watch - falling back to iPhone HealthKit")
                        }
                    }
                }
            }
        }
    }

    /// Stops the live data timeout monitoring timer
    private func stopLiveDataTimeoutMonitoring() {
        liveDataTimeoutTimer?.invalidate()
        liveDataTimeoutTimer = nil
    }
    #endif

    /// Starts the session timer for display (both iOS and watchOS)
    private func startSessionTimer() {
        stopSessionTimer()
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, let startDate = self.currentSession?.startDate else { return }
                self.sessionElapsedTime = Date().timeIntervalSince(startDate)
            }
        }
    }

    /// Stops the session timer
    private func stopSessionTimer() {
        sessionTimer?.invalidate()
        sessionTimer = nil
    }

    #if os(watchOS)
    /// Sends a live sample to iPhone if throttling allows
    private func sendLiveSampleIfNeeded(sensorType: LiveSensorSample.SensorType, value: Double) {
        let now = Date()

        // Check throttling - only send if enough time has passed since last send for this sensor
        if let lastTime = lastLiveSampleSentTimes[sensorType],
           now.timeIntervalSince(lastTime) < minimumLiveSampleInterval {
            // Throttled - too soon since last send
            return
        }

        // Update last send time
        lastLiveSampleSentTimes[sensorType] = now

        // Create and send sample
        let sample = LiveSensorSample(sensorType: sensorType, value: value, timestamp: now)
        print("📡 Attempting to send live sample: \(sensorType.rawValue) = \(value)")
        Task {
            do {
                try await WatchConnectivityService.shared.sendLiveSample(sample)
                print("✅ Live sample sent successfully: \(sensorType.rawValue) = \(value)")
            } catch {
                print("❌ Failed to send live sample \(sensorType.rawValue): \(error.localizedDescription)")
                // Error already logged in WatchConnectivityService
                // Don't retry - live samples are best-effort
            }
        }
    }
    #endif

    // MARK: - Private Helpers

    /// Updates heart rate with debouncing to prevent UI flickering
    /// Enforces minimum time between UI updates to prevent rapid flickering
    private func updateHeartRate(_ heartRate: Double) {
        let now = Date()

        // Always enforce minimum time between UI updates to prevent flickering
        // Only allow updates if:
        // 1. It's been at least 1.0 seconds since last update, AND
        // 2. Value changed by more than 2 BPM (if less than 3 seconds since last update)
        //    OR value changed by more than 1 BPM (if more than 3 seconds since last update)
        // Reduced minimum time to 1.0s to keep data flowing while preventing flicker
        let shouldUpdate: Bool
        if let lastUpdate = lastHeartRateUpdate {
            let timeSinceUpdate = now.timeIntervalSince(lastUpdate)

            // Always enforce minimum 1.0 second delay between UI updates
            guard timeSinceUpdate >= 1.0 else {
                // Still update timestamp to track that we're receiving data
                // This prevents "No recent updates" warning even if UI doesn't change
                lastHeartRateUpdate = now
                return // Skip UI update - too soon, prevents rapid flickering
            }

            // If enough time has passed, check value change threshold
            let valueDiff = abs((previousHeartRate ?? heartRate) - heartRate)

            // More lenient threshold if more time has passed
            let threshold = timeSinceUpdate >= 3.0 ? 1.0 : 2.0

            shouldUpdate = valueDiff >= threshold
        } else {
            // First reading - always update
            shouldUpdate = true
        }

        if shouldUpdate {
            currentHeartRate = heartRate
            lastHeartRateUpdate = now
            previousHeartRate = heartRate
            currentHeartRateZone = zoneClassifier.classifyHeartRate(heartRate, baseline: nil)
            addHeartRateSample(heartRate)
        } else {
            // Even if UI doesn't update, update timestamp to show we're receiving data
            // This prevents "No recent updates" warning
            lastHeartRateUpdate = now
        }
    }

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
    /// HRV is sampled less frequently (every 5 seconds) to optimize for long sessions
    private func addHRVSample(_ sdnn: Double) {
        let now = Date()

        // Dynamic rate limiting based on session duration
        // For sessions longer than 30 minutes, increase interval to 10 seconds
        let sessionDuration = currentSession.map { now.timeIntervalSince($0.startDate) } ?? 0
        let effectiveInterval = sessionDuration > 1800 ? 10.0 : minimumHRVSampleInterval // 30 minutes = 1800 seconds

        // Use HRV-specific rate limiting (5-10 seconds instead of 1 second)
        if let lastTime = lastHRVSampleTime,
           now.timeIntervalSince(lastTime) < effectiveInterval {
            #if os(watchOS)
            // Only log occasionally to avoid spam (every 5th skip roughly)
            let timeSince = now.timeIntervalSince(lastTime)
            if Int(timeSince * 2) % 10 == 0 {
                print("⏭️ HRV sample skipped (rate limited, last: \(String(format: "%.1f", timeSince))s ago, need \(effectiveInterval)s)")
            }
            #endif
            return // Skip this sample - too soon since last one
        }

        guard var session = currentSession else {
            #if os(watchOS)
            print("⚠️ HRV sample skipped (no current session)")
            #endif
            return
        }

        let sample = HRVSample(timestamp: now, sdnn: sdnn)
        session.hrvSamples.append(sample)
        currentSession = session
        lastHRVSampleTime = now

        #if os(watchOS)
        // Log every 10th sample to reduce noise
        if session.hrvSamples.count % 10 == 0 {
            print("✅ HRV sample \(session.hrvSamples.count): \(String(format: "%.1f", sdnn)) ms")
        }
        #endif
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

        // Calculate HRV metrics
        let hrvStart = session.hrvSamples.first?.sdnn
        let hrvEnd = session.hrvSamples.last?.sdnn
        let hrvChange: Double?
        if let start = hrvStart, let end = hrvEnd {
            hrvChange = end - start
        } else {
            hrvChange = nil
        }

        // Calculate average HRV
        let averageHRV: Double?
        if !session.hrvSamples.isEmpty {
            let sum = session.hrvSamples.reduce(0.0) { $0 + $1.sdnn }
            averageHRV = sum / Double(session.hrvSamples.count)
        } else {
            averageHRV = nil
        }

        // Calculate HRV trend (similar to respiratory rate)
        let hrvTrend: SessionSummary.HRVTrend
        if session.hrvSamples.count >= 3 {
            // Split samples into first half and second half
            let midpoint = session.hrvSamples.count / 2
            let firstHalf = session.hrvSamples[..<midpoint]
            let secondHalf = session.hrvSamples[midpoint...]

            let firstHalfAvg = firstHalf.reduce(0.0) { $0 + $1.sdnn } / Double(firstHalf.count)
            let secondHalfAvg = secondHalf.reduce(0.0) { $0 + $1.sdnn } / Double(secondHalf.count)

            let difference = secondHalfAvg - firstHalfAvg
            let threshold = 2.0 // ms threshold for HRV (more sensitive than respiratory rate)

            if difference < -threshold {
                hrvTrend = .decreasing
            } else if difference > threshold {
                hrvTrend = .increasing
            } else {
                hrvTrend = .stable
            }
        } else {
            hrvTrend = .insufficientData
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
            averageHRV: averageHRV,
            hrvTrend: hrvTrend,
            averageRespiratoryRate: averageRespiratoryRate,
            respiratoryRateTrend: respiratoryRateTrend
        )
    }
}

