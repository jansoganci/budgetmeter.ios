//
//  InsightsService.swift
//  BudgetMeter
//
//  Created by BudgetMeter Team on 17.09.2025.
//

import Foundation
import CoreData
import SwiftUI

/// Service for generating automated financial insights
final class InsightsService {

    // MARK: - Singleton

    static let shared = InsightsService()

    private let persistenceService: PersistenceService
    private let historicalService: HistoricalDataService

    // MARK: - Initialization

    private init(
        persistenceService: PersistenceService = .shared,
        historicalService: HistoricalDataService = .shared
    ) {
        self.persistenceService = persistenceService
        self.historicalService = historicalService
    }

    // MARK: - Public Methods

    /// Generates all insights for the current financial state
    func generateInsights() -> [Insight] {
        var insights: [Insight] = []

        // Get current financial data
        let context = persistenceService.viewContext
        guard let financialData = getCurrentFinancialData(in: context) else {
            return []
        }

        // 1. Spending breakdown
        if let breakdownInsight = generateSpendingBreakdown(financialData: financialData, context: context) {
            insights.append(breakdownInsight)
        }

        // 2. Savings rate
        if let savingsInsight = generateSavingsRate(financialData: financialData) {
            insights.append(savingsInsight)
        }

        // 3. Balance trend
        if let balanceTrendInsight = generateBalanceTrend() {
            insights.append(balanceTrendInsight)
        }

        // 4. Month comparison
        if let monthComparisonInsight = generateMonthComparison() {
            insights.append(monthComparisonInsight)
        }

        // 5. Goal progress
        if let goalProgressInsight = generateGoalProgress(financialData: financialData, context: context) {
            insights.append(goalProgressInsight)
        }

        // 6. Daily average
        if let dailyAverageInsight = generateDailyAverage(financialData: financialData) {
            insights.append(dailyAverageInsight)
        }

        return insights
    }

    /// Calculate spending breakdown by category
    func calculateSpendingBreakdown() -> [(category: String, amount: Double, percentage: Double)] {
        let context = persistenceService.viewContext

        let request: NSFetchRequest<FinancialCategory> = FinancialCategory.fetchRequest()
        request.predicate = NSPredicate(format: "type == %@", "expense")

        do {
            let categories = try context.fetch(request)

            // Calculate monthly equivalents for each category
            let categoryTotals: [(String, Double)] = categories.compactMap { category in
                guard let name = category.uniqueID ?? category.customName else { return nil }

                let monthlyAmount: Double
                switch category.frequency {
                case "daily":
                    monthlyAmount = category.amount * CalculationEngine.daysPerMonth
                case "yearly":
                    monthlyAmount = category.amount / 12.0
                default: // monthly
                    monthlyAmount = category.amount
                }

                return (name, monthlyAmount)
            }

            let totalExpense = categoryTotals.reduce(0) { $0 + $1.1 }

            // Calculate percentages
            let breakdown = categoryTotals.map { (category, amount) -> (String, Double, Double) in
                let percentage = totalExpense > 0 ? (amount / totalExpense) * 100 : 0
                return (category, amount, percentage)
            }

            // Sort by amount descending
            return breakdown.sorted { $0.1 > $1.1 }
        } catch {
            print("📊 InsightsService: ❌ Failed to calculate spending breakdown: \(error)")
            return []
        }
    }

    /// Get the biggest expense category
    func getBiggestCategory() -> (name: String, amount: Double)? {
        let breakdown = calculateSpendingBreakdown()
        return breakdown.first.map { ($0.category, $0.amount) }
    }

    /// Calculate savings rate (percentage of income saved)
    func getSavingsRate() -> Double {
        guard let financialData = getCurrentFinancialData(in: persistenceService.viewContext) else {
            return 0
        }

        let savingsAmount = max(0, financialData.totalIncome - financialData.totalExpense)
        return financialData.totalIncome > 0 ? (savingsAmount / financialData.totalIncome) * 100 : 0
    }

