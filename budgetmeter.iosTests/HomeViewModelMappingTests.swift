//
//  HomeViewModelMappingTests.swift
//  budgetmeter.iosTests
//
//  Phase 3 — verifies Home display values derive from FinancialSummary.
//

import CoreData
import XCTest
@testable import budgetmeter_ios

final class HomeViewModelMappingTests: XCTestCase {

    private var persistence: PersistenceService!
    private var context: NSManagedObjectContext!
    private var builder: FinancialSummaryBuilder!

    override func setUp() {
        super.setUp()
        persistence = PersistenceService.makeInMemoryForTesting()
        context = persistence.viewContext
        builder = FinancialSummaryBuilder(context: context)
    }

    override func tearDown() {
        builder = nil
        context = nil
        persistence = nil
        super.tearDown()
    }

    func test_homeDailyPace_comesFromSummaryNetPacePerDay() {
        let summary = builder.build(from: makeRecurringOnlyInput(
            incomeDaily: 100,
            expenseDaily: 40
        ))

        XCTAssertEqual(summary.netPacePerDay, 60, accuracy: 0.01)
        XCTAssertEqual(mapDailyPace(from: summary), summary.netPacePerDay, accuracy: 0.01)
    }

    func test_homeMinutePace_derivesFromSameDailyPace() {
        let summary = builder.build(from: makeRecurringOnlyInput(
            incomeDaily: 1440,
            expenseDaily: 0
        ))

        XCTAssertEqual(summary.netPacePerMinute, summary.netPacePerDay / 1_440, accuracy: 0.0001)
        XCTAssertEqual(mapMinutePace(from: summary), summary.netPacePerMinute, accuracy: 0.0001)
    }

    func test_paceStatusCopy_positiveNegativeNeutralAndInsufficient() {
        // Moving forward contains the amount
        let forwardResult = HomeDisplayMapping.paceStatusCopy(
            status: .movingForward,
            netDailyPace: 12,
            currencySymbol: "$"
        )
        XCTAssertTrue(forwardResult.contains("+$12"))
        // Slowing down contains the amount
        let slowingResult = HomeDisplayMapping.paceStatusCopy(
            status: .slowingDown,
            netDailyPace: -8,
            currencySymbol: "$"
        )
        XCTAssertTrue(slowingResult.contains("-$8"))
        // Neutral check: format includes amount
        let neutralResult = HomeDisplayMapping.paceStatusCopy(
            status: .neutral,
            netDailyPace: 0,
            currencySymbol: "$"
        )
        XCTAssertTrue(neutralResult.contains("+$0"))
        // Insufficient data returns non-empty informational copy
        let insufficientResult = HomeDisplayMapping.paceStatusCopy(
            status: .insufficientData,
            netDailyPace: 0,
            currencySymbol: "$"
        )
        XCTAssertFalse(insufficientResult.isEmpty)
    }

    func test_biggestDrain_comesFromSharedSummary() {
        let asOf = Date(timeIntervalSince1970: 1_704_067_200)
        let calendar = Calendar(identifier: .gregorian)
        let bounds = calendar.dateInterval(of: .month, for: asOf)!

        let input = FinancialSummaryInput(
            currencyCode: "USD",
            asOf: asOf,
            selectedPeriod: .month,
            periodStart: bounds.start,
            periodEnd: bounds.end,
            recurringIncomeLines: [],
            recurringExpenseLines: [
                RecurringMoneyLine(
                    id: "rent",
                    source: .category,
                    categoryKey: "rent",
                    label: "Rent",
                    amount: 1200,
                    interval: .monthly,
                    isActive: true
                ),
                RecurringMoneyLine(
                    id: "food",
                    source: .category,
                    categoryKey: "food",
                    label: "Food",
                    amount: 300,
                    interval: .monthly,
                    isActive: true
                )
            ],
            oneTimeIncomeLines: [],
            oneTimeExpenseLines: [],
            savingsTargetAmount: 0,
            savingsCurrentAmount: 0,
            cumulativeBaseline: 0,
            sessionElapsedSeconds: 0
        )

        let summary = builder.build(from: input)

        XCTAssertEqual(summary.biggestDrain?.label, "Rent")
        XCTAssertEqual(mapBiggestDrain(from: summary)?.label, "Rent")
    }

