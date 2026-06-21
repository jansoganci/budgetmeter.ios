//
//  CalculationEngineTests.swift
//  budgetmeter.iosTests
//
//  Created by BudgetMeter Team
//

import XCTest
@testable import budgetmeter_ios

/// Comprehensive unit tests for CalculationEngine
/// Tests all financial calculation formulas to ensure accuracy
final class CalculationEngineTests: XCTestCase {

    // MARK: - Monthly Expense Calculations

    func testTotalMonthlyExpense_AllZero() {
        let result = CalculationEngine.totalMonthlyExpense(
            dailyTotal: 0,
            monthlyTotal: 0,
            yearlyTotal: 0
        )
        XCTAssertEqual(result, 0, accuracy: 0.01, "Zero inputs should return zero")
    }

    func testTotalMonthlyExpense_OnlyDaily() {
        // $10/day should normalize through the shared average month length.
        let result = CalculationEngine.totalMonthlyExpense(
            dailyTotal: 10,
            monthlyTotal: 0,
            yearlyTotal: 0
        )
        XCTAssertEqual(result, 10 * CalculationEngine.daysPerMonth, accuracy: 0.01, "Daily normalization should use the shared month length")
    }

    func testTotalMonthlyExpense_OnlyMonthly() {
        let result = CalculationEngine.totalMonthlyExpense(
            dailyTotal: 0,
            monthlyTotal: 500,
            yearlyTotal: 0
        )
        XCTAssertEqual(result, 500, accuracy: 0.01, "Monthly should pass through directly")
    }

    func testTotalMonthlyExpense_OnlyYearly() {
        // $1200/year should equal $100/month (1200 / 12)
        let result = CalculationEngine.totalMonthlyExpense(
            dailyTotal: 0,
            monthlyTotal: 0,
            yearlyTotal: 1200
        )
        XCTAssertEqual(result, 100, accuracy: 0.01, "Yearly / 12 should equal monthly")
    }

    func testTotalMonthlyExpense_Mixed() {
        // Daily uses the shared average month length.
        // Monthly: $1000
        // Yearly: $1200 / 12 = $100
        let expected = (50 * CalculationEngine.daysPerMonth) + 1000 + (1200 / 12)
        let result = CalculationEngine.totalMonthlyExpense(
            dailyTotal: 50,
            monthlyTotal: 1000,
            yearlyTotal: 1200
        )
        XCTAssertEqual(result, expected, accuracy: 0.01, "Mixed frequencies should sum correctly")
    }

    func testTotalMonthlyExpense_WithDecimals() {
        // Test precision with decimal values
        let result = CalculationEngine.totalMonthlyExpense(
            dailyTotal: 33.33,
            monthlyTotal: 125.50,
            yearlyTotal: 999.99
        )
        let expected = (33.33 * CalculationEngine.daysPerMonth) + 125.50 + (999.99 / 12)
        XCTAssertEqual(result, expected, accuracy: 0.01, "Decimal calculations should be precise")
    }

    // MARK: - Daily Expense Calculations

    func testDailyExpenseTotal_AllZero() {
        let result = CalculationEngine.dailyExpenseTotal(
            dailyTotal: 0,
            monthlyTotal: 0,
            yearlyTotal: 0
        )
        XCTAssertEqual(result, 0, accuracy: 0.01)
    }

    func testDailyExpenseTotal_OnlyDaily() {
        let result = CalculationEngine.dailyExpenseTotal(
            dailyTotal: 100,
            monthlyTotal: 0,
            yearlyTotal: 0
        )
        XCTAssertEqual(result, 100, accuracy: 0.01, "Daily should pass through")
    }

    func testDailyExpenseTotal_Mixed() {
        // Daily: $50
        // Monthly and yearly use shared average period lengths.
        let result = CalculationEngine.dailyExpenseTotal(
            dailyTotal: 50,
            monthlyTotal: 900,
            yearlyTotal: 3650
        )
        let expected = 50 + (900 / CalculationEngine.daysPerMonth) + (3650 / CalculationEngine.daysPerYear)
        XCTAssertEqual(result, expected, accuracy: 0.01, "Daily conversion should be accurate")
    }

