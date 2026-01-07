//
//  WorkoutSessionService.swift
//  PlenaShared
//
//  Created on [Date]
//

import Foundation
import HealthKit
import OSLog

#if os(watchOS)
import WatchKit
#endif

/// Callback for workout builder statistics
typealias WorkoutStatisticsHandler = (HKQuantityType, HKStatistics) -> Void

/// Service to manage HKWorkoutSession for triggering active sensor measurements
/// This ensures Apple Watch actively measures HRV and other sensors during Plena sessions
protocol WorkoutSessionServiceProtocol {
    var isActive: Bool { get }
    func startSession() async throws
    func stopSession() async throws

    #if os(watchOS)
    /// Set callback for workout builder statistics
    func setStatisticsHandler(_ handler: @escaping WorkoutStatisticsHandler)
    #endif
}

final class WorkoutSessionService: NSObject, WorkoutSessionServiceProtocol, @unchecked Sendable {
    private let healthStore = HKHealthStore()
    private var workoutSession: HKWorkoutSession?

    #if os(watchOS)
    private var workoutBuilder: HKLiveWorkoutBuilder?
    private var statisticsHandler: WorkoutStatisticsHandler?
    #endif

    private var _isActive: Bool = false

    #if os(watchOS)
    private lazy var sessionDelegate: WorkoutSessionDelegate = {
        WorkoutSessionDelegate()
    }()
    #endif

    override init() {
        super.init()
    }

    #if os(watchOS)
    /// Set callback for workout builder statistics
    func setStatisticsHandler(_ handler: @escaping WorkoutStatisticsHandler) {
        self.statisticsHandler = handler
    }
    #endif

    var isActive: Bool {
        #if os(watchOS)
        if let session = workoutSession {
            return session.state == .running || session.state == .paused
        }
        return _isActive
        #else
        // On iOS, we track it ourselves since we can't directly check watch session state
        return _isActive
        #endif
    }

    /// Starts a workout session to trigger active sensor measurements
    /// This ensures Apple Watch measures HRV, heart rate, and other sensors during the session
    func startSession() async throws {
        guard !isActive else {
            print("⚠️ Workout session already active")
            return
        }

        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }

        // Request authorization for workout data
        // Include all sensors we track to ensure active measurements during the session
        let typesToShare: Set<HKSampleType> = [
            HKObjectType.workoutType(),
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKQuantityType.quantityType(forIdentifier: .respiratoryRate)!,
            HKQuantityType.quantityType(forIdentifier: .bodyTemperature)!
        ]

        let typesToRead: Set<HKObjectType> = [
            HKObjectType.workoutType(),
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKQuantityType.quantityType(forIdentifier: .respiratoryRate)!,
            HKQuantityType.quantityType(forIdentifier: .bodyTemperature)!
        ]

