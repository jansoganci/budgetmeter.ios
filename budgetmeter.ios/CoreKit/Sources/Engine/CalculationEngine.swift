//
//  CalculationEngine.swift
//  BudgetMeter
//
//  Created by BudgetMeter Team on 17.09.2025.
//

import Foundation

/// Pure calculation engine that ports all financial formulas from the JavaScript web app
/// All functions are stateless and use Double for compatibility with Core Data
struct CalculationEngine {

    // MARK: - Constants

    /// Average days in a month (365.25 / 12)
    /// Using the astronomically accurate value for consistency
    static let daysPerMonth: Double = 30.4375

    /// Days in a year (including leap years)
    static let daysPerYear: Double = 365.25

    /// Hours per day
    static let hoursPerDay: Double = 24

    /// Seconds per day
    static let secondsPerDay: Double = 86400

    /// Seconds per month (using accurate days per month)
    static let secondsPerMonth: Double = daysPerMonth * hoursPerDay * 60 * 60

    /// Seconds per year
    static let secondsPerYear: Double = daysPerYear * hoursPerDay * 60 * 60

    // MARK: - Financial Health Score
    
    struct FinancialHealthScore {
        let score: Int
        let text: String
        let color: String
        let description: String
    }
    
    struct TargetTimeResult {
        let hours: Double
        let days: Double
        let weeks: Double
        let months: Double
        let years: Double
        let message: String?
    }
    
    // MARK: - Expense Calculations
    
    /// Calculates the total monthly expense based on the exact web app formula.
    /// Formula: (dailyTotal * daysPerMonth) + monthlyTotal + (yearlyTotal / 12)
    static func totalMonthlyExpense(
        dailyTotal: Double,
        monthlyTotal: Double,
        yearlyTotal: Double
    ) -> Double {
        return (dailyTotal * daysPerMonth) + monthlyTotal + (yearlyTotal / 12)
    }
    
    /// Calculate daily expense total (including converted monthly and yearly)
    /// Formula: dailyTotal + (monthlyTotal / daysPerMonth) + (yearlyTotal / daysPerYear)
    static func dailyExpenseTotal(
        dailyTotal: Double,
        monthlyTotal: Double,
        yearlyTotal: Double
    ) -> Double {
        return dailyTotal + (monthlyTotal / daysPerMonth) + (yearlyTotal / daysPerYear)
    }
    
    /// Calculate hourly expense
    /// Formula: dailyExpenseTotal / hoursPerDay
    static func hourlyExpense(
        dailyTotal: Double,
        monthlyTotal: Double,
        yearlyTotal: Double
    ) -> Double {
        let dailyExpense = dailyExpenseTotal(
            dailyTotal: dailyTotal,
            monthlyTotal: monthlyTotal,
            yearlyTotal: yearlyTotal
        )
        return dailyExpense / hoursPerDay
    }
    
    /// Calculate weekly expense
    /// Formula: dailyExpenseTotal * 7
    static func weeklyExpense(
        dailyTotal: Double,
        monthlyTotal: Double,
        yearlyTotal: Double
    ) -> Double {
        let dailyExpense = dailyExpenseTotal(
            dailyTotal: dailyTotal,
            monthlyTotal: monthlyTotal,
            yearlyTotal: yearlyTotal
        )
        return dailyExpense * 7
    }
    
    // MARK: - Income Calculations
    
    /// Calculate total monthly income (daily * daysPerMonth + monthly + yearly/12)
    static func totalMonthlyIncome(
        dailyIncomeTotal: Double,
        monthlyIncomeTotal: Double,
        yearlyIncomeTotal: Double
    ) -> Double {
        return (dailyIncomeTotal * daysPerMonth) + monthlyIncomeTotal + (yearlyIncomeTotal / 12)
    }
    
