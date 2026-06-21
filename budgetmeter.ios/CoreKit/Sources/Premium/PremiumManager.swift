//
//  PremiumManager.swift
//  BudgetMeter
//
//  Created by BudgetMeter Team on 17.09.2025.
//

import Foundation
import SwiftUI
import StoreKit
import CoreData

/// Manages premium features, purchases, and feature gating
@MainActor
final class PremiumManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = PremiumManager()
    
    // MARK: - Published Properties
    
    @Published var isPremium: Bool = false
    @Published var purchaseState: PurchaseState = .unknown
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    
    private let persistenceService: PersistenceService
    private var product: Product?
    private var transactionListener: Task<Void, Error>?
    
    // MARK: - Premium Product Configuration
    
    private let premiumProductID = "com.budgetmeter.premium.lifetime"
    
    // MARK: - Initialization
    
    private init(persistenceService: PersistenceService = .shared) {
        self.persistenceService = persistenceService
        loadPremiumStatus()
        #if DEBUG
        applyDebugPremiumOverrideIfNeeded()
        #endif
        setupTransactionListener()
        Task {
            await loadProducts()
        }
    }
    
    deinit {
        transactionListener?.cancel()
    }
    
    // MARK: - Feature Access

    static func hasAccess(to capability: BudgetMeterCapability, isPremium: Bool) -> Bool {
        switch capability.accessLevel {
        case .free:
            return true
        case .premium:
            return isPremium
        case .postponed:
            return false
        }
    }

    func hasAccess(to capability: BudgetMeterCapability) -> Bool {
        Self.hasAccess(to: capability, isPremium: isPremium)
    }

    func hasAccess(to feature: PremiumFeature) -> Bool {
        hasAccess(to: feature.capability)
    }

    /// Check if user has access to Insights Dashboard
    var hasInsights: Bool {
        hasAccess(to: BudgetMeterCapability.spendingInsights)
    }

    /// Check if user has access to Advanced Notifications
    var hasAdvancedNotifications: Bool {
        hasAccess(to: BudgetMeterCapability.advancedNotifications)
    }

    var premiumDisplayPrice: String? {
        product?.displayPrice
    }

    // MARK: - Public Methods

    /// Checks current premium status from Core Data
    func checkPremiumStatus() {
        loadPremiumStatus()
    }
    
    /// Initiates premium purchase flow
    func purchasePremium() async {
        guard let product = product else {
            await MainActor.run {
                purchaseState = .failed
                errorMessage = String(localized: "premium.error.product_unavailable", defaultValue: "Premium is not available right now. Please try again later.", table: "UI")
            }
            return
        }
        
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await updatePremiumStatus(transaction: transaction)
                await transaction.finish()
                
            case .userCancelled:
                await MainActor.run {
                    purchaseState = .notPurchased
                    errorMessage = String(localized: "premium.error.purchase_cancelled", defaultValue: "Purchase cancelled.", table: "UI")
                }
                
            case .pending:
                await MainActor.run {
                    purchaseState = .pending
                    errorMessage = String(localized: "premium.error.purchase_pending", defaultValue: "Purchase pending approval.", table: "UI")
                }
                
            @unknown default:
                await MainActor.run {
                    purchaseState = .failed
                    errorMessage = String(localized: "premium.error.purchase_unknown", defaultValue: "Purchase could not be completed.", table: "UI")
                }
            }
        } catch {
            await MainActor.run {
                purchaseState = .failed
                let format = String(localized: "premium.error.purchase_failed", defaultValue: "Purchase failed: %@", table: "UI")
                errorMessage = String(format: format, error.localizedDescription)
            }
        }
        
        await MainActor.run {
            isLoading = false
        }
    }
    
    /// Restores previous purchases
    func restorePurchases() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            try await AppStore.sync()
            let didRestore = await checkForValidTransactions()
            await MainActor.run {
                if !didRestore {
                    purchaseState = .notPurchased
                    errorMessage = String(localized: "premium.restore.none_found", defaultValue: "No previous BudgetMeter Premium purchase was found.", table: "UI")
                }
            }
        } catch {
            await MainActor.run {
                purchaseState = .failed
                let format = String(localized: "premium.error.restore_failed", defaultValue: "Restore failed: %@", table: "UI")
                errorMessage = String(format: format, error.localizedDescription)
            }
        }
        
        await MainActor.run {
            isLoading = false
        }
    }
    
    // MARK: - Private Methods
    
    private func loadPremiumStatus() {
        let context = persistenceService.viewContext
        let fetchRequest: NSFetchRequest<AppSettings> = AppSettings.fetchRequest()
        
        do {
            let settings = try context.fetch(fetchRequest)
            if let appSettings = settings.first {
                isPremium = appSettings.isPremiumUser
            }
        } catch {
            print("Failed to load premium status: \(error)")
        }
    }
    
    private func setupTransactionListener() {
        transactionListener = Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    await self.updatePremiumStatus(transaction: transaction)
                    await transaction.finish()
                } catch {
                    print("Transaction verification failed: \(error)")
                }
            }
        }
    }
    
    private func loadProducts() async {
        do {
            let products = try await Product.products(for: [premiumProductID])
            product = products.first
            if product == nil {
                await MainActor.run {
                    purchaseState = .notPurchased
                }
            }
        } catch {
            print("Failed to load products: \(error)")
        }
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw PremiumError.unverifiedTransaction
        case .verified(let safe):
            return safe
        }
    }
    
    private func updatePremiumStatus(transaction: StoreKit.Transaction) async {
        guard transaction.productID == premiumProductID else { return }
        
        let context = persistenceService.viewContext
        let fetchRequest: NSFetchRequest<AppSettings> = AppSettings.fetchRequest()
        
        do {
            let settings = try context.fetch(fetchRequest)
            let appSettings: AppSettings
            
            if let existing = settings.first {
                appSettings = existing
            } else {
                appSettings = AppSettings(context: context)
            }
            
            appSettings.isPremiumUser = true
            appSettings.premiumPurchaseDate = transaction.purchaseDate
            
            persistenceService.save()
            
            await MainActor.run {
                isPremium = true
                purchaseState = .purchased
                WidgetSnapshotService.refreshFromCurrentData(
                    context: persistenceService.viewContext,
                    isPremium: true
                )
            }
        } catch {
            print("Failed to update premium status: \(error)")
        }
    }
    
    private func checkForValidTransactions() async -> Bool {
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                if transaction.productID == premiumProductID {
                    await updatePremiumStatus(transaction: transaction)
                    return true
                }
            } catch {
                print("Transaction verification failed: \(error)")
            }
        }

        return false
    }
    
    // MARK: - Debug Methods
    
    #if DEBUG
    static let debugPremiumOverrideKey = "debug_premium_override"

    private func applyDebugPremiumOverrideIfNeeded() {
        let override = UserDefaults.standard.bool(forKey: Self.debugPremiumOverrideKey)
        if override != isPremium {
            setDebugPremiumStatus(override)
        }
    }

    /// Sets premium status for debugging purposes (DEBUG builds only)
    func setDebugPremiumStatus(_ isPremium: Bool) {
        let context = persistenceService.viewContext
        let fetchRequest: NSFetchRequest<AppSettings> = AppSettings.fetchRequest()
        
        do {
            let settings = try context.fetch(fetchRequest)
            let appSettings: AppSettings
            
            if let existing = settings.first {
                appSettings = existing
            } else {
                appSettings = AppSettings(context: context)
            }
            
            appSettings.isPremiumUser = isPremium
            appSettings.premiumPurchaseDate = isPremium ? Date() : nil
            
            persistenceService.save()
            
            self.isPremium = isPremium
            print("DEBUG: Premium status set to \(isPremium)")
        } catch {
            print("Failed to set debug premium status: \(error)")
        }
    }
    #endif
}

