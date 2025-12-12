//
//  WatchConnectivityService.swift
//  PlenaShared
//
//  Created on [Date]
//

import Foundation
import Combine

#if os(iOS)
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
}

class WatchConnectivityService: NSObject, WatchConnectivityServiceProtocol, ObservableObject {
    static let shared = WatchConnectivityService()

    #if os(iOS)
    private let session: WCSession?
    #else
    private let session: Any? = nil
    #endif
    private var isMonitoring = false

    @Published private(set) var connectionStatus: WatchConnectionStatus = .notSupported
    @Published private(set) var isWatchReachable: Bool = false

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
        #else
        // WatchConnectivity monitoring is only needed on iOS
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

#if os(iOS)
extension WatchConnectivityService: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WatchConnectivity activation error: \(error)")
        }
        updateConnectionStatus()
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        updateConnectionStatus()
    }

    func sessionDidDeactivate(_ session: WCSession) {
        // Reactivate session
        session.activate()
        updateConnectionStatus()
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        updateConnectionStatus()
    }

    func sessionWatchStateDidChange(_ session: WCSession) {
        updateConnectionStatus()
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        // Handle messages from Watch if needed
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        // Handle messages with reply from Watch if needed
        replyHandler([:])
    }
}
#endif

