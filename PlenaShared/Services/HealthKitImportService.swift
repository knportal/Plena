//
//  HealthKitImportService.swift
//  PlenaShared
//
//  Service for importing historical HealthKit data
//

import Foundation
import HealthKit

protocol HealthKitImportServiceProtocol {
    func fetchHistoricalHeartRate(
        startDate: Date,
        endDate: Date,
        completion: @escaping (Result<[HeartRateSample], Error>) -> Void
    )

    func fetchHistoricalHRV(
        startDate: Date,
        endDate: Date,
        completion: @escaping (Result<[HRVSample], Error>) -> Void
    )

    func fetchHistoricalRespiratoryRate(
        startDate: Date,
        endDate: Date,
        completion: @escaping (Result<[RespiratoryRateSample], Error>) -> Void
    )

    func detectPotentialMeditationSessions(
        startDate: Date,
        endDate: Date,
        minimumDuration: TimeInterval,
        completion: @escaping (Result<[DateRange], Error>) -> Void
    )
}

struct DateRange {
    let startDate: Date
    let endDate: Date
}

class HealthKitImportService: HealthKitImportServiceProtocol {
    private let healthStore = HKHealthStore()

    private let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
    private let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
    private let respiratoryRateType = HKQuantityType.quantityType(forIdentifier: .respiratoryRate)!

    // MARK: - Historical Data Fetching

    func fetchHistoricalHeartRate(
        startDate: Date,
        endDate: Date,
        completion: @escaping (Result<[HeartRateSample], Error>) -> Void
    ) {
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        let query = HKSampleQuery(
            sampleType: heartRateType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [sortDescriptor]
        ) { _, samples, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let samples = samples as? [HKQuantitySample] else {
                completion(.success([]))
                return
            }

            let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
            let heartRateSamples = samples.map { sample in
                HeartRateSample(
                    timestamp: sample.startDate,
                    value: sample.quantity.doubleValue(for: heartRateUnit)
                )
            }

            completion(.success(heartRateSamples))
        }

        healthStore.execute(query)
    }

    func fetchHistoricalHRV(
        startDate: Date,
        endDate: Date,
        completion: @escaping (Result<[HRVSample], Error>) -> Void
    ) {
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        let query = HKSampleQuery(
            sampleType: hrvType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [sortDescriptor]
        ) { _, samples, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let samples = samples as? [HKQuantitySample] else {
                completion(.success([]))
                return
            }

            let hrvUnit = HKUnit.secondUnit(with: .milli)
            let hrvSamples = samples.map { sample in
                HRVSample(
                    timestamp: sample.startDate,
                    sdnn: sample.quantity.doubleValue(for: hrvUnit)
                )
            }

            completion(.success(hrvSamples))
        }

        healthStore.execute(query)
    }

    func fetchHistoricalRespiratoryRate(
        startDate: Date,
        endDate: Date,
        completion: @escaping (Result<[RespiratoryRateSample], Error>) -> Void
    ) {
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        let query = HKSampleQuery(
            sampleType: respiratoryRateType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [sortDescriptor]
        ) { _, samples, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let samples = samples as? [HKQuantitySample] else {
                completion(.success([]))
                return
            }

            let respiratoryUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
            let respiratorySamples = samples.map { sample in
                RespiratoryRateSample(
                    timestamp: sample.startDate,
                    value: sample.quantity.doubleValue(for: respiratoryUnit)
                )
            }

            completion(.success(respiratorySamples))
        }

        healthStore.execute(query)
    }

    // MARK: - Meditation Session Detection

    /// Detects potential meditation sessions based on heart rate patterns
    /// Looks for periods with lower heart rate variability and consistent patterns
    func detectPotentialMeditationSessions(
        startDate: Date,
        endDate: Date,
        minimumDuration: TimeInterval = 600, // 10 minutes default
        completion: @escaping (Result<[DateRange], Error>) -> Void
    ) {
        // Fetch HRV data to identify meditation periods
        fetchHistoricalHRV(startDate: startDate, endDate: endDate) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let hrvSamples):
                // Group HRV samples into potential sessions
                // Simple heuristic: periods with consistent HRV readings
                let sessions = self.groupSamplesIntoPotentialSessions(
                    samples: hrvSamples,
                    minimumDuration: minimumDuration
                )
                completion(.success(sessions))

            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func groupSamplesIntoPotentialSessions(
        samples: [HRVSample],
        minimumDuration: TimeInterval
    ) -> [DateRange] {
        guard !samples.isEmpty else { return [] }

        var sessions: [DateRange] = []
        var currentSessionStart: Date?
        var lastSampleTime: Date?

        // Sort by timestamp
        let sortedSamples = samples.sorted { $0.timestamp < $1.timestamp }

        for sample in sortedSamples {
            if let start = currentSessionStart {
                // Check if gap is too large (more than 5 minutes = new session)
                if let lastTime = lastSampleTime,
                   sample.timestamp.timeIntervalSince(lastTime) > 300 {
                    // End current session if it meets minimum duration
                    if let endTime = lastSampleTime,
                       endTime.timeIntervalSince(start) >= minimumDuration {
                        sessions.append(DateRange(startDate: start, endDate: endTime))
                    }
                    currentSessionStart = sample.timestamp
                }
            } else {
                currentSessionStart = sample.timestamp
            }

            lastSampleTime = sample.timestamp
        }

        // Close final session if it meets minimum duration
        if let start = currentSessionStart,
           let end = lastSampleTime,
           end.timeIntervalSince(start) >= minimumDuration {
            sessions.append(DateRange(startDate: start, endDate: end))
        }

        return sessions
    }
}


