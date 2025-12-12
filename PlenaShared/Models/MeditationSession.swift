//
//  MeditationSession.swift
//  PlenaShared
//
//  Created on [Date]
//

import Foundation

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
    }

    // Sensor data
    var heartRateSamples: [HeartRateSample] = []
    var hrvSamples: [HRVSample] = []
    var respiratoryRateSamples: [RespiratoryRateSample] = []
    var vo2MaxSamples: [VO2MaxSample] = []
    var temperatureSamples: [TemperatureSample] = []
    var stateOfMindLogs: [StateOfMindLog] = []

    init(id: UUID = UUID(), startDate: Date = Date()) {
        self.id = id
        self.startDate = startDate
    }
}


