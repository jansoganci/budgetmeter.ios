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

/// ViewModel for the Expense screen following MVVM architecture
@MainActor
final class ExpenseViewModel: ObservableObject {
    
    // MARK: - Published Properties

    @Published var dailyExpenses: [FinancialCategory] = []
    @Published var weeklyExpenses: [FinancialCategory] = []
    @Published var monthlyExpenses: [FinancialCategory] = []
    @Published var yearlyExpenses: [FinancialCategory] = []
    @Published var oneTimeExpenses: [FinancialCategory] = []
    @Published var subscriptions: [Subscription] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published private(set) var currencySymbol: String = CurrencyHelper.symbol(for: CurrencyHelper.defaultCurrencyCode())
    @Published private(set) var latestSummary: FinancialSummary?

    // MARK: - Summary Properties (FinancialSummaryBuilder)

    var totalMonthlyExpenses: Double {
        latestSummary?.recurringExpenseMonthly ?? 0
    }

    /// Section subtotal for subscriptions list (not added to summary card)
    var subscriptionsTotalMonthly: Double {
        SubscriptionManager.shared.getTotalMonthlyCost()
    }

    var subscriptionsTotalYearly: Double {
        SubscriptionManager.shared.getTotalYearlyCost()
    }

    var subscriptionsCount: Int {
        subscriptions.count
    }

    var dailyAverageExpenses: Double {
        latestSummary?.recurringExpenseDaily ?? 0
    }
    
    var yearlyProjectionExpenses: Double {
        totalMonthlyExpenses * 12
    }

