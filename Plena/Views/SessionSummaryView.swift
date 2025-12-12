//
//  SessionSummaryView.swift
//  Plena
//
//  Created on [Date]
//

import SwiftUI

struct SessionSummaryView: View {
    let summary: SessionSummary
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.title2)
                    .foregroundColor(Color("PlenaPrimary"))

                Text("Session Summary")
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()
            }
            .padding()
            .background(Color(.systemGroupedBackground))

            // Content
            ScrollView {
                VStack(spacing: 24) {
                    // Heart Rate Section
                    if let avgHR = summary.averageHeartRate {
                        SummaryCard(
                            title: "Average Heart Rate",
                            value: "\(Int(avgHR)) BPM",
                            icon: "heart.fill",
                            iconColor: Color("HeartRateColor")
                        )
                    }

                    // Lowest Heart Rate
                    if let lowestHR = summary.lowestHeartRate {
                        SummaryCard(
                            title: "Lowest Heart Rate",
                            value: "\(Int(lowestHR)) BPM",
                            icon: "arrow.down.circle.fill",
                            iconColor: Color("SuccessColor")
                        )
                    }

                    // HRV Change
                    if let hrvStart = summary.hrvStart,
                       let hrvEnd = summary.hrvEnd,
                       let hrvChange = summary.hrvChange {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "waveform.path.ecg")
                                    .foregroundColor(Color("HRVColor"))
                                    .font(.title3)

                                Text("HRV Change")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }

                            HStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Start")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(Int(hrvStart)) ms")
                                        .font(.title3)
                                        .fontWeight(.medium)
                                }

                                Image(systemName: "arrow.right")
                                    .foregroundColor(.secondary)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("End")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(Int(hrvEnd)) ms")
                                        .font(.title3)
                                        .fontWeight(.medium)
                                }

                                Spacer()

                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("Change")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(hrvChange >= 0 ? "+\(Int(hrvChange)) ms" : "\(Int(hrvChange)) ms")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(hrvChange >= 0 ? Color("SuccessColor") : Color("WarningColor"))
                                }
                            }

                            // Insight message
                            if let message = summary.hrvChangeMessage {
                                HStack {
                                    Image(systemName: hrvChange >= 0 ? "sparkles" : "arrow.up.right.circle.fill")
                                        .foregroundColor(hrvChange >= 0 ? .yellow : .orange)
                                    Text(message)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                                .padding(.top, 4)
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                    }

                    // Respiratory Rate Trend
                    if let avgRespRate = summary.averageRespiratoryRate {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "wind")
                                    .foregroundColor(Color("RespiratoryColor"))
                                    .font(.title3)

                                Text("Respiratory Rate")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }

                            HStack {
                                Text("Average: \(Int(avgRespRate)) /min")
                                    .font(.body)

                                Spacer()

                                // Trend indicator
                                HStack(spacing: 4) {
                                    switch summary.respiratoryRateTrend {
                                    case .decreasing:
                                        Image(systemName: "arrow.down.circle.fill")
                                            .foregroundColor(Color("SuccessColor"))
                                        Text("Decreasing")
                                            .font(.subheadline)
                                            .foregroundColor(Color("SuccessColor"))
                                    case .increasing:
                                        Image(systemName: "arrow.up.circle.fill")
                                            .foregroundColor(Color("WarningColor"))
                                        Text("Increasing")
                                            .font(.subheadline)
                                            .foregroundColor(Color("WarningColor"))
                                    case .stable:
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundColor(Color("PlenaPrimary"))
                                        Text("Stable")
                                            .font(.subheadline)
                                            .foregroundColor(Color("PlenaPrimary"))
                                    case .insufficientData:
                                        Text("Insufficient data")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                    }
                }
                .padding()
            }

            // Dismiss Button
            Button(action: onDismiss) {
                Text("Done")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .cornerRadius(20)
        .shadow(radius: 10)
    }
}

struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let iconColor: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .font(.title3)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text(value)
                    .font(.title2)
                    .fontWeight(.semibold)
            }

            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

#Preview {
    SessionSummaryView(
        summary: SessionSummary(
            averageHeartRate: 72.5,
            lowestHeartRate: 65.0,
            hrvStart: 45.0,
            hrvEnd: 52.0,
            hrvChange: 7.0,
            averageRespiratoryRate: 14.5,
            respiratoryRateTrend: .decreasing
        ),
        onDismiss: {}
    )
    .padding()
}


