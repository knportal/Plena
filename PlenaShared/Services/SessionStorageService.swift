//
//  SessionStorageService.swift
//  PlenaShared
//
//  Created on [Date]
//

import Foundation

protocol SessionStorageServiceProtocol {
    func saveSession(_ session: MeditationSession) throws
    func loadAllSessions() throws -> [MeditationSession]
    func deleteSession(_ session: MeditationSession) throws
    func loadSessions(startDate: Date, endDate: Date) throws -> [MeditationSession]
    /// Loads sessions without sample data to reduce memory usage. Use for statistics/aggregation views.
    func loadSessionsWithoutSamples(startDate: Date, endDate: Date) throws -> [MeditationSession]
}

class SessionStorageService: SessionStorageServiceProtocol {
    private let fileName = "meditation_sessions.json"

    private var fileURL: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent(fileName)
    }

    func saveSession(_ session: MeditationSession) throws {
        var sessions = try loadAllSessions()

        // Remove existing session if it has the same ID (update)
        sessions.removeAll { $0.id == session.id }

        // Add the new/updated session
        sessions.append(session)

        // Sort by start date (newest first)
        sessions.sort { $0.startDate > $1.startDate }

        // Save to file
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(sessions)
        try data.write(to: fileURL, options: .atomic)
    }

    func loadAllSessions() throws -> [MeditationSession] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }

        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([MeditationSession].self, from: data)
    }

    func deleteSession(_ session: MeditationSession) throws {
        var sessions = try loadAllSessions()
        sessions.removeAll { $0.id == session.id }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(sessions)
        try data.write(to: fileURL, options: .atomic)
    }

    func loadSessions(startDate: Date, endDate: Date) throws -> [MeditationSession] {
        // Load all sessions and filter by date range
        let allSessions = try loadAllSessions()
        return allSessions.filter { session in
            session.startDate >= startDate && session.startDate <= endDate
        }
    }

    func loadSessionsWithoutSamples(startDate: Date, endDate: Date) throws -> [MeditationSession] {
        // Load all sessions and filter by date range, then clear sample arrays
        let allSessions = try loadAllSessions()
        return allSessions.filter { session in
            session.startDate >= startDate && session.startDate <= endDate
        }.map { session in
            var lightweight = session
            // Clear all sample arrays to save memory
            lightweight.heartRateSamples = []
            lightweight.hrvSamples = []
            lightweight.respiratoryRateSamples = []
            lightweight.vo2MaxSamples = []
            lightweight.temperatureSamples = []
            lightweight.stateOfMindLogs = []
            return lightweight
        }
    }
}