    // MARK: - Hourly Expense Calculations

    func testHourlyExpense_Basic() {
        // $24/day = $1/hour
        let result = CalculationEngine.hourlyExpense(
            dailyTotal: 24,
            monthlyTotal: 0,
            yearlyTotal: 0
        )
        XCTAssertEqual(result, 1, accuracy: 0.01, "24/day should equal 1/hour")
    }

    func testHourlyExpense_FromMonthly() {
        // $900/month normalizes through the shared average month length.
        let result = CalculationEngine.hourlyExpense(
            dailyTotal: 0,
            monthlyTotal: 900,
            yearlyTotal: 0
        )
        XCTAssertEqual(result, 900 / CalculationEngine.daysPerMonth / CalculationEngine.hoursPerDay, accuracy: 0.01)
    }

    // MARK: - Weekly Expense Calculations

    func testWeeklyExpense_Basic() {
        // $10/day = $70/week
        let result = CalculationEngine.weeklyExpense(
            dailyTotal: 10,
            monthlyTotal: 0,
            yearlyTotal: 0
        )
        XCTAssertEqual(result, 70, accuracy: 0.01)
    }

    // MARK: - Monthly Income Calculations

    func testTotalMonthlyIncome_AllZero() {
        let result = CalculationEngine.totalMonthlyIncome(
            dailyIncomeTotal: 0,
            monthlyIncomeTotal: 0,
            yearlyIncomeTotal: 0
        )
        XCTAssertEqual(result, 0, accuracy: 0.01)
    }

    func testTotalMonthlyIncome_Salary() {
        // Common scenario: $5000/month salary
        let result = CalculationEngine.totalMonthlyIncome(
            dailyIncomeTotal: 0,
            monthlyIncomeTotal: 5000,
            yearlyIncomeTotal: 0
        )
        XCTAssertEqual(result, 5000, accuracy: 0.01)
    }

    func testTotalMonthlyIncome_YearlySalary() {
        // $60,000/year = $5,000/month
        let result = CalculationEngine.totalMonthlyIncome(
            dailyIncomeTotal: 0,
            monthlyIncomeTotal: 0,
            yearlyIncomeTotal: 60000
        )
        XCTAssertEqual(result, 5000, accuracy: 0.01)
    }

    func testTotalMonthlyIncome_Mixed() {
        // Daily gig normalizes through the shared average month length.
        // Monthly salary: $2000
        // Yearly bonus: $12000 / 12 = $1000
        let expected = (100 * CalculationEngine.daysPerMonth) + 2000 + (12000 / 12)
        let result = CalculationEngine.totalMonthlyIncome(
            dailyIncomeTotal: 100,
            monthlyIncomeTotal: 2000,
            yearlyIncomeTotal: 12000
        )
        XCTAssertEqual(result, expected, accuracy: 0.01)
    }

    // MARK: - Daily Income Calculations

    func testDailyIncomeTotalConverted_Mixed() {
        // Daily: $50
        // Monthly and yearly use shared average period lengths.
        let result = CalculationEngine.dailyIncomeTotalConverted(
            dailyIncomeTotal: 50,
            monthlyIncomeTotal: 600,
            yearlyIncomeTotal: 3650
        )
        let expected = 50 + (600 / CalculationEngine.daysPerMonth) + (3650 / CalculationEngine.daysPerYear)
        XCTAssertEqual(result, expected, accuracy: 0.01)
    }

    // MARK: - Hourly Income Calculations

    func testHourlyIncome_Basic() {
        // $240/day = $10/hour
        let result = CalculationEngine.hourlyIncome(
            dailyIncomeTotal: 240,
            monthlyIncomeTotal: 0,
            yearlyIncomeTotal: 0
        )
        XCTAssertEqual(result, 10, accuracy: 0.01)
    }

    // MARK: - Weekly Income Calculations

