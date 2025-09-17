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
    /// Formula: (dailyTotal * 30) + monthlyTotal + (yearlyTotal / 12)
    static func totalMonthlyExpense(
        dailyTotal: Double,
        monthlyTotal: Double,
        yearlyTotal: Double
    ) -> Double {
        return (dailyTotal * 30) + monthlyTotal + (yearlyTotal / 12)
    }
    
    /// Calculate daily expense total (including converted monthly and yearly)
    /// Formula: dailyTotal + (monthlyTotal / 30) + (yearlyTotal / 365)
    static func dailyExpenseTotal(
        dailyTotal: Double,
        monthlyTotal: Double,
        yearlyTotal: Double
    ) -> Double {
        return dailyTotal + (monthlyTotal / 30) + (yearlyTotal / 365)
    }
    
    /// Calculate hourly expense
    /// Formula: dailyExpenseTotal / 24
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
        return dailyExpense / 24
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
    
    /// Calculate total monthly income (daily * 30 + monthly + yearly/12)
    static func totalMonthlyIncome(
        dailyIncomeTotal: Double,
        monthlyIncomeTotal: Double,
        yearlyIncomeTotal: Double
    ) -> Double {
        return (dailyIncomeTotal * 30) + monthlyIncomeTotal + (yearlyIncomeTotal / 12)
    }
    
    /// Calculate daily income total (including converted monthly and yearly)
    /// Formula: dailyIncomeTotal + (monthlyIncomeTotal / 30) + (yearlyIncomeTotal / 365)
    static func dailyIncomeTotalConverted(
        dailyIncomeTotal: Double,
        monthlyIncomeTotal: Double,
        yearlyIncomeTotal: Double
    ) -> Double {
        return dailyIncomeTotal + (monthlyIncomeTotal / 30) + (yearlyIncomeTotal / 365)
    }
    
    /// Calculate hourly income
    /// Formula: dailyIncomeTotalConverted / 24
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
        return dailyIncome / 24
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
    /// Formula: (dailyIncome * 365) + (monthlyIncome * 12) + yearlyIncome - (dailyExpense * 365) - (monthlyExpense * 12) - yearlyExpense
    static func netYearlyFlow(
        dailyIncomeTotal: Double,
        monthlyIncomeTotal: Double,
        yearlyIncomeTotal: Double,
        dailyExpenseTotal: Double,
        monthlyExpenseTotal: Double,
        yearlyExpenseTotal: Double
    ) -> Double {
        let yearlyIncome = (dailyIncomeTotal * 365) + (monthlyIncomeTotal * 12) + yearlyIncomeTotal
        let yearlyExpense = (dailyExpenseTotal * 365) + (monthlyExpenseTotal * 12) + yearlyExpenseTotal
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
            return FinancialHealthScore(
                score: 10,
                text: "Mükemmel",
                color: "green",
                description: "Hiç gideriniz yok!"
            )
        }
        
        let ratio = totalMonthlyIncome / totalMonthlyExpense
        
        if ratio >= 2 {
            return FinancialHealthScore(
                score: 10,
                text: "Mükemmel",
                color: "green",
                description: "Geliriniz giderinizin 2 katından fazla"
            )
        } else if ratio >= 1.5 {
            return FinancialHealthScore(
                score: 8,
                text: "İyi",
                color: "blue",
                description: "Geliriniz giderinizin %50 fazlası"
            )
        } else if ratio >= 1.2 {
            return FinancialHealthScore(
                score: 6,
                text: "Orta",
                color: "yellow",
                description: "Geliriniz giderinizin %20 fazlası"
            )
        } else if ratio >= 1 {
            return FinancialHealthScore(
                score: 4,
                text: "Zayıf",
                color: "orange",
                description: "Gelir ve gideriniz eşit"
            )
        } else {
            return FinancialHealthScore(
                score: 2,
                text: "Kötü",
                color: "red",
                description: "Gideriniz gelirinizden fazla"
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
                message: "Net akışınız negatif! Hedefe ulaşamazsınız."
            )
        }
        
        let hours = targetAmount / netHourlyFlow
        let days = hours / 24
        let weeks = days / 7
        let months = days / 30.44 // Real average month (365.25/12)
        let years = days / 365.25 // Including leap years
        
        return TargetTimeResult(
            hours: (hours * 100).rounded() / 100,
            days: (days * 100).rounded() / 100,
            weeks: (weeks * 100).rounded() / 100,
            months: (months * 100).rounded() / 100,
            years: (years * 100).rounded() / 100,
            message: nil
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
        let dailyExpensePerSecond = dailyTotal / (24 * 60 * 60)
        let monthlyExpensePerSecond = monthlyTotal / (30 * 24 * 60 * 60)
        let yearlyExpensePerSecond = yearlyTotal / (365 * 24 * 60 * 60)
        
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
        let dailyIncomePerSecond = dailyIncomeTotal / (24 * 60 * 60)
        let monthlyIncomePerSecond = monthlyIncomeTotal / (30 * 24 * 60 * 60)
        let yearlyIncomePerSecond = yearlyIncomeTotal / (365 * 24 * 60 * 60)
        
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
