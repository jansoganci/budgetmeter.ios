//
//  SupabaseOneTimeTransactionSyncService.swift
//  BudgetMeter
//
//  Phase 3A one-time income/expense Supabase sync.
//

import CoreData
import Foundation
import Supabase

extension SupabaseFinancialTableNames {
    static let oneTimeTransactions = "one_time_transactions"
}

protocol OneTimeTransactionSyncScheduling: AnyObject {
    func scheduleSync()
    func bootstrapSignedInAccount() async
    func registerLocalOneTimeRow(_ category: FinancialCategory)
    func tombstoneLocalOneTimeRow(_ category: FinancialCategory)
}

struct SupabaseOneTimeTransactionRow: Decodable, Equatable {
    let id: UUID
    let userID: UUID
    let clientRecordID: String
    let type: String
    let amount: Decimal
    let occurrenceDate: Date
    let categoryKey: String?
    let categoryLabel: String
    let customIconName: String?
    let customColorHex: String?
    let sourceType: String?
    let sourceClientRecordID: String?
    let notes: String?
    let currencyCode: String
    let createdAt: Date?
    let updatedAt: Date?
    let deletedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case clientRecordID = "client_record_id"
        case type
        case amount
        case occurrenceDate = "occurrence_date"
        case categoryKey = "category_key"
        case categoryLabel = "category_label"
        case customIconName = "custom_icon_name"
        case customColorHex = "custom_color_hex"
        case sourceType = "source_type"
        case sourceClientRecordID = "source_client_record_id"
        case notes
        case currencyCode = "currency_code"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
    }

    init(
        id: UUID,
        userID: UUID,
        clientRecordID: String,
        type: String,
        amount: Decimal,
        occurrenceDate: Date,
        categoryKey: String?,
        categoryLabel: String,
        customIconName: String?,
        customColorHex: String?,
        sourceType: String?,
        sourceClientRecordID: String?,
        notes: String?,
        currencyCode: String,
        createdAt: Date?,
        updatedAt: Date?,
        deletedAt: Date?
    ) {
        self.id = id
        self.userID = userID
        self.clientRecordID = clientRecordID
        self.type = type
        self.amount = amount
        self.occurrenceDate = occurrenceDate
        self.categoryKey = categoryKey
        self.categoryLabel = categoryLabel
        self.customIconName = customIconName
        self.customColorHex = customColorHex
        self.sourceType = sourceType
        self.sourceClientRecordID = sourceClientRecordID
        self.notes = notes
        self.currencyCode = currencyCode
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
        amount = try container.decode(Decimal.self, forKey: .amount)
        occurrenceDate = try container.decodeRequiredTimestamp(forKey: .occurrenceDate)
        categoryKey = try container.decodeIfPresent(String.self, forKey: .categoryKey)
        categoryLabel = try container.decode(String.self, forKey: .categoryLabel)
        customIconName = try container.decodeIfPresent(String.self, forKey: .customIconName)
        customColorHex = try container.decodeIfPresent(String.self, forKey: .customColorHex)
        sourceType = try container.decodeIfPresent(String.self, forKey: .sourceType)
        sourceClientRecordID = try container.decodeIfPresent(String.self, forKey: .sourceClientRecordID)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        currencyCode = try container.decode(String.self, forKey: .currencyCode)
        createdAt = try container.decodeTimestampIfPresent(forKey: .createdAt)
        updatedAt = try container.decodeTimestampIfPresent(forKey: .updatedAt)
        deletedAt = try container.decodeTimestampIfPresent(forKey: .deletedAt)
    }
}

