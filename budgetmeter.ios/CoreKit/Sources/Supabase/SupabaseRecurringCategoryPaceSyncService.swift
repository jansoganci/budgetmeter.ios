//
//  SupabaseRecurringCategoryPaceSyncService.swift
//  BudgetMeter
//
//  Phase 3C recurring pace (Income/Expense FinancialCategory) Supabase sync.
//

import CoreData
import Foundation
import Supabase

protocol RecurringCategoryPaceSyncScheduling: AnyObject {
    func scheduleSync()
    func bootstrapSignedInAccount() async
    func registerLocalRecurringPaceRow(_ category: FinancialCategory)
    func tombstoneLocalRecurringPaceRow(_ category: FinancialCategory)
}

@MainActor
final class SupabaseRecurringCategoryPaceSyncService: RecurringCategoryPaceSyncScheduling {
    static let shared = SupabaseRecurringCategoryPaceSyncService()

    private let persistenceService: PersistenceService
    private let remoteStore: SupabaseRecurringTransactionRemoteStoreProtocol
    private let metadataStore: RecurringCategoryPaceSyncMetadataStore
    private var isSyncInFlight = false
    private var hasQueuedSync = false

    init(
        persistenceService: PersistenceService = .shared,
        remoteStore: SupabaseRecurringTransactionRemoteStoreProtocol = SupabaseRecurringTransactionRemoteStore(),
        metadataStore: RecurringCategoryPaceSyncMetadataStore = .shared
    ) {
        self.persistenceService = persistenceService
        self.remoteStore = remoteStore
        self.metadataStore = metadataStore
    }

    func bootstrapSignedInAccount() async {
        await requestSync()
    }

    func scheduleSync() {
        Task { @MainActor in
            await self.requestSync()
        }
    }

    func registerLocalRecurringPaceRow(_ category: FinancialCategory) {
        let context = persistenceService.viewContext
        RecordCurrencySupport.stampCurrencyCodeIfNeeded(on: category)
        metadataStore.markPending(category, in: context)
        _ = persistenceService.save()
        scheduleSync()
    }

    func tombstoneLocalRecurringPaceRow(_ category: FinancialCategory) {
        let context = persistenceService.viewContext
        metadataStore.tombstone(category, in: context)
        _ = persistenceService.save()
        scheduleSync()
    }

    private func requestSync() async {
        if isSyncInFlight {
            hasQueuedSync = true
            return
        }

        repeat {
            hasQueuedSync = false
            isSyncInFlight = true
            await performSyncPass()
            isSyncInFlight = false
        } while hasQueuedSync
    }

    private func performSyncPass() async {
        guard let userID = await remoteStore.currentAuthenticatedUserID() else { return }

        do {
            let remoteRows = try await remoteStore.fetchRecurringTransactions(userID: userID)
            let paceRows = remoteRows.filter { RecurringCategoryPaceSyncMapper.isCategoryPaceRemoteRow($0) }
            try await reconcile(
                localContext: persistenceService.viewContext,
                userID: userID,
                remoteRows: paceRows
            )
        } catch {
            print("☁️ SupabaseRecurringCategoryPaceSyncService: sync skipped (\(error))")
        }
    }

