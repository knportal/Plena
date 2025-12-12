//
//  ExtensionDelegate.swift
//  Plena Watch App
//
//  Created on [Date]
//

import WatchKit
import WatchConnectivity

class ExtensionDelegate: NSObject, WKExtensionDelegate {

    // Shared instance for access from views
    static var shared: ExtensionDelegate? {
        guard let delegate = WKExtension.shared().delegate as? ExtensionDelegate else {
            print("Warning: ExtensionDelegate not available yet")
            return nil
        }
        return delegate
    }

    // Track if a session is active
    private var isSessionActive: Bool = false
    private var backgroundRefreshTask: WKRefreshBackgroundTask?

    func applicationDidFinishLaunching() {
        // Perform any final initialization of your application.
    }

    func applicationDidBecomeActive() {
        // Restart any tasks that were paused (or not yet started) while the application was inactive.
        // If the application was previously in the background, optionally refresh the user interface.

        // If a session is active, reschedule background refresh to keep app running
        if isSessionActive {
            scheduleNextBackgroundRefresh()
        }
    }

    func applicationWillResignActive() {
        // Sent when the application is about to move from active to inactive state.
        // This can occur for certain types of temporary interruptions
        // (such as an incoming phone call or SMS message) or when the user quits the application
        // and it begins the transition to the background state.

        // If a session is active, schedule background refresh to bring app back to foreground
        if isSessionActive {
            scheduleNextBackgroundRefresh()
        }
    }

    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        // Sent when the system needs to launch the application in the background to process tasks.
        // Tasks arrive in a set, so loop through and process each one.
        for task in backgroundTasks {
            // Use a switch statement to check the task type
            switch task {
            case let backgroundTask as WKApplicationRefreshBackgroundTask:
                // Be sure to complete the background task once you're done.
                // If a session is active, schedule another refresh to keep the app running
                if isSessionActive {
                    // Schedule the next background refresh
                    scheduleNextBackgroundRefresh()
                }
                backgroundTask.setTaskCompletedWithSnapshot(false)

            case let snapshotTask as WKSnapshotRefreshBackgroundTask:
                // Snapshot tasks have a unique completion call, make sure to set your expiration date
                snapshotTask.setTaskCompleted(restoredDefaultState: true, estimatedSnapshotExpiration: Date.distantFuture, userInfo: nil)

            case let connectivityTask as WKWatchConnectivityRefreshBackgroundTask:
                // Be sure to complete the connectivity task once you're done.
                connectivityTask.setTaskCompletedWithSnapshot(false)

            case let urlSessionTask as WKURLSessionRefreshBackgroundTask:
                // Be sure to complete the URL session task once you're done.
                urlSessionTask.setTaskCompletedWithSnapshot(false)

            default:
                // make sure to complete unhandled task types
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }

    // MARK: - Session Management

    func startSession() {
        isSessionActive = true
        scheduleNextBackgroundRefresh()
    }

    func stopSession() {
        isSessionActive = false
        // Cancel any pending background refreshes
        WKExtension.shared().scheduleBackgroundRefresh(withPreferredDate: Date.distantFuture, userInfo: nil) { _ in }
    }

    private func scheduleNextBackgroundRefresh() {
        guard isSessionActive else { return }

        // Schedule background refresh in 15 seconds to keep the app active
        let refreshDate = Date().addingTimeInterval(15.0)
        WKExtension.shared().scheduleBackgroundRefresh(
            withPreferredDate: refreshDate,
            userInfo: nil
        ) { error in
            if let error = error {
                print("Error scheduling background refresh: \(error)")
            }
        }
    }
}
