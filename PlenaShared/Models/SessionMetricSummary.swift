//
//  SessionMetricSummary.swift
//  PlenaShared
//
//  Session-level metric aggregation with zone time fractions
//

import Foundation

/// Represents aggregated metric data for a single meditation session
struct SessionMetricSummary: Identifiable {
    let id: UUID
    let sessionID: UUID
    let date: Date
    let metric: SensorType
    let avgValue: Double
    let zoneFractions: [StressZone: Double] // Fraction of session time in each zone (0.0-1.0)
    let dominantZone: StressZone

    init(
        id: UUID = UUID(),
        sessionID: UUID,
        date: Date,
        metric: SensorType,
        avgValue: Double,
        zoneFractions: [StressZone: Double],
        dominantZone: StressZone
    ) {
        self.id = id
        self.sessionID = sessionID
        self.date = date
        self.metric = metric
        self.avgValue = avgValue
        self.zoneFractions = zoneFractions
        self.dominantZone = dominantZone
    }
}









