//
//  InsightsViewModel.swift
//  BudgetMeter
//
//  Created by BudgetMeter Team on 17.09.2025.
//

import Foundation
import SwiftUI
import CoreData
import Combine

/// ViewModel for Spending Insights feature following MVVM architecture
@MainActor
final class InsightsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var monthlyTrends: [MonthlyTrend] = []
    @Published var topCategories: [CategoryInsight] = []
    @Published var spendingPatterns: [SpendingPattern] = []
    @Published var financialHealthTrends: [HealthTrend] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Summary Data
    
    @Published var totalMonthlyIncome: Double = 0
    @Published var totalMonthlyExpenses: Double = 0
    @Published var netFlow: Double = 0
    @Published var savingsRate: Double = 0
    @Published var topSpendingCategory: String = ""
    @Published var averageDailySpending: Double = 0
    
    // MARK: - Private Properties
    
    private let persistenceService: PersistenceService
    private var cancellables = Set<AnyCancellable>()
    private var currencyCode: String = CurrencyHelper.defaultCurrencyCode()
    
    // MARK: - Initialization
    
    init(persistenceService: PersistenceService = .shared) {
        self.persistenceService = persistenceService
        setupObservers()
        loadInsightsData()
    }
    
    // MARK: - Public Methods
    
    /// Loads all insights data from Core Data
    func loadInsightsData() {
        isLoading = true
        errorMessage = nil
        
        Task {
            await loadMonthlyTrends()
            await loadTopCategories()
            await loadSpendingPatterns()
            await loadFinancialHealthTrends()
            await calculateSummaryData()
            
            isLoading = false
        }
    }
    
    /// Refreshes insights data
    func refresh() {
        loadInsightsData()
    }
    
    // MARK: - Private Methods
    
    private func setupObservers() {
        // Observe Core Data changes
        NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)
            .sink { [weak self] _ in
                self?.loadInsightsData()
            }
            .store(in: &cancellables)
    }
    
    private func loadMonthlyTrends() async {
        let context = persistenceService.viewContext
        
        // Get last 12 months of data
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .month, value: -12, to: endDate) ?? endDate
        
        let request: NSFetchRequest<FinancialCategory> = FinancialCategory.fetchRequest()
        request.predicate = NSPredicate(format: "createdAt >= %@ AND createdAt <= %@", 
                                       startDate as NSDate, endDate as NSDate)
        
        do {
            let categories = try context.fetch(request)
            let trends = calculateMonthlyTrends(from: categories, startDate: startDate, endDate: endDate)
            
            await MainActor.run {
                self.monthlyTrends = trends
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load monthly trends: \(error.localizedDescription)"
            }
        }
    }
    
    private func loadTopCategories() async {
        let context = persistenceService.viewContext
        
        let request: NSFetchRequest<FinancialCategory> = FinancialCategory.fetchRequest()
        request.predicate = NSPredicate(format: "type == %@", "expense")
        
        do {
            let categories = try context.fetch(request)
            let insights = calculateTopCategories(from: categories)
            
            await MainActor.run {
                self.topCategories = insights
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load top categories: \(error.localizedDescription)"
            }
        }
    }
    
    private func loadSpendingPatterns() async {
        let context = persistenceService.viewContext
        
        // Get last 30 days of data
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -30, to: endDate) ?? endDate
        
        let request: NSFetchRequest<FinancialCategory> = FinancialCategory.fetchRequest()
        request.predicate = NSPredicate(format: "type == %@ AND createdAt >= %@ AND createdAt <= %@", 
                                       "expense", startDate as NSDate, endDate as NSDate)
        
        do {
            let categories = try context.fetch(request)
            let patterns = calculateSpendingPatterns(from: categories, startDate: startDate, endDate: endDate)
            
            await MainActor.run {
                self.spendingPatterns = patterns
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load spending patterns: \(error.localizedDescription)"
            }
        }
    }
    
    private func loadFinancialHealthTrends() async {
        let context = persistenceService.viewContext
        
        // Get last 6 months of data
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .month, value: -6, to: endDate) ?? endDate
        
        let request: NSFetchRequest<FinancialCategory> = FinancialCategory.fetchRequest()
        request.predicate = NSPredicate(format: "createdAt >= %@ AND createdAt <= %@", 
                                       startDate as NSDate, endDate as NSDate)
        
        do {
            let categories = try context.fetch(request)
            let trends = calculateFinancialHealthTrends(from: categories, startDate: startDate, endDate: endDate)
            
            await MainActor.run {
                self.financialHealthTrends = trends
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load financial health trends: \(error.localizedDescription)"
            }
        }
    }
    
    private func calculateSummaryData() async {
        let context = persistenceService.viewContext
        
        // Get current month data
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        let endOfMonth = calendar.dateInterval(of: .month, for: now)?.end ?? now
        
        let incomeRequest: NSFetchRequest<FinancialCategory> = FinancialCategory.fetchRequest()
        incomeRequest.predicate = NSPredicate(format: "type == %@ AND createdAt >= %@ AND createdAt <= %@", 
                                             "income", startOfMonth as NSDate, endOfMonth as NSDate)
        
        let expenseRequest: NSFetchRequest<FinancialCategory> = FinancialCategory.fetchRequest()
        expenseRequest.predicate = NSPredicate(format: "type == %@ AND createdAt >= %@ AND createdAt <= %@", 
                                              "expense", startOfMonth as NSDate, endOfMonth as NSDate)
        
        do {
            let incomeCategories = try context.fetch(incomeRequest)
            let expenseCategories = try context.fetch(expenseRequest)
            
            let totalIncome = incomeCategories.reduce(0) { $0 + $1.amount }
            let totalExpenses = expenseCategories.reduce(0) { $0 + $1.amount }
            let net = totalIncome - totalExpenses
            let savingsRate = totalIncome > 0 ? (net / totalIncome) * 100 : 0
            
            // Find top spending category
            let topCategory = expenseCategories.max { $0.amount < $1.amount }
            let topCategoryName = topCategory?.uniqueID ?? "No data"
            
            // Calculate average daily spending
            let daysInMonth = calendar.range(of: .day, in: .month, for: now)?.count ?? 30
            let averageDaily = totalExpenses / Double(daysInMonth)
            
            await MainActor.run {
                self.totalMonthlyIncome = totalIncome
                self.totalMonthlyExpenses = totalExpenses
                self.netFlow = net
                self.savingsRate = savingsRate
                self.topSpendingCategory = topCategoryName
                self.averageDailySpending = averageDaily
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to calculate summary data: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Data Processing Methods
    
    private func calculateMonthlyTrends(from categories: [FinancialCategory], startDate: Date, endDate: Date) -> [MonthlyTrend] {
        let calendar = Calendar.current
        var trends: [MonthlyTrend] = []
        
        var currentDate = startDate
        while currentDate <= endDate {
            let monthStart = calendar.dateInterval(of: .month, for: currentDate)?.start ?? currentDate
            let monthEnd = calendar.dateInterval(of: .month, for: currentDate)?.end ?? currentDate
            
            // Filter categories by month using createdAt
            let monthCategories = categories.filter { category in
                guard let createdAt = category.createdAt else { return false }
                return createdAt >= monthStart && createdAt < monthEnd
            }
            
            let incomeCategories = monthCategories.compactMap { category -> FinancialCategory? in
                category.type == "income" ? category : nil
            }
            let expenseCategories = monthCategories.compactMap { category -> FinancialCategory? in
                category.type == "expense" ? category : nil
            }
            
            let income = incomeCategories.reduce(0) { $0 + $1.amount }
            let expenses = expenseCategories.reduce(0) { $0 + $1.amount }
            let netFlow = income - expenses
            
            let trend = MonthlyTrend(
                month: monthStart,
                income: income,
                expenses: expenses,
                netFlow: netFlow
            )
            
            trends.append(trend)
            currentDate = calendar.date(byAdding: .month, value: 1, to: currentDate) ?? endDate
        }
        
        return trends
    }
    
    private func calculateTopCategories(from categories: [FinancialCategory]) -> [CategoryInsight] {
        let groupedCategories = Dictionary(grouping: categories) { $0.uniqueID ?? "Unknown" }
        
        let insights = groupedCategories.map { (name, categories) in
            let totalAmount = categories.reduce(0) { $0 + $1.amount }
            let transactionCount = categories.count
            let averageAmount = totalAmount / Double(transactionCount)
            
            return CategoryInsight(
                name: name,
                totalAmount: totalAmount,
                transactionCount: transactionCount,
                averageAmount: averageAmount,
                percentage: 0 // Will be calculated after we have total
            )
        }
        
        let totalExpenses = insights.reduce(0) { $0 + $1.totalAmount }
        
        return insights.map { insight in
            var updatedInsight = insight
            updatedInsight.percentage = totalExpenses > 0 ? (insight.totalAmount / totalExpenses) * 100 : 0
            return updatedInsight
        }.sorted { $0.totalAmount > $1.totalAmount }.prefix(10).map { $0 }
    }
    
    private func calculateSpendingPatterns(from categories: [FinancialCategory], startDate: Date, endDate: Date) -> [SpendingPattern] {
        let calendar = Calendar.current
        var patterns: [SpendingPattern] = []
        
        var currentDate = startDate
        while currentDate <= endDate {
            let dayStart = calendar.startOfDay(for: currentDate)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? currentDate
            
            // Filter categories by day using createdAt
            let dayCategories = categories.filter { category in
                guard let createdAt = category.createdAt else { return false }
                return createdAt >= dayStart && createdAt < dayEnd
            }
            
            let totalSpending = dayCategories.reduce(0) { $0 + $1.amount }
            let transactionCount = dayCategories.count
            
            let pattern = SpendingPattern(
                date: dayStart,
                totalSpending: totalSpending,
                transactionCount: transactionCount
            )
            
            patterns.append(pattern)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? endDate
        }
        
        return patterns
    }
    
    private func calculateFinancialHealthTrends(from categories: [FinancialCategory], startDate: Date, endDate: Date) -> [HealthTrend] {
        let calendar = Calendar.current
        var trends: [HealthTrend] = []
        
        var currentDate = startDate
        while currentDate <= endDate {
            let monthStart = calendar.dateInterval(of: .month, for: currentDate)?.start ?? currentDate
            let monthEnd = calendar.dateInterval(of: .month, for: currentDate)?.end ?? currentDate
            
            // Filter categories by month using createdAt
            let monthCategories = categories.filter { category in
                guard let createdAt = category.createdAt else { return false }
                return createdAt >= monthStart && createdAt < monthEnd
            }
            
            let incomeCategories = monthCategories.compactMap { category -> FinancialCategory? in
                category.type == "income" ? category : nil
            }
            let expenseCategories = monthCategories.compactMap { category -> FinancialCategory? in
                category.type == "expense" ? category : nil
            }
            
            let income = incomeCategories.reduce(0) { $0 + $1.amount }
            let expenses = expenseCategories.reduce(0) { $0 + $1.amount }
            let netFlow = income - expenses
            let savingsRate = income > 0 ? (netFlow / income) * 100 : 0
            
            // Calculate health score (0-100)
            let healthScore = calculateHealthScore(income: income, expenses: expenses, savingsRate: savingsRate)
            
            let trend = HealthTrend(
                month: monthStart,
                healthScore: healthScore,
                savingsRate: savingsRate,
                netFlow: netFlow
            )
            
            trends.append(trend)
            currentDate = calendar.date(byAdding: .month, value: 1, to: currentDate) ?? endDate
        }
        
        return trends
    }
    
    private func calculateHealthScore(income: Double, expenses: Double, savingsRate: Double) -> Double {
        var score = 50.0 // Base score
        
        // Savings rate contribution (0-30 points)
        if savingsRate > 20 {
            score += 30
        } else if savingsRate > 10 {
            score += 20
        } else if savingsRate > 0 {
            score += 10
        } else if savingsRate > -10 {
            score += 0
        } else {
            score -= 20
        }
        
        // Income stability (0-20 points)
        if income > 0 {
            score += 20
        }
        
        // Expense control (0-20 points)
        if expenses > 0 && income > 0 {
            let expenseRatio = expenses / income
            if expenseRatio < 0.7 {
                score += 20
            } else if expenseRatio < 0.9 {
                score += 10
            } else if expenseRatio < 1.1 {
                score += 0
            } else {
                score -= 10
            }
        }
        
        return max(0, min(100, score))
    }
}

// MARK: - Supporting Types

struct MonthlyTrend: Identifiable {
    let id = UUID()
    let month: Date
    let income: Double
    let expenses: Double
    let netFlow: Double
    
    var formattedMonth: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: month)
    }
}

