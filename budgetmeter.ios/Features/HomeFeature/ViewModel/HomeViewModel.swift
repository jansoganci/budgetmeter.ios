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
    private var savedMeterValue: Double = 0
    
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
        Task { @MainActor in
            stopTimer()
        }
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
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.currencySymbol = String(localized: "currency.symbol")
        formatter.maximumFractionDigits = 0
        
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
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
        
        // Add saved meter value
        liveValue = savedMeterValue + liveNetFlow
        isPositive = liveValue >= 0
        
        // Format for display
        formattedLiveValue = formatLiveCurrency(liveValue)
        sessionDuration = formatDuration(sessionElapsed)
    }
    
    private func loadAllData() {
        isLoading = true
        
        let context = persistenceService.viewContext
        let fetchRequest: NSFetchRequest<FinancialCategory> = FinancialCategory.fetchRequest()
        
        do {
            let allCategories = try context.fetch(fetchRequest)
            
            // Calculate totals
            let incomeCategories = allCategories.filter { $0.type == "income" }
            dailyIncomeTotal = incomeCategories.filter { $0.frequency == "daily" }.reduce(0) { $0 + $1.amount }
            monthlyIncomeTotal = incomeCategories.filter { $0.frequency == "monthly" }.reduce(0) { $0 + $1.amount }
            yearlyIncomeTotal = incomeCategories.filter { $0.frequency == "yearly" }.reduce(0) { $0 + $1.amount }
            
            let expenseCategories = allCategories.filter { $0.type == "expense" }
            dailyExpenseTotal = expenseCategories.filter { $0.frequency == "daily" }.reduce(0) { $0 + $1.amount }
            monthlyExpenseTotal = expenseCategories.filter { $0.frequency == "monthly" }.reduce(0) { $0 + $1.amount }
            yearlyExpenseTotal = expenseCategories.filter { $0.frequency == "yearly" }.reduce(0) { $0 + $1.amount }
            
            // Check if user has any data
            hasAnyData = allCategories.contains { $0.amount > 0 }
            
            // Calculate snapshot metrics
            calculateSnapshotMetrics()
            
            // Load app settings
            loadAppSettings()
            
            isLoading = false
        } catch {
            print("Failed to load data: \(error)")
            isLoading = false
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
            let settings = try context.fetch(fetchRequest)
            if let appSettings = settings.first {
                savedMeterValue = appSettings.lastMeterValue
            }
        } catch {
            print("Failed to load app settings: \(error)")
        }
    }
    
    private func formatLiveCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.currencySymbol = String(localized: "currency.symbol")
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        
        return formatter.string(from: NSNumber(value: abs(amount))) ?? "$0.00"
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
    
    private func saveAppSettings() {
        let context = persistenceService.viewContext
        let fetchRequest: NSFetchRequest<AppSettings> = AppSettings.fetchRequest()
        
        do {
            let settings = try context.fetch(fetchRequest)
            let appSettings: AppSettings
            
            if let existingSettings = settings.first {
                appSettings = existingSettings
            } else {
                appSettings = AppSettings(context: context)
            }
            
            appSettings.lastMeterValue = liveValue
            appSettings.lastBackgroundedTimestamp = Date()
            
            persistenceService.save()
        } catch {
            print("Failed to save app settings: \(error)")
        }
    }
}
