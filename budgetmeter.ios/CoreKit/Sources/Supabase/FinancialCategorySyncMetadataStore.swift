//
//  FinancialCategorySyncMetadataStore.swift
//  BudgetMeter
//
//  Phase 3B sidecar sync metadata for custom + seeded category sync.
//

import CoreData
import Foundation

enum FinancialCategorySyncStatus: String {
    case synced
    case pending
    case failed
}

enum FinancialCategorySyncRecordKind: String {
    case custom
    case seededOverride = "seeded_override"
}

extension Notification.Name {
    static let financialCategoriesDidSync = Notification.Name("FinancialCategoriesDidSync")
}

enum FinancialCategorySyncMapper {

    static func isCustomRecurringSyncEligible(_ category: FinancialCategory) -> Bool {
        guard category.isCustom else { return false }
        guard FinancialCategoryWriteSupport.isRecurringDisplayCategory(category) else { return false }
        guard !FinancialCategoryWriteSupport.isOneTimeDisplayCategory(category) else { return false }
        guard category.type == "income" || category.type == "expense" else { return false }
        guard let name = trimmedCustomName(for: category), !name.isEmpty else { return false }
        return true
    }

    static func isSeededOverrideSyncEligible(_ category: FinancialCategory) -> Bool {
        guard !category.isCustom else { return false }
        guard FinancialCategoryWriteSupport.isRecurringDisplayCategory(category) else { return false }
        guard let categoryKey = seededCategoryKey(for: category) else { return false }
        return hasSeededUserOverride(category, categoryKey: categoryKey)
    }

    static func hasSeededUserOverride(_ category: FinancialCategory, categoryKey: String? = nil) -> Bool {
        let key = categoryKey ?? seededCategoryKey(for: category)
        guard key != nil else { return false }

        if let label = trimmedCustomName(for: category), !label.isEmpty {
            return true
        }
        if let icon = category.customIconName?.trimmingCharacters(in: .whitespacesAndNewlines), !icon.isEmpty {
            return true
        }
        if let color = category.customColorHex?.trimmingCharacters(in: .whitespacesAndNewlines), !color.isEmpty {
            return true
        }
        return category.isActive == false
    }

    static func seededCategoryKey(for category: FinancialCategory) -> String? {
        guard let uniqueID = category.uniqueID?.trimmingCharacters(in: .whitespacesAndNewlines),
              !uniqueID.isEmpty,
              !uniqueID.hasPrefix("custom_") else {
            return nil
        }
        return uniqueID
    }

    static func seededOverrideRecordKey(type: String, categoryKey: String) -> String {
        "seeded:\(type):\(categoryKey)"
    }

    static func trimmedCustomName(for category: FinancialCategory) -> String? {
        category.customName?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func resolvedCustomCategoryName(for category: FinancialCategory) -> String {
        trimmedCustomName(for: category) ?? "Unknown"
    }
}

final class FinancialCategorySyncMetadataStore {

    static let shared = FinancialCategorySyncMetadataStore()

    private init() {}

    @discardableResult
    func ensureCategoryID(_ category: FinancialCategory) -> UUID {
        if let id = category.id {
            return id
        }
        let id = UUID()
        category.id = id
        return id
    }

    func clientRecordID(for category: FinancialCategory) -> String {
        ensureCategoryID(category).uuidString
    }

    func metadata(forCustom category: FinancialCategory, in context: NSManagedObjectContext) -> FinancialCategorySyncMetadata {
        let clientRecordID = clientRecordID(for: category)
        let record = metadata(forRecordKey: clientRecordID, in: context)
        record.recordKind = FinancialCategorySyncRecordKind.custom.rawValue
        record.clientRecordID = clientRecordID
        record.categoryType = category.type
        return record
    }

    func metadata(
        forSeededOverride type: String,
        categoryKey: String,
        in context: NSManagedObjectContext
    ) -> FinancialCategorySyncMetadata {
        let recordKey = FinancialCategorySyncMapper.seededOverrideRecordKey(type: type, categoryKey: categoryKey)
        let record = metadata(forRecordKey: recordKey, in: context)
        record.recordKind = FinancialCategorySyncRecordKind.seededOverride.rawValue
        record.categoryKey = categoryKey
        record.categoryType = type
        return record
    }

