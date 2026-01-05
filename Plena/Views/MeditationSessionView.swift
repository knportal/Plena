//
//  MeditationSessionView.swift
//  Plena
//
//  Created on [Date]
//

import SwiftUI
import UIKit

// iOS 16 compatible pulsing heart animation
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

// Sensor data status indicator
enum SensorDataStatus {
    case receiving
    case waiting
    case noSensorsEnabled
    case watchOffWrist

    var displayName: String {
        switch self {
        case .receiving:
            return "Receiving data"
        case .waiting:
            return "Waiting for data..."
        case .noSensorsEnabled:
            return "No sensors enabled"
        case .watchOffWrist:
            return "No sensor data"
        }
    }

    var icon: String {
        switch self {
        case .receiving:
            return "checkmark.circle.fill"
        case .waiting:
            return "hourglass"
        case .noSensorsEnabled:
            return "exclamationmark.circle"
        case .watchOffWrist:
            return "applewatch.slash"
        }
    }

    var color: Color {
        switch self {
        case .receiving:
            return Color("SuccessColor")
        case .waiting:
            return .orange
        case .noSensorsEnabled:
            return .secondary
        case .watchOffWrist:
            return .red
        }
    }
}

struct SensorDataStatusView: View {
    let status: SensorDataStatus

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: status.icon)
                .font(.caption)
            Text(status.displayName)
                .font(.caption)
        }
        .foregroundColor(status.color)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(status.color.opacity(0.15))
        )
    }
}

struct MeditationSessionView: View {
    @StateObject private var viewModel: MeditationSessionViewModel
    @StateObject private var settingsViewModel: SettingsViewModel
    @State private var showPaywall = false
    @State private var screenDimmed = false
    @State private var savedBrightness: CGFloat = 0.5

    init(healthKitService: HealthKitServiceProtocol) {
        // Initialize subscription services
        let subscriptionService = SubscriptionService()
        let featureGateService = FeatureGateService(subscriptionService: subscriptionService)

        _settingsViewModel = StateObject(wrappedValue: SettingsViewModel(featureGateService: featureGateService))
        _viewModel = StateObject(wrappedValue: MeditationSessionViewModel(
            healthKitService: healthKitService,
            storageService: CoreDataStorageService(),
            featureGateService: featureGateService
        ))
    }

