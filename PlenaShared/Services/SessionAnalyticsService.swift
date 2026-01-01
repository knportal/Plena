//
//  SessionAnalyticsService.swift
//  PlenaShared
//
//  Service for analyzing HRV data collection statistics
//

import Foundation
import CoreData

struct HRVAnalytics {
    let totalSessions: Int
    let sessionsWithHRV: Int
    let sessionsWithoutHRV: Int
    let hrvAvailabilityRate: Double
    let avgHRVSamplesPerSession: Double
    let avgDurationWithHRV: TimeInterval
    let avgDurationWithoutHRV: TimeInterval

    // Breakdown by device
    let watchSessions: Int
    let watchSessionsWithHRV: Int
    let iPhoneSessions: Int
    let iPhoneSessionsWithHRV: Int

    // Watch model breakdown
    let hrvByWatchModel: [String: Double]

    var summaryDescription: String {
        """
        📊 HRV Analytics Summary

        Overall:
        • Total sessions: \(totalSessions)
        • HRV availability: \(String(format: "%.1f%%", hrvAvailabilityRate * 100))
        • Sessions with HRV: \(sessionsWithHRV)
        • Sessions without HRV: \(sessionsWithoutHRV)
        • Avg samples/session: \(String(format: "%.1f", avgHRVSamplesPerSession))

        Duration:
        • Avg with HRV: \(formatDuration(avgDurationWithHRV))
        • Avg without HRV: \(formatDuration(avgDurationWithoutHRV))

        Device Breakdown:
        • Watch: \(watchSessionsWithHRV)/\(watchSessions) (\(watchSessions > 0 ? String(format: "%.1f%%", Double(watchSessionsWithHRV)/Double(watchSessions) * 100) : "N/A"))
        • iPhone: \(iPhoneSessionsWithHRV)/\(iPhoneSessions) (\(iPhoneSessions > 0 ? String(format: "%.1f%%", Double(iPhoneSessionsWithHRV)/Double(iPhoneSessions) * 100) : "N/A"))
        """
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds / 60)
        let secs = Int(seconds.truncatingRemainder(dividingBy: 60))
        return "\(mins)m \(secs)s"
    }
}

class SessionAnalyticsService {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext = CoreDataStack.shared.mainContext) {
        self.context = context
    }

    /// Fetch HRV analytics for all completed sessions
    func fetchHRVAnalytics() throws -> HRVAnalytics {
        let fetchRequest: NSFetchRequest<MeditationSessionEntity> = MeditationSessionEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "endDate != nil")

        let sessions = try context.fetch(fetchRequest)

        let totalSessions = sessions.count
        let sessionsWithHRV = sessions.filter { $0.hrvDataAvailable }.count
        let sessionsWithoutHRV = totalSessions - sessionsWithHRV
        let hrvAvailabilityRate = totalSessions > 0 ? Double(sessionsWithHRV) / Double(totalSessions) : 0

        let totalHRVSamples = sessions.reduce(0) { $0 + Int($1.hrvSampleCount) }
        let avgHRVSamplesPerSession = totalSessions > 0 ? Double(totalHRVSamples) / Double(totalSessions) : 0

        let withHRVSessions = sessions.filter { $0.hrvDataAvailable }
        let withoutHRVSessions = sessions.filter { !$0.hrvDataAvailable }

        let avgDurationWithHRV = withHRVSessions.isEmpty ? 0 :
            withHRVSessions.reduce(0.0) { $0 + Double($1.durationSeconds) } / Double(withHRVSessions.count)
        let avgDurationWithoutHRV = withoutHRVSessions.isEmpty ? 0 :
            withoutHRVSessions.reduce(0.0) { $0 + Double($1.durationSeconds) } / Double(withoutHRVSessions.count)

        // Device breakdown
        let watchSessions = sessions.filter { $0.deviceType == "watch" }
        let watchSessionsWithHRV = watchSessions.filter { $0.hrvDataAvailable }.count
        let iPhoneSessions = sessions.filter { $0.deviceType == "iphone" }
        let iPhoneSessionsWithHRV = iPhoneSessions.filter { $0.hrvDataAvailable }.count

        // Watch model breakdown
        var hrvByModel: [String: (total: Int, withHRV: Int)] = [:]
        for session in watchSessions {
            guard let model = session.watchModel else { continue }
            let current = hrvByModel[model, default: (0, 0)]
            hrvByModel[model] = (current.total + 1, current.withHRV + (session.hrvDataAvailable ? 1 : 0))
        }
        let hrvByWatchModel = hrvByModel.mapValues { data -> Double in
            data.total > 0 ? Double(data.withHRV) / Double(data.total) : 0
        }

        return HRVAnalytics(
            totalSessions: totalSessions,
            sessionsWithHRV: sessionsWithHRV,
            sessionsWithoutHRV: sessionsWithoutHRV,
            hrvAvailabilityRate: hrvAvailabilityRate,
            avgHRVSamplesPerSession: avgHRVSamplesPerSession,
            avgDurationWithHRV: avgDurationWithHRV,
            avgDurationWithoutHRV: avgDurationWithoutHRV,
            watchSessions: watchSessions.count,
            watchSessionsWithHRV: watchSessionsWithHRV,
            iPhoneSessions: iPhoneSessions.count,
            iPhoneSessionsWithHRV: iPhoneSessionsWithHRV,
            hrvByWatchModel: hrvByWatchModel
        )
    }

    /// Print analytics to console for debugging
    func printAnalytics() {
        do {
            let analytics = try fetchHRVAnalytics()
            print(analytics.summaryDescription)
        } catch {
            print("⚠️ Failed to fetch analytics: \(error)")
        }
    }
}

