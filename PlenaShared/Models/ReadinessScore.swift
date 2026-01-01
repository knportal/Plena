//
//  ReadinessScore.swift
//  PlenaShared
//
//  Daily readiness score with all contributors
//

import Foundation

/// Represents a daily readiness score with all contributors
struct ReadinessScore: Identifiable {
    let id: UUID
    let date: Date
    let overallScore: Double // 0-100
    let contributors: [ReadinessContributor]

    init(
        id: UUID = UUID(),
        date: Date,
        overallScore: Double,
        contributors: [ReadinessContributor]
    ) {
        self.id = id
        self.date = date
        self.overallScore = max(0, min(100, overallScore)) // Clamp to 0-100
        self.contributors = contributors
    }

    var status: ReadinessStatus {
        switch overallScore {
        case 80...100: return .optimal
        case 60..<80: return .good
        case 40..<60: return .payAttention
        default: return .poor
        }
    }
}










