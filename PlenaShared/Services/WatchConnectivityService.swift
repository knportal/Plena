//
//  WatchConnectivityService.swift
//  PlenaShared
//
//  Created on [Date]
//

import Foundation
import Combine

#if os(iOS) || os(watchOS)
import WatchConnectivity
#endif

/// Represents the connection status of Apple Watch
enum WatchConnectionStatus {
    case notSupported
    case notPaired
    case notInstalled
    case connected
    case disconnected

    var displayName: String {
        switch self {
        case .notSupported:
            return "Watch Not Supported"
        case .notPaired:
            return "Watch Not Paired"
        case .notInstalled:
            return "Watch App Not Installed"
        case .connected:
            return "Watch Connected"
        case .disconnected:
            return "Watch Disconnected"
        }
    }

    var icon: String {
        switch self {
        case .notSupported, .notPaired, .notInstalled, .disconnected:
            return "applewatch.slash"
        case .connected:
            return "applewatch"
        }
    }

    var color: String {
        switch self {
        case .notSupported, .notPaired, .notInstalled, .disconnected:
            return "WarningColor"
        case .connected:
            return "SuccessColor"
        }
    }
}

/// Live sensor sample for best-effort streaming from Watch to iPhone
struct LiveSensorSample: Codable {
    enum SensorType: String, Codable {
        case heartRate
        case hrv
        case respiratoryRate
        case vo2Max
        case temperature
    }

    let sensorType: SensorType
    let value: Double
    let timestamp: Date
}

/// Message payload wrapper for WatchConnectivity message data
/// Provides type discrimination for robust message handling
private struct MessagePayload: Codable {
    let type: String
    let data: Data

    enum CodingKeys: String, CodingKey {
        case type
        case data
    }
}

/// Message type discriminators
private enum MessageType {
    static let liveSample = "liveSample"
    // Future message types can be added here:
    // static let healthAlert = "healthAlert"
    // static let sessionSync = "sessionSync"
}

protocol WatchConnectivityServiceProtocol {
    var connectionStatus: WatchConnectionStatus { get }
    var isWatchReachable: Bool { get }
    var connectionStatusPublisher: AnyPublisher<WatchConnectionStatus, Never> { get }
    var isWatchReachablePublisher: AnyPublisher<Bool, Never> { get }
    func startMonitoring()
    func stopMonitoring()

    // Session data sync
    func sendSession(_ session: MeditationSession) async throws
    func onSessionReceived(_ handler: @escaping (MeditationSession) -> Void)

    // Post-session package sync
    func sendSessionPackage(_ package: SessionSyncPackage) async throws
    func onSessionPackageReceived(_ handler: @escaping (SessionSyncPackage) -> Void)

    // Workout session coordination
    #if os(iOS)
    func requestWatchStartWorkoutSession() async throws
    func requestWatchStartMeditationSession() async throws
    func requestWatchStopSession() async throws
    #endif

    #if os(watchOS)
    func onWorkoutSessionRequested(_ handler: @escaping () -> Void)
    func onMeditationSessionRequested(_ handler: @escaping () -> Void)
    func onSessionStopRequested(_ handler: @escaping () -> Void)
    #endif

    // Live sample sync
    func sendLiveSample(_ sample: LiveSensorSample) async throws
    func onLiveSampleReceived(_ handler: @escaping (LiveSensorSample) -> Void)
}

class WatchConnectivityService: NSObject, WatchConnectivityServiceProtocol, ObservableObject {
    static let shared = WatchConnectivityService()

    #if os(iOS) || os(watchOS)
    private let session: WCSession?
    #else
    private let session: Any? = nil
    #endif
    private var isMonitoring = false

    @Published private(set) var connectionStatus: WatchConnectionStatus = .notSupported
    @Published private(set) var isWatchReachable: Bool = false

    // Handler for received sessions (iPhone side)
    private var sessionReceivedHandler: ((MeditationSession) -> Void)?

    // Handler for received session packages (iPhone side)
    private var sessionPackageReceivedHandler: ((SessionSyncPackage) -> Void)?

    // Handler for live samples (iPhone side)
    private var liveSampleReceivedHandler: ((LiveSensorSample) -> Void)?

