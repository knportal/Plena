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

    // Note: WKExtensionDelegateAdaptor warning may appear but is safe to ignore
    // watchOS apps are extension-based processes, so this is the correct usage
    @WKExtensionDelegateAdaptor(ExtensionDelegate.self) var extensionDelegate

    var body: some Scene {
        WindowGroup {
            WatchContentView()
        }
    }
}

