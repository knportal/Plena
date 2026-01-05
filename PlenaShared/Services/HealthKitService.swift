//
//  HealthKitService.swift
//  PlenaShared
//
//  Created on [Date]
//

import Foundation
import HealthKit
import OSLog
#if os(iOS)
import UIKit
#endif

// MARK: - Logging
private let logger = Logger(subsystem: "com.plena.app", category: "HealthKit")

// Callback types for real-time data
typealias HeartRateHandler = (Double) -> Void
typealias HRVHandler = (Double, Date) -> Void  // (sdnn, timestamp)
typealias RespiratoryRateHandler = (Double) -> Void
typealias VO2MaxHandler = (Double) -> Void
typealias TemperatureHandler = (Double) -> Void

// Represents a mindful session from HealthKit
struct MindfulSession {
    let startDate: Date
    let endDate: Date
    var duration: TimeInterval {
        endDate.timeIntervalSince(startDate)
    }
}

// Represents sleep analysis data from HealthKit
struct SleepAnalysis {
    let startDate: Date
    let endDate: Date
    let value: HKCategoryValueSleepAnalysis

    var duration: TimeInterval {
        endDate.timeIntervalSince(startDate)
    }

    var durationInHours: Double {
        duration / 3600.0
    }
}

protocol HealthKitServiceProtocol {
    func requestAuthorization() async throws
    func startHeartRateQuery(handler: @escaping HeartRateHandler) throws
    func startHRVQuery(handler: @escaping HRVHandler) throws
    func startRespiratoryRateQuery(handler: @escaping RespiratoryRateHandler) throws
    func startVO2MaxQuery(handler: @escaping VO2MaxHandler) throws
    func startTemperatureQuery(handler: @escaping TemperatureHandler) throws
    func stopAllQueries()

    // Baseline and periodic queries
    func fetchLatestVO2Max() async throws -> Double?
    func fetchLatestTemperature() async throws -> Double?
    func fetchLatestHeartRate() async throws -> Double?
    func fetchLatestHRV() async throws -> Double?
    func fetchHRVSamples(startDate: Date, endDate: Date) async throws -> [Double]
    func fetchLatestRespiratoryRate() async throws -> Double?
    func startPeriodicVO2MaxQuery(interval: TimeInterval, handler: @escaping VO2MaxHandler) throws
    func startPeriodicTemperatureQuery(interval: TimeInterval, handler: @escaping TemperatureHandler) throws
    func startPeriodicHeartRateQuery(interval: TimeInterval, handler: @escaping HeartRateHandler) throws
    func startPeriodicHRVQuery(interval: TimeInterval, handler: @escaping HRVHandler) throws
    func startPeriodicRespiratoryRateQuery(interval: TimeInterval, handler: @escaping RespiratoryRateHandler) throws

    // Meditation session tracking methods
    func saveMindfulSession(startDate: Date, endDate: Date) async throws
    func fetchMindfulSessions(startDate: Date, endDate: Date) async throws -> [MindfulSession]

    // Sleep analysis methods
    func fetchSleepAnalysis(startDate: Date, endDate: Date) async throws -> [SleepAnalysis]
    func fetchSleepForDate(_ date: Date) async throws -> SleepAnalysis?
}

class HealthKitService: HealthKitServiceProtocol {
    private let healthStore = HKHealthStore()

    // MARK: - HealthKit Types (Safely Initialized)

