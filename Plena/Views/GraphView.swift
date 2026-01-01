//
//  GraphView.swift
//  Plena
//
//  Created on [Date]
//

import SwiftUI
import Charts

struct GraphView: View {
    let dataPoints: [(date: Date, value: Double)]
    let sensorRange: SensorRange
    let sensorName: String
    let unit: String
    let trend: Trend?
    let timeRange: TimeRange

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Range indicators with trend indicator on same row
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Range Zones")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    HStack(spacing: 12) {
                        RangeIndicator(color: .orange, label: "Above", range: sensorRange.above)
                        RangeIndicator(color: .green, label: "Normal", range: sensorRange.normal)
                        RangeIndicator(color: .blue, label: "Below", range: sensorRange.below)
                    }
                }

                Spacer()

                // Trend indicator on same row
                if let trend = trend {
                    VStack(alignment: .trailing, spacing: 6) {
                        Text("Trend")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        TrendIndicator(trend: trend)
                    }
                }
            }
            .padding(.bottom, 16)

            // Chart
            if dataPoints.isEmpty {
                VStack {
                    Spacer()
                    Text("No data available")
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(height: 200)
            } else {
                VStack(spacing: 0) {
                    Chart {
                        // Background range zones using RectangleMark for full width
                        // Use full visible range, not just data range, to ensure proper scaling
                        let visibleRange = xAxisVisibleRange
                        // Filter data points to visible range to prevent line extending beyond chart
                        let filteredDataPoints = dataPoints.filter { point in
                            point.date >= visibleRange.start && point.date <= visibleRange.end
                        }

                        // Above range zone
                        RectangleMark(
                            xStart: .value("Start", visibleRange.start),
                            xEnd: .value("End", visibleRange.end),
                            yStart: .value("Above Start", sensorRange.above.lowerBound),
                            yEnd: .value("Above End", sensorRange.above.upperBound)
                        )
                        .foregroundStyle(.orange.opacity(0.12))

                        // Normal range zone
                        RectangleMark(
                            xStart: .value("Start", visibleRange.start),
                            xEnd: .value("End", visibleRange.end),
                            yStart: .value("Normal Start", sensorRange.normal.lowerBound),
                            yEnd: .value("Normal End", sensorRange.normal.upperBound)
                        )
                        .foregroundStyle(.green.opacity(0.12))

                        // Below range zone
                        RectangleMark(
                            xStart: .value("Start", visibleRange.start),
                            xEnd: .value("End", visibleRange.end),
                            yStart: .value("Below Start", sensorRange.below.lowerBound),
                            yEnd: .value("Below End", sensorRange.below.upperBound)
                        )
                        .foregroundStyle(.blue.opacity(0.12))

                        // Range reference lines (boundaries)
                        RuleMark(y: .value("Above", sensorRange.above.lowerBound))
                            .foregroundStyle(.orange.opacity(0.4))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))

                        RuleMark(y: .value("Normal Top", sensorRange.normal.upperBound))
                            .foregroundStyle(.green.opacity(0.4))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))

                        RuleMark(y: .value("Normal Bottom", sensorRange.normal.lowerBound))
                            .foregroundStyle(.green.opacity(0.4))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))

                        RuleMark(y: .value("Below", sensorRange.below.upperBound))
                            .foregroundStyle(.blue.opacity(0.4))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))

                        // Data line - single consistent blue color (using filtered points)
                        ForEach(Array(filteredDataPoints.enumerated()), id: \.offset) { index, point in
                            LineMark(
                                x: .value("Time", point.date, unit: .minute),
                                y: .value("Value", point.value)
                            )
                            .foregroundStyle(.blue)
                            .lineStyle(StrokeStyle(lineWidth: 2.5))
                            .interpolationMethod(.catmullRom)
                        }

                        // Vertical grid lines aligned with x-axis labels
                        // Drawn after data line to ensure they appear on top of zone shades
                        ForEach(xAxisGridLineDates(), id: \.self) { date in
                            RuleMark(x: .value("Grid", date))
                                .foregroundStyle(.gray.opacity(0.3))
                                .lineStyle(StrokeStyle(lineWidth: 0.75))
                        }
                    }
                    .frame(height: 220)
                    .clipped()
                    .chartXScale(domain: xAxisVisibleRange.start...xAxisVisibleRange.end)
                    .chartXAxis {
                        // Hide Chart's axis - we use separate view for labels
                        AxisMarks(position: .bottom) { _ in }
                    }
                    .chartYAxis {
                        AxisMarks(position: .trailing) { value in
                            AxisGridLine()
                            AxisValueLabel()
                        }
                    }
                    .padding(.horizontal, timeRange == .year ? 0 : 0) // Remove horizontal padding for year to match labels

                    // X-axis labels as separate view below chart
                    PlenaTimeAxisLabels(
                        granularity: timeRange.granularity,
                        referenceDate: dataPoints.first?.date ?? Date()
                    )
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                    .padding(.horizontal, timeRange == .year ? 0 : 0) // Match chart padding

                    // Chart legend explanation
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(.blue)
                                .frame(width: 8, height: 8)
                            Text("Your Data")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        Text("•")
                            .foregroundColor(.secondary)
                            .font(.caption2)
                        Text("Shaded areas show range zones")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 4)
                    .padding(.bottom, 4)
                }
            }

            // Statistics
            if !dataPoints.isEmpty {
                HStack(spacing: 20) {
                    StatView(label: "Min", value: minValue, unit: unit)
                    StatView(label: "Max", value: maxValue, unit: unit)
                    StatView(label: "Avg", value: averageValue, unit: unit)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
            }
        }
        .padding()
        .padding(.bottom, 12) // Reduced bottom padding
    }

    private var averageValue: Double? {
        guard !dataPoints.isEmpty else { return nil }
        let sum = dataPoints.reduce(0.0) { $0 + $1.value }
        return sum / Double(dataPoints.count)
    }

    private var minValue: Double? {
        dataPoints.map { $0.value }.min()
    }

    private var maxValue: Double? {
        dataPoints.map { $0.value }.max()
    }

    private func colorForCategory(_ category: RangeCategory) -> Color {
        switch category {
        case .above: return .orange
        case .normal: return .green
        case .below: return .blue
        }
    }

    // MARK: - X-Axis Domain

    /// Calculates the visible x-axis domain based on time range (not data range)
    /// This ensures grid lines are evenly spaced across the full visible period
    private var xAxisVisibleRange: (start: Date, end: Date) {
        guard !dataPoints.isEmpty else {
            let now = Date()
            return (now, now)
        }

        let calendar = Calendar.current
        let referenceDate = dataPoints.first?.date ?? Date()

        switch timeRange {
        case .day:
            // Full day: start of day to start of next day
            let startOfDay = calendar.startOfDay(for: referenceDate)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
            return (startOfDay, endOfDay)

        case .week:
            // Full week: start of week to start of next week
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: referenceDate)?.start
                ?? calendar.startOfDay(for: referenceDate)
            let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek) ?? startOfWeek
            return (startOfWeek, endOfWeek)

        case .month:
            // Full month: start of month to start of next month (for proper chart scaling)
            guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: referenceDate)),
                  let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth) else {
                let now = Date()
                return (now, now)
            }
            return (startOfMonth, endOfMonth)

        case .year:
            // Full year: start of year to start of next year
            guard let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: referenceDate)),
                  let endOfYear = calendar.date(byAdding: .year, value: 1, to: startOfYear) else {
                let now = Date()
                return (now, now)
            }
            return (startOfYear, endOfYear)
        }
    }

    // MARK: - X-Axis Grid Lines

    /// Generates dates for vertical grid lines that align with x-axis labels
    private func xAxisGridLineDates() -> [Date] {
        guard !dataPoints.isEmpty else { return [] }

        let calendar = Calendar.current
        let referenceDate = dataPoints.first?.date ?? Date()
        let visibleRange = xAxisVisibleRange

        var dates: [Date] = []

        switch timeRange {
        case .day:
            dates = dayGridLineDates(calendar: calendar, referenceDate: referenceDate)
            // Don't filter - always show full day grid lines to align with labels
            return dates
        case .week:
            // For week view, show all 7 days regardless of data range
            // This ensures we always have lines for S M T W T F S
            dates = weekGridLineDates(calendar: calendar, referenceDate: referenceDate)
            return dates
        case .month:
            dates = monthGridLineDates(calendar: calendar, referenceDate: referenceDate)
            // Filter to ensure dates are within visible range (prevent lines extending beyond chart)
            // Only include dates strictly less than the end date (since end is start of next month)
            return dates.filter { $0 >= visibleRange.start && $0 < visibleRange.end }
        case .year:
            // For year view, show all 12 months plus start of next year for proper spacing
            // Don't filter by data range to ensure all months are visible
            dates = yearGridLineDates(calendar: calendar, referenceDate: referenceDate)
            return dates
        }
    }

    private func dayGridLineDates(calendar: Calendar, referenceDate: Date) -> [Date] {
        var dates: [Date] = []
        let startOfDay = calendar.startOfDay(for: referenceDate)

        // Every 4 hours: 0, 4, 8, 12, 16, 20, 24
        for hourOffset in stride(from: 0, through: 24, by: 4) {
            if let date = calendar.date(byAdding: .hour, value: hourOffset, to: startOfDay) {
                dates.append(date)
            }
        }

        return dates
    }

    private func weekGridLineDates(calendar: Calendar, referenceDate: Date) -> [Date] {
        var dates: [Date] = []
        // Use the same logic as PlenaTimeAxisLabels to ensure alignment
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: referenceDate)?.start
            ?? calendar.startOfDay(for: referenceDate)

        // One for each day of the week (S M T W T F S)
        // Always generate all 7 days to match the labels
        for dayOffset in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek) {
                // Use start of day to ensure proper alignment
                let startOfDay = calendar.startOfDay(for: date)
                dates.append(startOfDay)
            }
        }

        return dates
    }

    private func monthGridLineDates(calendar: Calendar, referenceDate: Date) -> [Date] {
        guard let range = calendar.range(of: .day, in: .month, for: referenceDate),
              let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: referenceDate)) else {
            return []
        }

        let dayCount = range.count
        var dates: [Date] = []

        // Match the exact same logic as PlenaTimeAxisLabels.monthLabels() to ensure alignment
        let targetLabelCount = 7
        let step = max(1, dayCount / (targetLabelCount - 1))
        var currentDay = 1

        while currentDay <= dayCount {
            if let date = calendar.date(byAdding: .day, value: currentDay - 1, to: startOfMonth) {
                dates.append(date)
            }
            currentDay += step
        }

        // Ensure last day is included (matching PlenaTimeAxisLabels logic)
        // Unlike labels which replace the last value, we should append the last day if it's not already included
        // This ensures we have all intermediate grid lines plus the final day
        if let lastDate = calendar.date(byAdding: .day, value: dayCount - 1, to: startOfMonth) {
            let lastDayNumber = calendar.component(.day, from: lastDate)
            // Check if last date is already in the list
            let lastDayAlreadyIncluded = dates.contains { calendar.component(.day, from: $0) == lastDayNumber }
            if !lastDayAlreadyIncluded {
                // Append the last day instead of replacing, so we keep all intermediate dates
                dates.append(lastDate)
            }
        }

        return dates
    }

    private func yearGridLineDates(calendar: Calendar, referenceDate: Date) -> [Date] {
        var dates: [Date] = []
        guard let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: referenceDate)) else {
            return []
        }

        // Show grid lines for ALL 12 months (provides visual structure)
        // Labels will only show every other month (Jan, Mar, May, Jul, Sep, Nov)
        // This gives better visual separation while keeping labels readable
        for monthOffset in 0...12 { // 0-12 to include start of year and start of next year
            if let date = calendar.date(byAdding: .month, value: monthOffset, to: startOfYear) {
                dates.append(date)
            }
        }

        return dates
    }


}

struct RangeIndicator: View {
    let color: Color
    let label: String
    let range: ClosedRange<Double>

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                Text("\(Int(range.lowerBound))-\(Int(range.upperBound))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct StatView: View {
    let label: String
    let value: Double?
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            if let value = value {
                Text("\(Int(value)) \(unit)")
                    .font(.headline)
            } else {
                Text("--")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct TrendIndicator: View {
    let trend: Trend

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: trend.icon)
                .font(.caption)
                .foregroundColor(trend.color)
            Text(trend.description)
                .font(.caption)
                .foregroundColor(trend.color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(trend.color.opacity(0.1))
        .cornerRadius(8)
    }
}

#Preview {
    GraphView(
        dataPoints: [
            (Date().addingTimeInterval(-3600), 65.0),
            (Date().addingTimeInterval(-1800), 72.0),
            (Date(), 68.0)
        ],
        sensorRange: SensorRange(
            above: 100...200,
            normal: 60...100,
            below: 30...60
        ),
        sensorName: "Heart Rate",
        unit: "BPM",
        trend: .improving,
        timeRange: .day
    )
}

