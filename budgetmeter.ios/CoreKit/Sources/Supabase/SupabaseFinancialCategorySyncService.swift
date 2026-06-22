//
//  SupabaseFinancialCategorySyncService.swift
//  BudgetMeter
//
//  Phase 3B custom category + seeded category override Supabase sync.
//

import CoreData
import Foundation
import Supabase

protocol FinancialCategorySyncScheduling: AnyObject {
    func scheduleSync()
    func bootstrapSignedInAccount() async
    func registerLocalCustomCategory(_ category: FinancialCategory)
    func registerLocalSeededOverride(_ category: FinancialCategory)
    func tombstoneLocalCustomCategory(_ category: FinancialCategory)
}

struct SupabaseCustomFinancialCategoryRow: Decodable, Equatable {
    let id: UUID
    let userID: UUID
    let clientRecordID: String
    let type: String
    let name: String
    let iconName: String?
    let colorHex: String?
    let isActive: Bool
    let sortOrder: Int?
    let createdAt: Date?
    let updatedAt: Date?
    let deletedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case clientRecordID = "client_record_id"
        case type
        case name
        case iconName = "icon_name"
        case colorHex = "color_hex"
        case isActive = "is_active"
        case sortOrder = "sort_order"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
    }

    init(
        id: UUID,
        userID: UUID,
        clientRecordID: String,
        type: String,
        name: String,
        iconName: String?,
        colorHex: String?,
        isActive: Bool,
        sortOrder: Int?,
        createdAt: Date?,
        updatedAt: Date?,
        deletedAt: Date?
    ) {
        self.id = id
        self.userID = userID
        self.clientRecordID = clientRecordID
        self.type = type
        self.name = name
        self.iconName = iconName
        self.colorHex = colorHex
        self.isActive = isActive
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        userID = try container.decode(UUID.self, forKey: .userID)
        clientRecordID = try container.decode(String.self, forKey: .clientRecordID)
        type = try container.decode(String.self, forKey: .type)
        name = try container.decode(String.self, forKey: .name)
        iconName = try container.decodeIfPresent(String.self, forKey: .iconName)
        colorHex = try container.decodeIfPresent(String.self, forKey: .colorHex)
        isActive = try container.decode(Bool.self, forKey: .isActive)
        sortOrder = try container.decodeIfPresent(Int.self, forKey: .sortOrder)
        createdAt = try container.decodeTimestampIfPresent(forKey: .createdAt)
        updatedAt = try container.decodeTimestampIfPresent(forKey: .updatedAt)
        deletedAt = try container.decodeTimestampIfPresent(forKey: .deletedAt)
    }
}

struct SupabaseCustomFinancialCategoryUpsertPayload: Encodable {
    let userID: UUID
    let clientRecordID: String
    let type: String
    let name: String
    let iconName: String?
    let colorHex: String?
    let isActive: Bool
    let sortOrder: Int?
    let createdAt: Date?
    let deletedAt: Date?

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case clientRecordID = "client_record_id"
        case type
        case name
        case iconName = "icon_name"
        case colorHex = "color_hex"
        case isActive = "is_active"
        case sortOrder = "sort_order"
        case createdAt = "created_at"
        case deletedAt = "deleted_at"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(userID, forKey: .userID)
        try container.encode(clientRecordID, forKey: .clientRecordID)
        try container.encode(type, forKey: .type)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(iconName, forKey: .iconName)
        try container.encodeIfPresent(colorHex, forKey: .colorHex)
        try container.encode(isActive, forKey: .isActive)
        try container.encodeIfPresent(sortOrder, forKey: .sortOrder)
        try container.encodeTimestampIfPresent(createdAt, forKey: .createdAt)
        try container.encodeTimestampIfPresent(deletedAt, forKey: .deletedAt)
    }
}

struct SupabaseSeededCategoryOverrideRow: Decodable, Equatable {
    let id: UUID
    let userID: UUID
    let categoryKey: String
    let type: String
    let customLabel: String?
    let customIconName: String?
    let customColorHex: String?
    let isHidden: Bool
    let sortOrder: Int?
    let createdAt: Date?
    let updatedAt: Date?
    let deletedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case categoryKey = "category_key"
        case type
        case customLabel = "custom_label"
        case customIconName = "custom_icon_name"
        case customColorHex = "custom_color_hex"
        case isHidden = "is_hidden"
        case sortOrder = "sort_order"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
    }

    init(
        id: UUID,
        userID: UUID,
        categoryKey: String,
        type: String,
        customLabel: String?,
        customIconName: String?,
        customColorHex: String?,
        isHidden: Bool,
        sortOrder: Int?,
        createdAt: Date?,
        updatedAt: Date?,
        deletedAt: Date?
    ) {
        self.id = id
        self.userID = userID
        self.categoryKey = categoryKey
        self.type = type
        self.customLabel = customLabel
        self.customIconName = customIconName
        self.customColorHex = customColorHex
        self.isHidden = isHidden
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        userID = try container.decode(UUID.self, forKey: .userID)
        categoryKey = try container.decode(String.self, forKey: .categoryKey)
        type = try container.decode(String.self, forKey: .type)
        customLabel = try container.decodeIfPresent(String.self, forKey: .customLabel)
        customIconName = try container.decodeIfPresent(String.self, forKey: .customIconName)
        customColorHex = try container.decodeIfPresent(String.self, forKey: .customColorHex)
        isHidden = try container.decode(Bool.self, forKey: .isHidden)
        sortOrder = try container.decodeIfPresent(Int.self, forKey: .sortOrder)
        createdAt = try container.decodeTimestampIfPresent(forKey: .createdAt)
        updatedAt = try container.decodeTimestampIfPresent(forKey: .updatedAt)
        deletedAt = try container.decodeTimestampIfPresent(forKey: .deletedAt)
    }
}

