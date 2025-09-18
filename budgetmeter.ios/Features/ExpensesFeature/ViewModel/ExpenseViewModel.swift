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
    
    // MARK: - Private Properties
    
    private let persistenceService: PersistenceService
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(persistenceService: PersistenceService = .shared) {
        self.persistenceService = persistenceService
        loadExpenseCategories()
    }
    
    // MARK: - Public Methods
    
    /// Updates the amount for a specific expense category
    func updateAmount(for category: FinancialCategory, amount: Double) {
        print("🔴 ExpenseViewModel: updateAmount called")
        print("🔴 ExpenseViewModel: Category: \(category.uniqueID ?? "unknown")")
        print("🔴 ExpenseViewModel: Old amount: \(category.amount)")
        print("🔴 ExpenseViewModel: New amount: \(amount)")
        
        category.amount = amount
        print("🔴 ExpenseViewModel: Category.amount updated to: \(category.amount)")
        print("🔴 ExpenseViewModel: Calling persistenceService.save()...")
        
        persistenceService.save()
        print("🔴 ExpenseViewModel: persistenceService.save() completed")
    }
    
    /// Formats amount for display in input field (no live formatting during input)
    func formatInputAmount(_ amount: Double) -> String {
        if amount <= 0 {
            return ""
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
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
        formatter.currencyCode = "USD"
        formatter.currencySymbol = String(localized: "currency.symbol")
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
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
            errorMessage = "Failed to load expense categories: \(error.localizedDescription)"
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
                title: String(localized: "frequency.daily"),
                categories: dailyExpenses,
                color: .red
            ),
            (
                title: String(localized: "frequency.monthly"),
                categories: monthlyExpenses,
                color: .orange
            ),
            (
                title: String(localized: "frequency.yearly"),
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
