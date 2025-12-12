//
//  TestDataView.swift
//  Plena
//
//  Debug view for generating test meditation session data
//  Note: This should be removed or hidden in production builds
//

import SwiftUI

struct TestDataView: View {
    @State private var isGenerating = false
    @State private var generationStatus: String?
    @State private var sessionCount = 0
    @State private var showAlert = false
    @State private var alertMessage = ""

    private let storageService = CoreDataStorageService()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Generate realistic test meditation sessions to see the dashboard in action.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } header: {
                    Text("About")
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Current Sessions")
                            .font(.headline)

                        Text("\(sessionCount) sessions in database")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Database")
                }

                Section {
                    Button(action: generateTestData) {
                        HStack {
                            if isGenerating {
                                ProgressView()
                                    .padding(.trailing, 8)
                            }
                            Text(isGenerating ? "Generating..." : "Generate Test Data")
                        }
                    }
                    .disabled(isGenerating)

                    Button(action: generateHRVTestData) {
                        HStack {
                            if isGenerating {
                                ProgressView()
                                    .padding(.trailing, 8)
                            }
                            Text(isGenerating ? "Generating..." : "Generate HRV Insights Test Data")
                        }
                    }
                    .disabled(isGenerating)
                    .buttonStyle(.borderedProminent)

                    if let status = generationStatus {
                        Text(status)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Button(action: clearAllData) {
                        Text("Clear All Sessions")
                            .foregroundColor(Color("WarningColor"))
                    }
                    .disabled(isGenerating || sessionCount == 0)
                } header: {
                    Text("Actions")
                } footer: {
                    Text("Regular test data includes sessions from the past 30 days. HRV Insights test data is specifically designed to show HRV trend insights (guarantees 3+ sessions per week with HRV data).")
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Test Data Includes:")
                            .font(.headline)

                        VStack(alignment: .leading, spacing: 4) {
                            Label("~30 sessions over past month", systemImage: "calendar")
                            Label("Varied durations (10-30 minutes)", systemImage: "clock")
                            Label("Different times of day", systemImage: "sun.max")
                            Label("Heart rate, HRV, respiratory data", systemImage: "heart.text.square")
                            Label("More recent = more frequent", systemImage: "chart.line.uptrend.xyaxis")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                } header: {
                    Text("What's Generated")
                }
            }
            .navigationTitle("Test Data")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Success", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .task {
                loadSessionCount()
            }
        }
    }

    private func loadSessionCount() {
        do {
            let sessions = try storageService.loadAllSessions()
            sessionCount = sessions.count
        } catch {
            print("Error loading session count: \(error)")
        }
    }

    private func generateTestData() {
        isGenerating = true
        generationStatus = "Creating realistic test sessions..."

        Task {
            do {
                // Generate test data
                let testSessions = TestDataGenerator.generateRealisticTestData(includeSensorData: true)

                // Save to storage
                for session in testSessions {
                    try storageService.saveSession(session)
                }

                await MainActor.run {
                    sessionCount += testSessions.count
                    generationStatus = "✅ Generated \(testSessions.count) test sessions!"
                    isGenerating = false
                    alertMessage = "Successfully generated \(testSessions.count) meditation sessions with realistic data. Check the Dashboard tab to see them!"
                    showAlert = true
                }
            } catch {
                await MainActor.run {
                    generationStatus = "❌ Error: \(error.localizedDescription)"
                    isGenerating = false
                    alertMessage = "Failed to generate test data: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
    }

    private func generateHRVTestData() {
        isGenerating = true
        generationStatus = "Creating HRV insights test data..."

        Task {
            do {
                // Generate HRV-specific test data
                let testSessions = TestDataGenerator.generateHRVInsightsTestData()

                // Save to storage
                for session in testSessions {
                    try storageService.saveSession(session)
                }

                await MainActor.run {
                    sessionCount += testSessions.count
                    generationStatus = "✅ Generated \(testSessions.count) HRV test sessions!"
                    isGenerating = false
                    alertMessage = "Successfully generated \(testSessions.count) meditation sessions with HRV data designed to show insights. Check the Dashboard tab to see HRV trend insights!"
                    showAlert = true
                }
            } catch {
                await MainActor.run {
                    generationStatus = "❌ Error: \(error.localizedDescription)"
                    isGenerating = false
                    alertMessage = "Failed to generate HRV test data: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
    }

    private func clearAllData() {
        do {
            let allSessions = try storageService.loadAllSessions()
            for session in allSessions {
                try storageService.deleteSession(session)
            }
            sessionCount = 0
            generationStatus = "All sessions cleared"
            alertMessage = "All sessions have been deleted."
            showAlert = true
        } catch {
            alertMessage = "Error clearing data: \(error.localizedDescription)"
            showAlert = true
        }
    }
}

#Preview {
    TestDataView()
}


