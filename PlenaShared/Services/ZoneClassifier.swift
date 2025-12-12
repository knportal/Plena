//
//  ZoneClassifier.swift
//  PlenaShared
//
//  Created on December 5, 2025
//

import Foundation

/// Protocol for zone classification logic (for testability)
protocol ZoneClassifierProtocol {
    func classifyHeartRate(_ bpm: Double, baseline: Double?) -> StressZone
    func classifyHRV(_ sdnn: Double, age: Int?, baseline: Double?) -> StressZone
    func classifyRespiratoryRate(_ breathsPerMin: Double) -> StressZone
}

/// Service for classifying biometric readings into stress zones
struct ZoneClassifier: ZoneClassifierProtocol {

    // MARK: - Heart Rate Classification

    /// Classifies heart rate into stress zones
    /// - Parameters:
    ///   - bpm: Heart rate in beats per minute
    ///   - baseline: Optional resting heart rate (if available, uses relative thresholds)
    /// - Returns: Classified stress zone
    func classifyHeartRate(_ bpm: Double, baseline: Double? = nil) -> StressZone {
        // If resting HR baseline is available, use personalized thresholds
        if let restingHR = baseline, restingHR > 0 {
            let lowBand = restingHR + 5
            let midBand = restingHR + 20

            if bpm <= lowBand {
                return .calm
            } else if bpm <= midBand {
                return .optimal
            } else {
                return .elevatedStress
            }
        }

        // Fallback: Standard thresholds for adults (60-100 bpm normal range)
        if bpm < 60 {
            return .calm
        } else if bpm > 100 {
            return .elevatedStress
        } else {
            return .optimal
        }
    }

    // MARK: - HRV Classification

    /// Classifies HRV (SDNN) into stress zones
    /// - Parameters:
    ///   - sdnn: HRV SDNN value in milliseconds
    ///   - age: Optional age for age-adjusted thresholds (future enhancement)
    ///   - baseline: Optional personal baseline HRV (if available, uses relative thresholds)
    /// - Returns: Classified stress zone
    func classifyHRV(_ sdnn: Double, age: Int? = nil, baseline: Double? = nil) -> StressZone {
        // If baseline is available, use personalized relative thresholds
        if let baseline = baseline, baseline > 0 {
            let delta = baseline * 0.15 // 15% band

            if sdnn < baseline - delta {
                return .elevatedStress // Stress / Low
            } else if sdnn > baseline + delta {
                return .calm // Calm / Optimal
            } else {
                return .optimal // Neutral / Typical
            }
        }

        // Fallback: Absolute thresholds for new users without baseline
        // - < 25 ms: Low (Elevated Stress)
        // - 25-45 ms: Neutral (Optimal)
        // - > 45 ms: Optimal (Calm)
        if sdnn < 25 {
            return .elevatedStress
        } else if sdnn > 45 {
            return .calm
        } else {
            return .optimal
        }

        // TODO: Future enhancement - age-adjusted thresholds
        // SDNN naturally declines with age:
        // 20s: ~47ms, 30s: ~41ms, 40s: ~37ms, 50s: ~32ms, 60s: ~27ms
    }

    // MARK: - Respiratory Rate Classification

    /// Classifies respiratory rate into stress zones
    /// - Parameter breathsPerMin: Respiratory rate in breaths per minute
    /// - Returns: Classified stress zone
    func classifyRespiratoryRate(_ breathsPerMin: Double) -> StressZone {
        // Meditation-focused thresholds:
        // - > 16: Fast / Shallow (Elevated Stress)
        // - 12-16: Normal (Optimal)
        // - 6-12: Calm / Deep (Calm)

        if breathsPerMin > 16 {
            return .elevatedStress
        } else if breathsPerMin >= 12 {
            return .optimal
        } else {
            return .calm
        }
    }
}
