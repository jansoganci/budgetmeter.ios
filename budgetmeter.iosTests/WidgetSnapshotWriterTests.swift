//
//  WidgetSnapshotWriterTests.swift
//  budgetmeter.iosTests
//
//  Phase 8 — widget snapshot writer mapping tests.
//

import CoreData
import XCTest
@testable import budgetmeter_ios

final class WidgetSnapshotWriterTests: XCTestCase {

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

    func test_writer_mapsNetDailyPaceAndPaceStatus() {
        let summary = builder.build(from: makeRecurringOnlyInput(
            incomeDaily: 100,
            expenseDaily: 40
        ))

        let snapshot = WidgetSnapshotWriter.makeSnapshot(
            from: summary,
            isPremium: true,
            currencySymbol: "$"
        )

        XCTAssertEqual(snapshot.netDailyPace, summary.netPacePerDay, accuracy: 0.01)
        XCTAssertEqual(snapshot.paceStatus, "movingForward")
        XCTAssertEqual(snapshot.displayState, .unlocked)
        XCTAssertFalse(snapshot.isLockedTeaser)
    }

    func test_writer_usesHomeDisplayMappingCopy() {
        let summary = builder.build(from: makeRecurringOnlyInput(
            incomeDaily: 100,
            expenseDaily: 40
        ))

        let snapshot = WidgetSnapshotWriter.makeSnapshot(
            from: summary,
            isPremium: true,
            currencySymbol: "$"
        )

        let expected = HomeDisplayMapping.paceStatusCopy(
            status: summary.paceStatus,
            netDailyPace: summary.netPacePerDay,
            currencySymbol: "$"
        )

        XCTAssertEqual(snapshot.displayStatusCopy, expected)
        // Display value should contain the currency symbol
        XCTAssertTrue(snapshot.displayValue.contains("$"))
    }

    func test_writer_lockedTeaserForNonPremium() {
        let summary = builder.build(from: makeRecurringOnlyInput(
            incomeDaily: 100,
            expenseDaily: 40
        ))

        let snapshot = WidgetSnapshotWriter.makeSnapshot(
            from: summary,
            isPremium: false,
            currencySymbol: "$"
        )

        XCTAssertTrue(snapshot.isLockedTeaser)
        XCTAssertEqual(snapshot.displayState, .lockedTeaser)
        XCTAssertEqual(snapshot.deepLinkURL, WidgetConstants.lockedDeepLink)
        XCTAssertFalse(snapshot.isPremium)
        XCTAssertEqual(snapshot.netDailyPace, 0)
        XCTAssertEqual(snapshot.displayValue, "")
        XCTAssertEqual(snapshot.displayStatusCopy, "")
        XCTAssertEqual(snapshot.currencyCode, "")
        XCTAssertEqual(snapshot.currencySymbol, "")
        XCTAssertFalse(snapshot.hasFinancialInput)
        XCTAssertEqual(snapshot.paceStatus, "insufficientData")
    }

    func test_writer_insufficientDataWhenNoFinancialInput() {
        let summary = builder.build(from: FinancialSummaryInput(
            currencyCode: "USD",
            asOf: Date(),
            selectedPeriod: .day,
            periodStart: Date(),
            periodEnd: Date(),
            recurringIncomeLines: [],
            recurringExpenseLines: [],
            oneTimeIncomeLines: [],
            oneTimeExpenseLines: [],
            savingsTargetAmount: 0,
            savingsCurrentAmount: 0,
            cumulativeBaseline: 0,
            sessionElapsedSeconds: 0
        ))

        let snapshot = WidgetSnapshotWriter.makeSnapshot(
            from: summary,
            isPremium: true,
            currencySymbol: "$"
        )

        XCTAssertFalse(snapshot.hasFinancialInput)
        XCTAssertEqual(snapshot.displayState, .insufficientData)
    }

    func test_writer_setsStaleAfterFromGeneratedAt() {
        let generatedAt = Date(timeIntervalSince1970: 2_000)
        let summary = builder.build(from: makeRecurringOnlyInput(
            incomeDaily: 50,
            expenseDaily: 10
        ))

        let snapshot = WidgetSnapshotWriter.makeSnapshot(
            from: summary,
            isPremium: true,
            currencySymbol: "$",
            generatedAt: generatedAt
        )

        XCTAssertEqual(
            snapshot.staleAfter.timeIntervalSince1970,
            generatedAt.addingTimeInterval(WidgetConstants.staleInterval).timeIntervalSince1970,
            accuracy: 0.5
        )
    }

    private func makeRecurringOnlyInput(
        incomeDaily: Double,
        expenseDaily: Double
    ) -> FinancialSummaryInput {
        FinancialSummaryInput(
            currencyCode: "USD",
            asOf: Date(),
            selectedPeriod: .day,
            periodStart: Date(),
            periodEnd: Date(),
            recurringIncomeLines: incomeDaily > 0 ? [
                RecurringMoneyLine(
                    id: "income-1",
                    source: .category,
                    categoryKey: "salary",
                    label: "Salary",
                    amount: incomeDaily,
                    interval: .daily,
                    isActive: true
                )
            ] : [],
            recurringExpenseLines: expenseDaily > 0 ? [
                RecurringMoneyLine(
                    id: "expense-1",
                    source: .category,
                    categoryKey: "rent",
                    label: "Rent",
                    amount: expenseDaily,
                    interval: .daily,
                    isActive: true
                )
            ] : [],
            oneTimeIncomeLines: [],
            oneTimeExpenseLines: [],
            savingsTargetAmount: 0,
            savingsCurrentAmount: 0,
            cumulativeBaseline: 0,
            sessionElapsedSeconds: 0
        )
    }
}
