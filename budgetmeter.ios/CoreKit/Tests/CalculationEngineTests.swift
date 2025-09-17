//
//  CalculationEngineTests.swift
//  BudgetMeter
//
//  Created by BudgetMeter Team on 17.09.2025.
//

import XCTest
@testable import CoreKit

final class CalculationEngineTests: XCTestCase {
    
    // MARK: - Test Data
    // These values are taken directly from the web app for accuracy validation
    
    let testDailyExpense: Decimal = 100
    let testMonthlyExpense: Decimal = 2000
    let testYearlyExpense: Decimal = 12000
    
    let testDailyIncome: Decimal = 150
    let testMonthlyIncome: Decimal = 3000
    let testYearlyIncome: Decimal = 24000
    
    // MARK: - Expense Calculation Tests
    
    func testTotalMonthlyExpense() {
        // Formula: (dailyTotal * 30) + monthlyTotal + (yearlyTotal / 12)
        // Expected: (100 * 30) + 2000 + (12000 / 12) = 3000 + 2000 + 1000 = 6000
        let result = CalculationEngine.totalMonthlyExpense(
            dailyTotal: testDailyExpense,
            monthlyTotal: testMonthlyExpense,
            yearlyTotal: testYearlyExpense
        )
        XCTAssertEqual(result, 6000, "Total monthly expense calculation failed")
    }
    
    func testDailyExpenseTotal() {
        // Formula: dailyTotal + (monthlyTotal / 30) + (yearlyTotal / 365)
        // Expected: 100 + (2000 / 30) + (12000 / 365) = 100 + 66.67 + 32.88 = 199.55
        let result = CalculationEngine.dailyExpenseTotal(
            dailyTotal: testDailyExpense,
            monthlyTotal: testMonthlyExpense,
            yearlyTotal: testYearlyExpense
        )
        let expected = Decimal(100) + (Decimal(2000) / 30) + (Decimal(12000) / 365)
        XCTAssertEqual(result, expected, accuracy: 0.01, "Daily expense total calculation failed")
    }
    
    func testHourlyExpense() {
        // Formula: dailyExpenseTotal / 24
        let dailyTotal = CalculationEngine.dailyExpenseTotal(
            dailyTotal: testDailyExpense,
            monthlyTotal: testMonthlyExpense,
            yearlyTotal: testYearlyExpense
        )
        let result = CalculationEngine.hourlyExpense(
            dailyTotal: testDailyExpense,
            monthlyTotal: testMonthlyExpense,
            yearlyTotal: testYearlyExpense
        )
        let expected = dailyTotal / 24
        XCTAssertEqual(result, expected, accuracy: 0.01, "Hourly expense calculation failed")
    }
    
    func testWeeklyExpense() {
        // Formula: dailyExpenseTotal * 7
        let dailyTotal = CalculationEngine.dailyExpenseTotal(
            dailyTotal: testDailyExpense,
            monthlyTotal: testMonthlyExpense,
            yearlyTotal: testYearlyExpense
        )
        let result = CalculationEngine.weeklyExpense(
            dailyTotal: testDailyExpense,
            monthlyTotal: testMonthlyExpense,
            yearlyTotal: testYearlyExpense
        )
        let expected = dailyTotal * 7
        XCTAssertEqual(result, expected, accuracy: 0.01, "Weekly expense calculation failed")
    }
    
    // MARK: - Income Calculation Tests
    
    func testTotalMonthlyIncome() {
        // Formula: (dailyIncomeTotal * 30) + monthlyIncomeTotal + (yearlyIncomeTotal / 12)
        // Expected: (150 * 30) + 3000 + (24000 / 12) = 4500 + 3000 + 2000 = 9500
        let result = CalculationEngine.totalMonthlyIncome(
            dailyIncomeTotal: testDailyIncome,
            monthlyIncomeTotal: testMonthlyIncome,
            yearlyIncomeTotal: testYearlyIncome
        )
        XCTAssertEqual(result, 9500, "Total monthly income calculation failed")
    }
    
    func testDailyIncomeTotalConverted() {
        // Formula: dailyIncomeTotal + (monthlyIncomeTotal / 30) + (yearlyIncomeTotal / 365)
        // Expected: 150 + (3000 / 30) + (24000 / 365) = 150 + 100 + 65.75 = 315.75
        let result = CalculationEngine.dailyIncomeTotalConverted(
            dailyIncomeTotal: testDailyIncome,
            monthlyIncomeTotal: testMonthlyIncome,
            yearlyIncomeTotal: testYearlyIncome
        )
        let expected = Decimal(150) + (Decimal(3000) / 30) + (Decimal(24000) / 365)
        XCTAssertEqual(result, expected, accuracy: 0.01, "Daily income total converted calculation failed")
    }
    