// MARK: - Supporting Types

enum PremiumError: Error {
    case unverifiedTransaction
    case productNotAvailable
    case purchaseFailed
    case featureLocked(PremiumFeature)
    
    var localizedDescription: String {
        switch self {
        case .unverifiedTransaction:
            return String(localized: "premium.error.unverified_transaction", defaultValue: "Transaction could not be verified", table: "UI")
        case .productNotAvailable:
            return String(localized: "premium.error.product_not_available", defaultValue: "Premium product is not available", table: "UI")
        case .purchaseFailed:
            return String(localized: "premium.error.purchase_failed_short", defaultValue: "Purchase failed", table: "UI")
        case .featureLocked(let feature):
            let format = String(localized: "premium.error.feature_locked", defaultValue: "%@ requires BudgetMeter Premium", table: "UI")
            return String(format: format, feature.displayName)
        }
    }
}

enum PurchaseState {
    case unknown
    case purchased
    case notPurchased
    case pending
    case failed
}

// MARK: - Feature Gate Matrix

enum FeatureAccessLevel: Equatable {
    case free
    case premium
    case postponed
}

enum BudgetMeterCapability: String, CaseIterable {
    case homeDashboard
    case sharedFinancialSummary
    case incomeEntry
    case expenseEntry
    case oneTimeEntry
    case basicRecurringEntry
    case oneBasicSavingsGoal
    case defaultTheme
    case customCategories
    case subscriptionTracking
    case billReminders
    case multipleSavingsGoals
    case recurringAutomation
    case dataExport
    case widgets
    case spendingInsights
    case biometricLock
    case premiumThemes
    case advancedNotifications
    case advancedHistoryReporting
    case forecasting
    case backupSync
    case adsFree

    var accessLevel: FeatureAccessLevel {
        switch self {
        case .homeDashboard,
             .sharedFinancialSummary,
             .incomeEntry,
             .expenseEntry,
             .oneTimeEntry,
             .basicRecurringEntry,
             .oneBasicSavingsGoal,
             .defaultTheme:
            return .free
        case .customCategories,
             .subscriptionTracking,
             .billReminders,
             .multipleSavingsGoals,
             .recurringAutomation,
             .dataExport,
             .widgets,
             .spendingInsights,
             .biometricLock,
             .premiumThemes,
             .advancedNotifications,
             .advancedHistoryReporting,
             .forecasting,
             .backupSync:
            return .premium
        case .adsFree:
            return .postponed
        }
    }

