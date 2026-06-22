//
//  SupabaseRecurringTransactionSyncService.swift
//  BudgetMeter
//
//  Phase 2C recurring transaction Supabase sync.
//

import CoreData
import Foundation
import Supabase

struct SupabaseRecurringTransactionRow: Decodable, Equatable {
    let id: UUID
    let userID: UUID
    let clientRecordID: String
    let title: String
    let amount: Decimal
    let categoryName: String?
    let categoryType: String?
    let frequency: String?
    let startDate: Date?
    let endDate: Date?
    let nextDueDate: Date?
    let isActive: Bool
    let notes: String?
    let lastProcessedDate: Date?
    let createdAt: Date?
    let updatedAt: Date?
    let deletedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case clientRecordID = "client_record_id"
        case title
        case amount
        case categoryName = "category_name"
        case categoryType = "category_type"
        case frequency
        case startDate = "start_date"
        case endDate = "end_date"
        case nextDueDate = "next_due_date"
        case isActive = "is_active"
        case notes
        case lastProcessedDate = "last_processed_date"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
    }

    init(
        id: UUID,
        userID: UUID,
        clientRecordID: String,
        title: String,
        amount: Decimal,
        categoryName: String?,
        categoryType: String?,
        frequency: String?,
        startDate: Date?,
        endDate: Date?,
        nextDueDate: Date?,
        isActive: Bool,
        notes: String?,
        lastProcessedDate: Date?,
        createdAt: Date?,
        updatedAt: Date?,
        deletedAt: Date?
    ) {
        self.id = id
        self.userID = userID
        self.clientRecordID = clientRecordID
        self.title = title
        self.amount = amount
        self.categoryName = categoryName
        self.categoryType = categoryType
        self.frequency = frequency
        self.startDate = startDate
        self.endDate = endDate
        self.nextDueDate = nextDueDate
        self.isActive = isActive
        self.notes = notes
        self.lastProcessedDate = lastProcessedDate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        userID = try container.decode(UUID.self, forKey: .userID)
        clientRecordID = try container.decode(String.self, forKey: .clientRecordID)
        title = try container.decode(String.self, forKey: .title)
        amount = try container.decode(Decimal.self, forKey: .amount)
        categoryName = try container.decodeIfPresent(String.self, forKey: .categoryName)
        categoryType = try container.decodeIfPresent(String.self, forKey: .categoryType)
        frequency = try container.decodeIfPresent(String.self, forKey: .frequency)
        startDate = try container.decodeDateOnlyIfPresent(forKey: .startDate)
        endDate = try container.decodeDateOnlyIfPresent(forKey: .endDate)
        nextDueDate = try container.decodeDateOnlyIfPresent(forKey: .nextDueDate)
        isActive = try container.decode(Bool.self, forKey: .isActive)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        lastProcessedDate = try container.decodeDateOnlyIfPresent(forKey: .lastProcessedDate)
        createdAt = try container.decodeTimestampIfPresent(forKey: .createdAt)
        updatedAt = try container.decodeTimestampIfPresent(forKey: .updatedAt)
        deletedAt = try container.decodeTimestampIfPresent(forKey: .deletedAt)
    }
}

struct SupabaseRecurringTransactionUpsertPayload: Encodable {
    let userID: UUID
    let clientRecordID: String
    let title: String
    let amount: Decimal
    let categoryName: String?
    let categoryType: String?
    let frequency: String?
    let startDate: Date?
    let endDate: Date?
    let nextDueDate: Date?
    let isActive: Bool
    let notes: String?
    let lastProcessedDate: Date?
    let createdAt: Date?
    let deletedAt: Date?

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case clientRecordID = "client_record_id"
        case title
        case amount
        case categoryName = "category_name"
        case categoryType = "category_type"
        case frequency
        case startDate = "start_date"
        case endDate = "end_date"
        case nextDueDate = "next_due_date"
        case isActive = "is_active"
        case notes
        case lastProcessedDate = "last_processed_date"
        case createdAt = "created_at"
        case deletedAt = "deleted_at"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(userID, forKey: .userID)
        try container.encode(clientRecordID, forKey: .clientRecordID)
        try container.encode(title, forKey: .title)
        try container.encode(amount, forKey: .amount)
        try container.encodeIfPresent(categoryName, forKey: .categoryName)
        try container.encodeIfPresent(categoryType, forKey: .categoryType)
        try container.encodeIfPresent(frequency, forKey: .frequency)
        try container.encodeDateOnlyIfPresent(startDate, forKey: .startDate)
        try container.encodeDateOnlyIfPresent(endDate, forKey: .endDate)
        try container.encodeDateOnlyIfPresent(nextDueDate, forKey: .nextDueDate)
        try container.encode(isActive, forKey: .isActive)
        try container.encodeIfPresent(notes, forKey: .notes)
        try container.encodeDateOnlyIfPresent(lastProcessedDate, forKey: .lastProcessedDate)
        try container.encodeTimestampIfPresent(createdAt, forKey: .createdAt)
        try container.encodeTimestampIfPresent(deletedAt, forKey: .deletedAt)
    }
}

