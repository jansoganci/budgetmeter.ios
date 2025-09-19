//
//  DataSeedingService.swift
//  BudgetMeter
//
//  Created by BudgetMeter Team on 17.09.2025.
//

import Foundation
import CoreData
import SwiftUI

/// Service responsible for seeding initial data on first app launch
final class DataSeedingService {
    
    private let persistenceService: PersistenceService
    private let userDefaults: UserDefaults
    
    private static let didSeedInitialDataKey = "didSeedInitialData"
    
    init(
        persistenceService: PersistenceService = .shared,
        userDefaults: UserDefaults = .standard
    ) {
        self.persistenceService = persistenceService
        self.userDefaults = userDefaults
    }
    
    /// Seeds initial data if this is the first app launch
    func seedInitialDataIfNeeded(force: Bool = false) {
        let alreadySeeded = userDefaults.bool(forKey: Self.didSeedInitialDataKey)
        
        if !force && alreadySeeded {
            if hasExistingCategories() {
                // Only run migration if we haven't already completed it
                let migrationVersionKey = "categoryIDMigrationVersion"
                let requiredVersion = 2
                if userDefaults.integer(forKey: migrationVersionKey) < requiredVersion {
                    migrateOldCategoryIDsIfNeeded()
                }
                ensureCurrencyPreference()
                return
            }
        } else if force {
            if hasExistingCategories() {
                // Only run migration if we haven't already completed it
                let migrationVersionKey = "categoryIDMigrationVersion"
                let requiredVersion = 2
                if userDefaults.integer(forKey: migrationVersionKey) < requiredVersion {
                    migrateOldCategoryIDsIfNeeded()
                }
                ensureCurrencyPreference()
                return
            }
        }

        seedPredefinedCategories()
        seedInitialAppSettings()
        
        userDefaults.set(true, forKey: Self.didSeedInitialDataKey)
    }
    
    // MARK: - Private Methods
    
    private func seedPredefinedCategories() {
        let context = persistenceService.viewContext
        
        // Seed expense categories
        seedExpenseCategories(in: context)
        
        // Seed income categories
        seedIncomeCategories(in: context)
        
        // Save context
        persistenceService.save()
    }
    
    private func seedExpenseCategories(in context: NSManagedObjectContext) {
        // Daily Expense Categories
        let dailyExpenses = [
            ("food", "Food", "daily"),
            ("tea_coffee", "Tea/Coffee", "daily"),
            ("cigarettes", "Cigarettes", "daily"),
            ("transportation", "Transportation", "daily"),
            ("other", "Other", "daily")
        ]
        
        // Monthly Expense Categories
        let monthlyExpenses = [
            ("rent", "Rent", "monthly"),
            ("electricity", "Electricity", "monthly"),
            ("water", "Water", "monthly"),
            ("natural_gas", "Natural Gas", "monthly"),
            ("internet", "Internet", "monthly"),
            ("phone", "Phone", "monthly"),
            ("hoa_fees", "HOA Fees", "monthly"),
            ("maintenance_fees", "Maintenance Fees", "monthly"),
            ("car_fuel", "Car Fuel", "monthly"),
            ("social_security", "Social Security", "monthly"),
            ("school_fee", "School Fee", "monthly"),
            ("loan_payment", "Loan Payment", "monthly"),
            ("credit_card", "Credit Card", "monthly"),
            ("gym_monthly", "Gym (Monthly)", "monthly"),
            ("streaming_services", "Streaming Services", "monthly")
        ]
        
        // Yearly Expense Categories
        let yearlyExpenses = [
            ("car_maintenance", "Car Maintenance", "yearly"),
            ("car_insurance", "Car Insurance", "yearly"),
            ("vehicle_tax", "Vehicle Tax", "yearly"),
            ("comprehensive_insurance", "Comprehensive Insurance", "yearly"),
            ("vehicle_inspection", "Vehicle Inspection", "yearly"),
            ("property_insurance", "Property Insurance", "yearly"),
            ("health_insurance", "Health Insurance", "yearly"),
            ("property_tax", "Property Tax", "yearly"),
            ("vacation", "Vacation", "yearly"),
            ("gym_yearly", "Gym (Yearly)", "yearly")
        ]
        
        // Create expense categories
        createCategories(dailyExpenses + monthlyExpenses + yearlyExpenses, type: "expense", in: context)
    }
    
