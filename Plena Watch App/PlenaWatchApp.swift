//
//  PlenaWatchApp.swift
//  Plena Watch App
//
//  Created on [Date]
//

import SwiftUI
import WatchKit

@main
struct PlenaWatchApp: App {
    let coreDataStack = CoreDataStack.shared

    // Note: WKExtensionDelegateAdaptor warning may appear but is safe to ignore
    // watchOS apps are extension-based processes, so this is the correct usage
    @WKExtensionDelegateAdaptor(ExtensionDelegate.self) var extensionDelegate

    // Create a shared view model at app level for background session management
    @StateObject private var backgroundSessionManager = BackgroundSessionManager()

    init() {
        // Set up watch connectivity handlers at app level
        // This ensures they work even when the watch UI is not visible
        setupWatchConnectivityHandlers()
    }

    var body: some Scene {
        WindowGroup {
            WatchContentView()
                .environmentObject(backgroundSessionManager)
        }
    }

    private func setupWatchConnectivityHandlers() {
        #if os(watchOS)
        let watchConnectivity = WatchConnectivityService.shared

        // Handler for workout session requests from iPhone
        watchConnectivity.onWorkoutSessionRequested { [weak backgroundSessionManager] in
            print("📱 Watch: Received workout session request from iPhone (app-level)")
            Task {
                await backgroundSessionManager?.startWorkoutSessionFromRequest()
            }
        }

        // Handler for meditation session requests from iPhone
        watchConnectivity.onMeditationSessionRequested { [weak backgroundSessionManager] in
            print("📱 Watch: Received meditation session request from iPhone (app-level)")
            Task {
                await backgroundSessionManager?.startBackgroundSession()
            }
        }

        // Handler for session stop requests from iPhone
        watchConnectivity.onSessionStopRequested { [weak backgroundSessionManager] in
            print("📱 Watch: Received session stop request from iPhone (app-level)")
            Task {
                await backgroundSessionManager?.stopBackgroundSession()
            }
        }
        #endif
    }
}

