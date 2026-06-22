//
//  IncomeViewModel.swift
//  BudgetMeter
//
//  Created by BudgetMeter Team on 17.09.2025.
//

import Foundation
import SwiftUI
import CoreData
import Combine

/// ViewModel for the Income screen following MVVM architecture
@MainActor
final class IncomeViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var dailyIncomes: [FinancialCategory] = []
    @Published var weeklyIncomes: [FinancialCategory] = []
    @Published var monthlyIncomes: [FinancialCategory] = []
    @Published var yearlyIncomes: [FinancialCategory] = []
    @Published var oneTimeIncomes: [FinancialCategory] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published private(set) var currencySymbol: String = CurrencyHelper.symbol(for: CurrencyHelper.defaultCurrencyCode())
    @Published private(set) var latestSummary: FinancialSummary?

    // MARK: - Summary Properties (FinancialSummaryBuilder)

    var totalMonthlyIncome: Double {
        latestSummary?.recurringIncomeMonthly ?? 0
    }

    var dailyAverageIncome: Double {
        latestSummary?.recurringIncomeDaily ?? 0
    }
    
    var yearlyProjectionIncome: Double {
        totalMonthlyIncome * 12
    }

    /// Number of income sources with amounts > 0
    var activeSourcesCount: Int {
        let recurring = (dailyIncomes + weeklyIncomes + monthlyIncomes + yearlyIncomes).filter { $0.amount > 0 }.count
        let oneTime = oneTimeIncomes.filter { $0.amount > 0 }.count
        return recurring + oneTime
    }
    
    // MARK: - Localized Summary Titles
    
    var monthlyTitle: String {
        return "income.summary.monthly".localized(defaultValue: "Monthly")
    }
    
    var dailyAvgTitle: String {
        return "income.summary.daily_avg".localized(defaultValue: "Daily Avg")
    }
    
    var yearlyTitle: String {
        return "income.summary.yearly".localized(defaultValue: "Yearly")
    }
    
    var summaryTitle: String {
        return "income.summary.title".localized(defaultValue: "Income Overview")
    }
    
    // MARK: - Private Properties
    
    private let persistenceService: PersistenceService
    private let summaryBuilder: FinancialSummaryBuilder
    private let oneTimeSyncService: OneTimeTransactionSyncScheduling
    private let categorySyncService: FinancialCategorySyncScheduling
    private let paceSyncService: RecurringCategoryPaceSyncScheduling
    private var cancellables = Set<AnyCancellable>()
    private var currencyCode: String = CurrencyHelper.defaultCurrencyCode()
    private var hasLoadedCategories = false

    private static let saveFailedMessage = String(
        localized: "income.error.save",
        defaultValue: "Couldn't save your change. Please try again.",
        table: "UI"
    )

    // MARK: - Initialization

    init(
        persistenceService: PersistenceService = .shared,
        summaryBuilder: FinancialSummaryBuilder? = nil,
        oneTimeSyncService: OneTimeTransactionSyncScheduling = SupabaseOneTimeTransactionSyncService.shared,
        categorySyncService: FinancialCategorySyncScheduling = SupabaseFinancialCategorySyncService.shared,
        paceSyncService: RecurringCategoryPaceSyncScheduling = SupabaseRecurringCategoryPaceSyncService.shared
    ) {
        self.persistenceService = persistenceService
        self.summaryBuilder = summaryBuilder ?? FinancialSummaryBuilder(context: persistenceService.viewContext)
        self.oneTimeSyncService = oneTimeSyncService
        self.categorySyncService = categorySyncService
        self.paceSyncService = paceSyncService
        setupCurrencyObserver()
        setupLanguageObserver()
        setupOneTimeSyncObserver()
        setupCategorySyncObserver()
        setupPaceSyncObserver()
        loadCurrency()
        loadIncomeCategories()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Public Methods
    
    /// Updates the amount for a specific income category
    func updateAmount(for category: FinancialCategory, amount: Double) {
        category.amount = amount
        RecordCurrencySupport.stampCurrencyCodeIfNeeded(on: category)
        FinancialCategoryWriteSupport.touchModified(category)
        guard persistenceService.save() else {
            errorMessage = Self.saveFailedMessage
            return
        }

        loadIncomeCategories(showLoadingIndicator: false)

        syncRecurringPaceChange(for: category)
        syncOneTimeChange(for: category)
        WidgetSnapshotService.refreshFromCurrentData()
    }

    /// Updates the color for a custom category
    func updateColor(for category: FinancialCategory, color: CategoryColor) {
        guard category.isCustom else { return }
        category.customColorHex = color.rawValue
        FinancialCategoryWriteSupport.touchModified(category)
        guard persistenceService.save() else {
            errorMessage = Self.saveFailedMessage
            return
        }

        loadIncomeCategories(showLoadingIndicator: false)
        syncCategoryChange(for: category)
    }
    
    /// Formats amount for display in input field (no live formatting during input)
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
    
    /// Parses input string to Double amount with validation
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
    
    /// Formats amount for currency display (shown when not editing)
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
    
    /// Gets the localized display name for a category
    func displayName(for category: FinancialCategory) -> String {
        if let customName = category.customName, !customName.isEmpty {
            return customName
        }
        guard let uniqueID = category.uniqueID else { return "Unknown" }
        return DataSeedingService.displayName(for: uniqueID)
    }
    
    /// Gets the SF Symbol name for a category
    func sfSymbolName(for category: FinancialCategory) -> String {
        if category.isCustom, let icon = category.customIconName {
            return icon
        }
        guard let uniqueID = category.uniqueID else { return "questionmark.circle" }
        return DataSeedingService.sfSymbolName(for: uniqueID)
    }
    
    /// Refreshes data from Core Data
    func refresh() {
        loadIncomeCategories(showLoadingIndicator: false)
    }

    /// Deletes a custom income category
    func deleteCategory(_ category: FinancialCategory) {
        guard category.isCustom else { return }

        if FinancialCategoryWriteSupport.isOneTimeDisplayCategory(category) {
            oneTimeSyncService.tombstoneLocalOneTimeRow(category)
            loadIncomeCategories(showLoadingIndicator: false)
            WidgetSnapshotService.refreshFromCurrentData()
            return
        }

        categorySyncService.tombstoneLocalCustomCategory(category)
        paceSyncService.tombstoneLocalRecurringPaceRow(category)
        loadIncomeCategories(showLoadingIndicator: false)
        WidgetSnapshotService.refreshFromCurrentData()
    }

    // MARK: - Private Methods
    
    private func loadIncomeCategories(showLoadingIndicator: Bool = true) {
        if showLoadingIndicator || !hasLoadedCategories {
            isLoading = true
        }
        errorMessage = nil
        
        let context = persistenceService.viewContext
        let fetchRequest: NSFetchRequest<FinancialCategory> = FinancialCategory.fetchRequest()
        
        fetchRequest.predicate = NSPredicate(format: "type == %@", "income")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \FinancialCategory.uniqueID, ascending: true)]
        
        do {
            let allIncomes = try context.fetch(fetchRequest)
            let recurringIncomes = allIncomes
                .filter { FinancialCategoryWriteSupport.isRecurringDisplayCategory($0) }
                .filter { !FinancialCategorySyncMetadataStore.shared.isTombstonedCustomCategory($0, in: context) }
                .filter { !RecurringCategoryPaceSyncMetadataStore.shared.isTombstoned($0, in: context) }

            dailyIncomes = recurringIncomes.filter { $0.frequency == "daily" }
            weeklyIncomes = recurringIncomes.filter { $0.frequency == "weekly" }
            monthlyIncomes = recurringIncomes.filter { $0.frequency == "monthly" }
            yearlyIncomes = recurringIncomes.filter { $0.frequency == "yearly" }
            oneTimeIncomes = allIncomes
                .filter { FinancialCategoryWriteSupport.isOneTimeDisplayCategory($0) }
                .filter { !OneTimeTransactionSyncMetadataStore.shared.isTombstoned($0, in: context) }

            refreshSummary()
            hasLoadedCategories = true
            isLoading = false
        } catch {
            print("📊 IncomeViewModel: ❌ Loading failed: \(error)")
            let baseMessage = "income.error.load".localized(defaultValue: "Failed to load income categories.")
            errorMessage = "\(baseMessage) \(error.localizedDescription)"
            isLoading = false
        }
    }

    private func refreshSummary() {
        latestSummary = summaryBuilder.build(selectedPeriod: .month)
    }
}