    private func seedIncomeCategories(in context: NSManagedObjectContext) {
        // Daily Income Categories
        let dailyIncomes = [
            ("salary", "Salary", "daily"),
            ("freelance", "Freelance", "daily"),
            ("investment", "Investment", "daily"),
            ("other_income", "Other Income", "daily")
        ]
        
        // Monthly Income Categories
        let monthlyIncomes = [
            ("monthly_salary", "Monthly Salary", "monthly"),
            ("rental_income", "Rental Income", "monthly"),
            ("passive_income", "Passive Income", "monthly"),
            ("bonus", "Bonus", "monthly"),
            ("commission", "Commission", "monthly"),
            ("online_business", "Online Business", "monthly"),
            ("education", "Education", "monthly"),
            ("consulting", "Consulting", "monthly"),
            ("social_media", "Social Media", "monthly"),
            ("youtube", "YouTube", "monthly"),
            ("blog", "Blog", "monthly"),
            ("podcast", "Podcast", "monthly"),
            ("online_course", "Online Course", "monthly"),
            ("affiliate", "Affiliate", "monthly"),
            ("other_monthly", "Other Monthly", "monthly")
        ]
        
        // Yearly Income Categories
        let yearlyIncomes = [
            ("yearly_bonus", "Yearly Bonus", "yearly"),
            ("investment_return", "Investment Return", "yearly"),
            ("real_estate_sale", "Real Estate Sale", "yearly"),
            ("car_sale", "Car Sale", "yearly"),
            ("inheritance", "Inheritance", "yearly"),
            ("gift", "Gift", "yearly"),
            ("prize", "Prize", "yearly"),
            ("royalty", "Royalty", "yearly"),
            ("patent", "Patent", "yearly"),
            ("other_yearly", "Other Yearly", "yearly")
        ]
        
        // Create income categories
        createCategories(dailyIncomes + monthlyIncomes + yearlyIncomes, type: "income", in: context)
    }
    
    private func createCategories(
        _ categories: [(uniqueID: String, name: String, frequency: String)],
        type: String,
        in context: NSManagedObjectContext
    ) {
        for category in categories {
            let financialCategory = FinancialCategory(context: context)
            financialCategory.id = UUID()
            financialCategory.uniqueID = category.uniqueID
            financialCategory.amount = 0.0 // Start with zero amount
            financialCategory.type = type
            financialCategory.frequency = category.frequency
            
            // Note: We don't store the display name in Core Data as it will be
            // handled by localization. The uniqueID is used to map to display names.
        }
    }
    
    private func seedInitialAppSettings() {
        let context = persistenceService.viewContext

        // Check if AppSettings already exists
        let fetchRequest: NSFetchRequest<AppSettings> = AppSettings.fetchRequest()
        
        do {
            let existingSettings = try context.fetch(fetchRequest)
            if existingSettings.isEmpty {
                // Create initial AppSettings
                let appSettings = AppSettings(context: context)
                appSettings.lastBackgroundedTimestamp = nil
                appSettings.lastMeterValue = 0.0
                appSettings.savingsGoalAmount = 0.0
                appSettings.cumulativeTotal = 0.0
                appSettings.cumulativeStartDate = Date()
                appSettings.preferredCurrencyCode = CurrencyHelper.defaultCurrencyCode()
            } else if let existing = existingSettings.first,
                      existing.preferredCurrencyCode == nil {
                existing.preferredCurrencyCode = CurrencyHelper.defaultCurrencyCode()
                persistenceService.save()
            }
        } catch {
            print("Error checking for existing AppSettings: \(error)")
        }
    }
    