struct SupabaseSeededCategoryOverrideUpsertPayload: Encodable {
    let userID: UUID
    let categoryKey: String
    let type: String
    let customLabel: String?
    let customIconName: String?
    let customColorHex: String?
    let isHidden: Bool
    let sortOrder: Int?
    let createdAt: Date?
    let deletedAt: Date?

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case categoryKey = "category_key"
        case type
        case customLabel = "custom_label"
        case customIconName = "custom_icon_name"
        case customColorHex = "custom_color_hex"
        case isHidden = "is_hidden"
        case sortOrder = "sort_order"
        case createdAt = "created_at"
        case deletedAt = "deleted_at"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(userID, forKey: .userID)
        try container.encode(categoryKey, forKey: .categoryKey)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(customLabel, forKey: .customLabel)
        try container.encodeIfPresent(customIconName, forKey: .customIconName)
        try container.encodeIfPresent(customColorHex, forKey: .customColorHex)
        try container.encode(isHidden, forKey: .isHidden)
        try container.encodeIfPresent(sortOrder, forKey: .sortOrder)
        try container.encodeTimestampIfPresent(createdAt, forKey: .createdAt)
        try container.encodeTimestampIfPresent(deletedAt, forKey: .deletedAt)
    }
}

protocol SupabaseFinancialCategoryRemoteStoreProtocol {
    func currentAuthenticatedUserID() async -> UUID?
    func fetchCustomCategories(userID: UUID) async throws -> [SupabaseCustomFinancialCategoryRow]
    func fetchSeededCategoryOverrides(userID: UUID) async throws -> [SupabaseSeededCategoryOverrideRow]
    func upsertCustomCategory(_ payload: SupabaseCustomFinancialCategoryUpsertPayload) async throws -> SupabaseCustomFinancialCategoryRow
    func upsertSeededCategoryOverride(_ payload: SupabaseSeededCategoryOverrideUpsertPayload) async throws -> SupabaseSeededCategoryOverrideRow
}

enum SupabaseFinancialCategoryRemoteStoreError: Error {
    case notConfigured
}

struct SupabaseFinancialCategoryRemoteStore: SupabaseFinancialCategoryRemoteStoreProtocol {
    private let clientProvider: () -> SupabaseClient?

    init(clientProvider: @escaping () -> SupabaseClient? = { SupabaseClientProvider.makeClient() }) {
        self.clientProvider = clientProvider
    }

    func currentAuthenticatedUserID() async -> UUID? {
        guard let client = clientProvider() else { return nil }
        do {
            return try await client.auth.session.user.id
        } catch {
            return nil
        }
    }

    func fetchCustomCategories(userID: UUID) async throws -> [SupabaseCustomFinancialCategoryRow] {
        let client = try requireClient()
        return try await client
            .from(SupabaseFinancialTableNames.financialCategories)
            .select()
            .eq("user_id", value: userID.uuidString)
            .execute()
            .value
    }

    func fetchSeededCategoryOverrides(userID: UUID) async throws -> [SupabaseSeededCategoryOverrideRow] {
        let client = try requireClient()
        return try await client
            .from(SupabaseFinancialTableNames.seededCategoryOverrides)
            .select()
            .eq("user_id", value: userID.uuidString)
            .execute()
            .value
    }

    func upsertCustomCategory(_ payload: SupabaseCustomFinancialCategoryUpsertPayload) async throws -> SupabaseCustomFinancialCategoryRow {
        let client = try requireClient()
        return try await client
            .from(SupabaseFinancialTableNames.financialCategories)
            .upsert(payload, onConflict: "user_id,client_record_id")
            .select()
            .single()
            .execute()
            .value
    }

    func upsertSeededCategoryOverride(_ payload: SupabaseSeededCategoryOverrideUpsertPayload) async throws -> SupabaseSeededCategoryOverrideRow {
        let client = try requireClient()
        return try await client
            .from(SupabaseFinancialTableNames.seededCategoryOverrides)
            .upsert(payload, onConflict: "user_id,type,category_key")
            .select()
            .single()
            .execute()
            .value
    }

    private func requireClient() throws -> SupabaseClient {
        guard let client = clientProvider() else {
            throw SupabaseFinancialCategoryRemoteStoreError.notConfigured
        }
        return client
    }
}

