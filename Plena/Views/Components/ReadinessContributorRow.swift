//
//  ReadinessContributorRow.swift
//  Plena
//
//  Individual contributor row component for readiness view
//

import SwiftUI

struct ReadinessContributorRow: View {
    let contributor: ReadinessContributor
    let onTap: (() -> Void)?

    init(contributor: ReadinessContributor, onTap: (() -> Void)? = nil) {
        self.contributor = contributor
        self.onTap = onTap
    }

    var body: some View {
        let content = HStack(spacing: 12) {
            // Icon
            Image(systemName: contributor.icon)
                .font(.title3)
                .foregroundColor(contributor.status.color)
                .frame(width: 30)

            // Name and value
            VStack(alignment: .leading, spacing: 4) {
                Text(contributor.name)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(contributor.value)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Status badge (only show if status should be displayed)
            if contributor.status.shouldShowBadge {
                Text(contributor.status.rawValue)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(contributor.status.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(contributor.status.color.opacity(0.15))
                    )
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 8)

                    // Progress
                    RoundedRectangle(cornerRadius: 4)
                        .fill(contributor.status.color)
                        .frame(width: geometry.size.width * contributor.progress, height: 8)
                }
            }
            .frame(width: 80, height: 8)

            // Arrow
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)

        if let onTap = onTap {
            Button(action: onTap) {
                content
            }
            .buttonStyle(PlainButtonStyle())
        } else {
            content
        }
    }
}

#Preview {
    VStack(spacing: 0) {
        ReadinessContributorRow(
            contributor: ReadinessContributor(
                name: "Resting heart rate",
                value: "64 bpm",
                status: .optimal,
                score: 1.0
            )
        )

        Divider()

        ReadinessContributorRow(
            contributor: ReadinessContributor(
                name: "HRV balance",
                value: "Higher",
                status: .higher,
                score: 0.75
            )
        )

        Divider()

        ReadinessContributorRow(
            contributor: ReadinessContributor(
                name: "Sleep",
                value: "Moderate",
                status: .moderate,
                score: 0.5
            )
        )
    }
    .background(Color(.systemBackground))
}

