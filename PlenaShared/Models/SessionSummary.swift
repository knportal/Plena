//
//  SessionSummary.swift
//  PlenaShared
//
//  Created on [Date]
//

import Foundation

struct SessionSummary: Identifiable {
    let id = UUID()
    let averageHeartRate: Double?
    let lowestHeartRate: Double?
    let hrvStart: Double?
    let hrvEnd: Double?
    let hrvChange: Double? // End - Start
    let averageHRV: Double?
    let hrvTrend: HRVTrend
    let averageRespiratoryRate: Double?
    let respiratoryRateTrend: RespiratoryRateTrend

    enum RespiratoryRateTrend {
        case decreasing
        case stable
        case increasing
        case insufficientData
    }

    enum HRVTrend {
        case decreasing
        case stable
        case increasing
        case insufficientData
    }

    var hrvChangeMessage: String? {
        guard let change = hrvChange else { return nil }
        let absChange = abs(change)
        let direction = change > 0 ? "increased" : "decreased"
        return "Your HRV \(direction) by \(Int(absChange)) ms — \(change > 0 ? "great!" : "keep practicing!")"
    }

    var hrvTrendMessage: String? {
        switch hrvTrend {
        case .increasing:
            return "HRV improved throughout your session"
        case .decreasing:
            return "HRV decreased during your session"
        case .stable:
            return "HRV remained stable"
        case .insufficientData:
            return nil
        }
    }
}

