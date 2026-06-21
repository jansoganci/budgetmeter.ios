//
//  IncomeExpenseFlowTests.swift
//  budgetmeter.iosTests
//
//  Phase 5 — Income/Expense summary mapping and write behavior tests.
//

import CoreData
import XCTest
@testable import budgetmeter_ios

@MainActor
final class IncomeExpenseFlowTests: XCTestCase {

    private var persistence: PersistenceService!
    private var context: NSManagedObjectContext!
    private var builder: FinancialSummaryBuilder!
    private var calendar: Calendar!
    private let asOf = Date(timeIntervalSince1970: 1_704_067_200) // 2024-01-01 UTC

    override func setUp() {
        super.setUp()
        persistence = PersistenceService.makeInMemoryForTesting()
        context = persistence.viewContext
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        builder = FinancialSummaryBuilder(context: context, calendar: calendar)
    }

    override func tearDown() {
        builder = nil
        calendar = nil
        context = nil
        persistence = nil
        super.tearDown()
    }

    // MARK: - Summary mapping

    func test_incomeSummaryDisplay_usesRecurringIncomeMonthlyFromBuilder() {
        insertRecurringCategory(type: "income", frequency: "monthly", amount: 5_000)
        CoreDataMigrationTestSupport.saveContext(persistence)

        let summary = builder.build(selectedPeriod: .month, asOf: asOf)
        let viewModel = IncomeViewModel(
            persistenceService: persistence,
            summaryBuilder: builder
        )

        XCTAssertEqual(viewModel.totalMonthlyIncome, summary.recurringIncomeMonthly, accuracy: 0.01)
        XCTAssertEqual(viewModel.dailyAverageIncome, summary.recurringIncomeDaily, accuracy: 0.01)
        XCTAssertEqual(viewModel.yearlyProjectionIncome, summary.recurringIncomeMonthly * 12, accuracy: 0.01)
    }

    func test_expenseSummaryDisplay_usesRecurringExpenseMonthlyFromBuilder() {
        insertRecurringCategory(type: "expense", frequency: "monthly", amount: 1_200)
        CoreDataMigrationTestSupport.saveContext(persistence)

        let summary = builder.build(selectedPeriod: .month, asOf: asOf)
        let viewModel = ExpenseViewModel(
            persistenceService: persistence,
            summaryBuilder: builder
        )

        XCTAssertEqual(viewModel.totalMonthlyExpenses, summary.recurringExpenseMonthly, accuracy: 0.01)
        XCTAssertEqual(viewModel.dailyAverageExpenses, summary.recurringExpenseDaily, accuracy: 0.01)
        XCTAssertEqual(viewModel.yearlyProjectionExpenses, summary.recurringExpenseMonthly * 12, accuracy: 0.01)
    }

    func test_expenseSummary_includesSubscriptionsAndBillsThroughBuilder() {
        insertRecurringCategory(type: "expense", frequency: "monthly", amount: 500)
        insertSubscription(name: "Music", amount: 30, billingCycle: "monthly")
        insertBill(name: "Rent", amount: 1_200, frequency: "monthly")
        CoreDataMigrationTestSupport.saveContext(persistence)

        let summary = builder.build(selectedPeriod: .month, asOf: asOf)
        let viewModel = ExpenseViewModel(
            persistenceService: persistence,
            summaryBuilder: builder
        )

        XCTAssertEqual(summary.recurringExpenseMonthly, 1_730, accuracy: 0.01)
        XCTAssertEqual(viewModel.totalMonthlyExpenses, 1_730, accuracy: 0.01)
    }

    func test_expenseSummary_doesNotDoubleCountSubscriptions() {
        insertRecurringCategory(type: "expense", frequency: "monthly", amount: 1_000)
        insertSubscription(name: "Cloud", amount: 20, billingCycle: "monthly")
        CoreDataMigrationTestSupport.saveContext(persistence)

        let viewModel = ExpenseViewModel(
            persistenceService: persistence,
            summaryBuilder: builder
        )

        XCTAssertEqual(viewModel.totalMonthlyExpenses, 1_020, accuracy: 0.01)
        XCTAssertNotEqual(viewModel.totalMonthlyExpenses, 1_040, accuracy: 0.01)
    }

    func test_oneTimeIncome_inPeriodButNotRecurringPace() {
        insertRecurringCategory(type: "income", frequency: "daily", amount: 100)
        insertOneTimeCategory(type: "income", amount: 1_000, occurrenceDate: asOf)
        CoreDataMigrationTestSupport.saveContext(persistence)

        let summary = builder.build(selectedPeriod: .day, asOf: asOf)
        let viewModel = IncomeViewModel(
            persistenceService: persistence,
            summaryBuilder: builder
        )

        XCTAssertEqual(summary.recurringIncomeDaily, 100, accuracy: 0.01)
        XCTAssertEqual(viewModel.totalMonthlyIncome, summary.recurringIncomeMonthly, accuracy: 0.01)
        XCTAssertEqual(summary.oneTimeIncomeInPeriod, 1_000, accuracy: 0.01)
        XCTAssertEqual(viewModel.oneTimeIncomes.count, 1)
    }

