//
//  TestUtilities.swift
//  PlenaTests
//
//  Shared test utilities and mocks for all test files
//

import Foundation
import Combine
import StoreKit
@testable import PlenaShared

// MARK: - Mock HealthKitService

class MockHealthKitService: HealthKitServiceProtocol {
    var shouldThrowError = false
    var mockVO2Max: Double? = 45.0
    var mockTemperature: Double? = 37.0
    var mockHeartRate: Double = 72.0
    var mockHRV: Double = 45.0
    var mockRespiratoryRate: Double = 16.0

    // Track query state
    var heartRateHandler: HeartRateHandler?
    var hrvHandler: HRVHandler?
    var respiratoryHandler: RespiratoryRateHandler?
    var vo2MaxHandler: VO2MaxHandler?
    var temperatureHandler: TemperatureHandler?

    // Simulate data updates
    func simulateHeartRateUpdate(_ value: Double) {
        heartRateHandler?(value)
    }

    func simulateHRVUpdate(_ value: Double) {
        hrvHandler?(value)
    }

    func simulateRespiratoryRateUpdate(_ value: Double) {
        respiratoryHandler?(value)
    }

    func simulateVO2MaxUpdate(_ value: Double) {
        vo2MaxHandler?(value)
    }

    func simulateTemperatureUpdate(_ value: Double) {
        temperatureHandler?(value)
    }

    func requestAuthorization() async throws {
        if shouldThrowError {
            throw HealthKitError.notAuthorized
        }
    }

    func startHeartRateQuery(handler: @escaping HeartRateHandler) throws {
        if shouldThrowError {
            throw HealthKitError.notAvailable
        }
        heartRateHandler = handler
        // Simulate immediate update
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            handler(self.mockHeartRate)
        }
    }

    func startHRVQuery(handler: @escaping HRVHandler) throws {
        if shouldThrowError {
            throw HealthKitError.notAvailable
        }
        hrvHandler = handler
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            handler(self.mockHRV)
        }
    }

    func startRespiratoryRateQuery(handler: @escaping RespiratoryRateHandler) throws {
        if shouldThrowError {
            throw HealthKitError.notAvailable
        }
        respiratoryHandler = handler
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            handler(self.mockRespiratoryRate)
        }
    }

    func startVO2MaxQuery(handler: @escaping VO2MaxHandler) throws {
        if shouldThrowError {
            throw HealthKitError.notAvailable
        }
        vo2MaxHandler = handler
        if let vo2Max = mockVO2Max {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                handler(vo2Max)
            }
        }
    }

    func startTemperatureQuery(handler: @escaping TemperatureHandler) throws {
        if shouldThrowError {
            throw HealthKitError.notAvailable
        }
        temperatureHandler = handler
        if let temp = mockTemperature {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                handler(temp)
            }
        }
    }

    func stopAllQueries() {
        heartRateHandler = nil
        hrvHandler = nil
        respiratoryHandler = nil
        vo2MaxHandler = nil
        temperatureHandler = nil
    }

    func fetchLatestVO2Max() async throws -> Double? {
        if shouldThrowError {
            throw HealthKitError.notAvailable
        }
        return mockVO2Max
    }

    func fetchLatestTemperature() async throws -> Double? {
        if shouldThrowError {
            throw HealthKitError.notAvailable
        }
        return mockTemperature
    }

    func startPeriodicVO2MaxQuery(interval: TimeInterval, handler: @escaping VO2MaxHandler) throws {
        if shouldThrowError {
            throw HealthKitError.notAvailable
        }
        vo2MaxHandler = handler
        if let vo2Max = mockVO2Max {
            handler(vo2Max)
        }
    }

    func startPeriodicTemperatureQuery(interval: TimeInterval, handler: @escaping TemperatureHandler) throws {
        if shouldThrowError {
            throw HealthKitError.notAvailable
        }
        temperatureHandler = handler
        if let temp = mockTemperature {
            handler(temp)
        }
    }

    func saveMindfulSession(startDate: Date, endDate: Date) async throws {
        if shouldThrowError {
            throw HealthKitError.notAuthorized
        }
    }

    func fetchMindfulSessions(startDate: Date, endDate: Date) async throws -> [MindfulSession] {
        if shouldThrowError {
            throw HealthKitError.notAvailable
        }
        return []
    }
}