struct CategoryInsight: Identifiable {
    let id = UUID()
    let name: String
    let totalAmount: Double
    let transactionCount: Int
    let averageAmount: Double
    var percentage: Double
    
    var formattedAmount: String {
        return CurrencyHelper.formatAmount(totalAmount)
    }
    
    var formattedPercentage: String {
        return String(format: "%.1f%%", percentage)
    }
}

struct SpendingPattern: Identifiable {
    let id = UUID()
    let date: Date
    let totalSpending: Double
    let transactionCount: Int
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd"
        return formatter.string(from: date)
    }
    
    var formattedSpending: String {
        return CurrencyHelper.formatAmount(totalSpending)
    }
}

struct HealthTrend: Identifiable {
    let id = UUID()
    let month: Date
    let healthScore: Double
    let savingsRate: Double
    let netFlow: Double
    
    var formattedMonth: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: month)
    }
    
    var formattedHealthScore: String {
        return String(format: "%.0f", healthScore)
    }
    
    var formattedSavingsRate: String {
        return String(format: "%.1f%%", savingsRate)
    }
    
    var healthColor: Color {
        switch healthScore {
        case 80...100:
            return .green
        case 60..<80:
            return .yellow
        case 40..<60:
            return .orange
        default:
            return .red
        }
    }
}