protocol SupabaseRecurringTransactionRemoteStoreProtocol {
    func currentAuthenticatedUserID() async -> UUID?
    func fetchRecurringTransactions(userID: UUID) async throws -> [SupabaseRecurringTransactionRow]
    func upsertRecurringTransaction(_ payload: SupabaseRecurringTransactionUpsertPayload) async throws -> SupabaseRecurringTransactionRow
}

enum SupabaseRecurringTransactionRemoteStoreError: Error {
    case notConfigured
}

struct SupabaseRecurringTransactionRemoteStore: SupabaseRecurringTransactionRemoteStoreProtocol {
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

    func fetchRecurringTransactions(userID: UUID) async throws -> [SupabaseRecurringTransactionRow] {
        let client = try requireClient()
        return try await client
            .from(SupabaseFinancialTableNames.recurringTransactions)
            .select()
            .eq("user_id", value: userID.uuidString)
            .execute()
            .value
    }

    func upsertRecurringTransaction(
        _ payload: SupabaseRecurringTransactionUpsertPayload
    ) async throws -> SupabaseRecurringTransactionRow {
        let client = try requireClient()
        return try await client
            .from(SupabaseFinancialTableNames.recurringTransactions)
            .upsert(payload, onConflict: "user_id,client_record_id")
            .select()
            .single()
            .execute()
            .value
    }

    private func requireClient() throws -> SupabaseClient {
        guard let client = clientProvider() else {
            throw SupabaseRecurringTransactionRemoteStoreError.notConfigured
        }
        return client
    }
}

@MainActor
final class SupabaseRecurringTransactionSyncService: FinancialEntitySyncScheduling {
    static let shared = SupabaseRecurringTransactionSyncService()

    private let persistenceService: PersistenceService
    private let remoteStore: SupabaseRecurringTransactionRemoteStoreProtocol
    private var isSyncInFlight = false
    private var hasQueuedSync = false

    init(
        persistenceService: PersistenceService = .shared,
        remoteStore: SupabaseRecurringTransactionRemoteStoreProtocol = SupabaseRecurringTransactionRemoteStore()
    ) {
        self.persistenceService = persistenceService
        self.remoteStore = remoteStore
    }

    func bootstrapSignedInAccount() async {
        await requestSync()
    }