struct SupabaseOneTimeTransactionUpsertPayload: Encodable {
    let userID: UUID
    let clientRecordID: String
    let type: String
    let amount: Decimal
    let occurrenceDate: Date
    let categoryKey: String?
    let categoryLabel: String
    let customIconName: String?
    let customColorHex: String?
    let sourceType: String?
    let sourceClientRecordID: String?
    let notes: String?
    let currencyCode: String
    let createdAt: Date?
    let deletedAt: Date?

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case clientRecordID = "client_record_id"
        case type
        case amount
        case occurrenceDate = "occurrence_date"
        case categoryKey = "category_key"
        case categoryLabel = "category_label"
        case customIconName = "custom_icon_name"
        case customColorHex = "custom_color_hex"
        case sourceType = "source_type"
        case sourceClientRecordID = "source_client_record_id"
        case notes
        case currencyCode = "currency_code"
        case createdAt = "created_at"
        case deletedAt = "deleted_at"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(userID, forKey: .userID)
        try container.encode(clientRecordID, forKey: .clientRecordID)
        try container.encode(type, forKey: .type)
        try container.encode(amount, forKey: .amount)
        try container.encodeTimestamp(occurrenceDate, forKey: .occurrenceDate)
        try container.encodeIfPresent(categoryKey, forKey: .categoryKey)
        try container.encode(categoryLabel, forKey: .categoryLabel)
        try container.encodeIfPresent(customIconName, forKey: .customIconName)
        try container.encodeIfPresent(customColorHex, forKey: .customColorHex)
        try container.encodeIfPresent(sourceType, forKey: .sourceType)
        try container.encodeIfPresent(sourceClientRecordID, forKey: .sourceClientRecordID)
        try container.encodeIfPresent(notes, forKey: .notes)
        try container.encode(currencyCode, forKey: .currencyCode)
        try container.encodeTimestampIfPresent(createdAt, forKey: .createdAt)
        try container.encodeTimestampIfPresent(deletedAt, forKey: .deletedAt)
    }
}

protocol SupabaseOneTimeTransactionRemoteStoreProtocol {
    func currentAuthenticatedUserID() async -> UUID?
    func fetchOneTimeTransactions(userID: UUID) async throws -> [SupabaseOneTimeTransactionRow]
    func upsertOneTimeTransaction(_ payload: SupabaseOneTimeTransactionUpsertPayload) async throws -> SupabaseOneTimeTransactionRow
}

enum SupabaseOneTimeTransactionRemoteStoreError: Error {
    case notConfigured
}

struct SupabaseOneTimeTransactionRemoteStore: SupabaseOneTimeTransactionRemoteStoreProtocol {
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

    func fetchOneTimeTransactions(userID: UUID) async throws -> [SupabaseOneTimeTransactionRow] {
        let client = try requireClient()
        return try await client
            .from(SupabaseFinancialTableNames.oneTimeTransactions)
            .select()
            .eq("user_id", value: userID.uuidString)
            .execute()
            .value
    }

    func upsertOneTimeTransaction(_ payload: SupabaseOneTimeTransactionUpsertPayload) async throws -> SupabaseOneTimeTransactionRow {
        let client = try requireClient()
        return try await client
            .from(SupabaseFinancialTableNames.oneTimeTransactions)
            .upsert(payload, onConflict: "user_id,client_record_id")
            .select()
            .single()
            .execute()
            .value
    }

    private func requireClient() throws -> SupabaseClient {
        guard let client = clientProvider() else {
            throw SupabaseOneTimeTransactionRemoteStoreError.notConfigured
        }
        return client
    }
}

@MainActor
final class SupabaseOneTimeTransactionSyncService: OneTimeTransactionSyncScheduling {
    static let shared = SupabaseOneTimeTransactionSyncService()

    private let persistenceService: PersistenceService
    private let remoteStore: SupabaseOneTimeTransactionRemoteStoreProtocol
    private let metadataStore: OneTimeTransactionSyncMetadataStore
    private var isSyncInFlight = false
    private var hasQueuedSync = false

    init(
        persistenceService: PersistenceService = .shared,
        remoteStore: SupabaseOneTimeTransactionRemoteStoreProtocol = SupabaseOneTimeTransactionRemoteStore(),
        metadataStore: OneTimeTransactionSyncMetadataStore = .shared
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

    func registerLocalOneTimeRow(_ category: FinancialCategory) {
        let context = persistenceService.viewContext
        metadataStore.markPending(category, in: context)
        _ = persistenceService.save()
        scheduleSync()
    }

    func tombstoneLocalOneTimeRow(_ category: FinancialCategory) {
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
            let remoteRows = try await remoteStore.fetchOneTimeTransactions(userID: userID)
            try await reconcile(
                localContext: persistenceService.viewContext,
                userID: userID,
                remoteRows: remoteRows
            )
        } catch {
            print("☁️ SupabaseOneTimeTransactionSyncService: sync skipped (\(error))")
        }
    }

