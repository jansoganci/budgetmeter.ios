//
//  FinancialSummaryBuilderTests.swift
//  budgetmeter.iosTests
//
//  Phase 1 shared financial summary contract tests.
//

import CoreData
import XCTest
@testable import budgetmeter_ios

final class FinancialSummaryBuilderTests: XCTestCase {

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

    func test_normalization_usesSharedEngineConstants() {
        let lines = [
            RecurringMoneyLine(
                id: "daily",
                source: .category,
                categoryKey: "daily",
                label: "Daily",
                amount: 10,
                interval: .daily,
                isActive: true
            ),
            RecurringMoneyLine(
                id: "weekly",
                source: .category,
                categoryKey: "weekly",
                label: "Weekly",
                amount: 70,
                interval: .weekly,
                isActive: true
            ),
            RecurringMoneyLine(
                id: "monthly",
                source: .category,
                categoryKey: "monthly",
                label: "Monthly",
                amount: CalculationEngine.daysPerMonth,
                interval: .monthly,
                isActive: true
            ),
            RecurringMoneyLine(
                id: "yearly",
                source: .category,
                categoryKey: "yearly",
                label: "Yearly",
                amount: CalculationEngine.daysPerYear,
                interval: .yearly,
                isActive: true
            )
        ]
        let input = makeInput(recurringIncomeLines: lines)

        let summary = builder.build(from: input)

        XCTAssertEqual(summary.recurringIncomeDaily, 22, accuracy: 0.0001)
        XCTAssertEqual(summary.recurringIncomeMonthly, 22 * CalculationEngine.daysPerMonth, accuracy: 0.0001)
    }

    func test_paceIntervalConversion_derivesFromNetDailyPace() {
        let input = makeInput(
            recurringIncomeLines: [
                line(id: "income", amount: 100, interval: .daily)
            ],
            recurringExpenseLines: [
                line(id: "expense", amount: 40, interval: .daily)
            ]
        )

        let summary = builder.build(from: input)

        XCTAssertEqual(summary.netPacePerDay, 60, accuracy: 0.0001)
        XCTAssertEqual(summary.netPacePerHour, 2.5, accuracy: 0.0001)
        XCTAssertEqual(summary.netPacePerMinute, 60.0 / 1_440.0, accuracy: 0.0001)
        XCTAssertEqual(summary.netPacePerWeek, 420, accuracy: 0.0001)
        XCTAssertEqual(summary.netPacePerMonth, 60 * CalculationEngine.daysPerMonth, accuracy: 0.0001)
        XCTAssertEqual(summary.paceStatus, .movingForward)
    }

    func test_builderRollsSubscriptionsAndBillsIntoRecurringExpenses() {
        insertSettings(currencyCode: "USD")
        insertFinancialCategory(type: "income", frequency: "monthly", amount: 5_000, name: "Salary")
        insertSubscription(name: "Music", amount: 30, billingCycle: "monthly", category: "Entertainment")
        insertBill(name: "Rent", amount: 1_200, frequency: "monthly", category: "Housing")
        XCTAssertTrue(persistence.save())

        let summary = builder.build(selectedPeriod: .month, asOf: asOf)

        XCTAssertEqual(summary.currencyCode, "USD")
        XCTAssertEqual(summary.recurringIncomeMonthly, 5_000, accuracy: 0.01)
        XCTAssertEqual(summary.recurringExpenseMonthly, 1_230, accuracy: 0.01)
        XCTAssertEqual(summary.netPacePerMonth, 3_770, accuracy: 0.01)
    }

    func test_savingsETA_usesNetRecurringPace() {
        insertSettings(savingsGoalAmount: 1_000)
        insertFinancialCategory(type: "income", frequency: "daily", amount: 100, name: "Income")
        insertFinancialCategory(type: "expense", frequency: "daily", amount: 50, name: "Expense")
        XCTAssertTrue(persistence.save())

        let summary = builder.build(selectedPeriod: .month, asOf: asOf)

        XCTAssertEqual(summary.savingsRemaining, 1_000, accuracy: 0.01)
        XCTAssertEqual(summary.savingsTimeToGoal?.days ?? 0, 20, accuracy: 0.01)
    }

