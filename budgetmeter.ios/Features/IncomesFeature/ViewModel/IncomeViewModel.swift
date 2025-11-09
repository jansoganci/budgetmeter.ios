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
import WidgetKit

/// ViewModel for the Income screen following MVVM architecture
@MainActor
final class IncomeViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var dailyIncomes: [FinancialCategory] = []
    @Published var monthlyIncomes: [FinancialCategory] = []
    @Published var yearlyIncomes: [FinancialCategory] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published private(set) var currencySymbol: String = CurrencyHelper.symbol(for: CurrencyHelper.defaultCurrencyCode())
    
    // MARK: - Summary Computed Properties

    var totalMonthlyIncome: Double {
        let dailyTotal = dailyIncomes.reduce(0) { $0 + $1.amount }
        let monthlyTotal = monthlyIncomes.reduce(0) { $0 + $1.amount }
        let yearlyTotal = yearlyIncomes.reduce(0) { $0 + $1.amount }

        // Use CalculationEngine for consistency
        return CalculationEngine.totalMonthlyIncome(
            dailyIncomeTotal: dailyTotal,
            monthlyIncomeTotal: monthlyTotal,
            yearlyIncomeTotal: yearlyTotal
        )
    }

    var dailyAverageIncome: Double {
        return totalMonthlyIncome / CalculationEngine.daysPerMonth
    }
    
    var yearlyProjectionIncome: Double {
        return totalMonthlyIncome * 12
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
    private var cancellables = Set<AnyCancellable>()
    private var currencyCode: String = CurrencyHelper.defaultCurrencyCode()

    // MARK: - Initialization

    init(persistenceService: PersistenceService = .shared) {
        self.persistenceService = persistenceService
        setupCurrencyObserver()
        setupLanguageObserver()
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
        persistenceService.save()

        // Reload widgets to show updated income data
        WidgetCenter.shared.reloadAllTimelines()
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
        loadIncomeCategories()
    }
    
    // MARK: - Private Methods
    
    private func loadIncomeCategories() {
        isLoading = true
        errorMessage = nil
        
        let context = persistenceService.viewContext
        let fetchRequest: NSFetchRequest<FinancialCategory> = FinancialCategory.fetchRequest()
        
        // Fetch only income categories
        fetchRequest.predicate = NSPredicate(format: "type == %@", "income")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \FinancialCategory.uniqueID, ascending: true)]
        
        do {
            let allIncomes = try context.fetch(fetchRequest)
            
            // Separate by frequency
            dailyIncomes = allIncomes.filter { $0.frequency == "daily" }
            monthlyIncomes = allIncomes.filter { $0.frequency == "monthly" }
            yearlyIncomes = allIncomes.filter { $0.frequency == "yearly" }
            
            isLoading = false
        } catch {
            print("📊 IncomeViewModel: ❌ Loading failed: \(error)")
            let baseMessage = "income.error.load".localized(defaultValue: "Failed to load income categories.")
            errorMessage = "\(baseMessage) \(error.localizedDescription)"
            isLoading = false
        }
    }
}

// MARK: - Category Grouping Helper

extension IncomeViewModel {
    
    /// Groups categories by frequency for easier UI rendering
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
    
    /// Checks if any income categories have been entered
    var hasIncomeData: Bool {
        let allCategories = dailyIncomes + monthlyIncomes + yearlyIncomes
        return allCategories.contains { category in
            return category.amount > 0
        }
    }
}

// MARK: - Currency Handling

private extension IncomeViewModel {
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
        // Trigger UI refresh to re-evaluate localized strings in summary cards
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
    

}