    private func reconcile(
        localContext: NSManagedObjectContext,
        userID: UUID,
        remoteRows: [SupabaseRecurringTransactionRow]
    ) async throws {
        let localEntries = fetchEligibleLocalEntries(in: localContext)
        var localByClientRecordID: [String: LocalSyncEntry] = [:]
        for entry in localEntries {
            localByClientRecordID[entry.clientRecordID] = entry
        }

        let remoteByClientRecordID = Dictionary(uniqueKeysWithValues: remoteRows.map { ($0.clientRecordID, $0) })
        var didMutateLocalState = false
        var shouldRefreshViews = false

        for remoteRow in remoteRows {
            if let localEntry = localByClientRecordID[remoteRow.clientRecordID] {
                try await reconcilePair(
                    remoteRow: remoteRow,
                    localEntry: localEntry,
                    userID: userID,
                    localContext: localContext,
                    didMutateLocalState: &didMutateLocalState,
                    shouldRefreshViews: &shouldRefreshViews
                )
            } else if remoteRow.deletedAt == nil {
                if insertLocalRow(from: remoteRow, into: localContext) != nil {
                    didMutateLocalState = true
                    shouldRefreshViews = true
                }
            }
        }

        for entry in localEntries {
            guard remoteByClientRecordID[entry.clientRecordID] == nil else { continue }

            if entry.metadata.deletedAt != nil {
                if entry.metadata.lastSyncedAt != nil {
                    metadataStore.markSynced(
                        clientRecordID: entry.clientRecordID,
                        remoteUpdatedAt: entry.metadata.remoteUpdatedAt,
                        in: localContext
                    )
                    didMutateLocalState = true
                } else if let uploadedRow = try? await uploadLocalEntry(
                    category: entry.category,
                    metadata: entry.metadata,
                    userID: userID
                ) {
                    applyRemoteRow(uploadedRow, to: entry.category, metadata: entry.metadata, in: localContext)
                    didMutateLocalState = true
                    shouldRefreshViews = true
                } else {
                    metadataStore.markFailed(
                        clientRecordID: entry.clientRecordID,
                        error: "Tombstone upload failed",
                        in: localContext
                    )
                    didMutateLocalState = true
                }
                continue
            }

            if let uploadedRow = try? await uploadLocalEntry(
                category: entry.category,
                metadata: entry.metadata,
                userID: userID
            ) {
                applyRemoteRow(uploadedRow, to: entry.category, metadata: entry.metadata, in: localContext)
                didMutateLocalState = true
                shouldRefreshViews = true
            } else {
                metadataStore.markFailed(
                    clientRecordID: entry.clientRecordID,
                    error: "Initial upload failed",
                    in: localContext
                )
                didMutateLocalState = true
            }
        }

        if didMutateLocalState {
            _ = persistenceService.save()
        }

        if shouldRefreshViews {
            NotificationCenter.default.post(name: .recurringCategoryPaceDidSync, object: nil)
        }
    }

    private func reconcilePair(
        remoteRow: SupabaseRecurringTransactionRow,
        localEntry: LocalSyncEntry,
        userID: UUID,
        localContext: NSManagedObjectContext,
        didMutateLocalState: inout Bool,
        shouldRefreshViews: inout Bool
    ) async throws {
        let category = localEntry.category
        let metadata = localEntry.metadata
        let localTimestamp = mutationTimestamp(for: category, metadata: metadata)
        let remoteTimestamp = remoteMutationTimestamp(for: remoteRow)
        let localDeletedAt = metadata.deletedAt
        let remoteDeletedAt = remoteRow.deletedAt

        if let remoteDeletedAt {
            if localDeletedAt == nil
                || remoteTimestamp >= localTimestamp
                || metadata.syncStatus == RecurringCategoryPaceSyncStatus.synced.rawValue {
                applyRemoteRow(remoteRow, to: category, metadata: metadata, in: localContext)
                metadata.deletedAt = remoteDeletedAt
                category.isActive = false
                didMutateLocalState = true
                shouldRefreshViews = true
            } else if let uploadedRow = try? await uploadLocalEntry(category: category, metadata: metadata, userID: userID) {
                applyRemoteTimestamps(from: uploadedRow, metadata: metadata, in: localContext)
                didMutateLocalState = true
            }
            return
        }

        if localDeletedAt != nil {
            if localTimestamp >= remoteTimestamp {
                if let uploadedRow = try? await uploadLocalEntry(category: category, metadata: metadata, userID: userID) {
                    applyRemoteTimestamps(from: uploadedRow, metadata: metadata, in: localContext)
                    didMutateLocalState = true
                } else {
                    metadataStore.markFailed(
                        clientRecordID: localEntry.clientRecordID,
                        error: "Upload failed",
                        in: localContext
                    )
                    didMutateLocalState = true
                }
            } else {
                applyRemoteRow(remoteRow, to: category, metadata: metadata, in: localContext)
                didMutateLocalState = true
                shouldRefreshViews = true
            }
            return
        }

        if remoteTimestamp > localTimestamp {
            applyRemoteRow(remoteRow, to: category, metadata: metadata, in: localContext)
            didMutateLocalState = true
            shouldRefreshViews = true
            return
        }

        let localNeedsUpload =
            localTimestamp > remoteTimestamp
            || metadata.syncStatus == RecurringCategoryPaceSyncStatus.pending.rawValue
            || metadata.syncStatus == RecurringCategoryPaceSyncStatus.failed.rawValue
            || metadata.lastSyncedAt == nil

        if localNeedsUpload {
            if let uploadedRow = try? await uploadLocalEntry(category: category, metadata: metadata, userID: userID) {
                applyRemoteRow(uploadedRow, to: category, metadata: metadata, in: localContext)
                didMutateLocalState = true
                shouldRefreshViews = true
            } else {
                metadataStore.markFailed(
                    clientRecordID: localEntry.clientRecordID,
                    error: "Upload failed",
                    in: localContext
                )
                didMutateLocalState = true
            }
        } else if metadata.remoteUpdatedAt != remoteRow.updatedAt {
            applyRemoteRow(remoteRow, to: category, metadata: metadata, in: localContext)
            didMutateLocalState = true
            shouldRefreshViews = true
        }
    }

