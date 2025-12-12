//
//  SettingsViewModelTests.swift
//  PlenaTests
//
//  Unit tests for SettingsViewModel
//

import XCTest
@testable import PlenaShared

@MainActor
final class SettingsViewModelTests: XCTestCase {
    var viewModel: SettingsViewModel!
    let iCloudStore = NSUbiquitousKeyValueStore.default

    override func setUp() {
        super.setUp()
        // Clear iCloud store for clean test state
        iCloudStore.removeObject(forKey: "sensorHeartRateEnabled")
        iCloudStore.removeObject(forKey: "sensorHRVEnabled")
        iCloudStore.removeObject(forKey: "sensorRespiratoryRateEnabled")
        iCloudStore.removeObject(forKey: "sensorVO2MaxEnabled")
        iCloudStore.removeObject(forKey: "sensorTemperatureEnabled")
        iCloudStore.removeObject(forKey: "temperatureUnit")
        iCloudStore.synchronize()

        viewModel = SettingsViewModel()
    }

    override func tearDown() {
        viewModel = nil
        // Clean up
        iCloudStore.removeObject(forKey: "sensorHeartRateEnabled")
        iCloudStore.removeObject(forKey: "sensorHRVEnabled")
        iCloudStore.removeObject(forKey: "sensorRespiratoryRateEnabled")
        iCloudStore.removeObject(forKey: "sensorVO2MaxEnabled")
        iCloudStore.removeObject(forKey: "sensorTemperatureEnabled")
        iCloudStore.removeObject(forKey: "temperatureUnit")
        iCloudStore.synchronize()
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInit_LoadsDefaultValues() {
        // Then
        XCTAssertTrue(viewModel.heartRateEnabled, "Heart rate should be enabled by default")
        XCTAssertTrue(viewModel.hrvEnabled, "HRV should be enabled by default")
        XCTAssertTrue(viewModel.respiratoryRateEnabled, "Respiratory rate should be enabled by default")
        XCTAssertTrue(viewModel.vo2MaxEnabled, "VO2 Max should be enabled by default")
        XCTAssertTrue(viewModel.temperatureEnabled, "Temperature should be enabled by default")
    }

    // MARK: - Sensor Toggle Tests

    func testHeartRateEnabled_TogglesAndSavesToiCloud() {
        // Given
        let initialValue = viewModel.heartRateEnabled

        // When
        viewModel.heartRateEnabled = !initialValue

        // Then
        XCTAssertEqual(viewModel.heartRateEnabled, !initialValue, "Should toggle heart rate enabled")
        let storedValue = iCloudStore.object(forKey: "sensorHeartRateEnabled") as? Bool
        XCTAssertEqual(storedValue, !initialValue, "Should save to iCloud store")
    }

    func testHRVEnabled_TogglesAndSavesToiCloud() {
        // Given
        let initialValue = viewModel.hrvEnabled

        // When
        viewModel.hrvEnabled = !initialValue

        // Then
        XCTAssertEqual(viewModel.hrvEnabled, !initialValue, "Should toggle HRV enabled")
        let storedValue = iCloudStore.object(forKey: "sensorHRVEnabled") as? Bool
        XCTAssertEqual(storedValue, !initialValue, "Should save to iCloud store")
    }

    func testRespiratoryRateEnabled_TogglesAndSavesToiCloud() {
        // Given
        let initialValue = viewModel.respiratoryRateEnabled

        // When
        viewModel.respiratoryRateEnabled = !initialValue

        // Then
        XCTAssertEqual(viewModel.respiratoryRateEnabled, !initialValue, "Should toggle respiratory rate enabled")
        let storedValue = iCloudStore.object(forKey: "sensorRespiratoryRateEnabled") as? Bool
        XCTAssertEqual(storedValue, !initialValue, "Should save to iCloud store")
    }

    func testVO2MaxEnabled_TogglesAndSavesToiCloud() {
        // Given
        let initialValue = viewModel.vo2MaxEnabled

        // When
        viewModel.vo2MaxEnabled = !initialValue

        // Then
        XCTAssertEqual(viewModel.vo2MaxEnabled, !initialValue, "Should toggle VO2 Max enabled")
        let storedValue = iCloudStore.object(forKey: "sensorVO2MaxEnabled") as? Bool
        XCTAssertEqual(storedValue, !initialValue, "Should save to iCloud store")
    }

    func testTemperatureEnabled_TogglesAndSavesToiCloud() {
        // Given
        let initialValue = viewModel.temperatureEnabled

        // When
        viewModel.temperatureEnabled = !initialValue

        // Then
        XCTAssertEqual(viewModel.temperatureEnabled, !initialValue, "Should toggle temperature enabled")
        let storedValue = iCloudStore.object(forKey: "sensorTemperatureEnabled") as? Bool
        XCTAssertEqual(storedValue, !initialValue, "Should save to iCloud store")
    }

    // MARK: - Temperature Unit Tests

    func testTemperatureUnit_DefaultsToFahrenheit() {
        // Then
        XCTAssertEqual(viewModel.temperatureUnit, .fahrenheit, "Should default to Fahrenheit")
    }

    func testTemperatureUnit_ChangesAndSavesToiCloud() {
        // Given
        let initialUnit = viewModel.temperatureUnit

        // When
        viewModel.temperatureUnit = .celsius

        // Then
        XCTAssertEqual(viewModel.temperatureUnit, .celsius, "Should change to Celsius")
        let storedValue = iCloudStore.string(forKey: "temperatureUnit")
        XCTAssertEqual(storedValue, TemperatureUnit.celsius.rawValue, "Should save to iCloud store")
    }

    func testTemperatureUnitSymbol_ReturnsCorrectSymbol() {
        // Given
        viewModel.temperatureUnit = .fahrenheit

        // Then
        XCTAssertEqual(viewModel.temperatureUnitSymbol, "°F", "Should return Fahrenheit symbol")

        // When
        viewModel.temperatureUnit = .celsius

        // Then
        XCTAssertEqual(viewModel.temperatureUnitSymbol, "°C", "Should return Celsius symbol")
    }

    // MARK: - Helper Method Tests

    func testIsSensorEnabled_ReturnsCorrectValue() {
        // Given
        viewModel.heartRateEnabled = true
        viewModel.hrvEnabled = false
        viewModel.respiratoryRateEnabled = true
        viewModel.vo2MaxEnabled = false
        viewModel.temperatureEnabled = true

        // Then
        XCTAssertTrue(viewModel.isSensorEnabled(.heartRate), "Heart rate should be enabled")
        XCTAssertFalse(viewModel.isSensorEnabled(.hrv), "HRV should be disabled")
        XCTAssertTrue(viewModel.isSensorEnabled(.respiratoryRate), "Respiratory rate should be enabled")
        XCTAssertFalse(viewModel.isSensorEnabled(.vo2Max), "VO2 Max should be disabled")
        XCTAssertTrue(viewModel.isSensorEnabled(.temperature), "Temperature should be enabled")
    }

    func testConvertTemperature_ConvertsCorrectly() {
        // Given
        let celsius = 37.0 // Normal body temperature

        // When - Convert to Fahrenheit
        viewModel.temperatureUnit = .fahrenheit
        let fahrenheit = viewModel.convertTemperature(celsius)

        // Then
        XCTAssertEqual(fahrenheit, 98.6, accuracy: 0.1, "Should convert 37°C to 98.6°F")

        // When - Convert to Celsius (should return same)
        viewModel.temperatureUnit = .celsius
        let celsiusResult = viewModel.convertTemperature(celsius)

        // Then
        XCTAssertEqual(celsiusResult, 37.0, accuracy: 0.1, "Should return same value for Celsius")
    }
}
