//
//  WatchContentView.swift
//  Plena Watch App
//
//  Created on [Date]
//

import SwiftUI

struct WatchContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // Meditation Session Tab
            NavigationStack {
                MeditationWatchView(healthKitService: HealthKitService())
                    .navigationTitle("Session")
            }
            .tag(0)

            // Dashboard Tab
            NavigationStack {
                DashboardWatchView(healthKitService: HealthKitService())
            }
            .tag(1)

            // Readiness Tab
            NavigationStack {
                ReadinessWatchView(healthKitService: HealthKitService())
            }
            .tag(2)
        }
    }
}

#Preview {
    WatchContentView()
}