    // HealthKit types we need - safely initialized with guard statements
    // These are standard HealthKit identifiers that should always be available,
    // but we guard against nil to prevent crashes in edge cases
    private lazy var heartRateType: HKQuantityType = {
        guard let type = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            preconditionFailure("Heart rate type is not available. This indicates a system-level issue with HealthKit.")
        }
        return type
    }()

    private lazy var hrvType: HKQuantityType = {
        guard let type = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else {
            preconditionFailure("HRV type is not available. This indicates a system-level issue with HealthKit.")
        }
        return type
    }()

    private lazy var respiratoryRateType: HKQuantityType = {
        guard let type = HKQuantityType.quantityType(forIdentifier: .respiratoryRate) else {
            preconditionFailure("Respiratory rate type is not available. This indicates a system-level issue with HealthKit.")
        }
        return type
    }()

    private lazy var vo2MaxType: HKQuantityType = {
        guard let type = HKQuantityType.quantityType(forIdentifier: .vo2Max) else {
            preconditionFailure("VO2 Max type is not available. This indicates a system-level issue with HealthKit.")
        }
        return type
    }()

    private lazy var bodyTemperatureType: HKQuantityType = {
        guard let type = HKQuantityType.quantityType(forIdentifier: .bodyTemperature) else {
            preconditionFailure("Body temperature type is not available. This indicates a system-level issue with HealthKit.")
        }
        return type
    }()

    private lazy var mindfulSessionType: HKCategoryType = {
        guard let type = HKCategoryType.categoryType(forIdentifier: .mindfulSession) else {
            preconditionFailure("Mindful session type is not available. This indicates a system-level issue with HealthKit.")
        }
        return type
    }()

    private lazy var sleepAnalysisType: HKCategoryType = {
        guard let type = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else {
            preconditionFailure("Sleep analysis type is not available. This indicates a system-level issue with HealthKit.")
        }
        return type
    }()

    // Active queries
    private var heartRateQuery: HKAnchoredObjectQuery?
    private var hrvQuery: HKAnchoredObjectQuery?
    private var hrvAnchor: HKQueryAnchor? // Store anchor to avoid reprocessing old samples
    private var respiratoryRateQuery: HKAnchoredObjectQuery?
    private var vo2MaxQuery: HKAnchoredObjectQuery?
    private var temperatureQuery: HKAnchoredObjectQuery?

    // Periodic query tasks
    private var periodicVO2MaxTask: Task<Void, Never>?
    private var periodicTemperatureTask: Task<Void, Never>?
    private var periodicHeartRateTask: Task<Void, Never>?
    private var periodicHRVTask: Task<Void, Never>?
    private var periodicRespiratoryRateTask: Task<Void, Never>?

    var readTypes: Set<HKObjectType> {
        [heartRateType, hrvType, respiratoryRateType, vo2MaxType, bodyTemperatureType, mindfulSessionType, sleepAnalysisType]
    }

    var writeTypes: Set<HKSampleType> {
        [heartRateType, hrvType, respiratoryRateType, mindfulSessionType]
    }

    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("❌ HealthKit is not available on this device")
            throw HealthKitError.notAvailable
        }

        // Check current status before requesting
        let vo2MaxStatus = healthStore.authorizationStatus(for: vo2MaxType)
        let temperatureStatus = healthStore.authorizationStatus(for: bodyTemperatureType)
        let sleepStatus = healthStore.authorizationStatus(for: sleepAnalysisType)

        print("📋 Requesting HealthKit authorization...")
        print("   Current status before request:")
        print("   VO2 Max: \(authorizationStatusString(vo2MaxStatus))")
        print("   Temperature: \(authorizationStatusString(temperatureStatus))")
        print("   Sleep Analysis: \(authorizationStatusString(sleepStatus))")

        try await healthStore.requestAuthorization(toShare: writeTypes, read: readTypes)
        print("✅ HealthKit authorization request completed")

        // Small delay to allow iOS to update authorization status
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

        // Check if we have read authorization for sensor data
        let heartRateStatus = healthStore.authorizationStatus(for: heartRateType)
        let hrvStatus = healthStore.authorizationStatus(for: hrvType)
        let respiratoryStatus = healthStore.authorizationStatus(for: respiratoryRateType)
        // Re-check optional metrics after authorization request
        let vo2MaxStatusAfter = healthStore.authorizationStatus(for: vo2MaxType)
        let temperatureStatusAfter = healthStore.authorizationStatus(for: bodyTemperatureType)
        let sleepStatusAfter = healthStore.authorizationStatus(for: sleepAnalysisType)

        // Log all authorization statuses for debugging
        print("📊 Authorization Statuses:")
        print("   Heart Rate: \(heartRateStatus.rawValue) (\(authorizationStatusString(heartRateStatus)))")
        print("   HRV: \(hrvStatus.rawValue) (\(authorizationStatusString(hrvStatus)))")
        print("   Respiratory Rate: \(respiratoryStatus.rawValue) (\(authorizationStatusString(respiratoryStatus)))")

        // Check required permissions first
        // If any required permission is not determined or denied, throw error
        let requiredPermissionsDenied = heartRateStatus == .sharingDenied ||
                                       hrvStatus == .sharingDenied ||
                                       respiratoryStatus == .sharingDenied

        let requiredPermissionsNotDetermined = heartRateStatus == .notDetermined ||
                                              hrvStatus == .notDetermined ||
                                              respiratoryStatus == .notDetermined

        if requiredPermissionsDenied || requiredPermissionsNotDetermined {
            print("❌ Required sensor permissions not authorized")
            print("   Heart Rate: \(authorizationStatusString(heartRateStatus))")
            print("   HRV: \(authorizationStatusString(hrvStatus))")
            print("   Respiratory Rate: \(authorizationStatusString(respiratoryStatus))")

            if requiredPermissionsDenied {
                print("⚠️  Permissions were denied. Please enable in Settings → Privacy & Security → Health → Plena")
            }

            throw HealthKitError.notAuthorized
        }

        // Log optional permissions (only if authorized, to reduce noise)
        if vo2MaxStatusAfter == .sharingAuthorized {
            print("   VO2 Max: \(vo2MaxStatusAfter.rawValue) (\(authorizationStatusString(vo2MaxStatusAfter)))")
        }
        if temperatureStatusAfter == .sharingAuthorized {
            print("   Temperature: \(temperatureStatusAfter.rawValue) (\(authorizationStatusString(temperatureStatusAfter)))")
        }
        if sleepStatusAfter == .sharingAuthorized {
            print("   Sleep Analysis: \(sleepStatusAfter.rawValue) (\(authorizationStatusString(sleepStatusAfter)))")
        }

        print("✅ HealthKit authorization successful")
        // Note: Mindful session write permission may be requested separately by user
        // We don't fail if not yet authorized - it will be requested when saving
    }

    private func authorizationStatusString(_ status: HKAuthorizationStatus) -> String {
        switch status {
        case .notDetermined:
            return "Not Determined"
        case .sharingDenied:
            return "Sharing Denied"
        case .sharingAuthorized:
            return "Sharing Authorized"
        @unknown default:
            return "Unknown (\(status.rawValue))"
        }
    }

    /// Opens the Settings app
    /// This allows users to manually enable permissions that were previously denied
    static func openHealthSettings() {
        #if os(iOS)
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
        #endif
    }

    /// Checks and logs current authorization status without requesting authorization
    /// Useful for checking status after user enables permissions in Settings
    func checkAuthorizationStatus() {
        print("🔍 Checking HealthKit authorization status...")
        print("   HealthKit available: \(HKHealthStore.isHealthDataAvailable())")

        let heartRateStatus = healthStore.authorizationStatus(for: heartRateType)
        let hrvStatus = healthStore.authorizationStatus(for: hrvType)
        let respiratoryStatus = healthStore.authorizationStatus(for: respiratoryRateType)
        let vo2MaxStatus = healthStore.authorizationStatus(for: vo2MaxType)
        let temperatureStatus = healthStore.authorizationStatus(for: bodyTemperatureType)
        let sleepStatus = healthStore.authorizationStatus(for: sleepAnalysisType)

        // Log required permissions (always show)
        print("📊 Current Authorization Statuses:")
        print("   Heart Rate: \(heartRateStatus.rawValue) (\(authorizationStatusString(heartRateStatus)))")
        print("   HRV: \(hrvStatus.rawValue) (\(authorizationStatusString(hrvStatus)))")
        print("   Respiratory Rate: \(respiratoryStatus.rawValue) (\(authorizationStatusString(respiratoryStatus)))")

        // Only log optional permissions if they're authorized (to reduce noise)
        let optionalPermissions: [(String, HKAuthorizationStatus)] = [
            ("VO2 Max", vo2MaxStatus),
            ("Temperature", temperatureStatus),
            ("Sleep Analysis", sleepStatus)
        ]

        let authorizedOptional = optionalPermissions.filter { $0.1 == .sharingAuthorized }
        if !authorizedOptional.isEmpty {
            print("   Optional permissions (authorized):")
            for (name, status) in authorizedOptional {
                print("   \(name): \(status.rawValue) (\(authorizationStatusString(status)))")
            }
        }

        // Only show warning if required permissions are denied
        if heartRateStatus == .sharingDenied || hrvStatus == .sharingDenied || respiratoryStatus == .sharingDenied {
            print("⚠️ Required permissions are denied. App functionality will be limited.")
            print("   Please enable Heart Rate, HRV, and Respiratory Rate in Settings → Privacy & Security → Health → Plena")
        } else {
            print("✅ All required permissions authorized")
        }
    }

    func startHeartRateQuery(handler: @escaping HeartRateHandler) throws {
        // Stop existing query if any
        if let existingQuery = heartRateQuery {
            healthStore.stop(existingQuery)
        }

        // Create anchored query for real-time updates
        // Use a predicate to only get samples from the last 5 minutes to avoid processing historical data
        let now = Date()
        let startDate = now.addingTimeInterval(-300) // Last 5 minutes
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: now,
            options: .strictStartDate
        )

        let query = HKAnchoredObjectQuery(
            type: heartRateType,
            predicate: predicate,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { query, samples, deletedObjects, anchor, error in
            if let error = error {
                print("⚠️ Heart rate query initial error: \(error)")
                return
            }

            guard let samples = samples as? [HKQuantitySample], !samples.isEmpty else {
                print("⚠️ Heart rate query returned no recent samples (initial)")
                return
            }

            print("📊 Heart rate query initial: received \(samples.count) recent sample(s)")

            // Process only recent samples (within last 5 minutes)
            // Since we already filtered at query level (last 5 minutes), we can be more lenient here
            // This ensures we catch samples that might be slightly older but still relevant
            let cutoffDate = Date().addingTimeInterval(-300) // 5 minutes ago
            let recentSamples = samples.filter { $0.endDate >= cutoffDate }

            if recentSamples.isEmpty {
                // Log details about why samples were rejected
                if let oldestSample = samples.first {
                    let oldestAge = Date().timeIntervalSince(oldestSample.endDate)
                    print("⚠️ No samples within last 5 minutes. Oldest sample age: \(String(format: "%.1f", oldestAge))s")
                } else {
                    print("⚠️ No samples within last 5 minutes, waiting for new data...")
                }
                return
            }

            print("   → Processing \(recentSamples.count) sample(s) from last 5 minutes")

            // Process all recent samples, sorted by date
            for sample in recentSamples.sorted(by: { $0.endDate < $1.endDate }) {
                let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
                let heartRate = sample.quantity.doubleValue(for: heartRateUnit)
                let sampleAge = Date().timeIntervalSince(sample.endDate)
                print("   → HR: \(String(format: "%.1f", heartRate)) BPM (age: \(String(format: "%.1f", sampleAge))s)")
                handler(heartRate)
            }
        }

        // Update handler for continuous updates
        query.updateHandler = { query, samples, deletedObjects, anchor, error in
            // #region agent log
            // debugLog("Heart rate anchored query update handler called", data: [
            //     "hypothesisId": "D",
            //     "location": "HealthKitService.swift:361",
            //     "hasError": error != nil,
            //     "sampleCount": (samples as? [HKQuantitySample])?.count ?? 0,
            //     "hasDeletedObjects": deletedObjects != nil && !deletedObjects!.isEmpty
            // ])
            // #endregion agent log
            if let error = error {
                print("⚠️ Heart rate update error: \(error)")
                return
            }

            guard let samples = samples as? [HKQuantitySample], !samples.isEmpty else {
                // #region agent log
                // debugLog("Heart rate anchored query: no samples in update", data: [
                //     "hypothesisId": "D",
                //     "location": "HealthKitService.swift:367"
                // ])
                // #endregion agent log
                print("⚠️ Heart rate query returned no samples")
                return
            }

            print("📊 Heart rate query received \(samples.count) sample(s)")

            // Process all new samples to ensure we get every update
            let now = Date()
            for sample in samples.sorted(by: { $0.endDate < $1.endDate }) {
                let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
                let heartRate = sample.quantity.doubleValue(for: heartRateUnit)
                let sampleAge = now.timeIntervalSince(sample.endDate)
                print("   → HR: \(String(format: "%.1f", heartRate)) BPM at \(sample.endDate) (age: \(String(format: "%.1f", sampleAge))s)")
                // #region agent log
                // debugLog("Heart rate anchored query: processing sample", data: [
                //     "hypothesisId": "D",
                //     "location": "HealthKitService.swift:376",
                //     "heartRate": heartRate,
                //     "sampleAge": sampleAge,
                //     "sampleEndDate": sample.endDate.timeIntervalSince1970,
                //     "willProcess": sampleAge <= 300
                // ])
                // #endregion agent log

                // Only process samples from the last 5 minutes to avoid processing old data
                if sampleAge <= 300 {
                    print("   ✅ Processing sample (within 5 minutes)")
                    handler(heartRate)
                } else {
                    print("   ⚠️ Skipping sample (too old: \(String(format: "%.1f", sampleAge))s)")
                }
            }
        }

        heartRateQuery = query
        healthStore.execute(query)
        print("✅ Heart rate anchored query started")
    }

    func startHRVQuery(handler: @escaping HRVHandler) throws {
        // Log HRV query start
        logger.debug("startHRVQuery called - hasExistingAnchor: \(self.hrvAnchor != nil), hasExistingQuery: \(self.hrvQuery != nil)")

        // Stop existing query if any
        if let existingQuery = hrvQuery {
            healthStore.stop(existingQuery)
        }

        // Clear anchor when starting a new query to avoid reusing stale anchor from previous session
        // The anchor should only persist within a single session, not across sessions
        hrvAnchor = nil

        // Create anchored query for real-time updates
        // HRV samples can be written during or after the workout session
        // Use a more lenient predicate - check last 30 minutes to catch samples
        // that might be written with a delay
        let now = Date()
        let startDate = now.addingTimeInterval(-60 * 30) // Last 30 minutes (more lenient)
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: nil,
            options: [] // Don't use strictStartDate - be more lenient
        )

        // Log HRV query creation
        logger.debug("Creating HRV anchored query - usingAnchor: \(self.hrvAnchor != nil), startDate: \(startDate.timeIntervalSince1970), windowMinutes: 30")

        // Use the stored anchor if available, otherwise start fresh
        // This prevents reprocessing old samples while still getting new ones
        let query = HKAnchoredObjectQuery(
            type: hrvType,
            predicate: predicate,
            anchor: hrvAnchor, // Use stored anchor to avoid reprocessing
            limit: HKObjectQueryNoLimit
        ) { [weak self] query, samples, deletedObjects, anchor, error in
            print("🔍 HRV query INITIAL handler called - samples: \(samples?.count ?? 0), error: \(error?.localizedDescription ?? "none")")

            // Log HRV query initial handler
            let sampleCount = (samples as? [HKQuantitySample])?.count ?? 0
            logger.debug("HRV query initial handler - sampleCount: \(sampleCount), hasError: \(error != nil), hasAnchor: \(anchor != nil)")

            // Store anchor for next query
            if let anchor = anchor {
                self?.hrvAnchor = anchor
            }

            guard let samples = samples as? [HKQuantitySample] else {
                if let error = error {
                    print("❌ HRV query error: \(error)")
                } else {
                    print("⚠️ HRV query initial: no samples returned")
                }
                return
            }

            // Log sample processing
            if sampleCount > 0 {
                let firstSampleDate = samples.first?.endDate.timeIntervalSince1970 ?? 0
                let lastSampleDate = samples.last?.endDate.timeIntervalSince1970 ?? 0
                logger.debug("HRV query processing samples - count: \(sampleCount), firstDate: \(firstSampleDate), lastDate: \(lastSampleDate)")
            }

            // Process all new samples, not just the last one
            // This ensures we get all HRV updates during the workout session
            for sample in samples.sorted(by: { $0.endDate < $1.endDate }) {
                let hrvUnit = HKUnit.secondUnit(with: .milli)
                let sdnn = sample.quantity.doubleValue(for: hrvUnit)
                handler(sdnn, sample.endDate)  // Pass timestamp with value
            }
        }

        // Update handler for continuous updates
        query.updateHandler = { [weak self] query, samples, deletedObjects, anchor, error in
            print("🔍 HRV query UPDATE handler called - samples: \(samples?.count ?? 0), error: \(error?.localizedDescription ?? "none")")

            // Log HRV query update handler
            let sampleCount = (samples as? [HKQuantitySample])?.count ?? 0
            logger.debug("HRV query update handler - sampleCount: \(sampleCount), hasError: \(error != nil), hasAnchor: \(anchor != nil)")

            // Store anchor for next query
            if let anchor = anchor {
                self?.hrvAnchor = anchor
            }

            guard let samples = samples as? [HKQuantitySample] else {
                if let error = error {
                    print("❌ HRV update error: \(error)")
                } else {
                    print("⚠️ HRV query update: no samples returned")
                }
                return
            }

            // Log sample processing
            if sampleCount > 0 {
                let firstSampleDate = samples.first?.endDate.timeIntervalSince1970 ?? 0
                logger.debug("HRV query update processing samples - count: \(sampleCount), firstDate: \(firstSampleDate)")
            }

            // Process all new samples to ensure we get every HRV update
            for sample in samples.sorted(by: { $0.endDate < $1.endDate }) {
                let hrvUnit = HKUnit.secondUnit(with: .milli)
                let sdnn = sample.quantity.doubleValue(for: hrvUnit)
                handler(sdnn, sample.endDate)  // Pass timestamp with value
            }
        }

        hrvQuery = query
        print("🔍 Executing HRV anchored query...")
        healthStore.execute(query)
        print("✅ HRV anchored query execute() completed (with anchor persistence and 10-minute window)")

        // Log query execution
        logger.debug("HRV query executed successfully")
    }

    func startRespiratoryRateQuery(handler: @escaping RespiratoryRateHandler) throws {
        // Stop existing query if any
        if let existingQuery = respiratoryRateQuery {
            healthStore.stop(existingQuery)
        }

        // Create anchored query for real-time updates
        let query = HKAnchoredObjectQuery(
            type: respiratoryRateType,
            predicate: nil,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { query, samples, deletedObjects, anchor, error in
            guard let samples = samples as? [HKQuantitySample] else {
                if let error = error {
                    print("Respiratory rate query error: \(error)")
                }
                return
            }

            // Process the most recent sample
            if let latestSample = samples.last {
                let respiratoryUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
                let rate = latestSample.quantity.doubleValue(for: respiratoryUnit)
                handler(rate)
            }
        }

        // Update handler for continuous updates
        query.updateHandler = { query, samples, deletedObjects, anchor, error in
            guard let samples = samples as? [HKQuantitySample] else {
                if let error = error {
                    print("Respiratory rate update error: \(error)")
                }
                return
            }

            if let latestSample = samples.last {
                let respiratoryUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
                let rate = latestSample.quantity.doubleValue(for: respiratoryUnit)
                handler(rate)
            }
        }

        respiratoryRateQuery = query
        healthStore.execute(query)
    }

    func startVO2MaxQuery(handler: @escaping VO2MaxHandler) throws {
        // Stop existing query if any
        if let existingQuery = vo2MaxQuery {
            healthStore.stop(existingQuery)
        }

        // Note: VO2 Max is typically not measured in real-time during sessions
        // It's usually calculated from workout data. This query will capture
        // the most recent VO2 Max value and any updates during the session.
        let query = HKAnchoredObjectQuery(
            type: vo2MaxType,
            predicate: nil,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { query, samples, deletedObjects, anchor, error in
            guard let samples = samples as? [HKQuantitySample] else {
                if let error = error {
                    print("VO2 Max query error: \(error)")
                }
                return
            }

            // Process the most recent sample
            if let latestSample = samples.last {
                // VO2 Max is measured in mL/(kg·min)
                // HealthKit stores it as mL/kg/min, so we divide by kg and then by min
                let vo2MaxUnit = HKUnit.literUnit(with: .milli)
                    .unitDivided(by: HKUnit.gramUnit(with: .kilo))
                    .unitDivided(by: HKUnit.minute())
                let vo2Max = latestSample.quantity.doubleValue(for: vo2MaxUnit)
                handler(vo2Max)
            }
        }

        // Update handler for continuous updates
        query.updateHandler = { query, samples, deletedObjects, anchor, error in
            guard let samples = samples as? [HKQuantitySample] else {
                if let error = error {
                    print("VO2 Max update error: \(error)")
                }
                return
            }

            if let latestSample = samples.last {
                let vo2MaxUnit = HKUnit.literUnit(with: .milli)
                    .unitDivided(by: HKUnit.gramUnit(with: .kilo))
                    .unitDivided(by: HKUnit.minute())
                let vo2Max = latestSample.quantity.doubleValue(for: vo2MaxUnit)
                handler(vo2Max)
            }
        }

        vo2MaxQuery = query
        healthStore.execute(query)
    }

    func startTemperatureQuery(handler: @escaping TemperatureHandler) throws {
        // Stop existing query if any
        if let existingQuery = temperatureQuery {
            healthStore.stop(existingQuery)
        }

        // Note: Body temperature is typically measured during sleep or specific health events
        // Real-time temperature during meditation may not be available on all devices
        // This query will capture the most recent temperature reading and any updates
        let query = HKAnchoredObjectQuery(
            type: bodyTemperatureType,
            predicate: nil,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { query, samples, deletedObjects, anchor, error in
            guard let samples = samples as? [HKQuantitySample] else {
                if let error = error {
                    print("Body temperature query error: \(error)")
                }
                return
            }

            // Process the most recent sample
            if let latestSample = samples.last {
                // Body temperature is measured in Celsius
                let temperatureUnit = HKUnit.degreeCelsius()
                let temperature = latestSample.quantity.doubleValue(for: temperatureUnit)
                handler(temperature)
            }
        }

        // Update handler for continuous updates
        query.updateHandler = { query, samples, deletedObjects, anchor, error in
            guard let samples = samples as? [HKQuantitySample] else {
                if let error = error {
                    print("Body temperature update error: \(error)")
                }
                return
            }

            if let latestSample = samples.last {
                let temperatureUnit = HKUnit.degreeCelsius()
                let temperature = latestSample.quantity.doubleValue(for: temperatureUnit)
                handler(temperature)
            }
        }

        temperatureQuery = query
        healthStore.execute(query)
    }

    // MARK: - Baseline and Periodic Queries

    /// Fetches the most recent VO2 Max value from HealthKit
    /// Returns nil if no data is available
    func fetchLatestVO2Max() async throws -> Double? {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }

        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierEndDate,
            ascending: false
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: vo2MaxType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }

                let vo2MaxUnit = HKUnit.literUnit(with: .milli)
                    .unitDivided(by: HKUnit.gramUnit(with: .kilo))
                    .unitDivided(by: HKUnit.minute())
                let vo2Max = sample.quantity.doubleValue(for: vo2MaxUnit)
                continuation.resume(returning: vo2Max)
            }

            healthStore.execute(query)
        }
    }

    /// Fetches the most recent body temperature value from HealthKit
    /// Returns nil if no data is available
    func fetchLatestTemperature() async throws -> Double? {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }

        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierEndDate,
            ascending: false
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: bodyTemperatureType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }

                let temperatureUnit = HKUnit.degreeCelsius()
                let temperature = sample.quantity.doubleValue(for: temperatureUnit)
                continuation.resume(returning: temperature)
            }

            healthStore.execute(query)
        }
    }

    /// Fetches the most recent heart rate value from HealthKit
    /// Only returns samples from the last 60 seconds to ensure real-time data
    /// Returns nil if no recent data is available
    func fetchLatestHeartRate() async throws -> Double? {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }

        // Only fetch samples from the last 60 seconds to ensure we get current data
        let now = Date()
        let startDate = now.addingTimeInterval(-60)
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: now,
            options: .strictStartDate
        )

        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierEndDate,
            ascending: false
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: heartRateType,
                predicate: predicate,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    print("⚠️ fetchLatestHeartRate query error: \(error)")
                    continuation.resume(throwing: error)
                    return
                }

                guard let sample = samples?.first as? HKQuantitySample else {
                    // #region agent log
                    // debugLog("fetchLatestHeartRate: No samples found", data: [
                    //     "hypothesisId": "A",
                    //     "location": "HealthKitService.swift:717",
                    //     "queryWindowSeconds": 60,
                    //     "sampleCount": samples?.count ?? 0
                    // ])
                    // #endregion agent log
                    print("⚠️ fetchLatestHeartRate: No samples found in last 60 seconds")
                    continuation.resume(returning: nil)
                    return
                }

                // Accept any sample within the query window (60 seconds)
                // The predicate already filters to last 60 seconds, so any sample returned is valid
                // Apple Watch writes heart rate samples every 5-10 seconds during workouts,
                // so samples up to 60 seconds old are still recent enough to display
                let sampleAge = now.timeIntervalSince(sample.endDate)
                print("📊 fetchLatestHeartRate: Found sample, age: \(String(format: "%.1f", sampleAge))s")
                // #region agent log
                // debugLog("fetchLatestHeartRate: Sample age check", data: [
                //     "hypothesisId": "A",
                //     "location": "HealthKitService.swift:724",
                //     "sampleAge": sampleAge,
                //     "sampleEndDate": sample.endDate.timeIntervalSince1970,
                //     "currentTime": now.timeIntervalSince1970,
                //     "queryWindowSeconds": 60.0,
                //     "willAccept": sampleAge <= 60
                // ])
                // #endregion agent log

                // Accept samples within the query window (60 seconds)
                // No additional age check needed since predicate already filtered
                let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
                let heartRate = sample.quantity.doubleValue(for: heartRateUnit)
                // #region agent log
                // debugLog("fetchLatestHeartRate: Sample accepted", data: [
                //     "hypothesisId": "A",
                //     "location": "HealthKitService.swift:738",
                //     "heartRate": heartRate,
                //     "sampleAge": sampleAge
                // ])
                // #endregion agent log
                continuation.resume(returning: heartRate)
            }

            healthStore.execute(query)
        }
    }

    /// Fetches the most recent HRV value from HealthKit
    /// Only returns samples from the last 5 minutes (HRV updates less frequently)
    /// Returns nil if no recent data is available
    func fetchLatestHRV() async throws -> Double? {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }

        // HRV updates less frequently, so check last 5 minutes
        let now = Date()
        let startDate = now.addingTimeInterval(-300)
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: now,
            options: .strictStartDate
        )

        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierEndDate,
            ascending: false
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: hrvType,
                predicate: predicate,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                print("🔍 fetchLatestHRV callback - found: \(samples?.count ?? 0) samples, error: \(error?.localizedDescription ?? "none")")

                if let error = error {
                    print("❌ fetchLatestHRV error: \(error)")
                    continuation.resume(throwing: error)
                    return
                }

                guard let sample = samples?.first as? HKQuantitySample else {
                    print("⚠️ fetchLatestHRV: No samples in last 5 minutes")
                    continuation.resume(returning: nil)
                    return
                }

                // Accept samples within last 5 minutes (HRV can be written with delays)
                let sampleAge = now.timeIntervalSince(sample.endDate)
                print("🔍 fetchLatestHRV: Sample age: \(String(format: "%.1f", sampleAge))s")

                if sampleAge > 300 { // 5 minutes instead of 2
                    print("⚠️ fetchLatestHRV: Sample too old (\(String(format: "%.1f", sampleAge))s), rejecting")
                    continuation.resume(returning: nil)
                    return
                }

                let hrvUnit = HKUnit.secondUnit(with: .milli)
                let sdnn = sample.quantity.doubleValue(for: hrvUnit)
                print("✅ fetchLatestHRV: Returning value: \(String(format: "%.1f", sdnn)) ms")
                continuation.resume(returning: sdnn)
            }

            print("🔍 Executing fetchLatestHRV query...")
            healthStore.execute(query)
        }
    }

    /// Fetches all HRV samples from a specific time range
    /// Useful for post-workout queries when HRV samples may be written after the workout ends
    func fetchHRVSamples(startDate: Date, endDate: Date) async throws -> [Double] {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }

        // Extend the end date by 2 minutes to catch samples written after workout ends
        let extendedEndDate = endDate.addingTimeInterval(120)
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: extendedEndDate,
            options: []
        )

        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierEndDate,
            ascending: true
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: hrvType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                print("🔍 fetchHRVSamples callback - found: \(samples?.count ?? 0) samples, error: \(error?.localizedDescription ?? "none")")

                if let error = error {
                    print("❌ fetchHRVSamples error: \(error)")
                    continuation.resume(throwing: error)
                    return
                }

                guard let samples = samples as? [HKQuantitySample] else {
                    print("⚠️ fetchHRVSamples: No samples found in range")
                    continuation.resume(returning: [])
                    return
                }

                let hrvUnit = HKUnit.secondUnit(with: .milli)
                let hrvValues = samples.map { sample in
                    sample.quantity.doubleValue(for: hrvUnit)
                }

                print("✅ fetchHRVSamples: Returning \(hrvValues.count) HRV values")
                continuation.resume(returning: hrvValues)
            }

            print("🔍 Executing fetchHRVSamples query (start: \(startDate), end: \(extendedEndDate))...")
            healthStore.execute(query)
        }
    }

    /// Fetches the most recent respiratory rate value from HealthKit
    /// Only returns samples from the last 5 minutes
    /// Returns nil if no recent data is available
    func fetchLatestRespiratoryRate() async throws -> Double? {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }

        // Respiratory rate updates less frequently, so check last 5 minutes
        let now = Date()
        let startDate = now.addingTimeInterval(-300)
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: now,
            options: .strictStartDate
        )

        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierEndDate,
            ascending: false
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: respiratoryRateType,
                predicate: predicate,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }

                // Double-check that the sample is recent (within last 2 minutes)
                let sampleAge = now.timeIntervalSince(sample.endDate)
                if sampleAge > 120 {
                    continuation.resume(returning: nil)
                    return
                }

                let respiratoryUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
                let rate = sample.quantity.doubleValue(for: respiratoryUnit)
                continuation.resume(returning: rate)
            }

            healthStore.execute(query)
        }
    }

    /// Starts a periodic query for VO2 Max that fetches the latest value at specified intervals
    /// Useful as a fallback when real-time anchored queries don't provide frequent updates
    func startPeriodicVO2MaxQuery(interval: TimeInterval, handler: @escaping VO2MaxHandler) throws {
        // Cancel existing periodic task if any
        periodicVO2MaxTask?.cancel()

        // Fetch immediately
        Task {
            if let vo2Max = try? await fetchLatestVO2Max() {
                handler(vo2Max)
            }
        }

        // Set up periodic fetching
        periodicVO2MaxTask = Task {
            while !Task.isCancelled {
                do {
                    try await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                    if let vo2Max = try? await fetchLatestVO2Max() {
                        handler(vo2Max)
                    }
                } catch {
                    // Task was cancelled or sleep interrupted
                    break
                }
            }
        }
    }

    /// Starts a periodic query for body temperature that fetches the latest value at specified intervals
    /// Useful as a fallback when real-time anchored queries don't provide frequent updates
    func startPeriodicTemperatureQuery(interval: TimeInterval, handler: @escaping TemperatureHandler) throws {
        // Cancel existing periodic task if any
        periodicTemperatureTask?.cancel()

        // Fetch immediately
        Task {
            if let temperature = try? await fetchLatestTemperature() {
                handler(temperature)
            }
        }

        // Set up periodic fetching
        periodicTemperatureTask = Task {
            while !Task.isCancelled {
                do {
                    try await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                    if let temperature = try? await fetchLatestTemperature() {
                        handler(temperature)
                    }
                } catch {
                    // Task was cancelled or sleep interrupted
                    break
                }
            }
        }
    }

    /// Starts a periodic query for heart rate that fetches the latest value at specified intervals
    /// Useful as a fallback when real-time anchored queries don't provide frequent updates
    func startPeriodicHeartRateQuery(interval: TimeInterval, handler: @escaping HeartRateHandler) throws {
        // Cancel existing periodic task if any
        periodicHeartRateTask?.cancel()

        print("✅ Starting periodic heart rate query (interval: \(interval)s)")
        // Fetch immediately
        Task {
            if let heartRate = try? await fetchLatestHeartRate() {
                print("📊 Periodic HR query (initial): \(String(format: "%.1f", heartRate)) BPM")
                handler(heartRate)
            } else {
                print("⚠️ Periodic HR query (initial): No data available")
            }
        }

        // Set up periodic fetching
        periodicHeartRateTask = Task {
            while !Task.isCancelled {
                do {
                    try await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                    if let heartRate = try? await fetchLatestHeartRate() {
                        print("📊 Periodic HR query: \(String(format: "%.1f", heartRate)) BPM")
                        handler(heartRate)
                    } else {
                        print("⚠️ Periodic HR query: No data available")
                    }
                } catch {
                    // Task was cancelled or sleep interrupted
                    print("⚠️ Periodic HR query task cancelled or interrupted: \(error)")
                    break
                }
            }
        }
    }

    /// Starts a periodic query for HRV that fetches the latest value at specified intervals
    /// Useful as a fallback when real-time anchored queries don't provide frequent updates
    func startPeriodicHRVQuery(interval: TimeInterval, handler: @escaping HRVHandler) throws {
        print("🔍 Starting periodic HRV query (interval: \(interval)s)")

        // Cancel existing periodic task if any
        periodicHRVTask?.cancel()

        // Fetch immediately
        Task {
            print("🔍 Periodic HRV: Immediate fetch...")
            if let hrv = try? await fetchLatestHRV() {
                print("✅ Periodic HRV: Immediate value: \(String(format: "%.1f", hrv)) ms")
                handler(hrv, Date())  // Use current time for periodic queries
            } else {
                print("⚠️ Periodic HRV: No immediate value")
            }
        }

        // Set up periodic fetching
        periodicHRVTask = Task {
            print("🔍 Periodic HRV task loop started")
            while !Task.isCancelled {
                do {
                    try await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                    print("🔍 Periodic HRV: Woke up, fetching...")
                    if let hrv = try? await fetchLatestHRV() {
                        print("✅ Periodic HRV: Found value: \(String(format: "%.1f", hrv)) ms")
                        handler(hrv, Date())  // Use current time for periodic queries
                    } else {
                        print("⚠️ Periodic HRV: No value this cycle")
                    }
                } catch {
                    print("🔍 Periodic HRV task ended: \(error)")
                    break
                }
            }
        }
    }

    /// Starts a periodic query for respiratory rate that fetches the latest value at specified intervals
    /// Useful as a fallback when real-time anchored queries don't provide frequent updates
    func startPeriodicRespiratoryRateQuery(interval: TimeInterval, handler: @escaping RespiratoryRateHandler) throws {
        // Cancel existing periodic task if any
        periodicRespiratoryRateTask?.cancel()

        // Fetch immediately
        Task {
            if let rate = try? await fetchLatestRespiratoryRate() {
                handler(rate)
            }
        }

        // Set up periodic fetching
        periodicRespiratoryRateTask = Task {
            while !Task.isCancelled {
                do {
                    try await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                    if let rate = try? await fetchLatestRespiratoryRate() {
                        handler(rate)
                    }
                } catch {
                    // Task was cancelled or sleep interrupted
                    break
                }
            }
        }
    }

    func stopAllQueries() {
        print("🛑 Stopping all HealthKit queries...")
        if let query = heartRateQuery {
            healthStore.stop(query)
            heartRateQuery = nil
            print("   → Heart rate query stopped")
        }
        if let query = hrvQuery {
            healthStore.stop(query)
            hrvQuery = nil
            // Clear anchor when stopping to avoid reusing stale anchor in next session
            hrvAnchor = nil
            print("   → HRV query stopped (anchor cleared)")
        }
        if let query = respiratoryRateQuery {
            healthStore.stop(query)
            respiratoryRateQuery = nil
        }
        if let query = vo2MaxQuery {
            healthStore.stop(query)
            vo2MaxQuery = nil
        }
        if let query = temperatureQuery {
            healthStore.stop(query)
            temperatureQuery = nil
        }

        // Cancel periodic tasks
        periodicVO2MaxTask?.cancel()
        periodicVO2MaxTask = nil
        periodicTemperatureTask?.cancel()
        periodicTemperatureTask = nil
        periodicHeartRateTask?.cancel()
        periodicHeartRateTask = nil
        periodicHRVTask?.cancel()
        periodicHRVTask = nil
        periodicRespiratoryRateTask?.cancel()
        periodicRespiratoryRateTask = nil
    }

    // MARK: - Meditation Session Tracking

    /// Saves a mindful session to HealthKit
    /// This marks the time period in HealthKit for trend tracking
    func saveMindfulSession(startDate: Date, endDate: Date) async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }

        // Ensure we have write authorization
        var status = healthStore.authorizationStatus(for: mindfulSessionType)
        if status != .sharingAuthorized {
            // Request authorization if needed
            try await requestAuthorization()
            // Check status again after requesting
            status = healthStore.authorizationStatus(for: mindfulSessionType)
        }

        guard status == .sharingAuthorized else {
            throw HealthKitError.notAuthorized
        }

        // Create category sample for mindful session
        // Category samples use .notApplicable as the value - the duration is in the date range
        let mindfulSample = HKCategorySample(
            type: mindfulSessionType,
            value: HKCategoryValue.notApplicable.rawValue,
            start: startDate,
            end: endDate,
            metadata: [
                HKMetadataKeyWorkoutBrandName: "Plena",
                "sessionType": "mindfulness"
            ]
        )

        try await healthStore.save(mindfulSample)
    }

    /// Fetches historical mindful sessions from HealthKit
    /// Returns all mindful sessions within the specified date range
    func fetchMindfulSessions(startDate: Date, endDate: Date) async throws -> [MindfulSession] {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }

        // Create predicate for date range
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )

        // Create sort descriptor to order by start date
        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierStartDate,
            ascending: true
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: mindfulSessionType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let samples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: [])
                    return
                }

                // Convert HealthKit samples to MindfulSession structs
                let mindfulSessions = samples.map { sample in
                    MindfulSession(
                        startDate: sample.startDate,
                        endDate: sample.endDate
                    )
                }

                continuation.resume(returning: mindfulSessions)
            }

            healthStore.execute(query)
        }
    }

    // MARK: - Sleep Analysis

    /// Fetches sleep analysis data from HealthKit for the specified date range
    func fetchSleepAnalysis(startDate: Date, endDate: Date) async throws -> [SleepAnalysis] {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }

        // Create predicate for date range
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )

        // Create sort descriptor to order by start date
        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierStartDate,
            ascending: true
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepAnalysisType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let samples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: [])
                    return
                }

                // Convert HealthKit samples to SleepAnalysis structs
                let sleepAnalyses = samples.compactMap { sample -> SleepAnalysis? in
                    guard let sleepValue = HKCategoryValueSleepAnalysis(rawValue: sample.value) else {
                        return nil
                    }
                    return SleepAnalysis(
                        startDate: sample.startDate,
                        endDate: sample.endDate,
                        value: sleepValue
                    )
                }

                continuation.resume(returning: sleepAnalyses)
            }

            healthStore.execute(query)
        }
    }

    /// Fetches sleep data for a specific date (consolidates all sleep periods for that day)
    func fetchSleepForDate(_ date: Date) async throws -> SleepAnalysis? {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else {
            return nil
        }

        // Fetch sleep data for the day (may include periods from previous evening)
        // Also check previous day's evening sleep that might extend into this day
        guard let previousDayStart = calendar.date(byAdding: .day, value: -1, to: dayStart) else {
            return nil
        }

        let sleepPeriods = try await fetchSleepAnalysis(startDate: previousDayStart, endDate: dayEnd)

        // Filter to sleep periods that overlap with the target date
        let relevantPeriods = sleepPeriods.filter { period in
            // Include periods that start or end within the target day
            (period.startDate >= dayStart && period.startDate < dayEnd) ||
            (period.endDate >= dayStart && period.endDate < dayEnd) ||
            (period.startDate < dayStart && period.endDate > dayEnd)
        }

        // Calculate total sleep duration for the day
        var totalDuration: TimeInterval = 0
        var earliestStart = dayEnd
        var latestEnd = dayStart

        for period in relevantPeriods {
            // Calculate the portion of sleep that falls within the target day
            let periodStart = max(period.startDate, dayStart)
            let periodEnd = min(period.endDate, dayEnd)
            let periodDuration = periodEnd.timeIntervalSince(periodStart)

            if periodDuration > 0 {
                totalDuration += periodDuration
                if periodStart < earliestStart {
                    earliestStart = periodStart
                }
                if periodEnd > latestEnd {
                    latestEnd = periodEnd
                }
            }
        }

        guard totalDuration > 0 else {
            return nil
        }

        // Return a consolidated sleep analysis for the day
        return SleepAnalysis(
            startDate: earliestStart,
            endDate: latestEnd,
            value: .asleepUnspecified // Use unspecified as default for consolidated data
        )
    }
}

enum HealthKitError: LocalizedError {
    case notAvailable
    case notAuthorized
    case notImplemented

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "HealthKit is not available on this device"
        case .notAuthorized:
            return "HealthKit authorization was denied"
        case .notImplemented:
            return "Feature not yet implemented"
        }
    }
}

