//
//  AxisLabelTestView.swift
//  Plena
//
//  Test view to compare axis label implementations side-by-side
//

import SwiftUI
import Charts

struct AxisLabelTestView: View {
    @State private var selectedTimeRange: TimeRange = .day
    @State private var selectedImplementation: AxisLabelImplementation = .separateView

    // Sample data for testing
    private var sampleData: [(date: Date, value: Double)] {
        let calendar = Calendar.current
        let now = Date()
        var data: [(date: Date, value: Double)] = []

        let daysBack: Int
        switch selectedTimeRange {
        case .day:
            daysBack = 1
        case .week:
            daysBack = 7
        case .month:
            daysBack = 30
        case .year:
            daysBack = 365
        }

        for i in 0..<daysBack {
            if let date = calendar.date(byAdding: .day, value: -i, to: now) {
                let value = Double.random(in: 50...100)
                data.append((date: date, value: value))
            }
        }

        return data.reversed()
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Controls
                VStack(spacing: 16) {
                    Picker("Time Range", selection: $selectedTimeRange) {
                        Text("Day").tag(TimeRange.day)
                        Text("Week").tag(TimeRange.week)
                        Text("Month").tag(TimeRange.month)
                        Text("Year").tag(TimeRange.year)
                    }
                    .pickerStyle(.segmented)

                    Picker("Implementation", selection: $selectedImplementation) {
                        ForEach(AxisLabelImplementation.allCases, id: \.self) { impl in
                            Text(impl.rawValue).tag(impl)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: selectedImplementation) { _, newValue in
                        currentAxisLabelImplementation = newValue
                    }
                }
                .padding()

                // Chart with selected implementation
                VStack(alignment: .leading, spacing: 12) {
                    Text("Current Implementation: \(selectedImplementation.rawValue)")
                        .font(.headline)
                        .padding(.horizontal)

                    Chart {
                        ForEach(sampleData, id: \.date) { point in
                            LineMark(
                                x: .value("Date", point.date),
                                y: .value("Value", point.value)
                            )
                            .foregroundStyle(Color("PlenaPrimary"))
                        }
                    }
                    .frame(height: 200)
                    .chartXAxis {
                        if selectedImplementation == .chartIntegrated {
                            AxisMarks(values: .automatic) { _ in
                                AxisValueLabel()
                            }
                        }
                    }
                    .padding()

                    if selectedImplementation == .separateView {
                        PlenaTimeAxisLabels(
                            granularity: selectedTimeRange.granularity,
                            referenceDate: Date()
                        )
                        .padding(.horizontal)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                )
                .padding(.horizontal)

                // Comparison section (if chart integrated, show both)
                if selectedImplementation == .chartIntegrated {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Comparison: Separate View Implementation")
                            .font(.headline)
                            .padding(.horizontal)

                        Chart {
                            ForEach(sampleData, id: \.date) { point in
                                LineMark(
                                    x: .value("Date", point.date),
                                    y: .value("Value", point.value)
                                )
                                .foregroundStyle(Color("PlenaPrimary"))
                            }
                        }
                        .frame(height: 200)
                        .chartXAxis {
                            // No axis marks for separate view comparison
                        }
                        .padding()

                        PlenaTimeAxisLabels(
                            granularity: selectedTimeRange.granularity,
                            referenceDate: Date()
                        )
                        .padding(.horizontal)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    )
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Axis Label Test")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        AxisLabelTestView()
    }
}









