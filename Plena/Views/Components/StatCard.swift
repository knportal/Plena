//
//  StatCard.swift
//  Plena
//
//  Reusable stat card component for dashboard
//

import SwiftUI

struct StatCard: View {
    let value: String
    let label: String
    let subtitle: String?
    let icon: String?
    let trend: Trend?

    init(
        value: String,
        label: String,
        subtitle: String? = nil,
        icon: String? = nil,
        trend: Trend? = nil
    ) {
        self.value = value
        self.label = label
        self.subtitle = subtitle
        self.icon = icon
        self.trend = trend
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if let trend = trend {
                    TrendIndicator(trend: trend)
                }
            }

            Text(value)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.primary)

            Text(label)
                .font(.headline)
                .foregroundColor(.secondary)

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
}

#Preview {
    VStack(spacing: 16) {
        StatCard(
            value: "45",
            label: "Sessions",
            subtitle: "↑ +12 vs previous",
            icon: "calendar",
            trend: .improving
        )

        StatCard(
            value: "124 hrs",
            label: "Total Time",
            subtitle: "Avg: 15 min/session",
            icon: "clock"
        )

        StatCard(
            value: "7 days",
            label: "Streak",
            subtitle: "Keep it up! 🔥",
            icon: "flame.fill",
            trend: .improving
        )
    }
    .padding()
}

