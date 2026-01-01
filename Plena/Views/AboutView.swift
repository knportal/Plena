//
//  AboutView.swift
//  Plena
//
//  About section showing app version and information
//

import SwiftUI

struct AboutView: View {
    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        Form {
            Section {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("\(appVersion) (\(buildNumber))")
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("App Information")
            }

            Section {
                Text("Plena is a mindfulness tracking application that monitors biometric data during mindfulness sessions using HealthKit. Track your heart rate (continuously) and HRV, respiratory rate, and more (measured periodically by Apple Watch) to gain insights into how mindfulness practice affects your body and mind.")
                    .font(.body)
                    .padding(.vertical, 4)
            } header: {
                Text("About Plena")
            }

            Section {
                // Privacy Policy URL - hosted on plenitudo.ai website
                if let privacyURL = URL(string: "https://plenitudo.ai/privacy-policy") {
                    Link(destination: privacyURL) {
                        HStack {
                            Text("Privacy Policy")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                if let supportURL = URL(string: "mailto:hello@plenitudo.ai") {
                    Link(destination: supportURL) {
                        HStack {
                            Text("Contact Support")
                            Spacer()
                            Image(systemName: "envelope")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } header: {
                Text("Resources")
            } footer: {
                Text("For support, contact us at hello@plenitudo.ai. For privacy inquiries, email info@plenitudo.ai.")
            }

            Section {
                Text("Plena uses Apple's HealthKit framework to access health data. All health data is stored locally on your device or in your iCloud account. Plena does not transmit your health data to external servers.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } header: {
                Text("Privacy & Data")
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AboutView()
    }
}

