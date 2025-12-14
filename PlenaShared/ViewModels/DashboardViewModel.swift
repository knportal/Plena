//
//  DashboardViewModel.swift
//  PlenaShared
//
//  ViewModel for dashboard statistics and trend tracking
//

import Foundation
import Combine
import CoreData

// Represents a time period comparison
struct PeriodComparison {
    let current: Double
    let previous: Double
    var change: Double {
        current - previous
    }
    var percentChange: Double {
        guard previous > 0 else { return 0 }
        return (change / previous) * 100
    }

    var trend: Trend {
        if abs(percentChange) < 2.0 {
            return .stable
        }
        return change > 0 ? .improving : .declining
    }
}

// Time of day distribution
enum TimeOfDay: String, CaseIterable {
    case morning = "Morning"
    case afternoon = "Afternoon"
    case evening = "Evening"
    case night = "Night"

    static func from(date: Date) -> TimeOfDay {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 6..<12:
            return .morning
        case 12..<18:
            return .afternoon
        case 18..<22:
            return .evening
        default:
            return .night
        }
    }
}

// Session frequency data point for charts
struct SessionFrequencyDataPoint {
    let period: String
    let date: Date
    let count: Int
}

// Timeline session data point for day view
struct TimelineSessionDataPoint {
    let sessionId: UUID
    let startTime: Date
    let endTime: Date
    let duration: TimeInterval // in seconds