    /// Migrates legacy uniqueIDs to the latest canonical identifiers for existing installations
    private func migrateOldCategoryIDsIfNeeded() {
        let context = persistenceService.viewContext
        let migrationVersionKey = "categoryIDMigrationVersion"
        let requiredVersion = 2

        // More robust check - ensure migration only runs once
        let currentVersion = userDefaults.integer(forKey: migrationVersionKey)
        if currentVersion >= requiredVersion {
            print("🔄 DataSeedingService: Migration already completed (version \(currentVersion))")
            return
        }
        
        print("🔄 DataSeedingService: Starting category ID migration...")
        
        let migrationMap = createLegacyCategoryIDMigrationMap()
        
        let fetchRequest: NSFetchRequest<FinancialCategory> = FinancialCategory.fetchRequest()
        
        do {
            let categories = try context.fetch(fetchRequest)
            
            // Check if any categories actually need migration
            let needsMigration = categories.contains { category in
                guard let uniqueID = category.uniqueID else { return false }
                return migrationMap.keys.contains(uniqueID)
            }
            
            if !needsMigration {
                print("🔄 DataSeedingService: No categories need migration")
                userDefaults.set(requiredVersion, forKey: migrationVersionKey)
                return
            }
            
            var categoriesByID: [String: FinancialCategory] = [:]
            for category in categories {
                if let id = category.uniqueID {
                    categoriesByID[id] = category
                }
            }

            var migrationCount = 0
            var categoriesToDelete: [FinancialCategory] = []
            
            for category in categories {
                if let oldUniqueID = category.uniqueID,
                   let newUniqueID = migrationMap[oldUniqueID] {
                    
                    if let existing = categoriesByID[newUniqueID], existing != category {
                        // Only merge if both categories exist and are different
                        print("🔄 DataSeedingService: Merging \(oldUniqueID) -> \(newUniqueID) (amount: \(category.amount))")
                        existing.amount += category.amount
                        categoriesToDelete.append(category)
                    } else {
                        // Just update the uniqueID
                        print("🔄 DataSeedingService: Updating \(oldUniqueID) -> \(newUniqueID)")
                        category.uniqueID = newUniqueID
                        categoriesByID[newUniqueID] = category
                    }
                    migrationCount += 1
                }
            }
            
            // Delete categories in separate loop to avoid modifying array while iterating
            for categoryToDelete in categoriesToDelete {
                context.delete(categoryToDelete)
            }
            
            if migrationCount > 0 {
                persistenceService.save()
                print("🔄 DataSeedingService: Successfully migrated \(migrationCount) legacy category IDs, deleted \(categoriesToDelete.count) duplicates")
            }
            
            // Mark migration as completed
            userDefaults.set(requiredVersion, forKey: migrationVersionKey)
            userDefaults.synchronize() // Force immediate save
            
        } catch {
            print("❌ DataSeedingService: Failed to migrate category IDs: \(error)")
            // Don't set migration version if it failed
        }
    }
    
    /// Creates mapping from legacy uniqueIDs (Turkish and earlier English identifiers) to current canonical IDs
    private func createLegacyCategoryIDMigrationMap() -> [String: String] {
        let turkishToCanonical: [String: String] = [
            // Daily Expenses
            "yemek": "food",
            "cay_kahve": "tea_coffee",
            "sigara": "cigarettes",
            "ulasim": "transportation",
            "diger": "other",
            
            // Monthly Expenses
            "kira": "rent",
            "elektrik": "electricity",
            "su": "water",
            "dogalgaz": "natural_gas",
            "telefon": "phone",
            "aidat": "hoa_fees",
            "servis": "maintenance_fees",
            "arac_yakit": "car_fuel",
            "sgk_bagkur": "social_security",
            "okul_taksit": "school_fee",
            "kredi_taksit": "loan_payment",
            "kredi_karti": "credit_card",
            "dijital_abonelikler": "streaming_services",
            
            // Yearly Expenses
            "arac_bakim": "car_maintenance",
            "arac_sigorta": "car_insurance",
            "mtv": "vehicle_tax",
            "arac_kasko": "comprehensive_insurance",
            "arac_muayene": "vehicle_inspection",
            "dask": "property_insurance",
            "saglik_sigorta": "health_insurance",
            "emlak_vergi": "property_tax",
            "tatil": "vacation",
            
            // Daily Income
            "maas": "salary",
            "yatirim": "investment",
            "diger_gelir": "other_income",
            
            // Monthly Income
            "aylik_maas": "monthly_salary",
            "kira_geliri": "rental_income",
            "pasif_gelir": "passive_income",
            "komisyon": "commission",
            "dijital_urun": "other_income",
            "egitim": "education",
            "danismanlik": "consulting",
            "sosyal_medya": "social_media",
            "online_kurs": "online_course",
            "diger_aylik": "other_monthly",
            
            // Yearly Income
            "yillik_bonus": "yearly_bonus",
            "yatirim_getirisi": "investment_return",
            "emlak_satisi": "real_estate_sale",
            "arac_satisi": "car_sale",
            "miras": "inheritance",
            "hediye": "gift",
            "ikramiye": "prize",
            "telif": "royalty",
            "diger_yillik": "other_yearly"
        ]
        
        let englishLegacyToCanonical: [String: String] = [
            "building_fee": "hoa_fees",
            "service_fee": "maintenance_fees",
            "digital_subscriptions": "streaming_services",
            "car_comprehensive": "comprehensive_insurance",
            "earthquake_insurance": "property_insurance",
            "digital_product": "other_income"
        ]
        
        return turkishToCanonical.merging(englishLegacyToCanonical) { _, new in new }
    }
}