    var body: some View {
        VStack(spacing: 40) {
            if let countdown = viewModel.countdown {
                VStack(spacing: 20) {
                    Text("\(countdown)")
                        .font(.system(size: 96, weight: .bold))
                        .foregroundColor(Color("PlenaPrimary"))

                    Text("Get ready...")
                        .font(.title)
                        .foregroundColor(.secondary)
                }
            } else if viewModel.isTracking {
                ZStack {
                    // Main content
                    VStack(spacing: 40) {
                        // Timer display
                        Text(formatElapsedTime(viewModel.sessionElapsedTime))
                            .font(.system(size: 72, weight: .light, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(.primary)

                        Text("Session in progress")
                            .font(.title3)
                            .foregroundColor(.secondary)

                        // Simple watch connection status
                        if viewModel.watchConnectionStatus == .connected && !screenDimmed {
                            HStack(spacing: 6) {
                                Image(systemName: "applewatch")
                                Text("Watch connected")
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }

                        Spacer()

                        Button("Stop Session") {
                            viewModel.stopSession()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                    .padding()

                    // Dimming overlay
                    if screenDimmed {
                        Color.black
                            .opacity(0.7)
                            .ignoresSafeArea()
                            .allowsHitTesting(false)
                            .transition(.opacity)
                    }
                }
                .onAppear {
                    // Prevent auto-lock during session
                    savedBrightness = UIScreen.main.brightness
                    UIApplication.shared.isIdleTimerDisabled = true

                    // Dim screen after 15 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
                        guard viewModel.isTracking else { return }
                        withAnimation(.easeOut(duration: 2.0)) {
                            screenDimmed = true
                            UIScreen.main.brightness = 0.1
                        }
                    }
                }
                .onDisappear {
                    // Re-enable auto-lock and restore brightness
                    UIApplication.shared.isIdleTimerDisabled = false
                    if screenDimmed {
                        UIScreen.main.brightness = savedBrightness
                        screenDimmed = false
                    }
                }
                .onTapGesture {
                    // Wake up screen on tap
                    if screenDimmed {
                        withAnimation(.easeIn(duration: 0.3)) {
                            screenDimmed = false
                            UIScreen.main.brightness = savedBrightness
                        }

                        // Auto-dim again after 10 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                            guard viewModel.isTracking && !screenDimmed else { return }
                            withAnimation(.easeOut(duration: 2.0)) {
                                screenDimmed = true
                                UIScreen.main.brightness = 0.1
                            }
                        }
                    }
                }
            } else if viewModel.isWaitingForSessionPackage {
                // Loading state while waiting for post-session package
                VStack(spacing: 30) {
                    ProgressView()
                        .scaleEffect(1.5)

                    Text("Syncing with Apple Watch...")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("Receiving session data")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    // Add skip button for user control
                    Button(action: {
                        // User wants to skip waiting - show local summary
                        viewModel.forceShowLocalSummary()
                    }) {
                        Text("Show Summary Now")
                            .font(.footnote)
                            .foregroundColor(.accentColor)
                    }
                    .padding(.top, 20)
                }
                .padding()
            } else {
                VStack(spacing: 30) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 80))
                        .foregroundColor(Color("PlenaSecondary"))

                    Text("Welcome to Plena")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Monitor your biometrics: heart rate (continuous), HRV & breathing (periodic updates) - requires Apple Watch")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Button {
                        Task {
                            await viewModel.startSession()
                        }
                    } label: {
                        Label("Start Session", systemImage: "play.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding(.horizontal, 40)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .alert("Health Permissions", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("Open Settings") {
                HealthKitService.openHealthSettings()
                viewModel.errorMessage = nil
            }
            Button("Cancel", role: .cancel) {
                viewModel.errorMessage = nil
            }
        } message: {
            Text("""
            To enable HealthKit permissions:

            1. Tap "Open Settings" below
            2. Tap the back arrow (←) to go to main Settings
            3. Tap "Privacy & Security"
            4. Tap "Health"
            5. Find and tap "Plena"
            6. Enable toggles for:
               • Heart Rate
               • HRV (SDNN)
               • Respiratory Rate

            Then return to Plena to use these features.
            """)
        }
        .sheet(isPresented: Binding(
            get: { viewModel.sessionSummary != nil },
            set: { if !$0 { viewModel.dismissSummary() } }
        )) {
            if let summary = viewModel.sessionSummary {
                SessionSummaryView(summary: summary) {
                    viewModel.dismissSummary()
                }
                .presentationDetents([.medium, .large] as Set)
                .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Helper Functions

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
}

// MARK: - Sensor Value Card Component

struct SensorValueCard: View {
    let icon: String
    let iconColor: Color
    let value: String
    let unit: String
    let label: String
    let size: CardSize
    var isUnavailable: Bool = false
    var zone: StressZone? = nil
    var isStale: Bool = false

    enum CardSize {
        case large
        case medium

        var valueFontSize: CGFloat {
            switch self {
            case .large: return 24
            case .medium: return 20
            }
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(iconColor)
            Text(value)
                .font(.system(size: size.valueFontSize, weight: .bold))
                .foregroundColor(.primary)
            Text(unit)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)

            // Zone indicator
            if let zone = zone {
                Text(zone.displayName)
                    .font(.caption2)
                    .foregroundColor(zone.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(zone.backgroundColor)
                    )
            }

            // Stale data indicator
            if isStale {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption2)
                    Text("No recent updates")
                        .font(.caption2)
                }
                .foregroundColor(.orange)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 140)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(zone?.backgroundColor ?? (isUnavailable ? Color(.systemBackground).opacity(0.5) : Color(.systemBackground)))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(zone?.borderColor ?? Color.clear, lineWidth: zone != nil ? 2 : 0)
                )
                .shadow(color: isUnavailable ? .clear : .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        var label = "\(label), \(value) \(unit)"
        if let zone = zone {
            label += ", \(zone.accessibilityDescription)"
        }
        return label
    }
}

#Preview {
    MeditationSessionView(healthKitService: HealthKitService())
}