    func testWeeklyIncome_Basic() {
        // $100/day = $700/week
        let result = CalculationEngine.weeklyIncome(
            dailyIncomeTotal: 100,
            monthlyIncomeTotal: 0,
            yearlyIncomeTotal: 0
        )
        XCTAssertEqual(result, 700, accuracy: 0.01)
    }

    // MARK: - Net Flow Calculations

    func testNetFlow_Positive() {
        // Income: $5000/month, Expense: $3000/month
        // Net: +$2000/month
        let result = CalculationEngine.netFlow(
            dailyIncomeTotal: 0,
            monthlyIncomeTotal: 5000,
            yearlyIncomeTotal: 0,
            dailyExpenseTotal: 0,
            monthlyExpenseTotal: 3000,
            yearlyExpenseTotal: 0
        )
        XCTAssertEqual(result, 2000, accuracy: 0.01, "Net flow should be positive")
    }

    func testNetFlow_Negative() {
        // Income: $2000/month, Expense: $3000/month
        // Net: -$1000/month
        let result = CalculationEngine.netFlow(
            dailyIncomeTotal: 0,
            monthlyIncomeTotal: 2000,
            yearlyIncomeTotal: 0,
            dailyExpenseTotal: 0,
            monthlyExpenseTotal: 3000,
            yearlyExpenseTotal: 0
        )
        XCTAssertEqual(result, -1000, accuracy: 0.01, "Net flow should be negative")
    }

    func testNetFlow_BreakEven() {
        let result = CalculationEngine.netFlow(
            dailyIncomeTotal: 0,
            monthlyIncomeTotal: 3000,
            yearlyIncomeTotal: 0,
            dailyExpenseTotal: 0,
            monthlyExpenseTotal: 3000,
            yearlyExpenseTotal: 0
        )
        XCTAssertEqual(result, 0, accuracy: 0.01, "Break-even should be zero")
    }

    func testNetFlow_Complex() {
        let expectedIncome = (100 * CalculationEngine.daysPerMonth) + 2000 + (12000 / 12)
        let expectedExpense = (50 * CalculationEngine.daysPerMonth) + 1000 + (6000 / 12)
        let result = CalculationEngine.netFlow(
            dailyIncomeTotal: 100,
            monthlyIncomeTotal: 2000,
            yearlyIncomeTotal: 12000,
            dailyExpenseTotal: 50,
            monthlyExpenseTotal: 1000,
            yearlyExpenseTotal: 6000
        )
        XCTAssertEqual(result, expectedIncome - expectedExpense, accuracy: 0.01)
    }

    // MARK: - Net Daily Flow

    func testNetDailyFlow_Positive() {
        // Income: $120/day, Expense: $80/day
        // Net: $40/day
        let result = CalculationEngine.netDailyFlow(
            dailyIncomeTotal: 120,
            monthlyIncomeTotal: 0,
            yearlyIncomeTotal: 0,
            dailyExpenseTotal: 80,
            monthlyExpenseTotal: 0,
            yearlyExpenseTotal: 0
        )
        XCTAssertEqual(result, 40, accuracy: 0.01)
    }

    // MARK: - Net Hourly Flow

    func testNetHourlyFlow_Positive() {
        // Income: $24/day = $1/hour
        // Expense: $12/day = $0.50/hour
        // Net: $0.50/hour
        let result = CalculationEngine.netHourlyFlow(
            dailyIncomeTotal: 24,
            monthlyIncomeTotal: 0,
            yearlyIncomeTotal: 0,
            dailyExpenseTotal: 12,
            monthlyExpenseTotal: 0,
            yearlyExpenseTotal: 0
        )
        XCTAssertEqual(result, 0.5, accuracy: 0.01)
    }

    func testNetHourlyFlow_Negative() {
        // Income: $12/day = $0.50/hour
        // Expense: $24/day = $1/hour
        // Net: -$0.50/hour
        let result = CalculationEngine.netHourlyFlow(
            dailyIncomeTotal: 12,
            monthlyIncomeTotal: 0,
            yearlyIncomeTotal: 0,
            dailyExpenseTotal: 24,
            monthlyExpenseTotal: 0,
            yearlyExpenseTotal: 0
        )
        XCTAssertEqual(result, -0.5, accuracy: 0.01)
    }