// MARK: - Category Display Names

private extension DataSeedingService {
    func hasExistingCategories() -> Bool {
        let context = persistenceService.viewContext
        let fetchRequest: NSFetchRequest<FinancialCategory> = FinancialCategory.fetchRequest()
        fetchRequest.fetchLimit = 1
        do {
            let count = try context.count(for: fetchRequest)
            return count > 0
        } catch {
            print("🌱 DataSeedingService: Failed to check existing categories: \(error)")
            return false
        }
    }

    func ensureCurrencyPreference() {
        let context = persistenceService.viewContext
        let fetchRequest: NSFetchRequest<AppSettings> = AppSettings.fetchRequest()

        guard let settings = try? context.fetch(fetchRequest),
              let existing = settings.first,
              existing.preferredCurrencyCode == nil else {
            return
        }

        existing.preferredCurrencyCode = CurrencyHelper.defaultCurrencyCode()
        persistenceService.save()
    }
}

extension DataSeedingService {
    
    /// Maps category uniqueIDs to localized display names for UI
    static func displayName(for uniqueID: String) -> String {
        let key = "category.\(uniqueID).name"
        let defaultValue = uniqueID.replacingOccurrences(of: "_", with: " ").capitalized
        return key.localized(defaultValue: defaultValue)
    }
    
    /// Maps category uniqueIDs to SF Symbol names based on design rulebook
    static func sfSymbolName(for uniqueID: String) -> String {
        let symbolNames: [String: String] = [
            // Daily Expenses
            "food": "fork.knife",
            "tea_coffee": "cup.and.saucer",
            "cigarettes": "smoke",
            "transportation": "bus.fill",
            "other": "ellipsis.circle",
            
            // Monthly Expenses
            "rent": "house.fill",
            "electricity": "bolt.fill",
            "water": "drop.fill",
            "natural_gas": "flame.fill",
            "internet": "wifi",
            "phone": "phone.fill",
            "hoa_fees": "building.2.fill",
            "maintenance_fees": "wrench.and.screwdriver.fill",
            "car_fuel": "fuelpump.fill",
            "social_security": "cross.fill",
            "school_fee": "graduationcap.fill",
            "loan_payment": "banknote.fill",
            "credit_card": "creditcard.fill",
            "gym_monthly": "dumbbell.fill",
            "streaming_services": "tv.fill",
            
            // Yearly Expenses
            "car_maintenance": "wrench.and.screwdriver.fill",
            "car_insurance": "car.fill",
            "vehicle_tax": "doc.text.fill",
            "comprehensive_insurance": "shield.fill",
            "vehicle_inspection": "magnifyingglass",
            "property_insurance": "house.and.flag.fill",
            "health_insurance": "stethoscope",
            "property_tax": "building.columns.fill",
            "vacation": "airplane",
            "gym_yearly": "figure.strengthtraining.traditional",
            
            // Daily Income
            "salary": "dollarsign.circle.fill",
            "freelance": "laptopcomputer",
            "investment": "chart.line.uptrend.xyaxis",
            "other_income": "plus.circle.fill",
            
            // Monthly Income
            "monthly_salary": "briefcase.fill",
            "rental_income": "house.fill",
            "passive_income": "arrow.clockwise",
            "bonus": "gift.fill",
            "commission": "percent",
            "online_business": "desktopcomputer",
            "education": "graduationcap.fill",
            "consulting": "briefcase.circle.fill",
            "social_media": "person.3.fill",
            "youtube": "play.rectangle.fill",
            "blog": "doc.text.fill",
            "podcast": "mic.fill",
            "online_course": "laptopcomputer",
            "affiliate": "link",
            "other_monthly": "star.circle.fill",
            
            // Yearly Income
            "yearly_bonus": "gift.fill",
            "investment_return": "chart.bar.fill",
            "real_estate_sale": "building.2.fill",
            "car_sale": "car.fill",
            "inheritance": "crown.fill",
            "gift": "gift.fill",
            "prize": "trophy.fill",
            "royalty": "book.fill",
            "patent": "lightbulb.fill",
            "other_yearly": "star.circle.fill"
        ]
        
        return symbolNames[uniqueID] ?? "questionmark.circle"
    }
}