    func test_savingsGoal_primaryActiveGoalBeatsAppSettingsFallback() {
        insertSettings(savingsGoalAmount: 5_000)
        insertSavingsGoal(name: "Primary", targetAmount: 1_200, currentAmount: 300)
        XCTAssertTrue(persistence.save())

        let summary = builder.build(selectedPeriod: .month, asOf: asOf)

        XCTAssertEqual(summary.savingsTargetAmount, 1_200, accuracy: 0.01)
        XCTAssertEqual(summary.savingsCurrentAmount, 300, accuracy: 0.01)
        XCTAssertEqual(summary.savingsRemaining, 900, accuracy: 0.01)
    }

    func test_savingsGoal_appSettingsFallbackUsedOnlyWhenNoActiveGoalExists() {
        insertSettings(savingsGoalAmount: 2_500)
        insertSavingsGoal(name: "Archived", targetAmount: 900, currentAmount: 100, isArchived: true)
        XCTAssertTrue(persistence.save())

        let summary = builder.build(selectedPeriod: .month, asOf: asOf)

        XCTAssertEqual(summary.savingsTargetAmount, 2_500, accuracy: 0.01)
        XCTAssertEqual(summary.savingsCurrentAmount, 0, accuracy: 0.01)
        XCTAssertEqual(summary.savingsRemaining, 2_500, accuracy: 0.01)
    }

    func test_savingsGoal_missingCurrentSavedAmountDefaultsToZero() {
        insertSettings(savingsGoalAmount: 5_000)
        let goal = SavingsGoal(context: context)
        goal.id = UUID()
        goal.name = "Emergency Fund"
        goal.targetAmount = 1_000
        goal.isArchived = false
        goal.createdAt = asOf
        XCTAssertTrue(persistence.save())

        let summary = builder.build(selectedPeriod: .month, asOf: asOf)

        XCTAssertEqual(summary.savingsTargetAmount, 1_000, accuracy: 0.01)
        XCTAssertEqual(summary.savingsCurrentAmount, 0, accuracy: 0.01)
        XCTAssertEqual(summary.savingsRemaining, 1_000, accuracy: 0.01)
    }

    func test_savingsGoal_completedGoalRemainingIsZero() {
        insertSettings(savingsGoalAmount: 5_000)
        insertSavingsGoal(
            name: "Completed",
            targetAmount: 1_000,
            currentAmount: 1_250,
            completedDate: asOf
        )
        XCTAssertTrue(persistence.save())

        let summary = builder.build(selectedPeriod: .month, asOf: asOf)

        XCTAssertEqual(summary.savingsTargetAmount, 1_000, accuracy: 0.01)
        XCTAssertEqual(summary.savingsCurrentAmount, 1_250, accuracy: 0.01)
        XCTAssertEqual(summary.savingsRemaining, 0, accuracy: 0.01)
        XCTAssertNil(summary.savingsTimeToGoal)
    }

    func test_savingsGoal_zeroOrNegativeNetPaceProducesNoETA() {
        insertSettings(savingsGoalAmount: 1_000)
        insertFinancialCategory(type: "income", frequency: "daily", amount: 25, name: "Income")
        insertFinancialCategory(type: "expense", frequency: "daily", amount: 50, name: "Expense")
        XCTAssertTrue(persistence.save())

        let summary = builder.build(selectedPeriod: .month, asOf: asOf)

        XCTAssertEqual(summary.savingsRemaining, 1_000, accuracy: 0.01)
        XCTAssertNil(summary.savingsTimeToGoal)
    }

    func test_savingsGoal_etaUsesRecurringPaceAndIgnoresOneTimeWindfall() {
        insertSettings(savingsGoalAmount: 1_000)
        insertFinancialCategory(type: "income", frequency: "daily", amount: 100, name: "Income")
        insertFinancialCategory(type: "expense", frequency: "daily", amount: 50, name: "Expense")
        insertOneTimeCategory(type: "income", amount: 10_000, name: "Bonus", occurrenceDate: asOf)
        XCTAssertTrue(persistence.save())

        let summary = builder.build(selectedPeriod: .month, asOf: asOf)

        XCTAssertEqual(summary.netPacePerDay, 50, accuracy: 0.01)
        XCTAssertEqual(summary.oneTimeIncomeInPeriod, 10_000, accuracy: 0.01)
        XCTAssertEqual(summary.savingsTimeToGoal?.days ?? 0, 20, accuracy: 0.01)
    }

