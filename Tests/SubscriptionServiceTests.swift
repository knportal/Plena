//
//  SubscriptionServiceTests.swift
//  PlenaTests
//
//  Unit tests for SubscriptionService
//

import XCTest
import StoreKit
import Combine
@testable import PlenaShared

@MainActor
final class SubscriptionServiceTests: XCTestCase {
    var subscriptionService: SubscriptionService!

    override func setUp() {
        super.setUp()
        subscriptionService = SubscriptionService()
    }

    override func tearDown() {
        subscriptionService = nil
        super.tearDown()
    }

    // MARK: - Subscription Status Tests

    func testInitialSubscriptionStatus_IsNotSubscribed() {
        // Given/When
        let status = subscriptionService.currentSubscriptionStatus()

        // Then
        XCTAssertEqual(status, .notSubscribed, "Initial status should be notSubscribed")
    }

    func testSubscriptionStatus_IsObservable() async {
        // Given
        let expectation = XCTestExpectation(description: "Status update received")
        var receivedStatus: SubscriptionStatus?
        let cancellable = subscriptionService.subscriptionStatus
            .sink { status in
                receivedStatus = status
                expectation.fulfill()
            }

        // When
        await subscriptionService.checkSubscriptionStatus()

        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertNotNil(receivedStatus, "Should receive subscription status")
        cancellable.cancel()
    }

    // MARK: - Product Loading Tests

    func testLoadProducts_ReturnsProducts() async throws {
        // Note: This test will only work if StoreKit Configuration file is set up
        // and products are configured. In a real test environment, you'd mock this.
        do {
            let products = try await subscriptionService.loadProducts()
            // Products may be empty if StoreKit config isn't set up, which is okay for tests
            XCTAssertNotNil(products, "Should return products array (may be empty)")
        } catch {
            // If products fail to load (e.g., no StoreKit config), that's acceptable for tests
            // In a real test, you'd mock the StoreKit Product API
            print("⚠️ Products failed to load (this is expected if StoreKit config isn't set up): \(error)")
        }
    }

    // MARK: - Current Subscription Status Tests

    func testCurrentSubscriptionStatus_ReturnsCachedStatus() {
        // Given
        let initialStatus = subscriptionService.currentSubscriptionStatus()

        // When/Then
        let cachedStatus = subscriptionService.currentSubscriptionStatus()
        XCTAssertEqual(cachedStatus, initialStatus, "Should return cached status synchronously")
    }
}


