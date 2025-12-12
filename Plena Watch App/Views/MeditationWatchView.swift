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
                        .foregroundColor(.secondary)
                }
            } else if let summary = viewModel.sessionSummary {
                // Summary view
                ScrollView {
                    VStack(spacing: 12) {
                        Text("Session Complete")
                            .font(.headline)
                            .fontWeight(.bold)
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
                                Text("Avg BPM")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color("CardBackgroundColor"))
                            )
                        }

                        // HRV Change
                        if let hrvStart = summary.hrvStart,
                           let hrvEnd = summary.hrvEnd,
                           let hrvChange = summary.hrvChange {
                            VStack(spacing: 4) {
                                Image(systemName: "waveform.path.ecg")
                                    .font(.caption)
                                    .foregroundColor(Color("HRVColor"))
                                HStack(spacing: 4) {
                                    Text("\(Int(hrvStart))")
                                        .font(.caption)
                                    Image(systemName: "arrow.right")
                                        .font(.caption2)
                                    Text("\(Int(hrvEnd))")
                                        .font(.caption)
                                }
                                .fontWeight(.semibold)
                                Text(hrvChange >= 0 ? "+\(Int(hrvChange)) ms" : "\(Int(hrvChange)) ms")
                                    .font(.caption2)
                                    .foregroundColor(hrvChange >= 0 ? Color("SuccessColor") : Color("WarningColor"))
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
                                Text("Breaths/min")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
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
                ScrollView {
                    VStack(spacing: 15) {
                        // Heart Rate
                        if settingsViewModel.heartRateEnabled, let heartRate = viewModel.currentHeartRate {
                            VStack(spacing: 5) {
                                Image(systemName: "heart.fill")
                                    .font(.title2)
                                    .foregroundColor(Color("HeartRateColor"))
                                Text("\(Int(heartRate))")
                                    .font(.title)
                                    .fontWeight(.bold)
                                Text("BPM")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                // Zone indicator
                                if let zone = viewModel.currentHeartRateZone {
                                    Text(zone.displayName)
                                        .font(.caption2)
                                        .foregroundColor(zone.color)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(
                                            Capsule()
                                                .fill(zone.backgroundColor)
                                        )
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(viewModel.currentHeartRateZone?.backgroundColor ?? Color.clear)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(viewModel.currentHeartRateZone?.borderColor ?? Color.clear, lineWidth: viewModel.currentHeartRateZone != nil ? 1.5 : 0)
                                    )
                            )
                        }

                        // HRV
                        if settingsViewModel.hrvEnabled, let hrv = viewModel.currentHRV {
                            VStack(spacing: 5) {
                                Image(systemName: "waveform.path.ecg")
                                    .font(.title2)
                                    .foregroundColor(Color("HRVColor"))
                                Text("\(Int(hrv))")
                                    .font(.title)
                                    .fontWeight(.bold)
                                Text("ms SDNN")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                // Zone indicator
                                if let zone = viewModel.currentHRVZone {
                                    Text(zone.displayName)
                                        .font(.caption2)
                                        .foregroundColor(zone.color)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(
                                            Capsule()
                                                .fill(zone.backgroundColor)
                                        )
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(viewModel.currentHRVZone?.backgroundColor ?? Color.clear)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(viewModel.currentHRVZone?.borderColor ?? Color.clear, lineWidth: viewModel.currentHRVZone != nil ? 1.5 : 0)
                                    )
                            )
                        }

                        // Respiratory Rate
                        if settingsViewModel.respiratoryRateEnabled, let respiratoryRate = viewModel.currentRespiratoryRate {
                            VStack(spacing: 5) {
                                Image(systemName: "wind")
                                    .font(.title2)
                                    .foregroundColor(Color("RespiratoryColor"))
                                Text("\(Int(respiratoryRate))")
                                    .font(.title)
                                    .fontWeight(.bold)
                                Text("/min")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                        }

                        // VO2 Max
                        if settingsViewModel.vo2MaxEnabled {
                            if let vo2Max = viewModel.currentVO2Max {
                                VStack(spacing: 5) {
                                    Image(systemName: "figure.run")
                                        .font(.title2)
                                        .foregroundColor(Color("VO2MaxColor"))
                                    Text(String(format: "%.1f", vo2Max))
                                        .font(.title3)
                                        .fontWeight(.bold)
                                    Text("VO₂ Max")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                            } else if viewModel.vo2MaxAvailable == false {
                                VStack(spacing: 5) {
                                    Image(systemName: "figure.run")
                                        .font(.title2)
                                        .foregroundColor(.gray.opacity(0.5))
                                    Text("—")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(.secondary)
                                    Text("VO₂ Max N/A")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                            }
                        }

                        // Temperature
                        if settingsViewModel.temperatureEnabled {
                            if let temperatureCelsius = viewModel.currentTemperature {
                                let convertedTemp = settingsViewModel.convertTemperature(temperatureCelsius)
                                VStack(spacing: 5) {
                                    Image(systemName: "thermometer")
                                        .font(.title2)
                                        .foregroundColor(Color("TemperatureColor"))
                                    Text(String(format: "%.1f", convertedTemp))
                                        .font(.title3)
                                        .fontWeight(.bold)
                                    Text(settingsViewModel.temperatureUnitSymbol)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                            } else if viewModel.temperatureAvailable == false {
                                VStack(spacing: 5) {
                                    Image(systemName: "thermometer")
                                        .font(.title2)
                                        .foregroundColor(.gray.opacity(0.5))
                                    Text("—")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(.secondary)
                                    Text("Temp N/A")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                            }
                        }

                        // Waiting state
                        if !hasAnyEnabledSensor(settingsViewModel) ||
                           (settingsViewModel.heartRateEnabled && viewModel.currentHeartRate == nil &&
                            settingsViewModel.hrvEnabled && viewModel.currentHRV == nil &&
                            settingsViewModel.respiratoryRateEnabled && viewModel.currentRespiratoryRate == nil) {
                            PulsingHeartView()
                                .font(.system(size: 40))
                                .foregroundColor(Color("HeartRateColor"))
                            Text("Waiting for data...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

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
