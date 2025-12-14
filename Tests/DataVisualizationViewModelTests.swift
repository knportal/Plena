//
//  DataVisualizationViewModelTests.swift
//  PlenaTests
//
//  Unit tests for DataVisualizationViewModel
//

import XCTest
@testable import PlenaShared

@MainActor
final class DataVisualizationViewModelTests: XCTestCase {
    var viewModel: DataVisualizationViewModel!
    var mockStorageService: MockStorageService!

    override func setUp() {
        super.setUp()
        mockStorageService = MockStorageService()
        viewModel = DataVisualizationViewModel(storageService: mockStorageService)
    }

    override func tearDown() {
        viewModel = nil
        mockStorageService = nil
        super.tearDown()
    }

    // MARK: - Data Loading Tests

    func testLoadSessions_LoadsSessionsFromStorage() async {
        // Given
        let session = MeditationSession.createTestSession(daysAgo: 1)
        try! mockStorageService.saveSession(session)

        // When
        await viewModel.loadSessions()

        // Then
        XCTAssertEqual(viewModel.sessions.count, 1, "Should load 1 session")
        XCTAssertFalse(viewModel.isLoading, "Should not be loading after completion")
        XCTAssertNil(viewModel.errorMessage, "Should not have error message")
    }

    func testLoadSessions_HandlesError() async {
        // Given
        mockStorageService.loadError = NSError(domain: "TestError", code: 1, userInfo: nil)

        // When
        await viewModel.loadSessions()

        // Then
        XCTAssertTrue(viewModel.sessions.isEmpty, "Should have no sessions on error")
        XCTAssertNotNil(viewModel.errorMessage, "Should have error message")
    }

    // MARK: - Sensor Data Extraction Tests

    func testHeartRateDataPoints_ExtractsCorrectly() async {
        // Given
        var session = MeditationSession.createTestSession(daysAgo: 1)
        let sample1 = HeartRateSample(timestamp: Date(), value: 72.0)
        let sample2 = HeartRateSample(timestamp: Date().addingTimeInterval(60), value: 75.0)
        session.heartRateSamples = [sample1, sample2]
        try! mockStorageService.saveSession(session)
        await viewModel.loadSessions()

        // When
        let dataPoints = viewModel.heartRateDataPoints()

        // Then
        XCTAssertEqual(dataPoints.count, 2, "Should extract 2 heart rate data points")
        XCTAssertEqual(dataPoints.first?.value, 72.0, accuracy: 0.1, "Should have correct first value")
    }

    func testHRVDataPoints_ExtractsCorrectly() async {
        // Given
        var session = MeditationSession.createTestSession(daysAgo: 1)
        let sample1 = HRVSample(timestamp: Date(), sdnn: 45.0)
        let sample2 = HRVSample(timestamp: Date().addingTimeInterval(60), sdnn: 50.0)
        session.hrvSamples = [sample1, sample2]
        try! mockStorageService.saveSession(session)
        await viewModel.loadSessions()

        // When
        let dataPoints = viewModel.hrvDataPoints()

        // Then
        XCTAssertEqual(dataPoints.count, 2, "Should extract 2 HRV data points")
        XCTAssertEqual(dataPoints.first?.value, 45.0, accuracy: 0.1, "Should have correct first value")
    }

    func testTemperatureDataPoints_ConvertsToDisplayUnit() async {
        // Given
        var session = MeditationSession.createTestSession(daysAgo: 1)
        let sample = TemperatureSample(timestamp: Date(), value: 37.0) // Celsius
        session.temperatureSamples = [sample]
        try! mockStorageService.saveSession(session)
        viewModel.temperatureUnit = .fahrenheit
        await viewModel.loadSessions()

        // When
        let dataPoints = viewModel.temperatureDataPoints()

        // Then
        XCTAssertEqual(dataPoints.count, 1, "Should extract 1 temperature data point")
        // 37°C = 98.6°F
        XCTAssertEqual(dataPoints.first?.value, 98.6, accuracy: 0.1, "Should convert to Fahrenheit")
    }

    func testCurrentSensorDataPoints_ReturnsCorrectSensorData() async {
        // Given
        var session = MeditationSession.createTestSession(daysAgo: 1)
        session.heartRateSamples = [HeartRateSample(timestamp: Date(), value: 72.0)]
        session.hrvSamples = [HRVSample(timestamp: Date(), sdnn: 45.0)]
        try! mockStorageService.saveSession(session)
        await viewModel.loadSessions()

        // When - Test heart rate
        viewModel.selectedSensor = .heartRate
        let heartRatePoints = viewModel.currentSensorDataPoints()

        // Then
        XCTAssertEqual(heartRatePoints.count, 1, "Should return heart rate data points")

        // When - Test HRV
        viewModel.selectedSensor = .hrv
        let hrvPoints = viewModel.currentSensorDataPoints()

        // Then
        XCTAssertEqual(hrvPoints.count, 1, "Should return HRV data points")
    }