    private func reconcile(
        localContext: NSManagedObjectContext,
        userID: UUID,
        remoteRows: [SupabaseOneTimeTransactionRow]
    ) async throws {
        let localEntries = fetchEligibleLocalEntries(in: localContext)
        var localByClientRecordID: [String: (FinancialCategory, OneTimeTransactionSyncMetadata)] = [:]
        for entry in localEntries {
            localByClientRecordID[entry.clientRecordID] = (entry.category, entry.metadata)
        }

        let remoteByClientRecordID = Dictionary(uniqueKeysWithValues: remoteRows.map { ($0.clientRecordID, $0) })
        var didMutateLocalState = false
        var shouldRefreshViews = false

        for remoteRow in remoteRows {
            if let localEntry = localByClientRecordID[remoteRow.clientRecordID] {
                let (category, metadata) = localEntry
                let localTimestamp = mutationTimestamp(for: category, metadata: metadata)
                let remoteTimestamp = remoteMutationTimestamp(for: remoteRow)
                let localDeletedAt = metadata.deletedAt
                let remoteDeletedAt = remoteRow.deletedAt

                if let remoteDeletedAt {
                    if localDeletedAt == nil || remoteTimestamp >= localTimestamp || metadata.syncStatus == OneTimeTransactionSyncStatus.synced.rawValue {
                        applyRemoteRow(remoteRow, to: category, metadata: metadata, in: localContext)
                        metadata.deletedAt = remoteDeletedAt
                        category.isActive = false
                        didMutateLocalState = true
                        shouldRefreshViews = true
                    } else if let uploadedRow = try? await uploadLocalEntry(category: category, metadata: metadata, userID: userID) {
                        applyRemoteTimestamps(from: uploadedRow, metadata: metadata, in: localContext)
                        didMutateLocalState = true
                    }
                    continue
                }

                if localDeletedAt != nil {
                    if localTimestamp >= remoteTimestamp {
                        if let uploadedRow = try? await uploadLocalEntry(category: category, metadata: metadata, userID: userID) {
                            applyRemoteTimestamps(from: uploadedRow, metadata: metadata, in: localContext)
                            didMutateLocalState = true
                        } else {
                            metadataStore.markFailed(clientRecordID: remoteRow.clientRecordID, error: "Upload failed", in: localContext)
                            didMutateLocalState = true
                        }
                    } else {
                        applyRemoteRow(remoteRow, to: category, metadata: metadata, in: localContext)
                        didMutateLocalState = true
                        shouldRefreshViews = true
                    }
                    continue
                }

                if remoteTimestamp > localTimestamp {
                    applyRemoteRow(remoteRow, to: category, metadata: metadata, in: localContext)
                    didMutateLocalState = true
                    shouldRefreshViews = true
                    continue
                }

                let localNeedsUpload =
                    localTimestamp > remoteTimestamp
                    || metadata.syncStatus == OneTimeTransactionSyncStatus.pending.rawValue
                    || metadata.syncStatus == OneTimeTransactionSyncStatus.failed.rawValue
                    || metadata.lastSyncedAt == nil

                if localNeedsUpload {
                    if let uploadedRow = try? await uploadLocalEntry(category: category, metadata: metadata, userID: userID) {
                        applyRemoteRow(uploadedRow, to: category, metadata: metadata, in: localContext)
                        didMutateLocalState = true
                        shouldRefreshViews = true
                    } else {
                        metadataStore.markFailed(clientRecordID: remoteRow.clientRecordID, error: "Upload failed", in: localContext)
                        didMutateLocalState = true
                    }
                } else if metadata.remoteUpdatedAt != remoteRow.updatedAt {
                    applyRemoteRow(remoteRow, to: category, metadata: metadata, in: localContext)
                    didMutateLocalState = true
                    shouldRefreshViews = true
                }
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
                    metadataStore.markFailed(clientRecordID: entry.clientRecordID, error: "Tombstone upload failed", in: localContext)
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
                metadataStore.markFailed(clientRecordID: entry.clientRecordID, error: "Initial upload failed", in: localContext)
                didMutateLocalState = true
            }
        }

        if didMutateLocalState {
            _ = persistenceService.save()
        }

        if shouldRefreshViews {
            NotificationCenter.default.post(name: .oneTimeTransactionsDidSync, object: nil)
        }
    }

