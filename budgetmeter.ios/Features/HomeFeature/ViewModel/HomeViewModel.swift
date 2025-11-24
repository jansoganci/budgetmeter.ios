//
//  HomeViewModel.swift
//  BudgetMeter
//
//  Created by BudgetMeter Team on 17.09.2025.
//

import Foundation
import SwiftUI
import CoreData
import Combine
import WidgetKit

/// ViewModel for the Home screen following MVVM architecture
@MainActor
final class HomeViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    // Live Meter Data
    @Published var liveValue: Double = 0
    @Published var isPositive: Bool = true
    @Published var formattedLiveValue: String = "$0.00"
    @Published var sessionDuration: String = "0:00"
    
    // Today's Snapshot Data
    @Published var dailyNetFlow: Double = 0
    @Published var monthlyNetFlow: Double = 0
    @Published var hourlyNetFlow: Double = 0
    @Published var financialHealthScore: Int = 0
    @Published var financialHealthText: String = "Getting Started"
    @Published var financialHealthColor: Color = .secondary
    @Published var cumulativeDisplayAmount: String = "$0.00"
    @Published var cumulativeSinceDateText: String = ""
    @Published var cumulativeFlowColor: Color = .secondary

    // Interval Chart Data (for mini bar charts)
    @Published var hourlyChartData: [Double] = []
    @Published var dailyChartData: [Double] = []
    @Published var monthlyChartData: [Double] = []

    // Trend Data
    @Published var netFlowTrendPercentage: Double? = nil
    
    // Savings Goal Data
    @Published var savingsGoal: Double = 0
    @Published var formattedSavingsGoal: String = "$0"
    @Published var timeToGoal: String = ""
    @Published var showingSavingsGoalSheet = false

    // Daily Budget Data
    @Published var dailyBudgetAmount: Double = 0
    @Published var dailyBudgetColor: Color = .green
    @Published var daysLeftInMonth: Int = 0
    @Published var showingDailyBudgetInfo = false

    // State Management
    @Published var isLoading = false
    @Published var hasAnyData = false
    @Published var showingIncomeSheet = false
    @Published var showingExpenseSheet = false
    
    // MARK: - Private Properties

    private let persistenceService: PersistenceService
    private var cancellables = Set<AnyCancellable>()
    private var timer: Timer?
    private var sessionStartTime: Date
    private var sessionBaseline: Double = 0
    private var cumulativeBaseline: Double = 0
    private var cumulativeStartDate: Date = Date()
    var currencyCode: String = CurrencyHelper.defaultCurrencyCode()

    // Prevent timer race conditions
    private var isUpdatingLiveValue: Bool = false
    
    // Financial data cache
    private var dailyIncomeTotal: Double = 0
    private var monthlyIncomeTotal: Double = 0
    private var yearlyIncomeTotal: Double = 0
    private var dailyExpenseTotal: Double = 0
    private var monthlyExpenseTotal: Double = 0
    private var yearlyExpenseTotal: Double = 0

    // MARK: - Initialization
    
    init(persistenceService: PersistenceService = .shared) {
        self.persistenceService = persistenceService
        self.sessionStartTime = Date()
        
        setupNotifications()
        loadAllData()
        startTimer()
    }
    
    deinit {
        timer?.invalidate()
        timer = nil
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Public Methods
    
    /// Shows income entry modal
    func showIncomeEntry() {
        showingIncomeSheet = true
    }
    
    /// Shows expense entry modal
    func showExpenseEntry() {
        showingExpenseSheet = true
    }
    
    /// Shows savings goal input modal
    func showSavingsGoalEntry() {
        showingSavingsGoalSheet = true
    }
    
    /// Refreshes all data
    func refresh() {
        loadAllData()
    }
    
    /// Formats currency for display
    func formatCurrency(_ amount: Double) -> String {
        let formatter = makeCurrencyFormatter(maxFractionDigits: 0, minFractionDigits: 0)
        return formatter.string(from: NSNumber(value: amount)) ?? "\(CurrencyHelper.symbol(for: currencyCode))0"
    }
    
    /// Gets color for financial flow
    func colorForFlow(_ amount: Double) -> Color {
        if amount > 0 {
            return .green
        } else if amount < 0 {
            return .red
        } else {
            return .secondary
        }
    }
    
    /// Updates savings goal and recalculates time to goal
    func updateSavingsGoal(_ amount: Double) {
        savingsGoal = max(0, amount) // Ensure non-negative
        saveSavingsGoalToDatabase(amount)
        calculateTimeToGoal()
        updateSavingsGoalDisplay()
    }
    
    // MARK: - Private Methods
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(currencyDidChange(_:)),
            name: .currencyDidChange,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(languageDidChange(_:)),
            name: .languageDidChange,
            object: nil
        )
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateLiveValue()
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateLiveValue() {
        // Prevent race conditions - skip if already updating
        guard !isUpdatingLiveValue else {
            return
        }

        isUpdatingLiveValue = true
        defer { isUpdatingLiveValue = false }

        let currentTime = Date()
        let sessionElapsed = currentTime.timeIntervalSince(sessionStartTime)

        // Calculate live income and expense
        let liveIncome = CalculationEngine.calculateLiveIncome(
            dailyIncomeTotal: dailyIncomeTotal,
            monthlyIncomeTotal: monthlyIncomeTotal,
            yearlyIncomeTotal: yearlyIncomeTotal,
            sessionSeconds: sessionElapsed
        )

        let liveExpense = CalculationEngine.calculateLiveExpense(
            dailyTotal: dailyExpenseTotal,
            monthlyTotal: monthlyExpenseTotal,
            yearlyTotal: yearlyExpenseTotal,
            sessionSeconds: sessionElapsed
        )

        // Calculate net live flow
        let liveNetFlow = CalculationEngine.calculateLiveNetFlow(
            liveIncome: liveIncome,
            liveExpense: liveExpense
        )

        let sessionNet = liveNetFlow

        liveValue = sessionBaseline + sessionNet
        isPositive = liveValue >= 0

        formattedLiveValue = formatLiveCurrency(liveValue)
        sessionDuration = formatDuration(sessionElapsed)
        updateCumulativeDisplay(sessionNet: sessionNet)
    }
    
    private func loadAllData() {
        Task { @MainActor in
            isLoading = true
        }

        persistenceService.performBackgroundTask { [weak self] context in
            let fetchRequest: NSFetchRequest<FinancialCategory> = FinancialCategory.fetchRequest()
            
            do {
                let allCategories = try context.fetch(fetchRequest)
                
                // Process data into simple value types in the background
                let incomeCategories = allCategories.filter { $0.type == "income" }
                let bgDailyIncome = incomeCategories.filter { $0.frequency == "daily" }.reduce(0) { $0 + $1.amount }
                let bgMonthlyIncome = incomeCategories.filter { $0.frequency == "monthly" }.reduce(0) { $0 + $1.amount }
                let bgYearlyIncome = incomeCategories.filter { $0.frequency == "yearly" }.reduce(0) { $0 + $1.amount }
                
                let expenseCategories = allCategories.filter { $0.type == "expense" }
                let bgDailyExpense = expenseCategories.filter { $0.frequency == "daily" }.reduce(0) { $0 + $1.amount }
                let bgMonthlyExpense = expenseCategories.filter { $0.frequency == "monthly" }.reduce(0) { $0 + $1.amount }
                let bgYearlyExpense = expenseCategories.filter { $0.frequency == "yearly" }.reduce(0) { $0 + $1.amount }
                
                let bgHasAnyData = allCategories.contains { $0.amount > 0 }
                
                // Switch back to the main thread to update the UI
                Task { @MainActor in
                    guard let self = self else { return }
                    
                    self.dailyIncomeTotal = bgDailyIncome
                    self.monthlyIncomeTotal = bgMonthlyIncome
                    self.yearlyIncomeTotal = bgYearlyIncome
                    self.dailyExpenseTotal = bgDailyExpense
                    self.monthlyExpenseTotal = bgMonthlyExpense
                    self.yearlyExpenseTotal = bgYearlyExpense
                    self.hasAnyData = bgHasAnyData
                    
                    // Now that totals are updated, run calculations and load settings on main thread
                    self.calculateSnapshotMetrics()
                    self.loadAppSettings() // This is fast, involves another fetch but should be fine
                    self.loadSavingsGoal() // Load savings goal and calculate time to goal
                    
                    self.isLoading = false
                }
            } catch {
                print("Failed to load data in background: \(error)")
                Task { @MainActor in
                    self?.isLoading = false
                }
            }
        }
    }
    
    private func calculateSnapshotMetrics() {
        // Hourly net flow
        hourlyNetFlow = CalculationEngine.netHourlyFlow(
            dailyIncomeTotal: dailyIncomeTotal,
            monthlyIncomeTotal: monthlyIncomeTotal,
            yearlyIncomeTotal: yearlyIncomeTotal,
            dailyExpenseTotal: dailyExpenseTotal,
            monthlyExpenseTotal: monthlyExpenseTotal,
            yearlyExpenseTotal: yearlyExpenseTotal
        )

        // Daily net flow
        dailyNetFlow = CalculationEngine.netDailyFlow(
            dailyIncomeTotal: dailyIncomeTotal,
            monthlyIncomeTotal: monthlyIncomeTotal,
            yearlyIncomeTotal: yearlyIncomeTotal,
            dailyExpenseTotal: dailyExpenseTotal,
            monthlyExpenseTotal: monthlyExpenseTotal,
            yearlyExpenseTotal: yearlyExpenseTotal
        )

        // Monthly net flow
        let totalMonthlyIncome = CalculationEngine.totalMonthlyIncome(
            dailyIncomeTotal: dailyIncomeTotal,
            monthlyIncomeTotal: monthlyIncomeTotal,
            yearlyIncomeTotal: yearlyIncomeTotal
        )

        let totalMonthlyExpense = CalculationEngine.totalMonthlyExpense(
            dailyTotal: dailyExpenseTotal,
            monthlyTotal: monthlyExpenseTotal,
            yearlyTotal: yearlyExpenseTotal
        )

        monthlyNetFlow = totalMonthlyIncome - totalMonthlyExpense

        // Financial health score
        let healthScore = CalculationEngine.financialHealthScore(
            totalMonthlyIncome: totalMonthlyIncome,
            totalMonthlyExpense: totalMonthlyExpense
        )

        financialHealthScore = healthScore.score
        financialHealthText = healthScore.text
        financialHealthColor = colorFromString(healthScore.color)

        // Generate chart data for sparklines
        generateChartData()

        // Calculate trend percentage (compare to previous month - mock for now)
        calculateTrendPercentage()

        // Calculate daily budget
        calculateDailyBudget()

        // Recalculate time to goal when financial data changes
        calculateTimeToGoal()
    }

    /// Generates mock historical chart data for interval cards
    /// TODO: Replace with actual historical data from database
    private func generateChartData() {
        // Hourly chart data (last 8 hours)
        // Generate realistic variations around the hourly flow
        hourlyChartData = (0..<8).map { index in
            let variance = Double.random(in: 0.7...1.3)
            return max(0, abs(hourlyNetFlow) * variance)
        }

        // Daily chart data (last 15 days)
        dailyChartData = (0..<15).map { index in
            let variance = Double.random(in: 0.75...1.25)
            return max(0, abs(dailyNetFlow) * variance)
        }

        // Monthly chart data (last 12 months)
        monthlyChartData = (0..<12).map { index in
            let variance = Double.random(in: 0.8...1.2)
            let baseValue = abs(monthlyNetFlow)
            // Add growth trend
            let growthFactor = 1.0 + (Double(index) * 0.05)
            return max(0, baseValue * variance * growthFactor)
        }
    }

    /// Calculates trend percentage for hero card
    /// TODO: Replace with actual comparison to previous period data
    private func calculateTrendPercentage() {
        // Mock trend calculation - positive trend if net flow is positive
        if monthlyNetFlow != 0 {
            // Generate realistic trend between -20% and +30%
            let baseTrend = monthlyNetFlow > 0 ? 12.5 : -8.3
            let variance = Double.random(in: -5...5)
            netFlowTrendPercentage = baseTrend + variance
        } else {
            netFlowTrendPercentage = 0.0
        }
    }

    /// Calculates daily budget based on monthly patterns (Approach 3 - Simple Split)
    private func calculateDailyBudget() {
        // Calculate monthly income and expenses
        let totalMonthlyIncome = CalculationEngine.totalMonthlyIncome(
            dailyIncomeTotal: dailyIncomeTotal,
            monthlyIncomeTotal: monthlyIncomeTotal,
            yearlyIncomeTotal: yearlyIncomeTotal
        )

        let totalMonthlyExpense = CalculationEngine.totalMonthlyExpense(
            dailyTotal: dailyExpenseTotal,
            monthlyTotal: monthlyExpenseTotal,
            yearlyTotal: yearlyExpenseTotal
        )

        // Calculate monthly net (remaining budget)
        let monthlyNet = totalMonthlyIncome - totalMonthlyExpense

        // Calculate days left in month
        let calendar = Calendar.current
        let today = Date()
        let daysInMonth = calendar.range(of: .day, in: .month, for: today)?.count ?? 30
        let currentDay = calendar.component(.day, from: today)
        let daysLeft = max(1, daysInMonth - currentDay + 1)  // +1 to include today, minimum 1

        // Calculate daily budget
        dailyBudgetAmount = monthlyNet / Double(daysLeft)
        daysLeftInMonth = daysLeft

        // Determine color
        if dailyBudgetAmount > 20 {
            dailyBudgetColor = .green
        } else if dailyBudgetAmount > 0 {
            dailyBudgetColor = .yellow
        } else {
            dailyBudgetColor = .red
        }
    }

    /// Shows the daily budget info popup
    func showDailyBudgetInfo() {
        showingDailyBudgetInfo = true
    }

    private func loadAppSettings() {
        let context = persistenceService.viewContext
        let fetchRequest: NSFetchRequest<AppSettings> = AppSettings.fetchRequest()
        
        do {
            sessionBaseline = 0

            let settings = try context.fetch(fetchRequest)
            if let appSettings = settings.first {
                let preferredCode = appSettings.preferredCurrencyCode ?? CurrencyHelper.defaultCurrencyCode()
                currencyCode = CurrencyHelper.supportedCurrencyCodes.contains(preferredCode) ? preferredCode : CurrencyHelper.defaultCurrencyCode()
                cumulativeBaseline = appSettings.cumulativeTotal

                if let storedDate = appSettings.cumulativeStartDate {
                    cumulativeStartDate = storedDate
                } else {
                    cumulativeStartDate = Date()
                    appSettings.cumulativeStartDate = cumulativeStartDate
                    persistenceService.save()
                }
            } else {
                currencyCode = CurrencyHelper.defaultCurrencyCode()
                cumulativeBaseline = 0
                cumulativeStartDate = Date()
            }

            liveValue = sessionBaseline
            isPositive = liveValue >= 0
            formattedLiveValue = formatLiveCurrency(liveValue)
            sessionDuration = "home.session.duration.reset".localized(defaultValue: "0:00")

            updateCumulativeDisplay()
        } catch {
            print("Failed to load app settings: \(error)")
        }
    }

    private func updateCumulativeDisplay(sessionNet: Double = 0) {
        let currentTotal = cumulativeBaseline + sessionNet
        cumulativeDisplayAmount = formatCurrencyWithCents(currentTotal, absoluteValue: false)
        cumulativeSinceDateText = DateFormattingHelper.shared.formatMediumNoTime(cumulativeStartDate)
        cumulativeFlowColor = currentTotal == 0 ? .white : colorForFlow(currentTotal)
    }
    
    private func formatLiveCurrency(_ amount: Double) -> String {
        return formatCurrencyWithCents(amount, absoluteValue: true)
    }

    private func formatCurrencyWithCents(_ amount: Double, absoluteValue: Bool) -> String {
        let formatter = makeCurrencyFormatter(maxFractionDigits: 2, minFractionDigits: 2)
        let value = absoluteValue ? abs(amount) : amount
        return formatter.string(from: NSNumber(value: value)) ?? "\(CurrencyHelper.symbol(for: currencyCode))0.00"
    }

    private func makeCurrencyFormatter(maxFractionDigits: Int, minFractionDigits: Int) -> NumberFormatter {
        let formatter = CurrencyHelper.formatter(for: currencyCode)
        formatter.maximumFractionDigits = maxFractionDigits
        formatter.minimumFractionDigits = minFractionDigits
        return formatter
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = Int(seconds) % 3600 / 60
        let secs = Int(seconds) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }
    
    private func colorFromString(_ colorString: String) -> Color {
        switch colorString.lowercased() {
        case "green": return .green
        case "red": return .red
        case "orange": return .orange
        case "blue": return .blue
        default: return .secondary
        }
    }
    
    // MARK: - Savings Goal Private Methods
    
    /// Calculates time to reach savings goal using CalculationEngine
    private func calculateTimeToGoal() {
        guard savingsGoal > 0 else {
            timeToGoal = ""
            return
        }
        
        let netHourlyFlowValue = CalculationEngine.netHourlyFlow(
            dailyIncomeTotal: dailyIncomeTotal,
            monthlyIncomeTotal: monthlyIncomeTotal,
            yearlyIncomeTotal: yearlyIncomeTotal,
            dailyExpenseTotal: dailyExpenseTotal,
            monthlyExpenseTotal: monthlyExpenseTotal,
            yearlyExpenseTotal: yearlyExpenseTotal
        )
        
        let targetResult = CalculationEngine.targetTime(
            targetAmount: savingsGoal,
            netHourlyFlow: netHourlyFlowValue
        )
        
        if let message = targetResult.message {
            timeToGoal = message
        } else {
            // Format time display based on the most appropriate unit using localization
            if targetResult.days < 1 {
                let hoursText = "home.time_to_goal.hours".localized(defaultValue: "hours")
                timeToGoal = String(format: "%.1f %@", targetResult.hours, hoursText)
            } else if targetResult.days < 30 {
                let daysText = "home.time_to_goal.days".localized(defaultValue: "days")
                timeToGoal = String(format: "%.0f %@", targetResult.days, daysText)
            } else if targetResult.months < 12 {
                let monthsText = "home.time_to_goal.months".localized(defaultValue: "months")
                timeToGoal = String(format: "%.1f %@", targetResult.months, monthsText)
            } else {
                let yearsText = "home.time_to_goal.years".localized(defaultValue: "years")
                timeToGoal = String(format: "%.1f %@", targetResult.years, yearsText)
            }
        }
    }
    
    /// Updates the formatted savings goal display
    private func updateSavingsGoalDisplay() {
        if savingsGoal > 0 {
            formattedSavingsGoal = formatCurrencyWithCents(savingsGoal, absoluteValue: false)
        } else {
            formattedSavingsGoal = ""
        }
    }
    
    /// Loads savings goal from AppSettings
    private func loadSavingsGoal() {
        let context = persistenceService.viewContext
        let fetchRequest: NSFetchRequest<AppSettings> = AppSettings.fetchRequest()
        
        do {
            let settings = try context.fetch(fetchRequest)
            if let appSettings = settings.first {
                savingsGoal = appSettings.savingsGoalAmount
                updateSavingsGoalDisplay()
                calculateTimeToGoal()
            }
        } catch {
            print("Failed to load savings goal: \(error)")
        }
    }
    
    /// Saves savings goal to AppSettings database
    private func saveSavingsGoalToDatabase(_ amount: Double) {
        persistenceService.performBackgroundTask { [weak self] context in
            guard let self = self else { return }
            
            let fetchRequest: NSFetchRequest<AppSettings> = AppSettings.fetchRequest()
            
            do {
                let settings = try context.fetch(fetchRequest)
                let appSettings: AppSettings
                
                if let existingSettings = settings.first {
                    appSettings = existingSettings
                } else {
                    appSettings = AppSettings(context: context)
                }
                
                appSettings.savingsGoalAmount = amount

                // Save is automatically handled by performBackgroundTask

                // Reload widgets to show updated savings goal
                WidgetCenter.shared.reloadAllTimelines()

            } catch {
                print("Failed to save savings goal: \(error)")
            }
        }
    }

    private func applyCurrency(code: String) {
        let resolvedCode = CurrencyHelper.supportedCurrencyCodes.contains(code) ? code : CurrencyHelper.defaultCurrencyCode()
        guard resolvedCode != currencyCode else { return }
        currencyCode = resolvedCode

        isPositive = liveValue >= 0
        formattedLiveValue = formatLiveCurrency(liveValue)
        updateCumulativeDisplay(sessionNet: liveValue - sessionBaseline)
        updateSavingsGoalDisplay() // Update savings goal formatting when currency changes
    }
    
    // MARK: - Notification Handlers
    
    @objc private func appDidEnterBackground() {
        Task { @MainActor in
            saveAppSettings()
            stopTimer()
        }
    }
    
    @objc private func appWillEnterForeground() {
        Task { @MainActor in
            loadAllData()
            sessionStartTime = Date()
            startTimer()
        }
    }

    @objc private func currencyDidChange(_ notification: Notification) {
        if let code = notification.userInfo?["code"] as? String {
            applyCurrency(code: code)
        } else {
            let context = persistenceService.viewContext
            let fetchRequest: NSFetchRequest<AppSettings> = AppSettings.fetchRequest()
            if let settings = try? context.fetch(fetchRequest),
               let storedCode = settings.first?.preferredCurrencyCode {
                applyCurrency(code: storedCode)
            }
        }
    }
    
    @objc private func languageDidChange(_ notification: Notification) {
        // Trigger UI refresh to re-evaluate localized strings
        DispatchQueue.main.async {
            self.calculateTimeToGoal() // Recalculate with new language
            self.objectWillChange.send() // Force UI refresh
        }
    }
    
    private func saveAppSettings() {
        // Perform the save operation on a background thread to avoid blocking
        persistenceService.performBackgroundTask { [weak self] context in
            guard let self = self else { return }
            
            let fetchRequest: NSFetchRequest<AppSettings> = AppSettings.fetchRequest()
            
            do {
                let settings = try context.fetch(fetchRequest)
                let appSettings: AppSettings
                
                if let existingSettings = settings.first {
                    appSettings = existingSettings
                } else {
                    appSettings = AppSettings(context: context)
                }
                
                let sessionNet = self.liveValue - self.sessionBaseline
                let updatedCumulativeTotal = self.cumulativeBaseline + sessionNet
                let roundedCumulativeTotal = (updatedCumulativeTotal * 100).rounded() / 100

                if appSettings.cumulativeStartDate == nil {
                    appSettings.cumulativeStartDate = self.cumulativeStartDate
                }

                appSettings.cumulativeTotal = roundedCumulativeTotal
                appSettings.lastMeterValue = self.liveValue
                appSettings.lastBackgroundedTimestamp = Date()

                // The save is automatically handled by performBackgroundTask

                // Reload widgets to show updated data
                WidgetCenter.shared.reloadAllTimelines()

                // After saving, update the UI on the main thread
                Task { @MainActor in
                    // Safely update the baseline on the main thread
                    self.cumulativeBaseline = roundedCumulativeTotal
                    self.updateCumulativeDisplay()
                }
                
            } catch {
                print("Failed to save app settings in background: \(error)")
            }
        }
    }
}
