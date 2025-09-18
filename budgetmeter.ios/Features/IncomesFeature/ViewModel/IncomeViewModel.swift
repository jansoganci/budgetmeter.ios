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
    @Published var monthlyIncomes: [FinancialCategory] = []
    @Published var yearlyIncomes: [FinancialCategory] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    
    private let persistenceService: PersistenceService
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(persistenceService: PersistenceService = .shared) {
        self.persistenceService = persistenceService
        loadIncomeCategories()
    }
    
    // MARK: - Public Methods
    
    /// Updates the amount for a specific income category
    func updateAmount(for category: FinancialCategory, amount: Double) {
        print("🟢 IncomeViewModel: updateAmount called")
        print("🟢 IncomeViewModel: Category: \(category.uniqueID ?? "unknown")")
        print("🟢 IncomeViewModel: Old amount: \(category.amount)")
        print("🟢 IncomeViewModel: New amount: \(amount)")
        
        category.amount = amount
        print("🟢 IncomeViewModel: Category.amount updated to: \(category.amount)")
        print("🟢 IncomeViewModel: Calling persistenceService.save()...")
        
        persistenceService.save()
        print("🟢 IncomeViewModel: persistenceService.save() completed")
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
        loadIncomeCategories()
    }
    
    // MARK: - Private Methods
    
    private func loadIncomeCategories() {
        print("🟢 IncomeViewModel: loadIncomeCategories() called")
        isLoading = true
        errorMessage = nil
        
        let context = persistenceService.viewContext
        let fetchRequest: NSFetchRequest<FinancialCategory> = FinancialCategory.fetchRequest()
        
        // Fetch only income categories
        fetchRequest.predicate = NSPredicate(format: "type == %@", "income")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \FinancialCategory.uniqueID, ascending: true)]
        
        print("🟢 IncomeViewModel: Executing fetch request for income categories...")
        do {
            let allIncomes = try context.fetch(fetchRequest)
            print("🟢 IncomeViewModel: Fetched \(allIncomes.count) income categories")
            
            // Separate by frequency
            dailyIncomes = allIncomes.filter { $0.frequency == "daily" }
            monthlyIncomes = allIncomes.filter { $0.frequency == "monthly" }
            yearlyIncomes = allIncomes.filter { $0.frequency == "yearly" }
            
            print("🟢 IncomeViewModel: Daily: \(dailyIncomes.count), Monthly: \(monthlyIncomes.count), Yearly: \(yearlyIncomes.count)")
            
            // Log current amounts
            for category in allIncomes {
                print("🟢 IncomeViewModel: Category \(category.uniqueID ?? "unknown") has amount: \(category.amount)")
            }
            
            isLoading = false
            print("🟢 IncomeViewModel: ✅ Loading completed successfully")
        } catch {
            print("🟢 IncomeViewModel: ❌ Loading failed: \(error)")
            errorMessage = "Failed to load income categories: \(error.localizedDescription)"
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
                title: String(localized: "frequency.daily"),
                categories: dailyIncomes,
                color: .green
            ),
            (
                title: String(localized: "frequency.monthly"),
                categories: monthlyIncomes,
                color: .blue
            ),
            (
                title: String(localized: "frequency.yearly"),
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