    func test_savingsGoal_multipleActiveGoalsUseDeterministicPrimarySelection() {
        insertSettings(savingsGoalAmount: 5_000)
        insertSavingsGoal(
            name: "Later Low Priority",
            targetAmount: 900,
            currentAmount: 100,
            priority: 5,
            createdAt: asOf.addingTimeInterval(200)
        )
        insertSavingsGoal(
            name: "Earlier High Priority",
            targetAmount: 1_400,
            currentAmount: 400,
            priority: 1,
            createdAt: asOf.addingTimeInterval(300)
        )
        insertSavingsGoal(
            name: "Archived Highest Priority",
            targetAmount: 10_000,
            currentAmount: 9_000,
            priority: 0,
            createdAt: asOf,
            isArchived: true
        )
        XCTAssertTrue(persistence.save())

        let summary = builder.build(selectedPeriod: .month, asOf: asOf)

        XCTAssertEqual(summary.savingsTargetAmount, 1_400, accuracy: 0.01)
        XCTAssertEqual(summary.savingsCurrentAmount, 400, accuracy: 0.01)
        XCTAssertEqual(summary.savingsRemaining, 1_000, accuracy: 0.01)
    }

    func test_savingsGoal_primaryPrefersInProgressOverCompletedGoal() {
        insertSettings(savingsGoalAmount: 5_000)
        insertSavingsGoal(
            name: "Completed",
            targetAmount: 800,
            currentAmount: 800,
            priority: 0,
            createdAt: asOf,
            completedDate: asOf
        )
        insertSavingsGoal(
            name: "In Progress",
            targetAmount: 1_400,
            currentAmount: 200,
            priority: 5,
            createdAt: asOf.addingTimeInterval(200)
        )
        XCTAssertTrue(persistence.save())

        let summary = builder.build(selectedPeriod: .month, asOf: asOf)

        XCTAssertEqual(summary.savingsTargetAmount, 1_400, accuracy: 0.01)
        XCTAssertEqual(summary.savingsCurrentAmount, 200, accuracy: 0.01)
        XCTAssertEqual(summary.savingsRemaining, 1_200, accuracy: 0.01)
    }

    func test_savingsGoal_nilPriorityAndCreatedAtSortAfterDefinedMetadata() {
        insertSettings(savingsGoalAmount: 5_000)
        let defined = insertSavingsGoal(
            name: "Defined",
            targetAmount: 900,
            currentAmount: 100,
            priority: 0,
            createdAt: asOf
        )
        let nilMetadata = insertSavingsGoal(
            name: "Nil Metadata",
            targetAmount: 1_200,
            currentAmount: 100,
            priority: 5,
            createdAt: asOf.addingTimeInterval(200)
        )
        nilMetadata.setPrimitiveValue(nil, forKey: "priority")
        nilMetadata.createdAt = nil
        XCTAssertTrue(persistence.save())

        let summary = builder.build(selectedPeriod: .month, asOf: asOf)

        XCTAssertEqual(summary.savingsTargetAmount, defined.targetAmount, accuracy: 0.01)
        XCTAssertEqual(summary.savingsCurrentAmount, defined.currentAmount, accuracy: 0.01)
    }

    func test_biggestDrain_combinesRecurringAndOneTimePeriodExpenses() {
        insertSettings()
        insertFinancialCategory(type: "income", frequency: "daily", amount: 100, name: "Income")
        insertFinancialCategory(type: "expense", frequency: "monthly", amount: 500, name: "Rent")
        insertOneTimeCategory(type: "expense", amount: 800, name: "Repair", occurrenceDate: asOf)
        XCTAssertTrue(persistence.save())

        let summary = builder.build(selectedPeriod: .month, asOf: asOf)

        XCTAssertEqual(summary.biggestDrain?.categoryKey, "Repair")
        XCTAssertEqual(summary.biggestDrain?.amountInPeriod ?? 0, 800, accuracy: 0.01)
        XCTAssertEqual(summary.oneTimeExpenseInPeriod, 800, accuracy: 0.01)
    }

    func test_oneTimeEntriesDoNotAffectRecurringBaseline() {
        insertSettings()
        insertFinancialCategory(type: "income", frequency: "daily", amount: 100, name: "Income")
        insertFinancialCategory(type: "expense", frequency: "daily", amount: 40, name: "Expense")
        insertOneTimeCategory(type: "income", amount: 1_000, name: "Bonus", occurrenceDate: asOf)
        insertOneTimeCategory(type: "expense", amount: 200, name: "Repair", occurrenceDate: asOf)
        XCTAssertTrue(persistence.save())

        let summary = builder.build(selectedPeriod: .day, asOf: asOf)

        XCTAssertEqual(summary.netPacePerDay, 60, accuracy: 0.01)
        XCTAssertEqual(summary.oneTimeIncomeInPeriod, 1_000, accuracy: 0.01)
        XCTAssertEqual(summary.oneTimeExpenseInPeriod, 200, accuracy: 0.01)
        XCTAssertEqual(summary.netPeriodResult, 860, accuracy: 0.01)
    }

