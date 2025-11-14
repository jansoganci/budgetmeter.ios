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
        setupTransactionListener()
        Task {
            await loadProducts()
        }
    }
    
    deinit {
        transactionListener?.cancel()
    }
    
    // MARK: - Feature Access

    /// Check if user has access to Insights Dashboard
    var hasInsights: Bool {
        return isPremium
    }

    /// Check if user has access to Advanced Notifications
    var hasAdvancedNotifications: Bool {
        return isPremium
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
                errorMessage = "Product not available"
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
                    errorMessage = "Purchase cancelled"
                }
                
            case .pending:
                await MainActor.run {
                    errorMessage = "Purchase pending approval"
                }
                
            @unknown default:
                await MainActor.run {
                    errorMessage = "Unknown purchase result"
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = "Purchase failed: \(error.localizedDescription)"
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
            await checkForValidTransactions()
        } catch {
            await MainActor.run {
                errorMessage = "Restore failed: \(error.localizedDescription)"
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
            }
        } catch {
            print("Failed to update premium status: \(error)")
        }
    }
    
    private func checkForValidTransactions() async {
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                if transaction.productID == premiumProductID {
                    await updatePremiumStatus(transaction: transaction)
                    break
                }
            } catch {
                print("Transaction verification failed: \(error)")
            }
        }
    }
    
    // MARK: - Debug Methods
    
    #if DEBUG
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
    
    var localizedDescription: String {
        switch self {
        case .unverifiedTransaction:
            return "Transaction could not be verified"
        case .productNotAvailable:
            return "Premium product is not available"
        case .purchaseFailed:
            return "Purchase failed"
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

// MARK: - Premium Features

enum PremiumFeature: String, CaseIterable {
    case customCategories = "custom_categories"
    case subscriptionTracking = "subscription_tracking"
    case recurringTransactions = "recurring_transactions"
    case dataExport = "data_export"
    case widgets = "widgets"
    case spendingInsights = "spending_insights"
    case biometricLock = "biometric_lock"
    case premiumThemes = "premium_themes"
    
    var displayName: String {
        switch self {
        case .customCategories:
            return "Custom Categories"
        case .subscriptionTracking:
            return "Subscription Tracking"
        case .recurringTransactions:
            return "Recurring Transactions"
        case .dataExport:
            return "Data Export"
        case .widgets:
            return "Widgets"
        case .spendingInsights:
            return "Spending Insights"
        case .biometricLock:
            return "Biometric Lock"
        case .premiumThemes:
            return "Premium Themes"
        }
    }
    
    var description: String {
        switch self {
        case .customCategories:
            return "Create unlimited custom income and expense categories with SF Symbols and colors"
        case .subscriptionTracking:
            return "Track unlimited subscriptions with renewal reminders and spending insights"
        case .recurringTransactions:
            return "Automate repeating bills, salaries, and subscriptions"
        case .dataExport:
            return "Export your data in PDF, CSV, or JSON format"
        case .widgets:
            return "Display your financial data on Home and Lock Screen"
        case .spendingInsights:
            return "Visual charts and insights into your spending patterns"
        case .biometricLock:
            return "Protect your financial data with Face ID or Touch ID"
        case .premiumThemes:
            return "Unlock beautiful color themes and custom app icons"
        }
    }
    
    var iconName: String {
        switch self {
        case .customCategories:
            return "tag.fill"
        case .subscriptionTracking:
            return "creditcard"
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