// MARK: - Category Grouping Helper

extension IncomeViewModel {

    var categoryGroups: [(title: String, categories: [FinancialCategory], color: Color)] {
        [
            (
                title: "frequency.daily".localized(defaultValue: "Daily"),
                categories: dailyIncomes,
                color: .green
            ),
            (
                title: "frequency.monthly".localized(defaultValue: "Monthly"),
                categories: monthlyIncomes,
                color: .blue
            ),
            (
                title: "frequency.yearly".localized(defaultValue: "Yearly"),
                categories: yearlyIncomes,
                color: .purple
            )
        ]
    }

    var hasIncomeData: Bool {
        let allCategories = dailyIncomes + weeklyIncomes + monthlyIncomes + yearlyIncomes + oneTimeIncomes
        return allCategories.contains { $0.amount > 0 }
    }

    func subtotalForFrequency(_ frequency: String) -> Double {
        switch frequency {
        case "daily":
            return dailyIncomes.reduce(0) { $0 + $1.amount }
        case "weekly":
            return weeklyIncomes.reduce(0) { $0 + $1.amount }
        case "monthly":
            return monthlyIncomes.reduce(0) { $0 + $1.amount }
        case "yearly":
            return yearlyIncomes.reduce(0) { $0 + $1.amount }
        default:
            return 0
        }
    }

