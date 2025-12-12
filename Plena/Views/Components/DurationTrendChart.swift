//
//  DurationTrendChart.swift
//  Plena
//
//  Line chart showing average session duration trend over time
//

import SwiftUI
import Charts

struct DurationTrendChart: View {
    let dataPoints: [(date: Date, duration: Double)]
    let timeRange: TimeRange

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Average Session Duration")
                    .font(.headline)
                    .foregroundColor(.primary)

                if timeRange == .month, let monthRange = monthRangeString {
                    Text(monthRange)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            if dataPoints.isEmpty {
                Text("No duration data available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(height: 200)
            } else {
                HStack(alignment: .top, spacing: 0) {
                    // Scrollable chart without y-axis
                    ScrollView(.horizontal, showsIndicators: false) {
                        Chart {
                            ForEach(Array(dataPoints.enumerated()), id: \.offset) { index, point in
                                LineMark(
                                    x: .value("Date", point.date, unit: .day),
                                    y: .value("Duration", point.duration)
                                )
                                .foregroundStyle(.blue)
                                .interpolationMethod(.catmullRom)

                                AreaMark(
                                    x: .value("Date", point.date, unit: .day),
                                    y: .value("Duration", point.duration)
                                )
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue.opacity(0.3), .blue.opacity(0.1)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .interpolationMethod(.catmullRom)
                            }
                        }
                        .chartYScale(domain: 0...maxYValue)
                        .frame(height: 200)
                        .frame(minWidth: max(300, CGFloat(dataPoints.count) * 40))
                        .chartXAxis {
                            AxisMarks(position: .bottom, values: axisDateValues) { value in
                                AxisGridLine()
                                AxisValueLabel {
                                    if let date = value.as(Date.self) {
                                        HStack {
                                            Spacer()
                                            Text(formatAxisLabel(for: date))
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                            Spacer()
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.bottom, 20)
                        .chartYAxis {
                            // Hide the y-axis since we're using a custom fixed one
                            AxisMarks(position: .trailing) { _ in
                                AxisGridLine()
                            }
                        }
                        .padding(.bottom, 8)
                    }

                    // Fixed y-axis labels on the right side
                    YAxisLabelsView(maxValue: maxYValue, height: 200)
                        .frame(width: 30)
                }
            }
        }
        .padding()
        .padding(.bottom, 20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }

    // MARK: - Helper Methods

    /// Calculate the maximum y-value for the chart, rounded up to a nice number
    private var maxYValue: Double {
        guard !dataPoints.isEmpty else { return 60.0 }
        let maxDuration = dataPoints.map { $0.duration }.max() ?? 0
        // Round up to nearest nice number (5, 10, 15, 20, 30, 60, etc.)
        if maxDuration == 0 { return 60.0 }
        // Round up to nearest 5 minutes
        return ceil(maxDuration / 5.0) * 5.0
    }

    /// Get date values for axis marks - use actual data point dates to ensure alignment
    private var axisDateValues: [Date] {
        // Use actual data point dates to ensure labels align with data points
        // For year view, data is now grouped by month (12 data points), so all dates are used
        return dataPoints.map { $0.date }
    }

    /// Get month range string for header (e.g., "January 2024" or "December 2023 - January 2024")
    private var monthRangeString: String? {
        guard !dataPoints.isEmpty else { return nil }

        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMMM yyyy"

        let dates = dataPoints.map { $0.date }.sorted()
        guard let firstDate = dates.first, let lastDate = dates.last else { return nil }

        let firstMonth = calendar.component(.month, from: firstDate)
        let firstYear = calendar.component(.year, from: firstDate)
        let lastMonth = calendar.component(.month, from: lastDate)
        let lastYear = calendar.component(.year, from: lastDate)

        // Check if all dates are in the same month
        if firstMonth == lastMonth && firstYear == lastYear {
            return formatter.string(from: firstDate)
        } else {
            // Multiple months - show range
            let firstMonthString = formatter.string(from: firstDate)
            let lastMonthString = formatter.string(from: lastDate)
            return "\(firstMonthString) - \(lastMonthString)"
        }
    }

    /// Format axis label based on time range
    private func formatAxisLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")

        switch timeRange {
        case .day:
            formatter.dateFormat = "ha"
            formatter.amSymbol = "AM"
            formatter.pmSymbol = "PM"
            return formatter.string(from: date).replacingOccurrences(of: " ", with: "")

        case .week:
            // Return single letter day abbreviation (S, M, T, W, T, F, S)
            formatter.dateFormat = "E"
            let dayName = formatter.string(from: date)
            return String(dayName.prefix(1)).uppercased()

        case .month:
            // Show month name only on the first day of each month, otherwise just day number
            let calendar = Calendar.current
            let day = calendar.component(.day, from: date)

            if day == 1 {
                // First day of month - show month and day
                formatter.dateFormat = "MMM d"
                return formatter.string(from: date)
            } else {
                // Other days - show just day number
                formatter.dateFormat = "d"
                return formatter.string(from: date)
            }

        case .year:
            formatter.dateFormat = "MMM"
            return formatter.string(from: date)
        }
    }
}

// MARK: - Fixed Y-Axis Labels View

/// A fixed y-axis labels view that stays in place while the chart scrolls
private struct YAxisLabelsView: View {
    let maxValue: Double
    let height: CGFloat

    private var yAxisValues: [Double] {
        // Generate 5-6 evenly spaced values from 0 to maxValue
        let step = max(5.0, maxValue / 5.0)
        var values: [Double] = [0]
        var current = step
        while current <= maxValue {
            values.append(current)
            current += step
        }
        // Ensure maxValue is included if it's not already
        if values.last != maxValue && maxValue > 0 {
            values.append(maxValue)
        }
        return values.sorted()
    }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(yAxisValues.reversed(), id: \.self) { value in
                HStack {
                    Text("\(Int(value))")
                        .font(.caption)
                        .foregroundStyle(.primary)
                    Spacer()
                }
                .frame(height: height / CGFloat(max(yAxisValues.count - 1, 1)))
            }
        }
        .frame(height: height)
    }
}

#Preview {
    let calendar = Calendar.current
    let today = Date()

    DurationTrendChart(
        dataPoints: [
            (date: calendar.date(byAdding: .day, value: -6, to: today)!, duration: 15.0),
            (date: calendar.date(byAdding: .day, value: -5, to: today)!, duration: 18.0),
            (date: calendar.date(byAdding: .day, value: -4, to: today)!, duration: 20.0),
            (date: calendar.date(byAdding: .day, value: -3, to: today)!, duration: 17.0),
            (date: calendar.date(byAdding: .day, value: -2, to: today)!, duration: 19.0),
            (date: calendar.date(byAdding: .day, value: -1, to: today)!, duration: 22.0),
            (date: today, duration: 20.0)
        ],
        timeRange: TimeRange.week
    )
    .padding()
}

