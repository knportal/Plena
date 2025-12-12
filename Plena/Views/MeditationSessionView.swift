//
//  MeditationSessionView.swift
//  Plena
//
//  Created on [Date]
//

import SwiftUI

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

    var displayName: String {
        switch self {
        case .receiving:
            return "Receiving data"
        case .waiting:
            return "Waiting for data..."
        case .noSensorsEnabled:
            return "No sensors enabled"
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
    @StateObject private var settingsViewModel = SettingsViewModel()

    init(healthKitService: HealthKitServiceProtocol) {
        _viewModel = StateObject(wrappedValue: MeditationSessionViewModel(
            healthKitService: healthKitService,
            storageService: CoreDataStorageService()
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
                VStack(spacing: 30) {
                    PulsingHeartView()
                        .font(.system(size: 60))
                        .foregroundColor(Color("HeartRateColor"))

                    Text("Tracking Meditation")
                        .font(.largeTitle)
                        .fontWeight(.semibold)

                    // Sensor data status indicator
                    SensorDataStatusView(
                        status: {
                            if !viewModel.hasEnabledSensors(settings: settingsViewModel) {
                                return .noSensorsEnabled
                            } else if viewModel.hasActiveSensorData(settings: settingsViewModel) {
                                return .receiving
                            } else {
                                return .waiting
                            }
                        }()
                    )
                    .padding(.horizontal)

                    // Real-time sensor data as soft rounded buttons
                    VStack(spacing: 12) {
                        // Primary metrics row
                        HStack(spacing: 12) {
                            // Heart Rate Button
                            if settingsViewModel.heartRateEnabled, let heartRate = viewModel.currentHeartRate {
                                SensorValueCard(
                                    icon: "heart.fill",
                                    iconColor: Color("HeartRateColor"),
                                    value: "\(Int(heartRate))",
                                    unit: "BPM",
                                    label: "Heart Rate",
                                    size: SensorValueCard.CardSize.large,
                                    zone: viewModel.currentHeartRateZone,
                                    isStale: viewModel.isHeartRateStale
                                )
                            }

                            // HRV Button
                            if settingsViewModel.hrvEnabled, let hrv = viewModel.currentHRV {
                                SensorValueCard(
                                    icon: "waveform.path.ecg",
                                    iconColor: Color("HRVColor"),
                                    value: "\(Int(hrv))",
                                    unit: "ms",
                                    label: "HRV (SDNN)",
                                    size: SensorValueCard.CardSize.large,
                                    zone: viewModel.currentHRVZone,
                                    isStale: viewModel.isHRVStale
                                )
                            }

                            // Respiratory Rate Button
                            if settingsViewModel.respiratoryRateEnabled, let respiratoryRate = viewModel.currentRespiratoryRate {
                                SensorValueCard(
                                    icon: "wind",
                                    iconColor: Color("RespiratoryColor"),
                                    value: "\(Int(respiratoryRate))",
                                    unit: "/min",
                                    label: "Respiratory Rate",
                                    size: SensorValueCard.CardSize.large,
                                    isStale: viewModel.isRespiratoryRateStale
                                )
                            }

                            // Waiting state
                            if !hasAnyEnabledPrimarySensor(settingsViewModel) ||
                               (settingsViewModel.heartRateEnabled && viewModel.currentHeartRate == nil &&
                                settingsViewModel.hrvEnabled && viewModel.currentHRV == nil &&
                                settingsViewModel.respiratoryRateEnabled && viewModel.currentRespiratoryRate == nil) {
                                Text("Waiting for sensor data...")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity)
                            }
                        }

                        // Secondary metrics row (VO2 Max and Temperature)
                        HStack(spacing: 12) {
                            // VO2 Max Button
                            if settingsViewModel.vo2MaxEnabled {
                                if let vo2Max = viewModel.currentVO2Max {
                                    SensorValueCard(
                                        icon: "figure.run",
                                        iconColor: Color("VO2MaxColor"),
                                        value: String(format: "%.1f", vo2Max),
                                        unit: "mL/kg/min",
                                        label: "VO₂ Max",
                                        size: SensorValueCard.CardSize.large
                                    )
                                } else if viewModel.vo2MaxAvailable == false {
                                    SensorValueCard(
                                        icon: "figure.run",
                                        iconColor: Color.gray.opacity(0.5),
                                        value: "—",
                                        unit: "N/A",
                                        label: "VO₂ Max",
                                        size: SensorValueCard.CardSize.large,
                                        isUnavailable: true
                                    )
                                }
                            }

                            // Temperature Button
                            if settingsViewModel.temperatureEnabled {
                                if let temperatureCelsius = viewModel.currentTemperature {
                                    let convertedTemp = settingsViewModel.convertTemperature(temperatureCelsius)
                                    SensorValueCard(
                                        icon: "thermometer",
                                        iconColor: Color("TemperatureColor"),
                                        value: String(format: "%.1f", convertedTemp),
                                        unit: settingsViewModel.temperatureUnitSymbol,
                                        label: "Temperature",
                                        size: SensorValueCard.CardSize.large
                                    )
                                } else if viewModel.temperatureAvailable == false {
                                    SensorValueCard(
                                        icon: "thermometer",
                                        iconColor: Color.gray.opacity(0.5),
                                        value: "—",
                                        unit: "N/A",
                                        label: "Temperature",
                                        size: SensorValueCard.CardSize.large,
                                        isUnavailable: true
                                    )
                                }
                            }
                        }
                    }
                    .padding(.horizontal)

                    Button("Stop Session") {
                        viewModel.stopSession()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            } else {
                VStack(spacing: 30) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 80))
                        .foregroundColor(Color("PlenaSecondary"))

                    Text("Welcome to Plena")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Monitor your biometrics in real-time: heart rate, HRV, breathing, and more (requires Apple Watch)")
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

    private func hasAnyEnabledPrimarySensor(_ settings: SettingsViewModel) -> Bool {
        return settings.heartRateEnabled || settings.hrvEnabled || settings.respiratoryRateEnabled
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
