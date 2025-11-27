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

    // MARK: - Health Score (0-100 Scale)

    /// Calculate comprehensive financial health score (0-100)
    /// Components: Income stability (30 pts) + Expense management (30 pts) + Savings rate (40 pts)
    static func calculateFinancialHealthScore(
        monthlyIncome: Double,
        monthlyExpense: Double,
        savingsGoal: Double
    ) -> Int {
        var score = 0

        // Income Score (0-30 points)
        // Having income is essential
        if monthlyIncome > 0 {
            score += 30
        } else if monthlyIncome > monthlyExpense {
            score += 20
        } else if monthlyIncome > 0 {
            score += 10
        }

        // Expense Management Score (0-30 points)
        // Based on income to expense ratio
        if monthlyIncome > 0 {
            let ratio = monthlyIncome / max(monthlyExpense, 1)

            if ratio >= 2.0 {
                score += 30 // Excellent: Spending < 50% of income
            } else if ratio >= 1.5 {
                score += 25 // Great: Spending < 67% of income
            } else if ratio >= 1.2 {
                score += 20 // Good: Spending < 83% of income
            } else if ratio >= 1.0 {
                score += 15 // Fair: Breaking even
            } else if ratio >= 0.8 {
                score += 10 // Poor: Spending 125% of income
            } else {
                score += 5  // Bad: Spending much more than income
            }
        }

        // Savings Score (0-40 points) - Most important
        let savingsAmount = max(0, monthlyIncome - monthlyExpense)

        if monthlyIncome > 0 {
            let savingsRate = savingsAmount / monthlyIncome

            if savingsRate >= 0.30 {
                score += 40 // Excellent: Saving 30%+ of income
            } else if savingsRate >= 0.20 {
                score += 35 // Great: Saving 20-30% of income
            } else if savingsRate >= 0.15 {
                score += 30 // Good: Saving 15-20% of income
            } else if savingsRate >= 0.10 {
                score += 25 // Fair: Saving 10-15% of income
            } else if savingsRate >= 0.05 {
                score += 15 // Poor: Saving 5-10% of income
            } else if savingsRate > 0 {
                score += 10 // Bad: Saving less than 5%
            }
            // 0 points if not saving
        }

        return min(100, max(0, score))
    }

    /// Convert health score to descriptive text
    static func healthScoreText(for score: Int) -> String {
        switch score {
        case 90...100:
            return "Excellent"
        case 75...89:
            return "Great"
        case 60...74:
            return "Good"
        case 40...59:
            return "Fair"
        case 20...39:
            return "Needs Improvement"
        default:
            return "Getting Started"
        }
    }

    /// Calculate detailed health score breakdown
    static func calculateHealthScoreBreakdown(
        monthlyIncome: Double,
        monthlyExpense: Double,
        savingsGoal: Double
    ) -> HealthScoreBreakdown {
        var incomeScore = 0
        var incomeReason = ""

        // Income Score (0-30 points)
        if monthlyIncome > 0 {
            incomeScore = 30
            incomeReason = "You have a steady income source"
        } else if monthlyIncome > monthlyExpense {
            incomeScore = 20
            incomeReason = "Income covers your expenses"
        } else if monthlyIncome > 0 {
            incomeScore = 10
            incomeReason = "Income is present but low"
        } else {
            incomeReason = "No income tracked yet"
        }

        // Expense Score (0-30 points)
        var expenseScore = 0
        var expenseReason = ""

        if monthlyIncome > 0 {
            let ratio = monthlyIncome / max(monthlyExpense, 1)

            if ratio >= 2.0 {
                expenseScore = 30
                expenseReason = "Spending less than 50% of income"
            } else if ratio >= 1.5 {
                expenseScore = 25
                expenseReason = "Spending less than 67% of income"
            } else if ratio >= 1.2 {
                expenseScore = 20
                expenseReason = "Spending less than 83% of income"
            } else if ratio >= 1.0 {
                expenseScore = 15
                expenseReason = "Breaking even with income"
            } else if ratio >= 0.8 {
                expenseScore = 10
                expenseReason = "Spending exceeds income"
            } else {
                expenseScore = 5
                expenseReason = "Spending significantly exceeds income"
            }
        } else {
            expenseReason = "Set up income to track expense ratio"
        }

        // Savings Score (0-40 points)
        var savingsScore = 0
        var savingsReason = ""

        let savingsAmount = max(0, monthlyIncome - monthlyExpense)

        if monthlyIncome > 0 {
            let savingsRate = savingsAmount / monthlyIncome

            if savingsRate >= 0.30 {
                savingsScore = 40
                savingsReason = "Saving 30%+ of income - Outstanding!"
            } else if savingsRate >= 0.20 {
                savingsScore = 35
                savingsReason = "Saving 20-30% of income - Great job!"
            } else if savingsRate >= 0.15 {
                savingsScore = 30
                savingsReason = "Saving 15-20% of income - Good progress"
            } else if savingsRate >= 0.10 {
                savingsScore = 25
                savingsReason = "Saving 10-15% of income - Keep going"
            } else if savingsRate >= 0.05 {
                savingsScore = 15
                savingsReason = "Saving 5-10% of income - Room to improve"
            } else if savingsRate > 0 {
                savingsScore = 10
                savingsReason = "Saving less than 5% - Try to save more"
            } else {
                savingsReason = "Not saving yet - Reduce expenses"
            }
        } else {
            savingsReason = "Add income to start saving"
        }

        let totalScore = min(100, max(0, incomeScore + expenseScore + savingsScore))

        return HealthScoreBreakdown(
            totalScore: totalScore,
            incomeScore: incomeScore,
            expenseScore: expenseScore,
            savingsScore: savingsScore,
            incomeReason: incomeReason,
            expenseReason: expenseReason,
            savingsReason: savingsReason
        )
    }

    /// Generate actionable health tips
    static func generateHealthTips(
        breakdown: HealthScoreBreakdown,
        currentIncome: Double,
        currentExpense: Double,
        savingsGoal: Double
    ) -> [HealthTip] {
        var tips: [HealthTip] = []

        let savingsAmount = max(0, currentIncome - currentExpense)
        let savingsRate = currentIncome > 0 ? savingsAmount / currentIncome : 0

        // Tip 1: Savings Rate
        if savingsRate < 0.10 && currentIncome > 0 {
            let targetAmount = currentIncome * 0.10
            let reductionNeeded = currentExpense - (currentIncome - targetAmount)
            tips.append(HealthTip(
                icon: "arrow.down.circle.fill",
                title: "Increase Your Savings Rate",
                description: "Try to save at least 10% of your income. Reduce expenses by \(CurrencyHelper.formatAmount(reductionNeeded)) to reach this goal.",
                impact: "+10 points",
                color: .red
            ))
        } else if savingsRate < 0.20 && currentIncome > 0 {
            tips.append(HealthTip(
                icon: "arrow.up.circle.fill",
                title: "Boost Your Savings",
                description: "You're saving \(PercentageFormatter.formatInteger(savingsRate * 100)). Aim for 20% to build wealth faster.",
                impact: "+5 points",
                color: .orange
            ))
        }

        // Tip 2: Expense Management
        if currentIncome > 0 {
            let ratio = currentIncome / max(currentExpense, 1)
            if ratio < 1.2 {
                tips.append(HealthTip(
                    icon: "chart.pie.fill",
                    title: "Review Your Expenses",
                    description: "Your expenses are close to your income. Look for categories where you can cut back.",
                    impact: "+8 points",
                    color: .red
                ))
            }
        }

        // Tip 3: Income Growth
        if breakdown.incomeScore < 30 {
            tips.append(HealthTip(
                icon: "dollarsign.circle.fill",
                title: "Add Income Sources",
                description: "Track all your income sources to get an accurate financial picture.",
                impact: "+7 points",
                color: .red
            ))
        } else if savingsGoal > 0 && savingsAmount > 0 {
            let monthsToGoal = ceil(savingsGoal / savingsAmount)
            if monthsToGoal > 12 {
                tips.append(HealthTip(
                    icon: "arrow.up.right.circle.fill",
                    title: "Consider Additional Income",
                    description: "At your current rate, it will take \(Int(monthsToGoal)) months to reach your goal. Extra income could help you get there faster.",
                    impact: "+5 points",
                    color: .orange
                ))
            }
        }

        // Tip 4: Goal Progress
        if savingsGoal > 0 && savingsAmount > 0 {
            let progress = (savingsAmount / savingsGoal) * 100
            if progress < 25 {
                tips.append(HealthTip(
                    icon: "target",
                    title: "Adjust Your Savings Goal",
                    description: "Your current savings are \(PercentageFormatter.formatInteger(progress)) of your goal. Consider if your goal is realistic for your income level.",
                    impact: "+3 points",
                    color: .blue
                ))
            }
        } else if savingsGoal == 0 && savingsAmount > 0 {
            tips.append(HealthTip(
                icon: "flag.fill",
                title: "Set a Savings Goal",
                description: "You're saving \(CurrencyHelper.formatAmount(savingsAmount))/month. Set a goal to stay motivated!",
                impact: "+5 points",
                color: .orange
            ))
        }

        // Tip 5: Positive Reinforcement
        if breakdown.totalScore >= 75 {
            tips.append(HealthTip(
                icon: "star.fill",
                title: "You're Doing Great!",
                description: "Your financial health score is \(breakdown.totalScore)/100. Keep up the excellent habits!",
                impact: "Excellent",
                actionable: false,
                color: .green
            ))
        }

        // Sort by color priority (red > orange > blue > green) and limit to top 5
        return tips.sorted { tip1, tip2 in
            let priority1 = tip1.color == .red ? 4 : (tip1.color == .orange ? 3 : (tip1.color == .blue ? 2 : 1))
            let priority2 = tip2.color == .red ? 4 : (tip2.color == .orange ? 3 : (tip2.color == .blue ? 2 : 1))
            return priority1 > priority2
        }.prefix(5).map { $0 }
    }
}
