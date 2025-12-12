//
//  ReadinessContributor.swift
//  PlenaShared
//
//  Individual metric that contributes to the readiness score
//

import Foundation

/// Represents a single metric that contributes to the readiness score
struct ReadinessContributor: Identifiable, Hashable {
    let id: UUID
    let name: String
    let value: String // e.g., "64 bpm", "Good", "Optimal"
    let status: ReadinessStatus
    let score: Double // 0.0-1.0 contribution to overall score
    let progress: Double // 0.0-1.0 for progress bar

    init(
        id: UUID = UUID(),
        name: String,
        value: String,
        status: ReadinessStatus,
        score: Double,
        progress: Double? = nil
    ) {
        self.id = id
        self.name = name
        self.value = value
        self.status = status
        self.score = score
        self.progress = progress ?? status.progress
    }

    var icon: String {
        switch name {
        case "Resting heart rate": return "heart.fill"
        case "HRV balance": return "waveform.path.ecg"
        case "Body temperature": return "thermometer"
        case "Recovery index": return "arrow.triangle.2.circlepath"
        case "Sleep": return "moon.fill"
        case "Sleep balance": return "moon.stars.fill"
        case "Sleep regularity": return "calendar"
        default: return "circle.fill"
        }
    }
}

