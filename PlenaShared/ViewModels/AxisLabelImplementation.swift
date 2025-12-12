//
//  AxisLabelImplementation.swift
//  PlenaShared
//
//  Feature flag to switch between axis label implementations
//

import Foundation

enum AxisLabelImplementation: String, CaseIterable {
    case chartIntegrated = "Chart Integrated"
    case separateView = "Separate View"

    var description: String {
        switch self {
        case .chartIntegrated:
            return "Uses Chart's built-in AxisMarks (current)"
        case .separateView:
            return "Uses separate PlenaTimeAxisLabels view (new)"
        }
    }
}

// Global setting - can be changed via AppStorage or Settings
// Default to separateView - preferred implementation after testing
var currentAxisLabelImplementation: AxisLabelImplementation = .separateView