    /// Calculate daily income total (including converted monthly and yearly)
    /// Formula: dailyIncomeTotal + (monthlyIncomeTotal / daysPerMonth) + (yearlyIncomeTotal / daysPerYear)
    static func dailyIncomeTotalConverted(
        dailyIncomeTotal: Double,
        monthlyIncomeTotal: Double,
        yearlyIncomeTotal: Double
    ) -> Double {
        return dailyIncomeTotal + (monthlyIncomeTotal / daysPerMonth) + (yearlyIncomeTotal / daysPerYear)
    }
    
    /// Calculate hourly income
    /// Formula: dailyIncomeTotalConverted / hoursPerDay
    static func hourlyIncome(
        dailyIncomeTotal: Double,
        monthlyIncomeTotal: Double,
        yearlyIncomeTotal: Double
    ) -> Double {
        let dailyIncome = dailyIncomeTotalConverted(
            dailyIncomeTotal: dailyIncomeTotal,
            monthlyIncomeTotal: monthlyIncomeTotal,
            yearlyIncomeTotal: yearlyIncomeTotal
        )
        return dailyIncome / hoursPerDay
    }
    
    /// Calculate weekly income
    /// Formula: dailyIncomeTotalConverted * 7
    static func weeklyIncome(
        dailyIncomeTotal: Double,
        monthlyIncomeTotal: Double,
        yearlyIncomeTotal: Double
    ) -> Double {
        let dailyIncome = dailyIncomeTotalConverted(
            dailyIncomeTotal: dailyIncomeTotal,
            monthlyIncomeTotal: monthlyIncomeTotal,
            yearlyIncomeTotal: yearlyIncomeTotal
        )
        return dailyIncome * 7
    }
    
    // MARK: - Net Flow Calculations
    
    /// Calculate monthly net flow
    /// Formula: totalMonthlyIncome - totalMonthlyExpense
    static func netFlow(
        dailyIncomeTotal: Double,
        monthlyIncomeTotal: Double,
        yearlyIncomeTotal: Double,
        dailyExpenseTotal: Double,
        monthlyExpenseTotal: Double,
        yearlyExpenseTotal: Double
    ) -> Double {
        let totalIncome = totalMonthlyIncome(
            dailyIncomeTotal: dailyIncomeTotal,
            monthlyIncomeTotal: monthlyIncomeTotal,
            yearlyIncomeTotal: yearlyIncomeTotal
        )
        let totalExpense = totalMonthlyExpense(
            dailyTotal: dailyExpenseTotal,
            monthlyTotal: monthlyExpenseTotal,
            yearlyTotal: yearlyExpenseTotal
        )
        return totalIncome - totalExpense
    }
    
    /// Calculate daily net flow
    /// Formula: dailyIncomeTotalConverted - dailyExpenseTotal
    static func netDailyFlow(
        dailyIncomeTotal: Double,
        monthlyIncomeTotal: Double,
        yearlyIncomeTotal: Double,
        dailyExpenseTotal: Double,
        monthlyExpenseTotal: Double,
        yearlyExpenseTotal: Double
    ) -> Double {
        let dailyIncome = dailyIncomeTotalConverted(
            dailyIncomeTotal: dailyIncomeTotal,
            monthlyIncomeTotal: monthlyIncomeTotal,
            yearlyIncomeTotal: yearlyIncomeTotal
        )
        let dailyExpense = Self.dailyExpenseTotal(
            dailyTotal: dailyExpenseTotal,
            monthlyTotal: monthlyExpenseTotal,
            yearlyTotal: yearlyExpenseTotal
        )
        return dailyIncome - dailyExpense
    }
    
