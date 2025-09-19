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
    @Published var financialHealthScore: Int = 0
    @Published var financialHealthText: String = "Getting Started"
    @Published var financialHealthColor: Color = .secondary
    @Published var cumulativeDisplayAmount: String = "$0.00"
    @Published var cumulativeSinceDateText: String = ""
    @Published var cumulativeFlowColor: Color = .secondary
    
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
    private var currencyCode: String = CurrencyHelper.defaultCurrencyCode()
    
    // Financial data cache
    private var dailyIncomeTotal: Double = 0
    private var monthlyIncomeTotal: Double = 0
    private var yearlyIncomeTotal: Double = 0
    private var dailyExpenseTotal: Double = 0
    private var monthlyExpenseTotal: Double = 0
    private var yearlyExpenseTotal: Double = 0

    private let cumulativeDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
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
        cumulativeSinceDateText = cumulativeDateFormatter.string(from: cumulativeStartDate)
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

    private func applyCurrency(code: String) {
        let resolvedCode = CurrencyHelper.supportedCurrencyCodes.contains(code) ? code : CurrencyHelper.defaultCurrencyCode()
        guard resolvedCode != currencyCode else { return }
        currencyCode = resolvedCode

        isPositive = liveValue >= 0
        formattedLiveValue = formatLiveCurrency(liveValue)
        updateCumulativeDisplay(sessionNet: liveValue - sessionBaseline)
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
