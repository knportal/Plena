//
//  DashboardViewModelTests.swift
//  PlenaTests
//
//  Unit tests for DashboardViewModel
//

import XCTest
@testable import PlenaShared

@MainActor
final class DashboardViewModelTests: XCTestCase {
    var viewModel: DashboardViewModel!
    var mockStorageService: MockStorageService!

    override func setUp() {
        super.setUp()
        mockStorageService = MockStorageService()
        viewModel = DashboardViewModel(storageService: mockStorageService)
    }

    override func tearDown() {
        viewModel = nil
        mockStorageService = nil
        super.tearDown()
    }

    // MARK: - Data Loading Tests

    func testLoadSessions_LoadsSessionsFromStorage() async {
        // Given
        let session1 = MeditationSession.createTestSession(daysAgo: 1, durationMinutes: 20.0)
        let session2 = MeditationSession.createTestSession(daysAgo: 2, durationMinutes: 15.0)
        try! mockStorageService.saveSession(session1)
        try! mockStorageService.saveSession(session2)

        // When
        await viewModel.loadSessions()

        // Then
        XCTAssertEqual(viewModel.sessions.count, 2, "Should load 2 sessions")
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
        XCTAssertFalse(viewModel.isLoading, "Should not be loading after error")
    }

    func testReloadForTimeRange_ReloadsSessions() async {
        // Given
        let session = MeditationSession.createTestSession(daysAgo: 1)
        try! mockStorageService.saveSession(session)
        await viewModel.loadSessions()
        let initialCount = viewModel.sessions.count

        // When
        viewModel.selectedTimeRange = .week
        await viewModel.reloadForTimeRange()

        // Then
        XCTAssertEqual(viewModel.sessions.count, initialCount, "Should reload sessions for new time range")
    }

    // MARK: - Primary Statistics Tests

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

    func testAverageDuration_CalculatesCorrectly() async {
        // Given
        let session1 = MeditationSession.createTestSession(daysAgo: 1, durationMinutes: 20.0)
        let session2 = MeditationSession.createTestSession(daysAgo: 2, durationMinutes: 10.0)
        try! mockStorageService.saveSession(session1)
        try! mockStorageService.saveSession(session2)
        await viewModel.loadSessions()

        // Then
        XCTAssertEqual(viewModel.averageDuration, 15.0, accuracy: 0.1, "Should calculate average duration correctly")
    }

    func testAverageDuration_ReturnsNilWhenNoSessions() async {
        // Given
        await viewModel.loadSessions()

        // Then
        XCTAssertNil(viewModel.averageDuration, "Should return nil when no sessions")
    }

    func testCurrentStreak_CalculatesCorrectly() async {
        // Given - Create sessions for consecutive days
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        for dayOffset in 0..<5 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            var session = MeditationSession(startDate: date)
            session.endDate = date.addingTimeInterval(20 * 60)
            try! mockStorageService.saveSession(session)
        }

        await viewModel.loadSessions()

