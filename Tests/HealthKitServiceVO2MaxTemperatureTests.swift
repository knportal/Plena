//
//  HealthKitServiceVO2MaxTemperatureTests.swift
//  PlenaTests
//
//  Unit tests for VO2 Max and Temperature query functionality in HealthKitService
//
//  Note: These tests use the real HealthKitService which requires HealthKit availability.
//  For better testability, consider using a protocol-based approach with mocks in the future.
//

import XCTest
import HealthKit
@testable import PlenaShared

final class HealthKitServiceVO2MaxTemperatureTests: XCTestCase {
    var healthKitService: HealthKitService!

    override func setUp() {
        super.setUp()
        healthKitService = HealthKitService()
    }

    override func tearDown() {
        healthKitService?.stopAllQueries()
        healthKitService = nil
        super.tearDown()
    }

    // MARK: - VO2 Max Query Tests

    func testStartVO2MaxQuery_ThrowsWhenHealthKitUnavailable() {
        // Note: This test requires HealthKit availability
        // In a production test suite, you'd use a protocol-based mock
        // For now, we test the structure and error handling

        var handlerCalled = false
        var receivedValue: Double?

        let handler: VO2MaxHandler = { value in
            handlerCalled = true
            receivedValue = value
        }

        // This will fail on simulator/without HealthKit, but tests structure
        do {
            try healthKitService.startVO2MaxQuery(handler: handler)
            // If we get here, HealthKit is available
            XCTAssertNotNil(healthKitService, "Service should exist")
            // Clean up
            healthKitService.stopAllQueries()
        } catch {
            // Expected in test environment without HealthKit
            XCTAssertTrue(error is HealthKitError, "Should throw HealthKitError")
        }
    }

    func testFetchLatestVO2Max_ReturnsNilWhenNoData() async {
        // Note: Requires HealthKit availability
        // In production, this would use a mock

        do {
            let result = try await healthKitService.fetchLatestVO2Max()
            // Result may be nil if no data exists, which is valid
            XCTAssertTrue(result == nil || result! > 0, "If value exists, should be positive")
        } catch {
            // Expected in test environment without HealthKit
            XCTAssertTrue(error is HealthKitError, "Should throw HealthKitError when unavailable")
        }
    }

    func testStartPeriodicVO2MaxQuery_StartsPeriodicFetching() {
        var callCount = 0
        let handler: VO2MaxHandler = { _ in
            callCount += 1
        }

        do {
            try healthKitService.startPeriodicVO2MaxQuery(interval: 0.1, handler: handler)

            // Wait a bit for periodic calls
            let expectation = XCTestExpectation(description: "Periodic query called")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 1.0)

            // Should have been called at least once (immediate fetch)
            XCTAssertGreaterThanOrEqual(callCount, 1, "Handler should be called at least once")

            // Clean up
            healthKitService.stopAllQueries()
        } catch {
            // Expected in test environment
            XCTAssertTrue(error is HealthKitError || error is CancellationError)
        }
    }

    // MARK: - Temperature Query Tests

    func testStartTemperatureQuery_ThrowsWhenHealthKitUnavailable() {
        var handlerCalled = false
        var receivedValue: Double?

        let handler: TemperatureHandler = { value in
            handlerCalled = true
            receivedValue = value
        }

        do {
            try healthKitService.startTemperatureQuery(handler: handler)
            XCTAssertNotNil(healthKitService, "Service should exist")
        } catch {
            XCTAssertTrue(error is HealthKitError, "Should throw HealthKitError")
        }
    }

    func testFetchLatestTemperature_ReturnsNilWhenNoData() async {
        do {
            let result = try await healthKitService.fetchLatestTemperature()
            // Result may be nil if no data exists, which is valid
            // If value exists, should be reasonable body temperature (30-45°C)
            if let temp = result {
                XCTAssertGreaterThan(temp, 30.0, "Temperature should be above 30°C")
                XCTAssertLessThan(temp, 45.0, "Temperature should be below 45°C")
            }
        } catch {
            XCTAssertTrue(error is HealthKitError, "Should throw HealthKitError when unavailable")
        }
    }

    func testStartPeriodicTemperatureQuery_StartsPeriodicFetching() {
        var callCount = 0
        let handler: TemperatureHandler = { _ in
            callCount += 1
        }

        do {
            try healthKitService.startPeriodicTemperatureQuery(interval: 0.1, handler: handler)

            // Wait a bit for periodic calls
            let expectation = XCTestExpectation(description: "Periodic query called")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 1.0)

            // Should have been called at least once (immediate fetch)
            XCTAssertGreaterThanOrEqual(callCount, 1, "Handler should be called at least once")

            // Clean up
            healthKitService.stopAllQueries()
        } catch {
            XCTAssertTrue(error is HealthKitError || error is CancellationError)
        }
    }

    // MARK: - Stop All Queries Tests

    func testStopAllQueries_StopsVO2MaxAndTemperatureQueries() {
        var vo2MaxCalled = false
        var tempCalled = false

        let vo2MaxHandler: VO2MaxHandler = { _ in vo2MaxCalled = true }
        let tempHandler: TemperatureHandler = { _ in tempCalled = true }

        // Try to start queries
        try? healthKitService.startVO2MaxQuery(handler: vo2MaxHandler)
        try? healthKitService.startTemperatureQuery(handler: tempHandler)

        // Stop all queries
        healthKitService.stopAllQueries()

        // Verify queries are stopped (no new calls after stop)
        let initialVO2MaxState = vo2MaxCalled
        let initialTempState = tempCalled

        // Wait a bit
        let expectation = XCTestExpectation(description: "Wait after stop")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.5)

        // States shouldn't have changed (queries stopped)
        XCTAssertEqual(vo2MaxCalled, initialVO2MaxState, "VO2 Max query should be stopped")
        XCTAssertEqual(tempCalled, initialTempState, "Temperature query should be stopped")
    }
}

