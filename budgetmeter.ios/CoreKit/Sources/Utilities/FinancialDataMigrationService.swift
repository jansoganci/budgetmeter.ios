//
//  FinancialDataMigrationService.swift
//  BudgetMeter
//
//  Phase 2 local data migration for FinancialCategory v3 fields and legacy savings goal.
//

import Foundation
import CoreData

/// Migrates existing Core Data rows after the BudgetMeter v3 model upgrade.
/// Non-destructive and idempotent — safe to call on every launch.
final class FinancialDataMigrationService {

    // MARK: - Version Tracking

    static let migrationVersionKey = "financialDataMigrationVersion"
    static let currentMigrationVersion = 1

    // MARK: - Domain Constants

    private enum EntryKind {
        static let recurring = "recurring"
        static let oneTime = "oneTime"
    }

    private enum SourceType {
        static let recurringAutomation = "recurringAutomation"
    }

    private enum LegacyFrequency {
        static let recurring = "recurring"
    }

    private static let legacySavingsGoalName = "My Goal"
    private static let amountTolerance = 0.01

    // MARK: - Dependencies

    private let persistenceService: PersistenceService
    private let userDefaults: UserDefaults
    private let savingsGoalManager: SavingsGoalManager

    init(
        persistenceService: PersistenceService = .shared,
        userDefaults: UserDefaults = .standard,
        savingsGoalManager: SavingsGoalManager = .shared
    ) {
        self.persistenceService = persistenceService
        self.userDefaults = userDefaults
        self.savingsGoalManager = savingsGoalManager
    }

    // MARK: - Public API

    /// Runs all Phase 2 migrations. Each step is idempotent.
    func performMigrationIfNeeded() {
        let context = persistenceService.viewContext
        var didChange = false

        didChange = migrateFinancialCategoryDefaults(in: context) || didChange
        didChange = migrateLegacyRecurringFrequencyRows(in: context) || didChange
        didChange = migrateLegacySavingsGoalIfNeeded(in: context) || didChange

        if didChange {
            if persistenceService.save() {
                print("✅ FinancialDataMigrationService: Migration changes saved")
            } else {
                print("❌ FinancialDataMigrationService: Failed to save migration changes")
                return
            }
        } else {
            print("🔄 FinancialDataMigrationService: No migration changes required")
        }

        markMigrationCompletedIfNeeded()
    }

    /// Current recorded migration version in UserDefaults.
    var recordedMigrationVersion: Int {
        userDefaults.integer(forKey: Self.migrationVersionKey)
    }

    // MARK: - FinancialCategory Defaults

    @discardableResult
    private func migrateFinancialCategoryDefaults(in context: NSManagedObjectContext) -> Bool {
        let categories = fetchFinancialCategories(in: context)
        var changedCount = 0

        for category in categories {
            guard !isLegacyRecurringFrequencyRow(category) else { continue }
            guard needsDefaultFieldMigration(category) else { continue }

            applyDefaultFields(to: category)
            changedCount += 1
        }

        if changedCount > 0 {
            print("🔄 FinancialDataMigrationService: Updated default fields on \(changedCount) categories")
        }

        return changedCount > 0
    }

    private func needsDefaultFieldMigration(_ category: FinancialCategory) -> Bool {
        normalized(category.entryKind).isEmpty
    }

    private func applyDefaultFields(to category: FinancialCategory) {
        category.entryKind = EntryKind.recurring
        category.lastModified = Date()
    }

    // MARK: - Legacy frequency == "recurring"

    @discardableResult
    private func migrateLegacyRecurringFrequencyRows(in context: NSManagedObjectContext) -> Bool {
        let legacyRows = fetchFinancialCategories(in: context).filter(isLegacyRecurringFrequencyRow)
        guard !legacyRows.isEmpty else { return false }

        let recurringTransactions = fetchRecurringTransactions(in: context)
        var changedCount = 0

        for category in legacyRows {
            guard needsLegacyRecurringFrequencyMigration(category) else { continue }

            if let match = findMatchingRecurringTransaction(for: category, in: recurringTransactions),
               let recurringID = match.id {
                category.sourceType = SourceType.recurringAutomation
                category.sourceID = "recurring:\(recurringID.uuidString)"
            }

            category.entryKind = EntryKind.oneTime
            category.occurrenceDate = category.createdAt ?? Date()
            category.isActive = true
            category.lastModified = Date()
            changedCount += 1
        }

        if changedCount > 0 {
            print("🔄 FinancialDataMigrationService: Reclassified \(changedCount) legacy recurring-frequency categories")
        }

        return changedCount > 0
    }

