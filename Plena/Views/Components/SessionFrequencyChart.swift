//
//  SessionFrequencyChart.swift
//  Plena
//
//  Bar chart showing session frequency over time
//

import SwiftUI
import Charts

struct SessionFrequencyChart: View {
    let dataPoints: [SessionFrequencyDataPoint]
    let timeRange: TimeRange
    let timelineSessions: [TimelineSessionDataPoint]? // For day view timeline

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Sessions Over Time")
                    .font(.headline)
                    .foregroundColor(.primary)

                if timeRange == .month, let monthRange = monthRangeString {
                    Text(monthRange)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            if timeRange == .day, let timelineSessions = timelineSessions {
                // Timeline view for day view
                if timelineSessions.isEmpty {
                    Text("No session data available")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(height: 200)
                } else {
                    timelineChartView(sessions: timelineSessions)
                }
            } else if dataPoints.isEmpty {
                Text("No session data available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(height: 200)
            } else {
                HStack(alignment: .top, spacing: 0) {
                    // Scrollable chart without y-axis
                    ScrollView(.horizontal, showsIndicators: false) {
                        Chart {
                            ForEach(Array(dataPoints.enumerated()), id: \.offset) { index, point in
                                BarMark(
                                    x: .value("Date", point.date, unit: timeRange == .day ? .hour : .day),
                                    y: .value("Sessions", point.count)
                                )
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.green.opacity(0.8), .green.opacity(0.4)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .cornerRadius(4)
                            }
                        }
                        .chartYScale(domain: 0...maxYValue)
                        .frame(height: 200)
                        .frame(minWidth: max(300, CGFloat(dataPoints.count) * (timeRange == .year ? 60 : (timeRange == .day ? 80 : 40))))
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

    // MARK: - Timeline Chart View (Day View)

    @ViewBuilder
    private func timelineChartView(sessions: [TimelineSessionDataPoint]) -> some View {
        let calendar = Calendar.current
        if let firstSession = sessions.first {
            let dayStart = calendar.startOfDay(for: firstSession.startTime)

            // Calculate time range for x-axis (show from first session hour - 1 to last session hour + 1, or 6am-10pm default)
            let firstSessionHour = calendar.component(.hour, from: firstSession.startTime)
            let lastSession = sessions.last ?? firstSession
            let lastSessionEndHour = calendar.component(.hour, from: lastSession.endTime)
            let lastSessionStartHour = calendar.component(.hour, from: lastSession.startTime)
            let lastSessionHour = max(lastSessionEndHour, lastSessionStartHour)

            let chartStartHour = max(0, firstSessionHour - 1)
            let chartEndHour = min(23, lastSessionHour + 1)

            if let chartStart = calendar.date(bySettingHour: chartStartHour, minute: 0, second: 0, of: dayStart),
               let chartEnd = calendar.date(bySettingHour: chartEndHour, minute: 0, second: 0, of: dayStart) {
                // Generate hour markers for x-axis (moved outside ViewBuilder)
                let hourMarkers = generateHourMarkers(
                    calendar: calendar,
                    dayStart: dayStart,
                    startHour: chartStartHour,
                    endHour: chartEndHour
                )

                ScrollView(.horizontal, showsIndicators: false) {
                    Chart {
                        ForEach(Array(sessions.enumerated()), id: \.element.sessionId) { index, session in
                            // Use BarMark positioned at start time with width representing duration
                            // Calculate width in points: 1 minute = 2 points for good visibility
                            let widthPoints = CGFloat(session.duration / 60.0) * 2.0

                            BarMark(
                                x: .value("Time", session.startTime, unit: .minute),
                                y: .value("Session", index + 1),
                                width: .fixed(max(20, widthPoints)) // Minimum 20 points width
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.green.opacity(0.8), .green.opacity(0.4)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(4)
                            .annotation(position: .top, alignment: .leading) {
                                Text("\(Int(session.durationMinutes))m")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 2)
                                    .background(Color(.systemBackground).opacity(0.8))
                                    .cornerRadius(4)
                            }
                        }
                    }
                    .chartXScale(domain: chartStart...chartEnd)
                    .chartXAxis {
                        AxisMarks(position: .bottom, values: hourMarkers) { value in
                            AxisGridLine()
                            AxisValueLabel {
                                if let date = value.as(Date.self) {
                                    Text(formatAxisLabel(for: date))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .chartYAxis(.hidden)
                    .frame(height: max(120, CGFloat(sessions.count) * 50 + 40))
                    .frame(minWidth: max(300, CGFloat(hourMarkers.count) * 60))
                    .padding(.bottom, 20)
                }
            } else {
                Text("No session data available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(height: 200)
            }
        } else {
            Text("No session data available")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(height: 200)
        }
    }

    // MARK: - Helper Methods

    /// Generate hour markers for x-axis
    private func generateHourMarkers(calendar: Calendar, dayStart: Date, startHour: Int, endHour: Int) -> [Date] {
        var hourMarkers: [Date] = []
        var currentHour = startHour
        while currentHour <= endHour {
            if let hourDate = calendar.date(bySettingHour: currentHour, minute: 0, second: 0, of: dayStart) {
                hourMarkers.append(hourDate)
            }
            currentHour += 1
        }
        return hourMarkers
    }

    /// Calculate the maximum y-value for the chart, rounded up to a nice number
    private var maxYValue: Int {
        guard !dataPoints.isEmpty else { return 5 }
        let maxCount = dataPoints.map { $0.count }.max() ?? 0
        // Round up to nearest nice number (1, 2, 5, 10, 20, 50, etc.)
        if maxCount == 0 { return 5 }
        let magnitude = Int(pow(10, floor(log10(Double(maxCount)))))
        let normalized = Double(maxCount) / Double(magnitude)
        let rounded: Int
        if normalized <= 1 {
            rounded = 1
        } else if normalized <= 2 {
            rounded = 2
        } else if normalized <= 5 {
            rounded = 5
        } else {
            rounded = 10
        }
        return rounded * magnitude
    }

    /// Get date values for axis marks - use actual data point dates to ensure alignment
    private var axisDateValues: [Date] {
        // Use actual data point dates to ensure labels align with bars
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
    let maxValue: Int
    let height: CGFloat

    private var yAxisValues: [Int] {
        // Generate 5-6 evenly spaced values from 0 to maxValue
        let step = max(1, maxValue / 5)
        var values: [Int] = [0]
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
                    Text("\(value)")
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
    SessionFrequencyChart(
        dataPoints: [
            SessionFrequencyDataPoint(period: "Mon", date: Date(), count: 2),
            SessionFrequencyDataPoint(period: "Tue", date: Date(), count: 1),
            SessionFrequencyDataPoint(period: "Wed", date: Date(), count: 3),
            SessionFrequencyDataPoint(period: "Thu", date: Date(), count: 2),
            SessionFrequencyDataPoint(period: "Fri", date: Date(), count: 1),
            SessionFrequencyDataPoint(period: "Sat", date: Date(), count: 0),
            SessionFrequencyDataPoint(period: "Sun", date: Date(), count: 2)
        ],
        timeRange: TimeRange.week,
        timelineSessions: nil
    )
    .padding()
}

