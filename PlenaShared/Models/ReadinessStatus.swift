//
//  ReadinessStatus.swift
//  PlenaShared
//
//  Status levels for readiness contributors
//

import Foundation
import SwiftUI

/// Status levels for individual readiness contributors
enum ReadinessStatus: String, Codable, Hashable {
    case optimal = "Optimal"
    case good = "Good"
    case payAttention = "Pay attention"
    case poor = "Poor"
    case noData = "No data"

    var color: Color {
        switch self {
        case .optimal:
            return .green
        case .good:
            return .blue
        case .payAttention:
            return .orange
        case .poor:
            return .red
        case .noData:
            return .gray
        }
    }

    /// Weight for calculating overall score (0.0-1.0)
    var scoreWeight: Double {
        switch self {
        case .optimal: return 1.0
        case .good: return 0.75
        case .payAttention: return 0.5
        case .poor: return 0.25
        case .noData: return 0.0 // No data doesn't contribute to score
        }
    }

    /// Progress value for progress bar (0.0-1.0)
    var progress: Double {
        switch self {
        case .optimal: return 1.0
        case .good: return 0.75
        case .payAttention: return 0.5
        case .poor: return 0.25
        case .noData: return 0.0 // Empty bar for no data
        }
    }

    /// Whether this status should display a status badge
    var shouldShowBadge: Bool {
        switch self {
        case .noData:
            return false
        default:
            return true
        }
    }
}

