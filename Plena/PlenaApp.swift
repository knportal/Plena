//
//  PlenaApp.swift
//  Plena
//
//  Created on [Date]
//

import SwiftUI

@main
struct PlenaApp: App {
    let coreDataStack = CoreDataStack.shared
    @AppStorage("hasAcceptedDisclaimer") private var hasAcceptedDisclaimer = false

    init() {
        // Set up WatchConnectivity to receive sessions from Watch
        setupWatchConnectivity()

        // Perform one-time migration from JSON on first launch
        Task { @MainActor in
            await Self.performMigrationIfNeeded()
        }
    }

    private func setupWatchConnectivity() {
        #if os(iOS)
        let watchConnectivity = WatchConnectivityService.shared
        let storageService = CoreDataStorageService()

        // Handle sessions received from Watch
        watchConnectivity.onSessionReceived { session in
            Task {
                do {
                    try storageService.saveSession(session)
                    print("✅ Saved session \(session.id) received from Watch")

                    // Post notification to refresh dashboard
                    NotificationCenter.default.post(name: .NSPersistentStoreRemoteChange, object: nil)
                } catch {
                    print("❌ Error saving session from Watch: \(error)")
                }
            }
        }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            if hasAcceptedDisclaimer {
                ContentView()
            } else {
                DisclaimerView(hasAcceptedDisclaimer: $hasAcceptedDisclaimer)
            }
        }
    }

    // MARK: - Migration

    @MainActor
    private static func performMigrationIfNeeded() async {
        let userDefaults = UserDefaults.standard
        let migrationKey = "hasMigratedToCoreData"

        // Check if migration has already been performed
        guard !userDefaults.bool(forKey: migrationKey) else {
            return
        }

        // Check if JSON file exists
        let jsonService = SessionStorageService()
        do {
            let jsonSessions = try jsonService.loadAllSessions()

            // Only migrate if there's existing data
            guard !jsonSessions.isEmpty else {
                userDefaults.set(true, forKey: migrationKey)
                return
            }

            // Perform migration
            let storageService = CoreDataStorageService()

            for session in jsonSessions {
                try storageService.saveSession(session)
            }

            // Mark migration as complete
            userDefaults.set(true, forKey: migrationKey)
            print("✅ Successfully migrated \(jsonSessions.count) sessions to Core Data")

        } catch {
            print("⚠️ Migration failed: \(error)")
            // Don't mark as migrated so we can retry
        }
    }
}