    // MARK: - Net Weekly Flow

    func testNetWeeklyFlow_Positive() {
        // Income: $100/day = $700/week
        // Expense: $50/day = $350/week
        // Net: $350/week
        let result = CalculationEngine.netWeeklyFlow(
            dailyIncomeTotal: 100,
            monthlyIncomeTotal: 0,
            yearlyIncomeTotal: 0,
            dailyExpenseTotal: 50,
            monthlyExpenseTotal: 0,
            yearlyExpenseTotal: 0
        )
        XCTAssertEqual(result, 350, accuracy: 0.01)
    }

    // MARK: - Net Yearly Flow

    func testNetYearlyFlow_Positive() {
        // Income: $60,000/year
        // Expense: $36,000/year
        // Net: $24,000/year
        let result = CalculationEngine.netYearlyFlow(
            dailyIncomeTotal: 0,
            monthlyIncomeTotal: 0,
            yearlyIncomeTotal: 60000,
            dailyExpenseTotal: 0,
            monthlyExpenseTotal: 0,
            yearlyExpenseTotal: 36000
        )
        XCTAssertEqual(result, 24000, accuracy: 0.01)
    }

    func testNetYearlyFlow_Mixed() {
        let expectedIncome = (100 * CalculationEngine.daysPerYear) + (2000 * 12) + 12000
        let expectedExpense = (50 * CalculationEngine.daysPerYear) + (1000 * 12) + 6000
        let result = CalculationEngine.netYearlyFlow(
            dailyIncomeTotal: 100,
            monthlyIncomeTotal: 2000,
            yearlyIncomeTotal: 12000,
            dailyExpenseTotal: 50,
            monthlyExpenseTotal: 1000,
            yearlyExpenseTotal: 6000
        )
        XCTAssertEqual(result, expectedIncome - expectedExpense, accuracy: 0.01)
    }

    // MARK: - Financial Health Score

    func testFinancialHealthScore_Perfect_NoExpenses() {
        let result = CalculationEngine.financialHealthScore(
            totalMonthlyIncome: 5000,
            totalMonthlyExpense: 0
        )
        XCTAssertEqual(result.score, 10, "No expenses should give perfect score")
        XCTAssertEqual(result.color, "green")
    }

    func testFinancialHealthScore_Perfect_DoubleIncome() {
        // Income is 2x expenses
        let result = CalculationEngine.financialHealthScore(
            totalMonthlyIncome: 6000,
            totalMonthlyExpense: 3000
        )
        XCTAssertEqual(result.score, 10, "2x income should give perfect score")
        XCTAssertEqual(result.color, "green")
    }

    func testFinancialHealthScore_Good() {
        // Income is 1.5x expenses
        let result = CalculationEngine.financialHealthScore(
            totalMonthlyIncome: 4500,
            totalMonthlyExpense: 3000
        )
        XCTAssertEqual(result.score, 8, "1.5x income should give good score")
        XCTAssertEqual(result.color, "blue")
    }

    func testFinancialHealthScore_Fair() {
        // Income is 1.2x expenses
        let result = CalculationEngine.financialHealthScore(
            totalMonthlyIncome: 3600,
            totalMonthlyExpense: 3000
        )
        XCTAssertEqual(result.score, 6, "1.2x income should give fair score")
        XCTAssertEqual(result.color, "yellow")
    }

    func testFinancialHealthScore_Poor() {
        // Income equals expenses
        let result = CalculationEngine.financialHealthScore(
            totalMonthlyIncome: 3000,
            totalMonthlyExpense: 3000
        )
        XCTAssertEqual(result.score, 4, "Equal income/expense should give poor score")
        XCTAssertEqual(result.color, "orange")
    }

    func testFinancialHealthScore_Bad() {
        // Expenses exceed income
        let result = CalculationEngine.financialHealthScore(
            totalMonthlyIncome: 2000,
            totalMonthlyExpense: 3000
        )
        XCTAssertEqual(result.score, 2, "Expenses > income should give bad score")
        XCTAssertEqual(result.color, "red")
    }