    func scheduleSync() {
        Task { @MainActor in
            await self.requestSync()
        }
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
            try await reconcile(
                localContext: persistenceService.viewContext,
                userID: userID,
                remoteRows: remoteRows
            )
        } catch {
            print("☁️ SupabaseRecurringTransactionSyncService: sync skipped (\(error))")
        }
    }

    private func reconcile(
        localContext: NSManagedObjectContext,
        userID: UUID,
        remoteRows: [SupabaseRecurringTransactionRow]
    ) async throws {
        let localTransactions = fetchAllLocalRecurringTransactions(in: localContext)
        var localByClientRecordID: [String: RecurringTransaction] = [:]
        for transaction in localTransactions {
            let clientRecordID = transaction.ensureFinancialSyncClientRecordID()
            localByClientRecordID[clientRecordID] = transaction
        }

        let remoteByClientRecordID = Dictionary(uniqueKeysWithValues: remoteRows.map { ($0.clientRecordID, $0) })
        var didMutateLocalState = false

        for remoteRow in remoteRows {
            guard let localTransaction = localByClientRecordID[remoteRow.clientRecordID] else {
                if remoteRow.deletedAt == nil, insertLocalRecurringTransaction(from: remoteRow, into: localContext) != nil {
                    didMutateLocalState = true
                }
                continue
            }

            let localTimestamp = localTransaction.financialSyncMutationTimestamp()
            let remoteTimestamp = FinancialEntitySyncSupport.remoteMutationTimestamp(
                updatedAt: remoteRow.updatedAt,
                deletedAt: remoteRow.deletedAt,
                createdAt: remoteRow.createdAt
            )
            let localDeletedAt = localTransaction.deletedAt
            let remoteDeletedAt = remoteRow.deletedAt

            if let remoteDeletedAt {
                if localDeletedAt == nil
                    || remoteTimestamp >= localTimestamp
                    || localTransaction.syncStatus == FinancialEntitySyncStatus.synced.rawValue {
                    applyRemoteRow(remoteRow, to: localTransaction)
                    localTransaction.deletedAt = remoteDeletedAt
                    didMutateLocalState = true
                } else if let uploadedRow = try? await uploadLocalRecurringTransaction(localTransaction, for: userID) {
                    applyRemoteTimestamps(from: uploadedRow, to: localTransaction)
                    didMutateLocalState = true
                }
                continue
            }

            if localDeletedAt != nil {
                if localTimestamp >= remoteTimestamp {
                    if let uploadedRow = try? await uploadLocalRecurringTransaction(localTransaction, for: userID) {
                        applyRemoteTimestamps(from: uploadedRow, to: localTransaction)
                        didMutateLocalState = true
                    }
                } else {
                    applyRemoteRow(remoteRow, to: localTransaction)
                    didMutateLocalState = true
                }
                continue
            }

            if remoteTimestamp > localTimestamp {
                applyRemoteRow(remoteRow, to: localTransaction)
                didMutateLocalState = true
                continue
            }

            let localNeedsUpload =
                localTimestamp > remoteTimestamp
                || localTransaction.syncStatus == FinancialEntitySyncStatus.pending.rawValue
                || localTransaction.syncStatus == FinancialEntitySyncStatus.failed.rawValue
                || localTransaction.lastSyncedAt == nil

            if localNeedsUpload {
                if let uploadedRow = try? await uploadLocalRecurringTransaction(localTransaction, for: userID) {
                    applyRemoteRow(uploadedRow, to: localTransaction)
                    didMutateLocalState = true
                } else {
                    localTransaction.markFinancialSyncFailed("Upload failed")
                    didMutateLocalState = true
                }
            } else if localTransaction.remoteUpdatedAt != remoteRow.updatedAt {
                applyRemoteRow(remoteRow, to: localTransaction)
                didMutateLocalState = true
            }
        }

        for localTransaction in localTransactions {
            let clientRecordID = localTransaction.ensureFinancialSyncClientRecordID()
            guard remoteByClientRecordID[clientRecordID] == nil else { continue }

            if localTransaction.deletedAt != nil {
                if localTransaction.lastSyncedAt != nil {
                    localTransaction.markFinancialSyncSynced(remoteUpdatedAtValue: localTransaction.remoteUpdatedAt)
                    didMutateLocalState = true
                }
                continue
            }

            if let uploadedRow = try? await uploadLocalRecurringTransaction(localTransaction, for: userID) {
                applyRemoteRow(uploadedRow, to: localTransaction)
                didMutateLocalState = true
            } else {
                localTransaction.markFinancialSyncFailed("Initial upload failed")
                didMutateLocalState = true
            }
        }

        if didMutateLocalState {
            _ = persistenceService.save()
        }
    }

    private func uploadLocalRecurringTransaction(
        _ transaction: RecurringTransaction,
        for userID: UUID
    ) async throws -> SupabaseRecurringTransactionRow {
        let payload = makePayload(from: transaction, userID: userID)
        return try await remoteStore.upsertRecurringTransaction(payload)
    }

    private func makePayload(
        from transaction: RecurringTransaction,
        userID: UUID
    ) -> SupabaseRecurringTransactionUpsertPayload {
        SupabaseRecurringTransactionUpsertPayload(
            userID: userID,
            clientRecordID: transaction.ensureFinancialSyncClientRecordID(),
            title: normalizedTitle(transaction.title),
            amount: FinancialEntitySyncSupport.decimal(from: transaction.amount),
            categoryName: transaction.categoryName,
            categoryType: transaction.categoryType,
            frequency: transaction.frequency,
            startDate: transaction.startDate,
            endDate: transaction.endDate,
            nextDueDate: transaction.nextDueDate,
            isActive: transaction.isActive,
            notes: transaction.notes,
            lastProcessedDate: transaction.lastProcessedDate,
            createdAt: transaction.createdAt,
            deletedAt: transaction.deletedAt
        )
    }

    private func insertLocalRecurringTransaction(
        from remoteRow: SupabaseRecurringTransactionRow,
        into context: NSManagedObjectContext
    ) -> RecurringTransaction? {
        guard let clientUUID = UUID(uuidString: remoteRow.clientRecordID) else {
            print("☁️ SupabaseRecurringTransactionSyncService: skipped remote row with invalid client_record_id")
            return nil
        }

        let transaction = RecurringTransaction(context: context)
        transaction.id = clientUUID
        applyRemoteRow(remoteRow, to: transaction)
        return transaction
    }

    private func applyRemoteRow(_ remoteRow: SupabaseRecurringTransactionRow, to transaction: RecurringTransaction) {
        transaction.id = UUID(uuidString: remoteRow.clientRecordID) ?? transaction.id
        transaction.title = remoteRow.title
        transaction.amount = FinancialEntitySyncSupport.double(from: remoteRow.amount)
        transaction.categoryName = remoteRow.categoryName
        transaction.categoryType = remoteRow.categoryType
        transaction.frequency = remoteRow.frequency
        transaction.startDate = remoteRow.startDate
        transaction.endDate = remoteRow.endDate
        transaction.nextDueDate = remoteRow.nextDueDate
        transaction.isActive = remoteRow.isActive
        transaction.notes = remoteRow.notes
        transaction.lastProcessedDate = remoteRow.lastProcessedDate
        transaction.createdAt = remoteRow.createdAt ?? transaction.createdAt ?? Date()
        transaction.lastModified = FinancialEntitySyncSupport.maxDate(
            transaction.lastModified,
            remoteRow.updatedAt ?? remoteRow.createdAt
        )
        transaction.deletedAt = remoteRow.deletedAt
        transaction.markFinancialSyncSynced(remoteUpdatedAtValue: remoteRow.updatedAt ?? remoteRow.createdAt)
    }

    private func applyRemoteTimestamps(
        from remoteRow: SupabaseRecurringTransactionRow,
        to transaction: RecurringTransaction
    ) {
        transaction.markFinancialSyncSynced(remoteUpdatedAtValue: remoteRow.updatedAt ?? remoteRow.createdAt)
    }

    private func fetchAllLocalRecurringTransactions(in context: NSManagedObjectContext) -> [RecurringTransaction] {
        let request: NSFetchRequest<RecurringTransaction> = RecurringTransaction.fetchRequest()
        do {
            return try context.fetch(request)
        } catch {
            print("☁️ SupabaseRecurringTransactionSyncService: failed fetching local recurring transactions (\(error))")
            return []
        }
    }

    private func normalizedTitle(_ value: String?) -> String {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? "Recurring Transaction" : trimmed
    }
}