    var activeSourcesCount: Int {
        let recurring = (dailyExpenses + weeklyExpenses + monthlyExpenses + yearlyExpenses).filter { $0.amount > 0 }.count
        let oneTime = oneTimeExpenses.filter { $0.amount > 0 }.count
        return recurring + oneTime + subscriptionsCount
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
    private let summaryBuilder: FinancialSummaryBuilder
    private let oneTimeSyncService: OneTimeTransactionSyncScheduling
    private let categorySyncService: FinancialCategorySyncScheduling
    private var cancellables = Set<AnyCancellable>()
    private var currencyCode: String = CurrencyHelper.defaultCurrencyCode()
    private var hasLoadedCategories = false

    private static let saveFailedMessage = String(
        localized: "expenses.error.save",
        defaultValue: "Couldn't save your change. Please try again.",
        table: "UI"
    )

    // MARK: - Initialization

    init(
        persistenceService: PersistenceService = .shared,
        summaryBuilder: FinancialSummaryBuilder? = nil,
        oneTimeSyncService: OneTimeTransactionSyncScheduling = SupabaseOneTimeTransactionSyncService.shared,
        categorySyncService: FinancialCategorySyncScheduling = SupabaseFinancialCategorySyncService.shared
    ) {
        self.persistenceService = persistenceService
        self.summaryBuilder = summaryBuilder ?? FinancialSummaryBuilder(context: persistenceService.viewContext)
        self.oneTimeSyncService = oneTimeSyncService
        self.categorySyncService = categorySyncService
        setupCurrencyObserver()
        setupLanguageObserver()
        setupSubscriptionObservers()
        setupOneTimeSyncObserver()
        setupCategorySyncObserver()
        loadCurrency()
        loadExpenseCategories()
        loadSubscriptions()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Public Methods
    
    func updateAmount(for category: FinancialCategory, amount: Double) {
        category.amount = amount
        FinancialCategoryWriteSupport.touchModified(category)
        guard persistenceService.save() else {
            errorMessage = Self.saveFailedMessage
            return
        }

        loadExpenseCategories(showLoadingIndicator: false)

        syncOneTimeChange(for: category)
        WidgetSnapshotService.refreshFromCurrentData()
    }

    func updateColor(for category: FinancialCategory, color: CategoryColor) {
        guard category.isCustom else { return }
        category.customColorHex = color.rawValue
        FinancialCategoryWriteSupport.touchModified(category)
        guard persistenceService.save() else {
            errorMessage = Self.saveFailedMessage
            return
        }

        loadExpenseCategories(showLoadingIndicator: false)
        syncCategoryChange(for: category)
    }
    
    func formatInputAmount(_ amount: Double) -> String {
        if amount <= 0 {
            return ""
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        formatter.locale = Locale(identifier: "en_US")
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        
        return formatter.string(from: NSNumber(value: amount)) ?? "0"
    }
    
    func parseAmount(from input: String) -> Double {
        let cleanedInput = input.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)

        if cleanedInput.isEmpty {
            return 0
        }

        guard let amount = Double(cleanedInput) else {
            return 0
        }

        let maxAmount: Double = 1_000_000_000
        let minAmount: Double = 0

        return min(max(amount, minAmount), maxAmount)
    }
    
    func formatCurrencyDisplay(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_US")
        formatter.currencyCode = currencyCode
        formatter.currencySymbol = CurrencyHelper.symbol(for: currencyCode)
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        
        return formatter.string(from: NSNumber(value: amount)) ?? "\(currencySymbol)0"
    }
    
    func displayName(for category: FinancialCategory) -> String {
        if let customName = category.customName, !customName.isEmpty {
            return customName
        }
        guard let uniqueID = category.uniqueID else { return "Unknown" }
        return DataSeedingService.displayName(for: uniqueID)
    }
    
    func sfSymbolName(for category: FinancialCategory) -> String {
        if category.isCustom, let icon = category.customIconName {
            return icon
        }
        guard let uniqueID = category.uniqueID else { return "questionmark.circle" }
        return DataSeedingService.sfSymbolName(for: uniqueID)
    }
    
    func refresh() {
        loadExpenseCategories(showLoadingIndicator: false)
        loadSubscriptions()
    }

    func loadSubscriptions() {
        subscriptions = SubscriptionManager.shared.getAllActiveSubscriptions()
        refreshSummary()
    }

    func deleteSubscription(_ subscription: Subscription) {
        guard let id = subscription.id else { return }
        let success = SubscriptionManager.shared.deleteSubscription(id: id)
        if success {
            loadSubscriptions()
            WidgetSnapshotService.refreshFromCurrentData()
        }
    }

    func formatSubscriptionAmount(_ subscription: Subscription) -> String {
        let amount = subscription.amount
        return CurrencyHelper.format(amount: amount, currencyCode: currencyCode)
    }

    func subscriptionBillingCycle(_ subscription: Subscription) -> String {
        guard let cycle = subscription.billingCycle else { return "/mo" }
        switch cycle.lowercased() {
        case "monthly": return "/mo"
        case "yearly": return "/yr"
        case "weekly": return "/wk"
        default: return "/mo"
        }
    }

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

    func deleteCategory(_ category: FinancialCategory) {
        guard category.isCustom else { return }

        if FinancialCategoryWriteSupport.isOneTimeDisplayCategory(category) {
            oneTimeSyncService.tombstoneLocalOneTimeRow(category)
            loadExpenseCategories(showLoadingIndicator: false)
            WidgetSnapshotService.refreshFromCurrentData()
            return
        }

        categorySyncService.tombstoneLocalCustomCategory(category)
        loadExpenseCategories(showLoadingIndicator: false)
        WidgetSnapshotService.refreshFromCurrentData()
    }

    // MARK: - Private Methods
    
    private func loadExpenseCategories(showLoadingIndicator: Bool = true) {
        if showLoadingIndicator || !hasLoadedCategories {
            isLoading = true
        }
        errorMessage = nil
        
        let context = persistenceService.viewContext
        let fetchRequest: NSFetchRequest<FinancialCategory> = FinancialCategory.fetchRequest()
        
        fetchRequest.predicate = NSPredicate(format: "type == %@", "expense")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \FinancialCategory.uniqueID, ascending: true)]
        
        do {
            let allExpenses = try context.fetch(fetchRequest)
            let recurringExpenses = allExpenses
                .filter { FinancialCategoryWriteSupport.isRecurringDisplayCategory($0) }
                .filter { !FinancialCategorySyncMetadataStore.shared.isTombstonedCustomCategory($0, in: context) }

            dailyExpenses = recurringExpenses.filter { $0.frequency == "daily" }
            weeklyExpenses = recurringExpenses.filter { $0.frequency == "weekly" }
            monthlyExpenses = recurringExpenses.filter { $0.frequency == "monthly" }
            yearlyExpenses = recurringExpenses.filter { $0.frequency == "yearly" }
            oneTimeExpenses = allExpenses
                .filter { FinancialCategoryWriteSupport.isOneTimeDisplayCategory($0) }
                .filter { !OneTimeTransactionSyncMetadataStore.shared.isTombstoned($0, in: context) }

            refreshSummary()
            hasLoadedCategories = true
            isLoading = false
        } catch {
            print("📊 ExpenseViewModel: ❌ Loading failed: \(error)")
            let baseMessage = "expenses.error.load".localized(defaultValue: "Failed to load expense categories.")
            errorMessage = "\(baseMessage) \(error.localizedDescription)"
            isLoading = false
        }
    }