    private struct LocalSyncEntry {
        let category: FinancialCategory
        let metadata: OneTimeTransactionSyncMetadata
        let clientRecordID: String
    }

    private func fetchEligibleLocalEntries(in context: NSManagedObjectContext) -> [LocalSyncEntry] {
        let request: NSFetchRequest<FinancialCategory> = FinancialCategory.fetchRequest()
        let categories = (try? context.fetch(request)) ?? []

        return categories.compactMap { category in
            guard OneTimeTransactionSyncMapper.isSyncEligible(category) else { return nil }
            let metadata = metadataStore.metadata(for: category, in: context)
            return LocalSyncEntry(
                category: category,
                metadata: metadata,
                clientRecordID: metadataStore.clientRecordID(for: category)
            )
        }
    }

    private func uploadLocalEntry(
        category: FinancialCategory,
        metadata: OneTimeTransactionSyncMetadata,
        userID: UUID
    ) async throws -> SupabaseOneTimeTransactionRow {
        let payload = makePayload(from: category, metadata: metadata, userID: userID)
        return try await remoteStore.upsertOneTimeTransaction(payload)
    }

    private func makePayload(
        from category: FinancialCategory,
        metadata: OneTimeTransactionSyncMetadata,
        userID: UUID
    ) -> SupabaseOneTimeTransactionUpsertPayload {
        SupabaseOneTimeTransactionUpsertPayload(
            userID: userID,
            clientRecordID: metadataStore.clientRecordID(for: category),
            type: category.type ?? "expense",
            amount: Self.decimal(from: category.amount),
            occurrenceDate: category.occurrenceDate ?? Date(),
            categoryKey: OneTimeTransactionSyncMapper.categoryKey(for: category),
            categoryLabel: OneTimeTransactionSyncMapper.resolvedCategoryLabel(for: category),
            customIconName: category.customIconName,
            customColorHex: category.customColorHex,
            sourceType: category.sourceType,
            sourceClientRecordID: OneTimeTransactionSyncMapper.normalizedSourceClientRecordID(from: category.sourceID),
            notes: nil,
            currencyCode: RecordCurrencySupport.payloadCurrencyCode(storedCode: category.currencyCode),
            createdAt: category.createdAt,
            deletedAt: metadata.deletedAt
        )
    }

    @discardableResult
    private func insertLocalRow(
        from remoteRow: SupabaseOneTimeTransactionRow,
        into context: NSManagedObjectContext
    ) -> FinancialCategory? {
        guard let clientUUID = UUID(uuidString: remoteRow.clientRecordID) else {
            print("☁️ SupabaseOneTimeTransactionSyncService: skipped remote row with invalid client_record_id")
            return nil
        }

        let category = FinancialCategory(context: context)
        category.id = clientUUID
        let metadata = metadataStore.metadata(forClientRecordID: remoteRow.clientRecordID, in: context)
        applyRemoteRow(remoteRow, to: category, metadata: metadata, in: context)
        return category
    }