    var durationMinutes: Double {
        duration / 60.0
    }
}

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var sessions: [MeditationSession] = []
    @Published var selectedTimeRange: TimeRange = .month
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let storageService: SessionStorageServiceProtocol
    private let healthKitService: HealthKitServiceProtocol?
    private var remoteChangeObserver: NSObjectProtocol?

    init(
        storageService: SessionStorageServiceProtocol = CoreDataStorageService(),
        healthKitService: HealthKitServiceProtocol? = nil
    ) {
        self.storageService = storageService
        self.healthKitService = healthKitService

        // Listen for remote Core Data changes (CloudKit sync)
        setupRemoteChangeObserver()
    }

    deinit {
        if let observer = remoteChangeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    private func setupRemoteChangeObserver() {
        // Listen for Core Data store changes (from Watch or iPhone)
        // This works for both App Group shared container and CloudKit sync
        remoteChangeObserver = NotificationCenter.default.addObserver(
            forName: .NSPersistentStoreRemoteChange,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            print("🔄 Dashboard: Detected Core Data store change, refreshing sessions...")
            // Refresh the context to see changes from Watch
            CoreDataStack.shared.mainContext.refreshAllObjects()

            // Reload sessions when changes are detected from the shared container
            Task { @MainActor [weak self] in
                await self?.loadSessions()
            }
        }

        // Listen for ANY context saves (not just main context) to catch Watch saves
        NotificationCenter.default.addObserver(
            forName: .NSManagedObjectContextDidSave,
            object: nil, // nil = listen to ALL contexts
            queue: .main
        ) { [weak self] notification in
            // Only refresh if it's not from our own main context to avoid double refresh
            if let savedContext = notification.object as? NSManagedObjectContext,
               savedContext !== CoreDataStack.shared.mainContext {
                print("🔄 Dashboard: Detected save from other context (Watch?), refreshing...")
                // Refresh to see changes from Watch
                CoreDataStack.shared.mainContext.refreshAllObjects()

                Task { @MainActor [weak self] in
                    await self?.loadSessions()
                }
            }
        }
    }

    // MARK: - Data Loading

    func loadSessions() async {
        isLoading = true
        errorMessage = nil

        do {
            let (startDate, endDate) = selectedTimeRange.dateRange
            // Use lightweight loading without samples to save memory - dashboard only needs dates and durations
            sessions = try storageService.loadSessionsWithoutSamples(startDate: startDate, endDate: endDate)
            print("📊 Dashboard: Loaded \(sessions.count) sessions for time range \(selectedTimeRange)")
        } catch {
            errorMessage = "Failed to load sessions: \(error.localizedDescription)"
            print("❌ Dashboard: Error loading sessions: \(error)")
        }

        isLoading = false
    }

    func reloadForTimeRange() async {
        await loadSessions()
    }

    // MARK: - Primary Statistics

    /// Total number of sessions in selected time range
    var sessionCount: Int {
        sessions.count
    }

    /// Total meditation time in minutes
    var totalMinutes: Double {
        sessions.reduce(0.0) { $0 + $1.duration / 60.0 }
    }

    /// Total meditation time in hours (formatted)
    var totalHoursFormatted: String {
        let hours = totalMinutes / 60.0
        if hours >= 1.0 {
            return String(format: "%.1f hrs", hours)
        }
        return String(format: "%.0f min", totalMinutes)
    }

    /// Average session duration in minutes
    var averageDuration: Double? {
        guard !sessions.isEmpty else { return nil }
        return totalMinutes / Double(sessions.count)
    }

    /// Average duration formatted (e.g., "18 min")
    var averageDurationFormatted: String? {
        guard let avg = averageDuration else { return nil }
        return String(format: "%.0f min", avg)
    }

    /// Current streak of consecutive days with at least one session
    var currentStreak: Int {
        guard !sessions.isEmpty else { return 0 }

        let calendar = Calendar.current
        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())

        // Sort sessions by date (newest first)
        let sortedSessions = sessions.sorted { $0.startDate > $1.startDate }

        // Count backwards from today
        while true {
            // Check if there's a session on this date
            let hasSession = sortedSessions.contains { session in
                calendar.isDate(session.startDate, inSameDayAs: currentDate)
            }

            if hasSession {
                streak += 1
                // Move to previous day
                guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else {
                    break
                }
                currentDate = previousDay
            } else {
                // If today has no session, don't count it
                if streak == 0 {
                    // Check yesterday
                    guard let yesterday = calendar.date(byAdding: .day, value: -1, to: currentDate) else {
                        break
                    }
                    currentDate = yesterday
                    continue
                }
                // Streak broken
                break
            }
        }

        return streak
    }

    /// Sessions in current week
    var sessionsThisWeek: Int {
        let calendar = Calendar.current
        let now = Date()
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) else {
            return 0
        }

        return sessions.filter { session in
            session.startDate >= weekStart && session.startDate <= now
        }.count
    }

    // MARK: - Comparison Statistics

    /// Compare current period to previous period
    func compareToPrevious() -> PeriodComparison? {
        let (currentStart, currentEnd) = selectedTimeRange.dateRange
        let duration = currentEnd.timeIntervalSince(currentStart)

        // Calculate previous period dates
        let previousEnd = currentStart
        let previousStart = previousEnd.addingTimeInterval(-duration)

        // Load previous period sessions (without samples - only need counts and durations)
        let previousSessions = (try? storageService.loadSessionsWithoutSamples(startDate: previousStart, endDate: previousEnd)) ?? []

        let currentCount = Double(sessionCount)
        let previousCount = Double(previousSessions.count)

        guard previousCount > 0 || currentCount > 0 else { return nil }

        return PeriodComparison(current: currentCount, previous: previousCount)
    }

    /// Compare total minutes to previous period
    func compareTotalMinutes() -> PeriodComparison? {
        let (currentStart, currentEnd) = selectedTimeRange.dateRange
        let duration = currentEnd.timeIntervalSince(currentStart)

        let previousEnd = currentStart
        let previousStart = previousEnd.addingTimeInterval(-duration)

        // Load previous period sessions (without samples - only need durations)
        let previousSessions = (try? storageService.loadSessionsWithoutSamples(startDate: previousStart, endDate: previousEnd)) ?? []
        let previousMinutes = previousSessions.reduce(0.0) { $0 + $1.duration / 60.0 }

        return PeriodComparison(current: totalMinutes, previous: previousMinutes)
    }

    // MARK: - Advanced Statistics

    /// Longest session duration in minutes
    var longestSession: (duration: Double, date: Date)? {
        guard let longest = sessions.max(by: { $0.duration < $1.duration }) else {
            return nil
        }
        return (longest.duration / 60.0, longest.startDate)
    }

    /// Shortest session duration in minutes
    var shortestSession: (duration: Double, date: Date)? {
        guard let shortest = sessions.min(by: { $0.duration < $1.duration }) else {
            return nil
        }
        return (shortest.duration / 60.0, shortest.startDate)
    }

    /// Median session duration in minutes
    var medianDuration: Double? {
        guard !sessions.isEmpty else { return nil }
        let sorted = sessions.sorted { $0.duration < $1.duration }
        let middle = sorted.count / 2
        if sorted.count % 2 == 0 {
            return (sorted[middle - 1].duration + sorted[middle].duration) / 120.0 // Divide by 60 twice
        }
        return sorted[middle].duration / 60.0
    }

    /// Sessions per week (average)
    var sessionsPerWeek: Double? {
        let (startDate, endDate) = selectedTimeRange.dateRange
        let days = endDate.timeIntervalSince(startDate) / 86400.0
        guard days > 0 else { return nil }

        let weeks = days / 7.0
        guard weeks > 0 else { return nil }

        return Double(sessionCount) / weeks
    }

    // MARK: - Time Distribution

    /// Distribution of sessions by time of day
    func timeOfDayDistribution() -> [TimeOfDay: Int] {
        var distribution: [TimeOfDay: Int] = [:]
        TimeOfDay.allCases.forEach { distribution[$0] = 0 }

        sessions.forEach { session in
            let timeOfDay = TimeOfDay.from(date: session.startDate)
            distribution[timeOfDay, default: 0] += 1
        }

        return distribution
    }

    /// Most common time of day for sessions
    var bestTimeOfDay: (time: TimeOfDay, percentage: Double)? {
        let distribution = timeOfDayDistribution()
        guard let maxEntry = distribution.max(by: { $0.value < $1.value }),
              maxEntry.value > 0,
              sessionCount > 0 else {
            return nil
        }

        let percentage = (Double(maxEntry.value) / Double(sessionCount)) * 100.0
        return (maxEntry.key, percentage)
    }

    /// Sessions per day of week
    func weeklyPattern() -> [Int: Int] {
        let calendar = Calendar.current
        var pattern: [Int: Int] = [:]

        // Initialize all days (1 = Sunday, 2 = Monday, ..., 7 = Saturday)
        for day in 1...7 {
            pattern[day] = 0
        }

        sessions.forEach { session in
            let weekday = calendar.component(.weekday, from: session.startDate)
            pattern[weekday, default: 0] += 1
        }

        return pattern
    }

    // MARK: - Chart Data

    /// Session frequency data points for bar chart
    func sessionFrequencyDataPoints() -> [SessionFrequencyDataPoint] {
        let calendar = Calendar.current
        let (startDate, endDate) = selectedTimeRange.dateRange

        var dataPoints: [SessionFrequencyDataPoint] = []

        switch selectedTimeRange {
        case .day:
            // Group by hour - only show hours that have sessions
            // First, collect all hours that have sessions
            var hoursWithSessions: Set<Int> = []
            for session in sessions {
                let hour = calendar.component(.hour, from: session.startDate)
                hoursWithSessions.insert(hour)
            }

            // Only create data points for hours with sessions
            for hour in hoursWithSessions.sorted() {
                guard let date = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: startDate) else { continue }
                let count = sessions.filter { session in
                    calendar.component(.hour, from: session.startDate) == hour
                }.count

                // Only add if count > 0 (should always be true, but safety check)
                guard count > 0 else { continue }

                let formatter = DateFormatter()
                formatter.dateFormat = "ha"
                dataPoints.append(SessionFrequencyDataPoint(
                    period: formatter.string(from: date),
                    date: date,
                    count: count
                ))
            }

        case .week:
            // Group by day
            var currentDate = calendar.startOfDay(for: startDate)
            while currentDate <= endDate {
                let count = sessions.filter { session in
                    calendar.isDate(session.startDate, inSameDayAs: currentDate)
                }.count

                let formatter = DateFormatter()
                formatter.dateFormat = "E" // Day abbreviation
                dataPoints.append(SessionFrequencyDataPoint(
                    period: formatter.string(from: currentDate),
                    date: currentDate,
                    count: count
                ))

                guard let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
                currentDate = nextDay
            }

        case .month:
            // Group by day
            var currentDate = calendar.startOfDay(for: startDate)
            while currentDate <= endDate {
                let count = sessions.filter { session in
                    calendar.isDate(session.startDate, inSameDayAs: currentDate)
                }.count

                let formatter = DateFormatter()
                formatter.dateFormat = "MMM d"
                dataPoints.append(SessionFrequencyDataPoint(
                    period: formatter.string(from: currentDate),
                    date: currentDate,
                    count: count
                ))

                guard let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
                currentDate = nextDay
            }

        case .year:
            // Group by month
            var currentDate = calendar.startOfDay(for: startDate)
            while currentDate <= endDate {
                // Get the first day of the current month
                let year = calendar.component(.year, from: currentDate)
                let month = calendar.component(.month, from: currentDate)
                guard let monthStart = calendar.date(from: DateComponents(year: year, month: month, day: 1)) else { break }

                // Get the first day of the next month
                guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: monthStart) else { break }

                // Count all sessions in this month
                let count = sessions.filter { session in
                    session.startDate >= monthStart && session.startDate < nextMonth
                }.count

                let formatter = DateFormatter()
                formatter.dateFormat = "MMM"
                dataPoints.append(SessionFrequencyDataPoint(
                    period: formatter.string(from: monthStart),
                    date: monthStart,
                    count: count
                ))

                currentDate = nextMonth
            }
        }

        return dataPoints
    }

    /// Average duration trend data points for line chart
    func durationTrendDataPoints() -> [(date: Date, duration: Double)] {
        let calendar = Calendar.current
        let (startDate, endDate) = selectedTimeRange.dateRange

        var dataPoints: [(date: Date, duration: Double)] = []

        switch selectedTimeRange {
        case .day:
            // Group by hour - only show up to current hour if viewing today
            let now = Date()
            let isToday = calendar.isDate(startDate, inSameDayAs: now)
            let maxHour = isToday ? calendar.component(.hour, from: now) + 1 : 24

            for hour in 0..<maxHour {
                guard let date = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: startDate) else { continue }
                let hourSessions = sessions.filter { session in
                    calendar.component(.hour, from: session.startDate) == hour
                }

                guard !hourSessions.isEmpty else { continue }
                let avgDuration = hourSessions.reduce(0.0) { $0 + $1.duration } / Double(hourSessions.count) / 60.0
                dataPoints.append((date: date, duration: avgDuration))
            }

        case .week, .month:
            // Group by day
            var currentDate = calendar.startOfDay(for: startDate)
            while currentDate <= endDate {
                let daySessions = sessions.filter { session in
                    calendar.isDate(session.startDate, inSameDayAs: currentDate)
                }

                if !daySessions.isEmpty {
                    let avgDuration = daySessions.reduce(0.0) { $0 + $1.duration } / Double(daySessions.count) / 60.0
                    dataPoints.append((date: currentDate, duration: avgDuration))
                }

                guard let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
                currentDate = nextDay
            }

        case .year:
            // Group by month
            var currentDate = calendar.startOfDay(for: startDate)
            while currentDate <= endDate {
                // Get the first day of the current month
                let year = calendar.component(.year, from: currentDate)
                let month = calendar.component(.month, from: currentDate)
                guard let monthStart = calendar.date(from: DateComponents(year: year, month: month, day: 1)) else { break }

                // Get the first day of the next month
                guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: monthStart) else { break }

                // Get all sessions in this month
                let monthSessions = sessions.filter { session in
                    session.startDate >= monthStart && session.startDate < nextMonth
                }

                if !monthSessions.isEmpty {
                    // Calculate average duration for the month
                    let avgDuration = monthSessions.reduce(0.0) { $0 + $1.duration } / Double(monthSessions.count) / 60.0
                    dataPoints.append((date: monthStart, duration: avgDuration))
                }

                currentDate = nextMonth
            }
        }

        return dataPoints.sorted { $0.date < $1.date }
    }

    /// Timeline session data points for day view - shows individual sessions as blocks
    func timelineSessionDataPoints() -> [TimelineSessionDataPoint] {
        guard selectedTimeRange == .day else { return [] }

        let (startDate, endDate) = selectedTimeRange.dateRange

        // Filter sessions to only those in the selected day
        let daySessions = sessions.filter { session in
            session.startDate >= startDate && session.startDate < endDate
        }

        return daySessions.map { session in
            TimelineSessionDataPoint(
                sessionId: session.id,
                startTime: session.startDate,
                endTime: session.endDate ?? Date(),
                duration: session.duration
            )
        }.sorted { $0.startTime < $1.startTime }
    }

    // MARK: - HRV Trend Insights

    /// Represents an HRV insight with message and trend
    struct HRVInsight {
        let message: String
        let trend: Trend
        let type: InsightType

        enum InsightType {
            case weeklyTrend
            case recentSessions
        }
    }

    /// Calculate average HRV for a session (average of all HRV samples in that session)
    private func averageHRVForSession(_ session: MeditationSession) -> Double? {
        guard !session.hrvSamples.isEmpty else { return nil }
        let sum = session.hrvSamples.reduce(0.0) { $0 + $1.sdnn }
        return sum / Double(session.hrvSamples.count)
    }

    /// Get sessions with valid HRV data (at least 3 samples)
    private func sessionsWithValidHRV(_ sessions: [MeditationSession]) -> [MeditationSession] {
        return sessions.filter { $0.hrvSamples.count >= 3 }
    }

    /// Calculate weekly HRV trend insight
    /// Compares current week's average HRV to previous week's average HRV
    func weeklyHRVTrend() -> HRVInsight? {
        let calendar = Calendar.current
        let now = Date()

        // Get current week start
        guard let currentWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) else {
            return nil
        }

        // Get previous week dates
        guard let previousWeekEnd = calendar.date(byAdding: .day, value: -1, to: currentWeekStart),
              let previousWeekStart = calendar.date(byAdding: .day, value: -7, to: previousWeekEnd) else {
            return nil
        }

        // Load all sessions for both weeks (need full sessions with samples for HRV analysis)
        let currentWeekSessions = (try? storageService.loadSessions(startDate: currentWeekStart, endDate: now)) ?? []
        let previousWeekSessions = (try? storageService.loadSessions(startDate: previousWeekStart, endDate: previousWeekEnd)) ?? []

        // Filter to sessions with valid HRV data
        let currentWeekValid = sessionsWithValidHRV(currentWeekSessions)
        let previousWeekValid = sessionsWithValidHRV(previousWeekSessions)

        // Need at least 3 sessions with HRV data in each week
        guard currentWeekValid.count >= 3, previousWeekValid.count >= 3 else {
            return nil
        }

        // Calculate average HRV for each week
        let currentWeekHRVs = currentWeekValid.compactMap { averageHRVForSession($0) }
        let previousWeekHRVs = previousWeekValid.compactMap { averageHRVForSession($0) }

        guard !currentWeekHRVs.isEmpty, !previousWeekHRVs.isEmpty else {
            return nil
        }

        let currentWeekAvg = currentWeekHRVs.reduce(0.0, +) / Double(currentWeekHRVs.count)
        let previousWeekAvg = previousWeekHRVs.reduce(0.0, +) / Double(previousWeekHRVs.count)

        // Calculate percentage change
        guard previousWeekAvg > 0 else { return nil }
        let percentChange = ((currentWeekAvg - previousWeekAvg) / previousWeekAvg) * 100

        // Only show if change is significant (>= 5%)
        guard abs(percentChange) >= 5.0 else {
            return nil
        }

        let trend: Trend = percentChange > 0 ? .improving : .declining
        let direction = percentChange > 0 ? "increased" : "decreased"
        let message = String(format: "HRV %@ %.0f%% this week", direction, abs(percentChange))

        return HRVInsight(message: message, trend: trend, type: .weeklyTrend)
    }

    /// Calculate recent sessions improvement insight
    /// Analyzes last 3-5 sessions for HRV improvement trend
    func recentSessionsHRVImprovement() -> HRVInsight? {
        // Get recent sessions sorted by date (newest first) - need full sessions with samples for HRV analysis
        // Limit to last 30 days to avoid loading too much data
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date.distantPast
        let allSessions = (try? storageService.loadSessions(startDate: thirtyDaysAgo, endDate: Date())) ?? []
        let sortedSessions = allSessions.sorted { $0.startDate > $1.startDate }

        // Filter to sessions with valid HRV data (at least 3 samples)
        let validSessions = sessionsWithValidHRV(sortedSessions)

        // Need at least 3 sessions
        guard validSessions.count >= 3 else {
            return nil
        }

        // Take last 3 sessions
        let recentSessions = Array(validSessions.prefix(3))

        // Calculate average HRV for each session (using end HRV - post-meditation state)
        let sessionHRVs = recentSessions.compactMap { session -> Double? in
            // Use average of last 3 HRV samples (end of session) or all if less than 3
            let samples = session.hrvSamples.sorted { $0.timestamp < $1.timestamp }
            let endSamples = Array(samples.suffix(min(3, samples.count)))
            guard !endSamples.isEmpty else { return nil }
            let sum = endSamples.reduce(0.0) { $0 + $1.sdnn }
            return sum / Double(endSamples.count)
        }

        guard sessionHRVs.count >= 3 else {
            return nil
        }

        // Sessions are sorted newest first, so reverse to chronological order
        // [0] = newest, [2] = oldest
        // We want to check if newest > oldest (improvement over time)
        let chronologicalHRVs = Array(sessionHRVs.reversed()) // Now [0] = oldest, [2] = newest

        let oldest = chronologicalHRVs[0]
        let newest = chronologicalHRVs[chronologicalHRVs.count - 1]

        // Check for improvement: newest session should be higher than oldest
        let improvement = newest - oldest
        guard improvement > 0 else {
            return nil
        }

        let percentImprovement = (improvement / oldest) * 100

        // Only show if there's meaningful improvement (>= 5%)
        guard percentImprovement >= 5.0 else {
            return nil
        }

        // Verify trend is consistent (not just one good session)
        // Check that values are generally increasing from oldest to newest
        let allIncreasing = zip(chronologicalHRVs, chronologicalHRVs.dropFirst()).allSatisfy { $0 <= $1 }
        guard allIncreasing else {
            return nil
        }

        return HRVInsight(
            message: "Your last 3 sessions show improved calm response",
            trend: .improving,
            type: .recentSessions
        )
    }

    /// Get all HRV insights
    func hrvInsights() -> [HRVInsight] {
        var insights: [HRVInsight] = []

        if let weeklyTrend = weeklyHRVTrend() {
            insights.append(weeklyTrend)
        }

        if let recentImprovement = recentSessionsHRVImprovement() {
            insights.append(recentImprovement)
        }

        return insights
    }
}

