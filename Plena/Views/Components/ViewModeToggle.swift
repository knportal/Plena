//
//  ViewModeToggle.swift
//  Plena
//
//  Segmented control for Consistency/Trend toggle
//

import SwiftUI

struct ViewModeToggle: View {
    @Binding var viewMode: ViewMode

    var body: some View {
        Picker("View Mode", selection: $viewMode) {
            ForEach(ViewMode.allCases, id: \.self) { mode in
                Text(mode.rawValue).tag(mode)
            }
        }
        .pickerStyle(.segmented)
    }
}

#Preview {
    ViewModeToggle(viewMode: .constant(.consistency))
        .padding()
}
