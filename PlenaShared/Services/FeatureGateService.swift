//
//  FeatureGateService.swift
//  PlenaShared
//
//  Centralized feature gating service
//

import Foundation
import Combine

@MainActor
protocol FeatureGateServiceProtocol {
    var subscriptionStatus: AnyPublisher<SubscriptionStatus, Never> { get }
    func hasAccess(to feature: PremiumFeature) -> Bool
    func isFeatureAvailable(_ feature: PremiumFeature) -> Bool
    func checkAccess(to feature: PremiumFeature) async -> Bool
    func hasAccessToTimeRange(_ timeRange: TimeRange) -> Bool
    func hasAccessToSensor(_ sensorName: String) -> Bool
}

@MainActor
class FeatureGateService: FeatureGateServiceProtocol {
    private let subscriptionService: SubscriptionServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    var subscriptionStatus: AnyPublisher<SubscriptionStatus, Never> {
        return subscriptionService.subscriptionStatus.eraseToAnyPublisher()
    }

    init(subscriptionService: SubscriptionServiceProtocol) {
        self.subscriptionService = subscriptionService
    }

    /// Synchronous check for feature access (uses cached status)
    func hasAccess(to feature: PremiumFeature) -> Bool {
        let status = subscriptionService.currentSubscriptionStatus()
        return status.isPremium
    }

    /// Alias for hasAccess for semantic clarity
    func isFeatureAvailable(_ feature: PremiumFeature) -> Bool {
        return hasAccess(to: feature)
    }

    /// Async check that refreshes subscription status first
    func checkAccess(to feature: PremiumFeature) async -> Bool {
        await subscriptionService.checkSubscriptionStatus()
        return subscriptionService.currentSubscriptionStatus().isPremium
    }

    /// Check if a specific time range is available
    func hasAccessToTimeRange(_ timeRange: TimeRange) -> Bool {
        switch timeRange {
        case .day, .week:
            // Day and Week are free
            return true
        case .month, .year:
            // Month and Year are premium
            return hasAccess(to: .extendedTimeRanges)
        }
    }

    /// Check if a sensor is available
    func hasAccessToSensor(_ sensorName: String) -> Bool {
        // Basic sensors are free
        let freeSensors = ["Heart Rate", "HRV", "Respiratory Rate"]
        if freeSensors.contains(sensorName) {
            return true
        }

        // Advanced sensors require premium
        let premiumSensors = ["Temperature", "VO₂ Max", "VO2Max"]
        if premiumSensors.contains(sensorName) {
            return hasAccess(to: .advancedSensors)
        }

        // Unknown sensor, allow by default (fail open)
        return true
    }
}

