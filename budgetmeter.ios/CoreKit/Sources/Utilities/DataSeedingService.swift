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
    func seedInitialDataIfNeeded() {
        let alreadySeeded = userDefaults.bool(forKey: Self.didSeedInitialDataKey)
        print("🌱 DataSeedingService: Checking if data needs seeding...")
        print("🌱 DataSeedingService: Already seeded = \(alreadySeeded)")
        
        guard !alreadySeeded else {
            print("🌱 DataSeedingService: Data already seeded, skipping")
            return // Data already seeded
        }
        
        print("🌱 DataSeedingService: First launch detected, seeding data...")
        seedPredefinedCategories()
        seedInitialAppSettings()
        
        // Mark as seeded
        userDefaults.set(true, forKey: Self.didSeedInitialDataKey)
        print("🌱 DataSeedingService: ✅ Data seeding completed and marked as done")
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
            ("yemek", "Yemek", "daily"),
            ("cay_kahve", "Çay/Kahve", "daily"),
            ("sigara", "Sigara", "daily"),
            ("ulasim", "Ulaşım", "daily"),
            ("diger", "Diğer", "daily")
        ]
        
        // Monthly Expense Categories
        let monthlyExpenses = [
            ("kira", "Kira", "monthly"),
            ("elektrik", "Elektrik", "monthly"),
            ("su", "Su", "monthly"),
            ("dogalgaz", "Doğalgaz", "monthly"),
            ("internet", "İnternet", "monthly"),
            ("telefon", "Telefon", "monthly"),
            ("aidat", "Aidat", "monthly"),
            ("servis", "Servis Ücreti", "monthly"),
            ("arac_yakit", "Araç Yakıtı", "monthly"),
            ("sgk_bagkur", "SGK & Bağkur", "monthly"),
            ("okul_taksit", "Okul Taksidi", "monthly"),
            ("kredi_taksit", "Kredi Taksiti", "monthly"),
            ("kredi_karti", "Kredi Kartı", "monthly"),
            ("gym_monthly", "Spor Salonu (Aylık)", "monthly"),
            ("dijital_abonelikler", "Dijital Abonelikler", "monthly")
        ]
        
        // Yearly Expense Categories
        let yearlyExpenses = [
            ("arac_bakim", "Araç Bakımı", "yearly"),
            ("arac_sigorta", "Araç Sigortası", "yearly"),
            ("mtv", "MTV", "yearly"),
            ("arac_kasko", "Araç Kaskosu", "yearly"),
            ("arac_muayene", "Araç Muayenesi", "yearly"),
            ("dask", "DASK", "yearly"),
            ("saglik_sigorta", "Sağlık Sigortası", "yearly"),
            ("emlak_vergi", "Emlak Vergisi", "yearly"),
            ("tatil", "Tatil Masrafı", "yearly"),
            ("gym_yearly", "Spor Salonu (Yıllık)", "yearly")
        ]
        
        // Create expense categories
        createCategories(dailyExpenses + monthlyExpenses + yearlyExpenses, type: "expense", in: context)
    }
    
    private func seedIncomeCategories(in context: NSManagedObjectContext) {
        // Daily Income Categories
        let dailyIncomes = [
            ("maas", "Maaş", "daily"),
            ("freelance", "Freelance", "daily"),
            ("yatirim", "Yatırım", "daily"),
            ("diger_gelir", "Diğer", "daily")
        ]
        
        // Monthly Income Categories
        let monthlyIncomes = [
            ("aylik_maas", "Aylık Maaş", "monthly"),
            ("kira_geliri", "Kira Geliri", "monthly"),
            ("pasif_gelir", "Pasif Gelir", "monthly"),
            ("bonus", "Bonus", "monthly"),
            ("komisyon", "Komisyon", "monthly"),
            ("dijital_urun", "Dijital Ürün", "monthly"),
            ("egitim", "Eğitim", "monthly"),
            ("danismanlik", "Danışmanlık", "monthly"),
            ("sosyal_medya", "Sosyal Medya", "monthly"),
            ("youtube", "YouTube", "monthly"),
            ("blog", "Blog", "monthly"),
            ("podcast", "Podcast", "monthly"),
            ("online_kurs", "Online Kurs", "monthly"),
            ("affiliate", "Affiliate", "monthly"),
            ("diger_aylik", "Diğer", "monthly")
        ]
        
        // Yearly Income Categories
        let yearlyIncomes = [
            ("yillik_bonus", "Yıllık Bonus", "yearly"),
            ("yatirim_getirisi", "Yatırım Getirisi", "yearly"),
            ("emlak_satisi", "Emlak Satışı", "yearly"),
            ("arac_satisi", "Araç Satışı", "yearly"),
            ("miras", "Miras", "yearly"),
            ("hediye", "Hediye", "yearly"),
            ("ikramiye", "İkramiye", "yearly"),
            ("telif", "Telif", "yearly"),
            ("patent", "Patent", "yearly"),
            ("diger_yillik", "Diğer", "yearly")
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
            }
        } catch {
            print("Error checking for existing AppSettings: \(error)")
        }
    }
}

