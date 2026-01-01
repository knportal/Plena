//
//  SessionSyncPackage.swift
//  PlenaShared
//
//  Created on [Date]
//

import Foundation

/// Package containing complete session data for post-session transfer from Watch to iPhone
struct SessionSyncPackage: Codable {
    let sessionId: UUID
    let startDate: Date
    let endDate: Date
    let duration: TimeInterval

    // Sensor data samples
    let heartRateSamples: [HeartRateSample]
    let hrvSamples: [HRVSample]
    let respiratoryRateSamples: [RespiratoryRateSample]
    let vo2MaxSamples: [VO2MaxSample]
    let temperatureSamples: [TemperatureSample]

    /// Creates a SessionSyncPackage from a MeditationSession
    init(from session: MeditationSession) {
        self.sessionId = session.id
        self.startDate = session.startDate
        self.endDate = session.endDate ?? Date()
        self.duration = session.duration
        self.heartRateSamples = session.heartRateSamples
        self.hrvSamples = session.hrvSamples
        self.respiratoryRateSamples = session.respiratoryRateSamples
        self.vo2MaxSamples = session.vo2MaxSamples
        self.temperatureSamples = session.temperatureSamples
    }

    /// Merges package data into an existing MeditationSession
    func merge(into session: inout MeditationSession) {
        session.heartRateSamples = heartRateSamples
        session.hrvSamples = hrvSamples
        session.respiratoryRateSamples = respiratoryRateSamples
        session.vo2MaxSamples = vo2MaxSamples
        session.temperatureSamples = temperatureSamples
        session.endDate = endDate
    }
}