@MainActor
final class SupabaseFinancialCategorySyncService: FinancialCategorySyncScheduling {
    static let shared = SupabaseFinancialCategorySyncService()

    private let persistenceService: PersistenceService
    private let remoteStore: SupabaseFinancialCategoryRemoteStoreProtocol
    private let metadataStore: FinancialCategorySyncMetadataStore
    private var isSyncInFlight = false
    private var hasQueuedSync = false

    init(
        persistenceService: PersistenceService = .shared,
        remoteStore: SupabaseFinancialCategoryRemoteStoreProtocol = SupabaseFinancialCategoryRemoteStore(),
        metadataStore: FinancialCategorySyncMetadataStore = .shared
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

    func registerLocalCustomCategory(_ category: FinancialCategory) {
        let context = persistenceService.viewContext
        metadataStore.markCustomPending(category, in: context)
        _ = persistenceService.save()
        scheduleSync()
    }

    func registerLocalSeededOverride(_ category: FinancialCategory) {
        let context = persistenceService.viewContext
        metadataStore.markSeededOverridePending(category, in: context)
        _ = persistenceService.save()
        scheduleSync()
    }

    func tombstoneLocalCustomCategory(_ category: FinancialCategory) {
        let context = persistenceService.viewContext
        metadataStore.tombstoneCustomCategory(category, in: context)
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
            let remoteCustomRows = try await remoteStore.fetchCustomCategories(userID: userID)
            let remoteOverrideRows = try await remoteStore.fetchSeededCategoryOverrides(userID: userID)
            let customResult = try await reconcileCustomCategories(
                localContext: persistenceService.viewContext,
                userID: userID,
                remoteRows: remoteCustomRows
            )
            let overrideResult = try await reconcileSeededOverrides(
                localContext: persistenceService.viewContext,
                userID: userID,
                remoteRows: remoteOverrideRows
            )
            finalizeSync(
                didMutateLocalState: customResult.didMutate || overrideResult.didMutate,
                shouldRefreshViews: customResult.shouldRefresh || overrideResult.shouldRefresh
            )
        } catch {
            print("☁️ SupabaseFinancialCategorySyncService: sync skipped (\(error))")
        }
    }

    // MARK: - Custom categories

    private struct CustomLocalSyncEntry {
        let category: FinancialCategory
        let metadata: FinancialCategorySyncMetadata
        let clientRecordID: String
    }

    private struct SyncPassResult {
        let didMutate: Bool
        let shouldRefresh: Bool
    }

    private func reconcileCustomCategories(
        localContext: NSManagedObjectContext,
        userID: UUID,
        remoteRows: [SupabaseCustomFinancialCategoryRow]
    ) async throws -> SyncPassResult {
        let localEntries = fetchEligibleCustomLocalEntries(in: localContext)
        var localByClientRecordID: [String: CustomLocalSyncEntry] = [:]
        for entry in localEntries {
            localByClientRecordID[entry.clientRecordID] = entry
        }

        let remoteByClientRecordID = Dictionary(uniqueKeysWithValues: remoteRows.map { ($0.clientRecordID, $0) })
        var didMutateLocalState = false
        var shouldRefreshViews = false

        for remoteRow in remoteRows {
            if let localEntry = localByClientRecordID[remoteRow.clientRecordID] {
                try await reconcileCustomPair(
                    remoteRow: remoteRow,
                    localEntry: localEntry,
                    userID: userID,
                    localContext: localContext,
                    didMutateLocalState: &didMutateLocalState,
                    shouldRefreshViews: &shouldRefreshViews
                )
            } else if remoteRow.deletedAt == nil {
                if insertLocalCustomRow(from: remoteRow, into: localContext) != nil {
                    didMutateLocalState = true
                    shouldRefreshViews = true
                }
            }
        }

        for entry in localEntries {
            guard remoteByClientRecordID[entry.clientRecordID] == nil else { continue }
            if await uploadMissingCustomLocalEntry(entry, userID: userID, localContext: localContext) {
                didMutateLocalState = true
                shouldRefreshViews = true
            } else {
                metadataStore.markFailed(
                    recordKey: entry.clientRecordID,
                    error: "Custom category upload failed",
                    in: localContext
                )
                didMutateLocalState = true
            }
        }

        return SyncPassResult(didMutate: didMutateLocalState, shouldRefresh: shouldRefreshViews)
    }

