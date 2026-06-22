//
//  CategoryValidationService.swift
//  BudgetMeter
//
//  Created by BudgetMeter Team on 17.09.2025.
//

import Foundation
import CoreData
import SwiftUI

// MARK: - Category Name Rules

enum CategoryNameNormalizer {

    private static let allowedPunctuation = CharacterSet(charactersIn: ".,-'&()")

    /// Normalized text key for duplicate comparison (not shown in UI).
    static func normalizeForDuplicateComparison(_ name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let folded = trimmed.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        let collapsed = folded
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        return collapsed.lowercased()
    }

    static func containsEmoji(_ name: String) -> Bool {
        name.contains { character in
            character.unicodeScalars.contains { scalar in
                scalar.properties.isEmoji && (scalar.value > 0x238C || scalar.properties.isEmojiPresentation)
            }
        }
    }

    static func isValidDisplayName(_ name: String) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        guard !containsEmoji(trimmed) else { return false }

        for scalar in trimmed.unicodeScalars {
            if CharacterSet.controlCharacters.contains(scalar) {
                return false
            }
        }

        for character in trimmed {
            if character.isLetter || character.isNumber || character.isWhitespace {
                continue
            }
            guard let scalar = character.unicodeScalars.first,
                  allowedPunctuation.contains(scalar) else {
                return false
            }
        }

        return true
    }
}

/// Service for validating custom category creation and preventing duplicates
@MainActor
final class CategoryValidationService: ObservableObject {

    static let recurringFrequencyOptions = ["daily", "weekly", "monthly", "yearly"]

    private let persistenceService: PersistenceService

    init(persistenceService: PersistenceService = .shared) {
        self.persistenceService = persistenceService
    }

    /// Validates a custom category before creation.
    func validateCustomCategory(
        name: String,
        type: String,
        entryKind: FinancialCategoryEntryKind,
        recurringFrequency: String?,
        context: NSManagedObjectContext
    ) -> ValidationResult {

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedName.isEmpty {
            return .invalid(
                String(
                    localized: "category.validation.empty",
                    defaultValue: "Category name cannot be empty",
                    table: "UI"
                )
            )
        }

        if trimmedName.count > 50 {
            return .invalid(
                String(
                    localized: "category.validation.too_long",
                    defaultValue: "Category name is too long (maximum 50 characters)",
                    table: "UI"
                )
            )
        }

        guard type == "income" || type == "expense" else {
            return .invalid(
                String(
                    localized: "category.validation.invalid_type",
                    defaultValue: "Invalid category type",
                    table: "UI"
                )
            )
        }

        if entryKind == .recurring {
            guard let recurringFrequency,
                  Self.recurringFrequencyOptions.contains(recurringFrequency) else {
                return .invalid(
                    String(
                        localized: "category.validation.invalid_frequency",
                        defaultValue: "Invalid frequency",
                        table: "UI"
                    )
                )
            }
        }

        if CategoryNameNormalizer.containsEmoji(trimmedName) {
            return .invalid(
                String(
                    localized: "category.validation.emoji_not_allowed",
                    defaultValue: "Emoji can't be used in the category name. Choose an icon instead.",
                    table: "UI"
                )
            )
        }

        if !CategoryNameNormalizer.isValidDisplayName(trimmedName) {
            return .invalid(
                String(
                    localized: "category.validation.invalid_characters",
                    defaultValue: "This name isn't valid. Try a shorter name without emoji or special symbols.",
                    table: "UI"
                )
            )
        }

        if categoryExistsNormalized(name: trimmedName, type: type, context: context) {
            return .invalid(
                String(
                    localized: "category.validation.duplicate",
                    defaultValue: "You already have a category with this name.",
                    table: "UI"
                )
            )
        }

        return .valid
    }

    /// Legacy entry point — maps section frequency to recurring validation.
    func validateCustomCategory(
        name: String,
        type: String,
        frequency: String,
        context: NSManagedObjectContext
    ) -> ValidationResult {
        validateCustomCategory(
            name: name,
            type: type,
            entryKind: .recurring,
            recurringFrequency: frequency,
            context: context
        )
    }

    /// Checks normalized display-name duplicates within the same income/expense type.
    /// Compares against both custom (`customName`) and seeded (localized `uniqueID`) categories.
    func categoryExistsNormalized(name: String, type: String, context: NSManagedObjectContext) -> Bool {
        let targetKey = CategoryNameNormalizer.normalizeForDuplicateComparison(name)
        guard !targetKey.isEmpty else { return false }

        let request: NSFetchRequest<FinancialCategory> = FinancialCategory.fetchRequest()
        request.predicate = NSPredicate(format: "type == %@", type)

        do {
            let categories = try context.fetch(request)
            return categories.contains { category in
                let displayName = DataSeedingService.displayName(for: category)
                guard !displayName.isEmpty else { return false }
                return CategoryNameNormalizer.normalizeForDuplicateComparison(displayName) == targetKey
            }
        } catch {
            print("❌ CategoryValidationService: Failed to check for duplicates: \(error)")
            return false
        }
    }

    /// Creates a new custom FinancialCategory with validation.
    func createCustomCategory(
        name: String,
        type: String,
        entryKind: FinancialCategoryEntryKind,
        recurringFrequency: String,
        iconName: String = "tag.fill",
        colorHex: String? = nil,
        context: NSManagedObjectContext
    ) -> Result<FinancialCategory, ValidationResult> {

        let validationResult = validateCustomCategory(
            name: name,
            type: type,
            entryKind: entryKind,
            recurringFrequency: entryKind == .recurring ? recurringFrequency : nil,
            context: context
        )

        if case .invalid(let errorMessage) = validationResult {
            return .failure(.invalid(errorMessage))
        }

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let placeholderFrequency = entryKind == .recurring ? recurringFrequency : "monthly"

        let category = FinancialCategory(context: context)
        category.id = UUID()
        category.type = type
        category.frequency = placeholderFrequency
        category.amount = 0.0
        category.createdAt = Date()

        category.isCustom = true
        category.customName = trimmedName
        category.customIconName = iconName
        category.customColorHex = colorHex
        category.uniqueID = "custom_\(UUID().uuidString.lowercased())"

        return .success(category)
    }

    /// Legacy create API for tests and debug utilities.
    func createCustomCategory(
        name: String,
        type: String,
        frequency: String,
        iconName: String = "tag.fill",
        colorHex: String? = nil,
        context: NSManagedObjectContext
    ) -> Result<FinancialCategory, ValidationResult> {
        createCustomCategory(
            name: name,
            type: type,
            entryKind: .recurring,
            recurringFrequency: frequency,
            iconName: iconName,
            colorHex: colorHex,
            context: context
        )
    }

    /// Gets all custom categories of a specific type and frequency.
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

    /// Deletes a custom category with validation.
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
                FinancialCategoryWriteSupport.applyMetadata(
                    to: category,
                    entryKind: .recurring,
                    recurringFrequency: frequency
                )
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

    func validateSchemaAndData(context: NSManagedObjectContext) -> Bool {
        let sampleRequest: NSFetchRequest<FinancialCategory> = FinancialCategory.fetchRequest()
        sampleRequest.fetchLimit = 1

        do {
            let sample = try context.fetch(sampleRequest).first
            if let sample = sample {
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