    // MARK: - Target Time Calculations

    func testTargetTime_ZeroTarget() {
        let result = CalculationEngine.targetTime(
            targetAmount: 0,
            netHourlyFlow: 10
        )
        XCTAssertEqual(result.hours, 0)
        XCTAssertEqual(result.days, 0)
        XCTAssertNil(result.message)
    }

    func testTargetTime_NegativeFlow() {
        let result = CalculationEngine.targetTime(
            targetAmount: 1000,
            netHourlyFlow: -5
        )
        XCTAssertEqual(result.hours, 0)
        XCTAssertNotNil(result.message, "Should have warning message for negative flow")
    }

    func testTargetTime_ZeroFlow() {
        let result = CalculationEngine.targetTime(
            targetAmount: 1000,
            netHourlyFlow: 0
        )
        XCTAssertEqual(result.hours, 0)
        XCTAssertNotNil(result.message, "Should have warning message for zero flow")
    }

    func testTargetTime_Basic() {
        // Target: $1000, Flow: $10/hour
        // Expected: 100 hours = 4.17 days
        let result = CalculationEngine.targetTime(
            targetAmount: 1000,
            netHourlyFlow: 10
        )
        XCTAssertEqual(result.hours, 100, accuracy: 0.01)
        XCTAssertEqual(result.days, 4.17, accuracy: 0.01)
    }

    func testTargetTime_OneYear() {
        // Target: $10,000, Flow: $1.14/hour (approx $10k/year at 24/7)
        // Expected: 8771.93 hours = 365.5 days ≈ 1 year
        let hourlyFlow = 10000.0 / (365.25 * 24)
        let result = CalculationEngine.targetTime(
            targetAmount: 10000,
            netHourlyFlow: hourlyFlow
        )
        XCTAssertEqual(result.years, 1, accuracy: 0.01)
    }

    func testTargetTime_Rounding() {
        // Test that results are rounded to 2 decimal places
        let result = CalculationEngine.targetTime(
            targetAmount: 1000,
            netHourlyFlow: 7.777777
        )
        XCTAssertEqual(result.hours, 128.57, accuracy: 0.01, "Should round to 2 decimals")
    }

    // MARK: - Live Counter Calculations

    func testCalculateLiveExpense_OneHour() {
        // $24/day should spend $1 in 1 hour (3600 seconds)
        let result = CalculationEngine.calculateLiveExpense(
            dailyTotal: 24,
            monthlyTotal: 0,
            yearlyTotal: 0,
            sessionSeconds: 3600
        )
        XCTAssertEqual(result, 1, accuracy: 0.01)
    }

    func testCalculateLiveExpense_OneMinute() {
        // $1440/day = $60/hour = $1/minute
        let result = CalculationEngine.calculateLiveExpense(
            dailyTotal: 1440,
            monthlyTotal: 0,
            yearlyTotal: 0,
            sessionSeconds: 60
        )
        XCTAssertEqual(result, 1, accuracy: 0.01)
    }

    func testCalculateLiveExpense_Mixed() {
        // Daily: $24/day = $0.000277.../second
        // Monthly: $900/month = $0.000347.../second
        // Yearly: $3650/year = $0.000115.../second
        // Total per second: ~$0.00074
        // 1 hour (3600s): ~$2.67
        let result = CalculationEngine.calculateLiveExpense(
            dailyTotal: 24,
            monthlyTotal: 900,
            yearlyTotal: 3650,
            sessionSeconds: 3600
        )
        let expected = (
            24 / CalculationEngine.secondsPerDay
            + 900 / CalculationEngine.secondsPerMonth
            + 3650 / CalculationEngine.secondsPerYear
        ) * 3600
        XCTAssertEqual(result, expected, accuracy: 0.01)
    }

