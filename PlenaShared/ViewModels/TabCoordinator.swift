//
//  TabCoordinator.swift
//  PlenaShared
//
//  Coordinates tab navigation and deep linking
//

import SwiftUI

class TabCoordinator: ObservableObject {
    @Published var selectedTab: Int = 0
    @Published var selectedSensor: SensorType? = nil

    func navigateToDataTab(sensor: SensorType? = nil) {
        // Set sensor first, then switch tabs to ensure the view picks it up
        if let sensor = sensor {
            selectedSensor = sensor
        }
        // Use a small delay to ensure sensor is set before tab change
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 second delay
            selectedTab = 3 // Data tab index
        }
    }
}