    private func reconcileCustomPair(
        remoteRow: SupabaseCustomFinancialCategoryRow,
        localEntry: CustomLocalSyncEntry,
        userID: UUID,
        localContext: NSManagedObjectContext,
        didMutateLocalState: inout Bool,
        shouldRefreshViews: inout Bool
    ) async throws {
        let category = localEntry.category
        let metadata = localEntry.metadata
        let localTimestamp = customMutationTimestamp(for: category, metadata: metadata)
        let remoteTimestamp = remoteMutationTimestamp(updatedAt: remoteRow.updatedAt, deletedAt: remoteRow.deletedAt, createdAt: remoteRow.createdAt)
        let localDeletedAt = metadata.deletedAt
        let remoteDeletedAt = remoteRow.deletedAt

        if let remoteDeletedAt {
            if localDeletedAt == nil || remoteTimestamp >= localTimestamp || metadata.syncStatus == FinancialCategorySyncStatus.synced.rawValue {
                applyRemoteCustomRow(remoteRow, to: category, metadata: metadata, in: localContext)
                metadata.deletedAt = remoteDeletedAt
                category.isActive = false
                didMutateLocalState = true
                shouldRefreshViews = true
            } else if let uploadedRow = try? await uploadCustomLocalEntry(category: category, metadata: metadata, userID: userID) {
                applyRemoteCustomTimestamps(from: uploadedRow, recordKey: localEntry.clientRecordID, in: localContext)
                didMutateLocalState = true
            }
            return
        }

        if localDeletedAt != nil {
            if localTimestamp >= remoteTimestamp {
                if let uploadedRow = try? await uploadCustomLocalEntry(category: category, metadata: metadata, userID: userID) {
                    applyRemoteCustomTimestamps(from: uploadedRow, recordKey: localEntry.clientRecordID, in: localContext)
                    didMutateLocalState = true
                } else {
                    metadataStore.markFailed(recordKey: localEntry.clientRecordID, error: "Tombstone upload failed", in: localContext)
                    didMutateLocalState = true
                }
            } else {
                applyRemoteCustomRow(remoteRow, to: category, metadata: metadata, in: localContext)
                didMutateLocalState = true
                shouldRefreshViews = true
            }
            return
        }

        if remoteTimestamp > localTimestamp {
            applyRemoteCustomRow(remoteRow, to: category, metadata: metadata, in: localContext)
            didMutateLocalState = true
            shouldRefreshViews = true
            return
        }

        let localNeedsUpload =
            localTimestamp > remoteTimestamp
            || metadata.syncStatus == FinancialCategorySyncStatus.pending.rawValue
            || metadata.syncStatus == FinancialCategorySyncStatus.failed.rawValue
            || metadata.lastSyncedAt == nil

        if localNeedsUpload {
            if let uploadedRow = try? await uploadCustomLocalEntry(category: category, metadata: metadata, userID: userID) {
                applyRemoteCustomRow(uploadedRow, to: category, metadata: metadata, in: localContext)
                didMutateLocalState = true
                shouldRefreshViews = true
            } else {
                metadataStore.markFailed(recordKey: localEntry.clientRecordID, error: "Upload failed", in: localContext)
                didMutateLocalState = true
            }
        } else if metadata.remoteUpdatedAt != remoteRow.updatedAt {
            applyRemoteCustomRow(remoteRow, to: category, metadata: metadata, in: localContext)
            didMutateLocalState = true
            shouldRefreshViews = true
        }
    }

    private func uploadMissingCustomLocalEntry(
        _ entry: CustomLocalSyncEntry,
        userID: UUID,
        localContext: NSManagedObjectContext
    ) async -> Bool {
        if entry.metadata.deletedAt != nil, entry.metadata.lastSyncedAt != nil {
            metadataStore.markSynced(
                recordKey: entry.clientRecordID,
                remoteUpdatedAt: entry.metadata.remoteUpdatedAt,
                in: localContext
            )
            return true
        }

        guard let uploadedRow = try? await uploadCustomLocalEntry(
            category: entry.category,
            metadata: entry.metadata,
            userID: userID
        ) else {
            return false
        }

        applyRemoteCustomRow(uploadedRow, to: entry.category, metadata: entry.metadata, in: localContext)
        return true
    }

    private func fetchEligibleCustomLocalEntries(in context: NSManagedObjectContext) -> [CustomLocalSyncEntry] {
        let request: NSFetchRequest<FinancialCategory> = FinancialCategory.fetchRequest()
        let categories = (try? context.fetch(request)) ?? []

        return categories.compactMap { category in
            guard FinancialCategorySyncMapper.isCustomRecurringSyncEligible(category) else { return nil }
            let metadata = metadataStore.metadata(forCustom: category, in: context)
            return CustomLocalSyncEntry(
                category: category,
                metadata: metadata,
                clientRecordID: metadataStore.clientRecordID(for: category)
            )
        }
    }

    private func uploadCustomLocalEntry(
        category: FinancialCategory,
        metadata: FinancialCategorySyncMetadata,
        userID: UUID
    ) async throws -> SupabaseCustomFinancialCategoryRow {
        let payload = makeCustomPayload(from: category, metadata: metadata, userID: userID)
        return try await remoteStore.upsertCustomCategory(payload)
    }

    private func makeCustomPayload(
        from category: FinancialCategory,
        metadata: FinancialCategorySyncMetadata,
        userID: UUID
    ) -> SupabaseCustomFinancialCategoryUpsertPayload {
        SupabaseCustomFinancialCategoryUpsertPayload(
            userID: userID,
            clientRecordID: metadataStore.clientRecordID(for: category),
            type: category.type ?? "expense",
            name: FinancialCategorySyncMapper.resolvedCustomCategoryName(for: category),
            iconName: category.customIconName,
            colorHex: category.customColorHex,
            isActive: metadata.deletedAt == nil && category.isActive,
            sortOrder: nil,
            createdAt: category.createdAt,
            deletedAt: metadata.deletedAt
        )
    }

