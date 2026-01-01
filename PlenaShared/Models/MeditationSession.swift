//
//  MeditationSession.swift
//  PlenaShared
//
//  Created on [Date]
//

import Foundation

// Session diagnostic metadata for analytics
struct SessionMetadata: Codable {
    var hrvSampleCount: Int = 0
    var hrvDataAvailable: Bool = false
    var durationSeconds: Int = 0
    var watchModel: String?
    var deviceType: String? // "watch" or "iphone"
    var hrvQueryStarted: Bool = false
    var hrvInitialCallbackReceived: Bool = false
    var hrvUpdateCallbacksReceived: Int = 0
    var hrvPeriodicQueriesSuccessful: Int = 0
    var hrvPostWorkoutSamplesFound: Int = 0
}

struct MeditationSession: Identifiable, Codable {
    let id: UUID
    let startDate: Date
    var endDate: Date?

    var duration: TimeInterval {
        let end = endDate ?? Date()
        return end.timeIntervalSince(startDate)
    }

    enum CodingKeys: String, CodingKey {
        case id, startDate, endDate
        case heartRateSamples, hrvSamples, respiratoryRateSamples
        case vo2MaxSamples, temperatureSamples, stateOfMindLogs
        case metadata
    }

    // Sensor data
    var heartRateSamples: [HeartRateSample] = []
    var hrvSamples: [HRVSample] = []
    var respiratoryRateSamples: [RespiratoryRateSample] = []
    var vo2MaxSamples: [VO2MaxSample] = []
    var temperatureSamples: [TemperatureSample] = []
    var stateOfMindLogs: [StateOfMindLog] = []

    // Diagnostic metadata for analytics
    var metadata: SessionMetadata?

    init(id: UUID = UUID(), startDate: Date = Date()) {
        self.id = id
        self.startDate = startDate
        self.metadata = SessionMetadata()
    }
}