    private struct LocalSyncEntry {
        let category: FinancialCategory
        let metadata: RecurringCategoryPaceSyncMetadata
        let clientRecordID: String
    }

    private func fetchEligibleLocalEntries(in context: NSManagedObjectContext) -> [LocalSyncEntry] {
        let request: NSFetchRequest<FinancialCategory> = FinancialCategory.fetchRequest()
        let categories = (try? context.fetch(request)) ?? []

        return categories.compactMap { category in
            let metadata = metadataStore.metadata(for: category, in: context)
            guard RecurringCategoryPaceSyncMapper.isSyncEligible(category, metadata: metadata) else { return nil }
            return LocalSyncEntry(
                category: category,
                metadata: metadata,
                clientRecordID: metadataStore.clientRecordID(for: category)
            )
        }
    }

    private func uploadLocalEntry(
        category: FinancialCategory,
        metadata: RecurringCategoryPaceSyncMetadata,
        userID: UUID
    ) async throws -> SupabaseRecurringTransactionRow {
        let payload = makePayload(from: category, metadata: metadata, userID: userID)
        return try await remoteStore.upsertRecurringTransaction(payload)
    }

    private func makePayload(
        from category: FinancialCategory,
        metadata: RecurringCategoryPaceSyncMetadata,
        userID: UUID
    ) -> SupabaseRecurringTransactionUpsertPayload {
        let title = RecurringCategoryPaceSyncMapper.resolvedTitle(for: category)
        return SupabaseRecurringTransactionUpsertPayload(
            userID: userID,
            clientRecordID: metadataStore.clientRecordID(for: category),
            title: title,
            amount: Self.decimal(from: category.amount),
            categoryName: title,
            categoryType: category.type,
            frequency: category.frequency,
            startDate: category.createdAt,
            endDate: nil,
            nextDueDate: nil,
            isActive: metadata.deletedAt == nil && category.isActive,
            notes: nil,
            lastProcessedDate: nil,
            currencyCode: RecordCurrencySupport.payloadCurrencyCode(storedCode: category.currencyCode),
            sourceType: RecurringTransactionSourceType.categoryPace,
            categoryKey: RecurringCategoryPaceSyncMapper.categoryKey(for: category),
            createdAt: category.createdAt,
            deletedAt: metadata.deletedAt
        )
    }

    @discardableResult
    private func insertLocalRow(
        from remoteRow: SupabaseRecurringTransactionRow,
        into context: NSManagedObjectContext
    ) -> FinancialCategory? {
        if let seededIdentity = RecurringCategoryPaceSyncMapper.parseSeededClientRecordID(remoteRow.clientRecordID),
           let existing = fetchSeededCategory(
               type: seededIdentity.type,
               categoryKey: seededIdentity.categoryKey,
               frequency: seededIdentity.frequency,
               in: context
           ) {
            let metadata = metadataStore.metadata(for: existing, in: context)
            applyRemoteRow(remoteRow, to: existing, metadata: metadata, in: context)
            return existing
        }

        if let clientUUID = UUID(uuidString: remoteRow.clientRecordID) {
            if let existing = fetchCustomCategory(id: clientUUID, in: context) {
                let metadata = metadataStore.metadata(for: existing, in: context)
                applyRemoteRow(remoteRow, to: existing, metadata: metadata, in: context)
                return existing
            }

            let category = FinancialCategory(context: context)
            category.id = clientUUID
            category.isCustom = true
            category.uniqueID = "custom_\(UUID().uuidString.lowercased())"
            category.entryKind = FinancialCategoryEntryKind.recurring.rawValue
            let metadata = metadataStore.metadata(for: category, in: context)
            applyRemoteRow(remoteRow, to: category, metadata: metadata, in: context)
            return category
        }

        print("☁️ SupabaseRecurringCategoryPaceSyncService: skipped remote row with unsupported client_record_id")
        return nil
    }

