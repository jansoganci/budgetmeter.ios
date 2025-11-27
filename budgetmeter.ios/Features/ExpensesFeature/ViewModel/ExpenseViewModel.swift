//
//  ExpenseViewModel.swift
//  BudgetMeter
//
//  Created by BudgetMeter Team on 17.09.2025.
//

import Foundation
import SwiftUI
import CoreData
import Combine
import WidgetKit

/// ViewModel for the Expense screen following MVVM architecture
@MainActor
final class ExpenseViewModel: ObservableObject {
    
    // MARK: - Published Properties

    @Published var dailyExpenses: [FinancialCategory] = []
    @Published var monthlyExpenses: [FinancialCategory] = []
    @Published var yearlyExpenses: [FinancialCategory] = []
    @Published var subscriptions: [Subscription] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published private(set) var currencySymbol: String = CurrencyHelper.symbol(for: CurrencyHelper.defaultCurrencyCode())
    
    // MARK: - Summary Computed Properties

    var totalMonthlyExpenses: Double {
        let dailyTotal = dailyExpenses.reduce(0) { $0 + $1.amount }
        let monthlyTotal = monthlyExpenses.reduce(0) { $0 + $1.amount }
        let yearlyTotal = yearlyExpenses.reduce(0) { $0 + $1.amount }
        let subscriptionsTotal = subscriptionsTotalMonthly

        // Use CalculationEngine for consistency
        return CalculationEngine.totalMonthlyExpense(
            dailyTotal: dailyTotal,
            monthlyTotal: monthlyTotal,
            yearlyTotal: yearlyTotal
        ) + subscriptionsTotal
    }

    /// Total monthly cost of all subscriptions
    var subscriptionsTotalMonthly: Double {
        return SubscriptionManager.shared.getTotalMonthlyCost()
    }

    /// Total yearly cost of all subscriptions
    var subscriptionsTotalYearly: Double {
        return SubscriptionManager.shared.getTotalYearlyCost()
    }

    /// Number of active subscriptions
    var subscriptionsCount: Int {
        return subscriptions.count
    }

    var dailyAverageExpenses: Double {
        return totalMonthlyExpenses / CalculationEngine.daysPerMonth
    }
    
    var yearlyProjectionExpenses: Double {
        return totalMonthlyExpenses * 12
    }

    /// Number of expense sources with amounts > 0
    var activeSourcesCount: Int {
        let allCategories = dailyExpenses + monthlyExpenses + yearlyExpenses
        let categoryCount = allCategories.filter { $0.amount > 0 }.count
        return categoryCount + subscriptionsCount
    }
    
    // MARK: - Localized Summary Titles
    
    var monthlyTitle: String {
        return "expenses.summary.monthly".localized(defaultValue: "Monthly")
    }
    
    var dailyAvgTitle: String {
        return "expenses.summary.daily_avg".localized(defaultValue: "Daily Avg")
    }
    
    var yearlyTitle: String {
        return "expenses.summary.yearly".localized(defaultValue: "Yearly")
    }
    
    var summaryTitle: String {
        return "expenses.summary.title".localized(defaultValue: "Expense Overview")
    }
    
    // MARK: - Private Properties
    
    private let persistenceService: PersistenceService
    private var cancellables = Set<AnyCancellable>()
    private var currencyCode: String = CurrencyHelper.defaultCurrencyCode()

    // MARK: - Initialization

