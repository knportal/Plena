//
//  SmartAxisLabelFormatter.swift
//  PlenaShared
//
//  Smart x-axis label formatting based on time range
//

import Foundation
import Charts

struct SmartAxisLabelFormatter {
    let timeRange: TimeRange
    let dataPoints: [(date: Date, value: Double)]

    // MARK: - X-Axis Values

    func xAxisValues() -> [Date] {
        guard !dataPoints.isEmpty else { return [] }

        let dates = dataPoints.map { $0.date }.sorted()
        guard let firstDate = dates.first, let lastDate = dates.last else { return [] }

        let calendar = Calendar.current

        switch timeRange {
        case .day:
            return dayViewValues(calendar: calendar, firstDate: firstDate, lastDate: lastDate)
        case .week:
            return weekViewValues(calendar: calendar, firstDate: firstDate, lastDate: lastDate)
        case .month:
            return monthViewValues(calendar: calendar, firstDate: firstDate, lastDate: lastDate, dates: dates)
        case .year:
            return yearViewValues(calendar: calendar, firstDate: firstDate, lastDate: lastDate)
        }
    }

    // MARK: - Day View (24 hours)

    private func dayViewValues(calendar: Calendar, firstDate: Date, lastDate: Date) -> [Date] {
        var values: [Date] = []
        let startOfDay = calendar.startOfDay(for: firstDate)

        // Show hour clusters every 2-3 hours: 6 AM, 9 AM, 12 PM, 3 PM, 6 PM, 9 PM
        let hourIntervals = [6, 9, 12, 15, 18, 21]

        for hour in hourIntervals {
            if let date = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: startOfDay) {
                // Include if within the data range (with some tolerance)
                let hourStart = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: startOfDay) ?? startOfDay
                let hourEnd = calendar.date(bySettingHour: hour, minute: 59, second: 59, of: startOfDay) ?? startOfDay

                // Include if the hour range overlaps with data range
                if hourStart <= lastDate && hourEnd >= firstDate {
                    values.append(date)
                }
            }
        }

        // Always include first and last dates if they're not already included
        let firstHour = calendar.component(.hour, from: firstDate)
        if !hourIntervals.contains(firstHour) {
            values.insert(firstDate, at: 0)
        }

        let lastHour = calendar.component(.hour, from: lastDate)
        if !hourIntervals.contains(lastHour) {
            values.append(lastDate)
        }

        return values.sorted()
    }

    // MARK: - Week View (7 days)

    private func weekViewValues(calendar: Calendar, firstDate: Date, lastDate: Date) -> [Date] {
        var values: [Date] = []
        var currentDate = calendar.startOfDay(for: firstDate)
        let endDate = calendar.startOfDay(for: lastDate)

        while currentDate <= endDate {
            values.append(currentDate)
            if let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) {
                currentDate = nextDate
            } else {
                break
            }
        }

        return values
    }

    // MARK: - Month View (30-31 days)

    private func monthViewValues(calendar: Calendar, firstDate: Date, lastDate: Date, dates: [Date]) -> [Date] {
        let daysSpan = calendar.dateComponents([.day], from: firstDate, to: lastDate).day ?? 0

        // Calculate smart interval: every 3rd or 5th day depending on span
        let interval = daysSpan > 20 ? 5 : 3

        var values: [Date] = []
        var currentDate = calendar.startOfDay(for: firstDate)
        let endDate = calendar.startOfDay(for: lastDate)

        // Always include first day
        values.append(currentDate)

        // Add dates at intervals
        while currentDate < endDate {
            if let nextDate = calendar.date(byAdding: .day, value: interval, to: currentDate) {
                if nextDate <= endDate {
                    values.append(nextDate)
                }
                currentDate = nextDate
            } else {
                break
            }
        }

        // Always include last day
        if !calendar.isDate(values.last ?? firstDate, inSameDayAs: endDate) {
            values.append(endDate)
        }

        return values
    }

    // MARK: - Year View (12 months)

    private func yearViewValues(calendar: Calendar, firstDate: Date, lastDate: Date) -> [Date] {
        var values: [Date] = []
        var currentDate = calendar.date(from: calendar.dateComponents([.year, .month], from: firstDate)) ?? firstDate
        let endDate = calendar.date(from: calendar.dateComponents([.year, .month], from: lastDate)) ?? lastDate

        while currentDate <= endDate {
            values.append(currentDate)
            if let nextDate = calendar.date(byAdding: .month, value: 1, to: currentDate) {
                currentDate = nextDate
            } else {
                break
            }
        }

        return values
    }

    // MARK: - Label Formatting

    func formatLabel(for date: Date) -> String {
        let calendar = Calendar.current

        switch timeRange {
        case .day:
            return formatDayLabel(date: date, calendar: calendar)
        case .week:
            return formatWeekLabel(date: date, calendar: calendar)
        case .month:
            return formatMonthLabel(date: date, calendar: calendar)
        case .year:
            return formatYearLabel(date: date, calendar: calendar)
        }
    }

    private func formatDayLabel(date: Date, calendar: Calendar) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let formatted = formatter.string(from: date)
        // Ensure proper spacing: "6 AM" not "6AM"
        return formatted.replacingOccurrences(of: "AM", with: " AM").replacingOccurrences(of: "PM", with: " PM")
    }

    private func formatWeekLabel(date: Date, calendar: Calendar) -> String {
        // Single letter weekday: M T W T F S S
        let weekday = calendar.component(.weekday, from: date)
        let weekdaySymbols = ["S", "M", "T", "W", "T", "F", "S"] // Sunday = 1, Monday = 2, etc.
        return weekdaySymbols[weekday - 1]
    }

    private func formatMonthLabel(date: Date, calendar: Calendar) -> String {
        // Just the day number
        let day = calendar.component(.day, from: date)
        return "\(day)"
    }

    private func formatYearLabel(date: Date, calendar: Calendar) -> String {
        // First 3 letters of month: Jan, Feb, Mar, etc.
        let month = calendar.component(.month, from: date)
        let monthSymbols = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        return monthSymbols[month - 1]
    }

    // MARK: - Quarter Calculation (for Year View)

    func quarter(for date: Date) -> Int? {
        guard timeRange == .year else { return nil }
        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)
        return (month - 1) / 3 + 1
    }

    func quarterBoundaryDates() -> [Date] {
        guard timeRange == .year else { return [] }
        guard !dataPoints.isEmpty else { return [] }

        let dates = dataPoints.map { $0.date }.sorted()
        guard let firstDate = dates.first, let lastDate = dates.last else { return [] }

        let calendar = Calendar.current
        var boundaries: [Date] = []

        // Find quarter boundaries within the date range
        let startYear = calendar.component(.year, from: firstDate)
        let endYear = calendar.component(.year, from: lastDate)

        for year in startYear...endYear {
            for quarter in 1...4 {
                let month = (quarter - 1) * 3 + 1
                if let date = calendar.date(from: DateComponents(year: year, month: month, day: 1)) {
                    if date >= firstDate && date <= lastDate {
                        boundaries.append(date)
                    }
                }
            }
        }

        return boundaries
    }
}

