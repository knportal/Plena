//
//  ConsistencyChartView.swift
//  Plena
//
//  Bar chart showing period scores with height (calm score) and color (zone)
//

import SwiftUI
import Charts

struct ConsistencyChartView: View {
    let periodScores: [PeriodScore]
    let timeRange: TimeRange

    var body: some View {
        if periodScores.isEmpty {
            VStack {
                Spacer()
                Text("No data available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .frame(height: 220)
        } else {
            Chart(periodScores) { score in
                BarMark(
                    x: .value("Period", score.label),
                    y: .value("Score", score.score)
                )
                .foregroundStyle(score.zone.color)
                .cornerRadius(4)
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let intValue = value.as(Double.self) {
                            Text("\(Int(intValue))")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .chartYScale(domain: 0...100)
            .chartXAxis {
                AxisMarks(position: .bottom) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let label = value.as(String.self) {
                            Text(label)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .frame(height: 220)
        }
    }
}

#Preview {
    let calendar = Calendar.current
    let today = Date()

    ConsistencyChartView(
        periodScores: [
            PeriodScore(label: "W1", date: calendar.date(byAdding: .day, value: -28, to: today)!, score: 62, zone: .optimal),
            PeriodScore(label: "W2", date: calendar.date(byAdding: .day, value: -21, to: today)!, score: 75, zone: .calm),
            PeriodScore(label: "W3", date: calendar.date(byAdding: .day, value: -14, to: today)!, score: 81, zone: .calm),
            PeriodScore(label: "W4", date: calendar.date(byAdding: .day, value: -7, to: today)!, score: 55, zone: .optimal),
            PeriodScore(label: "W5", date: today, score: 88, zone: .calm)
        ],
        timeRange: .month
    )
    .padding()
}


