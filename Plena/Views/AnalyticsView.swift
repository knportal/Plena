//
//  AnalyticsView.swift
//  Plena
//
//  View for displaying HRV data collection analytics
//

import SwiftUI

struct AnalyticsView: View {
    @State private var analytics: HRVAnalytics?
    @State private var isLoading = true

    private let analyticsService = SessionAnalyticsService()

    var body: some View {
        List {
            if let analytics = analytics {
                Section("HRV Data Collection") {
                    HStack {
                        Text("HRV Availability Rate")
                        Spacer()
                        Text("\(Int(analytics.hrvAvailabilityRate * 100))%")
                            .fontWeight(.semibold)
                            .foregroundColor(analytics.hrvAvailabilityRate > 0.7 ? .green : analytics.hrvAvailabilityRate > 0.3 ? .orange : .red)
                    }

                    HStack {
                        Text("Sessions with HRV")
                        Spacer()
                        Text("\(analytics.sessionsWithHRV) / \(analytics.totalSessions)")
                    }

                    HStack {
                        Text("Sessions without HRV")
                        Spacer()
                        Text("\(analytics.sessionsWithoutHRV)")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Avg Samples per Session")
                        Spacer()
                        Text(String(format: "%.1f", analytics.avgHRVSamplesPerSession))
                    }
                }

                Section("By Device") {
                    HStack {
                        Text("Watch HRV Success")
                        Spacer()
                        Text("\(analytics.watchSessionsWithHRV) / \(analytics.watchSessions)")
                            .foregroundColor(analytics.watchSessions > 0 && Double(analytics.watchSessionsWithHRV)/Double(analytics.watchSessions) > 0.7 ? .green : .orange)
                    }

                    HStack {
                        Text("iPhone HRV Success")
                        Spacer()
                        Text("\(analytics.iPhoneSessionsWithHRV) / \(analytics.iPhoneSessions)")
                            .foregroundColor(analytics.iPhoneSessions > 0 && Double(analytics.iPhoneSessionsWithHRV)/Double(analytics.iPhoneSessions) > 0.7 ? .green : .orange)
                    }
                }

                Section("Session Duration Impact") {
                    HStack {
                        Text("Avg Duration (with HRV)")
                        Spacer()
                        Text(formatDuration(analytics.avgDurationWithHRV))
                    }

                    HStack {
                        Text("Avg Duration (without HRV)")
                        Spacer()
                        Text(formatDuration(analytics.avgDurationWithoutHRV))
                    }

                    if analytics.avgDurationWithHRV > 0 && analytics.avgDurationWithoutHRV > 0 {
                        VStack(alignment: .leading, spacing: 4) {
                            if analytics.avgDurationWithHRV > analytics.avgDurationWithoutHRV * 1.5 {
                                Label("Longer sessions have better HRV collection", systemImage: "checkmark.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            } else if analytics.avgDurationWithoutHRV > analytics.avgDurationWithHRV * 1.5 {
                                Label("Shorter sessions have better HRV collection", systemImage: "info.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            } else {
                                Label("Duration has minimal impact on HRV collection", systemImage: "equal.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                if !analytics.hrvByWatchModel.isEmpty {
                    Section("By Watch Model") {
                        ForEach(analytics.hrvByWatchModel.sorted(by: { $0.key < $1.key }), id: \.key) { model, rate in
                            HStack {
                                Text(model)
                                Spacer()
                                Text("\(Int(rate * 100))%")
                                    .foregroundColor(rate > 0.7 ? .green : rate > 0.3 ? .orange : .red)
                            }
                        }
                    }
                }

                Section {
                    Button(action: {
                        analyticsService.printAnalytics()
                    }) {
                        Label("Print to Console", systemImage: "doc.text.magnifyingglass")
                    }
                } footer: {
                    Text("Prints detailed analytics to Xcode console for debugging.")
                }
            } else if isLoading {
                Section {
                    HStack {
                        Spacer()
                        ProgressView("Loading analytics...")
                        Spacer()
                    }
                }
            } else {
                Section {
                    Text("No analytics data available")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("HRV Analytics")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            loadAnalytics()
        }
        .refreshable {
            loadAnalytics()
        }
    }

    private func loadAnalytics() {
        Task {
            isLoading = true
            do {
                analytics = try analyticsService.fetchHRVAnalytics()
                isLoading = false
            } catch {
                print("Failed to load analytics: \(error)")
                isLoading = false
            }
        }
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds / 60)
        let secs = Int(seconds.truncatingRemainder(dividingBy: 60))
        if mins > 0 {
            return "\(mins)m \(secs)s"
        } else {
            return "\(secs)s"
        }
    }
}

#Preview {
    NavigationStack {
        AnalyticsView()
    }
}

