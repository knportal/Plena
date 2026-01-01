//
//  CoreDataStorageService.swift
//  PlenaShared
//
//  Core Data-based storage service
//

import Foundation
import CoreData

class CoreDataStorageService: SessionStorageServiceProtocol {
    private let coreDataStack: CoreDataStack

    init(coreDataStack: CoreDataStack = .shared) {
        self.coreDataStack = coreDataStack
    }

    func saveSession(_ session: MeditationSession) throws {
        let context = coreDataStack.mainContext

        print("💾 Saving session \(session.id) to Core Data (App Group shared container)")
        print("   Start: \(session.startDate)")
        print("   End: \(session.endDate?.description ?? "nil")")
        print("   Samples: HR=\(session.heartRateSamples.count), HRV=\(session.hrvSamples.count), Resp=\(session.respiratoryRateSamples.count)")

        // Check if session already exists
        let fetchRequest: NSFetchRequest<MeditationSessionEntity> = MeditationSessionEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", session.id as CVarArg)

        let existingSession = try context.fetch(fetchRequest).first

        if let existing = existingSession {
            // Update existing session
            existing.startDate = session.startDate
            existing.endDate = session.endDate

            // Update metadata
            if let metadata = session.metadata {
                existing.hrvSampleCount = Int32(metadata.hrvSampleCount)
                existing.hrvDataAvailable = metadata.hrvDataAvailable
                existing.durationSeconds = Int32(metadata.durationSeconds)
                existing.watchModel = metadata.watchModel
                existing.deviceType = metadata.deviceType
            }

            // Clear existing samples
            if let heartRateSamples = existing.heartRateSamples as? Set<HeartRateSampleEntity> {
                heartRateSamples.forEach { context.delete($0) }
            }
            if let hrvSamples = existing.hrvSamples as? Set<HRVSampleEntity> {
                hrvSamples.forEach { context.delete($0) }
            }
            if let respiratorySamples = existing.respiratoryRateSamples as? Set<RespiratoryRateSampleEntity> {
                respiratorySamples.forEach { context.delete($0) }
            }
            if let vo2MaxSamples = existing.vo2MaxSamples as? Set<VO2MaxSampleEntity> {
                vo2MaxSamples.forEach { context.delete($0) }
            }
            if let temperatureSamples = existing.temperatureSamples as? Set<TemperatureSampleEntity> {
                temperatureSamples.forEach { context.delete($0) }
            }
            if let mindLogs = existing.stateOfMindLogs as? Set<StateOfMindLogEntity> {
                mindLogs.forEach { context.delete($0) }
            }

            // Add new samples
            existing.heartRateSamples = NSSet(array: session.heartRateSamples.map { sample in
                let entity = HeartRateSampleEntity(context: context)
                entity.id = sample.id
                entity.timestamp = sample.timestamp
                entity.value = sample.value
                entity.session = existing
                return entity
            })

            existing.hrvSamples = NSSet(array: session.hrvSamples.map { sample in
                let entity = HRVSampleEntity(context: context)
                entity.id = sample.id
                entity.timestamp = sample.timestamp
                entity.sdnn = sample.sdnn
                entity.session = existing
                return entity
            })

            existing.respiratoryRateSamples = NSSet(array: session.respiratoryRateSamples.map { sample in
                let entity = RespiratoryRateSampleEntity(context: context)
                entity.id = sample.id
                entity.timestamp = sample.timestamp
                entity.value = sample.value
                entity.session = existing
                return entity
            })

            existing.vo2MaxSamples = NSSet(array: session.vo2MaxSamples.map { sample in
                let entity = VO2MaxSampleEntity(context: context)
                entity.id = sample.id
                entity.timestamp = sample.timestamp
                entity.value = sample.value
                entity.session = existing
                return entity
            })

            existing.temperatureSamples = NSSet(array: session.temperatureSamples.map { sample in
                let entity = TemperatureSampleEntity(context: context)
                entity.id = sample.id
                entity.timestamp = sample.timestamp
                entity.value = sample.value
                entity.session = existing
                return entity
            })

            existing.stateOfMindLogs = NSSet(array: session.stateOfMindLogs.map { log in
                let entity = StateOfMindLogEntity(context: context)
                entity.id = log.id
                entity.timestamp = log.timestamp
                entity.rating = Int16(log.rating)
                entity.notes = log.notes
                entity.session = existing
                return entity
            })
        } else {
            // Create new session
            let sessionEntity = MeditationSessionEntity(context: context)
            sessionEntity.id = session.id
            sessionEntity.startDate = session.startDate
            sessionEntity.endDate = session.endDate

            // Store metadata
            if let metadata = session.metadata {
                sessionEntity.hrvSampleCount = Int32(metadata.hrvSampleCount)
                sessionEntity.hrvDataAvailable = metadata.hrvDataAvailable
                sessionEntity.durationSeconds = Int32(metadata.durationSeconds)
                sessionEntity.watchModel = metadata.watchModel
                sessionEntity.deviceType = metadata.deviceType
            }

            // Add samples
            sessionEntity.heartRateSamples = NSSet(array: session.heartRateSamples.map { sample in
                let entity = HeartRateSampleEntity(context: context)
                entity.id = sample.id
                entity.timestamp = sample.timestamp
                entity.value = sample.value
                entity.session = sessionEntity
                return entity
            })

            sessionEntity.hrvSamples = NSSet(array: session.hrvSamples.map { sample in
                let entity = HRVSampleEntity(context: context)
                entity.id = sample.id
                entity.timestamp = sample.timestamp
                entity.sdnn = sample.sdnn
                entity.session = sessionEntity
                return entity
            })

            sessionEntity.respiratoryRateSamples = NSSet(array: session.respiratoryRateSamples.map { sample in
                let entity = RespiratoryRateSampleEntity(context: context)
                entity.id = sample.id
                entity.timestamp = sample.timestamp
                entity.value = sample.value
                entity.session = sessionEntity
                return entity
            })

            sessionEntity.vo2MaxSamples = NSSet(array: session.vo2MaxSamples.map { sample in
                let entity = VO2MaxSampleEntity(context: context)
                entity.id = sample.id
                entity.timestamp = sample.timestamp
                entity.value = sample.value
                entity.session = sessionEntity
                return entity
            })

            sessionEntity.temperatureSamples = NSSet(array: session.temperatureSamples.map { sample in
                let entity = TemperatureSampleEntity(context: context)
                entity.id = sample.id
                entity.timestamp = sample.timestamp
                entity.value = sample.value
                entity.session = sessionEntity
                return entity
            })

            sessionEntity.stateOfMindLogs = NSSet(array: session.stateOfMindLogs.map { log in
                let entity = StateOfMindLogEntity(context: context)
                entity.id = log.id
                entity.timestamp = log.timestamp
                entity.rating = Int16(log.rating)
                entity.notes = log.notes
                entity.session = sessionEntity
                return entity
            })
        }

        try context.save()

        // Post notification to trigger refresh on other app (Watch/iPhone)
        NotificationCenter.default.post(name: .NSPersistentStoreRemoteChange, object: nil)

        print("✅ Session saved successfully to shared container")
    }