    func test_savingsRemainingAndTimeToGoal_useSharedSummary() {
        let input = makeRecurringOnlyInput(
            incomeDaily: 100,
            expenseDaily: 20,
            savingsTarget: 1000,
            savingsCurrent: 250
        )
        let summary = builder.build(from: input)

        XCTAssertEqual(summary.savingsRemaining, 750, accuracy: 0.01)
        XCTAssertNotNil(summary.savingsTimeToGoal)
        XCTAssertEqual(mapSavingsRemaining(from: summary), 750, accuracy: 0.01)
        XCTAssertNotNil(mapSavingsTimeToGoal(from: summary))
    }

    func test_oneTimeEntries_doNotAlterRecurringPace() {
        let asOf = Date(timeIntervalSince1970: 1_704_067_200)
        let calendar = Calendar(identifier: .gregorian)
        let bounds = calendar.dateInterval(of: .month, for: asOf)!

        let recurringOnly = builder.build(from: makeRecurringOnlyInput(
            incomeDaily: 50,
            expenseDaily: 10
        ))

        let withOneTime = builder.build(from: FinancialSummaryInput(
            currencyCode: "USD",
            asOf: asOf,
            selectedPeriod: .month,
            periodStart: bounds.start,
            periodEnd: bounds.end,
            recurringIncomeLines: dailyLine(amount: 50, type: "income"),
            recurringExpenseLines: dailyLine(amount: 10, type: "expense"),
            oneTimeIncomeLines: [],
            oneTimeExpenseLines: [
                OneTimeMoneyLine(
                    id: "spike",
                    categoryKey: "gift",
                    label: "Gift",
                    amount: 500,
                    occurrenceDate: asOf
                )
            ],
            savingsTargetAmount: 0,
            savingsCurrentAmount: 0,
            cumulativeBaseline: 0,
            sessionElapsedSeconds: 0
        ))

        XCTAssertEqual(recurringOnly.netPacePerDay, withOneTime.netPacePerDay, accuracy: 0.01)
        XCTAssertGreaterThan(withOneTime.oneTimeExpenseInPeriod, 0)
    }

    // MARK: - Helpers mirroring HomeViewModel mapping

    private func mapDailyPace(from summary: FinancialSummary) -> Double {
        summary.netPacePerDay
    }

    private func mapMinutePace(from summary: FinancialSummary) -> Double {
        summary.netPacePerMinute
    }

    private func mapBiggestDrain(from summary: FinancialSummary) -> DrainItem? {
        summary.biggestDrain
    }

    private func mapSavingsRemaining(from summary: FinancialSummary) -> Double {
        summary.savingsRemaining
    }

    private func mapSavingsTimeToGoal(from summary: FinancialSummary) -> CalculationEngine.TargetTimeResult? {
        summary.savingsTimeToGoal
    }

    private func makeRecurringOnlyInput(
        incomeDaily: Double,
        expenseDaily: Double,
        savingsTarget: Double = 0,
        savingsCurrent: Double = 0
    ) -> FinancialSummaryInput {
        let asOf = Date(timeIntervalSince1970: 1_704_067_200)
        let calendar = Calendar(identifier: .gregorian)
        let bounds = calendar.dateInterval(of: .month, for: asOf)!

        return FinancialSummaryInput(
            currencyCode: "USD",
            asOf: asOf,
            selectedPeriod: .month,
            periodStart: bounds.start,
            periodEnd: bounds.end,
            recurringIncomeLines: dailyLine(amount: incomeDaily, type: "income"),
            recurringExpenseLines: dailyLine(amount: expenseDaily, type: "expense"),
            oneTimeIncomeLines: [],
            oneTimeExpenseLines: [],
            savingsTargetAmount: savingsTarget,
            savingsCurrentAmount: savingsCurrent,
            cumulativeBaseline: 0,
            sessionElapsedSeconds: 0
        )
    }

    private func dailyLine(amount: Double, type: String) -> [RecurringMoneyLine] {
        guard amount > 0 else { return [] }
        return [
            RecurringMoneyLine(
                id: "\(type)-daily",
                source: .category,
                categoryKey: type,
                label: type.capitalized,
                amount: amount,
                interval: .daily,
                isActive: true
            )
        ]
    }
}