    /// Get balance trend (improving/declining/stable)
    func getBalanceTrend() -> (trend: String, change: Double) {
        let snapshots = historicalService.getDailyTrend(days: 30)

        guard snapshots.count >= 2 else {
            return ("stable", 0)
        }

        let recentBalances = snapshots.suffix(7).map { $0.balance }
        let olderBalances = snapshots.prefix(7).map { $0.balance }

        let recentAverage = recentBalances.reduce(0, +) / Double(recentBalances.count)
        let olderAverage = olderBalances.reduce(0, +) / Double(olderBalances.count)

        let change = recentAverage - olderAverage

        if abs(change) < 10 {
            return ("stable", change)
        } else if change > 0 {
            return ("improving", change)
        } else {
            return ("declining", change)
        }
    }

    /// Compare this month vs last month
    func getMonthComparison() -> (percentageChange: Double, isImprovement: Bool)? {
        let (current, previous) = historicalService.getMonthlyComparison()

        guard let currentSnapshot = current, let previousSnapshot = previous else {
            return nil
        }

        let currentExpense = currentSnapshot.totalExpense
        let previousExpense = previousSnapshot.totalExpense

        guard previousExpense > 0 else {
            return nil
        }

        let percentageChange = ((currentExpense - previousExpense) / previousExpense) * 100
        let isImprovement = currentExpense < previousExpense

        return (percentageChange, isImprovement)
    }

    // MARK: - Private Insight Generators

    private func generateSpendingBreakdown(financialData: FinancialData, context: NSManagedObjectContext) -> Insight? {
        let breakdown = calculateSpendingBreakdown()

        guard let biggest = breakdown.first else {
            return nil
        }

        let displayName = DataSeedingService.displayName(for: biggest.category)
        let percentage = Int(biggest.percentage)

        return Insight(
            icon: "chart.pie.fill",
            title: "Spending Breakdown",
            value: "\(percentage)% on \(displayName)",
            color: .blue,
            description: "Your largest expense category"
        )
    }

    private func generateSavingsRate(financialData: FinancialData) -> Insight? {
        let savingsAmount = max(0, financialData.totalIncome - financialData.totalExpense)

        guard financialData.totalIncome > 0 else {
            return nil
        }

        let savingsRate = (savingsAmount / financialData.totalIncome) * 100
        let formattedRate = Int(savingsRate)
        let formattedAmount = CurrencyHelper.formatAmount(savingsAmount)

        let trend: Insight.Trend = savingsRate >= 20 ? .up : (savingsRate >= 10 ? .neutral : .down)

        return Insight(
            icon: "arrow.up.circle.fill",
            title: "Savings Rate",
            value: "\(formattedRate)%",
            trend: trend,
            color: .green,
            description: "You're saving \(formattedAmount) per month"
        )
    }

    private func generateBalanceTrend() -> Insight? {
        let (trend, change) = getBalanceTrend()

        let formattedChange = CurrencyHelper.formatAmount(abs(change))
        let trendIcon: String
        let trendType: Insight.Trend
        let color: Color
        let description: String

        switch trend {
        case "improving":
            trendIcon = "chart.line.uptrend.xyaxis"
            trendType = .up
            color = .green
            description = "Your balance improved by \(formattedChange)"
        case "declining":
            trendIcon = "chart.line.downtrend.xyaxis"
            trendType = .down
            color = .red
            description = "Your balance decreased by \(formattedChange)"
        default:
            trendIcon = "chart.line.flattrend.xyaxis"
            trendType = .neutral
            color = .gray
            description = "Your balance is stable"
        }

        return Insight(
            icon: trendIcon,
            title: "Balance Trend",
            value: trend == "stable" ? "Stable" : "\(change > 0 ? "+" : "")\(formattedChange)",
            trend: trendType,
            color: color,
            description: description
        )
    }

