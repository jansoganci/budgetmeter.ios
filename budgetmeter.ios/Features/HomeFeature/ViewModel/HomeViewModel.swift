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
    @Published var totalDaysInMonth: Int = 30
    @Published var showingDailyBudgetInfo = false

    // Month Summary Data (for compact layout)
    @Published var totalMonthlyIncomeDisplay: Double = 0
    @Published var totalMonthlyExpenseDisplay: Double = 0
    @Published var incomeTrendPercentage: Double? = nil
    @Published var expenseTrendPercentage: Double? = nil

    // Primary Savings Goal Data (for compact layout)
    @Published var primarySavingsGoalName: String? = nil
    @Published var primarySavingsGoalEmoji: String? = nil
    @Published var primarySavingsGoalCurrent: Double = 0
    @Published var primarySavingsGoalTarget: Double = 0

    // Phase 3 — Momentum display fields (from FinancialSummary)
    @Published var netDailyPace: Double = 0
    @Published var netMinutePace: Double = 0
    @Published var paceStatus: PaceStatus = .insufficientData
    @Published var paceStatusCopy: String = ""
    @Published var biggestDrain: DrainItem? = nil
    @Published var savingsRemaining: Double = 0
    @Published var savingsTimeToGoal: CalculationEngine.TargetTimeResult? = nil

    // State Management
    @Published var isLoading = false
    @Published var hasAnyData = false
    @Published var showingIncomeSheet = false
    @Published var showingExpenseSheet = false
    
    // MARK: - Private Properties

    private let persistenceService: PersistenceService
    private let summaryBuilder: FinancialSummaryBuilder
    private let goalManager: SavingsGoalManager
    private var cancellables = Set<AnyCancellable>()
    private var timer: Timer?
    private var sessionStartTime: Date
    private var sessionBaseline: Double = 0
    private var cumulativeBaseline: Double = 0
    private var cumulativeStartDate: Date = Date()
    private var latestSummary: FinancialSummary?
    var currencyCode: String = CurrencyHelper.defaultCurrencyCode()

    // Prevent timer race conditions
    private var isUpdatingLiveValue: Bool = false
    
    // MARK: - Initialization
    
    init(
        persistenceService: PersistenceService = .shared,
        summaryBuilder: FinancialSummaryBuilder? = nil,
        goalManager: SavingsGoalManager? = nil
    ) {
        self.persistenceService = persistenceService
        self.summaryBuilder = summaryBuilder ?? FinancialSummaryBuilder(context: persistenceService.viewContext)
        self.goalManager = goalManager ?? SavingsGoalManager(persistence: persistenceService)
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
    
    // MARK: - Computed Properties (Greeting)

    /// Time-based greeting text
    var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return String(localized: "home.greeting.morning", defaultValue: "Good morning!")
        case 12..<17:
            return String(localized: "home.greeting.afternoon", defaultValue: "Good afternoon!")
        case 17..<21:
            return String(localized: "home.greeting.evening", defaultValue: "Good evening!")
        default:
            return String(localized: "home.greeting.night", defaultValue: "Good night!")
        }
    }

    /// SF Symbol for time-based greeting icon
    var greetingIcon: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "sun.max.fill"
        case 12..<17: return "sun.min.fill"
        case 17..<21: return "sunset.fill"
        default: return "moon.stars.fill"
        }
    }

    /// Currency symbol for display
    var currencySymbol: String {
        CurrencyHelper.symbol(for: currencyCode)
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
    
    /// Updates savings goal via the primary active SavingsGoal entity.
    func updateSavingsGoal(_ amount: Double) {
        let clamped = max(0, amount)
        let goalName = String(localized: "savings.basic_goal.name", defaultValue: "My Savings Goal")

        if clamped > 0 {
            _ = goalManager.upsertPrimaryBasicGoal(
                targetAmount: clamped,
                name: goalName
            )
        } else if let primary = goalManager.getPrimaryActiveGoal(), let id = primary.id {
            _ = goalManager.updateGoal(id: id, targetAmount: 0)
        }

        refresh()
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

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(savingsGoalDidChange),
            name: SavingsGoalManager.goalAddedNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(savingsGoalDidChange),
            name: SavingsGoalManager.goalUpdatedNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(savingsGoalDidChange),
            name: SavingsGoalManager.goalDeletedNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(savingsGoalDidChange),
            name: SavingsGoalManager.goalCompletedNotification,
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

        guard let summary = latestSummary else { return }

        let sessionNet = CalculationEngine.calculateLiveNetFlow(
            netHourlyFlow: summary.netPacePerHour,
            elapsedSeconds: sessionElapsed
        )

        liveValue = sessionBaseline + sessionNet
        isPositive = liveValue >= 0

        formattedLiveValue = formatLiveCurrency(liveValue)
        sessionDuration = formatDuration(sessionElapsed)
        updateCumulativeDisplay(sessionNet: sessionNet)
    }
    
    private func loadAllData() {
        isLoading = true
        loadAppSettings()
        loadPrimarySavingsGoal()

        let elapsed = Date().timeIntervalSince(sessionStartTime)
        let summary = summaryBuilder.build(sessionElapsedSeconds: elapsed)
        latestSummary = summary
        applyFinancialSummary(summary)

        isLoading = false
    }

    private func applyFinancialSummary(_ summary: FinancialSummary) {
        let resolvedCode = summary.currencyCode
        if CurrencyHelper.supportedCurrencyCodes.contains(resolvedCode) {
            currencyCode = resolvedCode
        }

        netDailyPace = summary.netPacePerDay
        netMinutePace = summary.netPacePerMinute
        paceStatus = summary.paceStatus
        paceStatusCopy = HomeDisplayMapping.paceStatusCopy(
            status: summary.paceStatus,
            netDailyPace: summary.netPacePerDay,
            currencySymbol: currencySymbol
        )
        biggestDrain = summary.biggestDrain
        savingsRemaining = summary.savingsRemaining
        savingsTimeToGoal = summary.savingsTimeToGoal

        dailyNetFlow = summary.netPacePerDay
        hourlyNetFlow = summary.netPacePerHour
        monthlyNetFlow = summary.netPacePerMonth
        totalMonthlyIncomeDisplay = summary.recurringIncomeMonthly
        totalMonthlyExpenseDisplay = summary.recurringExpenseMonthly

        savingsGoal = summary.savingsTargetAmount
        primarySavingsGoalCurrent = summary.savingsCurrentAmount
        primarySavingsGoalTarget = summary.savingsTargetAmount
        updateSavingsGoalDisplay()
        timeToGoal = HomeDisplayMapping.formatSavingsETA(from: summary)

        hasAnyData = HomeDisplayMapping.hasFinancialInput(in: summary)

        let healthScore = CalculationEngine.financialHealthScore(
            totalMonthlyIncome: summary.recurringIncomeMonthly,
            totalMonthlyExpense: summary.recurringExpenseMonthly
        )
        financialHealthScore = healthScore.score
        financialHealthText = healthScore.text
        financialHealthColor = colorFromString(healthScore.color)

        hourlyChartData = []
        dailyChartData = []
        monthlyChartData = []
        netFlowTrendPercentage = nil
        incomeTrendPercentage = nil
        expenseTrendPercentage = nil

        calculateDailyBudget(from: summary)
        updateLiveValue()
        publishWidgetSnapshot(from: summary)
    }

    private func publishWidgetSnapshot(from summary: FinancialSummary) {
        WidgetSnapshotWriter.persistAndReload(
            summary: summary,
            isPremium: PremiumManager.shared.isPremium,
            currencySymbol: currencySymbol
        )
    }

    /// Calculates daily budget from shared summary monthly net pace.
    private func calculateDailyBudget(from summary: FinancialSummary) {
        let monthlyNet = summary.netPacePerMonth
        let calendar = Calendar.current
        let today = Date()
        let daysInMonth = calendar.range(of: .day, in: .month, for: today)?.count ?? 30
        let currentDay = calendar.component(.day, from: today)
        let daysLeft = max(1, daysInMonth - currentDay + 1)

        dailyBudgetAmount = monthlyNet / Double(daysLeft)
        daysLeftInMonth = daysLeft
        totalDaysInMonth = daysInMonth

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
    
    /// Updates the formatted savings goal display
    private func updateSavingsGoalDisplay() {
        if savingsGoal > 0 {
            formattedSavingsGoal = formatCurrencyWithCents(savingsGoal, absoluteValue: false)
        } else {
            formattedSavingsGoal = ""
        }
    }
    
    /// Loads primary savings goal metadata for Home display.
    private func loadPrimarySavingsGoal() {
        if let primaryGoal = goalManager.getPrimaryActiveGoal() {
            primarySavingsGoalName = primaryGoal.name
            primarySavingsGoalEmoji = primaryGoal.emoji
        } else {
            primarySavingsGoalName = nil
            primarySavingsGoalEmoji = nil
        }
    }

    @objc private func savingsGoalDidChange() {
        refresh()
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
        if let summary = latestSummary {
            applyFinancialSummary(summary)
        }
        objectWillChange.send()
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

                // Refresh widget snapshot after background save
                Task { @MainActor in
                    WidgetSnapshotService.refreshFromCurrentData()
                }

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
