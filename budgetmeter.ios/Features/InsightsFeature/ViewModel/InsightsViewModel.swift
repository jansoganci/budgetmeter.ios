//
//  InsightsViewModel.swift
//  BudgetMeter
//
//  Phase 1B: Insights Dashboard
//  Created by BudgetMeter Team on 17.09.2025.
//

import Foundation
import SwiftUI
import CoreData
import Combine

/// ViewModel for Phase 1B Insights Dashboard
/// Manages automated insights, chart data, and premium state
@MainActor
final class InsightsViewModel: ObservableObject {

    // MARK: - Published Properties

    /// Array of automated insights from InsightsService
    @Published var insights: [Insight] = []

    /// Loading state
    @Published var isLoading = false

    /// Error message if data loading fails
    @Published var errorMessage: String?

    /// Premium status
    @Published var isPremium = false

    /// Show paywall
    @Published var showPaywall = false

    // MARK: - Chart Data

    /// Data for spending breakdown pie chart
    @Published var spendingBreakdown: [(category: String, amount: Double, percentage: Double)] = []

    /// Data for month comparison bar chart
    @Published var monthComparison: (current: FinancialSnapshot?, previous: FinancialSnapshot?)?

    /// Data for balance trend line chart
    @Published var balanceTrend: [FinancialSnapshot] = []

    // MARK: - Private Properties

    private let insightsService: InsightsService
    private let historicalService: HistoricalDataService
    private let premiumManager: PremiumManager
    private let persistenceService: PersistenceService
    private var cancellables = Set<AnyCancellable>()
    private var currencyCode: String = CurrencyHelper.defaultCurrencyCode()

    // MARK: - Initialization

    init(
        insightsService: InsightsService = .shared,
        historicalService: HistoricalDataService = .shared,
        premiumManager: PremiumManager = .shared,
        persistenceService: PersistenceService = .shared
    ) {
        self.insightsService = insightsService
        self.historicalService = historicalService
        self.premiumManager = premiumManager
        self.persistenceService = persistenceService

        setupObservers()
        loadCurrency()
        loadData()
    }

    // MARK: - Public Methods