    var requiresPremium: Bool {
        accessLevel == .premium
    }
}

// MARK: - Premium Features

enum PremiumFeature: String, CaseIterable {
    case customCategories = "custom_categories"
    case subscriptionTracking = "subscription_tracking"
    case billReminders = "bill_reminders"
    case savingsGoals = "savings_goals"
    case recurringTransactions = "recurring_transactions"
    case dataExport = "data_export"
    case widgets = "widgets"
    case spendingInsights = "spending_insights"
    case biometricLock = "biometric_lock"
    case premiumThemes = "premium_themes"

    var capability: BudgetMeterCapability {
        switch self {
        case .customCategories:
            return .customCategories
        case .subscriptionTracking:
            return .subscriptionTracking
        case .billReminders:
            return .billReminders
        case .savingsGoals:
            return .multipleSavingsGoals
        case .recurringTransactions:
            return .recurringAutomation
        case .dataExport:
            return .dataExport
        case .widgets:
            return .widgets
        case .spendingInsights:
            return .spendingInsights
        case .biometricLock:
            return .biometricLock
        case .premiumThemes:
            return .premiumThemes
        }
    }

    var requiresPremium: Bool {
        capability.requiresPremium
    }
    
    var displayName: String {
        switch self {
        case .customCategories:
            return String(localized: "premium.feature.custom_categories.name", defaultValue: "Custom Categories", table: "UI")
        case .subscriptionTracking:
            return String(localized: "premium.feature.subscription_tracking.name", defaultValue: "Subscription Tracking", table: "UI")
        case .billReminders:
            return String(localized: "premium.feature.bill_reminders.name", defaultValue: "Bill Reminders", table: "UI")
        case .savingsGoals:
            return String(localized: "premium.feature.savings_goals.name", defaultValue: "Savings Goals", table: "UI")
        case .recurringTransactions:
            return String(localized: "premium.feature.recurring_transactions.name", defaultValue: "Recurring Transactions", table: "UI")
        case .dataExport:
            return String(localized: "premium.feature.data_export.name", defaultValue: "Data Export", table: "UI")
        case .widgets:
            return String(localized: "premium.feature.widgets.name", defaultValue: "Widgets", table: "UI")
        case .spendingInsights:
            return String(localized: "premium.feature.spending_insights.name", defaultValue: "Spending Insights", table: "UI")
        case .biometricLock:
            return String(localized: "premium.feature.biometric_lock.name", defaultValue: "Biometric Lock", table: "UI")
        case .premiumThemes:
            return String(localized: "premium.feature.premium_themes.name", defaultValue: "Premium Themes", table: "UI")
        }
    }
    
    var description: String {
        switch self {
        case .customCategories:
            return String(localized: "premium.feature.custom_categories.description", defaultValue: "Create unlimited custom income and expense categories with SF Symbols and colors", table: "UI")
        case .subscriptionTracking:
            return String(localized: "premium.feature.subscription_tracking.description", defaultValue: "Track unlimited subscriptions with renewal reminders and spending insights", table: "UI")
        case .billReminders:
            return String(localized: "premium.feature.bill_reminders.description", defaultValue: "Track bills, due dates, and payment history with smart reminders", table: "UI")
        case .savingsGoals:
            return String(localized: "premium.feature.savings_goals.description", defaultValue: "Create and track multiple savings goals with visual progress and pace tracking", table: "UI")
        case .recurringTransactions:
            return String(localized: "premium.feature.recurring_transactions.description", defaultValue: "Automate repeating bills, salaries, and subscriptions", table: "UI")
        case .dataExport:
            return String(localized: "premium.feature.data_export.description", defaultValue: "Export your data in PDF, CSV, or JSON format", table: "UI")
        case .widgets:
            return String(localized: "premium.feature.widgets.description", defaultValue: "Home Screen widget with your net daily pace", table: "UI")
        case .spendingInsights:
            return String(localized: "premium.feature.spending_insights.description", defaultValue: "Visual charts and insights into your spending patterns", table: "UI")
        case .biometricLock:
            return String(localized: "premium.feature.biometric_lock.description", defaultValue: "Protect your financial data with Face ID or Touch ID", table: "UI")
        case .premiumThemes:
            return String(localized: "premium.feature.premium_themes.description", defaultValue: "Unlock beautiful color themes and custom app icons", table: "UI")
        }
    }
    
    var iconName: String {
        switch self {
        case .customCategories:
            return "tag.fill"
        case .subscriptionTracking:
            return "creditcard"
        case .billReminders:
            return "doc.text"
        case .savingsGoals:
            return "target"
        case .recurringTransactions:
            return "repeat"
        case .dataExport:
            return "square.and.arrow.up"
        case .widgets:
            return "rectangle.3.group"
        case .spendingInsights:
            return "chart.bar.fill"
        case .biometricLock:
            return "faceid"
        case .premiumThemes:
            return "paintbrush.fill"
        }
    }
}
