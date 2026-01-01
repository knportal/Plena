//
//  DataExportService.swift
//  PlenaShared
//
//  Service for exporting meditation session data to CSV format
//

import Foundation

enum ExportError: Error, LocalizedError {
    case noSessionsToExport
    case fileCreationFailed
    case encodingFailed

    var errorDescription: String? {
        switch self {
        case .noSessionsToExport:
            return "No sessions available to export"
        case .fileCreationFailed:
            return "Failed to create export file"
        case .encodingFailed:
            return "Failed to encode data for export"
        }
    }
}

enum ExportFormat {
    case sessionSummary
    case detailedWithSamples
}

class DataExportService {
    private let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private let displayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter
    }()

    // MARK: - Public Export Methods

    /// Export sessions as CSV with summary data only
    func exportSessionSummary(sessions: [MeditationSession]) throws -> URL {
        guard !sessions.isEmpty else {
            throw ExportError.noSessionsToExport
        }

        let csvContent = try generateSessionSummaryCSV(sessions: sessions)
        return try writeToFile(content: csvContent, filename: "plena_sessions_summary.csv")
    }

    /// Export sessions with all detailed sensor samples
    func exportDetailedData(sessions: [MeditationSession]) throws -> URL {
        guard !sessions.isEmpty else {
            throw ExportError.noSessionsToExport
        }

        let csvContent = try generateDetailedCSV(sessions: sessions)
        return try writeToFile(content: csvContent, filename: "plena_sessions_detailed.csv")
    }

    // MARK: - CSV Generation

    private func generateSessionSummaryCSV(sessions: [MeditationSession]) throws -> String {
        var csv = "Session ID,Start Date,End Date,Duration (min),Heart Rate Samples,HRV Samples,Respiratory Rate Samples,Temperature Samples,VO2 Max Samples,Avg Heart Rate,Avg HRV,Avg Respiratory Rate,Avg Temperature,Device Type\n"

        let sortedSessions = sessions.sorted { $0.startDate > $1.startDate }

        for session in sortedSessions {
            let duration = session.duration / 60.0
            let avgHR = session.heartRateSamples.isEmpty ? "" : String(format: "%.1f", session.heartRateSamples.map(\.value).reduce(0, +) / Double(session.heartRateSamples.count))
            let avgHRV = session.hrvSamples.isEmpty ? "" : String(format: "%.1f", session.hrvSamples.map(\.sdnn).reduce(0, +) / Double(session.hrvSamples.count))
            let avgResp = session.respiratoryRateSamples.isEmpty ? "" : String(format: "%.1f", session.respiratoryRateSamples.map(\.value).reduce(0, +) / Double(session.respiratoryRateSamples.count))
            let avgTemp = session.temperatureSamples.isEmpty ? "" : String(format: "%.2f", session.temperatureSamples.map(\.value).reduce(0, +) / Double(session.temperatureSamples.count))
            let deviceType = session.metadata?.deviceType ?? "unknown"

            let row = [
                session.id.uuidString,
                dateFormatter.string(from: session.startDate),
                session.endDate.map { dateFormatter.string(from: $0) } ?? "",
                String(format: "%.2f", duration),
                String(session.heartRateSamples.count),
                String(session.hrvSamples.count),
                String(session.respiratoryRateSamples.count),
                String(session.temperatureSamples.count),
                String(session.vo2MaxSamples.count),
                avgHR,
                avgHRV,
                avgResp,
                avgTemp,
                deviceType
            ]

            csv += row.joined(separator: ",") + "\n"
        }

        return csv
    }

    private func generateDetailedCSV(sessions: [MeditationSession]) throws -> String {
        var csv = "Session ID,Session Start,Sample Type,Sample Timestamp,Value,Unit\n"

        let sortedSessions = sessions.sorted { $0.startDate > $1.startDate }

        for session in sortedSessions {
            let sessionID = session.id.uuidString
            let sessionStart = dateFormatter.string(from: session.startDate)

            // Heart Rate samples
            for sample in session.heartRateSamples.sorted(by: { $0.timestamp < $1.timestamp }) {
                let row = [
                    sessionID,
                    sessionStart,
                    "Heart Rate",
                    dateFormatter.string(from: sample.timestamp),
                    String(format: "%.1f", sample.value),
                    "BPM"
                ]
                csv += row.joined(separator: ",") + "\n"
            }

            // HRV samples
            for sample in session.hrvSamples.sorted(by: { $0.timestamp < $1.timestamp }) {
                let row = [
                    sessionID,
                    sessionStart,
                    "HRV (SDNN)",
                    dateFormatter.string(from: sample.timestamp),
                    String(format: "%.1f", sample.sdnn),
                    "ms"
                ]
                csv += row.joined(separator: ",") + "\n"
            }

            // Respiratory Rate samples
            for sample in session.respiratoryRateSamples.sorted(by: { $0.timestamp < $1.timestamp }) {
                let row = [
                    sessionID,
                    sessionStart,
                    "Respiratory Rate",
                    dateFormatter.string(from: sample.timestamp),
                    String(format: "%.1f", sample.value),
                    "breaths/min"
                ]
                csv += row.joined(separator: ",") + "\n"
            }

            // Temperature samples
            for sample in session.temperatureSamples.sorted(by: { $0.timestamp < $1.timestamp }) {
                let row = [
                    sessionID,
                    sessionStart,
                    "Temperature",
                    dateFormatter.string(from: sample.timestamp),
                    String(format: "%.2f", sample.value),
                    "°C"
                ]
                csv += row.joined(separator: ",") + "\n"
            }

            // VO2 Max samples
            for sample in session.vo2MaxSamples.sorted(by: { $0.timestamp < $1.timestamp }) {
                let row = [
                    sessionID,
                    sessionStart,
                    "VO2 Max",
                    dateFormatter.string(from: sample.timestamp),
                    String(format: "%.2f", sample.value),
                    "ml/kg/min"
                ]
                csv += row.joined(separator: ",") + "\n"
            }
        }

        return csv
    }

    // MARK: - File Writing

    private func writeToFile(content: String, filename: String) throws -> URL {
        guard let data = content.data(using: .utf8) else {
            throw ExportError.encodingFailed
        }

        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(filename)

        do {
            try data.write(to: fileURL, options: .atomic)
            return fileURL
        } catch {
            throw ExportError.fileCreationFailed
        }
    }
}

