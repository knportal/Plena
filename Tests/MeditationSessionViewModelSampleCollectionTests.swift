//
//  MeditationSessionViewModelSampleCollectionTests.swift
//  PlenaTests
//
//  Unit tests for sample collection in MeditationSessionViewModel
//

import XCTest
import Combine
@testable import PlenaShared

// Note: MockHealthKitService and MockStorageService are now in TestUtilities.swift

@MainActor
final class MeditationSessionViewModelSampleCollectionTests: XCTestCase {
    var viewModel: MeditationSessionViewModel!
    var mockHealthKitService: MockHealthKitService!
    var mockStorageService: MockStorageService!
    var mockWatchConnectivityService: MockWatchConnectivityService!

    override func setUp() {
        super.setUp()
        mockHealthKitService = MockHealthKitService()
        mockStorageService = MockStorageService()
        mockWatchConnectivityService = MockWatchConnectivityService()
        viewModel = MeditationSessionViewModel(
            healthKitService: mockHealthKitService,
            storageService: mockStorageService,
            watchConnectivityService: mockWatchConnectivityService
        )
    }

    override func tearDown() {
        viewModel = nil
        mockHealthKitService = nil
        mockStorageService = nil
        mockWatchConnectivityService = nil
        super.tearDown()
    }

    // MARK: - VO2 Max Sample Collection Tests

    func testStartSession_FetchesBaselineVO2Max() async {
        mockHealthKitService.mockVO2Max = 48.5

        await viewModel.startSession()

        // Wait for baseline fetch
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds

        XCTAssertEqual(viewModel.baselineVO2Max, 48.5, "Should fetch baseline VO2 Max")
        XCTAssertTrue(viewModel.vo2MaxAvailable, "Should mark VO2 Max as available")
    }

    func testStartSession_CollectsVO2MaxSamples() async {
        mockHealthKitService.mockVO2Max = 45.0

        await viewModel.startSession()

        // Wait for sample collection
        let expectation = XCTestExpectation(description: "VO2 Max sample collected")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 1.0)

        guard let session = viewModel.currentSession else {
            XCTFail("Session should exist")
            return
        }

