//
//  MetricSelectorView.swift
//  Plena
//
//  Updated metric selector with icons and subtitles
//

import SwiftUI

struct MetricSelectorView: View {
    @Binding var selectedMetric: SensorType
    let enabledMetrics: [SensorType]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(enabledMetrics.enumerated()), id: \.element) { index, metric in
                    MetricButton(
                        metric: metric,
                        isSelected: metric == selectedMetric,
                        subtitle: subtitle(for: metric),
                        index: index,
                        color: colorForSensor(metric),
                        iconName: iconName(for: metric)
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedMetric = metric
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    private func iconName(for metric: SensorType) -> String {
        switch metric {
        case .hrv:
            return "waveform.path.ecg"
        case .heartRate:
            return "heart.fill"
        case .respiratoryRate:
            return "wind"
        case .vo2Max:
            return "figure.run"
        case .temperature:
            return "thermometer"
        }
    }

    private func subtitle(for metric: SensorType) -> String {
        switch metric {
        case .hrv:
            return "Recovery"
        case .heartRate:
            return "Calmness"
        case .respiratoryRate:
            return "Breath Depth"
        case .vo2Max:
            return "Fitness"
        case .temperature:
            return "Body State"
        }
    }

    private func colorForSensor(_ sensor: SensorType) -> Color {
        switch sensor {
        case .heartRate:
            return .red
        case .hrv:
            return .blue
        case .respiratoryRate:
            return .green
        case .vo2Max:
            return .orange
        case .temperature:
            return .purple
        }
    }
}

// MARK: - Metric Button Component

private struct MetricButton: View {
    let metric: SensorType
    let isSelected: Bool
    let subtitle: String
    let index: Int
    let color: Color
    let iconName: String
    let action: () -> Void

    @State private var hasAppeared = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                // Icon - prominent in center
                Image(systemName: iconName)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(isSelected ? color : .primary)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(isSelected ? color.opacity(0.15) : Color.primary.opacity(0.08))
                    )

                // Sensor name - compact
                Text(metric.rawValue)
                    .font(.system(size: 9, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)

                // Subtitle - very small, secondary color
                Text(subtitle)
                    .font(.system(size: 7, weight: .regular))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
            }
            .frame(width: 60, height: 70) // Slightly taller to fit subtitle
            .padding(8)
            .background(
                // Circular glassmorphic background
                Circle()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Circle()
                            .stroke(
                                isSelected ? color : Color.clear,
                                lineWidth: isSelected ? 2 : 0
                            )
                    )
                    .shadow(
                        color: isSelected ? color.opacity(0.3) : .black.opacity(0.1),
                        radius: isSelected ? 8 : 3,
                        x: 0,
                        y: isSelected ? 2 : 1
                    )
            )
            .scaleEffect(isSelected ? 1.1 : (hasAppeared ? 1.0 : 0.85))
            .opacity(hasAppeared ? 1.0 : 0.0)
            .offset(x: hasAppeared ? 0 : 20)
        }
        .buttonStyle(.plain)
        .onAppear {
            // Staggered animation - triggers when button appears
            if !hasAppeared {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75).delay(Double(index) * 0.05)) {
                    hasAppeared = true
                }
            }
        }
    }
}

#Preview {
    MetricSelectorView(
        selectedMetric: .constant(.hrv),
        enabledMetrics: [.hrv, .heartRate, .respiratoryRate]
    )
    .padding()
}









