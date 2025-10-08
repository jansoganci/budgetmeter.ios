//
//  CategoryValidationService.swift
//  BudgetMeter
//
//  Created by BudgetMeter Team on 17.09.2025.
//

import Foundation
import CoreData
import SwiftUI

/// Service for validating custom category creation and preventing duplicates
@MainActor
final class CategoryValidationService: ObservableObject {
    
    private let persistenceService: PersistenceService
    
    init(persistenceService: PersistenceService = .shared) {
        self.persistenceService = persistenceService
    }
    
    /// Validates a custom category before creation
    func validateCustomCategory(
        name: String,
        type: String,
        frequency: String,
        context: NSManagedObjectContext
    ) -> ValidationResult {
        
        // 1. Name validation
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedName.isEmpty {
            return .invalid("Category name cannot be empty")
        }
        
        if trimmedName.count > 50 {
            return .invalid("Category name is too long (maximum 50 characters)")
        }
        
        // 2. Type validation
        guard type == "income" || type == "expense" else {
            return .invalid("Invalid category type")
        }
        
        // 3. Frequency validation
        guard frequency == "daily" || frequency == "monthly" || frequency == "yearly" else {
            return .invalid("Invalid frequency")
        }
        
        // 4. Duplicate checking
        if categoryExists(name: trimmedName, type: type, frequency: frequency, context: context) {
            return .invalid("A category with this name already exists in the \(frequency) \(type) section")
        }
        
        // 5. Character validation
        if !isValidCategoryName(trimmedName) {
            return .invalid("Category name contains invalid characters")
        }
        
        return .valid
    }
    
    /// Checks if a category with the same name, type, and frequency already exists
    func categoryExists(name: String, type: String, frequency: String, context: NSManagedObjectContext) -> Bool {
        let request: NSFetchRequest<FinancialCategory> = FinancialCategory.fetchRequest()
        request.predicate = NSPredicate(
            format: "customName == %@ AND type == %@ AND frequency == %@ AND isCustom == YES",
            name, type, frequency
        )
        request.fetchLimit = 1
        
        do {
            let count = try context.count(for: request)
            return count > 0
        } catch {
            print("❌ CategoryValidationService: Failed to check for duplicates: \(error)")
            return false
        }
    }
    
    /// Validates that a category name contains only valid characters
    private func isValidCategoryName(_ name: String) -> Bool {
        // Allow letters, numbers, spaces, hyphens, and parentheses
        let allowedCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 -()")
        let nameCharacterSet = CharacterSet(charactersIn: name)
        return allowedCharacters.isSuperset(of: nameCharacterSet)
    }
    
    /// Creates a new custom FinancialCategory with validation
    func createCustomCategory(
        name: String,
        type: String,
        frequency: String,
        iconName: String = "tag.fill",
        colorHex: String? = nil,
        context: NSManagedObjectContext
    ) -> Result<FinancialCategory, ValidationResult> {
        
        // Validate input
        let validationResult = validateCustomCategory(
            name: name,
            type: type,
            frequency: frequency,
            context: context
        )
        
        if case .invalid(let errorMessage) = validationResult {
            return .failure(.invalid(errorMessage))
        }
        
        // Create the category
        let category = FinancialCategory(context: context)
        category.id = UUID()
        category.type = type
        category.frequency = frequency
        category.amount = 0.0
        category.createdAt = Date()
        
        // Set custom attributes
        category.isCustom = true
        category.customName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        category.customIconName = iconName
        category.customColorHex = colorHex
        
        // No uniqueID for custom categories
        category.uniqueID = nil
        
        return .success(category)
    }
    
    /// Gets all custom categories of a specific type and frequency
    func getCustomCategories(type: String, frequency: String, context: NSManagedObjectContext) -> [FinancialCategory] {
        let request: NSFetchRequest<FinancialCategory> = FinancialCategory.fetchRequest()
        request.predicate = NSPredicate(
            format: "isCustom == YES AND type == %@ AND frequency == %@",
            type, frequency
        )
        request.sortDescriptors = [NSSortDescriptor(keyPath: \FinancialCategory.customName, ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("❌ CategoryValidationService: Failed to fetch custom categories: \(error)")
            return []
        }
    }
    
    /// Deletes a custom category with validation
    func deleteCustomCategory(_ category: FinancialCategory, context: NSManagedObjectContext) -> Bool {
        guard category.isCustom else {
            print("❌ CategoryValidationService: Cannot delete predefined category")
            return false
        }
        
        context.delete(category)
        
        do {
            try context.save()
            return true
        } catch {
            print("❌ CategoryValidationService: Failed to delete custom category: \(error)")
            return false
        }
    }
}

// MARK: - Validation Result

enum ValidationResult: Error {
    case valid
    case invalid(String)
    
    var isValid: Bool {
        switch self {
        case .valid:
            return true
        case .invalid:
            return false
        }
    }
    
    var errorMessage: String? {
        switch self {
        case .valid:
            return nil
        case .invalid(let message):
            return message
        }
    }
}

// MARK: - Testing Utilities

#if DEBUG
extension CategoryValidationService {
    
    /// Creates test custom categories for development
    func createTestCustomCategories(context: NSManagedObjectContext) {
        let testCategories = [
            ("Gym", "expense", "monthly", "dumbbell.fill"),
            ("Freelance", "income", "daily", "laptopcomputer"),
            ("Coffee", "expense", "daily", "cup.and.saucer"),
            ("Bonus", "income", "yearly", "gift.fill")
        ]
        
        for (name, type, frequency, icon) in testCategories {
            let result = createCustomCategory(
                name: name,
                type: type,
                frequency: frequency,
                iconName: icon,
                context: context
            )
            
            switch result {
            case .success(let category):
                print("✅ Created test category: \(category.customName ?? "Unknown")")
            case .failure(let error):
                print("❌ Failed to create test category '\(name)': \(error.errorMessage ?? "Unknown error")")
            }
        }
        
        do {
            try context.save()
            print("✅ Test custom categories created successfully")
        } catch {
            print("❌ Failed to save test custom categories: \(error)")
        }
    }
    
    /// Validates the current schema and data
    func validateSchemaAndData(context: NSManagedObjectContext) -> Bool {
        // Test 1: Check if FinancialCategory has the new attributes
        let sampleRequest: NSFetchRequest<FinancialCategory> = FinancialCategory.fetchRequest()
        sampleRequest.fetchLimit = 1
        
        do {
            let sample = try context.fetch(sampleRequest).first
            if let sample = sample {
                // Try to access new attributes (this will fail if they don't exist)
                let _ = sample.isCustom
                let _ = sample.customName
                let _ = sample.customIconName
                let _ = sample.customColorHex
                print("✅ FinancialCategory schema validation passed")
            }
        } catch {
            print("❌ FinancialCategory schema validation failed: \(error)")
            return false
        }
        
        // Test 2: Check if we can create and query custom categories
        let customRequest: NSFetchRequest<FinancialCategory> = FinancialCategory.fetchRequest()
        customRequest.predicate = NSPredicate(format: "isCustom == YES")
        
        do {
            let customCategories = try context.fetch(customRequest)
            print("✅ Found \(customCategories.count) custom categories")
            
            for category in customCategories {
                print("  - \(category.customName ?? "Unknown"): \(category.type ?? "Unknown") (\(category.frequency ?? "Unknown"))")
            }
        } catch {
            print("❌ Failed to query custom categories: \(error)")
            return false
        }
        
        return true
    }
}
#endif
