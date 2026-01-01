//
//  BackgroundSessionManager.swift
//  PlenaShared
//
//  Background session management for Apple Watch
//  Handles data collection when UI is not visible
//

import Foundation
import SwiftUI

@MainActor
class BackgroundSessionManager: ObservableObject {
    private var viewModel: MeditationSessionViewModel?
    @Published var isBackgroundSessionActive: Bool = false

    init() {
        // Initialize with services
        let healthKitService = HealthKitService()
        let storageService = CoreDataStorageService()
        let workoutService = WorkoutSessionService()

        self.viewModel = MeditationSessionViewModel(
            healthKitService: healthKitService,
            storageService: storageService,
            workoutSessionService: workoutService
        )
    }

    /// Start workout session from iPhone request (background data collection)
    func startWorkoutSessionFromRequest() async {
        guard let viewModel = viewModel else { return }
        await viewModel.startWorkoutSessionFromRequest()
    }

    /// Start full session from iPhone request (background data collection)
    func startBackgroundSession() async {
        print("🎯 Starting background session on watch")
        guard let viewModel = viewModel else { return }

        isBackgroundSessionActive = true

        // Start the session (this handles all sensor queries and data collection)
        await viewModel.startSession()

        // Notify extension delegate to keep app alive in background
        #if os(watchOS)
        ExtensionDelegate.shared?.startSession()
        #endif
    }

    /// Stop background session
    func stopBackgroundSession() async {
        print("🛑 Stopping background session on watch")
        guard let viewModel = viewModel else { return }

        // Stop the session (this saves data and sends to iPhone)
        await MainActor.run {
            viewModel.stopSession()
        }

        isBackgroundSessionActive = false

        // Stop extension delegate background refresh
        #if os(watchOS)
        ExtensionDelegate.shared?.stopSession()
        #endif
    }

    /// Get the current view model (for UI binding if needed)
    func getViewModel() -> MeditationSessionViewModel? {
        return viewModel
    }
}