    private func refreshSummary() {
        latestSummary = summaryBuilder.build(selectedPeriod: .month)
    }
}

// MARK: - Category Grouping Helper

extension ExpenseViewModel {

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
                color: Color(hex: "6B7280")
            )
        ]
    }

    var hasExpenseData: Bool {
        let allCategories = dailyExpenses + weeklyExpenses + monthlyExpenses + yearlyExpenses + oneTimeExpenses
        let hasCategories = allCategories.contains { $0.amount > 0 }
        return hasCategories || !subscriptions.isEmpty
    }

    func subtotalForFrequency(_ frequency: String) -> Double {
        switch frequency {
        case "daily":
            return dailyExpenses.reduce(0) { $0 + $1.amount }
        case "weekly":
            return weeklyExpenses.reduce(0) { $0 + $1.amount }
        case "monthly":
            return monthlyExpenses.reduce(0) { $0 + $1.amount }
        case "yearly":
            return yearlyExpenses.reduce(0) { $0 + $1.amount }
        default:
            return 0
        }
    }

    func oneTimeSubtotal() -> Double {
        oneTimeExpenses.reduce(0) { $0 + $1.amount }
    }

    func formattedOneTimeSubtotal() -> String {
        let total = oneTimeSubtotal()
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        formatter.groupingSeparator = ","
        let formatted = formatter.string(from: NSNumber(value: total)) ?? "0"
        return "\(currencySymbol)\(formatted)"
    }

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
        case "weekly":
            return "\(currencySymbol)\(formatted)/wk"
        case "monthly":
            return "\(currencySymbol)\(formatted)/mo"
        case "yearly":
            return "\(currencySymbol)\(formatted)/yr"
        default:
            return "\(currencySymbol)\(formatted)"
        }
    }

    func sectionTitle(_ frequency: String) -> String {
        switch frequency {
        case "daily":
            return String(localized: "expense.section.daily", defaultValue: "Daily Expenses")
        case "weekly":
            return String(localized: "expense.section.weekly", defaultValue: "Weekly Expenses")
        case "monthly":
            return String(localized: "expense.section.monthly", defaultValue: "Monthly Expenses")
        case "yearly":
            return String(localized: "expense.section.yearly", defaultValue: "Yearly Expenses")
        default:
            return String(localized: "expense.section.other", defaultValue: "Other Expenses")
        }
    }

    var oneTimeSectionTitle: String {
        String(localized: "expense.section.one_time", defaultValue: "Surprise Expenses")
    }

    func categoriesForFrequency(_ frequency: String) -> [FinancialCategory] {
        switch frequency {
        case "daily":
            return dailyExpenses
        case "weekly":
            return weeklyExpenses
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
    func setupOneTimeSyncObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(oneTimeTransactionsDidSync(_:)),
            name: .oneTimeTransactionsDidSync,
            object: nil
        )
    }

    @objc func oneTimeTransactionsDidSync(_ notification: Notification) {
        loadExpenseCategories(showLoadingIndicator: false)
    }

    func setupCategorySyncObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(financialCategoriesDidSync(_:)),
            name: .financialCategoriesDidSync,
            object: nil
        )
    }

    @objc func financialCategoriesDidSync(_ notification: Notification) {
        loadExpenseCategories(showLoadingIndicator: false)
    }

    func syncCategoryChange(for category: FinancialCategory) {
        if FinancialCategoryWriteSupport.isOneTimeDisplayCategory(category) {
            oneTimeSyncService.registerLocalOneTimeRow(category)
            return
        }
        if FinancialCategorySyncMapper.isCustomRecurringSyncEligible(category) {
            categorySyncService.registerLocalCustomCategory(category)
            return
        }
        if FinancialCategorySyncMapper.isSeededOverrideSyncEligible(category) {
            categorySyncService.registerLocalSeededOverride(category)
        }
    }

    func syncOneTimeChange(for category: FinancialCategory) {
        guard FinancialCategoryWriteSupport.isOneTimeDisplayCategory(category) else { return }
        oneTimeSyncService.registerLocalOneTimeRow(category)
    }

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
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
}
