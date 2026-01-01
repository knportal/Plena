//
//  SubscriptionProduct.swift
//  PlenaShared
//
//  Subscription product identifiers and configuration
//

import Foundation

/// Product identifiers for subscriptions
enum SubscriptionProduct {
    /// Monthly subscription product ID
    static let monthly = "com.plena.meditation.subscription.monthly"

    /// Annual subscription product ID
    static let annual = "com.plena.meditation.subscription.annual"

    /// All subscription product IDs
    static let all: [String] = [monthly, annual]

    /// Determine subscription tier from product ID
    static func tier(for productId: String) -> SubscriptionTier {
        switch productId {
        case monthly, annual:
            return .premium
        default:
            return .free
        }
    }
}

/// Represents a premium feature that can be gated
enum PremiumFeature: String, CaseIterable {
    case readinessScore = "readiness_score"
    case extendedTimeRanges = "extended_time_ranges" // Month, Year views
    case advancedSensors = "advanced_sensors" // Temperature, VO2Max
    case advancedDataVisualization = "advanced_data_visualization" // Trend analysis, zone distribution
    case dataExport = "data_export"
    case appleWatchApp = "apple_watch_app"

    /// Human-readable name for the feature
    var displayName: String {
        switch self {
        case .readinessScore:
            return "Readiness Score"
        case .extendedTimeRanges:
            return "Extended Time Ranges"
        case .advancedSensors:
            return "Advanced Sensors"
        case .advancedDataVisualization:
            return "Advanced Data Visualization"
        case .dataExport:
            return "Data Export"
        case .appleWatchApp:
            return "Apple Watch App"
        }
    }

    /// Description of what this feature provides
    var description: String {
        switch self {
        case .readinessScore:
            return "Comprehensive readiness score with detailed contributor breakdowns"
        case .extendedTimeRanges:
            return "Access to Month and Year views for long-term trend analysis"
        case .advancedSensors:
            return "Track Temperature and VO₂ Max during meditation sessions"
        case .advancedDataVisualization:
            return "Trend analysis, zone distribution, and consistency views"
        case .dataExport:
            return "Export your meditation session data"
        case .appleWatchApp:
            return "Full Apple Watch integration for on-the-go sessions"
        }
    }
}

