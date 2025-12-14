//
//  SettingsView.swift
//  Plena
//
//  Created on [Date]
//

import SwiftUI
#if os(iOS)
import UIKit
#endif

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @State private var showHealthInstructions = false
    private let healthKitService = HealthKitService()

    var body: some View {
        NavigationStack {
            Form {
                // Sensors Section
                Section {
                    SensorToggleRow(
                        title: "Heart Rate",
                        icon: "heart.fill",
                        iconColor: .red,
                        isEnabled: $viewModel.heartRateEnabled
                    )

                    SensorToggleRow(
                        title: "HRV (SDNN)",
                        icon: "waveform.path.ecg",
                        iconColor: .blue,
                        isEnabled: $viewModel.hrvEnabled
                    )

                    SensorToggleRow(
                        title: "Respiratory Rate",
                        icon: "wind",
                        iconColor: .green,
                        isEnabled: $viewModel.respiratoryRateEnabled
                    )

                    SensorToggleRow(
                        title: "VO₂ Max",
                        icon: "figure.run",
                        iconColor: .orange,
                        isEnabled: $viewModel.vo2MaxEnabled
                    )

                    SensorToggleRow(
                        title: "Temperature",
                        icon: "thermometer",
                        iconColor: .purple,
                        isEnabled: $viewModel.temperatureEnabled
                    )
                } header: {
                    Text("Sensors")
                } footer: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Enable or disable sensors to show during meditation sessions. Disabled sensors will not be displayed or tracked.")

                        Text("Note: Different Apple Watch models support different sensors. It is your responsibility to verify that your Apple Watch model supports the sensors you wish to use. Some sensors require specific Apple Watch models (e.g., HRV requires Series 4+, Respiratory Rate requires Series 6+, Temperature requires Series 8+).")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Temperature Unit Section
                Section {
                    Picker("Temperature Unit", selection: Binding(
                        get: { viewModel.temperatureUnit },
                        set: { viewModel.temperatureUnit = $0 }
                    )) {
                        ForEach(TemperatureUnit.allCases, id: \.self) { unit in
                            Text(unit.displayName)
                                .tag(unit)
                        }
                    }
                } header: {
                    Text("Temperature")
                } footer: {
                    Text("Choose your preferred temperature unit. Temperature data is stored in Celsius and converted for display.")
                }

                // Health Permissions Section
                Section {
                    Button(action: {
                        showHealthInstructions = true
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "heart.text.square.fill")
                                .font(.title3)
                                .foregroundColor(Color("PlenaPrimary"))
                                .frame(width: 30)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Health Permissions")
                                    .font(.body)
                                    .foregroundColor(.primary)
                                Text("Manage HealthKit data access")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Button(action: {
                        healthKitService.checkAuthorizationStatus()
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "arrow.clockwise")
                                .font(.title3)
                                .foregroundColor(Color("PlenaPrimary"))
                                .frame(width: 30)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Refresh Status")
                                    .font(.body)
                                    .foregroundColor(.primary)
                                Text("Check current authorization status")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()
                        }
                    }

                    Button(action: {
                        Task {
                            do {
                                try await healthKitService.requestAuthorization()
                                // Check status after requesting
                                healthKitService.checkAuthorizationStatus()
                            } catch {
                                print("❌ Failed to request authorization: \(error)")
                            }
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "key.fill")
                                .font(.title3)
                                .foregroundColor(Color("PlenaPrimary"))
                                .frame(width: 30)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Re-request Authorization")
                                    .font(.body)
                                    .foregroundColor(.primary)
                                Text("Request permissions again")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()
                        }
                    }
                } header: {
                    Text("Privacy")
                } footer: {
                    Text("If you previously denied access to certain health data types (like VO₂ Max, Temperature, or Sleep Analysis), tap above to see instructions for enabling them. After enabling in Settings, tap 'Refresh Status' to check the updated permissions.")
                }
                .alert("Health Permissions", isPresented: $showHealthInstructions) {
                    Button("Open Settings") {
                        HealthKitService.openHealthSettings()
                    }
                    Button("Cancel", role: .cancel) { }
                } message: {
                    Text("""
                    To enable HealthKit permissions:

                    1. Tap "Open Settings" below
                    2. Tap the back arrow (←) to go to main Settings
                    3. Tap "Privacy & Security"
                    4. Tap "Health"
                    5. Find and tap "Plena"
                    6. Enable toggles for:
                       • VO₂ Max
                       • Body Temperature
                       • Sleep Analysis

                    Then return to Plena to use these features.
                    """)
                }

                // Test Data Section (iOS only)
                #if os(iOS)
                Section {
                    NavigationLink(destination: TestDataView()) {
                        HStack(spacing: 12) {
                            Image(systemName: "flask.fill")
                                .font(.title3)
                                .foregroundColor(Color("PlenaPrimary"))
                                .frame(width: 30)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Test Data")
                                    .font(.body)
                                Text("Generate test meditation sessions")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Testing")
                } footer: {
                    Text("Generate test data with realistic sensor readings to preview features and test the app.")
                }
                #endif

                // About Section
                Section {
                    NavigationLink(destination: MedicalDisclaimerDetailView()) {
                        HStack(spacing: 12) {
                            Image(systemName: "stethoscope")
                                .font(.title3)
                                .foregroundColor(Color("PlenaPrimary"))
                                .frame(width: 30)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Medical Disclaimer")
                                    .font(.body)
                                Text("Important health information")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    NavigationLink(destination: AboutView()) {
                        HStack(spacing: 12) {
                            Image(systemName: "info.circle")
                                .font(.title3)
                                .foregroundColor(Color("PlenaPrimary"))
                                .frame(width: 30)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("About")
                                    .font(.body)
                                Text("App version and information")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Information")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Sensor Toggle Row

struct SensorToggleRow: View {
    let title: String
    let icon: String
    let iconColor: Color
    @Binding var isEnabled: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(iconColor)
                .frame(width: 30)

            Text(title)
                .font(.body)

            Spacer()

            Toggle("", isOn: $isEnabled)
                .labelsHidden()
        }
        .contentShape(Rectangle())
    }
}

#Preview {
    SettingsView()
}

