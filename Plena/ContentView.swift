//
//  ContentView.swift
//  Plena
//
//  Created on [Date]
//

import SwiftUI

struct ContentView: View {
    @StateObject private var tabCoordinator = TabCoordinator()

    var body: some View {
        TabView(selection: $tabCoordinator.selectedTab) {
            // Meditation Session Tab
            NavigationStack {
                ZStack {
                    // Subtle gradient background
                    LinearGradient(
                        colors: [
                            Color("PlenaSecondary").opacity(0.1),
                            Color("PlenaPrimary").opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()

                    MeditationSessionView(healthKitService: HealthKitService())
                }
            }
            .tabItem {
                Label("Session", systemImage: "leaf.fill")
            }
            .tag(0)

            // Dashboard Tab
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.fill")
                }
                .tag(1)

            // Readiness Tab
            ReadinessView(healthKitService: HealthKitService())
                .environmentObject(tabCoordinator)
                .tabItem {
                    Label("Readiness", systemImage: "heart.text.square.fill")
                }
                .tag(2)

            // Data Visualization Tab
            DataVisualizationView()
                .environmentObject(tabCoordinator)
                .tabItem {
                    Label("Data", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(3)

            // Settings Tab
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(4)
        }
    }
}

#Preview {
    ContentView()
}
