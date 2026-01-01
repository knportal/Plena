//
//  TrendInsightCard.swift
//  Plena
//
//  Insight header card showing trend stats (status, delta, description)
//

import SwiftUI

struct TrendInsightCard: View {
    let trendStats: TrendStats?

    var body: some View {
        if let stats = trendStats {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(stats.statusText)
                        .font(.headline)
                        .foregroundColor(.primary)

                    if !stats.deltaText.isEmpty {
                        Text(stats.deltaText)
                            .font(.subheadline)
                            .foregroundColor(statusColor(for: stats.statusText))
                    }

                    Spacer()
                }

                Text(stats.description)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.secondarySystemBackground))
            )
        } else {
            EmptyView()
        }
    }

    private func statusColor(for status: String) -> Color {
        switch status.lowercased() {
        case "improving":
            return .green
        case "mixed":
            return .orange
        case "stable":
            return .blue
        default:
            return .secondary
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        TrendInsightCard(
            trendStats: TrendStats(
                statusText: "Improving",
                deltaText: "+14% vs last month",
                description: "Your nervous system is reaching recovery more often this month."
            )
        )

        TrendInsightCard(
            trendStats: TrendStats(
                statusText: "Stable",
                deltaText: "-3 bpm vs last week",
                description: "Your session heart rate stayed in a similar range."
            )
        )

        TrendInsightCard(trendStats: nil)
    }
    .padding()
}









