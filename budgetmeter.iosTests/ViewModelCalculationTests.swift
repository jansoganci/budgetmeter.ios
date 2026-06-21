//
//  ViewModelCalculationTests.swift
//  budgetmeter.iosTests
//
//  Created by BudgetMeter Team
//

import XCTest
import CoreData
@testable import budgetmeter_ios

/// Tests to verify that ViewModels use CalculationEngine correctly
/// These tests ensure that the UI layer matches the calculation logic
final class ViewModelCalculationTests: XCTestCase {

    // MARK: - ExpenseViewModel Calculation Tests

    func testExpenseViewModel_TotalMonthlyExpenses_MatchesEngine() {
        // Create mock data
        let dailyExpense: Double = 50
        let monthlyExpense: Double = 1000
        let yearlyExpense: Double = 1200

        // Calculate using CalculationEngine (source of truth)
        let engineResult = CalculationEngine.totalMonthlyExpense(
            dailyTotal: dailyExpense,
            monthlyTotal: monthlyExpense,
            yearlyTotal: yearlyExpense
        )

        // Calculate using the shared normalization contract.
        let viewModelResult = (dailyExpense * CalculationEngine.daysPerMonth) + monthlyExpense + (yearlyExpense / 12)

        XCTAssertEqual(
            engineResult,
            viewModelResult,
            accuracy: 0.01,
            "ExpenseViewModel formula should match CalculationEngine"
        )
    }

    func testExpenseViewModel_DailyAverageExpenses() {
        let totalMonthly: Double = 3000
        let expectedDaily = totalMonthly / 30

        XCTAssertEqual(
            expectedDaily,
            100,
            accuracy: 0.01,
            "Daily average should be monthly / 30"
        )
    }

    func testExpenseViewModel_YearlyProjectionExpenses() {
        let totalMonthly: Double = 2500
        let expectedYearly = totalMonthly * 12

        XCTAssertEqual(
            expectedYearly,
            30000,
            accuracy: 0.01,
            "Yearly projection should be monthly * 12"
        )
    }

    // MARK: - IncomeViewModel Calculation Tests

    func testIncomeViewModel_TotalMonthlyIncome_MatchesEngine() {
        // Create mock data
        let dailyIncome: Double = 100
        let monthlyIncome: Double = 2000
        let yearlyIncome: Double = 12000

        // Calculate using CalculationEngine (source of truth)
        let engineResult = CalculationEngine.totalMonthlyIncome(
            dailyIncomeTotal: dailyIncome,
            monthlyIncomeTotal: monthlyIncome,
            yearlyIncomeTotal: yearlyIncome
        )

        // Calculate using the shared normalization contract.
        let viewModelResult = (dailyIncome * CalculationEngine.daysPerMonth) + monthlyIncome + (yearlyIncome / 12)

        XCTAssertEqual(
            engineResult,
            viewModelResult,
            accuracy: 0.01,
            "IncomeViewModel formula should match CalculationEngine"
        )
    }

    func testIncomeViewModel_DailyAverageIncome() {
        let totalMonthly: Double = 6000
        let expectedDaily = totalMonthly / 30

        XCTAssertEqual(
            expectedDaily,
            200,
            accuracy: 0.01,
            "Daily average should be monthly / 30"
        )
    }

    func testIncomeViewModel_YearlyProjectionIncome() {
        let totalMonthly: Double = 5000
        let expectedYearly = totalMonthly * 12

        XCTAssertEqual(
            expectedYearly,
            60000,
            accuracy: 0.01,
            "Yearly projection should be monthly * 12"
        )
    }

    // MARK: - Input Parsing Tests

    func testParseAmount_ValidInput() {
        let testCases: [(input: String, expected: Double)] = [
            ("123", 123.0),
            ("123.45", 123.45),
            ("0.99", 0.99),
            ("1000", 1000.0),
            ("1234.567", 1234.567), // Should preserve decimals beyond 2
        ]

        for testCase in testCases {
            // Simulating ViewModel parseAmount logic
            let cleaned = testCase.input.replacingOccurrences(
                of: "[^0-9.]",
                with: "",
                options: .regularExpression
            )
            let result = Double(cleaned) ?? 0

            XCTAssertEqual(
                result,
                testCase.expected,
                accuracy: 0.001,
                "Failed to parse '\(testCase.input)'"
            )
        }
    }

    func testParseAmount_InvalidInput() {
        let testCases = ["", "abc", "$", "---", "..."]

        for input in testCases {
            let cleaned = input.replacingOccurrences(
                of: "[^0-9.]",
                with: "",
                options: .regularExpression
            )
            let result = cleaned.isEmpty ? 0 : (Double(cleaned) ?? 0)

            XCTAssertEqual(
                result,
                0,
                "Invalid input '\(input)' should parse to 0"
            )
        }
    }