    @discardableResult
    private func insertLocalCustomRow(
        from remoteRow: SupabaseCustomFinancialCategoryRow,
        into context: NSManagedObjectContext
    ) -> FinancialCategory? {
        guard let clientUUID = UUID(uuidString: remoteRow.clientRecordID) else {
            print("☁️ SupabaseFinancialCategorySyncService: skipped custom row with invalid client_record_id")
            return nil
        }

        if let existing = fetchCustomCategory(clientRecordID: remoteRow.clientRecordID, in: context) {
            let metadata = metadataStore.metadata(forCustom: existing, in: context)
            applyRemoteCustomRow(remoteRow, to: existing, metadata: metadata, in: context)
            return existing
        }

        let category = FinancialCategory(context: context)
        category.id = clientUUID
        let metadata = metadataStore.metadata(forCustom: category, in: context)
        applyRemoteCustomRow(remoteRow, to: category, metadata: metadata, in: context)
        return category
    }

    private func fetchCustomCategory(clientRecordID: String, in context: NSManagedObjectContext) -> FinancialCategory? {
        guard let uuid = UUID(uuidString: clientRecordID) else { return nil }
        let request: NSFetchRequest<FinancialCategory> = FinancialCategory.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", uuid as CVarArg)
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }

    private func applyRemoteCustomRow(
        _ remoteRow: SupabaseCustomFinancialCategoryRow,
        to category: FinancialCategory,
        metadata: FinancialCategorySyncMetadata,
        in context: NSManagedObjectContext
    ) {
        category.id = UUID(uuidString: remoteRow.clientRecordID) ?? category.id
        category.type = remoteRow.type
        category.isCustom = true
        category.customName = remoteRow.name
        category.customIconName = remoteRow.iconName
        category.customColorHex = remoteRow.colorHex
        category.isActive = remoteRow.deletedAt == nil && remoteRow.isActive
        category.createdAt = remoteRow.createdAt ?? category.createdAt ?? Date()
        category.lastModified = maxDate(category.lastModified, remoteRow.updatedAt ?? remoteRow.createdAt)
        metadata.deletedAt = remoteRow.deletedAt

        if category.uniqueID == nil || category.uniqueID?.isEmpty == true {
            category.uniqueID = "custom_\(remoteRow.clientRecordID.lowercased())"
        }

        if !FinancialCategoryWriteSupport.isRecurringDisplayCategory(category) {
            category.entryKind = FinancialCategoryEntryKind.recurring.rawValue
            category.frequency = category.frequency ?? "monthly"
        }

        metadataStore.markSynced(
            recordKey: remoteRow.clientRecordID,
            remoteUpdatedAt: remoteRow.updatedAt ?? remoteRow.createdAt,
            in: context
        )
    }

    private func applyRemoteCustomTimestamps(
        from remoteRow: SupabaseCustomFinancialCategoryRow,
        recordKey: String,
        in context: NSManagedObjectContext
    ) {
        metadataStore.markSynced(
            recordKey: recordKey,
            remoteUpdatedAt: remoteRow.updatedAt ?? remoteRow.createdAt,
            in: context
        )
    }

    // MARK: - Seeded overrides

    private struct SeededOverrideLocalSyncEntry {
        let category: FinancialCategory
        let metadata: FinancialCategorySyncMetadata
        let recordKey: String
        let categoryKey: String
        let type: String
    }

    private func reconcileSeededOverrides(
        localContext: NSManagedObjectContext,
        userID: UUID,
        remoteRows: [SupabaseSeededCategoryOverrideRow]
    ) async throws -> SyncPassResult {
        let localEntries = fetchEligibleSeededOverrideLocalEntries(in: localContext)
        var localByRecordKey: [String: SeededOverrideLocalSyncEntry] = [:]
        for entry in localEntries {
            localByRecordKey[entry.recordKey] = entry
        }

        let remoteByRecordKey = Dictionary(uniqueKeysWithValues: remoteRows.map {
            (
                FinancialCategorySyncMapper.seededOverrideRecordKey(type: $0.type, categoryKey: $0.categoryKey),
                $0
            )
        })

        var didMutateLocalState = false
        var shouldRefreshViews = false

        for remoteRow in remoteRows {
            let recordKey = FinancialCategorySyncMapper.seededOverrideRecordKey(
                type: remoteRow.type,
                categoryKey: remoteRow.categoryKey
            )

            if let localEntry = localByRecordKey[recordKey] {
                try await reconcileSeededOverridePair(
                    remoteRow: remoteRow,
                    localEntry: localEntry,
                    userID: userID,
                    localContext: localContext,
                    didMutateLocalState: &didMutateLocalState,
                    shouldRefreshViews: &shouldRefreshViews
                )
            } else if remoteRow.deletedAt == nil {
                applyRemoteSeededOverrideRow(remoteRow, in: localContext)
                metadataStore.markSynced(
                    recordKey: recordKey,
                    remoteUpdatedAt: remoteRow.updatedAt ?? remoteRow.createdAt,
                    in: localContext
                )
                didMutateLocalState = true
                shouldRefreshViews = true
            }
        }

        for entry in localEntries {
            guard remoteByRecordKey[entry.recordKey] == nil else { continue }
            if await uploadMissingSeededOverrideLocalEntry(entry, userID: userID, localContext: localContext) {
                didMutateLocalState = true
                shouldRefreshViews = true
            } else {
                metadataStore.markFailed(
                    recordKey: entry.recordKey,
                    error: "Seeded override upload failed",
                    in: localContext
                )
                didMutateLocalState = true
            }
        }

        return SyncPassResult(didMutate: didMutateLocalState, shouldRefresh: shouldRefreshViews)
    }