// MARK: - Category Display Names

extension DataSeedingService {
    
    /// Maps category uniqueIDs to localized display names for UI
    /// Uses String Catalog for proper i18n support
    static func displayName(for uniqueID: String) -> String {
        return String(localized: "category.\(uniqueID).name")
    }
    
    /// Maps category uniqueIDs to SF Symbol names based on design rulebook
    static func sfSymbolName(for uniqueID: String) -> String {
        let symbolNames: [String: String] = [
            // Daily Expenses
            "yemek": "fork.knife",
            "cay_kahve": "cup.and.saucer",
            "sigara": "smoke",
            "ulasim": "bus.fill",
            "diger": "ellipsis.circle",
            
            // Monthly Expenses
            "kira": "house.fill",
            "elektrik": "bolt.fill",
            "su": "drop.fill",
            "dogalgaz": "flame.fill",
            "internet": "wifi",
            "telefon": "phone.fill",
            "aidat": "building.2.fill",
            "servis": "bus.fill",
            "arac_yakit": "fuelpump.fill",
            "sgk_bagkur": "cross.fill",
            "okul_taksit": "graduationcap.fill",
            "kredi_taksit": "banknote.fill",
            "kredi_karti": "creditcard.fill",
            "gym_monthly": "dumbbell.fill",
            "dijital_abonelikler": "tv.fill",
            
            // Yearly Expenses
            "arac_bakim": "wrench.and.screwdriver.fill",
            "arac_sigorta": "car.fill",
            "mtv": "doc.text.fill",
            "arac_kasko": "shield.fill",
            "arac_muayene": "magnifyingglass",
            "dask": "house.and.flag.fill",
            "saglik_sigorta": "stethoscope",
            "emlak_vergi": "building.columns.fill",
            "tatil": "airplane",
            "gym_yearly": "figure.strengthtraining.traditional",
            
            // Daily Income
            "maas": "dollarsign.circle.fill",
            "freelance": "laptopcomputer",
            "yatirim": "chart.line.uptrend.xyaxis",
            "diger_gelir": "plus.circle.fill",
            
            // Monthly Income
            "aylik_maas": "briefcase.fill",
            "kira_geliri": "house.fill",
            "pasif_gelir": "arrow.clockwise",
            "bonus": "gift.fill",
            "komisyon": "percent",
            "dijital_urun": "opticaldisc.fill",
            "egitim": "graduationcap.fill",
            "danismanlik": "handshake.fill",
            "sosyal_medya": "person.3.fill",
            "youtube": "play.rectangle.fill",
            "blog": "doc.text.fill",
            "podcast": "mic.fill",
            "online_kurs": "laptopcomputer",
            "affiliate": "link",
            "diger_aylik": "gem",
            
            // Yearly Income
            "yillik_bonus": "gift.fill",
            "yatirim_getirisi": "chart.bar.fill",
            "emlak_satisi": "building.2.fill",
            "arac_satisi": "car.fill",
            "miras": "crown.fill",
            "hediye": "gift.fill",
            "ikramiye": "trophy.fill",
            "telif": "book.fill",
            "patent": "lightbulb.fill",
            "diger_yillik": "gem"
        ]
        
        return symbolNames[uniqueID] ?? "questionmark.circle"
    }
}
