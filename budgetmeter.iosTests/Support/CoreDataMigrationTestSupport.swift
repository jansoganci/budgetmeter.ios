//
//  CoreDataMigrationTestSupport.swift
//  budgetmeter.iosTests
//
//  In-memory Core Data helpers for Phase 2 migration tests.
//

import CoreData
import XCTest
@testable import budgetmeter_ios

enum CoreDataMigrationTestSupport {

    static func makeIsolatedUserDefaults() -> UserDefaults {
        let suiteName = "FinancialDataMigrationTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    static func makeMigrationService(
        persistence: PersistenceService,
        userDefaults: UserDefaults
    ) -> FinancialDataMigrationService {
        let savingsGoalManager = SavingsGoalManager(persistence: persistence)
        return FinancialDataMigrationService(
            persistenceService: persistence,
            userDefaults: userDefaults,
            savingsGoalManager: savingsGoalManager
        )
    }

    @discardableResult
    static func insertFinancialCategory(
        in context: NSManagedObjectContext,
        type: String,
        frequency: String,
        amount: Double,
        entryKind: String? = "recurring",
        createdAt: Date = Date(),
        isActive: Bool = true
    ) -> FinancialCategory {
        let category = FinancialCategory(context: context)
        category.id = UUID()
        category.type = type
        category.frequency = frequency
        category.amount = amount
        category.createdAt = createdAt
        category.isActive = isActive
        category.uniqueID = "test-\(UUID().uuidString)"

        if let entryKind {
            category.entryKind = entryKind
        } else {
            category.setValue(nil, forKey: "entryKind")
        }

        return category
    }

    @discardableResult
    static func insertRecurringTransaction(
        in context: NSManagedObjectContext,
        categoryType: String,
        amount: Double,
        startDate: Date = Date()
    ) -> RecurringTransaction {
        let transaction = RecurringTransaction(context: context)
        transaction.id = UUID()
        transaction.categoryType = categoryType
        transaction.amount = amount
        transaction.startDate = startDate
        transaction.lastProcessedDate = startDate
        transaction.frequency = "monthly"
        transaction.title = "Test Recurring"
        return transaction
    }

    @discardableResult
    static func insertAppSettings(
        in context: NSManagedObjectContext,
        savingsGoalAmount: Double = 0
    ) -> AppSettings {
        let settings = AppSettings(context: context)
        settings.savingsGoalAmount = savingsGoalAmount
        settings.preferredCurrencyCode = "USD"
        return settings
    }

    @discardableResult
    static func insertSavingsGoal(
        in context: NSManagedObjectContext,
        name: String = "Existing Goal",
        targetAmount: Double = 500,
        isArchived: Bool = false
    ) -> SavingsGoal {
        let goal = SavingsGoal(context: context)
        goal.id = UUID()
        goal.name = name
        goal.targetAmount = targetAmount
        goal.currentAmount = 0
        goal.isArchived = isArchived
        goal.createdAt = Date()
        return goal
    }

    static func fetchAllCategories(in context: NSManagedObjectContext) -> [FinancialCategory] {
        let request: NSFetchRequest<FinancialCategory> = FinancialCategory.fetchRequest()
        return (try? context.fetch(request)) ?? []
    }

    static func fetchAllSavingsGoals(in context: NSManagedObjectContext) -> [SavingsGoal] {
        let request: NSFetchRequest<SavingsGoal> = SavingsGoal.fetchRequest()
        return (try? context.fetch(request)) ?? []
    }

    static func saveContext(_ persistence: PersistenceService, file: StaticString = #file, line: UInt = #line) {
        XCTAssertTrue(persistence.save(), "Failed to save test context", file: file, line: line)
    }
}
