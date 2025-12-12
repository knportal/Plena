//
//  AxisLabelSettingsView.swift
//  Plena
//
//  Settings view to toggle between axis label implementations
//

import SwiftUI

struct AxisLabelSettingsView: View {
    @State private var selectedImplementation: AxisLabelImplementation = .separateView

    var body: some View {
        Form {
            Section {
                Picker("Axis Label Implementation", selection: $selectedImplementation) {
                    ForEach(AxisLabelImplementation.allCases, id: \.self) { impl in
                        Text(impl.rawValue).tag(impl)
                    }
                }
                .onChange(of: selectedImplementation) { _, newValue in
                    currentAxisLabelImplementation = newValue
                }

                Text(selectedImplementation.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            } header: {
                Text("Implementation")
            } footer: {
                Text("Choose how x-axis labels are displayed. Chart Integrated uses Swift Charts' built-in system. Separate View uses a custom view below the chart.")
            }

            Section {
                NavigationLink {
                    AxisLabelTestView()
                } label: {
                    HStack {
                        Image(systemName: "chart.bar.xaxis")
                        Text("Test View")
                    }
                }
            } header: {
                Text("Testing")
            } footer: {
                Text("Use the test view to compare both implementations side-by-side.")
            }
        }
        .navigationTitle("Axis Labels")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        AxisLabelSettingsView()
    }
}