    func testHourlyIncome() {
        // Formula: dailyIncomeTotalConverted / 24
        let dailyTotal = CalculationEngine.dailyIncomeTotalConverted(
            dailyIncomeTotal: testDailyIncome,
            monthlyIncomeTotal: testMonthlyIncome,
            yearlyIncomeTotal: testYearlyIncome
        )
        let result = CalculationEngine.hourlyIncome(
            dailyIncomeTotal: testDailyIncome,
            monthlyIncomeTotal: testMonthlyIncome,
            yearlyIncomeTotal: testYearlyIncome
        )
        let expected = dailyTotal / 24
        XCTAssertEqual(result, expected, accuracy: 0.01, "Hourly income calculation failed")
    }
    
    func testWeeklyIncome() {
        // Formula: dailyIncomeTotalConverted * 7
        let dailyTotal = CalculationEngine.dailyIncomeTotalConverted(
            dailyIncomeTotal: testDailyIncome,
            monthlyIncomeTotal: testMonthlyIncome,
            yearlyIncomeTotal: testYearlyIncome
        )
        let result = CalculationEngine.weeklyIncome(
            dailyIncomeTotal: testDailyIncome,
            monthlyIncomeTotal: testMonthlyIncome,
            yearlyIncomeTotal: testYearlyIncome
        )
        let expected = dailyTotal * 7
        XCTAssertEqual(result, expected, accuracy: 0.01, "Weekly income calculation failed")
    }
    
    // MARK: - Net Flow Tests
    
    func testNetFlow() {
        // Formula: totalMonthlyIncome - totalMonthlyExpense
        // Expected: 9500 - 6000 = 3500
        let result = CalculationEngine.netFlow(
            dailyIncomeTotal: testDailyIncome,
            monthlyIncomeTotal: testMonthlyIncome,
            yearlyIncomeTotal: testYearlyIncome,
            dailyExpenseTotal: testDailyExpense,
            monthlyExpenseTotal: testMonthlyExpense,
            yearlyExpenseTotal: testYearlyExpense
        )
        XCTAssertEqual(result, 3500, "Net flow calculation failed")
    }
    
    func testNetDailyFlow() {
        // Formula: dailyIncomeTotalConverted - dailyExpenseTotal
        let dailyIncome = CalculationEngine.dailyIncomeTotalConverted(
            dailyIncomeTotal: testDailyIncome,
            monthlyIncomeTotal: testMonthlyIncome,
            yearlyIncomeTotal: testYearlyIncome
        )
        let dailyExpense = CalculationEngine.dailyExpenseTotal(
            dailyTotal: testDailyExpense,
            monthlyTotal: testMonthlyExpense,
            yearlyTotal: testYearlyExpense
        )
        let result = CalculationEngine.netDailyFlow(
            dailyIncomeTotal: testDailyIncome,
            monthlyIncomeTotal: testMonthlyIncome,
            yearlyIncomeTotal: testYearlyIncome,
            dailyExpenseTotal: testDailyExpense,
            monthlyExpenseTotal: testMonthlyExpense,
            yearlyExpenseTotal: testYearlyExpense
        )
        let expected = dailyIncome - dailyExpense
        XCTAssertEqual(result, expected, accuracy: 0.01, "Net daily flow calculation failed")
    }
    
    func testNetHourlyFlow() {
        // Formula: hourlyIncome - hourlyExpense
        let hourlyInc = CalculationEngine.hourlyIncome(
            dailyIncomeTotal: testDailyIncome,
            monthlyIncomeTotal: testMonthlyIncome,
            yearlyIncomeTotal: testYearlyIncome
        )
        let hourlyExp = CalculationEngine.hourlyExpense(
            dailyTotal: testDailyExpense,
            monthlyTotal: testMonthlyExpense,
            yearlyTotal: testYearlyExpense
        )
        let result = CalculationEngine.netHourlyFlow(
            dailyIncomeTotal: testDailyIncome,
            monthlyIncomeTotal: testMonthlyIncome,
            yearlyIncomeTotal: testYearlyIncome,
            dailyExpenseTotal: testDailyExpense,
            monthlyExpenseTotal: testMonthlyExpense,
            yearlyExpenseTotal: testYearlyExpense
        )
        let expected = hourlyInc - hourlyExp
        XCTAssertEqual(result, expected, accuracy: 0.01, "Net hourly flow calculation failed")
    }
    