    private func generateMonthComparison() -> Insight? {
        guard let (percentageChange, isImprovement) = getMonthComparison() else {
            return nil
        }

        let absChange = abs(percentageChange)
        let formattedChange = PercentageFormatter.formatInteger(absChange)

        let trend: Insight.Trend = isImprovement ? .down : .up
        let color: Color = isImprovement ? .green : .orange
        let description = isImprovement
            ? "You spent \(formattedChange) less than last month"
            : "You spent \(formattedChange) more than last month"

        return Insight(
            icon: "chart.bar.fill",
            title: "Monthly Spending",
            value: "\(isImprovement ? "-" : "+")\(formattedChange)",
            trend: trend,
            color: color,
            description: description
        )
    }

    private func generateGoalProgress(financialData: FinancialData, context: NSManagedObjectContext) -> Insight? {
        let settingsRequest: NSFetchRequest<AppSettings> = AppSettings.fetchRequest()
        guard let settings = try? context.fetch(settingsRequest).first,
              settings.savingsGoalAmount > 0 else {
            return nil
        }

        let savingsGoal = settings.savingsGoalAmount
        let savingsAmount = max(0, financialData.totalIncome - financialData.totalExpense)

        guard savingsAmount > 0 else {
            return nil
        }

        let monthsToGoal = ceil((savingsGoal - 0) / savingsAmount)
        let formattedMonths = Int(monthsToGoal)

        let timeString: String
        if formattedMonths <= 1 {
            timeString = "This month!"
        } else if formattedMonths <= 12 {
            timeString = "\(formattedMonths) months"
        } else {
            let years = formattedMonths / 12
            timeString = "\(years) year\(years > 1 ? "s" : "")"
        }

        return Insight(
            icon: "target",
            title: "Goal Progress",
            value: timeString,
            color: .purple,
            description: "At this rate, you'll reach your \(CurrencyHelper.formatAmount(savingsGoal)) goal"
        )
    }

    private func generateDailyAverage(financialData: FinancialData) -> Insight? {
        let dailyExpense = financialData.totalExpense / CalculationEngine.daysPerMonth
        let formattedAmount = CurrencyHelper.formatAmount(dailyExpense)

        return Insight(
            icon: "calendar",
            title: "Daily Average",
            value: formattedAmount,
            color: .orange,
            description: "You spend an average of \(formattedAmount) per day"
        )
    }

    // MARK: - Helper Types

    private struct FinancialData {
        let totalIncome: Double
        let totalExpense: Double
        let balance: Double
    }

    // MARK: - Private Methods

    private func getCurrentFinancialData(in context: NSManagedObjectContext) -> FinancialData? {
        let request: NSFetchRequest<FinancialCategory> = FinancialCategory.fetchRequest()

        do {
            let categories = try context.fetch(request)

            let incomeCategories = categories.filter { $0.type == "income" }
            let expenseCategories = categories.filter { $0.type == "expense" }

            let dailyIncome = incomeCategories.filter { $0.frequency == "daily" }.reduce(0) { $0 + $1.amount }
            let monthlyIncome = incomeCategories.filter { $0.frequency == "monthly" }.reduce(0) { $0 + $1.amount }
            let yearlyIncome = incomeCategories.filter { $0.frequency == "yearly" }.reduce(0) { $0 + $1.amount }

            let dailyExpense = expenseCategories.filter { $0.frequency == "daily" }.reduce(0) { $0 + $1.amount }
            let monthlyExpense = expenseCategories.filter { $0.frequency == "monthly" }.reduce(0) { $0 + $1.amount }
            let yearlyExpense = expenseCategories.filter { $0.frequency == "yearly" }.reduce(0) { $0 + $1.amount }

            let totalIncome = CalculationEngine.totalMonthlyIncome(
                dailyIncomeTotal: dailyIncome,
                monthlyIncomeTotal: monthlyIncome,
                yearlyIncomeTotal: yearlyIncome
            )

            let totalExpense = CalculationEngine.totalMonthlyExpense(
                dailyTotal: dailyExpense,
                monthlyTotal: monthlyExpense,
                yearlyTotal: yearlyExpense
            )

            let balance = totalIncome - totalExpense

            return FinancialData(
                totalIncome: totalIncome,
                totalExpense: totalExpense,
                balance: balance
            )
        } catch {
            print("📊 InsightsService: ❌ Failed to fetch current financial data: \(error)")
            return nil
        }
    }
}