// MARK: - Mock Storage Service

class MockStorageService: SessionStorageServiceProtocol {
    var savedSessions: [MeditationSession] = []
    var shouldThrowError = false
    var loadError: Error?

    func saveSession(_ session: MeditationSession) throws {
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock save error"])
        }
        // Remove existing session if it has the same ID (update)
        savedSessions.removeAll { $0.id == session.id }
        savedSessions.append(session)
        // Sort by start date (newest first)
        savedSessions.sort { $0.startDate > $1.startDate }
    }

    func loadAllSessions() throws -> [MeditationSession] {
        if let error = loadError {
            throw error
        }
        return savedSessions
    }

    func loadSessions(startDate: Date, endDate: Date) throws -> [MeditationSession] {
        if let error = loadError {
            throw error
        }
        return savedSessions.filter { session in
            session.startDate >= startDate && session.startDate <= endDate
        }
    }

    func deleteSession(_ session: MeditationSession) throws {
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock delete error"])
        }
        savedSessions.removeAll { $0.id == session.id }
    }
}

// MARK: - Test Data Helpers

extension MeditationSession {
    static func createTestSession(
        daysAgo: Int = 0,
        durationMinutes: Double = 20.0,
        heartRateSamples: [HeartRateSample] = [],
        hrvSamples: [HRVSample] = [],
        respiratorySamples: [RespiratoryRateSample] = []
    ) -> MeditationSession {
        let calendar = Calendar.current
        let now = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -daysAgo, to: now) else {
            return MeditationSession()
        }

        var session = MeditationSession(startDate: startDate)
        session.endDate = startDate.addingTimeInterval(durationMinutes * 60.0)
        session.heartRateSamples = heartRateSamples
        session.hrvSamples = hrvSamples
        session.respiratoryRateSamples = respiratorySamples

        return session
    }
}

// MARK: - Mock Subscription Service

@MainActor
class MockSubscriptionService: SubscriptionServiceProtocol {
    var subscriptionStatus = CurrentValueSubject<SubscriptionStatus, Never>(.notSubscribed)
    var isLoading = CurrentValueSubject<Bool, Never>(false)

    private(set) var loadProductsCalled = false
    private(set) var purchaseCalled = false
    private(set) var restorePurchasesCalled = false
    private(set) var checkSubscriptionStatusCalled = false

    var mockProducts: [Product] = []
    var mockSubscriptionStatus: SubscriptionStatus = .notSubscribed
    var shouldFailPurchase = false
    var shouldFailRestore = false

    func loadProducts() async throws -> [Product] {
        loadProductsCalled = true
        isLoading.send(true)
        defer { isLoading.send(false) }
        return mockProducts
    }

    func purchase(_ product: Product) async throws -> Transaction? {
        purchaseCalled = true
        isLoading.send(true)
        defer { isLoading.send(false) }

        if shouldFailPurchase {
            throw SubscriptionError.purchaseFailed(NSError(domain: "TestError", code: 1))
        }

        // Simulate successful purchase
        mockSubscriptionStatus = .subscribed(tier: .premium, expirationDate: Date().addingTimeInterval(86400 * 30))
        subscriptionStatus.send(mockSubscriptionStatus)
        return nil // In real implementation, would return transaction
    }

    func restorePurchases() async throws {
        restorePurchasesCalled = true
        isLoading.send(true)
        defer { isLoading.send(false) }

        if shouldFailRestore {
            throw SubscriptionError.verificationFailed(NSError(domain: "TestError", code: 1))
        }

        // Simulate restore
        await checkSubscriptionStatus()
    }

    func checkSubscriptionStatus() async {
        checkSubscriptionStatusCalled = true
        subscriptionStatus.send(mockSubscriptionStatus)
    }

    func currentSubscriptionStatus() -> SubscriptionStatus {
        return mockSubscriptionStatus
    }
}







