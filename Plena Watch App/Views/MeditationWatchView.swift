//
//  MeditationWatchView.swift
//  Plena Watch App
//
//  Created on [Date]
//

import SwiftUI
import WatchKit

struct MeditationWatchView: View {
    @StateObject private var viewModel: MeditationSessionViewModel
    @StateObject private var settingsViewModel = SettingsViewModel()

    init(healthKitService: HealthKitServiceProtocol) {
        _viewModel = StateObject(wrappedValue: MeditationSessionViewModel(
            healthKitService: healthKitService,
            storageService: CoreDataStorageService()
        ))
    }

    var body: some View {
        VStack(spacing: 20) {
            if let countdown = viewModel.countdown {
                VStack(spacing: 10) {
                    Text("\(countdown)")
                        .font(.system(size: 64, weight: .bold))
                        .foregroundColor(Color("PlenaPrimary"))

                    Text("Get ready")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(Color("TextSecondaryColor").opacity(0.9))
                }
            } else if let summary = viewModel.sessionSummary {
                // Summary view
                ScrollView {
                    VStack(spacing: 12) {
                        Text("Session Complete")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(Color("TextPrimaryColor"))
                            .padding(.bottom, 4)

                        // Average Heart Rate
                        if let avgHR = summary.averageHeartRate {
                            VStack(spacing: 4) {
                                Image(systemName: "heart.fill")
                                    .font(.caption)
                                    .foregroundColor(Color("HeartRateColor"))
                                Text("\(Int(avgHR))")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color("TextPrimaryColor"))
                                Text("Avg BPM")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color("TextSecondaryColor"))
                            }
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color("CardBackgroundColor"))
                            )
                        }

                        // Average HRV
                        if let avgHRV = summary.averageHRV {
                            VStack(spacing: 4) {
                                Image(systemName: "waveform.path.ecg")
                                    .font(.caption)
                                    .foregroundColor(Color("HRVColor"))
                                Text("\(Int(avgHRV))")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color("TextPrimaryColor"))
                                Text("Avg HRV (ms)")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color("TextSecondaryColor"))

                                // HRV Trend indicator
                                if summary.hrvTrend != .insufficientData {
                                    HStack(spacing: 4) {
                                        Image(systemName: trendIcon(summary.hrvTrend))
                                            .font(.caption2)
                                            .foregroundColor(trendColor(summary.hrvTrend))
                                        Text(trendText(summary.hrvTrend))
                                            .font(.caption2)
                                            .fontWeight(.semibold)
                                            .foregroundColor(trendColor(summary.hrvTrend))
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color("CardBackgroundColor"))
                            )
                        }