    // MARK: - Statistics Tests

    func testAverageValue_CalculatesCorrectly() async {
        // Given
        var session = MeditationSession.createTestSession(daysAgo: 1)
        session.heartRateSamples = [
            HeartRateSample(timestamp: Date(), value: 70.0),
            HeartRateSample(timestamp: Date().addingTimeInterval(60), value: 80.0)
        ]
        try! mockStorageService.saveSession(session)
        viewModel.selectedSensor = .heartRate
        await viewModel.loadSessions()

        // When
        let average = viewModel.averageValue()

        // Then
        XCTAssertEqual(average, 75.0, accuracy: 0.1, "Should calculate average correctly")
    }

    func testMinValue_ReturnsMinimum() async {
        // Given
        var session = MeditationSession.createTestSession(daysAgo: 1)
        session.heartRateSamples = [
            HeartRateSample(timestamp: Date(), value: 70.0),
            HeartRateSample(timestamp: Date().addingTimeInterval(60), value: 80.0)
        ]
        try! mockStorageService.saveSession(session)
        viewModel.selectedSensor = .heartRate
        await viewModel.loadSessions()

        // When
        let min = viewModel.minValue()

        // Then
        XCTAssertEqual(min, 70.0, accuracy: 0.1, "Should return minimum value")
    }

    func testMaxValue_ReturnsMaximum() async {
        // Given
        var session = MeditationSession.createTestSession(daysAgo: 1)
        session.heartRateSamples = [
            HeartRateSample(timestamp: Date(), value: 70.0),
            HeartRateSample(timestamp: Date().addingTimeInterval(60), value: 80.0)
        ]
        try! mockStorageService.saveSession(session)
        viewModel.selectedSensor = .heartRate
        await viewModel.loadSessions()

        // When
        let max = viewModel.maxValue()

        // Then
        XCTAssertEqual(max, 80.0, accuracy: 0.1, "Should return maximum value")
    }

    // MARK: - Trend Calculation Tests

    func testCalculateTrend_ReturnsTrendWhenDataAvailable() async {
        // Given - Create data with improving trend (HRV increasing)
        var session = MeditationSession.createTestSession(daysAgo: 1)
        // Create samples with increasing HRV values
        session.hrvSamples = (0..<10).map { i in
            HRVSample(timestamp: Date().addingTimeInterval(Double(i) * 60), sdnn: 40.0 + Double(i) * 2.0)
        }
        try! mockStorageService.saveSession(session)
        viewModel.selectedSensor = .hrv
        await viewModel.loadSessions()

        // When
        let trend = viewModel.calculateTrend()

        // Then
        // May return improving, declining, or stable depending on calculation
        XCTAssertNotNil(trend, "Should return a trend")
    }

    func testCalculateTrend_ReturnsNilWhenInsufficientData() async {
        // Given
        var session = MeditationSession.createTestSession(daysAgo: 1)
        session.heartRateSamples = [HeartRateSample(timestamp: Date(), value: 72.0)] // Only 1 sample
        try! mockStorageService.saveSession(session)
        viewModel.selectedSensor = .heartRate
        await viewModel.loadSessions()

        // When
        let trend = viewModel.calculateTrend()

        // Then
        XCTAssertNil(trend, "Should return nil when insufficient data")
    }

    // MARK: - Session Statistics Tests

    func testSessionCount_ReturnsCorrectCount() async {
        // Given
        let session1 = MeditationSession.createTestSession(daysAgo: 1)
        let session2 = MeditationSession.createTestSession(daysAgo: 2)
        try! mockStorageService.saveSession(session1)
        try! mockStorageService.saveSession(session2)
        await viewModel.loadSessions()

        // Then
        XCTAssertEqual(viewModel.sessionCount, 2, "Should return correct session count")
    }

    func testTotalMinutes_CalculatesCorrectly() async {
        // Given
        let session1 = MeditationSession.createTestSession(daysAgo: 1, durationMinutes: 20.0)
        let session2 = MeditationSession.createTestSession(daysAgo: 2, durationMinutes: 15.0)
        try! mockStorageService.saveSession(session1)
        try! mockStorageService.saveSession(session2)
        await viewModel.loadSessions()

        // Then
        XCTAssertEqual(viewModel.totalMinutes, 35.0, accuracy: 0.1, "Should calculate total minutes correctly")
    }
}


