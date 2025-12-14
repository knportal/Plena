//
//  ZoneChipsView.swift
//  Plena
//
//  Zone percentage chips (🟩 Calm: 61%, 🟨 Neutral: 29%, 🟥 Stress: 10%)
//

import SwiftUI

struct ZoneChipsView: View {
    let zoneSummaries: [ZoneSummary]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(zoneSummaries.sorted(by: { $0.zone.rawValue < $1.zone.rawValue }), id: \.id) { summary in
                HStack(spacing: 4) {
                    // Use colored circle instead of emoji to match bar colors
                    Circle()
                        .fill(summary.zone.color)
                        .frame(width: 12, height: 12)

                    Text("\(summary.zone.displayName): \(Int(summary.percentage))%")
                        .font(.caption)
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color(.secondarySystemBackground))
                )
            }
        }
    }
}

#Preview {
    ZoneChipsView(
        zoneSummaries: [
            ZoneSummary(zone: .calm, percentage: 61),
            ZoneSummary(zone: .optimal, percentage: 29),
            ZoneSummary(zone: .elevatedStress, percentage: 10)
        ]
    )
    .padding()
}