    private func reconcileSeededOverridePair(
        remoteRow: SupabaseSeededCategoryOverrideRow,
        localEntry: SeededOverrideLocalSyncEntry,
        userID: UUID,
        localContext: NSManagedObjectContext,
        didMutateLocalState: inout Bool,
        shouldRefreshViews: inout Bool
    ) async throws {
        let metadata = localEntry.metadata
        let localTimestamp = seededOverrideMutationTimestamp(for: localEntry.category, metadata: metadata)
        let remoteTimestamp = remoteMutationTimestamp(
            updatedAt: remoteRow.updatedAt,
            deletedAt: remoteRow.deletedAt,
            createdAt: remoteRow.createdAt
        )
        let localDeletedAt = metadata.deletedAt
        let remoteDeletedAt = remoteRow.deletedAt

        if let remoteDeletedAt {
            if localDeletedAt == nil || remoteTimestamp >= localTimestamp || metadata.syncStatus == FinancialCategorySyncStatus.synced.rawValue {
                clearLocalSeededOverride(type: localEntry.type, categoryKey: localEntry.categoryKey, in: localContext)
                metadata.deletedAt = remoteDeletedAt
                metadataStore.markSynced(
                    recordKey: localEntry.recordKey,
                    remoteUpdatedAt: remoteRow.updatedAt ?? remoteRow.createdAt,
                    in: localContext
                )
                didMutateLocalState = true
                shouldRefreshViews = true
            } else if let uploadedRow = try? await uploadSeededOverrideLocalEntry(
                category: localEntry.category,
                metadata: metadata,
                userID: userID
            ) {
                metadataStore.markSynced(
                    recordKey: localEntry.recordKey,
                    remoteUpdatedAt: uploadedRow.updatedAt ?? uploadedRow.createdAt,
                    in: localContext
                )
                didMutateLocalState = true
            }
            return
        }

        if localDeletedAt != nil {
            if localTimestamp >= remoteTimestamp {
                if let uploadedRow = try? await uploadSeededOverrideLocalEntry(
                    category: localEntry.category,
                    metadata: metadata,
                    userID: userID
                ) {
                    metadataStore.markSynced(
                        recordKey: localEntry.recordKey,
                        remoteUpdatedAt: uploadedRow.updatedAt ?? uploadedRow.createdAt,
                        in: localContext
                    )
                    didMutateLocalState = true
                } else {
                    metadataStore.markFailed(recordKey: localEntry.recordKey, error: "Override tombstone upload failed", in: localContext)
                    didMutateLocalState = true
                }
            } else {
                applyRemoteSeededOverrideRow(remoteRow, in: localContext)
                metadata.deletedAt = nil
                metadataStore.markSynced(
                    recordKey: localEntry.recordKey,
                    remoteUpdatedAt: remoteRow.updatedAt ?? remoteRow.createdAt,
                    in: localContext
                )
                didMutateLocalState = true
                shouldRefreshViews = true
            }
            return
        }

        if remoteTimestamp > localTimestamp {
            applyRemoteSeededOverrideRow(remoteRow, in: localContext)
            metadataStore.markSynced(
                recordKey: localEntry.recordKey,
                remoteUpdatedAt: remoteRow.updatedAt ?? remoteRow.createdAt,
                in: localContext
            )
            didMutateLocalState = true
            shouldRefreshViews = true
            return
        }

        let localNeedsUpload =
            localTimestamp > remoteTimestamp
            || metadata.syncStatus == FinancialCategorySyncStatus.pending.rawValue
            || metadata.syncStatus == FinancialCategorySyncStatus.failed.rawValue
            || metadata.lastSyncedAt == nil

        if localNeedsUpload {
            if let uploadedRow = try? await uploadSeededOverrideLocalEntry(
                category: localEntry.category,
                metadata: metadata,
                userID: userID
            ) {
                metadataStore.markSynced(
                    recordKey: localEntry.recordKey,
                    remoteUpdatedAt: uploadedRow.updatedAt ?? uploadedRow.createdAt,
                    in: localContext
                )
                didMutateLocalState = true
                shouldRefreshViews = true
            } else {
                metadataStore.markFailed(recordKey: localEntry.recordKey, error: "Override upload failed", in: localContext)
                didMutateLocalState = true
            }
        } else if metadata.remoteUpdatedAt != remoteRow.updatedAt {
            applyRemoteSeededOverrideRow(remoteRow, in: localContext)
            metadataStore.markSynced(
                recordKey: localEntry.recordKey,
                remoteUpdatedAt: remoteRow.updatedAt ?? remoteRow.createdAt,
                in: localContext
            )
            didMutateLocalState = true
            shouldRefreshViews = true
        }
    }