    /// Load all insights and chart data
    func loadData() {
        // Check premium status first
        isPremium = premiumManager.hasInsights

        // Only load data if user has access
        guard isPremium else {
            showPaywall = true
            return
        }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                // Load insights from InsightsService
                let generatedInsights = insightsService.generateInsights()

                // Load chart data from HistoricalDataService
                let breakdown = insightsService.calculateSpendingBreakdown()
                let comparison = historicalService.getMonthlyComparison()
                let trend = historicalService.getDailyTrend(days: 30)

                await MainActor.run {
                    self.insights = generatedInsights
                    self.spendingBreakdown = breakdown
                    self.monthComparison = comparison
                    self.balanceTrend = trend
                    self.isLoading = false
                }

                print("📊 InsightsViewModel: Loaded \(generatedInsights.count) insights")
            } catch {
                await MainActor.run {
                    let errorFormat = "insights.error.load_failed".localized(defaultValue: "Failed to load insights: %@")
                    self.errorMessage = String(format: errorFormat, error.localizedDescription)
                    self.isLoading = false
                }
                print("📊 InsightsViewModel: ❌ Error loading data: \(error)")
            }
        }
    }

    /// Refresh insights data
    func refresh() async {
        print("📊 InsightsViewModel: Refreshing data...")

        // Save a snapshot first to ensure we have latest data
        historicalService.saveDailySnapshot()

        // Wait a moment for the save to complete
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

        // Reload all data
        await MainActor.run {
            loadData()
        }
    }

    /// Handle premium upgrade
    func upgradeToPremium() {
        showPaywall = true
    }

    /// Dismiss paywall
    func dismissPaywall() {
        showPaywall = false

        // Recheck premium status after paywall dismissal
        isPremium = premiumManager.hasInsights

        // If user upgraded, load data
        if isPremium {
            loadData()
        }
    }

    // MARK: - Data Access Methods

    /// Get the biggest spending category
    func getBiggestCategory() -> (name: String, amount: Double)? {
        return insightsService.getBiggestCategory()
    }

    /// Get current savings rate
    func getSavingsRate() -> Double {
        return insightsService.getSavingsRate()
    }

    /// Get balance trend direction
    func getBalanceTrendDirection() -> (trend: String, change: Double) {
        return insightsService.getBalanceTrend()
    }

    /// Get month over month comparison
    func getMonthOverMonthComparison() -> (percentageChange: Double, isImprovement: Bool)? {
        return insightsService.getMonthComparison()
    }

    // MARK: - Private Methods

    private func setupObservers() {
        // Observe premium status changes
        premiumManager.$isPremium
            .sink { [weak self] isPremium in
                guard let self else { return }
                self.isPremium = PremiumManager.hasAccess(to: BudgetMeterCapability.spendingInsights, isPremium: isPremium)
                if self.isPremium {
                    self.loadData()
                }
            }
            .store(in: &cancellables)

        // Observe Core Data changes
        NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self, self.isPremium else { return }
                self.loadData()
            }
            .store(in: &cancellables)

        // Listen for language changes
        NotificationCenter.default.publisher(for: .languageDidChange)
            .sink { [weak self] _ in
                // Trigger UI refresh to re-evaluate localized strings
                DispatchQueue.main.async {
                    self?.objectWillChange.send()
                }
            }
            .store(in: &cancellables)

        // Listen for currency changes
        NotificationCenter.default.publisher(for: .currencyDidChange)
            .sink { [weak self] notification in
                self?.currencyDidChange(notification)
            }
            .store(in: &cancellables)
    }

    // MARK: - Currency Management

    func loadCurrency() {
        let context = persistenceService.viewContext
        let fetchRequest: NSFetchRequest<AppSettings> = AppSettings.fetchRequest()
        if let settings = try? context.fetch(fetchRequest),
           let storedCode = settings.first?.preferredCurrencyCode,
           CurrencyHelper.supportedCurrencyCodes.contains(storedCode) {
            updateCurrency(code: storedCode)
        } else {
            updateCurrency(code: CurrencyHelper.defaultCurrencyCode())
        }
    }

    func updateCurrency(code: String) {
        let resolvedCode = CurrencyHelper.supportedCurrencyCodes.contains(code) ? code : CurrencyHelper.defaultCurrencyCode()
        currencyCode = resolvedCode
    }

    @objc func currencyDidChange(_ notification: Notification) {
        if let code = notification.userInfo?["code"] as? String {
            updateCurrency(code: code)
        } else {
            loadCurrency()
        }
        // Trigger UI refresh
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }

    // MARK: - Formatting

    func formatAmount(_ amount: Double) -> String {
        CurrencyHelper.format(amount: amount, currencyCode: currencyCode)
    }
}

// MARK: - Chart Data Helpers

extension InsightsViewModel {

    /// Format spending breakdown for pie chart
    var pieChartData: [(String, Double)] {
        return spendingBreakdown.prefix(5).map { ($0.category, $0.amount) }
    }

    /// Format month comparison for bar chart
    var barChartData: [(String, Double)] {
        guard let comparison = monthComparison,
              let current = comparison.current,
              let previous = comparison.previous else {
            return []
        }

        return [
            ("insights.chart.last_month".localized(defaultValue: "Last Month"), previous.totalExpense),
            ("insights.chart.this_month".localized(defaultValue: "This Month"), current.totalExpense)
        ]
    }

    /// Format balance trend for line chart
    var lineChartData: [(Date, Double)] {
        return balanceTrend.map { ($0.date ?? Date(), $0.balance) }
    }

    /// Check if there's enough data to show charts
    var hasEnoughData: Bool {
        return !spendingBreakdown.isEmpty || !balanceTrend.isEmpty
    }

    /// Get the total expense for the current month
    var totalMonthlyExpense: Double {
        return spendingBreakdown.reduce(0) { $0 + $1.amount }
    }
}