    func testNetWeeklyFlow() {
        // Formula: weeklyIncome - weeklyExpense
        let weeklyInc = CalculationEngine.weeklyIncome(
            dailyIncomeTotal: testDailyIncome,
            monthlyIncomeTotal: testMonthlyIncome,
            yearlyIncomeTotal: testYearlyIncome
        )
        let weeklyExp = CalculationEngine.weeklyExpense(
            dailyTotal: testDailyExpense,
            monthlyTotal: testMonthlyExpense,
            yearlyTotal: testYearlyExpense
        )
        let result = CalculationEngine.netWeeklyFlow(
            dailyIncomeTotal: testDailyIncome,
            monthlyIncomeTotal: testMonthlyIncome,
            yearlyIncomeTotal: testYearlyIncome,
            dailyExpenseTotal: testDailyExpense,
            monthlyExpenseTotal: testMonthlyExpense,
            yearlyExpenseTotal: testYearlyExpense
        )
        let expected = weeklyInc - weeklyExp
        XCTAssertEqual(result, expected, accuracy: 0.01, "Net weekly flow calculation failed")
    }
    
    // MARK: - Financial Health Score Tests
    
    func testFinancialHealthScorePerfect() {
        // When expense is 0, should return perfect score
        let result = CalculationEngine.financialHealthScore(
            totalMonthlyIncome: 5000,
            totalMonthlyExpense: 0
        )
        XCTAssertEqual(result.score, 10)
        XCTAssertEqual(result.text, "Mükemmel")
        XCTAssertEqual(result.color, "green")
    }
    
    func testFinancialHealthScoreExcellent() {
        // When income is 2x expense, should return excellent score
        let result = CalculationEngine.financialHealthScore(
            totalMonthlyIncome: 6000,
            totalMonthlyExpense: 3000
        )
        XCTAssertEqual(result.score, 10)
        XCTAssertEqual(result.text, "Mükemmel")
        XCTAssertEqual(result.color, "green")
    }
    
    func testFinancialHealthScoreGood() {
        // When income is 1.5x expense, should return good score
        let result = CalculationEngine.financialHealthScore(
            totalMonthlyIncome: 4500,
            totalMonthlyExpense: 3000
        )
        XCTAssertEqual(result.score, 8)
        XCTAssertEqual(result.text, "İyi")
        XCTAssertEqual(result.color, "blue")
    }
    
    func testFinancialHealthScoreAverage() {
        // When income is 1.2x expense, should return average score
        let result = CalculationEngine.financialHealthScore(
            totalMonthlyIncome: 3600,
            totalMonthlyExpense: 3000
        )
        XCTAssertEqual(result.score, 6)
        XCTAssertEqual(result.text, "Orta")
        XCTAssertEqual(result.color, "yellow")
    }
    
    func testFinancialHealthScorePoor() {
        // When income equals expense, should return poor score
        let result = CalculationEngine.financialHealthScore(
            totalMonthlyIncome: 3000,
            totalMonthlyExpense: 3000
        )
        XCTAssertEqual(result.score, 4)
        XCTAssertEqual(result.text, "Zayıf")
        XCTAssertEqual(result.color, "orange")
    }
    
    func testFinancialHealthScoreBad() {
        // When expense > income, should return bad score
        let result = CalculationEngine.financialHealthScore(
            totalMonthlyIncome: 2000,
            totalMonthlyExpense: 3000
        )
        XCTAssertEqual(result.score, 2)
        XCTAssertEqual(result.text, "Kötü")
        XCTAssertEqual(result.color, "red")
    }
    
    // MARK: - Target Time Tests
    
    func testTargetTimeZeroAmount() {
        let result = CalculationEngine.targetTime(
            targetAmount: 0,
            netHourlyFlow: 10
        )
        XCTAssertEqual(result.hours, 0)
        XCTAssertEqual(result.days, 0)
        XCTAssertEqual(result.weeks, 0)
        XCTAssertEqual(result.months, 0)
        XCTAssertEqual(result.years, 0)
        XCTAssertNil(result.message)
    }
    
    func testTargetTimeNegativeFlow() {
        let result = CalculationEngine.targetTime(
            targetAmount: 10000,
            netHourlyFlow: -5
        )
        XCTAssertEqual(result.hours, 0)
        XCTAssertEqual(result.days, 0)
        XCTAssertEqual(result.weeks, 0)
        XCTAssertEqual(result.months, 0)
        XCTAssertEqual(result.years, 0)
        XCTAssertEqual(result.message, "Net akışınız negatif! Hedefe ulaşamazsınız.")
    }
    
