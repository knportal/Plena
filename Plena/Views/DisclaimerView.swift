//
//  DisclaimerView.swift
//  Plena
//
//  First-launch medical disclaimer screen
//

import SwiftUI

struct DisclaimerView: View {
    @Binding var hasAcceptedDisclaimer: Bool
    @State private var hasScrolledToBottom = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "heart.text.square.fill")
                        .font(.system(size: 60))
                        .foregroundColor(Color("PlenaPrimary"))

                    Text("Welcome to Plena")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Meditation Tracking with Biometrics")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                .padding(.bottom, 20)

                // Disclaimer Content
                VStack(alignment: .leading, spacing: 20) {
                    Text("Important Information")
                        .font(.title2)
                        .fontWeight(.semibold)

                    VStack(alignment: .leading, spacing: 16) {
                        DisclaimerSection(
                            icon: "stethoscope",
                            title: "Not a Medical Device",
                            content: "Plena is not a medical device and does not provide medical advice, diagnosis, or treatment. The information provided is for wellness and self-improvement purposes only."
                        )

                        DisclaimerSection(
                            icon: "exclamationmark.triangle.fill",
                            title: "Consult Healthcare Professionals",
                            content: "Do not use Plena data to diagnose, treat, or prevent any disease. Consult healthcare professionals for medical advice. Plena data is not a substitute for professional medical care."
                        )

                        DisclaimerSection(
                            icon: "waveform.path",
                            title: "Data Accuracy",
                            content: "Sensor readings may vary and are estimates, not clinical measurements. Data accuracy depends on your device's sensors and environmental factors."
                        )

                        DisclaimerSection(
                            icon: "chart.bar.fill",
                            title: "Stress Zone Classifications",
                            content: "Stress zones (Calm, Optimal, Elevated) are general guidelines based on population averages, not personalized medical assessments. Individual baselines may vary."
                        )
                    }
                }
                .padding(.horizontal, 20)

                // Spacer to help detect scroll position
                Color.clear
                    .frame(height: 1)
                    .onAppear {
                        // Small delay to ensure scroll detection works
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            hasScrolledToBottom = true
                        }
                    }
            }
        }
        .safeAreaInset(edge: .bottom) {
            // Accept Button (fixed at bottom)
            VStack(spacing: 12) {
                Button(action: {
                    hasAcceptedDisclaimer = true
                }) {
                    HStack {
                        Text("I Understand")
                            .fontWeight(.semibold)
                        Image(systemName: "checkmark.circle.fill")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("PlenaPrimary"))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 8)

                Text("By continuing, you acknowledge that you have read and understood this information.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
            }
            .background(
                // Blur effect for better visual separation
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea(edges: .bottom)
            )
        }
    }
}

// MARK: - Disclaimer Section Component

struct DisclaimerSection: View {
    let icon: String
    let title: String
    let content: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(Color("PlenaPrimary"))
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(content)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    DisclaimerView(hasAcceptedDisclaimer: .constant(false))
}









