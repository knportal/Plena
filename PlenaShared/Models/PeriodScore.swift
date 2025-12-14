//
//  PeriodScore.swift
//  PlenaShared
//
//  Period-level data for consistency charts (bars with height + color)
//

import Foundation

/// Represents aggregated metric data for a time period (day/week/month)
/// Used for consistency chart bars where:
/// - Height = calm score (0-100)
/// - Color = dominant zone for that period
struct PeriodScore: Identifiable {
    let id: UUID
    let label: String      // "Mon", "W1", "Dec", etc.
    let date: Date         // Start date of the period
    let score: Double      // Calm score 0-100 (% of time in calm zone)
    let zone: StressZone   // Dominant zone for bar color

    init(
        id: UUID = UUID(),
        label: String,
        date: Date,
        score: Double,
        zone: StressZone
    ) {
        self.id = id
        self.label = label
        self.date = date
        self.score = score
        self.zone = zone
    }
}