    func loadAllSessions() throws -> [MeditationSession] {
        let context = coreDataStack.mainContext
        let fetchRequest: NSFetchRequest<MeditationSessionEntity> = MeditationSessionEntity.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: false)]

        let entities = try context.fetch(fetchRequest)
        return entities.map { $0.toMeditationSession() }
    }

    func loadSessions(startDate: Date, endDate: Date) throws -> [MeditationSession] {
        let context = coreDataStack.mainContext
        let fetchRequest: NSFetchRequest<MeditationSessionEntity> = MeditationSessionEntity.fetchRequest()

        // Filter by date range
        fetchRequest.predicate = NSPredicate(
            format: "startDate >= %@ AND startDate <= %@",
            startDate as NSDate,
            endDate as NSDate
        )
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: false)]

        let entities = try context.fetch(fetchRequest)
        return entities.map { $0.toMeditationSession() }
    }

    func loadSessionsWithoutSamples(startDate: Date, endDate: Date) throws -> [MeditationSession] {
        let context = coreDataStack.mainContext
        let fetchRequest: NSFetchRequest<MeditationSessionEntity> = MeditationSessionEntity.fetchRequest()

        // Filter by date range
        fetchRequest.predicate = NSPredicate(
            format: "startDate >= %@ AND startDate <= %@",
            startDate as NSDate,
            endDate as NSDate
        )
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: false)]

        // Don't fetch relationships to avoid loading sample entities
        fetchRequest.relationshipKeyPathsForPrefetching = []

        let entities = try context.fetch(fetchRequest)
        return entities.map { $0.toMeditationSessionWithoutSamples() }
    }

    func deleteSession(_ session: MeditationSession) throws {
        let context = coreDataStack.mainContext
        let fetchRequest: NSFetchRequest<MeditationSessionEntity> = MeditationSessionEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", session.id as CVarArg)

        if let entity = try context.fetch(fetchRequest).first {
            context.delete(entity)
            try context.save()
        }
    }
}

