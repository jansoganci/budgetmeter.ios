//
//  HealthDetailsViewModel.swift
//  BudgetMeter
//
//  Phase 1D: Financial Health Details - ViewModel
//  Created by BudgetMeter Team on 17.09.2025.
//

import SwiftUI
import Combine
import Foundation
import CoreData

/// ViewModel for Financial Health Details screen
@MainActor
final class HealthDetailsViewModel: ObservableObject {

    // MARK: - Published Properties

    /// Current health score (0-100)
    @Published var healthScore: Int = 0

    /// Text description of health score (Excellent, Great, Good, etc.)
    @Published var healthText: String = "Getting Started"

    /// Detailed breakdown of health components
    @Published var breakdown: HealthScoreBreakdown?

    /// List of personalized health tips
    @Published var healthTips: [HealthTip] = []

    /// Loading state
    @Published var isLoading: Bool = false

    /// Premium status
    @Published var isPremium: Bool = false

    /// Show premium paywall
    @Published var showPaywall: Bool = false

    /// Currently expanded breakdown category
    @Published var selectedBreakdown: String?

    /// Last updated timestamp
    @Published var lastUpdated: Date = Date()

    /// Error message if data load fails
    @Published var errorMessage: String?

    /// Show error alert
    @Published var showErrorAlert: Bool = false

    // MARK: - Private Properties

    private let persistenceService: PersistenceService
    private let premiumManager: PremiumManager
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(
        persistenceService: PersistenceService = .shared,
        premiumManager: PremiumManager = .shared
    ) {
        self.persistenceService = persistenceService
        self.premiumManager = premiumManager

        // Load initial data
        Task {
            await loadHealthData()
        }

        // Subscribe to premium changes
        premiumManager.$isPremium
            .assign(to: &$isPremium)

        // Listen for language changes
        setupLanguageObserver()
    }

    // MARK: - Public Methods

