//
//  ReadinessScoreCard.swift
//  Plena
//
//  Main readiness score display card
//

import SwiftUI

struct ReadinessScoreCard: View {
    let score: ReadinessScore
    let changeFromYesterday: Double?

    @State private var isShowingMedicalDisclaimer = false

    var body: some View {
        VStack(spacing: 16) {
            // Score display
            VStack(spacing: 8) {
                Text("\(Int(score.overallScore))")
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundColor(score.status.color)

                Text("Daily Trend Score")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Text("For self-reflection only (not medical).")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                // Status badge
                Text(score.status.rawValue)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(score.status.color)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(score.status.color.opacity(0.15))
                    )
            }

            // Comparison to yesterday
            if let change = changeFromYesterday {
                HStack(spacing: 4) {
                    Image(systemName: change >= 0 ? "arrow.up" : "arrow.down")
                        .font(.caption)
                        .foregroundColor(.gray)

                    Text("\(change >= 0 ? "+" : "")\(Int(change))")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.gray)

                    Text("vs yesterday")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            HStack {
                Spacer()
                Button {
                    isShowingMedicalDisclaimer = true
                } label: {
                    Label("Disclaimer", systemImage: "info.circle")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Disclaimer")
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
        )
        .sheet(isPresented: $isShowingMedicalDisclaimer) {
            NavigationStack {
                MedicalDisclaimerDetailView()
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        ReadinessScoreCard(
            score: ReadinessScore(
                date: Date(),
                overallScore: 85,
                contributors: []
            ),
            changeFromYesterday: 5
        )

        ReadinessScoreCard(
            score: ReadinessScore(
                date: Date(),
                overallScore: 65,
                contributors: []
            ),
            changeFromYesterday: -10
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}










