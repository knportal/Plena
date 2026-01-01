//
//  TrendStats.swift
//  PlenaShared
//
//  Period-over-period comparison data for trend insight header
//

import Foundation

/// Represents trend statistics comparing current period to previous period
/// Used for insight header: "Improving 🟢 +14% vs last month"
struct TrendStats {
    let statusText: String      // "Improving", "Stable", "Mixed"
    let deltaText: String       // "+14% vs last month" or "-3 bpm vs last week"
    let description: String     // Human-readable explanation

    init(
        statusText: String,
        deltaText: String,
        description: String
    ) {
        self.statusText = statusText
        self.deltaText = deltaText
        self.description = description
    }

    /// Default stats for when there's no previous period to compare
    static var trackingStarted: TrendStats {
        TrendStats(
            statusText: "Tracking started",
            deltaText: "",
            description: "We'll show trends as you complete more sessions."
        )
    }
}









