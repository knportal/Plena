//
//  HealthKitService.swift
//  PlenaShared
//
//  Created on [Date]
//

import Foundation
import HealthKit
#if os(iOS)
import UIKit
#endif

// Callback types for real-time data
typealias HeartRateHandler = (Double) -> Void
typealias HRVHandler = (Double) -> Void
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
        let query = HKAnchoredObjectQuery(
            type: heartRateType,
            predicate: nil,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { query, samples, deletedObjects, anchor, error in
            guard let samples = samples as? [HKQuantitySample] else {
                if let error = error {
                    print("Heart rate query error: \(error)")
                }
                return
            }

            // Process the most recent sample
            if let latestSample = samples.last {
                let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
                let heartRate = latestSample.quantity.doubleValue(for: heartRateUnit)
                handler(heartRate)
            }
        }

        // Update handler for continuous updates
        query.updateHandler = { query, samples, deletedObjects, anchor, error in
            guard let samples = samples as? [HKQuantitySample] else {
                if let error = error {
                    print("Heart rate update error: \(error)")
                }
                return
            }

            if let latestSample = samples.last {
                let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
                let heartRate = latestSample.quantity.doubleValue(for: heartRateUnit)
                handler(heartRate)
            }
        }

        heartRateQuery = query
        healthStore.execute(query)
    }

    func startHRVQuery(handler: @escaping HRVHandler) throws {
        // Stop existing query if any
        if let existingQuery = hrvQuery {
            healthStore.stop(existingQuery)
        }

        // Create anchored query for real-time updates
        let query = HKAnchoredObjectQuery(
            type: hrvType,
            predicate: nil,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { query, samples, deletedObjects, anchor, error in
            guard let samples = samples as? [HKQuantitySample] else {
                if let error = error {
                    print("HRV query error: \(error)")
                }
                return
            }

            // Process the most recent sample
            if let latestSample = samples.last {
                let hrvUnit = HKUnit.secondUnit(with: .milli)
                let sdnn = latestSample.quantity.doubleValue(for: hrvUnit)
                handler(sdnn)
            }
        }

        // Update handler for continuous updates
        query.updateHandler = { query, samples, deletedObjects, anchor, error in
            guard let samples = samples as? [HKQuantitySample] else {
                if let error = error {
                    print("HRV update error: \(error)")
                }
                return
            }

            if let latestSample = samples.last {
                let hrvUnit = HKUnit.secondUnit(with: .milli)
                let sdnn = latestSample.quantity.doubleValue(for: hrvUnit)
                handler(sdnn)
            }
        }

        hrvQuery = query
        healthStore.execute(query)
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
    /// Returns nil if no data is available
    func fetchLatestHeartRate() async throws -> Double? {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }

        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierEndDate,
            ascending: false
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: heartRateType,
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

                let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
                let heartRate = sample.quantity.doubleValue(for: heartRateUnit)
                continuation.resume(returning: heartRate)
            }

            healthStore.execute(query)
        }
    }

    /// Fetches the most recent HRV value from HealthKit
    /// Returns nil if no data is available
    func fetchLatestHRV() async throws -> Double? {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }

        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierEndDate,
            ascending: false
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: hrvType,
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

                let hrvUnit = HKUnit.secondUnit(with: .milli)
                let sdnn = sample.quantity.doubleValue(for: hrvUnit)
                continuation.resume(returning: sdnn)
            }

            healthStore.execute(query)
        }
    }

    /// Fetches the most recent respiratory rate value from HealthKit
    /// Returns nil if no data is available
    func fetchLatestRespiratoryRate() async throws -> Double? {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }

        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierEndDate,
            ascending: false
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: respiratoryRateType,
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

        // Fetch immediately
        Task {
            if let heartRate = try? await fetchLatestHeartRate() {
                handler(heartRate)
            }
        }

        // Set up periodic fetching
        periodicHeartRateTask = Task {
            while !Task.isCancelled {
                do {
                    try await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                    if let heartRate = try? await fetchLatestHeartRate() {
                        handler(heartRate)
                    }
                } catch {
                    // Task was cancelled or sleep interrupted
                    break
                }
            }
        }
    }

    /// Starts a periodic query for HRV that fetches the latest value at specified intervals
    /// Useful as a fallback when real-time anchored queries don't provide frequent updates
    func startPeriodicHRVQuery(interval: TimeInterval, handler: @escaping HRVHandler) throws {
        // Cancel existing periodic task if any
        periodicHRVTask?.cancel()

        // Fetch immediately
        Task {
            if let hrv = try? await fetchLatestHRV() {
                handler(hrv)
            }
        }

        // Set up periodic fetching
        periodicHRVTask = Task {
            while !Task.isCancelled {
                do {
                    try await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                    if let hrv = try? await fetchLatestHRV() {
                        handler(hrv)
                    }
                } catch {
                    // Task was cancelled or sleep interrupted
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
        if let query = heartRateQuery {
            healthStore.stop(query)
            heartRateQuery = nil
        }
        if let query = hrvQuery {
            healthStore.stop(query)
            hrvQuery = nil
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
                "sessionType": "meditation"
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