    private func isLegacyRecurringFrequencyRow(_ category: FinancialCategory) -> Bool {
        normalized(category.frequency) == LegacyFrequency.recurring
    }

    private func needsLegacyRecurringFrequencyMigration(_ category: FinancialCategory) -> Bool {
        if normalized(category.entryKind) == EntryKind.oneTime {
            return false
        }
        if normalized(category.sourceType) == SourceType.recurringAutomation {
            return false
        }
        return true
    }

    private func findMatchingRecurringTransaction(
        for category: FinancialCategory,
        in transactions: [RecurringTransaction]
    ) -> RecurringTransaction? {
        guard let categoryType = category.type else { return nil }

        let candidates = transactions.filter { transaction in
            transaction.categoryType == categoryType
                && abs(transaction.amount - category.amount) <= Self.amountTolerance
        }

        guard !candidates.isEmpty else { return nil }
        if candidates.count == 1 { return candidates[0] }

        guard let createdAt = category.createdAt else {
            return candidates.first
        }

        return candidates.min { lhs, rhs in
            let lhsDate = lhs.lastProcessedDate ?? lhs.startDate ?? .distantPast
            let rhsDate = rhs.lastProcessedDate ?? rhs.startDate ?? .distantPast
            return abs(lhsDate.timeIntervalSince(createdAt)) < abs(rhsDate.timeIntervalSince(createdAt))
        }
    }

    // MARK: - Savings Goal

    @discardableResult
    private func migrateLegacySavingsGoalIfNeeded(in context: NSManagedObjectContext) -> Bool {
        guard let settings = fetchAppSettings(in: context) else { return false }
        guard settings.savingsGoalAmount > 0 else { return false }
        guard !hasActiveSavingsGoal(in: context) else { return false }

        let created = savingsGoalManager.createGoal(
            name: Self.legacySavingsGoalName,
            targetAmount: settings.savingsGoalAmount,
            currentAmount: 0,
            notes: "Migrated from AppSettings.savingsGoalAmount"
        )

        if created != nil {
            print("🔄 FinancialDataMigrationService: Created savings goal from AppSettings.savingsGoalAmount")
            return true
        }

        print("❌ FinancialDataMigrationService: Failed to create savings goal from AppSettings")
        return false
    }

    // MARK: - Fetch Helpers

    private func fetchFinancialCategories(in context: NSManagedObjectContext) -> [FinancialCategory] {
        let request: NSFetchRequest<FinancialCategory> = FinancialCategory.fetchRequest()
        do {
            return try context.fetch(request)
        } catch {
            print("❌ FinancialDataMigrationService: Failed to fetch categories: \(error)")
            return []
        }
    }

    private func fetchRecurringTransactions(in context: NSManagedObjectContext) -> [RecurringTransaction] {
        let request: NSFetchRequest<RecurringTransaction> = RecurringTransaction.fetchRequest()
        do {
            return try context.fetch(request)
        } catch {
            print("❌ FinancialDataMigrationService: Failed to fetch recurring transactions: \(error)")
            return []
        }
    }

    private func fetchAppSettings(in context: NSManagedObjectContext) -> AppSettings? {
        let request: NSFetchRequest<AppSettings> = AppSettings.fetchRequest()
        request.fetchLimit = 1
        do {
            return try context.fetch(request).first
        } catch {
            print("❌ FinancialDataMigrationService: Failed to fetch app settings: \(error)")
            return nil
        }
    }

    private func hasActiveSavingsGoal(in context: NSManagedObjectContext) -> Bool {
        let request: NSFetchRequest<SavingsGoal> = SavingsGoal.fetchRequest()
        request.predicate = NSPredicate(format: "isArchived == NO")
        request.fetchLimit = 1
        do {
            return try context.fetch(request).isEmpty == false
        } catch {
            print("❌ FinancialDataMigrationService: Failed to fetch savings goals: \(error)")
            return true
        }
    }

    // MARK: - Version Marker

    private func markMigrationCompletedIfNeeded() {
        let recorded = userDefaults.integer(forKey: Self.migrationVersionKey)
        guard recorded < Self.currentMigrationVersion else {
            print("🔄 FinancialDataMigrationService: Migration version \(recorded) already current")
            return
        }

        userDefaults.set(Self.currentMigrationVersion, forKey: Self.migrationVersionKey)
        print("✅ FinancialDataMigrationService: Recorded migration version \(Self.currentMigrationVersion)")
    }

    // MARK: - Utilities

    private func normalized(_ value: String?) -> String {
        value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}
