//
//  OneTimeTransactionSyncMetadataStore.swift
//  BudgetMeter
//
//  Phase 3A sidecar sync metadata for one-time FinancialCategory rows.
//

import CoreData
import Foundation

enum OneTimeTransactionSyncStatus: String {
    case synced
    case pending
    case failed
}

extension Notification.Name {
    static let oneTimeTransactionsDidSync = Notification.Name("OneTimeTransactionsDidSync")
}

enum OneTimeTransactionSyncMapper {

    static func isSyncEligible(_ category: FinancialCategory) -> Bool {
        guard FinancialCategoryWriteSupport.isOneTimeDisplayCategory(category) else { return false }
        guard category.type == "income" || category.type == "expense" else { return false }
        guard category.occurrenceDate != nil else { return false }
        return !resolvedCategoryLabel(for: category).isEmpty
    }

    static func resolvedCategoryLabel(for category: FinancialCategory) -> String {
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

    static func normalizedSourceClientRecordID(from sourceID: String?) -> String? {
        guard var value = sourceID?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else {
            return nil
        }
        if value.hasPrefix("recurring:") {
            value = String(value.dropFirst("recurring:".count))
        }
        return value.isEmpty ? nil : value
    }
}

final class OneTimeTransactionSyncMetadataStore {

    static let shared = OneTimeTransactionSyncMetadataStore()

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

    func metadata(for category: FinancialCategory, in context: NSManagedObjectContext) -> OneTimeTransactionSyncMetadata {
        metadata(forClientRecordID: clientRecordID(for: category), in: context)
    }

    func metadata(forClientRecordID clientRecordID: String, in context: NSManagedObjectContext) -> OneTimeTransactionSyncMetadata {
        let request: NSFetchRequest<OneTimeTransactionSyncMetadata> = OneTimeTransactionSyncMetadata.fetchRequest()
        request.predicate = NSPredicate(format: "clientRecordID == %@", clientRecordID)
        request.fetchLimit = 1

        if let existing = try? context.fetch(request).first {
            return existing
        }

        let record = OneTimeTransactionSyncMetadata(context: context)
        record.clientRecordID = clientRecordID
        record.syncStatus = OneTimeTransactionSyncStatus.pending.rawValue
        return record
    }

    func isTombstoned(_ category: FinancialCategory, in context: NSManagedObjectContext) -> Bool {
        guard FinancialCategoryWriteSupport.isOneTimeDisplayCategory(category) else { return false }
        guard let clientRecordID = category.id?.uuidString else { return false }
        return tombstoneDate(forClientRecordID: clientRecordID, in: context) != nil
    }

    func tombstoneDate(forClientRecordID clientRecordID: String, in context: NSManagedObjectContext) -> Date? {
        let request: NSFetchRequest<OneTimeTransactionSyncMetadata> = OneTimeTransactionSyncMetadata.fetchRequest()
        request.predicate = NSPredicate(format: "clientRecordID == %@", clientRecordID)
        request.fetchLimit = 1
        return try? context.fetch(request).first?.deletedAt
    }

    func markPending(_ category: FinancialCategory, in context: NSManagedObjectContext) {
        guard OneTimeTransactionSyncMapper.isSyncEligible(category) else { return }
        let record = metadata(for: category, in: context)
        record.syncStatus = OneTimeTransactionSyncStatus.pending.rawValue
        record.lastSyncError = nil
    }

    func markSynced(
        clientRecordID: String,
        remoteUpdatedAt: Date?,
        in context: NSManagedObjectContext
    ) {
        let record = metadata(forClientRecordID: clientRecordID, in: context)
        record.syncStatus = OneTimeTransactionSyncStatus.synced.rawValue
        record.lastSyncedAt = Date()
        record.remoteUpdatedAt = remoteUpdatedAt
        record.lastSyncError = nil
    }

    func markFailed(clientRecordID: String, error: String, in context: NSManagedObjectContext) {
        let record = metadata(forClientRecordID: clientRecordID, in: context)
        record.syncStatus = OneTimeTransactionSyncStatus.failed.rawValue
        record.lastSyncError = error
    }

    func tombstone(_ category: FinancialCategory, in context: NSManagedObjectContext) {
        let record = metadata(for: category, in: context)
        record.deletedAt = Date()
        record.syncStatus = OneTimeTransactionSyncStatus.pending.rawValue
        record.lastSyncError = nil
        category.isActive = false
        category.lastModified = Date()
    }

    func fetchAll(in context: NSManagedObjectContext) -> [OneTimeTransactionSyncMetadata] {
        let request: NSFetchRequest<OneTimeTransactionSyncMetadata> = OneTimeTransactionSyncMetadata.fetchRequest()
        return (try? context.fetch(request)) ?? []
    }
}