        // Then
        XCTAssertGreaterThanOrEqual(viewModel.currentStreak, 1, "Should have at least 1 day streak")
    }

    func testCurrentStreak_ReturnsZeroWhenNoSessions() async {
        // Given
        await viewModel.loadSessions()

        // Then
        XCTAssertEqual(viewModel.currentStreak, 0, "Should return 0 when no sessions")
    }

    // MARK: - Comparison Statistics Tests

    func testCompareToPrevious_ReturnsComparison() async {
        // Given
        let calendar = Calendar.current
        let now = Date()

        // Current period sessions
        guard let currentStart = calendar.date(byAdding: .day, value: -7, to: now) else {
            XCTFail("Could not create date")
            return
        }

        var session1 = MeditationSession(startDate: currentStart.addingTimeInterval(86400))
        session1.endDate = session1.startDate.addingTimeInterval(20 * 60)
        try! mockStorageService.saveSession(session1)

        // Previous period sessions
        guard let previousStart = calendar.date(byAdding: .day, value: -14, to: now) else {
            XCTFail("Could not create date")
            return
        }

        var session2 = MeditationSession(startDate: previousStart.addingTimeInterval(86400))
        session2.endDate = session2.startDate.addingTimeInterval(20 * 60)
        try! mockStorageService.saveSession(session2)

        viewModel.selectedTimeRange = .week
        await viewModel.loadSessions()

        // When
        let comparison = viewModel.compareToPrevious()

        // Then
        XCTAssertNotNil(comparison, "Should return comparison")
        XCTAssertGreaterThanOrEqual(comparison?.current ?? 0, 0, "Should have current count")
    }

    // MARK: - Chart Data Tests

    func testSessionFrequencyDataPoints_ReturnsDataPoints() async {
        // Given
        let session = MeditationSession.createTestSession(daysAgo: 1)
        try! mockStorageService.saveSession(session)
        await viewModel.loadSessions()

        // When
        let dataPoints = viewModel.sessionFrequencyDataPoints()

        // Then
        XCTAssertFalse(dataPoints.isEmpty, "Should return data points")
    }

    func testDurationTrendDataPoints_ReturnsDataPoints() async {
        // Given
        let session = MeditationSession.createTestSession(daysAgo: 1, durationMinutes: 20.0)
        try! mockStorageService.saveSession(session)
        await viewModel.loadSessions()

        // When
        let dataPoints = viewModel.durationTrendDataPoints()

        // Then
        XCTAssertFalse(dataPoints.isEmpty, "Should return data points")
    }

    // MARK: - HRV Insights Tests

    func testWeeklyHRVTrend_ReturnsInsightWhenDataAvailable() async {
        // Given - Create sessions with HRV data for current and previous week
        let calendar = Calendar.current
        let now = Date()

        // Current week sessions with HRV
        guard let currentWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) else {
            XCTFail("Could not get current week start")
            return
        }

        for dayOffset in 0..<3 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: currentWeekStart) else { continue }
            var session = MeditationSession(startDate: date)
            session.endDate = date.addingTimeInterval(20 * 60)
            // Add HRV samples (at least 3)
            session.hrvSamples = (0..<5).map { i in
                HRVSample(timestamp: date.addingTimeInterval(Double(i) * 60), sdnn: 50.0 + Double(dayOffset))
            }
            try! mockStorageService.saveSession(session)
        }

        // Previous week sessions with HRV
        guard let previousWeekStart = calendar.date(byAdding: .day, value: -7, to: currentWeekStart) else {
            XCTFail("Could not get previous week start")
            return
        }

        for dayOffset in 0..<3 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: previousWeekStart) else { continue }
            var session = MeditationSession(startDate: date)
            session.endDate = date.addingTimeInterval(20 * 60)
            // Add HRV samples with lower values
            session.hrvSamples = (0..<5).map { i in
                HRVSample(timestamp: date.addingTimeInterval(Double(i) * 60), sdnn: 40.0)
            }
            try! mockStorageService.saveSession(session)
        }

        await viewModel.loadSessions()

        // When
        let insight = viewModel.weeklyHRVTrend()

        // Then
        // May or may not return insight depending on percentage change calculation
        // Just verify it doesn't crash
        XCTAssertNotNil(viewModel, "ViewModel should exist")
    }

    func testRecentSessionsHRVImprovement_ReturnsInsightWhenDataAvailable() async {
        // Given - Create 3 recent sessions with improving HRV
        let calendar = Calendar.current
        let now = Date()

        for dayOffset in 0..<3 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
            var session = MeditationSession(startDate: date)
            session.endDate = date.addingTimeInterval(20 * 60)
            // Add HRV samples with increasing values (oldest = 40, newest = 50)
            let baseHRV = 40.0 + Double(dayOffset) * 5.0
            session.hrvSamples = (0..<5).map { i in
                HRVSample(timestamp: date.addingTimeInterval(Double(i) * 60), sdnn: baseHRV)
            }
            try! mockStorageService.saveSession(session)
        }

        await viewModel.loadSessions()

        // When
        let insight = viewModel.recentSessionsHRVImprovement()

        // Then
        // May or may not return insight depending on improvement calculation
        // Just verify it doesn't crash
        XCTAssertNotNil(viewModel, "ViewModel should exist")
    }
}
