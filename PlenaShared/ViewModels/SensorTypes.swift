//
//  SensorTypes.swift
//  PlenaShared
//
//  Shared enums and types for sensor data
//

import Foundation
import SwiftUI

enum SensorType: String, CaseIterable {
    case heartRate = "Heart Rate"
    case hrv = "HRV (SDNN)"
    case respiratoryRate = "Respiratory Rate"
    case vo2Max = "VO₂ Max"
    case temperature = "Temperature"
}

enum TemperatureUnit: String, CaseIterable {
    case fahrenheit = "°F"
    case celsius = "°C"

    var displayName: String {
        switch self {
        case .celsius:
            return "Celsius"
        case .fahrenheit:
            return "Fahrenheit"
        }
    }
}

struct SensorRange {
    let above: ClosedRange<Double>
    let normal: ClosedRange<Double>
    let below: ClosedRange<Double>

    func category(for value: Double) -> RangeCategory {
        if normal.contains(value) {
            return .normal
        } else if above.contains(value) {
            return .above
        } else {
            return .below
        }
    }
}

enum RangeCategory: String {
    case above = "Above"
    case normal = "Normal"
    case below = "Below"

    var color: String {
        switch self {
        case .above: return "orange"
        case .normal: return "green"
        case .below: return "blue"
        }
    }
}

enum Trend {
    case improving
    case declining
    case stable

    var icon: String {
        switch self {
        case .improving: return "arrow.up.right"
        case .declining: return "arrow.down.right"
        case .stable: return "arrow.right"
        }
    }

    var color: Color {
        switch self {
        case .improving: return .green
        case .declining: return .red
        case .stable: return .gray
        }
    }

    var description: String {
        switch self {
        case .improving: return "Improving"
        case .declining: return "Declining"
        case .stable: return "Stable"
        }
    }
}

enum ViewMode: String, CaseIterable {
    case consistency = "Consistency"
    case trend = "Trend"
}