    private func applyRemoteRow(
        _ remoteRow: SupabaseOneTimeTransactionRow,
        to category: FinancialCategory,
        metadata: OneTimeTransactionSyncMetadata,
        in context: NSManagedObjectContext
    ) {
        category.id = UUID(uuidString: remoteRow.clientRecordID) ?? category.id
        category.type = remoteRow.type
        category.amount = Self.double(from: remoteRow.amount)
        category.occurrenceDate = remoteRow.occurrenceDate
        category.customName = remoteRow.categoryLabel
        category.customIconName = remoteRow.customIconName
        category.customColorHex = remoteRow.customColorHex
        category.sourceType = remoteRow.sourceType
        category.sourceID = remoteRow.sourceClientRecordID
        category.currencyCode = remoteRow.currencyCode
        category.isCustom = true
        category.isActive = remoteRow.deletedAt == nil
        category.createdAt = remoteRow.createdAt ?? category.createdAt ?? Date()
        category.lastModified = maxDate(category.lastModified, remoteRow.updatedAt ?? remoteRow.createdAt)
        metadata.deletedAt = remoteRow.deletedAt

        if let categoryKey = remoteRow.categoryKey, !categoryKey.isEmpty {
            category.uniqueID = categoryKey
        } else if category.uniqueID == nil || category.uniqueID?.isEmpty == true {
            category.uniqueID = "custom_\(UUID().uuidString.lowercased())"
        }

        category.entryKind = FinancialCategoryEntryKind.oneTime.rawValue
        category.frequency = "once"
        category.occurrenceDate = remoteRow.occurrenceDate
        category.lastModified = maxDate(category.lastModified, remoteRow.updatedAt ?? remoteRow.createdAt)

        metadataStore.markSynced(
            clientRecordID: remoteRow.clientRecordID,
            remoteUpdatedAt: remoteRow.updatedAt ?? remoteRow.createdAt,
            in: context
        )
    }

    private func applyRemoteTimestamps(
        from remoteRow: SupabaseOneTimeTransactionRow,
        metadata: OneTimeTransactionSyncMetadata,
        in context: NSManagedObjectContext
    ) {
        metadataStore.markSynced(
            clientRecordID: remoteRow.clientRecordID,
            remoteUpdatedAt: remoteRow.updatedAt ?? remoteRow.createdAt,
            in: context
        )
    }

    private func mutationTimestamp(for category: FinancialCategory, metadata: OneTimeTransactionSyncMetadata) -> Date {
        category.lastModified ?? metadata.deletedAt ?? category.createdAt ?? .distantPast
    }

    private func remoteMutationTimestamp(for row: SupabaseOneTimeTransactionRow) -> Date {
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

private enum SupabaseOneTimeTransactionDateCoding {
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

        let wholeSeconds = DateFormatter()
        wholeSeconds.locale = Locale(identifier: "en_US_POSIX")
        wholeSeconds.calendar = Calendar(identifier: .gregorian)
        wholeSeconds.timeZone = TimeZone(secondsFromGMT: 0)
        wholeSeconds.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"

        return [fractional, milliseconds, wholeSeconds]
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

private extension KeyedDecodingContainer where K == SupabaseOneTimeTransactionRow.CodingKeys {
    func decodeRequiredTimestamp(forKey key: K) throws -> Date {
        let value = try decode(String.self, forKey: key)
        guard let date = SupabaseOneTimeTransactionDateCoding.decodeTimestamp(value) else {
            throw DecodingError.dataCorruptedError(forKey: key, in: self, debugDescription: "Invalid timestamp")
        }
        return date
    }

    func decodeTimestampIfPresent(forKey key: K) throws -> Date? {
        guard let value = try decodeIfPresent(String.self, forKey: key), !value.isEmpty else {
            return nil
        }
        return SupabaseOneTimeTransactionDateCoding.decodeTimestamp(value)
    }
}

private extension KeyedEncodingContainer where K == SupabaseOneTimeTransactionUpsertPayload.CodingKeys {
    mutating func encodeTimestamp(_ value: Date, forKey key: K) throws {
        try encode(SupabaseOneTimeTransactionDateCoding.encodeTimestamp(value), forKey: key)
    }

    mutating func encodeTimestampIfPresent(_ value: Date?, forKey key: K) throws {
        guard let value else { return }
        try encodeTimestamp(value, forKey: key)
    }
}
