//
//  SubscriptionTier.swift
//  PlenaShared
//
//  Subscription tier enum
//

import Foundation

/// Represents the subscription tier/status of the user
enum SubscriptionTier: String, Codable, CaseIterable {
    case free
    case premium

    /// Human-readable name
    var displayName: String {
        switch self {
        case .free:
            return "Free"
        case .premium:
            return "Premium"
        }
    }

    /// Whether this tier has premium features
    var isPremium: Bool {
        return self == .premium
    }
}

/// Represents the subscription status
enum SubscriptionStatus: Equatable {
    case notSubscribed
    case subscribed(tier: SubscriptionTier, expirationDate: Date?)
    case expired
    case revoked

    /// Whether the user has an active premium subscription
    var isPremium: Bool {
        switch self {
        case .subscribed(let tier, _):
            return tier.isPremium
        default:
            return false
        }
    }

    /// Current tier based on status
    var tier: SubscriptionTier {
        switch self {
        case .subscribed(let tier, _):
            return tier
        default:
            return .free
        }
    }
}