    private func uploadMissingSeededOverrideLocalEntry(
        _ entry: SeededOverrideLocalSyncEntry,
        userID: UUID,
        localContext: NSManagedObjectContext
    ) async -> Bool {
        if entry.metadata.deletedAt != nil, entry.metadata.lastSyncedAt != nil {
            metadataStore.markSynced(
                recordKey: entry.recordKey,
                remoteUpdatedAt: entry.metadata.remoteUpdatedAt,
                in: localContext
            )
            return true
        }

        guard FinancialCategorySyncMapper.isSeededOverrideSyncEligible(entry.category)
            || entry.metadata.syncStatus == FinancialCategorySyncStatus.pending.rawValue
            || entry.metadata.syncStatus == FinancialCategorySyncStatus.failed.rawValue else {
            return false
        }

        guard let uploadedRow = try? await uploadSeededOverrideLocalEntry(
            category: entry.category,
            metadata: entry.metadata,
            userID: userID
        ) else {
            return false
        }

        metadataStore.markSynced(
            recordKey: entry.recordKey,
            remoteUpdatedAt: uploadedRow.updatedAt ?? uploadedRow.createdAt,
            in: localContext
        )
        return true
    }

    private func fetchEligibleSeededOverrideLocalEntries(in context: NSManagedObjectContext) -> [SeededOverrideLocalSyncEntry] {
        let request: NSFetchRequest<FinancialCategory> = FinancialCategory.fetchRequest()
        let categories = (try? context.fetch(request)) ?? []
        var grouped: [String: SeededOverrideLocalSyncEntry] = [:]

        for category in categories {
            guard let categoryKey = FinancialCategorySyncMapper.seededCategoryKey(for: category),
                  let type = category.type else {
                continue
            }

            let recordKey = FinancialCategorySyncMapper.seededOverrideRecordKey(type: type, categoryKey: categoryKey)
            let metadata = metadataStore.metadata(forSeededOverride: type, categoryKey: categoryKey, in: context)
            let timestamp = seededOverrideMutationTimestamp(for: category, metadata: metadata)

            guard FinancialCategorySyncMapper.isSeededOverrideSyncEligible(category)
                || metadata.syncStatus == FinancialCategorySyncStatus.pending.rawValue
                || metadata.syncStatus == FinancialCategorySyncStatus.failed.rawValue
                || metadata.deletedAt != nil else {
                continue
            }

            if let existing = grouped[recordKey] {
                let existingTimestamp = seededOverrideMutationTimestamp(for: existing.category, metadata: existing.metadata)
                if timestamp >= existingTimestamp {
                    grouped[recordKey] = SeededOverrideLocalSyncEntry(
                        category: category,
                        metadata: metadata,
                        recordKey: recordKey,
                        categoryKey: categoryKey,
                        type: type
                    )
                }
            } else {
                grouped[recordKey] = SeededOverrideLocalSyncEntry(
                    category: category,
                    metadata: metadata,
                    recordKey: recordKey,
                    categoryKey: categoryKey,
                    type: type
                )
            }
        }

        return Array(grouped.values)
    }

    private func uploadSeededOverrideLocalEntry(
        category: FinancialCategory,
        metadata: FinancialCategorySyncMetadata,
        userID: UUID
    ) async throws -> SupabaseSeededCategoryOverrideRow {
        let payload = makeSeededOverridePayload(from: category, metadata: metadata, userID: userID)
        return try await remoteStore.upsertSeededCategoryOverride(payload)
    }

    private func makeSeededOverridePayload(
        from category: FinancialCategory,
        metadata: FinancialCategorySyncMetadata,
        userID: UUID
    ) -> SupabaseSeededCategoryOverrideUpsertPayload {
        let categoryKey = FinancialCategorySyncMapper.seededCategoryKey(for: category)
            ?? metadata.categoryKey
            ?? ""
        let type = category.type ?? metadata.categoryType ?? "expense"
        let label = FinancialCategorySyncMapper.trimmedCustomName(for: category)

        return SupabaseSeededCategoryOverrideUpsertPayload(
            userID: userID,
            categoryKey: categoryKey,
            type: type,
            customLabel: label?.isEmpty == false ? label : nil,
            customIconName: category.customIconName,
            customColorHex: category.customColorHex,
            isHidden: category.isActive == false,
            sortOrder: nil,
            createdAt: category.createdAt,
            deletedAt: metadata.deletedAt
        )
    }

