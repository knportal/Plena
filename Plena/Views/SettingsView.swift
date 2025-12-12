//
//  SettingsView.swift
//  Plena
//
//  Created on [Date]
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()

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

