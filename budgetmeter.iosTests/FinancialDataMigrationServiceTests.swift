//
//  FinancialDataMigrationServiceTests.swift
//  budgetmeter.iosTests
//
//  Phase 2 migration tests (M1–M4, readability) on in-memory Core Data.
//

import CoreData
import XCTest
@testable import budgetmeter_ios

final class FinancialDataMigrationServiceTests: XCTestCase {

    private var persistence: PersistenceService!
    private var userDefaults: UserDefaults!
    private var userDefaultsSuiteName: String!
    private var migrationService: FinancialDataMigrationService!
    private var context: NSManagedObjectContext!

    override func setUp() {
        super.setUp()
        persistence = PersistenceService.makeInMemoryForTesting()
        context = persistence.viewContext
        userDefaultsSuiteName = "FinancialDataMigrationTests.\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: userDefaultsSuiteName)!
        userDefaults.removePersistentDomain(forName: userDefaultsSuiteName)
        migrationService = CoreDataMigrationTestSupport.makeMigrationService(
            persistence: persistence,
            userDefaults: userDefaults
        )
    }

    override func tearDown() {
        userDefaults?.removePersistentDomain(forName: userDefaultsSuiteName)
        persistence = nil
        userDefaults = nil
        migrationService = nil
        context = nil
        super.tearDown()
    }

    // MARK: - M1: In-memory v3 model loads

    func test_inMemoryV3Model_loadsWithoutCrash() {
        _ = FinancialCategory(context: context)
        CoreDataMigrationTestSupport.saveContext(persistence)
        XCTAssertFalse(persistence.hasCriticalError)
    }

    // MARK: - M2: entryKind defaults

    func test_missingEntryKind_becomesRecurring() {
        let category = CoreDataMigrationTestSupport.insertFinancialCategory(
            in: context,
            type: "expense",
            frequency: "monthly",
            amount: 120,
            entryKind: nil
        )
        CoreDataMigrationTestSupport.saveContext(persistence)

        migrationService.performMigrationIfNeeded()
        context.refreshAllObjects()

        XCTAssertEqual(category.entryKind, "recurring")
        XCTAssertNotNil(category.lastModified)
        XCTAssertEqual(migrationService.recordedMigrationVersion, 2)
    }

    // MARK: - isActive

    func test_existingCategory_hasIsActiveTrue_afterMigration() {
        let category = CoreDataMigrationTestSupport.insertFinancialCategory(
            in: context,
            type: "income",
            frequency: "monthly",
            amount: 3000,
            entryKind: nil
        )
        XCTAssertTrue(category.isActive, "v3 schema default should be active")
        CoreDataMigrationTestSupport.saveContext(persistence)

        migrationService.performMigrationIfNeeded()
        context.refreshAllObjects()

        XCTAssertTrue(category.isActive)
    }

    func test_legacyRecurringFrequency_setsIsActiveTrue() {
        let category = CoreDataMigrationTestSupport.insertFinancialCategory(
            in: context,
            type: "expense",
            frequency: "recurring",
            amount: 45,
            entryKind: nil,
            isActive: false
        )
        CoreDataMigrationTestSupport.saveContext(persistence)

        migrationService.performMigrationIfNeeded()
        context.refreshAllObjects()

        XCTAssertTrue(category.isActive)
    }

    // MARK: - M3: Legacy frequency == "recurring"

    func test_legacyFrequencyRecurring_orphanReclassifiedToOneTime() {
        let createdAt = Date(timeIntervalSince1970: 1_700_000_000)
        let category = CoreDataMigrationTestSupport.insertFinancialCategory(
            in: context,
            type: "expense",
            frequency: "recurring",
            amount: 99.99,
            entryKind: nil,
            createdAt: createdAt
        )
        CoreDataMigrationTestSupport.saveContext(persistence)

        migrationService.performMigrationIfNeeded()
        context.refreshAllObjects()

        XCTAssertEqual(category.entryKind, "oneTime")
        XCTAssertEqual(category.occurrenceDate, createdAt)
        XCTAssertEqual(category.amount, 99.99, accuracy: 0.01)
        XCTAssertNil(category.sourceType)
        XCTAssertNil(category.sourceID)

        let allCategories = CoreDataMigrationTestSupport.fetchAllCategories(in: context)
        XCTAssertEqual(allCategories.count, 1, "Legacy rows must not be deleted")
    }

    func test_legacyFrequencyRecurring_matchedRecurringTransactionGetsSourceLink() {
        let createdAt = Date(timeIntervalSince1970: 1_700_000_000)
        let recurring = CoreDataMigrationTestSupport.insertRecurringTransaction(
            in: context,
            categoryType: "expense",
            amount: 50,
            startDate: createdAt
        )
        let category = CoreDataMigrationTestSupport.insertFinancialCategory(
            in: context,
            type: "expense",
            frequency: "recurring",
            amount: 50,
            entryKind: nil,
            createdAt: createdAt
        )
        CoreDataMigrationTestSupport.saveContext(persistence)

        migrationService.performMigrationIfNeeded()
        context.refreshAllObjects()

        XCTAssertEqual(category.entryKind, "oneTime")
        XCTAssertEqual(category.sourceType, "recurringAutomation")
        XCTAssertEqual(category.sourceID, "recurring:\(recurring.id!.uuidString)")
    }

    // MARK: - M4: Savings goal migration