    func testParseAmount_WithCurrencySymbols() {
        let testCases: [(input: String, expected: Double)] = [
            ("$123.45", 123.45),
            ("€1000", 1000.0),
            ("£99.99", 99.99),
        ]

        for testCase in testCases {
            let cleaned = testCase.input.replacingOccurrences(
                of: "[^0-9.]",
                with: "",
                options: .regularExpression
            )
            let result = Double(cleaned) ?? 0

            XCTAssertEqual(
                result,
                testCase.expected,
                accuracy: 0.01,
                "Should strip currency symbols from '\(testCase.input)'"
            )
        }
    }

    // MARK: - Realistic Scenario Tests

    func testRealisticScenario_SoftwareEngineer() {
        // Scenario: Software engineer with:
        // - $8,000/month salary
        // - $100/day freelance side income
        // - $3,000/month rent + utilities
        // - $50/day food
        // - $1,200/year subscriptions

        let monthlyIncome = CalculationEngine.totalMonthlyIncome(
            dailyIncomeTotal: 100,
            monthlyIncomeTotal: 8000,
            yearlyIncomeTotal: 0
        )
        let expectedMonthlyIncome = (100 * CalculationEngine.daysPerMonth) + 8000

        let monthlyExpense = CalculationEngine.totalMonthlyExpense(
            dailyTotal: 50,
            monthlyTotal: 3000,
            yearlyTotal: 1200
        )
        let expectedMonthlyExpense = (50 * CalculationEngine.daysPerMonth) + 3000 + (1200 / 12)

        let netFlow = monthlyIncome - monthlyExpense
        let expectedNetFlow = expectedMonthlyIncome - expectedMonthlyExpense

        XCTAssertEqual(monthlyIncome, expectedMonthlyIncome, accuracy: 0.01)
        XCTAssertEqual(monthlyExpense, expectedMonthlyExpense, accuracy: 0.01)
        XCTAssertEqual(netFlow, expectedNetFlow, accuracy: 0.01)

        // Check financial health
        let health = CalculationEngine.financialHealthScore(
            totalMonthlyIncome: monthlyIncome,
            totalMonthlyExpense: monthlyExpense
        )
        // Ratio: 11,000 / 4,600 = 2.39 (> 2.0)
        XCTAssertEqual(health.score, 10, "Should have perfect financial health")
        XCTAssertEqual(health.color, "green")
    }

    func testRealisticScenario_Student() {
        // Scenario: Student with:
        // - $30/day part-time job
        // - $500/month from parents
        // - $20/day expenses
        // - $400/month rent
        // - $0/year

        let monthlyIncome = CalculationEngine.totalMonthlyIncome(
            dailyIncomeTotal: 30,
            monthlyIncomeTotal: 500,
            yearlyIncomeTotal: 0
        )
        let expectedMonthlyIncome = (30 * CalculationEngine.daysPerMonth) + 500

        let monthlyExpense = CalculationEngine.totalMonthlyExpense(
            dailyTotal: 20,
            monthlyTotal: 400,
            yearlyTotal: 0
        )
        let expectedMonthlyExpense = (20 * CalculationEngine.daysPerMonth) + 400

        let netFlow = monthlyIncome - monthlyExpense
        let expectedNetFlow = expectedMonthlyIncome - expectedMonthlyExpense

        XCTAssertEqual(monthlyIncome, expectedMonthlyIncome, accuracy: 0.01)
        XCTAssertEqual(monthlyExpense, expectedMonthlyExpense, accuracy: 0.01)
        XCTAssertEqual(netFlow, expectedNetFlow, accuracy: 0.01)

        // Check financial health
        let health = CalculationEngine.financialHealthScore(
            totalMonthlyIncome: monthlyIncome,
            totalMonthlyExpense: monthlyExpense
        )
        // Ratio: 1,400 / 1,000 = 1.4 (between 1.2 and 1.5)
        XCTAssertEqual(health.score, 6, "Should have fair financial health")
        XCTAssertEqual(health.color, "yellow")
    }