    init(persistenceService: PersistenceService = .shared) {
        self.persistenceService = persistenceService
        setupCurrencyObserver()
        setupLanguageObserver()
        setupSubscriptionObservers()
        loadCurrency()
        loadExpenseCategories()
        loadSubscriptions()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Public Methods
    
    /// Updates the amount for a specific expense category
    func updateAmount(for category: FinancialCategory, amount: Double) {
        category.amount = amount
        persistenceService.save()

        // Reload data to reflect changes immediately
        loadExpenseCategories()

        // Reload widgets to show updated expense data
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Updates the color for a custom category
    func updateColor(for category: FinancialCategory, color: CategoryColor) {
        guard category.isCustom else { return }
        category.customColorHex = color.rawValue
        persistenceService.save()

        // Reload to reflect changes
        loadExpenseCategories()
    }
    
    /// Formats amount for display in input field (no live formatting during input)
    func formatInputAmount(_ amount: Double) -> String {
        if amount <= 0 {
            return ""
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        formatter.locale = Locale(identifier: "en_US") // Standardized formatting (1234.56)
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        
        return formatter.string(from: NSNumber(value: amount)) ?? "0"
    }
    
    /// Parses input string to Double amount with validation
    func parseAmount(from input: String) -> Double {
        // Remove any non-numeric characters except decimal point
        let cleanedInput = input.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)

        // Handle empty input
        if cleanedInput.isEmpty {
            return 0
        }

        guard let amount = Double(cleanedInput) else {
            return 0
        }

        // Validate maximum value (prevent overflow and unrealistic amounts)
        // Max: 1 billion (prevents display issues and calculation overflow)
        let maxAmount: Double = 1_000_000_000

        // Validate minimum value
        let minAmount: Double = 0

        // Clamp to valid range
        return min(max(amount, minAmount), maxAmount)
    }
    
    /// Formats amount for currency display (shown when not editing)
    func formatCurrencyDisplay(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_US") // Standardized formatting (1,234.56)
        formatter.currencyCode = currencyCode
        formatter.currencySymbol = CurrencyHelper.symbol(for: currencyCode)
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        
        return formatter.string(from: NSNumber(value: amount)) ?? "\(currencySymbol)0"
    }
    
    /// Gets the localized display name for a category
    func displayName(for category: FinancialCategory) -> String {
        guard let uniqueID = category.uniqueID else { return "Unknown" }
        return DataSeedingService.displayName(for: uniqueID)
    }
    
    /// Gets the SF Symbol name for a category
    func sfSymbolName(for category: FinancialCategory) -> String {
        guard let uniqueID = category.uniqueID else { return "questionmark.circle" }
        return DataSeedingService.sfSymbolName(for: uniqueID)
    }
    
    /// Refreshes data from Core Data
    func refresh() {
        loadExpenseCategories()
        loadSubscriptions()
    }

    /// Load all subscriptions
    func loadSubscriptions() {
        subscriptions = SubscriptionManager.shared.getAllActiveSubscriptions()
    }

    /// Delete a subscription
    func deleteSubscription(_ subscription: Subscription) {
        guard let id = subscription.id else { return }
        let success = SubscriptionManager.shared.deleteSubscription(id: id)
        if success {
            loadSubscriptions()
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    /// Format subscription amount
    func formatSubscriptionAmount(_ subscription: Subscription) -> String {
        let amount = subscription.amount
        return CurrencyHelper.format(amount: amount, currencyCode: currencyCode)
    }

    /// Get billing cycle text for subscription
    func subscriptionBillingCycle(_ subscription: Subscription) -> String {
        guard let cycle = subscription.billingCycle else { return "/mo" }
        switch cycle.lowercased() {
        case "monthly": return "/mo"
        case "yearly": return "/yr"
        case "weekly": return "/wk"
        default: return "/mo"
        }
    }

    /// Formatted subscriptions subtotal for section header
    var formattedSubscriptionsSubtotal: String {
        let total = subscriptionsTotalMonthly
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        formatter.groupingSeparator = ","
        let formatted = formatter.string(from: NSNumber(value: total)) ?? "0"
        return "\(currencySymbol)\(formatted)/mo"
    }

    /// Deletes a custom expense category
    func deleteCategory(_ category: FinancialCategory) {
        guard category.isCustom else { return }

        let context = persistenceService.viewContext
        context.delete(category)
        persistenceService.save()

        // Reload to update UI
        loadExpenseCategories()

        // Reload widgets
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Private Methods
    
    private func loadExpenseCategories() {
        isLoading = true
        errorMessage = nil
        
        let context = persistenceService.viewContext
        let fetchRequest: NSFetchRequest<FinancialCategory> = FinancialCategory.fetchRequest()
        
        // Fetch only expense categories
        fetchRequest.predicate = NSPredicate(format: "type == %@", "expense")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \FinancialCategory.uniqueID, ascending: true)]
        
        do {
            let allExpenses = try context.fetch(fetchRequest)
            
            // Separate by frequency
            dailyExpenses = allExpenses.filter { $0.frequency == "daily" }
            monthlyExpenses = allExpenses.filter { $0.frequency == "monthly" }
            yearlyExpenses = allExpenses.filter { $0.frequency == "yearly" }
            
            isLoading = false
        } catch {
            print("📊 ExpenseViewModel: ❌ Loading failed: \(error)")
            let baseMessage = "expenses.error.load".localized(defaultValue: "Failed to load expense categories.")
            errorMessage = "\(baseMessage) \(error.localizedDescription)"
            isLoading = false
        }
    }
}

// MARK: - Category Grouping Helper

extension ExpenseViewModel {

    /// Groups categories by frequency for easier UI rendering
    /// Uses red color scheme for expenses as per design rulebook
    var categoryGroups: [(title: String, categories: [FinancialCategory], color: Color)] {
        [
            (
                title: "frequency.daily".localized(defaultValue: "Daily"),
                categories: dailyExpenses,
                color: .red
            ),
            (
                title: "frequency.monthly".localized(defaultValue: "Monthly"),
                categories: monthlyExpenses,
                color: .orange
            ),
            (
                title: "frequency.yearly".localized(defaultValue: "Yearly"),
                categories: yearlyExpenses,
                color: Color(hex: "6B7280") // Secondary color from design rulebook
            )
        ]
    }

    /// Checks if any expense categories have been entered
    var hasExpenseData: Bool {
        let allCategories = dailyExpenses + monthlyExpenses + yearlyExpenses
        return allCategories.contains { category in
            return category.amount > 0
        }
    }

    // MARK: - Subtotal Methods for Collapsible Sections

    /// Returns the raw subtotal for a given frequency
    func subtotalForFrequency(_ frequency: String) -> Double {
        switch frequency {
        case "daily":
            return dailyExpenses.reduce(0) { $0 + $1.amount }
        case "monthly":
            return monthlyExpenses.reduce(0) { $0 + $1.amount }
        case "yearly":
            return yearlyExpenses.reduce(0) { $0 + $1.amount }
        default:
            return 0
        }
    }

    /// Returns formatted subtitle for section header (e.g., "$150/day", "$5,983/mo", "$71,796/yr")
    func formattedSubtotal(_ frequency: String) -> String {
        let total = subtotalForFrequency(frequency)

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        formatter.groupingSeparator = ","

        let formatted = formatter.string(from: NSNumber(value: total)) ?? "0"

        switch frequency {
        case "daily":
            return "\(currencySymbol)\(formatted)/day"
        case "monthly":
            return "\(currencySymbol)\(formatted)/mo"
        case "yearly":
            return "\(currencySymbol)\(formatted)/yr"
        default:
            return "\(currencySymbol)\(formatted)"
        }
    }

    /// Returns section title for a given frequency
    func sectionTitle(_ frequency: String) -> String {
        switch frequency {
        case "daily":
            return String(localized: "expense.section.daily", defaultValue: "Daily Expenses")
        case "monthly":
            return String(localized: "expense.section.monthly", defaultValue: "Monthly Expenses")
        case "yearly":
            return String(localized: "expense.section.yearly", defaultValue: "Yearly Expenses")
        default:
            return String(localized: "expense.section.other", defaultValue: "Other Expenses")
        }
    }

    /// Returns categories for a given frequency
    func categoriesForFrequency(_ frequency: String) -> [FinancialCategory] {
        switch frequency {
        case "daily":
            return dailyExpenses
        case "monthly":
            return monthlyExpenses
        case "yearly":
            return yearlyExpenses
        default:
            return []
        }
    }
}

// MARK: - Currency Handling

private extension ExpenseViewModel {
    func setupCurrencyObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(currencyDidChange(_:)),
            name: .currencyDidChange,
            object: nil
        )
    }
    
    func setupLanguageObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(languageDidChange(_:)),
            name: .languageDidChange,
            object: nil
        )
    }

    func setupSubscriptionObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(subscriptionsDidChange),
            name: SubscriptionManager.subscriptionAddedNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(subscriptionsDidChange),
            name: SubscriptionManager.subscriptionUpdatedNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(subscriptionsDidChange),
            name: SubscriptionManager.subscriptionDeletedNotification,
            object: nil
        )
    }

    @objc func subscriptionsDidChange() {
        loadSubscriptions()
    }
    


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
        currencySymbol = CurrencyHelper.symbol(for: resolvedCode)
    }

    @objc func currencyDidChange(_ notification: Notification) {
        if let code = notification.userInfo?["code"] as? String {
            updateCurrency(code: code)
        } else {
            loadCurrency()
        }
    }
    
    @objc func languageDidChange(_ notification: Notification) {
        // Trigger UI refresh to re-evaluate localized strings in summary cards
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
    

}
