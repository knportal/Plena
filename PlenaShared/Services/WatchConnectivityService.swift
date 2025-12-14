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

    // Track activation state and queue pending sessions (watchOS only)
    #if os(watchOS)
    private var isActivated = false
    private var pendingSessions: [MeditationSession] = []
    private let activationQueue = DispatchQueue(label: "com.plena.watchconnectivity.activation")
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
        // Handle messages from Watch if needed
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        // Handle messages with reply from Watch if needed
        replyHandler([:])
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        // Handle application context updates from Watch
        guard let sessionData = applicationContext["sessionData"] as? Data else {
            print("⚠️ Received application context without sessionData")
            return
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let receivedSession = try decoder.decode(MeditationSession.self, from: sessionData)

            print("✅ Received session \(receivedSession.id) from Watch")

            // Call handler if set
            sessionReceivedHandler?(receivedSession)
        } catch {
            print("❌ Error decoding session from Watch: \(error)")
        }
    }
}
#endif

