//
//  OnboardingViewModel.swift
//  BudgetMeter
//
//  Created by BudgetMeter Team
//

import Foundation
import CoreData
import SwiftUI

/// ViewModel for onboarding flow - manages state and saves initial data
@MainActor
final class OnboardingViewModel: ObservableObject {

    // MARK: - Published Properties

    /// Current onboarding screen (0 = Welcome, 1 = Quick Setup)
    @Published var currentScreen: Int = 0

    /// Income amount entered by user (optional)
    @Published var incomeAmount: String = ""

    /// Selected frequency for income (default: monthly)
    @Published var selectedFrequency: Frequency = .monthly

    /// Whether user entered income (for tracking)
    @Published var didEnterIncome: Bool = false

    // MARK: - Private Properties

    private let persistenceService: PersistenceService
    private let onboardingManager: OnboardingManager

    // MARK: - Frequency Enum

    enum Frequency: String, CaseIterable {
        case daily = "daily"
        case monthly = "monthly"
        case yearly = "yearly"

        var displayName: String {
            switch self {
            case .daily:
                return "onboarding.frequency.daily".localized(defaultValue: "Daily")
            case .monthly:
                return "onboarding.frequency.monthly".localized(defaultValue: "Monthly")
            case .yearly:
                return "onboarding.frequency.yearly".localized(defaultValue: "Yearly")
            }
        }

        var icon: String {
            switch self {
            case .daily:
                return "sun.max.fill"
            case .monthly:
                return "calendar"
            case .yearly:
                return "calendar.badge.clock"
            }
        }
    }

    // MARK: - Initialization

    init(
        persistenceService: PersistenceService = .shared,
        onboardingManager: OnboardingManager = .shared
    ) {
        self.persistenceService = persistenceService
        self.onboardingManager = onboardingManager
    }

    // MARK: - Navigation

    /// Move to next screen
    func nextScreen() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentScreen += 1
        }
    }

    /// Skip current screen
    func skipScreen() {
        if currentScreen == 0 {
            // Skipped welcome - go to quick setup
            nextScreen()
        } else {
            // Skipped quick setup - complete onboarding without data
            completeOnboarding(skipped: true)
        }
    }

    /// Skip entire onboarding flow
    func skipAll() {
        completeOnboarding(skipped: true)
    }

    // MARK: - Data Handling

    /// Saves income to Core Data if user entered it
    func saveIncomeIfProvided() {
        guard !incomeAmount.isEmpty,
              let amount = Double(incomeAmount.replacingOccurrences(of: ",", with: "")),
              amount > 0 else {
            // No income entered or invalid - that's OK
            print("ℹ️ No income entered during onboarding")
            completeOnboarding(skipped: false)
            return
        }

        didEnterIncome = true

        let context = persistenceService.viewContext
        let fetchRequest: NSFetchRequest<FinancialCategory> = FinancialCategory.fetchRequest()

        // Find existing "Salary" income category or create new one
        fetchRequest.predicate = NSPredicate(
            format: "type == %@ AND frequency == %@",
            "income",
            selectedFrequency.rawValue
        )

        do {
            let existingCategories = try context.fetch(fetchRequest)

            // Try to find "Salary" category specifically
            if let salaryCategory = existingCategories.first(where: {
                $0.customName == "Salary" || $0.customName == "onboarding.category.salary".localized(defaultValue: "Salary")
            }) {
                // Update existing salary category
                salaryCategory.amount = amount
                print("✅ Updated existing salary category: \(amount)")
            } else if let firstIncomeCategory = existingCategories.first {
                // Update first income category of this frequency
                firstIncomeCategory.amount = amount
                print("✅ Updated first income category: \(amount)")
            } else {
                // Create new income category
                let newIncome = FinancialCategory(context: context)
                newIncome.id = UUID()
                newIncome.type = "income"
                newIncome.frequency = selectedFrequency.rawValue
                newIncome.amount = amount
                newIncome.customName = "onboarding.category.salary".localized(defaultValue: "Salary")
                newIncome.isCustom = false
                newIncome.createdAt = Date()
                print("✅ Created new income category: \(amount)")
            }

            persistenceService.save()
            print("💾 Income saved successfully")

            completeOnboarding(skipped: false)

        } catch {
            print("❌ Failed to save income: \(error)")
            // Still complete onboarding even if save failed
            completeOnboarding(skipped: false)
        }
    }

    // MARK: - Completion

    /// Marks onboarding as complete
    private func completeOnboarding(skipped: Bool) {
        onboardingManager.markOnboardingComplete(skipped: skipped)
    }

    // MARK: - Helpers

    /// Returns formatted income amount for display
    var formattedIncomeAmount: String {
        guard !incomeAmount.isEmpty,
              let amount = Double(incomeAmount.replacingOccurrences(of: ",", with: "")) else {
            return ""
        }

        return CurrencyHelper.formatAmount(amount)
    }

    /// Returns calculated daily amount (if monthly selected)
    var calculatedDailyAmount: String? {
        guard selectedFrequency == .monthly,
              !incomeAmount.isEmpty,
              let amount = Double(incomeAmount.replacingOccurrences(of: ",", with: "")) else {
            return nil
        }

        let dailyAmount = amount / 30.4375 // Use same constant as CalculationEngine
        return CurrencyHelper.formatAmount(dailyAmount)
    }

    /// Returns calculated yearly amount (if monthly selected)
    var calculatedYearlyAmount: String? {
        guard selectedFrequency == .monthly,
              !incomeAmount.isEmpty,
              let amount = Double(incomeAmount.replacingOccurrences(of: ",", with: "")) else {
            return nil
        }

        let yearlyAmount = amount * 12
        return CurrencyHelper.formatAmount(yearlyAmount)
    }

    /// Whether "Save & Go" button should be enabled
    var canProceed: Bool {
        // Can always proceed (income is optional)
        // But if they entered something, it should be valid
        if incomeAmount.isEmpty {
            return true
        }

        guard let amount = Double(incomeAmount.replacingOccurrences(of: ",", with: "")) else {
            return false
        }

        return amount > 0 && amount < 1_000_000_000 // Reasonable validation
    }
}