    /// Calculate hourly net flow
    /// Formula: hourlyIncome - hourlyExpense
    static func netHourlyFlow(
        dailyIncomeTotal: Double,
        monthlyIncomeTotal: Double,
        yearlyIncomeTotal: Double,
        dailyExpenseTotal: Double,
        monthlyExpenseTotal: Double,
        yearlyExpenseTotal: Double
    ) -> Double {
        let hourlyInc = hourlyIncome(
            dailyIncomeTotal: dailyIncomeTotal,
            monthlyIncomeTotal: monthlyIncomeTotal,
            yearlyIncomeTotal: yearlyIncomeTotal
        )
        let hourlyExp = hourlyExpense(
            dailyTotal: dailyExpenseTotal,
            monthlyTotal: monthlyExpenseTotal,
            yearlyTotal: yearlyExpenseTotal
        )
        return hourlyInc - hourlyExp
    }
    
    /// Calculate weekly net flow
    /// Formula: weeklyIncome - weeklyExpense
    static func netWeeklyFlow(
        dailyIncomeTotal: Double,
        monthlyIncomeTotal: Double,
        yearlyIncomeTotal: Double,
        dailyExpenseTotal: Double,
        monthlyExpenseTotal: Double,
        yearlyExpenseTotal: Double
    ) -> Double {
        let weeklyInc = weeklyIncome(
            dailyIncomeTotal: dailyIncomeTotal,
            monthlyIncomeTotal: monthlyIncomeTotal,
            yearlyIncomeTotal: yearlyIncomeTotal
        )
        let weeklyExp = weeklyExpense(
            dailyTotal: dailyExpenseTotal,
            monthlyTotal: monthlyExpenseTotal,
            yearlyTotal: yearlyExpenseTotal
        )
        return weeklyInc - weeklyExp
    }
    
    /// Calculate net yearly flow
    /// Formula: (dailyIncome * daysPerYear) + (monthlyIncome * 12) + yearlyIncome - (dailyExpense * daysPerYear) - (monthlyExpense * 12) - yearlyExpense
    static func netYearlyFlow(
        dailyIncomeTotal: Double,
        monthlyIncomeTotal: Double,
        yearlyIncomeTotal: Double,
        dailyExpenseTotal: Double,
        monthlyExpenseTotal: Double,
        yearlyExpenseTotal: Double
    ) -> Double {
        let yearlyIncome = (dailyIncomeTotal * daysPerYear) + (monthlyIncomeTotal * 12) + yearlyIncomeTotal
        let yearlyExpense = (dailyExpenseTotal * daysPerYear) + (monthlyExpenseTotal * 12) + yearlyExpenseTotal
        return yearlyIncome - yearlyExpense
    }
    
    // MARK: - Financial Health Score
    
    /// Calculate financial health score based on income vs expense ratio
    /// Exact port from JavaScript logic
    static func financialHealthScore(
        totalMonthlyIncome: Double,
        totalMonthlyExpense: Double
    ) -> FinancialHealthScore {
        if totalMonthlyExpense == 0 {
            return financialHealthScore(
                score: 10,
                textKey: "home.health.status.perfect",
                descriptionKey: "home.health.desc.no_expenses",
                color: "green"
            )
        }

        let ratio = totalMonthlyIncome / totalMonthlyExpense

        if ratio >= 2 {
            return financialHealthScore(
                score: 10,
                textKey: "home.health.status.perfect",
                descriptionKey: "home.health.desc.income_double",
                color: "green"
            )
        } else if ratio >= 1.5 {
            return financialHealthScore(
                score: 8,
                textKey: "home.health.status.good",
                descriptionKey: "home.health.desc.income_50",
                color: "blue"
            )
        } else if ratio >= 1.2 {
            return financialHealthScore(
                score: 6,
                textKey: "home.health.status.fair",
                descriptionKey: "home.health.desc.income_20",
                color: "yellow"
            )
        } else if ratio >= 1 {
            return financialHealthScore(
                score: 4,
                textKey: "home.health.status.poor",
                descriptionKey: "home.health.desc.income_equal",
                color: "orange"
            )
        } else {
            return financialHealthScore(
                score: 2,
                textKey: "home.health.status.bad",
                descriptionKey: "home.health.desc.expense_higher",
                color: "red"
            )
        }
    }
    