    func test_savingsGoalAmount_migratesWhenNoActiveGoalExists() {
        CoreDataMigrationTestSupport.insertAppSettings(in: context, savingsGoalAmount: 2500)
        CoreDataMigrationTestSupport.saveContext(persistence)

        migrationService.performMigrationIfNeeded()
        context.refreshAllObjects()

        let goals = CoreDataMigrationTestSupport.fetchAllSavingsGoals(in: context)
        XCTAssertEqual(goals.count, 1)
        XCTAssertEqual(goals.first?.name, "My Goal")
        XCTAssertEqual(goals.first?.targetAmount ?? 0, 2500, accuracy: 0.01)
        XCTAssertFalse(goals.first?.isArchived ?? true)
    }

    func test_savingsGoalAmount_skippedWhenActiveGoalExists() {
        CoreDataMigrationTestSupport.insertAppSettings(in: context, savingsGoalAmount: 2500)
        CoreDataMigrationTestSupport.insertSavingsGoal(in: context, targetAmount: 800)
        CoreDataMigrationTestSupport.saveContext(persistence)

        migrationService.performMigrationIfNeeded()
        context.refreshAllObjects()

        let goals = CoreDataMigrationTestSupport.fetchAllSavingsGoals(in: context)
        XCTAssertEqual(goals.count, 1)
        XCTAssertEqual(goals.first?.name, "Existing Goal")
        XCTAssertEqual(goals.first?.targetAmount ?? 0, 800, accuracy: 0.01)
    }

    // MARK: - Idempotency

    func test_migration_isIdempotent() {
        let category = CoreDataMigrationTestSupport.insertFinancialCategory(
            in: context,
            type: "expense",
            frequency: "monthly",
            amount: 200,
            entryKind: nil
        )
        CoreDataMigrationTestSupport.insertAppSettings(in: context, savingsGoalAmount: 1000)
        CoreDataMigrationTestSupport.saveContext(persistence)

        migrationService.performMigrationIfNeeded()
        context.refreshAllObjects()

        let entryKindAfterFirst = category.entryKind
        let lastModifiedAfterFirst = category.lastModified
        let goalCountAfterFirst = CoreDataMigrationTestSupport.fetchAllSavingsGoals(in: context).count
        let versionAfterFirst = migrationService.recordedMigrationVersion

        migrationService.performMigrationIfNeeded()
        context.refreshAllObjects()

        XCTAssertEqual(category.entryKind, entryKindAfterFirst)
        XCTAssertEqual(category.lastModified, lastModifiedAfterFirst)
        XCTAssertEqual(
            CoreDataMigrationTestSupport.fetchAllSavingsGoals(in: context).count,
            goalCountAfterFirst
        )
        XCTAssertEqual(migrationService.recordedMigrationVersion, versionAfterFirst)
    }

    // MARK: - M6: Recurring data remains readable

    func test_recurringIncomeExpenseData_remainsReadableAfterMigration() {
        CoreDataMigrationTestSupport.insertFinancialCategory(
            in: context,
            type: "income",
            frequency: "monthly",
            amount: 5000,
            entryKind: nil
        )
        CoreDataMigrationTestSupport.insertFinancialCategory(
            in: context,
            type: "income",
            frequency: "yearly",
            amount: 1200,
            entryKind: nil
        )
        CoreDataMigrationTestSupport.insertFinancialCategory(
            in: context,
            type: "expense",
            frequency: "daily",
            amount: 10,
            entryKind: nil
        )
        CoreDataMigrationTestSupport.insertFinancialCategory(
            in: context,
            type: "expense",
            frequency: "monthly",
            amount: 1500,
            entryKind: nil
        )
        CoreDataMigrationTestSupport.saveContext(persistence)

        migrationService.performMigrationIfNeeded()
        context.refreshAllObjects()

        let categories = CoreDataMigrationTestSupport.fetchAllCategories(in: context)
        XCTAssertEqual(categories.count, 4)

        var dailyIncome = 0.0
        var monthlyIncome = 0.0
        var yearlyIncome = 0.0
        var dailyExpense = 0.0
        var monthlyExpense = 0.0
        var yearlyExpense = 0.0

        for category in categories where category.entryKind == "recurring" {
            guard category.isActive else { continue }
            switch category.type {
            case "income":
                switch category.frequency {
                case "daily": dailyIncome += category.amount
                case "monthly": monthlyIncome += category.amount
                case "yearly": yearlyIncome += category.amount
                default: break
                }
            case "expense":
                switch category.frequency {
                case "daily": dailyExpense += category.amount
                case "monthly": monthlyExpense += category.amount
                case "yearly": yearlyExpense += category.amount
                default: break
                }
            default:
                break
            }
        }

        XCTAssertEqual(dailyIncome, 0, accuracy: 0.01)
        XCTAssertEqual(monthlyIncome, 5000, accuracy: 0.01)
        XCTAssertEqual(yearlyIncome, 1200, accuracy: 0.01)
        XCTAssertEqual(dailyExpense, 10, accuracy: 0.01)
        XCTAssertEqual(monthlyExpense, 1500, accuracy: 0.01)
        XCTAssertEqual(yearlyExpense, 0, accuracy: 0.01)

        let monthlyIncomeTotal = CalculationEngine.totalMonthlyIncome(
            dailyIncomeTotal: dailyIncome,
            monthlyIncomeTotal: monthlyIncome,
            yearlyIncomeTotal: yearlyIncome
        )
        let monthlyExpenseTotal = CalculationEngine.totalMonthlyExpense(
            dailyTotal: dailyExpense,
            monthlyTotal: monthlyExpense,
            yearlyTotal: yearlyExpense
        )

        XCTAssertEqual(monthlyIncomeTotal, 5100, accuracy: 0.1)
        XCTAssertEqual(
            monthlyExpenseTotal,
            CalculationEngine.totalMonthlyExpense(dailyTotal: 10, monthlyTotal: 1500, yearlyTotal: 0),
            accuracy: 0.01
        )
    }
}