    private func applyRemoteRow(
        _ remoteRow: SupabaseRecurringTransactionRow,
        to category: FinancialCategory,
        metadata: RecurringCategoryPaceSyncMetadata,
        in context: NSManagedObjectContext
    ) {
        category.type = remoteRow.categoryType ?? category.type
        category.amount = Self.double(from: remoteRow.amount)
        category.frequency = remoteRow.frequency ?? category.frequency
        category.currencyCode = remoteRow.currencyCode
        category.isActive = remoteRow.deletedAt == nil && remoteRow.isActive
        category.createdAt = remoteRow.createdAt ?? category.createdAt ?? Date()
        category.lastModified = maxDate(category.lastModified, remoteRow.updatedAt ?? remoteRow.createdAt)
        category.entryKind = FinancialCategoryEntryKind.recurring.rawValue
        metadata.deletedAt = remoteRow.deletedAt

        if category.isCustom {
            if let label = remoteRow.categoryName, !label.isEmpty {
                category.customName = label
            }
        } else if let categoryKey = remoteRow.categoryKey, !categoryKey.isEmpty {
            category.uniqueID = categoryKey
        }

        metadataStore.markSynced(
            clientRecordID: remoteRow.clientRecordID,
            remoteUpdatedAt: remoteRow.updatedAt ?? remoteRow.createdAt,
            in: context
        )
    }

    private func applyRemoteTimestamps(
        from remoteRow: SupabaseRecurringTransactionRow,
        metadata: RecurringCategoryPaceSyncMetadata,
        in context: NSManagedObjectContext
    ) {
        metadataStore.markSynced(
            clientRecordID: remoteRow.clientRecordID,
            remoteUpdatedAt: remoteRow.updatedAt ?? remoteRow.createdAt,
            in: context
        )
    }

    private func fetchSeededCategory(
        type: String,
        categoryKey: String,
        frequency: String,
        in context: NSManagedObjectContext
    ) -> FinancialCategory? {
        let request: NSFetchRequest<FinancialCategory> = FinancialCategory.fetchRequest()
        request.predicate = NSPredicate(
            format: "isCustom == NO AND type == %@ AND uniqueID == %@ AND frequency == %@",
            type, categoryKey, frequency
        )
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }

    private func fetchCustomCategory(id: UUID, in context: NSManagedObjectContext) -> FinancialCategory? {
        let request: NSFetchRequest<FinancialCategory> = FinancialCategory.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }

    private func mutationTimestamp(
        for category: FinancialCategory,
        metadata: RecurringCategoryPaceSyncMetadata
    ) -> Date {
        category.lastModified ?? metadata.deletedAt ?? category.createdAt ?? .distantPast
    }

    private func remoteMutationTimestamp(for row: SupabaseRecurringTransactionRow) -> Date {
        row.updatedAt ?? row.deletedAt ?? row.createdAt ?? .distantPast
    }

    private func maxDate(_ lhs: Date?, _ rhs: Date?) -> Date? {
        switch (lhs, rhs) {
        case let (lhs?, rhs?):
            return max(lhs, rhs)
        case let (lhs?, nil):
            return lhs
        case let (nil, rhs?):
            return rhs
        case (nil, nil):
            return nil
        }
    }

    private static func decimal(from value: Double) -> Decimal {
        Decimal(string: NSDecimalNumber(value: value).stringValue) ?? Decimal(value)
    }

    private static func double(from value: Decimal) -> Double {
        NSDecimalNumber(decimal: value).doubleValue
    }
}
