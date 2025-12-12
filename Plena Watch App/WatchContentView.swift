//
//  WatchContentView.swift
//  Plena Watch App
//
//  Created on [Date]
//

import SwiftUI

struct WatchContentView: View {
    var body: some View {
        NavigationStack {
            MeditationWatchView(healthKitService: HealthKitService())
                .navigationTitle("Plena")
        }
    }
}

#Preview {
    WatchContentView()
}