    func testTargetTimePositiveFlow() {
        // Target: 10000, hourly flow: 10
        // Expected hours: 1000
        // Expected days: 1000/24 = 41.67
        // Expected weeks: 41.67/7 = 5.95
        // Expected months: 41.67/30.44 = 1.37
        // Expected years: 41.67/365.25 = 0.11
        let result = CalculationEngine.targetTime(
            targetAmount: 10000,
            netHourlyFlow: 10
        )
        XCTAssertEqual(result.hours, 1000)
        XCTAssertEqual(result.days, (Decimal(1000) / 24 * 100).rounded() / 100, accuracy: 0.01)
        XCTAssertEqual(result.weeks, (Decimal(1000) / 24 / 7 * 100).rounded() / 100, accuracy: 0.01)
        XCTAssertEqual(result.months, (Decimal(1000) / 24 / Decimal(30.44) * 100).rounded() / 100, accuracy: 0.01)
        XCTAssertEqual(result.years, (Decimal(1000) / 24 / Decimal(365.25) * 100).rounded() / 100, accuracy: 0.01)
        XCTAssertNil(result.message)
    }
    
    // MARK: - Live Counter Tests
    
    func testCalculateLiveExpense() {
        // Test with 3600 seconds (1 hour)
        let sessionSeconds: Decimal = 3600
        let result = CalculationEngine.calculateLiveExpense(
            dailyTotal: testDailyExpense,
            monthlyTotal: testMonthlyExpense,
            yearlyTotal: testYearlyExpense,
            sessionSeconds: sessionSeconds
        )
        
        // Manual calculation:
        // Daily per second: 100 / (24 * 60 * 60) = 100 / 86400 = 0.00115741
        // Monthly per second: 2000 / (30 * 24 * 60 * 60) = 2000 / 2592000 = 0.00077160
        // Yearly per second: 12000 / (365 * 24 * 60 * 60) = 12000 / 31536000 = 0.00038052
        // Total per second: 0.00115741 + 0.00077160 + 0.00038052 = 0.00230953
        // For 3600 seconds: 0.00230953 * 3600 = 8.31
        
        let dailyPerSecond = testDailyExpense / (24 * 60 * 60)
        let monthlyPerSecond = testMonthlyExpense / (30 * 24 * 60 * 60)
        let yearlyPerSecond = testYearlyExpense / (365 * 24 * 60 * 60)
        let totalPerSecond = dailyPerSecond + monthlyPerSecond + yearlyPerSecond
        let expected = (totalPerSecond * sessionSeconds * 100).rounded() / 100
        
        XCTAssertEqual(result, expected, accuracy: 0.01, "Live expense calculation failed")
    }
    
    func testCalculateLiveIncome() {
        // Test with 3600 seconds (1 hour)
        let sessionSeconds: Decimal = 3600
        let result = CalculationEngine.calculateLiveIncome(
            dailyIncomeTotal: testDailyIncome,
            monthlyIncomeTotal: testMonthlyIncome,
            yearlyIncomeTotal: testYearlyIncome,
            sessionSeconds: sessionSeconds
        )
        
        let dailyPerSecond = testDailyIncome / (24 * 60 * 60)
        let monthlyPerSecond = testMonthlyIncome / (30 * 24 * 60 * 60)
        let yearlyPerSecond = testYearlyIncome / (365 * 24 * 60 * 60)
        let totalPerSecond = dailyPerSecond + monthlyPerSecond + yearlyPerSecond
        let expected = (totalPerSecond * sessionSeconds * 100).rounded() / 100
        
        XCTAssertEqual(result, expected, accuracy: 0.01, "Live income calculation failed")
    }
    
    func testCalculateLiveNetFlow() {
        let liveIncome: Decimal = 100
        let liveExpense: Decimal = 75
        let result = CalculationEngine.calculateLiveNetFlow(
            liveIncome: liveIncome,
            liveExpense: liveExpense
        )
        XCTAssertEqual(result, 25, "Live net flow calculation failed")
    }
}

// MARK: - XCTAssertEqual Extension for Decimal
extension XCTTestCase {
    func XCTAssertEqual(_ expression1: Decimal, _ expression2: Decimal, accuracy: Decimal, _ message: String = "", file: StaticString = #filePath, line: UInt = #line) {
        let difference = abs(expression1 - expression2)
        XCTAssertLessThanOrEqual(difference, accuracy, message, file: file, line: line)
    }
}
