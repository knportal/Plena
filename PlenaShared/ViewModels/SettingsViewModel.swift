//
//  SettingsViewModel.swift
//  PlenaShared
//
//  Created on [Date]
//

import Foundation
import SwiftUI
import Combine

/// Uses iCloud Key-Value Store for syncing settings between iOS and Watch
/// This is already configured in the entitlements and doesn't require App Groups setup
private let iCloudStore = NSUbiquitousKeyValueStore.default

@MainActor
class SettingsViewModel: ObservableObject {
    // Sensor toggles - default all to true
    @Published var heartRateEnabled: Bool {
        didSet {
            iCloudStore.set(heartRateEnabled, forKey: "sensorHeartRateEnabled")
            iCloudStore.synchronize()
        }
    }
    @Published var hrvEnabled: Bool {
        didSet {
            iCloudStore.set(hrvEnabled, forKey: "sensorHRVEnabled")
            iCloudStore.synchronize()
        }
    }
    @Published var respiratoryRateEnabled: Bool {
        didSet {
            iCloudStore.set(respiratoryRateEnabled, forKey: "sensorRespiratoryRateEnabled")
            iCloudStore.synchronize()
        }
    }
    @Published var vo2MaxEnabled: Bool {
        didSet {
            iCloudStore.set(vo2MaxEnabled, forKey: "sensorVO2MaxEnabled")
            iCloudStore.synchronize()
        }
    }
    @Published var temperatureEnabled: Bool {
        didSet {
            iCloudStore.set(temperatureEnabled, forKey: "sensorTemperatureEnabled")
            iCloudStore.synchronize()
        }
    }

    // Temperature unit preference
    @Published var temperatureUnitRaw: String {
        didSet {
            iCloudStore.set(temperatureUnitRaw, forKey: "temperatureUnit")
            iCloudStore.synchronize()
        }
    }

    var temperatureUnit: TemperatureUnit {
        get {
            TemperatureUnit(rawValue: temperatureUnitRaw) ?? .celsius
        }
        set {
            temperatureUnitRaw = newValue.rawValue
        }
    }

    private var cancellables = Set<AnyCancellable>()

    init() {
        // Load initial values from iCloud Key-Value Store
        heartRateEnabled = iCloudStore.object(forKey: "sensorHeartRateEnabled") as? Bool ?? true
        hrvEnabled = iCloudStore.object(forKey: "sensorHRVEnabled") as? Bool ?? true
        respiratoryRateEnabled = iCloudStore.object(forKey: "sensorRespiratoryRateEnabled") as? Bool ?? true
        vo2MaxEnabled = iCloudStore.object(forKey: "sensorVO2MaxEnabled") as? Bool ?? true
        temperatureEnabled = iCloudStore.object(forKey: "sensorTemperatureEnabled") as? Bool ?? true
        temperatureUnitRaw = iCloudStore.string(forKey: "temperatureUnit") ?? TemperatureUnit.fahrenheit.rawValue

        // Observe iCloud Key-Value Store changes for automatic sync
        NotificationCenter.default.publisher(for: NSUbiquitousKeyValueStore.didChangeExternallyNotification)
            .sink { [weak self] notification in
                guard let self = self else { return }
                // Refresh all settings when iCloud syncs changes from other device
                self.refreshFromiCloud()
            }
            .store(in: &cancellables)

        // Also check periodically in case notifications don't fire
        Timer.publish(every: 2.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.refreshFromiCloud()
            }
            .store(in: &cancellables)
    }

    /// Refreshes all settings from iCloud Key-Value Store (for sync from other app)
    private func refreshFromiCloud() {
        let newHeartRate = iCloudStore.object(forKey: "sensorHeartRateEnabled") as? Bool ?? true
        let newHRV = iCloudStore.object(forKey: "sensorHRVEnabled") as? Bool ?? true
        let newRespiratory = iCloudStore.object(forKey: "sensorRespiratoryRateEnabled") as? Bool ?? true
        let newVO2Max = iCloudStore.object(forKey: "sensorVO2MaxEnabled") as? Bool ?? true
        let newTemperature = iCloudStore.object(forKey: "sensorTemperatureEnabled") as? Bool ?? true
        let newUnit = iCloudStore.string(forKey: "temperatureUnit") ?? TemperatureUnit.celsius.rawValue

        // Only update if values changed to avoid unnecessary UI updates
        if heartRateEnabled != newHeartRate { heartRateEnabled = newHeartRate }
        if hrvEnabled != newHRV { hrvEnabled = newHRV }
        if respiratoryRateEnabled != newRespiratory { respiratoryRateEnabled = newRespiratory }
        if vo2MaxEnabled != newVO2Max { vo2MaxEnabled = newVO2Max }
        if temperatureEnabled != newTemperature { temperatureEnabled = newTemperature }
        if temperatureUnitRaw != newUnit { temperatureUnitRaw = newUnit }
    }

    // Helper to check if a sensor is enabled
    func isSensorEnabled(_ sensor: SensorType) -> Bool {
        switch sensor {
        case .heartRate:
            return heartRateEnabled
        case .hrv:
            return hrvEnabled
        case .respiratoryRate:
            return respiratoryRateEnabled
        case .vo2Max:
            return vo2MaxEnabled
        case .temperature:
            return temperatureEnabled
        }
    }

    // Helper to convert temperature from Celsius (stored) to display unit
    func convertTemperature(_ celsius: Double) -> Double {
        switch temperatureUnit {
        case .celsius:
            return celsius
        case .fahrenheit:
            return (celsius * 9.0 / 5.0) + 32.0
        }
    }

    // Helper to get temperature unit symbol
    var temperatureUnitSymbol: String {
        return temperatureUnit.rawValue
    }
}

