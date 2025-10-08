//
//  CustomCategoryMigrationService.swift
//  BudgetMeter
//
//  Created by BudgetMeter Team on 17.09.2025.
//

import Foundation
import CoreData

/// Service responsible for migrating existing CustomCategory data to the new unified FinancialCategory system
final class CustomCategoryMigrationService {
    
    private let persistenceService: PersistenceService
    private let userDefaults: UserDefaults
    
    private static let migrationCompletedKey = "customCategoryMigrationCompleted"
    
    init(
        persistenceService: PersistenceService = .shared,
        userDefaults: UserDefaults = .standard
    ) {
        self.persistenceService = persistenceService
        self.userDefaults = userDefaults
    }
    
    /// Performs the migration from CustomCategory to FinancialCategory if needed
    func performMigrationIfNeeded() {
        let migrationCompleted = userDefaults.bool(forKey: Self.migrationCompletedKey)
        
        if !migrationCompleted {
            migrateCustomCategoriesToFinancialCategories()
            userDefaults.set(true, forKey: Self.migrationCompletedKey)
            print("🔄 CustomCategoryMigrationService: Migration completed successfully")
        } else {
            print("🔄 CustomCategoryMigrationService: Migration already completed, skipping")
        }
    }
    
    // MARK: - Private Methods
    
    private func migrateCustomCategoriesToFinancialCategories() {
        let context = persistenceService.viewContext
        
        // Try to fetch CustomCategory entities (they might not exist if this is a fresh install)
        let customCategoryRequest: NSFetchRequest<NSManagedObject>
        
        // Use NSManagedObject since CustomCategory class might not be available after schema change
        if let customCategoryEntity = NSEntityDescription.entity(forEntityName: "CustomCategory", in: context) {
            customCategoryRequest = NSFetchRequest<NSManagedObject>()
            customCategoryRequest.entity = customCategoryEntity
        } else {
            print("🔄 CustomCategoryMigrationService: CustomCategory entity not found, no migration needed")
            return
        }
        
        do {
            let customCategories = try context.fetch(customCategoryRequest)
            
            if customCategories.isEmpty {
                print("🔄 CustomCategoryMigrationService: No custom categories found to migrate")
                return
            }
            
            print("🔄 CustomCategoryMigrationService: Found \(customCategories.count) custom categories to migrate")
            
            for customCategory in customCategories {
                migrateSingleCustomCategory(customCategory, in: context)
            }
            
            // Save the migration
            persistenceService.save()
            print("🔄 CustomCategoryMigrationService: Successfully migrated \(customCategories.count) custom categories")
            
        } catch {
            print("❌ CustomCategoryMigrationService: Failed to fetch custom categories: \(error)")
        }
    }
    
    private func migrateSingleCustomCategory(_ customCategory: NSManagedObject, in context: NSManagedObjectContext) {
        // Extract data from CustomCategory
        let name = customCategory.value(forKey: "name") as? String
        let iconName = customCategory.value(forKey: "iconName") as? String
        let colorHex = customCategory.value(forKey: "colorHex") as? String
        let type = customCategory.value(forKey: "type") as? String
        let isActive = customCategory.value(forKey: "isActive") as? Bool ?? true
        
        // Skip inactive categories
        guard isActive else {
            print("🔄 CustomCategoryMigrationService: Skipping inactive category: \(name ?? "Unknown")")
            return
        }
        
        // Create new FinancialCategory
        let financialCategory = FinancialCategory(context: context)
        financialCategory.id = UUID()
        financialCategory.type = type
        financialCategory.frequency = "monthly" // Default frequency for migrated categories
        financialCategory.amount = 0.0
        financialCategory.createdAt = Date()
        
        // Set custom attributes
        financialCategory.isCustom = true
        financialCategory.customName = name
        financialCategory.customIconName = iconName
        financialCategory.customColorHex = colorHex
        
        // No uniqueID for custom categories (they use customName instead)
        financialCategory.uniqueID = nil
        
        print("🔄 CustomCategoryMigrationService: Migrated '\(name ?? "Unknown")' (\(type ?? "Unknown")) to FinancialCategory")
    }
    
    /// Checks if there are any existing CustomCategory entities that need migration
    func hasCustomCategoriesToMigrate() -> Bool {
        let context = persistenceService.viewContext
        
        guard let customCategoryEntity = NSEntityDescription.entity(forEntityName: "CustomCategory", in: context) else {
            return false
        }
        
        let request = NSFetchRequest<NSManagedObject>()
        request.entity = customCategoryEntity
        request.fetchLimit = 1
        
        do {
            let count = try context.count(for: request)
            return count > 0
        } catch {
            print("❌ CustomCategoryMigrationService: Failed to check for custom categories: \(error)")
            return false
        }
    }
    
    /// Forces a re-migration (for debugging purposes)
    func forceRemigration() {
        userDefaults.set(false, forKey: Self.migrationCompletedKey)
        print("🔄 CustomCategoryMigrationService: Force re-migration enabled")
    }
}

// MARK: - Migration Validation

extension CustomCategoryMigrationService {
    
    /// Validates that the migration was successful
    func validateMigration() -> Bool {
        let context = persistenceService.viewContext
        let request: NSFetchRequest<FinancialCategory> = FinancialCategory.fetchRequest()
        request.predicate = NSPredicate(format: "isCustom == YES")
        
        do {
            let customFinancialCategories = try context.fetch(request)
            print("🔄 CustomCategoryMigrationService: Found \(customFinancialCategories.count) migrated custom categories")
            
            // Validate that migrated categories have proper data
            for category in customFinancialCategories {
                guard let customName = category.customName,
                      !customName.isEmpty,
                      let type = category.type,
                      let frequency = category.frequency else {
                    print("❌ CustomCategoryMigrationService: Invalid migrated category data")
                    return false
                }
                
                print("✅ Migrated: \(customName) (\(type), \(frequency))")
            }
            
            return true
        } catch {
            print("❌ CustomCategoryMigrationService: Failed to validate migration: \(error)")
            return false
        }
    }
}

