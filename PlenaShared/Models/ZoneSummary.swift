//
//  ZoneSummary.swift
//  PlenaShared
//
//  Zone percentage summaries for zone chips display
//

import Foundation

/// Represents the percentage of time spent in a specific zone
/// Used for zone chips showing: 🟩 Calm: 61%, 🟨 Neutral: 29%, 🟥 Stress: 10%
struct ZoneSummary: Identifiable {
    let id: UUID
    let zone: StressZone
    let percentage: Double // 0-100

    init(
        id: UUID = UUID(),
        zone: StressZone,
        percentage: Double
    ) {
        self.id = id
        self.zone = zone
        self.percentage = percentage
    }
}