    // Handler for workout session requests (watchOS side)
    #if os(watchOS)
    private var workoutSessionRequestedHandler: (() -> Void)?
    private var meditationSessionRequestedHandler: (() -> Void)?
    private var sessionStopRequestedHandler: (() -> Void)?
    #endif

    // Track activation state and queue pending sessions (watchOS only)
    #if os(watchOS)
    private var isActivated = false
    private var pendingSessions: [MeditationSession] = []
    private let activationQueue = DispatchQueue(label: "com.plena.watchconnectivity.activation")
    #endif

    // Track recently received session IDs to prevent duplicate processing (iOS only)
    #if os(iOS)
    private var recentlyReceivedSessionIDs: Set<UUID> = []
    private let receivedSessionsQueue = DispatchQueue(label: "com.plena.receivedSessions")
    #endif

    var connectionStatusPublisher: AnyPublisher<WatchConnectionStatus, Never> {
        $connectionStatus.eraseToAnyPublisher()
    }

    var isWatchReachablePublisher: AnyPublisher<Bool, Never> {
        $isWatchReachable.eraseToAnyPublisher()
    }

    override init() {
        #if os(iOS)
        if WCSession.isSupported() {
            self.session = WCSession.default
        } else {
            self.session = nil
            self.connectionStatus = .notSupported
        }
        super.init()

        if let session = session {
            session.delegate = self
            session.activate()
        }
        #elseif os(watchOS)
        if WCSession.isSupported() {
            self.session = WCSession.default
        } else {
            self.session = nil
            self.connectionStatus = .notSupported
        }
        super.init()

        if let session = session {
            session.delegate = self
            session.activate()
        }
        #else
        // WatchConnectivity monitoring is only needed on iOS/watchOS
        // session is already initialized to nil in property declaration
        self.connectionStatus = .notSupported
        super.init()
        #endif
    }

    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        updateConnectionStatus()
    }

    func stopMonitoring() {
        isMonitoring = false
    }

    // MARK: - Session Data Sync

    /// Send session data from Watch to iPhone
    func sendSession(_ meditationSession: MeditationSession) async throws {
        #if os(watchOS)
        guard WCSession.isSupported() else {
            throw NSError(domain: "WatchConnectivityService", code: 1, userInfo: [NSLocalizedDescriptionKey: "WatchConnectivity not supported"])
        }

        let wcSession = WCSession.default

        // Wait for activation (with timeout)
        if wcSession.activationState != .activated {
            print("⏳ Waiting for WatchConnectivity activation...")

            // Wait up to 5 seconds for activation
            let startTime = Date()
            while wcSession.activationState != .activated && Date().timeIntervalSince(startTime) < 5.0 {
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
            }
        }

        guard wcSession.activationState == .activated else {
            // If still not activated, queue the session to send later
            activationQueue.sync {
                pendingSessions.append(meditationSession)
            }
            print("⏸️ Session \(meditationSession.id) queued - will send when WatchConnectivity activates")
            return // Don't throw - session is queued and will be sent later
        }

        // Session is activated, send it
        try await sendSessionInternal(meditationSession)
        #else
        // On iOS, this method shouldn't be called (sessions are created on iPhone)
        throw NSError(domain: "WatchConnectivityService", code: 3, userInfo: [NSLocalizedDescriptionKey: "sendSession should only be called from watchOS"])
        #endif
    }

    #if os(watchOS)
    /// Send any pending sessions (called after activation)
    private func sendPendingSessions() {
        let sessionsToSend = activationQueue.sync {
            let sessions = pendingSessions
            pendingSessions.removeAll()
            return sessions
        }

        guard !sessionsToSend.isEmpty else { return }

        print("📤 Sending \(sessionsToSend.count) pending session(s)...")

        Task {
            for session in sessionsToSend {
                do {
                    try await sendSessionInternal(session)
                } catch {
                    print("❌ Failed to send queued session \(session.id): \(error)")
                }
            }
        }
    }

    /// Internal method to send session (without activation check/queue logic)
    private func sendSessionInternal(_ meditationSession: MeditationSession) async throws {
        guard WCSession.isSupported() else {
            throw NSError(domain: "WatchConnectivityService", code: 1, userInfo: [NSLocalizedDescriptionKey: "WatchConnectivity not supported"])
        }

        let wcSession = WCSession.default
        guard wcSession.activationState == .activated else {
            throw NSError(domain: "WatchConnectivityService", code: 2, userInfo: [NSLocalizedDescriptionKey: "WatchConnectivity session not activated"])
        }

        // Encode session to JSON
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let sessionData = try encoder.encode(meditationSession)

        // Send as application context (reliable, persists even if iPhone app is closed)
        let context: [String: Any] = [
            "sessionData": sessionData,
            "timestamp": Date().timeIntervalSince1970
        ]

        do {
            try wcSession.updateApplicationContext(context)
            print("✅ Sent session \(meditationSession.id) to iPhone via WatchConnectivity")
        } catch {
            print("❌ Error sending session to iPhone: \(error)")
            throw error
        }
    }
    #endif

    /// Set handler for received sessions (iPhone side)
    func onSessionReceived(_ handler: @escaping (MeditationSession) -> Void) {
        self.sessionReceivedHandler = handler
    }

    // MARK: - Session Package Sync

    /// Send session package from Watch to iPhone (post-session)
    func sendSessionPackage(_ package: SessionSyncPackage) async throws {
        #if os(watchOS)
        guard WCSession.isSupported() else {
            throw NSError(domain: "WatchConnectivityService", code: 1, userInfo: [NSLocalizedDescriptionKey: "WatchConnectivity not supported"])
        }

        let wcSession = WCSession.default

        // Wait for activation (with timeout)
        if wcSession.activationState != .activated {
            print("⏳ Waiting for WatchConnectivity activation...")
            let startTime = Date()
            while wcSession.activationState != .activated && Date().timeIntervalSince(startTime) < 5.0 {
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
            }
        }

        guard wcSession.activationState == .activated else {
            throw NSError(domain: "WatchConnectivityService", code: 2, userInfo: [NSLocalizedDescriptionKey: "WatchConnectivity session not activated"])
        }

        // Encode package to JSON
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let packageData = try encoder.encode(package)

        // Use transferUserInfo for reliable post-session transfer (works even if iPhone app is backgrounded)
        let userInfo: [String: Any] = [
            "sessionPackage": packageData,
            "timestamp": Date().timeIntervalSince1970,
            "type": "sessionPackage"
        ]

        wcSession.transferUserInfo(userInfo)
        print("✅ Sent session package \(package.sessionId) to iPhone via WatchConnectivity")
        #else
        throw NSError(domain: "WatchConnectivityService", code: 3, userInfo: [NSLocalizedDescriptionKey: "sendSessionPackage should only be called from watchOS"])
        #endif
    }

    /// Set handler for received session packages (iPhone side)
    func onSessionPackageReceived(_ handler: @escaping (SessionSyncPackage) -> Void) {
        self.sessionPackageReceivedHandler = handler
    }

    #if os(watchOS)
    /// Notify iPhone that session started (so it can start timer display)
    func notifyIPhoneSessionStarted(sessionId: UUID, startDate: Date) async throws {
        guard WCSession.isSupported() else {
            return // Silently fail - not critical
        }

        let wcSession = WCSession.default
        guard wcSession.activationState == .activated else {
            return // Silently fail - not critical
        }

        let message: [String: Any] = [
            "action": "sessionStarted",
            "sessionId": sessionId.uuidString,
            "startDate": startDate.timeIntervalSince1970,
            "timestamp": Date().timeIntervalSince1970
        ]

        if wcSession.isReachable {
            wcSession.sendMessage(message, replyHandler: nil) { error in
                print("⚠️ Error notifying iPhone of session start: \(error.localizedDescription)")
            }
        } else {
            // Use application context as fallback
            let context: [String: Any] = [
                "action": "sessionStarted",
                "sessionId": sessionId.uuidString,
                "startDate": startDate.timeIntervalSince1970,
                "timestamp": Date().timeIntervalSince1970
            ]
            try? wcSession.updateApplicationContext(context)
        }
    }

    /// Notify iPhone that session ended (so it can stop timer display)
    func notifyIPhoneSessionEnded(sessionId: UUID) async throws {
        guard WCSession.isSupported() else {
            return // Silently fail - not critical
        }

        let wcSession = WCSession.default
        guard wcSession.activationState == .activated else {
            return // Silently fail - not critical
        }

        let message: [String: Any] = [
            "action": "sessionEnded",
            "sessionId": sessionId.uuidString,
            "timestamp": Date().timeIntervalSince1970
        ]

        if wcSession.isReachable {
            wcSession.sendMessage(message, replyHandler: nil) { error in
                print("⚠️ Error notifying iPhone of session end: \(error.localizedDescription)")
            }
        } else {
            // Use application context as fallback
            let context: [String: Any] = [
                "action": "sessionEnded",
                "sessionId": sessionId.uuidString,
                "timestamp": Date().timeIntervalSince1970
            ]
            try? wcSession.updateApplicationContext(context)
        }
    }
    #endif

    // MARK: - Live Sample Sync

    /// Send live sensor sample from Watch to iPhone
    func sendLiveSample(_ sample: LiveSensorSample) async throws {
        #if os(watchOS)
        guard WCSession.isSupported() else {
            print("⚠️ WatchConnectivity not supported - cannot send live sample")
            throw NSError(domain: "WatchConnectivityService", code: 1, userInfo: [NSLocalizedDescriptionKey: "WatchConnectivity not supported"])
        }

        let wcSession = WCSession.default
        guard wcSession.activationState == .activated else {
            print("⚠️ WatchConnectivity not activated (state: \(wcSession.activationState.rawValue)) - skipping live sample")
            // Silently fail - session might activate later, live samples are best-effort
            return
        }

        // Check if iPhone is reachable before sending
        guard wcSession.isReachable else {
            print("⚠️ iPhone not reachable - skipping live sample (\(sample.sensorType.rawValue): \(sample.value))")
            // iPhone not reachable - skip this sample (live samples are best-effort)
            // We could queue these, but for live data, it's better to skip stale samples
            return
        }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        do {
            // Encode the sample
            let sampleData = try encoder.encode(sample)

            // Wrap with type discriminator for robust message handling
            let payload = MessagePayload(type: MessageType.liveSample, data: sampleData)
            let payloadData = try encoder.encode(payload)

            print("📤 Sending live sample [\(MessageType.liveSample)]: \(sample.sensorType.rawValue) = \(sample.value)")
            // Use sendMessageData for low-latency delivery when reachable
            // Note: This doesn't guarantee delivery, but that's acceptable for live samples
            wcSession.sendMessageData(payloadData, replyHandler: nil) { error in
                // Log error but don't throw - live samples are best-effort
                print("⚠️ Error sending live sample to iPhone: \(error.localizedDescription)")
            }
            print("✅ Live sample sent successfully: \(sample.sensorType.rawValue)")
        } catch {
            // Log but don't propagate - live samples are best-effort
            print("⚠️ Failed to encode live sample: \(error.localizedDescription)")
        }
        #else
        throw NSError(domain: "WatchConnectivityService", code: 3, userInfo: [NSLocalizedDescriptionKey: "sendLiveSample should only be called from watchOS"])
        #endif
    }

    /// Set handler for received live samples (iPhone side)
    func onLiveSampleReceived(_ handler: @escaping (LiveSensorSample) -> Void) {
        self.liveSampleReceivedHandler = handler
    }

    // MARK: - Workout Session Coordination

    #if os(iOS)
    /// Request watch app to start workout session
    func requestWatchStartWorkoutSession() async throws {
        guard let session = session else {
            throw NSError(domain: "WatchConnectivityService", code: 1, userInfo: [NSLocalizedDescriptionKey: "WatchConnectivity not supported"])
        }

        guard session.activationState == .activated else {
            print("⚠️ WatchConnectivity not activated, cannot request workout session start")
            return // Don't throw - session might activate later
        }

        // Try sendMessage first (requires watch to be reachable)
        if session.isReachable {
            let message: [String: Any] = ["action": "startWorkoutSession"]

            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                session.sendMessage(message, replyHandler: { reply in
                    if let error = reply["error"] as? String {
                        continuation.resume(throwing: NSError(domain: "WatchConnectivityService", code: 2, userInfo: [NSLocalizedDescriptionKey: error]))
                    } else {
                        print("✅ Watch acknowledged workout session start request")
                        continuation.resume()
                    }
                }, errorHandler: { error in
                    print("⚠️ Error sending workout session request to watch: \(error)")
                    continuation.resume(throwing: error)
                })
            }
        } else {
            // Watch not reachable - use application context as fallback
            // This will be delivered when watch becomes reachable
            print("⚠️ Watch is not reachable, using application context fallback")
            let context: [String: Any] = ["action": "startWorkoutSession", "timestamp": Date().timeIntervalSince1970]
            do {
                try session.updateApplicationContext(context)
                print("✅ Workout session request queued via application context (will be delivered when watch is reachable)")
            } catch {
                print("⚠️ Failed to queue workout session request: \(error)")
                throw error
            }
        }
    }
    #endif

    #if os(watchOS)
    /// Set handler for workout session requests from iPhone
    func onWorkoutSessionRequested(_ handler: @escaping () -> Void) {
        workoutSessionRequestedHandler = handler
    }
    #endif

    // MARK: - Meditation Session Coordination

    #if os(iOS)
    /// Request watch app to start meditation session
    func requestWatchStartMeditationSession() async throws {
        guard let session = session else {
            throw NSError(domain: "WatchConnectivityService", code: 1, userInfo: [NSLocalizedDescriptionKey: "WatchConnectivity not supported"])
        }

        guard session.activationState == .activated else {
            print("⚠️ WatchConnectivity not activated, cannot request meditation session start")
            return
        }

        let message: [String: Any] = ["action": "startMeditationSession"]

        if session.isReachable {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                session.sendMessage(message, replyHandler: { reply in
                    if let error = reply["error"] as? String {
                        continuation.resume(throwing: NSError(domain: "WatchConnectivityService", code: 2, userInfo: [NSLocalizedDescriptionKey: error]))
                    } else {
                        print("✅ Watch acknowledged meditation session start request")
                        continuation.resume()
                    }
                }, errorHandler: { error in
                    print("⚠️ Error sending meditation session request to watch: \(error)")
                    continuation.resume(throwing: error)
                })
            }
        } else {
            // Watch not reachable - use application context as fallback
            print("⚠️ Watch is not reachable, using application context fallback")
            let context: [String: Any] = ["action": "startMeditationSession", "timestamp": Date().timeIntervalSince1970]
            do {
                try session.updateApplicationContext(context)
                print("✅ Meditation session request queued via application context")
            } catch {
                print("⚠️ Failed to queue meditation session request: \(error)")
                throw error
            }
        }
    }

    /// Request watch app to stop meditation session
    func requestWatchStopSession() async throws {
        guard let session = session else {
            throw NSError(domain: "WatchConnectivityService", code: 1, userInfo: [NSLocalizedDescriptionKey: "WatchConnectivity not supported"])
        }

        guard session.activationState == .activated else {
            print("⚠️ WatchConnectivity not activated, cannot request session stop")
            return
        }

        let message: [String: Any] = ["action": "stopSession"]

        if session.isReachable {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                session.sendMessage(message, replyHandler: { reply in
                    if let error = reply["error"] as? String {
                        continuation.resume(throwing: NSError(domain: "WatchConnectivityService", code: 2, userInfo: [NSLocalizedDescriptionKey: error]))
                    } else {
                        print("✅ Watch acknowledged session stop request")
                        continuation.resume()
                    }
                }, errorHandler: { error in
                    print("⚠️ Error sending session stop request to watch: \(error)")
                    continuation.resume(throwing: error)
                })
            }
        } else {
            // Watch not reachable - use application context as fallback
            print("⚠️ Watch is not reachable, using application context fallback for stop request")
            let context: [String: Any] = ["action": "stopSession", "timestamp": Date().timeIntervalSince1970]
            do {
                try session.updateApplicationContext(context)
                print("✅ Session stop request queued via application context")
            } catch {
                print("⚠️ Failed to queue session stop request: \(error)")
                throw error
            }
        }
    }
    #endif

    #if os(watchOS)
    /// Set handler for meditation session requests from iPhone
    func onMeditationSessionRequested(_ handler: @escaping () -> Void) {
        meditationSessionRequestedHandler = handler
    }

    /// Set handler for session stop requests from iPhone
    func onSessionStopRequested(_ handler: @escaping () -> Void) {
        sessionStopRequestedHandler = handler
    }
    #endif

    private func updateConnectionStatus() {
        #if os(iOS)
        guard let session = session else {
            DispatchQueue.main.async {
                self.connectionStatus = .notSupported
                self.isWatchReachable = false
            }
            return
        }

        // Check if session is activated before checking state
        guard session.activationState == .activated else {
            // Session not yet activated, wait for activation callback
            // Don't update status yet - will be updated in activationDidCompleteWith
            return
        }

        guard session.isPaired else {
            DispatchQueue.main.async {
                self.connectionStatus = .notPaired
                self.isWatchReachable = false
            }
            return
        }

        guard session.isWatchAppInstalled else {
            DispatchQueue.main.async {
                self.connectionStatus = .notInstalled
                self.isWatchReachable = false
            }
            return
        }

        // If watch is paired and app is installed, consider it "connected"
        // isReachable only indicates if we can send messages immediately,
        // but for connection status, we care about whether the watch is available
        DispatchQueue.main.async {
            // Show as connected if paired and installed
            // isWatchReachable tracks actual immediate message capability
            self.connectionStatus = .connected
            self.isWatchReachable = session.isReachable
        }
        #else
        // On watchOS, we're always "connected" from our own perspective
        DispatchQueue.main.async {
            self.connectionStatus = .connected
            self.isWatchReachable = true
        }
        #endif
    }
}