                        // Respiratory Rate
                        if let avgRespRate = summary.averageRespiratoryRate {
                            VStack(spacing: 4) {
                                Image(systemName: "wind")
                                    .font(.caption)
                                    .foregroundColor(Color("RespiratoryColor"))
                                Text("\(Int(avgRespRate))")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color("TextPrimaryColor"))
                                Text("Breaths/min")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color("TextSecondaryColor"))
                            }
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color("CardBackgroundColor"))
                            )
                        }

                        Button("Done") {
                            viewModel.dismissSummary()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .padding(.top, 4)
                    }
                }
            } else if viewModel.isTracking {
                // Check if this is a remote session (started from iPhone)
                if viewModel.isRemoteSession {
                    // Silent background mode - no UI needed
                    // Watch collects data in background only
                    EmptyView()
                } else {
                    // Local watch session - show timer UI
                    VStack(spacing: 20) {
                        // Timer display
                        Text(formatElapsedTime(viewModel.sessionElapsedTime))
                            .font(.system(size: 48, weight: .light, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(.primary)

                        Text("Session in progress")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Button("Stop") {
                            viewModel.stopSession()
                            // Notify extension delegate to stop session management
                            ExtensionDelegate.shared?.stopSession()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                }
            } else {
                VStack(spacing: 15) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 50))
                        .foregroundColor(Color("PlenaSecondary"))

                    Text("Plena")
                        .font(.title3)
                        .fontWeight(.bold)

                    // Show error message if present
                    if let errorMessage = viewModel.errorMessage {
                        ScrollView {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .frame(maxHeight: 60)
                    }

                    Button {
                        Task {
                            await viewModel.startSession()
                            // Notify extension delegate to start session management
                            // Only if session started successfully (isTracking will be true)
                            if viewModel.isTracking {
                                ExtensionDelegate.shared?.startSession()
                            }
                        }
                    } label: {
                        Label("Start", systemImage: "play.fill")
                            .font(.headline)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                }
            }
        }
        .padding()
        .onChange(of: viewModel.isTracking) { oldValue, newValue in
            // Handle session state changes
            if newValue {
                ExtensionDelegate.shared?.startSession()
            } else {
                ExtensionDelegate.shared?.stopSession()
            }
        }
        .onAppear {
            // Set up workout session request handler from iPhone
            #if os(watchOS)
            let watchConnectivity = WatchConnectivityService.shared
            watchConnectivity.onWorkoutSessionRequested { [weak viewModel] in
                Task {
                    // Start workout session when requested from iPhone
                    // The viewModel will handle this through its startSession flow
                    // But we need to ensure the workout session service starts
                    await viewModel?.startWorkoutSessionFromRequest()
                }
            }

            // Set up meditation session request handler from iPhone
            watchConnectivity.onMeditationSessionRequested { [weak viewModel] in
                Task {
                    // Start meditation session in background (no UI) when requested from iPhone
                    await viewModel?.startSession(isRemote: true)
                }
            }

            // Set up session stop request handler from iPhone
            watchConnectivity.onSessionStopRequested { [weak viewModel] in
                Task { @MainActor in
                    // Stop the session when requested from iPhone
                    viewModel?.stopSession()
                }
            }
            #endif

            // If tracking when view appears, ensure session management is active
            if viewModel.isTracking {
                ExtensionDelegate.shared?.startSession()
            } else {
                // Try to load recent session summary if app was restarted shortly after stopping
                viewModel.loadRecentSessionSummaryIfNeeded()
            }
        }
        .onDisappear {
            // Only stop session management if we're actually stopping the session
            // Don't stop if the view just disappeared temporarily
            if !viewModel.isTracking {
                ExtensionDelegate.shared?.stopSession()
            }
        }
    }

    // MARK: - Helper Functions

    private func hasAnyEnabledSensor(_ settings: SettingsViewModel) -> Bool {
        return settings.heartRateEnabled || settings.hrvEnabled || settings.respiratoryRateEnabled ||
               settings.vo2MaxEnabled || settings.temperatureEnabled
    }

    private func formatElapsedTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) / 60 % 60
        let seconds = Int(timeInterval) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }

    private func trendIcon(_ trend: SessionSummary.HRVTrend) -> String {
        switch trend {
        case .increasing:
            return "arrow.up.right"
        case .decreasing:
            return "arrow.down.right"
        case .stable:
            return "arrow.right"
        case .insufficientData:
            return "minus"
        }
    }

    private func trendColor(_ trend: SessionSummary.HRVTrend) -> Color {
        switch trend {
        case .increasing:
            return Color("SuccessColor")
        case .decreasing:
            return Color("WarningColor")
        case .stable:
            return Color("TextSecondaryColor")
        case .insufficientData:
            return Color("TextSecondaryColor")
        }
    }

    private func trendText(_ trend: SessionSummary.HRVTrend) -> String {
        switch trend {
        case .increasing:
            return "Increasing"
        case .decreasing:
            return "Decreasing"
        case .stable:
            return "Stable"
        case .insufficientData:
            return "Insufficient data"
        }
    }
}

// iOS 16 compatible pulsing heart animation for watch
struct PulsingHeartView: View {
    @State private var scale: CGFloat = 1.0

    var body: some View {
        Image(systemName: "heart.fill")
            .scaleEffect(scale)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    scale = 1.2
                }
            }
    }
}

#Preview {
    MeditationWatchView(healthKitService: HealthKitService())
}