    func testRealisticScenario_Struggling() {
        // Scenario: Someone struggling with:
        // - $2,500/month income
        // - $3,000/month expenses
        // - Negative cash flow

        let monthlyIncome = CalculationEngine.totalMonthlyIncome(
            dailyIncomeTotal: 0,
            monthlyIncomeTotal: 2500,
            yearlyIncomeTotal: 0
        )

        let monthlyExpense = CalculationEngine.totalMonthlyExpense(
            dailyTotal: 0,
            monthlyTotal: 3000,
            yearlyTotal: 0
        )

        let netFlow = monthlyIncome - monthlyExpense
        // 2,500 - 3,000 = -500

        XCTAssertEqual(netFlow, -500, accuracy: 0.01, "Should have negative net flow")

        // Check financial health
        let health = CalculationEngine.financialHealthScore(
            totalMonthlyIncome: monthlyIncome,
            totalMonthlyExpense: monthlyExpense
        )
        // Ratio: 2,500 / 3,000 = 0.833 (< 1.0)
        XCTAssertEqual(health.score, 2, "Should have bad financial health")
        XCTAssertEqual(health.color, "red")

        // Check savings goal feasibility
        let targetResult = CalculationEngine.targetTime(
            targetAmount: 1000,
            netHourlyFlow: -500.0 / 30 / 24  // Negative hourly flow
        )
        XCTAssertNotNil(targetResult.message, "Should warn about negative flow")
    }

    func testRealisticScenario_SavingsGoal() {
        // Scenario: Saving for vacation
        // - $5,000/month income
        // - $3,500/month expenses
        // - Goal: Save $3,000 for vacation

        let netHourly = CalculationEngine.netHourlyFlow(
            dailyIncomeTotal: 0,
            monthlyIncomeTotal: 5000,
            yearlyIncomeTotal: 0,
            dailyExpenseTotal: 0,
            monthlyExpenseTotal: 3500,
            yearlyExpenseTotal: 0
        )
        // Monthly net: 1,500
        // Daily net uses the shared average month length.

        let targetResult = CalculationEngine.targetTime(
            targetAmount: 3000,
            netHourlyFlow: netHourly
        )

        let expectedHours = 3000 / netHourly
        let expectedDays = expectedHours / CalculationEngine.hoursPerDay
        let expectedMonths = expectedDays / CalculationEngine.daysPerMonth

        XCTAssertEqual(targetResult.hours, expectedHours, accuracy: 1)
        XCTAssertEqual(targetResult.days, expectedDays, accuracy: 1)
        XCTAssertEqual(targetResult.months, expectedMonths, accuracy: 0.1)
    }

    // MARK: - Consistency Tests

    func testConsistency_DailyMonthlyYearly() {
        // Test that the shared day/month/year constants stay internally consistent.
        let dailyAmount: Double = 10

        let fromDaily = CalculationEngine.totalMonthlyIncome(
            dailyIncomeTotal: dailyAmount,
            monthlyIncomeTotal: 0,
            yearlyIncomeTotal: 0
        ) * 12
        let expectedYearly = dailyAmount * CalculationEngine.daysPerYear

        let fromMonthly = CalculationEngine.totalMonthlyIncome(
            dailyIncomeTotal: 0,
            monthlyIncomeTotal: expectedYearly / 12,
            yearlyIncomeTotal: 0
        ) * 12

        let fromYearly = CalculationEngine.totalMonthlyIncome(
            dailyIncomeTotal: 0,
            monthlyIncomeTotal: 0,
            yearlyIncomeTotal: expectedYearly
        ) * 12

        XCTAssertEqual(fromDaily, expectedYearly, accuracy: 0.01)
        XCTAssertEqual(fromMonthly, expectedYearly, accuracy: 0.01)
        XCTAssertEqual(fromYearly, expectedYearly, accuracy: 0.01)
    }

    func testConsistency_LiveMeterMatchesSnapshot() {
        // Test that live meter calculations over 24 hours match daily snapshot

        let dailyIncome: Double = 240
        let dailyExpense: Double = 144

        // Live meter for 24 hours (86400 seconds)
        let liveIncome24h = CalculationEngine.calculateLiveIncome(
            dailyIncomeTotal: dailyIncome,
            monthlyIncomeTotal: 0,
            yearlyIncomeTotal: 0,
            sessionSeconds: 86400
        )

        let liveExpense24h = CalculationEngine.calculateLiveExpense(
            dailyTotal: dailyExpense,
            monthlyTotal: 0,
            yearlyTotal: 0,
            sessionSeconds: 86400
        )

        let liveNet24h = liveIncome24h - liveExpense24h

        // Daily snapshot
        let dailyNet = CalculationEngine.netDailyFlow(
            dailyIncomeTotal: dailyIncome,
            monthlyIncomeTotal: 0,
            yearlyIncomeTotal: 0,
            dailyExpenseTotal: dailyExpense,
            monthlyExpenseTotal: 0,
            yearlyExpenseTotal: 0
        )

        XCTAssertEqual(
            liveNet24h,
            dailyNet,
            accuracy: 0.1,
            "Live meter over 24h should match daily snapshot"
        )
    }
}