    func oneTimeSubtotal() -> Double {
        oneTimeIncomes.reduce(0) { $0 + $1.amount }
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
            return String(localized: "income.section.daily", defaultValue: "Daily Income")
        case "weekly":
            return String(localized: "income.section.weekly", defaultValue: "Weekly Income")
        case "monthly":
            return String(localized: "income.section.monthly", defaultValue: "Monthly Income")
        case "yearly":
            return String(localized: "income.section.yearly", defaultValue: "Yearly Income")
        default:
            return String(localized: "income.section.other", defaultValue: "Other Income")
        }
    }

    var oneTimeSectionTitle: String {
        String(localized: "income.section.one_time", defaultValue: "One-Time Income")
    }

    func categoriesForFrequency(_ frequency: String) -> [FinancialCategory] {
        switch frequency {
        case "daily":
            return dailyIncomes
        case "weekly":
            return weeklyIncomes
        case "monthly":
            return monthlyIncomes
        case "yearly":
            return yearlyIncomes
        default:
            return []
        }
    }
}

// MARK: - Currency Handling

private extension IncomeViewModel {
    func setupOneTimeSyncObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(oneTimeTransactionsDidSync(_:)),
            name: .oneTimeTransactionsDidSync,
            object: nil
        )
    }

    @objc func oneTimeTransactionsDidSync(_ notification: Notification) {
        loadIncomeCategories(showLoadingIndicator: false)
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
        loadIncomeCategories(showLoadingIndicator: false)
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

    func syncRecurringPaceChange(for category: FinancialCategory) {
        guard FinancialCategoryWriteSupport.isRecurringDisplayCategory(category) else { return }
        guard category.sourceType != "recurringAutomation" else { return }
        paceSyncService.registerLocalRecurringPaceRow(category)
    }

    func setupPaceSyncObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(recurringCategoryPaceDidSync(_:)),
            name: .recurringCategoryPaceDidSync,
            object: nil
        )
    }

    @objc func recurringCategoryPaceDidSync(_ notification: Notification) {
        loadIncomeCategories(showLoadingIndicator: false)
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
