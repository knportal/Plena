//
//  CoreDataStack.swift
//  PlenaShared
//
//  Core Data stack setup and management
//

import Foundation
import CoreData

class CoreDataStack {
    static let shared = CoreDataStack()

    private var _persistentContainer: NSPersistentContainer?
    private var initializationError: Error?

    var persistentContainer: NSPersistentContainer {
        if let container = _persistentContainer {
            return container
        }

        let container = NSPersistentContainer(name: "PlenaDataModel")

        // Configure Core Data to use App Group shared container
        // This allows both iPhone and Watch apps to access the same Core Data store
        let appGroupIdentifier = "group.com.plena.meditation.coredata"

        if let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) {
            let storeURL = appGroupURL.appendingPathComponent("PlenaDataModel.sqlite")

            // Update the persistent store description to use the shared location
            let description = container.persistentStoreDescriptions.first
            description?.url = storeURL
            description?.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            description?.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

            print("✅ Using App Group shared container: \(storeURL.path)")
            print("   App Group ID: \(appGroupIdentifier)")
            print("   Container URL: \(appGroupURL.path)")
            print("   Store exists: \(FileManager.default.fileExists(atPath: storeURL.path))")

            // Extract container UUID from path for comparison
            let containerPath = appGroupURL.path
            if let uuidRange = containerPath.range(of: "[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}", options: .regularExpression) {
                let containerUUID = String(containerPath[uuidRange])
                print("   Container UUID: \(containerUUID)")

                // Check if this matches known separate containers (indicates App Group not properly shared)
                if containerUUID == "804EC17C-B879-437D-ACF8-46D0344E31EB" {
                    print("   ⚠️ WARNING: Watch container detected - if iPhone uses different UUID, App Group is not shared!")
                } else if containerUUID == "E75E196F-D110-4BC9-810A-D0E5728D8E0F" {
                    print("   ⚠️ WARNING: iPhone container detected - if Watch uses different UUID, App Group is not shared!")
                }
            }
        } else {
            // Fallback to default location if App Group is not available
            let description = container.persistentStoreDescriptions.first
            description?.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            description?.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

            print("⚠️ WARNING: App Group not available!")
            print("   App Group ID: \(appGroupIdentifier)")
            print("   This means Watch and iPhone will use separate stores!")
            print("   Check that App Groups capability is enabled in Xcode for both targets.")
            print("   Using default container location instead.")
        }

        var loadError: Error?
        container.loadPersistentStores { description, error in
            if let error = error {
                let nsError = error as NSError
                let detailedError = """
                ❌ Core Data store failed to load

                Error Domain: \(nsError.domain)
                Error Code: \(nsError.code)
                Error Description: \(nsError.localizedDescription)

                Underlying Errors:
                \(nsError.userInfo[NSUnderlyingErrorKey] as? NSError ?? nsError)

                User Info:
                \(nsError.userInfo)

                Possible Causes:
                1. Core Data model file (PlenaDataModel.xcdatamodeld) is missing or not added to the project
                2. CloudKit container identifier is incorrect or not configured
                3. Persistent store file is corrupted
                4. Missing entitlements or capabilities

                To Fix:
                1. Verify PlenaDataModel.xcdatamodeld exists in PlenaShared/Models/
                2. Ensure it's added to both iOS and watchOS targets
                3. Check CloudKit container identifier matches entitlements
                4. Clean build folder (⌘ShiftK) and rebuild
                """

                print(detailedError)
                loadError = error
                self.initializationError = error
            }
        }

        if let error = loadError {
            #if DEBUG
            fatalError("Core Data initialization failed: \(error.localizedDescription)")
            #else
            return createFallbackContainer()
            #endif
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        _persistentContainer = container
        return container
    }

    private func createFallbackContainer() -> NSPersistentContainer {
        // Create a minimal container to prevent crashes
        // This won't work properly but prevents immediate crash
        let container = NSPersistentContainer(name: "PlenaDataModel")
        _persistentContainer = container
        return container
    }

    var mainContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    func saveContext() {
        let context = persistentContainer.viewContext

        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved Core Data error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    func newBackgroundContext() -> NSManagedObjectContext {
        return persistentContainer.newBackgroundContext()
    }
}