    func testCalculateLiveExpense_RoundingToCents() {
        // Test that results are rounded to 2 decimal places (cents)
        let result = CalculationEngine.calculateLiveExpense(
            dailyTotal: 7.77,
            monthlyTotal: 0,
            yearlyTotal: 0,
            sessionSeconds: 1000
        )
        // Should be rounded to cents
        let rounded = (result * 100).rounded() / 100
        XCTAssertEqual(result, rounded, "Should be rounded to 2 decimal places")
    }

    // MARK: - Live Income Calculations

    func testCalculateLiveIncome_OneHour() {
        // $240/day should earn $10 in 1 hour
        let result = CalculationEngine.calculateLiveIncome(
            dailyIncomeTotal: 240,
            monthlyIncomeTotal: 0,
            yearlyIncomeTotal: 0,
            sessionSeconds: 3600
        )
        XCTAssertEqual(result, 10, accuracy: 0.01)
    }

    func testCalculateLiveIncome_Mixed() {
        // Daily: $100 * 365 / 365 / 24 / 3600 = $0.001157.../second
        // Monthly: $3000 * 12 / 365 / 24 / 3600 = $0.001141.../second
        // Yearly: $12000 / 365 / 24 / 3600 = $0.000380.../second
        let result = CalculationEngine.calculateLiveIncome(
            dailyIncomeTotal: 100,
            monthlyIncomeTotal: 3000,
            yearlyIncomeTotal: 12000,
            sessionSeconds: 3600
        )
        let expected = (
            100 / CalculationEngine.secondsPerDay
            + 3000 / CalculationEngine.secondsPerMonth
            + 12000 / CalculationEngine.secondsPerYear
        ) * 3600
        XCTAssertEqual(result, expected, accuracy: 0.01)
    }

    // MARK: - Live Net Flow

    func testCalculateLiveNetFlow_Positive() {
        let result = CalculationEngine.calculateLiveNetFlow(
            liveIncome: 100,
            liveExpense: 60
        )
        XCTAssertEqual(result, 40, accuracy: 0.01)
    }

    func testCalculateLiveNetFlow_Negative() {
        let result = CalculationEngine.calculateLiveNetFlow(
            liveIncome: 60,
            liveExpense: 100
        )
        XCTAssertEqual(result, -40, accuracy: 0.01)
    }

    func testCalculateLiveNetFlow_Zero() {
        let result = CalculationEngine.calculateLiveNetFlow(
            liveIncome: 50,
            liveExpense: 50
        )
        XCTAssertEqual(result, 0, accuracy: 0.01)
    }

    // MARK: - Edge Cases

    func testLargeNumbers() {
        // Test with very large numbers (billionaire scenario)
        let result = CalculationEngine.totalMonthlyIncome(
            dailyIncomeTotal: 1000000,
            monthlyIncomeTotal: 5000000,
            yearlyIncomeTotal: 100000000
        )
        let expected = (1_000_000 * CalculationEngine.daysPerMonth) + 5_000_000 + (100_000_000 / 12)
        XCTAssertEqual(result, expected, accuracy: 100, "Should handle large numbers")
    }

    func testSmallDecimals() {
        // Test with very small amounts (cents)
        let result = CalculationEngine.dailyExpenseTotal(
            dailyTotal: 0.01,
            monthlyTotal: 0.30,
            yearlyTotal: 3.65
        )
        // 0.01 + (0.30 / 30) + (3.65 / 365) = 0.01 + 0.01 + 0.01 = 0.03
        XCTAssertEqual(result, 0.03, accuracy: 0.001, "Should handle small decimals")
    }

    func testNegativeInputsHandling() {
        // While negative values shouldn't occur in normal use,
        // the calculation engine should still compute them mathematically
        let result = CalculationEngine.netFlow(
            dailyIncomeTotal: 100,
            monthlyIncomeTotal: 0,
            yearlyIncomeTotal: 0,
            dailyExpenseTotal: 150,
            monthlyExpenseTotal: 0,
            yearlyExpenseTotal: 0
        )
        XCTAssertEqual(result, -50 * CalculationEngine.daysPerMonth, accuracy: 0.01)
    }
}