        try await healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead)

        #if os(watchOS)
        // On watchOS, create and start the workout session directly
        print("🏃 Starting workout session on watchOS...")
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .mindAndBody
        configuration.locationType = .indoor

        let session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
        session.delegate = sessionDelegate

        let builder = session.associatedWorkoutBuilder()
        builder.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: configuration)
        builder.delegate = self

        workoutSession = session
        workoutBuilder = builder
        print("✅ Workout session and builder created on watchOS")

        // Add metadata to identify this as a mindful session from Plena
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let metadata: [String: Any] = [
                HKMetadataKeyWorkoutBrandName: "Plena",
                "sessionType": "mindfulness",
                "workoutActivityType": "mindfulness"
            ]

            builder.addMetadata(metadata) { success, error in
                if let error = error {
                    print("⚠️ Error adding workout metadata: \(error)")
                    continuation.resume(throwing: error)
                } else if success {
                    continuation.resume()
                } else {
                    let error = NSError(domain: "WorkoutSessionService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to add workout metadata"])
                    continuation.resume(throwing: error)
                }
            }
        }

        print("🏃 Starting workout activity...")
        session.startActivity(with: Date())
        print("✅ Workout activity started")

        // Begin collection asynchronously
        print("🏃 Beginning workout data collection...")
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            builder.beginCollection(withStart: Date()) { success, error in
                if let error = error {
                    print("⚠️ Error starting workout builder: \(error)")
                    continuation.resume(throwing: error)
                } else if success {
                    print("✅ Workout session fully started - sensors will now actively measure HRV and heart rate")
                    self._isActive = true
                    continuation.resume()
                } else {
                    let error = NSError(domain: "WorkoutSessionService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to start workout builder"])
                    continuation.resume(throwing: error)
                }
            }
        }

        #else
        // On iOS, attempt to launch the watch app into a workout context so the watch can start
        // its HKWorkoutSession without the user manually opening the watch app first.
        // This is best-effort; we still mark active and let WatchConnectivity requests handle the rest.
        #if os(iOS)
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .mindAndBody
        configuration.locationType = .indoor

        print("📱 iPhone: Attempting to start Watch app via HealthKit startWatchApp...")
        let didStartWatchApp = await startWatchAppForWorkout(configuration: configuration)
        if didStartWatchApp {
            print("✅ iPhone: startWatchApp succeeded (watch app should launch and become reachable)")
        } else {
            print("⚠️ iPhone: startWatchApp failed (will rely on WatchConnectivity fallback)")
        }
        #endif

        // iOS can't run the workout session itself; we track locally while watch runs sensors.
        _isActive = true
        print("✅ Workout session marked as active (watch app should start session)")
        #endif
    }

    #if os(iOS)
    /// Best-effort: Ask HealthKit to launch the watch app in a workout context.
    private func startWatchAppForWorkout(configuration: HKWorkoutConfiguration) async -> Bool {
        await withCheckedContinuation { continuation in
            healthStore.startWatchApp(with: configuration) { success, error in
                if let error = error {
                    print("⚠️ iPhone: startWatchApp error: \(error.localizedDescription)")
                }
                continuation.resume(returning: success)
            }
        }
    }
    #endif

    /// Stops the workout session
    func stopSession() async throws {
        guard isActive else {
            print("⚠️ Workout session not active")
            return
        }

        #if os(watchOS)
        if let session = workoutSession {
            session.end()

            // End collection and finish workout asynchronously
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                workoutBuilder?.endCollection(withEnd: Date()) { success, error in
                    if let error = error {
                        print("⚠️ Error ending workout builder: \(error)")
                        continuation.resume(throwing: error)
                        return
                    }

                    print("✅ Workout collection ended")

                    self.workoutBuilder?.finishWorkout { workout, error in
                        if let error = error {
                            print("⚠️ Error finishing workout: \(error)")
                            continuation.resume(throwing: error)
                        } else {
                            print("✅ Workout finished")
                            self._isActive = false
                            continuation.resume()
                        }
                    }
                }
            }
        }

        workoutSession = nil
        workoutBuilder = nil
        statisticsHandler = nil

        #else
        // On iOS, mark as inactive
        _isActive = false
        print("✅ Workout session marked as inactive")
        #endif
    }

    // MARK: - HKLiveWorkoutBuilderDelegate

    #if os(watchOS)
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        print("📊 Workout builder collected data types: \(collectedTypes.map { $0.identifier })")

        // Process each collected type
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else { continue }

            // Get statistics for this type
            guard let statistics = workoutBuilder.statistics(for: quantityType) else {
                continue
            }

            // Log which statistics were collected
            let identifier = quantityType.identifier
            print("📊 Statistics collected for \(identifier)")

            // Forward to handler if set
            statisticsHandler?(quantityType, statistics)

            // Extract and log specific statistics based on type
            switch identifier {
            case HKQuantityTypeIdentifier.heartRate.rawValue:
                if let mostRecent = statistics.mostRecentQuantity() {
                    let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
                    let heartRate = mostRecent.doubleValue(for: heartRateUnit)
                    print("   → Heart Rate: \(String(format: "%.1f", heartRate)) BPM")
                }
                if let average = statistics.averageQuantity() {
                    let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
                    let avgHR = average.doubleValue(for: heartRateUnit)
                    print("   → Average Heart Rate: \(String(format: "%.1f", avgHR)) BPM")
                }

            case HKQuantityTypeIdentifier.heartRateVariabilitySDNN.rawValue:
                if let mostRecent = statistics.mostRecentQuantity() {
                    let hrvUnit = HKUnit.secondUnit(with: .milli)
                    let hrv = mostRecent.doubleValue(for: hrvUnit)
                    print("   → HRV (SDNN): \(String(format: "%.1f", hrv)) ms")
                }

            case HKQuantityTypeIdentifier.respiratoryRate.rawValue:
                if let mostRecent = statistics.mostRecentQuantity() {
                    let respiratoryUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
                    let rate = mostRecent.doubleValue(for: respiratoryUnit)
                    print("   → Respiratory Rate: \(String(format: "%.1f", rate)) /min")
                }

            default:
                print("   → Other statistic type: \(identifier)")
            }
        }
    }

    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        // Handle workout events if needed
        print("📊 Workout builder collected event")
    }
    #endif
}

#if os(watchOS)
// MARK: - HKLiveWorkoutBuilderDelegate Conformance
extension WorkoutSessionService: HKLiveWorkoutBuilderDelegate {
    // Protocol conformance is implemented in the main class body above
    // This extension declaration makes the conformance explicit for watchOS
}
#endif

#if os(watchOS)
/// Delegate for HKWorkoutSession to handle state changes
private class WorkoutSessionDelegate: NSObject, HKWorkoutSessionDelegate {
    // MARK: - Logging
    private let logger = Logger(subsystem: "com.plena.app", category: "WorkoutSession")

    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        print("🔄 Workout session state changed: \(fromState) -> \(toState)")
        logger.debug("Workout session state changed - from: \(String(describing: fromState)), to: \(String(describing: toState)), stateRawValue: \(toState.rawValue)")
    }

    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("❌ Workout session error: \(error)")
        logger.error("Workout session error: \(error.localizedDescription)")
    }
}
#endif

