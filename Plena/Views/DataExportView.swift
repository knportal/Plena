//
//  DataExportView.swift
//  Plena
//
//  View for exporting meditation session data
//

import SwiftUI

@MainActor
struct DataExportView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = DataExportViewModel()

    var body: some View {
        NavigationStack {
            Form {
                // Export Type Section
                Section {
                    Picker("Export Type", selection: $viewModel.exportType) {
                        Text("Session Summary").tag(ExportType.summary)
                        Text("Detailed Data").tag(ExportType.detailed)
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Export Type")
                } footer: {
                    if viewModel.exportType == .summary {
                        Text("Export session summaries with statistics (one row per session). Ideal for overview and analysis.")
                    } else {
                        Text("Export all sensor samples with timestamps (multiple rows per session). Best for detailed data analysis.")
                    }
                }

                // Date Range Section
                Section {
                    DatePicker("Start Date", selection: $viewModel.startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $viewModel.endDate, displayedComponents: .date)
                } header: {
                    Text("Date Range")
                } footer: {
                    Text("Select the date range for sessions to export.")
                }

                // Sessions Info Section
                Section {
                    if viewModel.isLoadingSessions {
                        HStack {
                            ProgressView()
                            Text("Loading sessions...")
                                .foregroundColor(.secondary)
                        }
                    } else {
                        HStack {
                            Text("Sessions to Export")
                            Spacer()
                            Text("\(viewModel.sessionCount)")
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Preview")
                }

                // Export Button Section
                Section {
                    Button(action: {
                        Task {
                            await viewModel.exportData()
                        }
                    }) {
                        HStack {
                            Spacer()
                            if viewModel.isExporting {
                                ProgressView()
                                    .padding(.trailing, 8)
                            }
                            Text(viewModel.isExporting ? "Exporting..." : "Export Data")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(viewModel.isExporting || viewModel.sessionCount == 0)
                }
            }
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Export Successful", isPresented: $viewModel.showSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your data has been exported successfully. You can now share or save the file.")
            }
            .alert("Export Error", isPresented: $viewModel.showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage)
            }
            .sheet(isPresented: $viewModel.showShareSheet) {
                if let url = viewModel.exportedFileURL {
                    ShareSheet(items: [url])
                }
            }
            .task {
                await viewModel.loadSessionCount()
            }
            .onChange(of: viewModel.startDate) { oldValue, newValue in
                Task {
                    await viewModel.loadSessionCount()
                }
            }
            .onChange(of: viewModel.endDate) { oldValue, newValue in
                Task {
                    await viewModel.loadSessionCount()
                }
            }
        }
    }
}

// MARK: - Export Type

enum ExportType {
    case summary
    case detailed
}

// MARK: - View Model

@MainActor
class DataExportViewModel: ObservableObject {
    @Published var exportType: ExportType = .summary
    @Published var startDate: Date
    @Published var endDate: Date
    @Published var sessionCount: Int = 0
    @Published var isLoadingSessions = false
    @Published var isExporting = false
    @Published var showSuccessAlert = false
    @Published var showErrorAlert = false
    @Published var showShareSheet = false
    @Published var errorMessage = ""
    @Published var exportedFileURL: URL?

    private let storageService = CoreDataStorageService()
    private let exportService = DataExportService()

    init() {
        // Default to last 30 days
        self.endDate = Date()
        self.startDate = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
    }

    func loadSessionCount() async {
        isLoadingSessions = true
        defer { isLoadingSessions = false }

        do {
            // Load sessions without samples for counting (more efficient)
            let sessions = try storageService.loadSessionsWithoutSamples(
                startDate: startDate,
                endDate: endDate
            )
            sessionCount = sessions.count
        } catch {
            print("❌ Error loading session count: \(error)")
            sessionCount = 0
        }
    }

    func exportData() async {
        isExporting = true
        defer { isExporting = false }

        do {
            // Load full sessions with samples for export
            let sessions = try storageService.loadSessions(
                startDate: startDate,
                endDate: endDate
            )

            guard !sessions.isEmpty else {
                errorMessage = "No sessions found in the selected date range."
                showErrorAlert = true
                return
            }

            // Export based on type
            let fileURL: URL
            switch exportType {
            case .summary:
                fileURL = try exportService.exportSessionSummary(sessions: sessions)
            case .detailed:
                fileURL = try exportService.exportDetailedData(sessions: sessions)
            }

            // Show share sheet
            exportedFileURL = fileURL
            showShareSheet = true

        } catch let error as ExportError {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        } catch {
            errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
            showErrorAlert = true
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No updates needed
    }
}

#Preview {
    DataExportView()
}

