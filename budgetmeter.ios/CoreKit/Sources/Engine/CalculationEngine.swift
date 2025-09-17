//
//  CalculationEngine.swift
//  BudgetMeter
//
//  Created by BudgetMeter Team on 17.09.2025.
//

import Foundation

/// Pure calculation engine that ports all financial formulas from the JavaScript web app
/// All functions are stateless and use Decimal for precision
struct CalculationEngine {
    
    // MARK: - Financial Health Score
    
    struct FinancialHealthScore {
        let score: Int
        let text: String
        let color: String
        let description: String
    }
    
    struct TargetTimeResult {
        let hours: Decimal
        let days: Decimal
        let weeks: Decimal
        let months: Decimal
        let years: Decimal
        let message: String?
    }
    
    // MARK: - Expense Calculations
    
    /// Calculates the total monthly expense based on the exact web app formula.
    /// Formula: (dailyTotal * 30) + monthlyTotal + (yearlyTotal / 12)
    static func totalMonthlyExpense(
        dailyTotal: Decimal,
        monthlyTotal: Decimal,
        yearlyTotal: Decimal
    ) -> Decimal {
        return (dailyTotal * 30) + monthlyTotal + (yearlyTotal / 12)
    }
    
    /// Calculate daily expense total (including converted monthly and yearly)
    /// Formula: dailyTotal + (monthlyTotal / 30) + (yearlyTotal / 365)
    static func dailyExpenseTotal(
        dailyTotal: Decimal,
        monthlyTotal: Decimal,
        yearlyTotal: Decimal
    ) -> Decimal {
        return dailyTotal + (monthlyTotal / 30) + (yearlyTotal / 365)
    }
    
    /// Calculate hourly expense
    /// Formula: dailyExpenseTotal / 24
    static func hourlyExpense(
        dailyTotal: Decimal,
        monthlyTotal: Decimal,
        yearlyTotal: Decimal
    ) -> Decimal {
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
        dailyTotal: Decimal,
        monthlyTotal: Decimal,
        yearlyTotal: Decimal
    ) -> Decimal {
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
        dailyIncomeTotal: Decimal,
        monthlyIncomeTotal: Decimal,
        yearlyIncomeTotal: Decimal
    ) -> Decimal {
        return (dailyIncomeTotal * 30) + monthlyIncomeTotal + (yearlyIncomeTotal / 12)
    }
    
    /// Calculate daily income total (including converted monthly and yearly)
    /// Formula: dailyIncomeTotal + (monthlyIncomeTotal / 30) + (yearlyIncomeTotal / 365)
    static func dailyIncomeTotalConverted(
        dailyIncomeTotal: Decimal,
        monthlyIncomeTotal: Decimal,
        yearlyIncomeTotal: Decimal
    ) -> Decimal {
        return dailyIncomeTotal + (monthlyIncomeTotal / 30) + (yearlyIncomeTotal / 365)
    }
    
    /// Calculate hourly income
    /// Formula: dailyIncomeTotalConverted / 24
    static func hourlyIncome(
        dailyIncomeTotal: Decimal,
        monthlyIncomeTotal: Decimal,
        yearlyIncomeTotal: Decimal
    ) -> Decimal {
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
        dailyIncomeTotal: Decimal,
        monthlyIncomeTotal: Decimal,
        yearlyIncomeTotal: Decimal
    ) -> Decimal {
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
        dailyIncomeTotal: Decimal,
        monthlyIncomeTotal: Decimal,
        yearlyIncomeTotal: Decimal,
        dailyExpenseTotal: Decimal,
        monthlyExpenseTotal: Decimal,
        yearlyExpenseTotal: Decimal
    ) -> Decimal {
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
        dailyIncomeTotal: Decimal,
        monthlyIncomeTotal: Decimal,
        yearlyIncomeTotal: Decimal,
        dailyExpenseTotal: Decimal,
        monthlyExpenseTotal: Decimal,
        yearlyExpenseTotal: Decimal
    ) -> Decimal {
        let dailyIncome = dailyIncomeTotalConverted(
            dailyIncomeTotal: dailyIncomeTotal,
            monthlyIncomeTotal: monthlyIncomeTotal,
            yearlyIncomeTotal: yearlyIncomeTotal
        )
        let dailyExpense = dailyExpenseTotal(
            dailyTotal: dailyExpenseTotal,
            monthlyTotal: monthlyExpenseTotal,
            yearlyTotal: yearlyExpenseTotal
        )
        return dailyIncome - dailyExpense
    }
    
    /// Calculate hourly net flow
    /// Formula: hourlyIncome - hourlyExpense
    static func netHourlyFlow(
        dailyIncomeTotal: Decimal,
        monthlyIncomeTotal: Decimal,
        yearlyIncomeTotal: Decimal,
        dailyExpenseTotal: Decimal,
        monthlyExpenseTotal: Decimal,
        yearlyExpenseTotal: Decimal
    ) -> Decimal {
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
        dailyIncomeTotal: Decimal,
        monthlyIncomeTotal: Decimal,
        yearlyIncomeTotal: Decimal,
        dailyExpenseTotal: Decimal,
        monthlyExpenseTotal: Decimal,
        yearlyExpenseTotal: Decimal
    ) -> Decimal {
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
    
    // MARK: - Financial Health Score
    
    /// Calculate financial health score based on income vs expense ratio
    /// Exact port from JavaScript logic
    static func financialHealthScore(
        totalMonthlyIncome: Decimal,
        totalMonthlyExpense: Decimal
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
        } else if ratio >= Decimal(1.5) {
            return FinancialHealthScore(
                score: 8,
                text: "İyi",
                color: "blue",
                description: "Geliriniz giderinizin %50 fazlası"
            )
        } else if ratio >= Decimal(1.2) {
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
        targetAmount: Decimal,
        netHourlyFlow: Decimal
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
        let months = days / Decimal(30.44) // Real average month (365.25/12)
        let years = days / Decimal(365.25) // Including leap years
        
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
        dailyTotal: Decimal,
        monthlyTotal: Decimal,
        yearlyTotal: Decimal,
        sessionSeconds: Decimal
    ) -> Decimal {
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
        dailyIncomeTotal: Decimal,
        monthlyIncomeTotal: Decimal,
        yearlyIncomeTotal: Decimal,
        sessionSeconds: Decimal
    ) -> Decimal {
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
        liveIncome: Decimal,
        liveExpense: Decimal
    ) -> Decimal {
        return liveIncome - liveExpense
    }
}
