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
                // Check if we need to migrate old Turkish uniqueIDs to English
                migrateOldCategoryIDsIfNeeded()
                return
            }
        } else if force {
            if hasExistingCategories() {
                migrateOldCategoryIDsIfNeeded()
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
            ("building_fee", "Building Fee", "monthly"),
            ("service_fee", "Service Fee", "monthly"),
            ("car_fuel", "Car Fuel", "monthly"),
            ("social_security", "Social Security", "monthly"),
            ("school_fee", "School Fee", "monthly"),
            ("loan_payment", "Loan Payment", "monthly"),
            ("credit_card", "Credit Card", "monthly"),
            ("gym_monthly", "Gym (Monthly)", "monthly"),
            ("digital_subscriptions", "Digital Subscriptions", "monthly")
        ]
        
        // Yearly Expense Categories
        let yearlyExpenses = [
            ("car_maintenance", "Car Maintenance", "yearly"),
            ("car_insurance", "Car Insurance", "yearly"),
            ("vehicle_tax", "Vehicle Tax", "yearly"),
            ("car_comprehensive", "Car Comprehensive", "yearly"),
            ("vehicle_inspection", "Vehicle Inspection", "yearly"),
            ("earthquake_insurance", "Earthquake Insurance", "yearly"),
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
            ("digital_product", "Digital Product", "monthly"),
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
            }
        } catch {
            print("Error checking for existing AppSettings: \(error)")
        }
    }
    
    /// Migrates old Turkish uniqueIDs to new English uniqueIDs for existing installations
    private func migrateOldCategoryIDsIfNeeded() {
        let context = persistenceService.viewContext
        let migrationKey = "didMigrateCategoryIDs"
        
        // Check if migration already completed
        if userDefaults.bool(forKey: migrationKey) {
            return
        }
        
        let migrationMap = createTurkishToEnglishMigrationMap()
        
        let fetchRequest: NSFetchRequest<FinancialCategory> = FinancialCategory.fetchRequest()
        
        do {
            let categories = try context.fetch(fetchRequest)
            var migrationCount = 0
            
            for category in categories {
                if let oldUniqueID = category.uniqueID,
                   let newUniqueID = migrationMap[oldUniqueID] {
                    category.uniqueID = newUniqueID
                    migrationCount += 1
                }
            }
            
            if migrationCount > 0 {
                persistenceService.save()
                print("🔄 DataSeedingService: Migrated \(migrationCount) category IDs from Turkish to English")
            }
            
            // Mark migration as completed
            userDefaults.set(true, forKey: migrationKey)
            
        } catch {
            print("❌ DataSeedingService: Failed to migrate category IDs: \(error)")
        }
    }
    
    /// Creates mapping from old Turkish uniqueIDs to new English uniqueIDs
    private func createTurkishToEnglishMigrationMap() -> [String: String] {
        return [
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
            "aidat": "building_fee",
            "servis": "service_fee",
            "arac_yakit": "car_fuel",
            "sgk_bagkur": "social_security",
            "okul_taksit": "school_fee",
            "kredi_taksit": "loan_payment",
            "kredi_karti": "credit_card",
            "dijital_abonelikler": "digital_subscriptions",
            
            // Yearly Expenses
            "arac_bakim": "car_maintenance",
            "arac_sigorta": "car_insurance",
            "mtv": "vehicle_tax",
            "arac_kasko": "car_comprehensive",
            "arac_muayene": "vehicle_inspection",
            "dask": "earthquake_insurance",
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
            "dijital_urun": "digital_product",
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
}

extension DataSeedingService {
    
    /// Maps category uniqueIDs to display names for UI
    /// Uses static mapping to avoid dynamic string interpolation issues
    static func displayName(for uniqueID: String) -> String {
        switch uniqueID {
        // Daily Expenses
        case "food": return "Food"
        case "tea_coffee": return "Tea/Coffee"
        case "cigarettes": return "Cigarettes"
        case "transportation": return "Transportation"
        case "other": return "Other"
        
        // Monthly Expenses
        case "rent": return "Rent"
        case "electricity": return "Electricity"
        case "water": return "Water"
        case "natural_gas": return "Natural Gas"
        case "internet": return "Internet"
        case "phone": return "Phone"
        case "building_fee": return "Building Fee"
        case "service_fee": return "Service Fee"
        case "car_fuel": return "Car Fuel"
        case "social_security": return "Social Security"
        case "school_fee": return "School Fee"
        case "loan_payment": return "Loan Payment"
        case "credit_card": return "Credit Card"
        case "gym_monthly": return "Gym (Monthly)"
        case "digital_subscriptions": return "Digital Subscriptions"
        
        // Yearly Expenses
        case "car_maintenance": return "Car Maintenance"
        case "car_insurance": return "Car Insurance"
        case "vehicle_tax": return "Vehicle Tax"
        case "car_comprehensive": return "Car Comprehensive"
        case "vehicle_inspection": return "Vehicle Inspection"
        case "earthquake_insurance": return "Earthquake Insurance"
        case "health_insurance": return "Health Insurance"
        case "property_tax": return "Property Tax"
        case "vacation": return "Vacation"
        case "gym_yearly": return "Gym (Yearly)"
        
        // Daily Income
        case "salary": return "Salary"
        case "freelance": return "Freelance"
        case "investment": return "Investment"
        case "other_income": return "Other Income"
        
        // Monthly Income
        case "monthly_salary": return "Monthly Salary"
        case "rental_income": return "Rental Income"
        case "passive_income": return "Passive Income"
        case "bonus": return "Bonus"
        case "commission": return "Commission"
        case "digital_product": return "Digital Product"
        case "education": return "Education"
        case "consulting": return "Consulting"
        case "social_media": return "Social Media"
        case "youtube": return "YouTube"
        case "blog": return "Blog"
        case "podcast": return "Podcast"
        case "online_course": return "Online Course"
        case "affiliate": return "Affiliate"
        case "other_monthly": return "Other Monthly"
        
        // Yearly Income
        case "yearly_bonus": return "Yearly Bonus"
        case "investment_return": return "Investment Return"
        case "real_estate_sale": return "Real Estate Sale"
        case "car_sale": return "Car Sale"
        case "inheritance": return "Inheritance"
        case "gift": return "Gift"
        case "prize": return "Prize"
        case "royalty": return "Royalty"
        case "patent": return "Patent"
        case "other_yearly": return "Other Yearly"
        
        // Fallback for unknown IDs
        default: 
            return uniqueID.capitalized.replacingOccurrences(of: "_", with: " ")
        }
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
            "building_fee": "building.2.fill",
            "service_fee": "bus.fill",
            "car_fuel": "fuelpump.fill",
            "social_security": "cross.fill",
            "school_fee": "graduationcap.fill",
            "loan_payment": "banknote.fill",
            "credit_card": "creditcard.fill",
            "gym_monthly": "dumbbell.fill",
            "digital_subscriptions": "tv.fill",
            
            // Yearly Expenses
            "car_maintenance": "wrench.and.screwdriver.fill",
            "car_insurance": "car.fill",
            "vehicle_tax": "doc.text.fill",
            "car_comprehensive": "shield.fill",
            "vehicle_inspection": "magnifyingglass",
            "earthquake_insurance": "house.and.flag.fill",
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
            "digital_product": "opticaldisc.fill",
            "education": "graduationcap.fill",
            "consulting": "handshake.fill",
            "social_media": "person.3.fill",
            "youtube": "play.rectangle.fill",
            "blog": "doc.text.fill",
            "podcast": "mic.fill",
            "online_course": "laptopcomputer",
            "affiliate": "link",
            "other_monthly": "gem",
            
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
            "other_yearly": "gem"
        ]
        
        return symbolNames[uniqueID] ?? "questionmark.circle"
    }
}
