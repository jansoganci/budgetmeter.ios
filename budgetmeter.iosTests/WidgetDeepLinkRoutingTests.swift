//
//  WidgetDeepLinkRoutingTests.swift
//  budgetmeter.iosTests
//
//  Phase 8 — widget deep link contract tests.
//

import CoreData
import XCTest
@testable import budgetmeter_ios

final class WidgetDeepLinkRoutingTests: XCTestCase {

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

    func test_lockedTeaserDeepLink_matchesPaywallRoute() {
        XCTAssertEqual(WidgetConstants.lockedDeepLink, "budgetmeter://premium/widgets")

        let url = URL(string: WidgetConstants.lockedDeepLink)
        XCTAssertNotNil(url)
        XCTAssertEqual(url?.scheme, "budgetmeter")
        XCTAssertEqual(url?.host, "premium")
        XCTAssertEqual(url?.path, "/widgets")
    }

    func test_unlockedDeepLink_matchesHomeHeroRoute() {
        XCTAssertEqual(WidgetConstants.unlockedDeepLink, "budgetmeter://home/hero")

        let url = URL(string: WidgetConstants.unlockedDeepLink)
        XCTAssertNotNil(url)
        XCTAssertEqual(url?.scheme, "budgetmeter")
        XCTAssertEqual(url?.host, "home")
        XCTAssertEqual(url?.path, "/hero")
    }

    func test_writer_lockedSnapshot_usesLockedDeepLink() {
        let summary = builder.build(from: makeRecurringOnlyInput(
            incomeDaily: 100,
            expenseDaily: 40
        ))

        let snapshot = WidgetSnapshotWriter.makeSnapshot(
            from: summary,
            isPremium: false,
            currencySymbol: "$"
        )

        XCTAssertEqual(snapshot.deepLinkURL, WidgetConstants.lockedDeepLink)
        XCTAssertTrue(snapshot.isLockedTeaser)
        XCTAssertEqual(snapshot.displayState, .lockedTeaser)
    }

    func test_writer_unlockedSnapshot_usesUnlockedDeepLink() {
        let summary = builder.build(from: makeRecurringOnlyInput(
            incomeDaily: 100,
            expenseDaily: 40
        ))

        let snapshot = WidgetSnapshotWriter.makeSnapshot(
            from: summary,
            isPremium: true,
            currencySymbol: "$"
        )

        XCTAssertEqual(snapshot.deepLinkURL, WidgetConstants.unlockedDeepLink)
        XCTAssertFalse(snapshot.isLockedTeaser)
        XCTAssertEqual(snapshot.displayState, .unlocked)
    }

    func test_deepLinkURLs_areWellFormedBudgetMeterURLs() {
        let links = [
            WidgetConstants.lockedDeepLink,
            WidgetConstants.unlockedDeepLink
        ]

        for link in links {
            let url = URL(string: link)
            XCTAssertNotNil(url, "Expected valid URL for \(link)")
            XCTAssertEqual(url?.scheme, "budgetmeter")
            XCTAssertFalse(url?.host?.isEmpty ?? true)
        }
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
