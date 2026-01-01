//
//  TimeRange.swift
//  PlenaShared
//
//  Time range enum for data visualization
//

import Foundation

enum TimeRange: String, CaseIterable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
    case year = "Year"

    var dateRange: (start: Date, end: Date) {
        let end = Date()
        let calendar = Calendar.current

        switch self {
        case .day:
            let start = calendar.startOfDay(for: end)
            return (start, end)
        case .week:
            let start = calendar.date(byAdding: .day, value: -7, to: end) ?? end
            return (start, end)
        case .month:
            let start = calendar.date(byAdding: .month, value: -1, to: end) ?? end
            return (start, end)
        case .year:
            let start = calendar.date(byAdding: .year, value: -1, to: end) ?? end
            return (start, end)
        }
    }
}