// MARK: - Entity Extensions

extension MeditationSessionEntity {
    func toMeditationSession() -> MeditationSession {
        var session = MeditationSession(id: id ?? UUID(), startDate: startDate ?? Date())
        session.endDate = endDate

        if let heartRateSet = heartRateSamples as? Set<HeartRateSampleEntity> {
            session.heartRateSamples = heartRateSet.sorted { $0.timestamp ?? Date() < $1.timestamp ?? Date() }
                .map { HeartRateSample(id: $0.id ?? UUID(), timestamp: $0.timestamp ?? Date(), value: $0.value) }
        }

        if let hrvSet = hrvSamples as? Set<HRVSampleEntity> {
            session.hrvSamples = hrvSet.sorted { $0.timestamp ?? Date() < $1.timestamp ?? Date() }
                .map { HRVSample(id: $0.id ?? UUID(), timestamp: $0.timestamp ?? Date(), sdnn: $0.sdnn) }
        }

        if let respiratorySet = respiratoryRateSamples as? Set<RespiratoryRateSampleEntity> {
            session.respiratoryRateSamples = respiratorySet.sorted { $0.timestamp ?? Date() < $1.timestamp ?? Date() }
                .map { RespiratoryRateSample(id: $0.id ?? UUID(), timestamp: $0.timestamp ?? Date(), value: $0.value) }
        }

        if let vo2MaxSet = vo2MaxSamples as? Set<VO2MaxSampleEntity> {
            session.vo2MaxSamples = vo2MaxSet.sorted { $0.timestamp ?? Date() < $1.timestamp ?? Date() }
                .map { VO2MaxSample(id: $0.id ?? UUID(), timestamp: $0.timestamp ?? Date(), value: $0.value) }
        }

        if let temperatureSet = temperatureSamples as? Set<TemperatureSampleEntity> {
            session.temperatureSamples = temperatureSet.sorted { $0.timestamp ?? Date() < $1.timestamp ?? Date() }
                .map { TemperatureSample(id: $0.id ?? UUID(), timestamp: $0.timestamp ?? Date(), value: $0.value) }
        }

        if let logsSet = stateOfMindLogs as? Set<StateOfMindLogEntity> {
            session.stateOfMindLogs = logsSet.sorted { $0.timestamp ?? Date() < $1.timestamp ?? Date() }
                .map { StateOfMindLog(id: $0.id ?? UUID(), timestamp: $0.timestamp ?? Date(), rating: Int($0.rating), notes: $0.notes) }
        }

        return session
    }

    /// Creates a MeditationSession without loading sample data to save memory
    func toMeditationSessionWithoutSamples() -> MeditationSession {
        var session = MeditationSession(id: id ?? UUID(), startDate: startDate ?? Date())
        session.endDate = endDate
        // Intentionally leave all sample arrays empty to save memory
        return session
    }
}