    func metadata(forRecordKey recordKey: String, in context: NSManagedObjectContext) -> FinancialCategorySyncMetadata {
        let request: NSFetchRequest<FinancialCategorySyncMetadata> = FinancialCategorySyncMetadata.fetchRequest()
        request.predicate = NSPredicate(format: "recordKey == %@", recordKey)
        request.fetchLimit = 1

        if let existing = try? context.fetch(request).first {
            if existing.recordKey == nil || existing.recordKey?.isEmpty == true {
                existing.recordKey = recordKey
            }
            return existing
        }

        let record = FinancialCategorySyncMetadata(context: context)
        record.recordKey = recordKey
        record.syncStatus = FinancialCategorySyncStatus.pending.rawValue
        return record
    }

    func isTombstonedCustomCategory(_ category: FinancialCategory, in context: NSManagedObjectContext) -> Bool {
        guard FinancialCategorySyncMapper.isCustomRecurringSyncEligible(category)
            || (category.isCustom && FinancialCategoryWriteSupport.isRecurringDisplayCategory(category)) else {
            return false
        }
        guard let clientRecordID = category.id?.uuidString else { return false }
        return tombstoneDate(forRecordKey: clientRecordID, in: context) != nil
    }

    func tombstoneDate(forRecordKey recordKey: String, in context: NSManagedObjectContext) -> Date? {
        let request: NSFetchRequest<FinancialCategorySyncMetadata> = FinancialCategorySyncMetadata.fetchRequest()
        request.predicate = NSPredicate(format: "recordKey == %@", recordKey)
        request.fetchLimit = 1
        return try? context.fetch(request).first?.deletedAt
    }

    func markCustomPending(_ category: FinancialCategory, in context: NSManagedObjectContext) {
        guard FinancialCategorySyncMapper.isCustomRecurringSyncEligible(category) else { return }
        let record = metadata(forCustom: category, in: context)
        record.syncStatus = FinancialCategorySyncStatus.pending.rawValue
        record.lastSyncError = nil
        FinancialCategoryWriteSupport.touchModified(category)
    }

    func markSeededOverridePending(
        type: String,
        categoryKey: String,
        in context: NSManagedObjectContext
    ) {
        let record = metadata(forSeededOverride: type, categoryKey: categoryKey, in: context)
        record.syncStatus = FinancialCategorySyncStatus.pending.rawValue
        record.lastSyncError = nil
    }

    func markSeededOverridePending(_ category: FinancialCategory, in context: NSManagedObjectContext) {
        guard let categoryKey = FinancialCategorySyncMapper.seededCategoryKey(for: category),
              let type = category.type else {
            return
        }
        guard FinancialCategorySyncMapper.isSeededOverrideSyncEligible(category) else { return }
        markSeededOverridePending(type: type, categoryKey: categoryKey, in: context)
        FinancialCategoryWriteSupport.touchModified(category)
    }

    func markSynced(recordKey: String, remoteUpdatedAt: Date?, in context: NSManagedObjectContext) {
        let record = metadata(forRecordKey: recordKey, in: context)
        record.syncStatus = FinancialCategorySyncStatus.synced.rawValue
        record.lastSyncedAt = Date()
        record.remoteUpdatedAt = remoteUpdatedAt
        record.lastSyncError = nil
    }

    func markFailed(recordKey: String, error: String, in context: NSManagedObjectContext) {
        let record = metadata(forRecordKey: recordKey, in: context)
        record.syncStatus = FinancialCategorySyncStatus.failed.rawValue
        record.lastSyncError = error
    }

    func tombstoneCustomCategory(_ category: FinancialCategory, in context: NSManagedObjectContext) {
        let record = metadata(forCustom: category, in: context)
        record.deletedAt = Date()
        record.syncStatus = FinancialCategorySyncStatus.pending.rawValue
        record.lastSyncError = nil
        category.isActive = false
        category.lastModified = Date()
    }

    func tombstoneSeededOverride(type: String, categoryKey: String, in context: NSManagedObjectContext) {
        let recordKey = FinancialCategorySyncMapper.seededOverrideRecordKey(type: type, categoryKey: categoryKey)
        let record = metadata(forRecordKey: recordKey, in: context)
        record.deletedAt = Date()
        record.syncStatus = FinancialCategorySyncStatus.pending.rawValue
        record.lastSyncError = nil
    }

    func fetchAll(in context: NSManagedObjectContext) -> [FinancialCategorySyncMetadata] {
        let request: NSFetchRequest<FinancialCategorySyncMetadata> = FinancialCategorySyncMetadata.fetchRequest()
        return (try? context.fetch(request)) ?? []
    }
}
