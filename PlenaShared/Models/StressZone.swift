//
//  StressZone.swift
//  PlenaShared
//
//  Created on December 5, 2025
//

import Foundation
import SwiftUI

/// Represents stress/arousal zones for biometric readings
enum StressZone: String, Codable, CaseIterable {
    case calm
    case optimal
    case elevatedStress

    /// Human-readable name
    var displayName: String {
        switch self {
        case .calm:
            return "Calm"
        case .optimal:
            return "Optimal"
        case .elevatedStress:
            return "Higher Activation"
        }
    }

    /// Color representing this zone
    var color: Color {
        switch self {
        case .calm:
            return .blue
        case .optimal:
            return .green
        case .elevatedStress:
            return .indigo
        }
    }

    /// Background color with opacity for subtle display
    var backgroundColor: Color {
        switch self {
        case .calm:
            return Color.blue.opacity(0.15)
        case .optimal:
            return Color.green.opacity(0.15)
        case .elevatedStress:
            return Color.indigo.opacity(0.15)
        }
    }

    /// Border color for card highlighting
    var borderColor: Color {
        switch self {
        case .calm:
            return Color.blue.opacity(0.4)
        case .optimal:
            return Color.green.opacity(0.4)
        case .elevatedStress:
            return Color.indigo.opacity(0.4)
        }
    }

    /// Accessibility description for VoiceOver
    var accessibilityDescription: String {
        return "\(displayName) zone"
    }
}