// MARK: - WCSessionDelegate

#if os(iOS) || os(watchOS)
extension WatchConnectivityService: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WatchConnectivity activation error: \(error)")
        } else if activationState == .activated {
            print("✅ WatchConnectivity session activated")
            #if os(watchOS)
            isActivated = true
            // Send any pending sessions
            sendPendingSessions()
            #endif
        }
        updateConnectionStatus()
    }

    #if os(iOS)
    // These delegate methods are only available on iOS, not watchOS
    func sessionDidBecomeInactive(_ session: WCSession) {
        updateConnectionStatus()
    }

    func sessionDidDeactivate(_ session: WCSession) {
        // Reactivate session
        session.activate()
        updateConnectionStatus()
    }

    func sessionWatchStateDidChange(_ session: WCSession) {
        updateConnectionStatus()
    }
    #endif

    func sessionReachabilityDidChange(_ session: WCSession) {
        updateConnectionStatus()
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        #if os(watchOS)
        if let action = message["action"] as? String {
            switch action {
            case "startWorkoutSession":
                print("📱 Received workout session start request from iPhone")
                workoutSessionRequestedHandler?()
            case "startMeditationSession":
                print("📱 Received meditation session start request from iPhone")
                meditationSessionRequestedHandler?()
            case "stopSession":
                print("📱 Received session stop request from iPhone")
                sessionStopRequestedHandler?()
            default:
                break
            }
        }
        #elseif os(iOS)
        // Handle messages from Watch on iPhone
        if let action = message["action"] as? String {
            switch action {
            case "sessionStarted":
                print("📱 iPhone: Received session started notification from Watch")
                // Post notification so ViewModel can start its session display
                if let sessionIdString = message["sessionId"] as? String,
                   let sessionId = UUID(uuidString: sessionIdString),
                   let startDateTimestamp = message["startDate"] as? TimeInterval {
                    let startDate = Date(timeIntervalSince1970: startDateTimestamp)
                    NotificationCenter.default.post(
                        name: NSNotification.Name("WatchSessionStarted"),
                        object: nil,
                        userInfo: [
                            "sessionId": sessionId,
                            "startDate": startDate
                        ]
                    )
                }
            case "sessionEnded":
                print("📱 iPhone: Received session ended notification from Watch")
                // Post notification so ViewModel can stop its session display
                if let sessionIdString = message["sessionId"] as? String,
                   let sessionId = UUID(uuidString: sessionIdString) {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("WatchSessionEnded"),
                        object: nil,
                        userInfo: ["sessionId": sessionId]
                    )
                }
            default:
                break
            }
        }
        #endif
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        #if os(watchOS)
        if let action = message["action"] as? String {
            switch action {
            case "startWorkoutSession":
                print("📱 Received workout session start request from iPhone (with reply)")
                workoutSessionRequestedHandler?()
                replyHandler(["status": "acknowledged"])
                return
            case "startMeditationSession":
                print("📱 Received meditation session start request from iPhone (with reply)")
                meditationSessionRequestedHandler?()
                replyHandler(["status": "acknowledged"])
                return
            case "stopSession":
                print("📱 Received session stop request from iPhone (with reply)")
                sessionStopRequestedHandler?()
                replyHandler(["status": "acknowledged"])
                return
            default:
                break
            }
        }
        #endif
        replyHandler([:])
    }

    /// Receive live sensor samples from Watch
    func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
        print("📱 iPhone: Received messageData from Watch (\(messageData.count) bytes)")

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        // Try to decode as wrapped payload with discriminator (new format)
        if let payload = try? decoder.decode(MessagePayload.self, from: messageData) {
            print("📱 iPhone: Decoded message with type discriminator: [\(payload.type)]")

            // Branch based on message type
            switch payload.type {
            case MessageType.liveSample:
                handleLiveSampleMessage(payload.data, decoder: decoder)

            default:
                // Unknown message type - log and ignore gracefully
                print("⚠️ iPhone: Unknown message type '\(payload.type)' - ignoring")
                print("   This may be a newer message type not supported by this version")
                // No crash, just log and continue
            }
            return
        }

        // Backward compatibility: Try to decode as bare LiveSensorSample (old format)
        print("📱 iPhone: No discriminator found - attempting backward-compatible decode")
        do {
            let sample = try decoder.decode(LiveSensorSample.self, from: messageData)
            print("📱 iPhone: Successfully decoded live sample (legacy format): \(sample.sensorType.rawValue) = \(sample.value)")

            // Dispatch to main thread for handler execution
            DispatchQueue.main.async { [weak self] in
                guard let handler = self?.liveSampleReceivedHandler else {
                    print("⚠️ iPhone: Live sample handler is nil!")
                    return
                }
                print("📱 iPhone: Calling live sample handler")
                handler(sample)
            }
        } catch {
            // Failed to decode as any known format - log and ignore gracefully
            print("⚠️ iPhone: Could not decode message data (not a recognized format)")
            print("   Error: \(error.localizedDescription)")
            if let jsonString = String(data: messageData, encoding: .utf8) {
                print("   Raw data: \(jsonString)")
            }
            // No crash, just log and continue
        }
    }

    /// Handle live sensor sample messages
    private func handleLiveSampleMessage(_ data: Data, decoder: JSONDecoder) {
        do {
            let sample = try decoder.decode(LiveSensorSample.self, from: data)
            print("📱 iPhone: Successfully decoded live sample: \(sample.sensorType.rawValue) = \(sample.value)")

            // Dispatch to main thread for handler execution
            DispatchQueue.main.async { [weak self] in
                guard let handler = self?.liveSampleReceivedHandler else {
                    print("⚠️ iPhone: Live sample handler is nil!")
                    return
                }
                print("📱 iPhone: Calling live sample handler")
                handler(sample)
            }
        } catch {
            print("❌ iPhone: Error decoding live sample data: \(error.localizedDescription)")
            if let jsonString = String(data: data, encoding: .utf8) {
                print("   Sample data: \(jsonString)")
            }
            // No crash, just log and continue
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        #if os(iOS)
        print("📱 iPhone: Received application context from Watch")
        // Handle session notifications from Watch
        if let action = applicationContext["action"] as? String {
            switch action {
            case "sessionStarted":
                print("📱 iPhone: Received session started notification from Watch (via application context)")
                if let sessionIdString = applicationContext["sessionId"] as? String,
                   let sessionId = UUID(uuidString: sessionIdString),
                   let startDateTimestamp = applicationContext["startDate"] as? TimeInterval {
                    let startDate = Date(timeIntervalSince1970: startDateTimestamp)
                    NotificationCenter.default.post(
                        name: NSNotification.Name("WatchSessionStarted"),
                        object: nil,
                        userInfo: [
                            "sessionId": sessionId,
                            "startDate": startDate
                        ]
                    )
                }
                return
            case "sessionEnded":
                print("📱 iPhone: Received session ended notification from Watch (via application context)")
                if let sessionIdString = applicationContext["sessionId"] as? String,
                   let sessionId = UUID(uuidString: sessionIdString) {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("WatchSessionEnded"),
                        object: nil,
                        userInfo: ["sessionId": sessionId]
                    )
                }
                return
            default:
                break
            }
        }
        #elseif os(watchOS)
        print("📱 Watch: Received application context from iPhone")
        // Handle workout/meditation session requests from iPhone
        if let action = applicationContext["action"] as? String {
            switch action {
            case "startWorkoutSession":
                print("📱 Watch: Received workout session start request from iPhone (via application context)")
                if workoutSessionRequestedHandler != nil {
                    print("📱 Watch: Calling workout session requested handler...")
                    workoutSessionRequestedHandler?()
                } else {
                    print("⚠️ Watch: Workout session requested handler is nil! Handler not set up.")
                }
                return
            case "startMeditationSession":
                print("📱 Watch: Received meditation session start request from iPhone (via application context)")
                if meditationSessionRequestedHandler != nil {
                    print("📱 Watch: Calling meditation session requested handler...")
                    meditationSessionRequestedHandler?()
                } else {
                    print("⚠️ Watch: Meditation session requested handler is nil! Handler not set up.")
                }
                return
            case "stopSession":
                print("📱 Watch: Received session stop request from iPhone (via application context)")
                if sessionStopRequestedHandler != nil {
                    print("📱 Watch: Calling session stop requested handler...")
                    sessionStopRequestedHandler?()
                } else {
                    print("⚠️ Watch: Session stop requested handler is nil! Handler not set up.")
                }
                return
            default:
                print("📱 Watch: Application context received but no recognized action found")
                break
            }
        }
        #endif

        // Handle application context updates from Watch (session data)
        guard let sessionData = applicationContext["sessionData"] as? Data else {
            // Not a session data update, might be a workout session request or other message
            return
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let receivedSession = try decoder.decode(MeditationSession.self, from: sessionData)

            #if os(iOS)
            // Check if we've already processed this session recently
            let shouldProcess = receivedSessionsQueue.sync {
                if recentlyReceivedSessionIDs.contains(receivedSession.id) {
                    print("⚠️ Skipping duplicate session \(receivedSession.id) - already processed")
                    return false
                }
                recentlyReceivedSessionIDs.insert(receivedSession.id)

                // Clean up old IDs after 5 minutes to prevent memory growth
                DispatchQueue.main.asyncAfter(deadline: .now() + 300) { [weak self] in
                    self?.receivedSessionsQueue.async {
                        self?.recentlyReceivedSessionIDs.remove(receivedSession.id)
                    }
                }
                return true
            }

            guard shouldProcess else { return }
            #endif

            print("✅ Received session \(receivedSession.id) from Watch")

            // Call handler if set
            sessionReceivedHandler?(receivedSession)
        } catch {
            print("❌ Error decoding session from Watch: \(error)")
        }
    }

    /// Receive user info transfer (for session packages)
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any]) {
        print("📱 iPhone: Received userInfo from Watch")

        // Check if this is a session package
        if let type = userInfo["type"] as? String, type == "sessionPackage",
           let packageData = userInfo["sessionPackage"] as? Data {
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let package = try decoder.decode(SessionSyncPackage.self, from: packageData)

                print("✅ Received session package \(package.sessionId) from Watch")

                // Dispatch to main thread for handler execution
                DispatchQueue.main.async { [weak self] in
                    guard let handler = self?.sessionPackageReceivedHandler else {
                        print("⚠️ iPhone: Session package handler is nil!")
                        return
                    }
                    handler(package)
                }
            } catch {
                print("❌ Error decoding session package from Watch: \(error)")
            }
            return
        }

        // Handle other userInfo types if needed
    }
}
#endif

