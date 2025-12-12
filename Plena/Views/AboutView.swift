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
                Text("Plena is a meditation tracking application that monitors biometric data during meditation sessions using HealthKit. Track your heart rate, HRV, respiratory rate, and more to gain insights into how meditation affects your body and mind.")
                    .font(.body)
                    .padding(.vertical, 4)
            } header: {
                Text("About Plena")
            }

            Section {
                // Update this URL with your actual privacy policy location
                // Set to nil to hide the link until you have a hosted privacy policy
                if let privacyURL = URL(string: "https://plenitudo.ai/privacy") {
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

