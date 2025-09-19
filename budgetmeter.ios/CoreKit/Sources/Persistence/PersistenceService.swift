//
//  PersistenceService.swift
//  BudgetMeter
//
//  Created by BudgetMeter Team on 17.09.2025.
//

import CoreData
import CloudKit

/// Singleton service that manages the Core Data stack with CloudKit integration
final class PersistenceService {
    
    // MARK: - Singleton
    static let shared = PersistenceService()
    
    // MARK: - Core Data Stack
    
    /// The persistent container for the application
    lazy var persistentContainer: NSPersistentCloudKitContainer = {
        let container = NSPersistentCloudKitContainer(name: "BudgetMeter")
        
        // Configure for CloudKit
        let storeDescription = container.persistentStoreDescriptions.first
        storeDescription?.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        storeDescription?.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                print("💾 PersistenceService: ❌ Error loading stores: \(error)")
                // In production, you should handle this error appropriately
                fatalError("Unresolved Core Data error \(error), \(error.userInfo)")
            }
        }
        
        // Automatically merge changes from parent context
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        return container
    }()
    
    /// The main context for UI operations (runs on main queue)
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    // MARK: - Private Initializer
    private init() {}
    
    // MARK: - Core Data Operations
    
    /// Saves the context if there are changes
    func save() {
        let context = persistentContainer.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                print("💾 PersistenceService: ❌ Save failed: \(nsError)")
                fatalError("Unresolved Core Data save error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    /// Creates a background context for performing data operations off the main thread
    func newBackgroundContext() -> NSManagedObjectContext {
        return persistentContainer.newBackgroundContext()
    }
    
    /// Performs a block on a background context and saves automatically
    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        persistentContainer.performBackgroundTask { context in
            block(context)
            
            if context.hasChanges {
                do {
                    try context.save()
                } catch {
                    print("Background save failed: \(error)")
                }
            }
        }
    }
}

// MARK: - CloudKit Status
extension PersistenceService {
    
    /// Check if CloudKit is available
    var isCloudKitAvailable: Bool {
        guard FileManager.default.ubiquityIdentityToken != nil else {
            return false
        }
        return true
    }
}