    private func applyRemoteSeededOverrideRow(
        _ remoteRow: SupabaseSeededCategoryOverrideRow,
        in context: NSManagedObjectContext
    ) {
        let matchingCategories = fetchSeededCategories(type: remoteRow.type, categoryKey: remoteRow.categoryKey, in: context)
        guard !matchingCategories.isEmpty else { return }

        for category in matchingCategories {
            if let label = remoteRow.customLabel?.trimmingCharacters(in: .whitespacesAndNewlines), !label.isEmpty {
                category.customName = label
            } else {
                category.customName = nil
            }
            category.customIconName = remoteRow.customIconName
            category.customColorHex = remoteRow.customColorHex
            category.isActive = remoteRow.isHidden ? false : true
            category.lastModified = maxDate(category.lastModified, remoteRow.updatedAt ?? remoteRow.createdAt)
        }
    }

    private func clearLocalSeededOverride(type: String, categoryKey: String, in context: NSManagedObjectContext) {
        for category in fetchSeededCategories(type: type, categoryKey: categoryKey, in: context) {
            category.customName = nil
            category.customIconName = nil
            category.customColorHex = nil
            category.isActive = true
            category.lastModified = Date()
        }
    }

    private func fetchSeededCategories(
        type: String,
        categoryKey: String,
        in context: NSManagedObjectContext
    ) -> [FinancialCategory] {
        let request: NSFetchRequest<FinancialCategory> = FinancialCategory.fetchRequest()
        request.predicate = NSPredicate(
            format: "isCustom == NO AND type == %@ AND uniqueID == %@",
            type,
            categoryKey
        )
        return (try? context.fetch(request)) ?? []
    }

    // MARK: - Shared helpers

    private func finalizeSync(didMutateLocalState: Bool, shouldRefreshViews: Bool) {
        if didMutateLocalState {
            _ = persistenceService.save()
        }
        if shouldRefreshViews {
            NotificationCenter.default.post(name: .financialCategoriesDidSync, object: nil)
        }
    }

    private func customMutationTimestamp(for category: FinancialCategory, metadata: FinancialCategorySyncMetadata) -> Date {
        category.lastModified ?? metadata.deletedAt ?? category.createdAt ?? .distantPast
    }

    private func seededOverrideMutationTimestamp(for category: FinancialCategory, metadata: FinancialCategorySyncMetadata) -> Date {
        category.lastModified ?? metadata.deletedAt ?? category.createdAt ?? .distantPast
    }

    private func remoteMutationTimestamp(updatedAt: Date?, deletedAt: Date?, createdAt: Date?) -> Date {
        updatedAt ?? deletedAt ?? createdAt ?? .distantPast
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
}

private enum SupabaseFinancialCategoryDateCoding {
    static let timestampFormatters: [DateFormatter] = {
        let fractional = DateFormatter()
        fractional.locale = Locale(identifier: "en_US_POSIX")
        fractional.calendar = Calendar(identifier: .gregorian)
        fractional.timeZone = TimeZone(secondsFromGMT: 0)
        fractional.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSXXXXX"

        let milliseconds = DateFormatter()
        milliseconds.locale = Locale(identifier: "en_US_POSIX")
        milliseconds.calendar = Calendar(identifier: .gregorian)
        milliseconds.timeZone = TimeZone(secondsFromGMT: 0)
        milliseconds.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"

        return [fractional, milliseconds]
    }()

    static func decodeTimestamp(_ value: String) -> Date? {
        for formatter in timestampFormatters {
            if let date = formatter.date(from: value) {
                return date
            }
        }
        return ISO8601DateFormatter().date(from: value)
    }

    static func encodeTimestamp(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }
}

private extension KeyedDecodingContainer where K == SupabaseCustomFinancialCategoryRow.CodingKeys {
    func decodeTimestampIfPresent(forKey key: K) throws -> Date? {
        guard let value = try decodeIfPresent(String.self, forKey: key), !value.isEmpty else {
            return nil
        }
        return SupabaseFinancialCategoryDateCoding.decodeTimestamp(value)
    }
}

private extension KeyedDecodingContainer where K == SupabaseSeededCategoryOverrideRow.CodingKeys {
    func decodeTimestampIfPresent(forKey key: K) throws -> Date? {
        guard let value = try decodeIfPresent(String.self, forKey: key), !value.isEmpty else {
            return nil
        }
        return SupabaseFinancialCategoryDateCoding.decodeTimestamp(value)
    }
}

private extension KeyedEncodingContainer where K == SupabaseCustomFinancialCategoryUpsertPayload.CodingKeys {
    mutating func encodeTimestampIfPresent(_ value: Date?, forKey key: K) throws {
        guard let value else { return }
        try encode(SupabaseFinancialCategoryDateCoding.encodeTimestamp(value), forKey: key)
    }
}

private extension KeyedEncodingContainer where K == SupabaseSeededCategoryOverrideUpsertPayload.CodingKeys {
    mutating func encodeTimestampIfPresent(_ value: Date?, forKey key: K) throws {
        guard let value else { return }
        try encode(SupabaseFinancialCategoryDateCoding.encodeTimestamp(value), forKey: key)
    }
}
