# HealthKit Historical Data Import - Usage Guide

## Overview

The `HealthKitImportService` allows you to import historical health data from the Health app and create meditation sessions from it.

## Basic Usage

### 1. Import Heart Rate Data for a Date Range

```swift
let importService = HealthKitImportService()

let startDate = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
let endDate = Date()

importService.fetchHistoricalHeartRate(
    startDate: startDate,
    endDate: endDate
) { result in
    switch result {
    case .success(let samples):
        print("Imported \(samples.count) heart rate samples")
        // Process samples...

    case .failure(let error):
        print("Import failed: \(error)")
    }
}
```

### 2. Auto-Detect Meditation Sessions

```swift
importService.detectPotentialMeditationSessions(
    startDate: startDate,
    endDate: endDate,
    minimumDuration: 600 // 10 minutes
) { result in
    switch result {
    case .success(let dateRanges):
        print("Found \(dateRanges.count) potential meditation sessions")

        for range in dateRanges {
            print("Session: \(range.startDate) to \(range.endDate)")
            // Create MeditationSession from this range
        }

    case .failure(let error):
        print("Detection failed: \(error)")
    }
}
```

### 3. Complete Import Workflow

```swift
class MeditationImportViewModel: ObservableObject {
    @Published var isImporting = false
    @Published var importProgress: Double = 0.0
    @Published var importedSessions: [MeditationSession] = []

    private let importService = HealthKitImportService()
    private let storageService: SwiftDataStorageServiceProtocol

    func importHistoricalData(
        startDate: Date,
        endDate: Date
    ) async {
        await MainActor.run {
            isImporting = true
            importProgress = 0.0
        }

        // Step 1: Detect potential sessions
        await withCheckedContinuation { continuation in
            importService.detectPotentialMeditationSessions(
                startDate: startDate,
                endDate: endDate
            ) { [weak self] result in
                guard let self = self else { return }

                switch result {
                case .success(let dateRanges):
                    Task {
                        await self.importSessions(from: dateRanges)
                        continuation.resume()
                    }

                case .failure(let error):
                    print("Error: \(error)")
                    continuation.resume()
                }
            }
        }

        await MainActor.run {
            isImporting = false
        }
    }

    private func importSessions(from dateRanges: [DateRange]) async {
        let total = dateRanges.count

        for (index, range) in dateRanges.enumerated() {
            // Fetch all data for this session
            let (heartRate, hrv, respiratory) = await fetchAllData(for: range)

            // Create session
            var session = MeditationSession(startDate: range.startDate)
            session.endDate = range.endDate
            session.heartRateSamples = heartRate
            session.hrvSamples = hrv
            session.respiratoryRateSamples = respiratory

            // Save to SwiftData
            do {
                try storageService.saveSession(session)
                await MainActor.run {
                    importedSessions.append(session)
                    importProgress = Double(index + 1) / Double(total)
                }
            } catch {
                print("Failed to save session: \(error)")
            }
        }
    }

    private func fetchAllData(for range: DateRange) async -> (
        [HeartRateSample],
        [HRVSample],
        [RespiratoryRateSample]
    ) {
        await withTaskGroup(of: (String, [Any]).self) { group in
            var results: [String: [Any]] = [:]

            group.addTask {
                await withCheckedContinuation { continuation in
                    importService.fetchHistoricalHeartRate(
                        startDate: range.startDate,
                        endDate: range.endDate
                    ) { result in
                        continuation.resume(returning: ("heartRate", try? result.get() ?? []))
                    }
                }
            }

            group.addTask {
                await withCheckedContinuation { continuation in
                    importService.fetchHistoricalHRV(
                        startDate: range.startDate,
                        endDate: range.endDate
                    ) { result in
                        continuation.resume(returning: ("hrv", try? result.get() ?? []))
                    }
                }
            }

            group.addTask {
                await withCheckedContinuation { continuation in
                    importService.fetchHistoricalRespiratoryRate(
                        startDate: range.startDate,
                        endDate: range.endDate
                    ) { result in
                        continuation.resume(returning: ("respiratory", try? result.get() ?? []))
                    }
                }
            }

            for await (key, value) in group {
                results[key] = value
            }

            return (
                results["heartRate"] as? [HeartRateSample] ?? [],
                results["hrv"] as? [HRVSample] ?? [],
                results["respiratory"] as? [RespiratoryRateSample] ?? []
            )
        }
    }
}
```

## UI Example

```swift
struct ImportHistoricalDataView: View {
    @StateObject private var viewModel = MeditationImportViewModel()
    @State private var startDate = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
    @State private var endDate = Date()

    var body: some View {
        VStack {
            DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
            DatePicker("End Date", selection: $endDate, displayedComponents: .date)

            Button("Import Historical Data") {
                Task {
                    await viewModel.importHistoricalData(
                        startDate: startDate,
                        endDate: endDate
                    )
                }
            }
            .disabled(viewModel.isImporting)

            if viewModel.isImporting {
                ProgressView(value: viewModel.importProgress)
                Text("Importing... \(Int(viewModel.importProgress * 100))%")
            }

            Text("Imported \(viewModel.importedSessions.count) sessions")
        }
        .padding()
    }
}
```

## Important Notes

1. **Authorization Required**: User must grant HealthKit read permissions first
2. **Performance**: Large date ranges may take time - show progress indicator
3. **Background Processing**: Consider using background tasks for large imports
4. **Data Quality**: Auto-detection is heuristic-based - users may need to manually adjust sessions
5. **Privacy**: Only import data user has explicitly granted access to



