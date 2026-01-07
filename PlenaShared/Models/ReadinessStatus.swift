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
    case higher = "Higher"
    case moderate = "Moderate"
    case lower = "Lower"
    case noData = "No data"

    var color: Color {
        switch self {
        case .optimal:
            return .blue
        case .higher:
            return .blue
        case .moderate:
            return .gray
        case .lower:
            return .gray
        case .noData:
            return .gray
        }
    }

    /// Weight for calculating overall score (0.0-1.0)
    var scoreWeight: Double {
        switch self {
        case .optimal: return 1.0
        case .higher: return 0.75
        case .moderate: return 0.5
        case .lower: return 0.25
        case .noData: return 0.0 // No data doesn't contribute to score
        }
    }

    /// Progress value for progress bar (0.0-1.0)
    var progress: Double {
        switch self {
        case .optimal: return 1.0
        case .higher: return 0.75
        case .moderate: return 0.5
        case .lower: return 0.25
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