    /// Load health data from persistence
    func loadHealthData() async {
        isLoading = true
        errorMessage = nil

        do {
            // Fetch financial data
            let (monthlyIncome, monthlyExpense, savingsGoal) = await fetchFinancialData()
            
            guard monthlyIncome > 0 || monthlyExpense > 0 else {
                throw HealthDetailsError.noDataAvailable
            }

            // Calculate health score
            let score = CalculationEngine.calculateFinancialHealthScore(
                monthlyIncome: monthlyIncome,
                monthlyExpense: monthlyExpense,
                savingsGoal: savingsGoal
            )

            // Get health text
            let text = CalculationEngine.healthScoreText(for: score)

            // Calculate breakdown
            let breakdownData = CalculationEngine.calculateHealthScoreBreakdown(
                monthlyIncome: monthlyIncome,
                monthlyExpense: monthlyExpense,
                savingsGoal: savingsGoal
            )

            // Generate health tips
            let tips = CalculationEngine.generateHealthTips(
                breakdown: breakdownData,
                currentIncome: monthlyIncome,
                currentExpense: monthlyExpense,
                savingsGoal: savingsGoal
            )

            // Update UI on main thread
            await MainActor.run {
                self.healthScore = score
                self.healthText = text
                self.breakdown = breakdownData
                self.healthTips = tips
                self.lastUpdated = Date()
                self.isLoading = false
            }

            print("💚 HealthDetails: ✅ Loaded health data - Score: \(score), Tips: \(tips.count)")

        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
                self.showErrorAlert = true
            }
            print("💚 HealthDetails: ❌ Error loading data: \(error)")
        }
    }

    /// Refresh health data (for pull-to-refresh)
    func refreshData() async {
        await loadHealthData()
    }

    /// Toggle breakdown row expansion
    func toggleBreakdown(_ category: String) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            if selectedBreakdown == category {
                selectedBreakdown = nil
            } else {
                selectedBreakdown = category
            }
        }
    }

    /// Check if a breakdown category is expanded
    func isExpanded(_ category: String) -> Bool {
        return selectedBreakdown == category
    }

    /// Share health report
    func shareHealthReport() {
        // Generate shareable text
        let shareText = """
        My BudgetMeter Financial Health Score: \(healthScore)/100 (\(healthText))

        📊 Health Breakdown:
        • Income Score: \(breakdown?.incomeScore ?? 0)/30
        • Expense Score: \(breakdown?.expenseScore ?? 0)/30
        • Savings Score: \(breakdown?.savingsScore ?? 0)/40

        Stay on top of your finances with BudgetMeter! 💚
        """

        // Use UIActivityViewController (will be called from view)
        print("💚 HealthDetails: 📤 Sharing report: \(shareText)")
    }

    /// Show premium paywall
    func showPremiumPaywall() {
        showPaywall = true
    }

    /// Dismiss premium paywall
    func dismissPaywall() {
        showPaywall = false
    }

    /// Clear error state
    func clearError() {
        errorMessage = nil
        showErrorAlert = false
    }

    // MARK: - Private Methods

    /// Fetch financial data from persistence
    private func fetchFinancialData() async -> (monthlyIncome: Double, monthlyExpense: Double, savingsGoal: Double) {
        return await withCheckedContinuation { continuation in
            persistenceService.performBackgroundTask { context in
                // Fetch financial categories
                let request: NSFetchRequest<FinancialCategory> = FinancialCategory.fetchRequest()
                
                do {
                    let categories = try context.fetch(request)
                    
                    let incomeCategories = categories.filter { $0.type == "income" }
                    let expenseCategories = categories.filter { $0.type == "expense" }
                    
                    // Calculate by frequency
                    let dailyIncome = incomeCategories.filter { $0.frequency == "daily" }.reduce(0) { $0 + $1.amount }
                    let monthlyIncome = incomeCategories.filter { $0.frequency == "monthly" }.reduce(0) { $0 + $1.amount }
                    let yearlyIncome = incomeCategories.filter { $0.frequency == "yearly" }.reduce(0) { $0 + $1.amount }
                    
                    let dailyExpense = expenseCategories.filter { $0.frequency == "daily" }.reduce(0) { $0 + $1.amount }
                    let monthlyExpense = expenseCategories.filter { $0.frequency == "monthly" }.reduce(0) { $0 + $1.amount }
                    let yearlyExpense = expenseCategories.filter { $0.frequency == "yearly" }.reduce(0) { $0 + $1.amount }
                    
                    // Convert to monthly equivalents
                    let totalMonthlyIncome = CalculationEngine.totalMonthlyIncome(
                        dailyIncomeTotal: dailyIncome,
                        monthlyIncomeTotal: monthlyIncome,
                        yearlyIncomeTotal: yearlyIncome
                    )
                    
                    let totalMonthlyExpense = CalculationEngine.totalMonthlyExpense(
                        dailyTotal: dailyExpense,
                        monthlyTotal: monthlyExpense,
                        yearlyTotal: yearlyExpense
                    )
                    
                    // Get savings goal from AppSettings
                    let settingsRequest: NSFetchRequest<AppSettings> = AppSettings.fetchRequest()
                    let settings = try context.fetch(settingsRequest).first
                    let savingsGoal = settings?.savingsGoalAmount ?? 0.0
                    
                    continuation.resume(returning: (totalMonthlyIncome, totalMonthlyExpense, savingsGoal))
                } catch {
                    print("💚 HealthDetails: ❌ Failed to fetch financial data: \(error)")
                    continuation.resume(returning: (0.0, 0.0, 0.0))
                }
            }
        }
    }

    // MARK: - Computed Properties

    /// Health score color based on value
    var healthScoreColor: Color {
        switch healthScore {
        case 90...100:
            return .green
        case 75...89:
            return .blue
        case 60...74:
            return .yellow
        case 40...59:
            return .orange
        default:
            return .red
        }
    }

    /// Formatted last updated text
    var lastUpdatedText: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastUpdated, relativeTo: Date())
    }

    /// Has any data loaded
    var hasData: Bool {
        return healthScore > 0 || breakdown != nil
    }

    /// Premium tips only (filtered)
    var premiumTips: [HealthTip] {
        return healthTips.filter { _ in !isPremium }
    }

    /// Available tips (free or premium if unlocked)
    var availableTips: [HealthTip] {
        if isPremium {
            return healthTips
        } else {
            // Show first 3 tips, rest are premium
            return Array(healthTips.prefix(3))
        }
    }

    // MARK: - Language Observer

    private func setupLanguageObserver() {
        NotificationCenter.default.publisher(for: .languageDidChange)
            .sink { [weak self] _ in
                // Trigger UI refresh to re-evaluate localized strings
                DispatchQueue.main.async {
                    self?.objectWillChange.send()
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - Health Details Error

enum HealthDetailsError: Error {
    case noDataAvailable
    case calculationFailed

    var localizedDescription: String {
        switch self {
        case .noDataAvailable:
            return "health.error.no_data".localized(defaultValue: "No financial data available. Please set up your budget first.")
        case .calculationFailed:
            return "health.error.calculation_failed".localized(defaultValue: "Failed to calculate health score. Please try again.")
        }
    }
}
