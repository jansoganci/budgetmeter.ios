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
    @Published var monthlyExpenses: [FinancialCategory] = []
    @Published var yearlyExpenses: [FinancialCategory] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published private(set) var currencySymbol: String = CurrencyHelper.symbol(for: CurrencyHelper.defaultCurrencyCode())
    
    // MARK: - Summary Computed Properties
    
    var totalMonthlyExpenses: Double {
        let dailyTotal = dailyExpenses.reduce(0) { $0 + $1.amount } * 30 // Daily × 30
        let monthlyTotal = monthlyExpenses.reduce(0) { $0 + $1.amount }
        let yearlyMonthly = yearlyExpenses.reduce(0) { $0 + $1.amount } / 12 // Yearly ÷ 12
        return dailyTotal + monthlyTotal + yearlyMonthly
    }
    
    var dailyAverageExpenses: Double {
        return totalMonthlyExpenses / 30
    }
    
    var yearlyProjectionExpenses: Double {
        return totalMonthlyExpenses * 12
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
        loadExpenseCategories()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Public Methods
    
    /// Updates the amount for a specific expense category
    func updateAmount(for category: FinancialCategory, amount: Double) {
        category.amount = amount
        persistenceService.save()
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
    
    /// Parses input string to Double amount
    func parseAmount(from input: String) -> Double {
        // Remove any non-numeric characters except decimal point
        let cleanedInput = input.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
        
        // Handle empty input
        if cleanedInput.isEmpty {
            return 0
        }
        
        return Double(cleanedInput) ?? 0
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
        // Force UI refresh to update localized strings
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
}
