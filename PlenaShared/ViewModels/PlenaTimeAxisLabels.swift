//
//  PlenaTimeAxisLabels.swift
//  PlenaShared
//
//  Separate view approach for x-axis labels
//

import SwiftUI

/// Main axis view for your charts
struct PlenaTimeAxisLabels: View {
    enum Granularity {
        case day
        case week
        case month
        case year
    }

    let granularity: Granularity
    /// Reference date for the current view (today, selected date, etc.)
    let referenceDate: Date

    private let calendar = Calendar.current

    // MARK: - Cached DateFormatters

    /// Cached formatter for day labels (12AM, 4AM, etc.)
    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha" // 12AM, 4AM, etc.
        formatter.amSymbol = "AM"
        formatter.pmSymbol = "PM"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    /// Cached formatter for week labels (Mon, Tue, etc.)
    private static let weekFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E" // Mon, Tue, etc.
        formatter.locale = Locale.current
        return formatter
    }()

    /// Cached formatter for year labels (month symbols)
    private static let yearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        return formatter
    }()

    var body: some View {
        if granularity == .year {
            // For year view, show all 12 months at grid positions 0-11
            // There are 13 grid lines (0-12), so we create 13 equal sections
            // Positions 0-11 show month labels, position 12 is empty (start of next year)
            HStack(spacing: 0) {
                ForEach(0..<13, id: \.self) { gridIndex in
                    Group {
                        if gridIndex < 12 && gridIndex < axisLabels.count {
                            // Show month label for positions 0-11
                            Text(axisLabels[gridIndex])
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        } else {
                            // Empty space for position 12 (start of next year)
                            Text("")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 0) // No padding for year view to match chart
        } else {
            // For other granularities, use evenly spaced labels
            HStack(alignment: .center, spacing: 0) {
                ForEach(axisLabels.indices, id: \.self) { index in
                    Text(axisLabels[index])
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)

                    if index != axisLabels.count - 1 {
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, 8)
        }
    }

    // MARK: - Label Generation

    private var axisLabels: [String] {
        switch granularity {
        case .day:
            return dayLabels()
        case .week:
            return weekLabels()
        case .month:
            return monthLabels()
        case .year:
            return yearLabels()
        }
    }

    /// 24h day: show hours every 4h (e.g., 12 AM, 4 AM, 8 AM...)
    private func dayLabels() -> [String] {
        var labels: [String] = []

        let startOfDay = calendar.startOfDay(for: referenceDate)

        // 0,4,8,12,16,20,24
        for hourOffset in stride(from: 0, through: 24, by: 4) {
            if let date = calendar.date(byAdding: .hour, value: hourOffset, to: startOfDay) {
                let formatted = Self.dayFormatter.string(from: date)
                    .replacingOccurrences(of: " ", with: "") // "12AM"
                labels.append(formatted)
            }
        }

        return labels
    }

    /// Week: M T W T F S S
    private func weekLabels() -> [String] {
        var labels: [String] = []

        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: referenceDate)?.start
            ?? calendar.startOfDay(for: referenceDate)

        for dayOffset in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek) {
                let symbol = Self.weekFormatter.string(from: date) // "Mon"
                let first = symbol.prefix(1)              // "M"
                labels.append(String(first))
            }
        }

        return labels
    }

    /// Month: show ~7 labels spaced across month (e.g. 1, 5, 10, 15, 20, 25, 30)
    private func monthLabels() -> [String] {
        guard let range = calendar.range(of: .day, in: .month, for: referenceDate) else {
            return []
        }

        let dayCount = range.count
        let targetLabelCount = 7
        let step = max(1, dayCount / (targetLabelCount - 1))

        var labels: [String] = []
        var currentDay = 1

        while currentDay <= dayCount {
            labels.append("\(currentDay)")
            currentDay += step
        }

        // Ensure last day is included
        if let last = labels.last, last != "\(dayCount)" {
            labels[labels.count - 1] = "\(dayCount)"
        }

        return labels
    }

    /// Year: Show all 12 months (Jan, Feb, Mar, Apr, May, Jun, Jul, Aug, Sep, Oct, Nov, Dec)
    private func yearLabels() -> [String] {
        let allMonths = Self.yearFormatter.shortMonthSymbols ?? [
            "Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"
        ]
        // Return all 12 months
        return allMonths
    }
}

// MARK: - Helper Extension

extension TimeRange {
    var granularity: PlenaTimeAxisLabels.Granularity {
        switch self {
        case .day: return .day
        case .week: return .week
        case .month: return .month
        case .year: return .year
        }
    }
}

// MARK: - Preview

struct PlenaTimeAxisLabels_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Day View")
                    .font(.headline)
                PlenaTimeAxisLabels(granularity: .day, referenceDate: .now)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Week View")
                    .font(.headline)
                PlenaTimeAxisLabels(granularity: .week, referenceDate: .now)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Month View")
                    .font(.headline)
                PlenaTimeAxisLabels(granularity: .month, referenceDate: .now)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Year View")
                    .font(.headline)
                PlenaTimeAxisLabels(granularity: .year, referenceDate: .now)
            }
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}

