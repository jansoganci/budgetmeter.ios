//
//  RecurringCategoryPaceSyncMetadataStore.swift
//  BudgetMeter
//
//  Phase 3C sidecar sync metadata for recurring pace FinancialCategory rows.
//

import CoreData
import Foundation

enum RecurringCategoryPaceSyncStatus: String {
    case synced
    case pending
    case failed
}

enum RecurringTransactionSourceType {
    static let categoryPace = "categoryPace"
    static let automation = "automation"
}

extension Notification.Name {
    static let recurringCategoryPaceDidSync = Notification.Name("RecurringCategoryPaceDidSync")
}

enum RecurringCategoryPaceSyncMapper {

    static func isSyncEligible(
        _ category: FinancialCategory,
        metadata: RecurringCategoryPaceSyncMetadata?
    ) -> Bool {
        guard FinancialCategoryWriteSupport.isRecurringDisplayCategory(category) else { return false }
        guard category.type == "income" || category.type == "expense" else { return false }
        guard normalized(category.sourceType) != "recurringAutomation" else { return false }
        guard !resolvedTitle(for: category).isEmpty else { return false }

        if category.isCustom {
            return true
        }

        if category.amount > 0 {
            return true
        }
        if metadata?.lastSyncedAt != nil {
            return true
        }
        if metadata?.deletedAt != nil {
            return true
        }
        return false
    }

    static func clientRecordID(for category: FinancialCategory) -> String {
        if category.isCustom {
            return ensureCategoryID(category).uuidString
        }

        if let type = category.type,
           let categoryKey = categoryKey(for: category),
           let frequency = normalizedFrequency(for: category) {
            return "seed:\(type):\(categoryKey):\(frequency)"
        }

        return ensureCategoryID(category).uuidString
    }

    static func resolvedTitle(for category: FinancialCategory) -> String {
        if let customName = category.customName?.trimmingCharacters(in: .whitespacesAndNewlines),
           !customName.isEmpty {
            return customName
        }
        if let uniqueID = category.uniqueID, !uniqueID.isEmpty {
            let displayName = DataSeedingService.displayName(for: uniqueID)
            if !displayName.isEmpty {
                return displayName
            }
        }
        let fallback = category.type?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return fallback.isEmpty ? "Unknown" : fallback
    }

    static func categoryKey(for category: FinancialCategory) -> String? {
        guard let uniqueID = category.uniqueID?.trimmingCharacters(in: .whitespacesAndNewlines),
              !uniqueID.isEmpty,
              !uniqueID.hasPrefix("custom_") else {
            return nil
        }
        return uniqueID
    }

    static func parseSeededClientRecordID(_ value: String) -> (type: String, categoryKey: String, frequency: String)? {
        guard value.hasPrefix("seed:") else { return nil }
        let parts = value.split(separator: ":", omittingEmptySubsequences: false).map(String.init)
        guard parts.count == 4, parts[0] == "seed" else { return nil }
        return (parts[1], parts[2], parts[3])
    }

    static func isCategoryPaceRemoteRow(_ row: SupabaseRecurringTransactionRow) -> Bool {
        if row.sourceType == RecurringTransactionSourceType.categoryPace {
            return true
        }
        if row.sourceType == RecurringTransactionSourceType.automation {
            return false
        }
        if row.clientRecordID.hasPrefix("seed:") {
            return true
        }
        if row.sourceType == nil {
            return row.nextDueDate == nil && row.lastProcessedDate == nil
        }
        return false
    }

    static func isAutomationRemoteRow(_ row: SupabaseRecurringTransactionRow) -> Bool {
        !isCategoryPaceRemoteRow(row)
    }

    @discardableResult
    private static func ensureCategoryID(_ category: FinancialCategory) -> UUID {
        if let id = category.id {
            return id
        }
        let id = UUID()
        category.id = id
        return id
    }

    private static func normalizedFrequency(for category: FinancialCategory) -> String? {
        let frequency = category.frequency?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return frequency.isEmpty ? nil : frequency
    }

    private static func normalized(_ value: String?) -> String {
        value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}

final class RecurringCategoryPaceSyncMetadataStore {

    static let shared = RecurringCategoryPaceSyncMetadataStore()

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
        RecurringCategoryPaceSyncMapper.clientRecordID(for: category)
    }

    func metadata(for category: FinancialCategory, in context: NSManagedObjectContext) -> RecurringCategoryPaceSyncMetadata {
        metadata(forClientRecordID: clientRecordID(for: category), in: context)
    }

    func metadata(
        forClientRecordID clientRecordID: String,
        in context: NSManagedObjectContext
    ) -> RecurringCategoryPaceSyncMetadata {
        let request: NSFetchRequest<RecurringCategoryPaceSyncMetadata> = RecurringCategoryPaceSyncMetadata.fetchRequest()
        request.predicate = NSPredicate(format: "clientRecordID == %@", clientRecordID)
        request.fetchLimit = 1

        if let existing = try? context.fetch(request).first {
            return existing
        }

        let record = RecurringCategoryPaceSyncMetadata(context: context)
        record.clientRecordID = clientRecordID
        record.syncStatus = RecurringCategoryPaceSyncStatus.pending.rawValue
        return record
    }

    func isTombstoned(_ category: FinancialCategory, in context: NSManagedObjectContext) -> Bool {
        guard FinancialCategoryWriteSupport.isRecurringDisplayCategory(category) else { return false }
        let recordID = clientRecordID(for: category)
        return tombstoneDate(forClientRecordID: recordID, in: context) != nil
    }

    func tombstoneDate(forClientRecordID clientRecordID: String, in context: NSManagedObjectContext) -> Date? {
        let request: NSFetchRequest<RecurringCategoryPaceSyncMetadata> = RecurringCategoryPaceSyncMetadata.fetchRequest()
        request.predicate = NSPredicate(format: "clientRecordID == %@", clientRecordID)
        request.fetchLimit = 1
        return try? context.fetch(request).first?.deletedAt
    }

    func markPending(_ category: FinancialCategory, in context: NSManagedObjectContext) {
        let metadata = metadata(for: category, in: context)
        guard RecurringCategoryPaceSyncMapper.isSyncEligible(category, metadata: metadata) else { return }
        metadata.syncStatus = RecurringCategoryPaceSyncStatus.pending.rawValue
        metadata.lastSyncError = nil
    }

    func markSynced(
        clientRecordID: String,
        remoteUpdatedAt: Date?,
        in context: NSManagedObjectContext
    ) {
        let record = metadata(forClientRecordID: clientRecordID, in: context)
        record.syncStatus = RecurringCategoryPaceSyncStatus.synced.rawValue
        record.lastSyncedAt = Date()
        record.remoteUpdatedAt = remoteUpdatedAt
        record.lastSyncError = nil
    }

    func markFailed(clientRecordID: String, error: String, in context: NSManagedObjectContext) {
        let record = metadata(forClientRecordID: clientRecordID, in: context)
        record.syncStatus = RecurringCategoryPaceSyncStatus.failed.rawValue
        record.lastSyncError = error
    }

    func tombstone(_ category: FinancialCategory, in context: NSManagedObjectContext) {
        let record = metadata(for: category, in: context)
        record.deletedAt = Date()
        record.syncStatus = RecurringCategoryPaceSyncStatus.pending.rawValue
        record.lastSyncError = nil
        category.isActive = false
        category.lastModified = Date()
    }
}
