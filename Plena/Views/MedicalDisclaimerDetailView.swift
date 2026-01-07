//
//  MedicalDisclaimerDetailView.swift
//  Plena
//
//  Full medical disclaimer view accessible from Settings
//

import SwiftUI

struct MedicalDisclaimerDetailView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 12) {
                        Image(systemName: "stethoscope")
                            .font(.title)
                            .foregroundColor(Color("PlenaPrimary"))

                        Text("Medical Disclaimer")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                    }

                    Text("Important information about Plena")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                // Disclaimer Sections
                VStack(alignment: .leading, spacing: 24) {
                    DisclaimerDetailSection(
                        icon: "exclamationmark.triangle.fill",
                        iconColor: .orange,
                        title: "Not a Medical Device",
                        content: "Plena is not a medical device and does not provide medical advice, diagnosis, or treatment. The information provided by Plena, including biometric readings, stress zone classifications, and data visualizations, is for wellness and self-improvement purposes only."
                    )

                    DisclaimerDetailSection(
                        icon: "person.2.fill",
                        iconColor: .blue,
                        title: "Consult Healthcare Professionals",
                        content: "Do not use Plena data to diagnose, treat, or prevent any disease. Consult healthcare professionals for medical advice. Plena data is not a substitute for professional medical care. If you have health concerns or experience symptoms, please seek appropriate medical attention."
                    )

                    DisclaimerDetailSection(
                        icon: "waveform.path",
                        iconColor: .purple,
                        title: "Data Accuracy",
                        content: "Sensor readings may vary and are estimates, not clinical measurements. Data accuracy depends on your device's sensors (Apple Watch, iPhone) and environmental factors. HealthKit data may be incomplete or inaccurate. Plena displays data as provided by HealthKit and makes no guarantees about data completeness or accuracy."
                    )

                    DisclaimerDetailSection(
                        icon: "wind",
                        iconColor: .green,
                        title: "Derived Measurements",
                        content: "Some biometric measurements are algorithmically derived rather than directly measured. For example, Respiratory Rate on Apple Watch is estimated using accelerometer, motion sensor, and photoplethysmography (PPG) data, rather than directly counting breaths. These derived measurements provide estimations that may differ from direct clinical measurements. Accuracy can be affected by factors including movement, device positioning, signal quality, and algorithm limitations."
                    )

                    DisclaimerDetailSection(
                        icon: "chart.bar.fill",
                        iconColor: .green,
                        title: "Stress Zone Classifications",
                        content: "Stress zones (Calm, Optimal, Elevated Stress) are general guidelines based on population averages, not personalized medical assessments. Individual baselines may vary significantly. These zones are for informational purposes only and should not be used for medical diagnosis or health assessment."
                    )

                    DisclaimerDetailSection(
                        icon: "heart.text.square.fill",
                        iconColor: .red,
                        title: "Mindfulness & Wellness",
                        content: "Mindfulness tracking and biometric data are for personal awareness and self-improvement purposes only. Results may vary by individual. Plena is not a substitute for professional mental health care. If you are experiencing mental health issues, please consult with qualified healthcare professionals."
                    )

                    DisclaimerDetailSection(
                        icon: "applewatch",
                        iconColor: .indigo,
                        title: "Device Compatibility & User Responsibility",
                        content: "Different Apple Watch models support different biometric sensors. It is your responsibility to determine which Apple Watch model you have and verify that it supports the sensors you wish to use. For example, HRV (SDNN) requires Apple Watch Series 4 or later, Respiratory Rate requires Series 6 or later, and Temperature requires Series 8, Ultra, or later. Plena displays sensor data as available from your device but does not guarantee that all sensors will be available on all Apple Watch models. You are responsible for ensuring your device meets the requirements for the features you wish to use."
                    )
                }
                .padding(.horizontal, 20)

                // Footer Note
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                        .padding(.vertical, 8)

                    Text("By using Plena, you acknowledge that you have read, understood, and agree to this medical disclaimer. You understand that Plena is not a medical device and should not be used as a substitute for professional medical care.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .navigationTitle("Medical Disclaimer")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Disclaimer Detail Section Component

struct DisclaimerDetailSection: View {
    let icon: String
    let iconColor: Color
    let title: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(iconColor)
                    .frame(width: 32)

                Text(title)
                    .font(.headline)
            }

            Text(content)
                .font(.body)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color("CardBackgroundColor"))
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        MedicalDisclaimerDetailView()
    }
}

