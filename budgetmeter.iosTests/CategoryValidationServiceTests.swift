//
//  CategoryValidationServiceTests.swift
//  budgetmeter.iosTests
//

import CoreData
import XCTest
@testable import budgetmeter_ios

@MainActor
final class CategoryValidationServiceTests: XCTestCase {

    private var persistence: PersistenceService!
    private var context: NSManagedObjectContext!
    private var validationService: CategoryValidationService!

    override func setUp() {
        super.setUp()
        persistence = PersistenceService.makeInMemoryForTesting()
        context = persistence.viewContext
        validationService = CategoryValidationService(persistenceService: persistence)
    }

    override func tearDown() {
        validationService = nil
        context = nil
        persistence = nil
        super.tearDown()
    }

    func test_turkishNamePassesValidation() {
        let result = validationService.validateCustomCategory(
            name: "Maaş",
            type: "income",
            entryKind: .recurring,
            recurringFrequency: "monthly",
            context: context
        )
        XCTAssertTrue(result.isValid)
    }

    func test_emojiInNameFailsValidation() {
        let result = validationService.validateCustomCategory(
            name: "Coffee ☕",
            type: "expense",
            entryKind: .recurring,
            recurringFrequency: "monthly",
            context: context
        )
        XCTAssertFalse(result.isValid)
    }

    func test_duplicateBlockedSameType() throws {
        let first = validationService.createCustomCategory(
            name: "Freelance",
            type: "income",
            entryKind: .recurring,
            recurringFrequency: "monthly",
            context: context
        )
        guard case .success(let category) = first else {
            return XCTFail("Expected first category to be created")
        }
        FinancialCategoryWriteSupport.applyMetadata(
            to: category,
            entryKind: .recurring,
            recurringFrequency: "monthly"
        )
        try context.save()

        let duplicate = validationService.validateCustomCategory(
            name: "freelance",
            type: "income",
            entryKind: .oneTime,
            recurringFrequency: nil,
            context: context
        )
        XCTAssertFalse(duplicate.isValid)
    }

    func test_incomeFreelanceDuplicateFailsAgainstSeededCategory() {
        insertSeededCategory(type: "income", uniqueID: "freelance", frequency: "daily")

        let duplicate = validationService.validateCustomCategory(
            name: "Freelance",
            type: "income",
            entryKind: .recurring,
            recurringFrequency: "daily",
            context: context
        )
        XCTAssertFalse(duplicate.isValid)
    }

    func test_incomeFreelanceDuplicateFailsEvenWhenIconDiffers() throws {
        let first = validationService.createCustomCategory(
            name: "Freelance",
            type: "income",
            entryKind: .recurring,
            recurringFrequency: "daily",
            iconName: "laptopcomputer",
            context: context
        )
        guard case .success(let category) = first else {
            return XCTFail("Expected first category to be created")
        }
        FinancialCategoryWriteSupport.applyMetadata(
            to: category,
            entryKind: .recurring,
            recurringFrequency: "daily"
        )
        try context.save()

        let duplicate = validationService.createCustomCategory(
            name: "Freelance",
            type: "income",
            entryKind: .recurring,
            recurringFrequency: "daily",
            iconName: "briefcase.fill",
            context: context
        )
        guard case .failure = duplicate else {
            return XCTFail("Expected duplicate validation failure")
        }
    }

    func test_expenseFreelanceDuplicateFailsEvenWhenIconDiffers() throws {
        let first = validationService.createCustomCategory(
            name: "Freelance",
            type: "expense",
            entryKind: .recurring,
            recurringFrequency: "monthly",
            iconName: "cart.fill",
            context: context
        )
        guard case .success(let category) = first else {
            return XCTFail("Expected first category to be created")
        }
        FinancialCategoryWriteSupport.applyMetadata(
            to: category,
            entryKind: .recurring,
            recurringFrequency: "monthly"
        )
        try context.save()

        let duplicate = validationService.validateCustomCategory(
            name: "Freelance",
            type: "expense",
            entryKind: .recurring,
            recurringFrequency: "weekly",
            context: context
        )
        XCTAssertFalse(duplicate.isValid)
    }

    func test_unicodeDuplicateFailsSameIncomeType() throws {
        let first = validationService.createCustomCategory(
            name: "Maaş",
            type: "income",
            entryKind: .recurring,
            recurringFrequency: "monthly",
            context: context
        )
        guard case .success(let category) = first else {
            return XCTFail("Expected first category to be created")
        }
        FinancialCategoryWriteSupport.applyMetadata(
            to: category,
            entryKind: .recurring,
            recurringFrequency: "monthly"
        )
        try context.save()

        let duplicate = validationService.validateCustomCategory(
            name: "maaş",
            type: "income",
            entryKind: .recurring,
            recurringFrequency: "yearly",
            context: context
        )
        XCTAssertFalse(duplicate.isValid)
    }

    func test_whitespaceDuplicateFails() throws {
        let first = validationService.createCustomCategory(
            name: "Freelance",
            type: "income",
            entryKind: .recurring,
            recurringFrequency: "daily",
            context: context
        )
        guard case .success(let category) = first else {
            return XCTFail("Expected first category to be created")
        }
        FinancialCategoryWriteSupport.applyMetadata(
            to: category,
            entryKind: .recurring,
            recurringFrequency: "daily"
        )
        try context.save()

        let duplicate = validationService.validateCustomCategory(
            name: "  Freelance  ",
            type: "income",
            entryKind: .oneTime,
            recurringFrequency: nil,
            context: context
        )
        XCTAssertFalse(duplicate.isValid)
    }

    func test_sameNameAllowedAcrossIncomeAndExpense() throws {
        let income = validationService.createCustomCategory(
            name: "Transfer",
            type: "income",
            entryKind: .recurring,
            recurringFrequency: "monthly",
            context: context
        )
        guard case .success(let incomeCategory) = income else {
            return XCTFail("Expected income category")
        }
        FinancialCategoryWriteSupport.applyMetadata(
            to: incomeCategory,
            entryKind: .recurring,
            recurringFrequency: "monthly"
        )
        try context.save()

        let expense = validationService.validateCustomCategory(
            name: "Transfer",
            type: "expense",
            entryKind: .recurring,
            recurringFrequency: "monthly",
            context: context
        )
        XCTAssertTrue(expense.isValid)
    }

    func test_customCategoryAssignsUniqueID() {
        let result = validationService.createCustomCategory(
            name: "Çay",
            type: "expense",
            entryKind: .recurring,
            recurringFrequency: "weekly",
            context: context
        )

        guard case .success(let category) = result else {
            return XCTFail("Expected category creation")
        }

        XCTAssertTrue(category.isCustom)
        XCTAssertEqual(category.customName, "Çay")
        XCTAssertNotNil(category.uniqueID)
        XCTAssertTrue(category.uniqueID?.hasPrefix("custom_") == true)
    }

    func test_normalizeForDuplicateComparison_stripsDiacritics() {
        let left = CategoryNameNormalizer.normalizeForDuplicateComparison("Maaş")
        let right = CategoryNameNormalizer.normalizeForDuplicateComparison("maas")
        XCTAssertEqual(left, right)
    }

    @discardableResult
    private func insertSeededCategory(
        type: String,
        uniqueID: String,
        frequency: String
    ) -> FinancialCategory {
        let category = FinancialCategory(context: context)
        category.id = UUID()
        category.type = type
        category.uniqueID = uniqueID
        category.frequency = frequency
        category.entryKind = "recurring"
        category.isCustom = false
        category.isActive = true
        return category
    }
}