private enum SupabaseRecurringTransactionDateCoding {
    static let dateOnlyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

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
        wholeSeconds.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXXXX"

        return [fractional, milliseconds, wholeSeconds]
    }()

    static func decodeDateOnly(_ value: String) -> Date? {
        guard let date = dateOnlyFormatter.date(from: value) else { return nil }
        let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return Calendar.current.date(from: components)
    }

    static func encodeDateOnly(_ date: Date) -> String {
        dateOnlyFormatter.string(from: date)
    }

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

private extension KeyedDecodingContainer where K == SupabaseRecurringTransactionRow.CodingKeys {
    func decodeDateOnlyIfPresent(forKey key: K) throws -> Date? {
        guard let value = try decodeIfPresent(String.self, forKey: key), !value.isEmpty else {
            return nil
        }
        return SupabaseRecurringTransactionDateCoding.decodeDateOnly(value)
    }

    func decodeTimestampIfPresent(forKey key: K) throws -> Date? {
        guard let value = try decodeIfPresent(String.self, forKey: key), !value.isEmpty else {
            return nil
        }
        return SupabaseRecurringTransactionDateCoding.decodeTimestamp(value)
    }
}

private extension KeyedEncodingContainer where K == SupabaseRecurringTransactionUpsertPayload.CodingKeys {
    mutating func encodeDateOnlyIfPresent(_ value: Date?, forKey key: K) throws {
        guard let value else { return }
        try encode(SupabaseRecurringTransactionDateCoding.encodeDateOnly(value), forKey: key)
    }

    mutating func encodeTimestampIfPresent(_ value: Date?, forKey key: K) throws {
        guard let value else { return }
        try encode(SupabaseRecurringTransactionDateCoding.encodeTimestamp(value), forKey: key)
    }
}
