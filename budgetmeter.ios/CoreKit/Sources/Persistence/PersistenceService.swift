//
//  PersistenceService.swift
//  BudgetMeter
//
//  Created by BudgetMeter Team on 17.09.2025.
//

import CoreData
import CloudKit
import Foundation

/// Singleton service that manages the Core Data stack with CloudKit integration
final class PersistenceService {

    // MARK: - Singleton
    static let shared = PersistenceService()

    // MARK: - Error Handling

    /// Notification posted when a critical persistence error occurs
    static let persistenceErrorNotification = Notification.Name("PersistenceServiceError")

    /// Flag indicating if the persistence layer failed to initialize
    private(set) var hasCriticalError: Bool = false
    private(set) var lastError: Error?
    
    // MARK: - Core Data Stack
    
    /// The persistent container for the application
    lazy var persistentContainer: NSPersistentCloudKitContainer = {
        let container = NSPersistentCloudKitContainer(name: "BudgetMeter")
        
        // Configure for CloudKit
        let storeDescription = container.persistentStoreDescriptions.first
        storeDescription?.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        storeDescription?.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        container.loadPersistentStores { [weak self] _, error in
            if let error = error as NSError? {
                print("💾 PersistenceService: ❌ Error loading stores: \(error)")
                self?.hasCriticalError = true
                self?.lastError = error

                // Post notification so the UI can respond
                NotificationCenter.default.post(
                    name: PersistenceService.persistenceErrorNotification,
                    object: nil,
                    userInfo: ["error": error]
                )

                // Log detailed error for debugging
                print("💾 PersistenceService: ❌ Critical error - app may not function correctly")
                print("💾 Error details: \(error.localizedDescription)")
                if let detailedErrors = error.userInfo[NSDetailedErrorsKey] as? [NSError] {
                    for detailedError in detailedErrors {
                        print("💾 Detailed error: \(detailedError.localizedDescription)")
                    }
                }
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
    /// - Returns: true if save succeeded, false if it failed
    @discardableResult
    func save() -> Bool {
        let context = persistentContainer.viewContext

        guard context.hasChanges else {
            return true // No changes to save
        }

        do {
            try context.save()
            return true
        } catch {
            let nsError = error as NSError
            print("💾 PersistenceService: ❌ Save failed: \(nsError)")
            print("💾 Error details: \(nsError.localizedDescription)")

            // Store the error
            lastError = error

            // Post notification so the UI can respond
            NotificationCenter.default.post(
                name: PersistenceService.persistenceErrorNotification,
                object: nil,
                userInfo: ["error": error, "operation": "save"]
            )

            // Rollback to prevent corrupt state
            context.rollback()

            return false
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

// MARK: - Error Recovery
extension PersistenceService {

    /// Check if the persistence layer is healthy and ready to use
    var isHealthy: Bool {
        return !hasCriticalError
    }

    /// Reset error state (use with caution, typically after user acknowledges error)
    func resetErrorState() {
        hasCriticalError = false
        lastError = nil
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