    // MARK: - Helpers

    private func makeInput(
        recurringIncomeLines: [RecurringMoneyLine] = [],
        recurringExpenseLines: [RecurringMoneyLine] = [],
        oneTimeIncomeLines: [OneTimeMoneyLine] = [],
        oneTimeExpenseLines: [OneTimeMoneyLine] = []
    ) -> FinancialSummaryInput {
        FinancialSummaryInput(
            currencyCode: "USD",
            asOf: asOf,
            selectedPeriod: .month,
            periodStart: asOf,
            periodEnd: asOf.addingTimeInterval(CalculationEngine.secondsPerDay * CalculationEngine.daysPerMonth),
            recurringIncomeLines: recurringIncomeLines,
            recurringExpenseLines: recurringExpenseLines,
            oneTimeIncomeLines: oneTimeIncomeLines,
            oneTimeExpenseLines: oneTimeExpenseLines,
            savingsTargetAmount: 0,
            savingsCurrentAmount: 0,
            cumulativeBaseline: 0,
            sessionElapsedSeconds: 0
        )
    }

    private func line(
        id: String,
        amount: Double,
        interval: CalculationEngine.RecurringInterval
    ) -> RecurringMoneyLine {
        RecurringMoneyLine(
            id: id,
            source: .category,
            categoryKey: id,
            label: id,
            amount: amount,
            interval: interval,
            isActive: true
        )
    }

    @discardableResult
    private func insertSettings(
        currencyCode: String = "USD",
        savingsGoalAmount: Double = 0
    ) -> AppSettings {
        let settings = AppSettings(context: context)
        settings.preferredCurrencyCode = currencyCode
        settings.savingsGoalAmount = savingsGoalAmount
        settings.cumulativeTotal = 0
        return settings
    }

    @discardableResult
    private func insertFinancialCategory(
        type: String,
        frequency: String,
        amount: Double,
        name: String
    ) -> FinancialCategory {
        let category = FinancialCategory(context: context)
        category.id = UUID()
        category.type = type
        category.frequency = frequency
        category.amount = amount
        category.customName = name
        category.uniqueID = name
        category.entryKind = "recurring"
        category.isActive = true
        category.createdAt = asOf
        return category
    }

    @discardableResult
    private func insertOneTimeCategory(
        type: String,
        amount: Double,
        name: String,
        occurrenceDate: Date
    ) -> FinancialCategory {
        let category = insertFinancialCategory(
            type: type,
            frequency: "once",
            amount: amount,
            name: name
        )
        category.entryKind = "oneTime"
        category.occurrenceDate = occurrenceDate
        return category
    }

    @discardableResult
    private func insertSubscription(
        name: String,
        amount: Double,
        billingCycle: String,
        category: String
    ) -> Subscription {
        let subscription = Subscription(context: context)
        subscription.id = UUID()
        subscription.name = name
        subscription.amount = amount
        subscription.billingCycle = billingCycle
        subscription.category = category
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
        frequency: String,
        category: String
    ) -> Bill {
        let bill = Bill(context: context)
        bill.id = UUID()
        bill.name = name
        bill.amount = amount
        bill.frequency = frequency
        bill.category = category
        bill.isRecurring = true
        bill.isPaid = false
        bill.dueDate = asOf
        return bill
    }

    @discardableResult
    private func insertSavingsGoal(
        name: String,
        targetAmount: Double,
        currentAmount: Double,
        priority: Int16 = 0,
        createdAt: Date? = nil,
        completedDate: Date? = nil,
        isArchived: Bool = false
    ) -> SavingsGoal {
        let goal = SavingsGoal(context: context)
        goal.id = UUID()
        goal.name = name
        goal.targetAmount = targetAmount
        goal.currentAmount = currentAmount
        goal.priority = priority
        goal.createdAt = createdAt ?? asOf
        goal.completedDate = completedDate
        goal.isArchived = isArchived
        return goal
    }
}
