//
//  PlenaWatchApp.swift
//  Plena Watch App
//
//  Created on [Date]
//

import SwiftUI
import WatchKit

@main
struct PlenaWatchApp: App {
    let coreDataStack = CoreDataStack.shared
    @WKExtensionDelegateAdaptor(ExtensionDelegate.self) var extensionDelegate

    var body: some Scene {
        WindowGroup {
            WatchContentView()
        }
    }
}

