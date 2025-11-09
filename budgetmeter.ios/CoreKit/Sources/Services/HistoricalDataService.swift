//
//  HistoricalDataService.swift
//  BudgetMeter
//
//  Created by BudgetMeter Team on 17.09.2025.
//

import Foundation
import CoreData

/// Service for managing historical financial data snapshots
final class HistoricalDataService {

    // MARK: - Singleton

    static let shared = HistoricalDataService()

    private let persistenceService: PersistenceService

    // MARK: - Initialization

    private init(persistenceService: PersistenceService = .shared) {
        self.persistenceService = persistenceService
    }

    // MARK: - Public Methods

    /// Saves a daily snapshot of current financial state
    func saveDailySnapshot() {
        let context = persistenceService.viewContext

        // Get current financial data
        let financialData = getCurrentFinancialData(in: context)

        // Check if snapshot already exists for today
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())

        let fetchRequest: NSFetchRequest<FinancialSnapshot> = FinancialSnapshot.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "snapshotType == %@ AND date >= %@ AND date < %@",
            "daily",
            startOfDay as NSDate,
            calendar.date(byAdding: .day, value: 1, to: startOfDay)! as NSDate
        )

        do {
            let existing = try context.fetch(fetchRequest)

            let snapshot: FinancialSnapshot
            if let existingSnapshot = existing.first {
                // Update existing snapshot
                snapshot = existingSnapshot
            } else {
                // Create new snapshot
                snapshot = FinancialSnapshot(context: context)
                snapshot.id = UUID()
                snapshot.date = startOfDay
                snapshot.snapshotType = "daily"
                snapshot.createdAt = Date()
            }

            // Update snapshot data
            snapshot.totalIncome = financialData.totalIncome
            snapshot.totalExpense = financialData.totalExpense
            snapshot.balance = financialData.balance
            snapshot.netFlow = financialData.netFlow
            snapshot.savingsAmount = financialData.savingsAmount
            snapshot.healthScore = Int16(financialData.healthScore)
            snapshot.savingsRate = financialData.savingsRate
            snapshot.categoryBreakdown = financialData.categoryBreakdown

            persistenceService.save()

            print("📊 HistoricalDataService: Saved daily snapshot for \(startOfDay)")
        } catch {
            print("📊 HistoricalDataService: ❌ Failed to save daily snapshot: \(error)")
        }
    }

    /// Saves a monthly snapshot
    func saveMonthlySnapshot() {
        let context = persistenceService.viewContext

        // Get current financial data
        let financialData = getCurrentFinancialData(in: context)

        // Get first day of current month
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: Date())
        guard let firstDayOfMonth = calendar.date(from: components) else { return }

        let fetchRequest: NSFetchRequest<FinancialSnapshot> = FinancialSnapshot.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "snapshotType == %@ AND date == %@",
            "monthly",
            firstDayOfMonth as NSDate
        )

        do {
            let existing = try context.fetch(fetchRequest)

            let snapshot: FinancialSnapshot
            if let existingSnapshot = existing.first {
                snapshot = existingSnapshot
            } else {
                snapshot = FinancialSnapshot(context: context)
                snapshot.id = UUID()
                snapshot.date = firstDayOfMonth
                snapshot.snapshotType = "monthly"
                snapshot.createdAt = Date()
            }

            snapshot.totalIncome = financialData.totalIncome
            snapshot.totalExpense = financialData.totalExpense
            snapshot.balance = financialData.balance
            snapshot.netFlow = financialData.netFlow
            snapshot.savingsAmount = financialData.savingsAmount
            snapshot.healthScore = Int16(financialData.healthScore)
            snapshot.savingsRate = financialData.savingsRate
            snapshot.categoryBreakdown = financialData.categoryBreakdown

            persistenceService.save()

            print("📊 HistoricalDataService: Saved monthly snapshot for \(firstDayOfMonth)")
        } catch {
            print("📊 HistoricalDataService: ❌ Failed to save monthly snapshot: \(error)")
        }
    }

    /// Retrieves snapshots for a date range
    func getSnapshots(from startDate: Date, to endDate: Date, type: String = "daily") -> [FinancialSnapshot] {
        let context = persistenceService.viewContext

        let fetchRequest: NSFetchRequest<FinancialSnapshot> = FinancialSnapshot.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "snapshotType == %@ AND date >= %@ AND date <= %@",
            type,
            startDate as NSDate,
            endDate as NSDate
        )
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \FinancialSnapshot.date, ascending: true)]

        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("📊 HistoricalDataService: ❌ Failed to fetch snapshots: \(error)")
            return []
        }
    }

    /// Get snapshots for last N days
    func getDailyTrend(days: Int) -> [FinancialSnapshot] {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate) ?? endDate

        return getSnapshots(from: startDate, to: endDate, type: "daily")
    }

    /// Compare current month vs last month
    func getMonthlyComparison() -> (current: FinancialSnapshot?, previous: FinancialSnapshot?) {
        let context = persistenceService.viewContext
        let calendar = Calendar.current

        // Current month
        let currentComponents = calendar.dateComponents([.year, .month], from: Date())
        guard let currentMonthStart = calendar.date(from: currentComponents) else {
            return (nil, nil)
        }

        // Previous month
        guard let previousMonthStart = calendar.date(byAdding: .month, value: -1, to: currentMonthStart) else {
            return (nil, nil)
        }

        let fetchRequest: NSFetchRequest<FinancialSnapshot> = FinancialSnapshot.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "snapshotType == %@ AND (date == %@ OR date == %@)",
            "monthly",
            currentMonthStart as NSDate,
            previousMonthStart as NSDate
        )

        do {
            let snapshots = try context.fetch(fetchRequest)
            let current = snapshots.first { $0.date == currentMonthStart }
            let previous = snapshots.first { $0.date == previousMonthStart }

            return (current, previous)
        } catch {
            print("📊 HistoricalDataService: ❌ Failed to fetch monthly comparison: \(error)")
            return (nil, nil)
        }
    }

    /// Clean up old snapshots (keep last 90 days of daily, 12 months of monthly)
    func cleanupOldSnapshots() {
        let context = persistenceService.viewContext
        let calendar = Calendar.current

        // Delete daily snapshots older than 90 days
        if let dailyCutoff = calendar.date(byAdding: .day, value: -90, to: Date()) {
            let dailyRequest: NSFetchRequest<NSFetchRequestResult> = FinancialSnapshot.fetchRequest()
            dailyRequest.predicate = NSPredicate(
                format: "snapshotType == %@ AND date < %@",
                "daily",
                dailyCutoff as NSDate
            )

            let deleteDailyRequest = NSBatchDeleteRequest(fetchRequest: dailyRequest)

            do {
                try context.execute(deleteDailyRequest)
                print("📊 HistoricalDataService: Cleaned up old daily snapshots")
            } catch {
                print("📊 HistoricalDataService: ❌ Failed to clean up daily snapshots: \(error)")
            }
        }

        // Delete monthly snapshots older than 12 months
        if let monthlyCutoff = calendar.date(byAdding: .month, value: -12, to: Date()) {
            let monthlyRequest: NSFetchRequest<NSFetchRequestResult> = FinancialSnapshot.fetchRequest()
            monthlyRequest.predicate = NSPredicate(
                format: "snapshotType == %@ AND date < %@",
                "monthly",
                monthlyCutoff as NSDate
            )

            let deleteMonthlyRequest = NSBatchDeleteRequest(fetchRequest: monthlyRequest)

            do {
                try context.execute(deleteMonthlyRequest)
                print("📊 HistoricalDataService: Cleaned up old monthly snapshots")
            } catch {
                print("📊 HistoricalDataService: ❌ Failed to clean up monthly snapshots: \(error)")
            }
        }

        persistenceService.save()
    }

    // MARK: - Private Methods

    /// Fetches current financial state
    private func getCurrentFinancialData(in context: NSManagedObjectContext) -> (
        totalIncome: Double,
        totalExpense: Double,
        balance: Double,
        netFlow: Double,
        savingsAmount: Double,
        healthScore: Int,
        savingsRate: Double,
        categoryBreakdown: String
    ) {
        // Fetch financial categories
        let request: NSFetchRequest<FinancialCategory> = FinancialCategory.fetchRequest()

        do {
            let categories = try context.fetch(request)

            let incomeCategories = categories.filter { $0.type == "income" }
            let expenseCategories = categories.filter { $0.type == "expense" }

            // Calculate monthly totals
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
            let netFlow = balance
            let savingsAmount = max(0, balance)

            // Get savings goal
            let settingsRequest: NSFetchRequest<AppSettings> = AppSettings.fetchRequest()
            let settings = try? context.fetch(settingsRequest).first
            let savingsGoal = settings?.savingsGoalAmount ?? 0.0

            // Calculate health score
            let healthScore = CalculationEngine.calculateFinancialHealthScore(
                monthlyIncome: totalIncome,
                monthlyExpense: totalExpense,
                savingsGoal: savingsGoal
            )

            // Calculate savings rate
            let savingsRate = totalIncome > 0 ? (savingsAmount / totalIncome) : 0.0

            // Create category breakdown JSON
            let breakdown = expenseCategories.map { category in
                [
                    "id": category.uniqueID ?? "unknown",
                    "amount": category.amount
                ] as [String: Any]
            }

            let jsonData = try? JSONSerialization.data(withJSONObject: breakdown)
            let categoryBreakdownJSON = String(data: jsonData ?? Data(), encoding: .utf8) ?? "[]"

            return (
                totalIncome: totalIncome,
                totalExpense: totalExpense,
                balance: balance,
                netFlow: netFlow,
                savingsAmount: savingsAmount,
                healthScore: healthScore,
                savingsRate: savingsRate,
                categoryBreakdown: categoryBreakdownJSON
            )
        } catch {
            print("📊 HistoricalDataService: ❌ Failed to fetch current financial data: \(error)")
            return (0, 0, 0, 0, 0, 0, 0, "[]")
        }
    }
}