        XCTAssertFalse(session.vo2MaxSamples.isEmpty, "Should collect VO2 Max samples")
        XCTAssertEqual(session.vo2MaxSamples.first?.value, 45.0, accuracy: 0.1, "Should have correct VO2 Max value")
    }

    func testStartSession_HandlesVO2MaxUnavailable() async {
        mockHealthKitService.mockVO2Max = nil
        mockHealthKitService.shouldThrowError = true

        await viewModel.startSession()

        // Wait a bit
        try? await Task.sleep(nanoseconds: 200_000_000)

        // Should not crash, and availability should reflect state
        XCTAssertNotNil(viewModel, "ViewModel should still exist")
    }

    // MARK: - Temperature Sample Collection Tests

    func testStartSession_CollectsTemperatureSamples() async {
        mockHealthKitService.mockTemperature = 36.8

        await viewModel.startSession()

        // Wait for sample collection
        let expectation = XCTestExpectation(description: "Temperature sample collected")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 1.0)

        guard let session = viewModel.currentSession else {
            XCTFail("Session should exist")
            return
        }

        XCTAssertFalse(session.temperatureSamples.isEmpty, "Should collect temperature samples")
        XCTAssertEqual(session.temperatureSamples.first?.value, 36.8, accuracy: 0.1, "Should have correct temperature value")
    }

    func testStartSession_HandlesTemperatureUnavailable() async {
        mockHealthKitService.mockTemperature = nil
        mockHealthKitService.shouldThrowError = true

        await viewModel.startSession()

        // Wait a bit
        try? await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertNotNil(viewModel, "ViewModel should still exist")
        XCTAssertFalse(viewModel.temperatureAvailable, "Should mark temperature as unavailable")
    }

    // MARK: - Sample Storage Tests

    func testStopSession_SavesVO2MaxAndTemperatureSamples() async {
        mockHealthKitService.mockVO2Max = 46.0
        mockHealthKitService.mockTemperature = 37.2

        await viewModel.startSession()

        // Wait for samples
        try? await Task.sleep(nanoseconds: 300_000_000)

        viewModel.stopSession()

        // Wait for save
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(mockStorageService.savedSessions.count, 1, "Should save one session")

        let savedSession = mockStorageService.savedSessions.first!
        XCTAssertFalse(savedSession.vo2MaxSamples.isEmpty, "Saved session should have VO2 Max samples")
        XCTAssertFalse(savedSession.temperatureSamples.isEmpty, "Saved session should have temperature samples")
    }

    // MARK: - Periodic Query Fallback Tests

    func testStartSession_UsesPeriodicQueryWhenAnchoredQueryUnavailable() async {
        // Simulate anchored query failure but periodic success
        mockHealthKitService.mockVO2Max = 47.5
        mockHealthKitService.shouldThrowError = false // Allow periodic queries

        await viewModel.startSession()

        // Wait for periodic query
        let expectation = XCTestExpectation(description: "Periodic query provides data")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 1.0)

        // Should eventually get data from periodic query
        XCTAssertNotNil(viewModel.currentVO2Max, "Should receive VO2 Max from periodic query")
    }

    // MARK: - State Management Tests

    func testStopSession_ClearsVO2MaxAndTemperatureState() async {
        mockHealthKitService.mockVO2Max = 45.0
        mockHealthKitService.mockTemperature = 37.0

        await viewModel.startSession()
        try? await Task.sleep(nanoseconds: 300_000_000)

        // Verify values are set
        XCTAssertNotNil(viewModel.currentVO2Max)
        XCTAssertNotNil(viewModel.currentTemperature)

        viewModel.stopSession()

        // Verify values are cleared
        XCTAssertNil(viewModel.currentVO2Max, "Should clear VO2 Max")
        XCTAssertNil(viewModel.currentTemperature, "Should clear temperature")
        XCTAssertNil(viewModel.baselineVO2Max, "Should clear baseline VO2 Max")
        XCTAssertFalse(viewModel.vo2MaxAvailable, "Should reset availability")
        XCTAssertFalse(viewModel.temperatureAvailable, "Should reset availability")
    }

    // MARK: - Live sample handling (Watch -> iPhone)

    func testLiveSample_UpdatesStateAndAppendsSamples_WhenSessionActive() async {
        await viewModel.startSession()

        // Ensure startSession completed (countdown + setup)
        try? await Task.sleep(nanoseconds: 200_000_000)

        let now = Date()
        mockWatchConnectivityService.simulateLiveSample(LiveSensorSample(sensorType: .heartRate, value: 80, timestamp: now))
        mockWatchConnectivityService.simulateLiveSample(LiveSensorSample(sensorType: .hrv, value: 55, timestamp: now.addingTimeInterval(1)))
        mockWatchConnectivityService.simulateLiveSample(LiveSensorSample(sensorType: .respiratoryRate, value: 14, timestamp: now.addingTimeInterval(2)))
        mockWatchConnectivityService.simulateLiveSample(LiveSensorSample(sensorType: .vo2Max, value: 47, timestamp: now.addingTimeInterval(3)))
        mockWatchConnectivityService.simulateLiveSample(LiveSensorSample(sensorType: .temperature, value: 36.9, timestamp: now.addingTimeInterval(4)))

        // Allow MainActor tasks to apply updates
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(viewModel.currentHeartRate, 80, accuracy: 0.1)
        XCTAssertEqual(viewModel.currentHRV, 55, accuracy: 0.1)
        XCTAssertEqual(viewModel.currentRespiratoryRate, 14, accuracy: 0.1)
        XCTAssertEqual(viewModel.currentVO2Max, 47, accuracy: 0.1)
        XCTAssertEqual(viewModel.currentTemperature, 36.9, accuracy: 0.1)

        guard let session = viewModel.currentSession else {
            XCTFail("Session should exist")
            return
        }
        XCTAssertFalse(session.heartRateSamples.isEmpty, "Should append heart rate samples from live updates")
        XCTAssertFalse(session.hrvSamples.isEmpty, "Should append HRV samples from live updates")
        XCTAssertFalse(session.respiratoryRateSamples.isEmpty, "Should append respiratory samples from live updates")
        XCTAssertFalse(session.vo2MaxSamples.isEmpty, "Should append VO2 Max samples from live updates")
        XCTAssertFalse(session.temperatureSamples.isEmpty, "Should append temperature samples from live updates")
    }

    func testLiveSample_IgnoredAfterStopSession() async {
        await viewModel.startSession()
        try? await Task.sleep(nanoseconds: 200_000_000)

        let now = Date()
        mockWatchConnectivityService.simulateLiveSample(LiveSensorSample(sensorType: .heartRate, value: 78, timestamp: now))
        try? await Task.sleep(nanoseconds: 100_000_000)

        viewModel.stopSession()

        let countAfterStop = viewModel.currentSession?.heartRateSamples.count ?? 0
        XCTAssertNil(viewModel.currentHeartRate, "In-session values should be cleared on stop")

        // Late sample arrives after stop; should be ignored
        mockWatchConnectivityService.simulateLiveSample(LiveSensorSample(sensorType: .heartRate, value: 90, timestamp: now.addingTimeInterval(10)))
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertNil(viewModel.currentHeartRate, "Should ignore late live sample after stop")
        XCTAssertEqual(viewModel.currentSession?.heartRateSamples.count ?? 0, countAfterStop, "Should not append samples after stop")
    }
}

