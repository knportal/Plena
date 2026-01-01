//
//  DataExportServiceTests.swift
//  Tests
//
//  Unit tests for DataExportService
//

import XCTest
@testable import PlenaShared

class DataExportServiceTests: XCTestCase {
    var exportService: DataExportService!

    override func setUp() {
        super.setUp()
        exportService = DataExportService()
    }

    override func tearDown() {
        exportService = nil
        super.tearDown()
    }

    // MARK: - Session Summary Export Tests

    func testExportSessionSummary_WithValidSessions_Success() throws {
        // Given
        let session1 = createMockSession(
            startDate: Date().addingTimeInterval(-7200), // 2 hours ago
            duration: 600, // 10 minutes
            heartRateSamples: 10,
            hrvSamples: 5
        )

        let session2 = createMockSession(
            startDate: Date().addingTimeInterval(-3600), // 1 hour ago
            duration: 900, // 15 minutes
            heartRateSamples: 15,
            hrvSamples: 8
        )

        let sessions = [session1, session2]

        // When
        let fileURL = try exportService.exportSessionSummary(sessions: sessions)

        // Then
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))

        let csvContent = try String(contentsOf: fileURL, encoding: .utf8)

        // Verify header
        XCTAssertTrue(csvContent.contains("Session ID"))
        XCTAssertTrue(csvContent.contains("Start Date"))
        XCTAssertTrue(csvContent.contains("Duration (min)"))
        XCTAssertTrue(csvContent.contains("Heart Rate Samples"))
        XCTAssertTrue(csvContent.contains("HRV Samples"))

        // Verify data rows
        let lines = csvContent.components(separatedBy: "\n")
        XCTAssertGreaterThanOrEqual(lines.count, 3) // Header + 2 sessions

        // Verify session IDs are present
        XCTAssertTrue(csvContent.contains(session1.id.uuidString))
        XCTAssertTrue(csvContent.contains(session2.id.uuidString))

        // Cleanup
        try? FileManager.default.removeItem(at: fileURL)
    }

    func testExportSessionSummary_WithEmptySessions_ThrowsError() {
        // Given
        let sessions: [MeditationSession] = []

        // When/Then
        XCTAssertThrowsError(try exportService.exportSessionSummary(sessions: sessions)) { error in
            XCTAssertTrue(error is ExportError)
            if let exportError = error as? ExportError {
                XCTAssertEqual(exportError, ExportError.noSessionsToExport)
            }
        }
    }

    // MARK: - Detailed Data Export Tests

    func testExportDetailedData_WithValidSessions_Success() throws {
        // Given
        let session = createMockSession(
            startDate: Date().addingTimeInterval(-3600),
            duration: 600,
            heartRateSamples: 5,
            hrvSamples: 3
        )

        let sessions = [session]

        // When
        let fileURL = try exportService.exportDetailedData(sessions: sessions)

        // Then
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))

        let csvContent = try String(contentsOf: fileURL, encoding: .utf8)

        // Verify header
        XCTAssertTrue(csvContent.contains("Session ID"))
        XCTAssertTrue(csvContent.contains("Sample Type"))
        XCTAssertTrue(csvContent.contains("Sample Timestamp"))
        XCTAssertTrue(csvContent.contains("Value"))
        XCTAssertTrue(csvContent.contains("Unit"))

        // Verify sample types
        XCTAssertTrue(csvContent.contains("Heart Rate"))
        XCTAssertTrue(csvContent.contains("HRV (SDNN)"))
        XCTAssertTrue(csvContent.contains("BPM"))
        XCTAssertTrue(csvContent.contains("ms"))

        // Verify correct number of samples (5 HR + 3 HRV = 8 data rows + 1 header)
        let lines = csvContent.components(separatedBy: "\n").filter { !$0.isEmpty }
        XCTAssertEqual(lines.count, 9) // 1 header + 8 samples

        // Cleanup
        try? FileManager.default.removeItem(at: fileURL)
    }

    func testExportDetailedData_WithEmptySessions_ThrowsError() {
        // Given
        let sessions: [MeditationSession] = []

        // When/Then
        XCTAssertThrowsError(try exportService.exportDetailedData(sessions: sessions)) { error in
            XCTAssertTrue(error is ExportError)
            if let exportError = error as? ExportError {
                XCTAssertEqual(exportError, ExportError.noSessionsToExport)
            }
        }
    }

    // MARK: - Helper Methods

    private func createMockSession(
        startDate: Date,
        duration: TimeInterval,
        heartRateSamples: Int,
        hrvSamples: Int
    ) -> MeditationSession {
        var session = MeditationSession(id: UUID(), startDate: startDate)
        session.endDate = startDate.addingTimeInterval(duration)

        // Add heart rate samples
        for i in 0..<heartRateSamples {
            let sample = HeartRateSample(
                timestamp: startDate.addingTimeInterval(Double(i) * 60),
                value: Double(60 + i)
            )
            session.heartRateSamples.append(sample)
        }

        // Add HRV samples
        for i in 0..<hrvSamples {
            let sample = HRVSample(
                timestamp: startDate.addingTimeInterval(Double(i) * 120),
                sdnn: Double(50 + i * 5)
            )
            session.hrvSamples.append(sample)
        }

        return session
    }
}

// Make ExportError equatable for testing
extension ExportError: Equatable {
    public static func == (lhs: ExportError, rhs: ExportError) -> Bool {
        switch (lhs, rhs) {
        case (.noSessionsToExport, .noSessionsToExport),
             (.fileCreationFailed, .fileCreationFailed),
             (.encodingFailed, .encodingFailed):
            return true
        default:
            return false
        }
    }
}