    // MARK: - Target Time Calculation
    
    /// Calculate time needed to reach savings target
    /// Exact port from JavaScript logic
    static func targetTime(
        targetAmount: Double,
        netHourlyFlow: Double
    ) -> TargetTimeResult {
        if targetAmount <= 0 {
            return TargetTimeResult(
                hours: 0,
                days: 0,
                weeks: 0,
                months: 0,
                years: 0,
                message: nil
            )
        }
        
        if netHourlyFlow <= 0 {
            return TargetTimeResult(
                hours: 0,
                days: 0,
                weeks: 0,
                months: 0,
                years: 0,
                message: LocalizationManager.shared.localizedString(
                    for: "home.target.message.negative",
                    defaultValue: "Your net flow is negative. Increase income or reduce expenses to reach the target."
                )
            )
        }
        
        let hours = targetAmount / netHourlyFlow
        let days = hours / hoursPerDay
        let weeks = days / 7
        let months = days / daysPerMonth
        let years = days / daysPerYear
        
        return TargetTimeResult(
            hours: (hours * 100).rounded() / 100,
            days: (days * 100).rounded() / 100,
            weeks: (weeks * 100).rounded() / 100,
            months: (months * 100).rounded() / 100,
            years: (years * 100).rounded() / 100,
            message: nil
        )
    }

    private static func financialHealthScore(
        score: Int,
        textKey: String,
        descriptionKey: String,
        color: String
    ) -> FinancialHealthScore {
        let manager = LocalizationManager.shared
        return FinancialHealthScore(
            score: score,
            text: manager.localizedString(for: textKey, defaultValue: textKey),
            color: color,
            description: manager.localizedString(for: descriptionKey, defaultValue: descriptionKey)
        )
    }
    
    // MARK: - Live Counter Calculations
    
    /// Calculate live expense based on session time (in seconds)
    /// Formula: (dailyExpensePerSecond + monthlyExpensePerSecond + yearlyExpensePerSecond) * sessionSeconds
    static func calculateLiveExpense(
        dailyTotal: Double,
        monthlyTotal: Double,
        yearlyTotal: Double,
        sessionSeconds: Double
    ) -> Double {
        let dailyExpensePerSecond = dailyTotal / secondsPerDay
        let monthlyExpensePerSecond = monthlyTotal / secondsPerMonth
        let yearlyExpensePerSecond = yearlyTotal / secondsPerYear
        
        let liveExpense = (dailyExpensePerSecond + monthlyExpensePerSecond + yearlyExpensePerSecond) * sessionSeconds
        
        // Round to 2 decimal places for currency precision
        return (liveExpense * 100).rounded() / 100
    }
    
    /// Calculate live income based on session time (in seconds)
    /// Formula: (dailyIncomePerSecond + monthlyIncomePerSecond + yearlyIncomePerSecond) * sessionSeconds
    static func calculateLiveIncome(
        dailyIncomeTotal: Double,
        monthlyIncomeTotal: Double,
        yearlyIncomeTotal: Double,
        sessionSeconds: Double
    ) -> Double {
        let dailyIncomePerSecond = dailyIncomeTotal / secondsPerDay
        let monthlyIncomePerSecond = monthlyIncomeTotal / secondsPerMonth
        let yearlyIncomePerSecond = yearlyIncomeTotal / secondsPerYear
        
        let liveIncome = (dailyIncomePerSecond + monthlyIncomePerSecond + yearlyIncomePerSecond) * sessionSeconds
        
        // Round to 2 decimal places for currency precision
        return (liveIncome * 100).rounded() / 100
    }
    
    /// Calculate live net flow
    /// Formula: liveIncome - liveExpense
    static func calculateLiveNetFlow(
        liveIncome: Double,
        liveExpense: Double
    ) -> Double {
        return liveIncome - liveExpense
    }
}
