//
//  FeatureGateServiceTests.swift
//  PlenaTests
//
//  Unit tests for FeatureGateService
//

import XCTest
import Combine
@testable import PlenaShared

@MainActor
final class FeatureGateServiceTests: XCTestCase {
    var mockSubscriptionService: MockSubscriptionService!
    var featureGateService: FeatureGateService!

    override func setUp() {
        super.setUp()
        mockSubscriptionService = MockSubscriptionService()
        featureGateService = FeatureGateService(subscriptionService: mockSubscriptionService)
    }

    override func tearDown() {
        featureGateService = nil
        mockSubscriptionService = nil
        super.tearDown()
    }

    // MARK: - Feature Access Tests

    func testHasAccess_WhenNotSubscribed_ReturnsFalse() {
        // Given
        mockSubscriptionService.mockSubscriptionStatus = .notSubscribed

        // When
        let hasAccess = featureGateService.hasAccess(to: .readinessScore)

        // Then
        XCTAssertFalse(hasAccess, "Free tier should not have access to readiness score")
    }

    func testHasAccess_WhenSubscribed_ReturnsTrue() {
        // Given
        let expirationDate = Date().addingTimeInterval(86400 * 30) // 30 days from now
        mockSubscriptionService.mockSubscriptionStatus = .subscribed(tier: .premium, expirationDate: expirationDate)

        // When
        let hasAccess = featureGateService.hasAccess(to: .readinessScore)

        // Then
        XCTAssertTrue(hasAccess, "Premium tier should have access to readiness score")
    }

    func testHasAccess_WhenExpired_ReturnsFalse() {
        // Given
        mockSubscriptionService.mockSubscriptionStatus = .expired

        // When
        let hasAccess = featureGateService.hasAccess(to: .readinessScore)

        // Then
        XCTAssertFalse(hasAccess, "Expired subscription should not have access")
    }

    // MARK: - Time Range Access Tests

    func testHasAccessToTimeRange_DayAndWeek_AlwaysAvailable() {
        // Given
        mockSubscriptionService.mockSubscriptionStatus = .notSubscribed

        // When/Then
        XCTAssertTrue(featureGateService.hasAccessToTimeRange(.day), "Day view should be available for free tier")
        XCTAssertTrue(featureGateService.hasAccessToTimeRange(.week), "Week view should be available for free tier")
    }

    func testHasAccessToTimeRange_MonthAndYear_RequiresPremium() {
        // Given - Free tier
        mockSubscriptionService.mockSubscriptionStatus = .notSubscribed

        // When/Then
        XCTAssertFalse(featureGateService.hasAccessToTimeRange(.month), "Month view should require premium")
        XCTAssertFalse(featureGateService.hasAccessToTimeRange(.year), "Year view should require premium")
    }

    func testHasAccessToTimeRange_MonthAndYear_WithPremium_ReturnsTrue() {
        // Given - Premium tier
        let expirationDate = Date().addingTimeInterval(86400 * 30)
        mockSubscriptionService.mockSubscriptionStatus = .subscribed(tier: .premium, expirationDate: expirationDate)

        // When/Then
        XCTAssertTrue(featureGateService.hasAccessToTimeRange(.month), "Month view should be available for premium")
        XCTAssertTrue(featureGateService.hasAccessToTimeRange(.year), "Year view should be available for premium")
    }

    // MARK: - Sensor Access Tests

    func testHasAccessToSensor_BasicSensors_AlwaysAvailable() {
        // Given
        mockSubscriptionService.mockSubscriptionStatus = .notSubscribed

        // When/Then
        XCTAssertTrue(featureGateService.hasAccessToSensor("Heart Rate"), "Heart Rate should be available for free tier")
        XCTAssertTrue(featureGateService.hasAccessToSensor("HRV"), "HRV should be available for free tier")
        XCTAssertTrue(featureGateService.hasAccessToSensor("Respiratory Rate"), "Respiratory Rate should be available for free tier")
    }

    func testHasAccessToSensor_AdvancedSensors_RequiresPremium() {
        // Given - Free tier
        mockSubscriptionService.mockSubscriptionStatus = .notSubscribed

        // When/Then
        XCTAssertFalse(featureGateService.hasAccessToSensor("Temperature"), "Temperature should require premium")
        XCTAssertFalse(featureGateService.hasAccessToSensor("VO₂ Max"), "VO₂ Max should require premium")
        XCTAssertFalse(featureGateService.hasAccessToSensor("VO2Max"), "VO2Max should require premium")
    }

    func testHasAccessToSensor_AdvancedSensors_WithPremium_ReturnsTrue() {
        // Given - Premium tier
        let expirationDate = Date().addingTimeInterval(86400 * 30)
        mockSubscriptionService.mockSubscriptionStatus = .subscribed(tier: .premium, expirationDate: expirationDate)

        // When/Then
        XCTAssertTrue(featureGateService.hasAccessToSensor("Temperature"), "Temperature should be available for premium")
        XCTAssertTrue(featureGateService.hasAccessToSensor("VO₂ Max"), "VO₂ Max should be available for premium")
    }

    // MARK: - Subscription Status Observable Tests

    func testSubscriptionStatus_IsObservable() async {
        // Given
        let expectation = XCTestExpectation(description: "Status update received")
        var receivedStatus: SubscriptionStatus?
        let cancellable = featureGateService.subscriptionStatus
            .sink { status in
                receivedStatus = status
                expectation.fulfill()
            }

        // When
        let expirationDate = Date().addingTimeInterval(86400 * 30)
        mockSubscriptionService.mockSubscriptionStatus = .subscribed(tier: .premium, expirationDate: expirationDate)
        await mockSubscriptionService.checkSubscriptionStatus()

        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertNotNil(receivedStatus, "Should receive subscription status")
        if let status = receivedStatus {
            XCTAssertTrue(status.isPremium, "Should receive premium status")
        }
        cancellable.cancel()
    }

    // MARK: - Async Access Check Tests

    func testCheckAccess_RefreshesStatus() async {
        // Given
        mockSubscriptionService.mockSubscriptionStatus = .notSubscribed

        // When
        let hasAccess = await featureGateService.checkAccess(to: .readinessScore)

        // Then
        XCTAssertFalse(hasAccess, "Should not have access")
        XCTAssertTrue(mockSubscriptionService.checkSubscriptionStatusCalled, "Should check subscription status")
    }
}