    func test_oneTimeExpense_inPeriodButNotRecurringPace() {
        insertRecurringCategory(type: "expense", frequency: "daily", amount: 40)
        insertOneTimeCategory(type: "expense", amount: 250, occurrenceDate: asOf)
        CoreDataMigrationTestSupport.saveContext(persistence)

        let summary = builder.build(selectedPeriod: .day, asOf: asOf)
        let viewModel = ExpenseViewModel(
            persistenceService: persistence,
            summaryBuilder: builder
        )

        XCTAssertEqual(summary.recurringExpenseDaily, 40, accuracy: 0.01)
        XCTAssertEqual(viewModel.totalMonthlyExpenses, summary.recurringExpenseMonthly, accuracy: 0.01)
        XCTAssertEqual(summary.oneTimeExpenseInPeriod, 250, accuracy: 0.01)
        XCTAssertEqual(viewModel.oneTimeExpenses.count, 1)
    }

    // MARK: - Write mapping

    func test_recurringCategoryWrite_setsEntryKindAndMetadata() {
        let category = FinancialCategory(context: context)
        category.id = UUID()
        category.type = "income"
        category.amount = 500
        category.customName = "Salary"
        category.isCustom = true

        FinancialCategoryWriteSupport.applyMetadata(
            to: category,
            entryKind: .recurring,
            recurringFrequency: "monthly"
        )
        CoreDataMigrationTestSupport.saveContext(persistence)

        XCTAssertEqual(category.entryKind, "recurring")
        XCTAssertEqual(category.frequency, "monthly")
        XCTAssertTrue(category.isActive)
        XCTAssertNotNil(category.lastModified)
    }

    func test_oneTimeCategoryWrite_setsEntryKindAndOccurrenceDate() {
        let category = FinancialCategory(context: context)
        category.id = UUID()
        category.type = "expense"
        category.amount = 120
        category.customName = "Repair"
        category.isCustom = true

        FinancialCategoryWriteSupport.applyMetadata(
            to: category,
            entryKind: .oneTime,
            recurringFrequency: "monthly",
            occurrenceDate: asOf
        )
        CoreDataMigrationTestSupport.saveContext(persistence)

        XCTAssertEqual(category.entryKind, "oneTime")
        XCTAssertEqual(category.frequency, "once")
        XCTAssertEqual(category.occurrenceDate, asOf)
        XCTAssertTrue(category.isActive)
        XCTAssertNotNil(category.lastModified)
    }

    func test_recurringAutomation_createsOneTimeNotLegacyRecurringFrequency() {
        let transaction = RecurringTransaction(context: context)
        transaction.id = UUID()
        transaction.title = "Automated Rent"
        transaction.amount = 900
        transaction.categoryType = "expense"
        transaction.frequency = "monthly"
        transaction.nextDueDate = asOf
        transaction.isActive = true

        let category = FinancialCategory(context: context)
        category.id = UUID()
        category.uniqueID = UUID().uuidString
        category.type = transaction.categoryType
        category.amount = transaction.amount
        category.customName = transaction.title
        category.isCustom = true

        FinancialCategoryWriteSupport.applyMetadata(
            to: category,
            entryKind: .oneTime,
            recurringFrequency: "once",
            occurrenceDate: transaction.nextDueDate ?? Date(),
            sourceType: "recurringAutomation",
            sourceID: transaction.id?.uuidString
        )
        CoreDataMigrationTestSupport.saveContext(persistence)

        XCTAssertEqual(category.entryKind, "oneTime")
        XCTAssertEqual(category.frequency, "once")
        XCTAssertNotEqual(category.frequency, "recurring")
        XCTAssertEqual(category.sourceType, "recurringAutomation")
    }

    func test_recurringDisplayFilter_excludesOneTimeRows() {
        insertRecurringCategory(type: "income", frequency: "monthly", amount: 1_000)
        insertOneTimeCategory(type: "income", amount: 500, occurrenceDate: asOf)
        CoreDataMigrationTestSupport.saveContext(persistence)

        let viewModel = IncomeViewModel(
            persistenceService: persistence,
            summaryBuilder: builder
        )

        XCTAssertEqual(viewModel.monthlyIncomes.count, 1)
        XCTAssertEqual(viewModel.oneTimeIncomes.count, 1)
    }

    // MARK: - Helpers

    @discardableResult
    private func insertRecurringCategory(
        type: String,
        frequency: String,
        amount: Double
    ) -> FinancialCategory {
        let category = FinancialCategory(context: context)
        category.id = UUID()
        category.type = type
        category.frequency = frequency
        category.amount = amount
        category.uniqueID = "test-\(UUID().uuidString)"
        category.entryKind = "recurring"
        category.isActive = true
        return category
    }

    @discardableResult
    private func insertOneTimeCategory(
        type: String,
        amount: Double,
        occurrenceDate: Date
    ) -> FinancialCategory {
        let category = insertRecurringCategory(type: type, frequency: "once", amount: amount)
        category.entryKind = "oneTime"
        category.occurrenceDate = occurrenceDate
        category.customName = "One-Time"
        return category
    }

    @discardableResult
    private func insertSubscription(
        name: String,
        amount: Double,
        billingCycle: String
    ) -> Subscription {
        let subscription = Subscription(context: context)
        subscription.id = UUID()
        subscription.name = name
        subscription.amount = amount
        subscription.billingCycle = billingCycle
        subscription.isActive = true
        subscription.isPaused = false
        subscription.firstBillDate = asOf
        subscription.nextRenewalDate = asOf
        return subscription
    }

    @discardableResult
    private func insertBill(
        name: String,
        amount: Double,
        frequency: String
    ) -> Bill {
        let bill = Bill(context: context)
        bill.id = UUID()
        bill.name = name
        bill.amount = amount
        bill.frequency = frequency
        bill.isRecurring = true
        bill.isPaid = false
        bill.dueDate = asOf
        return bill
    }
}
