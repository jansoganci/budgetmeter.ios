//
//  SupabaseBillSyncService.swift
//  BudgetMeter
//
//  Phase 2C bill Supabase sync.
//

import CoreData
import Foundation
import Supabase

struct SupabaseBillRow: Decodable, Equatable {
    let id: UUID
    let userID: UUID
    let clientRecordID: String
    let name: String
    let amount: Decimal
    let isRecurring: Bool
    let frequency: String?
    let dueDate: Date?
    let originalDueDate: Date?
    let categoryLabel: String?
    let iconName: String?
    let colorHex: String?
    let notes: String?
    let reminderDaysBefore: Int?
    let isPaid: Bool
    let paidDate: Date?
    let paidAmount: Decimal?
    let isAutoPay: Bool
    let currencyCode: String
    let createdAt: Date?
    let updatedAt: Date?
    let deletedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case clientRecordID = "client_record_id"
        case name
        case amount
        case isRecurring = "is_recurring"
        case frequency
        case dueDate = "due_date"
        case originalDueDate = "original_due_date"
        case categoryLabel = "category_label"
        case iconName = "icon_name"
        case colorHex = "color_hex"
        case notes
        case reminderDaysBefore = "reminder_days_before"
        case isPaid = "is_paid"
        case paidDate = "paid_date"
        case paidAmount = "paid_amount"
        case isAutoPay = "is_auto_pay"
        case currencyCode = "currency_code"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
    }

    init(
        id: UUID,
        userID: UUID,
        clientRecordID: String,
        name: String,
        amount: Decimal,
        isRecurring: Bool,
        frequency: String?,
        dueDate: Date?,
        originalDueDate: Date?,
        categoryLabel: String?,
        iconName: String?,
        colorHex: String?,
        notes: String?,
        reminderDaysBefore: Int?,
        isPaid: Bool,
        paidDate: Date?,
        paidAmount: Decimal?,
        isAutoPay: Bool,
        currencyCode: String,
        createdAt: Date?,
        updatedAt: Date?,
        deletedAt: Date?
    ) {
        self.id = id
        self.userID = userID
        self.clientRecordID = clientRecordID
        self.name = name
        self.amount = amount
        self.isRecurring = isRecurring
        self.frequency = frequency
        self.dueDate = dueDate
        self.originalDueDate = originalDueDate
        self.categoryLabel = categoryLabel
        self.iconName = iconName
        self.colorHex = colorHex
        self.notes = notes
        self.reminderDaysBefore = reminderDaysBefore
        self.isPaid = isPaid
        self.paidDate = paidDate
        self.paidAmount = paidAmount
        self.isAutoPay = isAutoPay
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
        name = try container.decode(String.self, forKey: .name)
        amount = try container.decode(Decimal.self, forKey: .amount)
        isRecurring = try container.decode(Bool.self, forKey: .isRecurring)
        frequency = try container.decodeIfPresent(String.self, forKey: .frequency)
        dueDate = try container.decodeDateOnlyIfPresent(forKey: .dueDate)
        originalDueDate = try container.decodeDateOnlyIfPresent(forKey: .originalDueDate)
        categoryLabel = try container.decodeIfPresent(String.self, forKey: .categoryLabel)
        iconName = try container.decodeIfPresent(String.self, forKey: .iconName)
        colorHex = try container.decodeIfPresent(String.self, forKey: .colorHex)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        reminderDaysBefore = try container.decodeIfPresent(Int.self, forKey: .reminderDaysBefore)
        isPaid = try container.decode(Bool.self, forKey: .isPaid)
        paidDate = try container.decodeDateOnlyIfPresent(forKey: .paidDate)
        paidAmount = try container.decodeIfPresent(Decimal.self, forKey: .paidAmount)
        isAutoPay = try container.decode(Bool.self, forKey: .isAutoPay)
        currencyCode = try container.decode(String.self, forKey: .currencyCode)
        createdAt = try container.decodeTimestampIfPresent(forKey: .createdAt)
        updatedAt = try container.decodeTimestampIfPresent(forKey: .updatedAt)
        deletedAt = try container.decodeTimestampIfPresent(forKey: .deletedAt)
    }
}

struct SupabaseBillUpsertPayload: Encodable {
    let userID: UUID
    let clientRecordID: String
    let name: String
    let amount: Decimal
    let isRecurring: Bool
    let frequency: String?
    let dueDate: Date?
    let originalDueDate: Date?
    let categoryLabel: String?
    let iconName: String?
    let colorHex: String?
    let notes: String?
    let reminderDaysBefore: Int?
    let isPaid: Bool
    let paidDate: Date?
    let paidAmount: Decimal?
    let isAutoPay: Bool
    let currencyCode: String
    let createdAt: Date?
    let deletedAt: Date?

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case clientRecordID = "client_record_id"
        case name
        case amount
        case isRecurring = "is_recurring"
        case frequency
        case dueDate = "due_date"
        case originalDueDate = "original_due_date"
        case categoryLabel = "category_label"
        case iconName = "icon_name"
        case colorHex = "color_hex"
        case notes
        case reminderDaysBefore = "reminder_days_before"
        case isPaid = "is_paid"
        case paidDate = "paid_date"
        case paidAmount = "paid_amount"
        case isAutoPay = "is_auto_pay"
        case currencyCode = "currency_code"
        case createdAt = "created_at"
        case deletedAt = "deleted_at"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(userID, forKey: .userID)
        try container.encode(clientRecordID, forKey: .clientRecordID)
        try container.encode(name, forKey: .name)
        try container.encode(amount, forKey: .amount)
        try container.encode(isRecurring, forKey: .isRecurring)
        try container.encodeIfPresent(frequency, forKey: .frequency)
        try container.encodeDateOnlyIfPresent(dueDate, forKey: .dueDate)
        try container.encodeDateOnlyIfPresent(originalDueDate, forKey: .originalDueDate)
        try container.encodeIfPresent(categoryLabel, forKey: .categoryLabel)
        try container.encodeIfPresent(iconName, forKey: .iconName)
        try container.encodeIfPresent(colorHex, forKey: .colorHex)
        try container.encodeIfPresent(notes, forKey: .notes)
        try container.encodeIfPresent(reminderDaysBefore, forKey: .reminderDaysBefore)
        try container.encode(isPaid, forKey: .isPaid)
        try container.encodeDateOnlyIfPresent(paidDate, forKey: .paidDate)
        try container.encodeIfPresent(paidAmount, forKey: .paidAmount)
        try container.encode(isAutoPay, forKey: .isAutoPay)
        try container.encode(currencyCode, forKey: .currencyCode)
        try container.encodeTimestampIfPresent(createdAt, forKey: .createdAt)
        try container.encodeTimestampIfPresent(deletedAt, forKey: .deletedAt)
    }
}

protocol SupabaseBillRemoteStoreProtocol {
    func currentAuthenticatedUserID() async -> UUID?
    func fetchBills(userID: UUID) async throws -> [SupabaseBillRow]
    func upsertBill(_ payload: SupabaseBillUpsertPayload) async throws -> SupabaseBillRow
}

enum SupabaseBillRemoteStoreError: Error {
    case notConfigured
}

struct SupabaseBillRemoteStore: SupabaseBillRemoteStoreProtocol {
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

    func fetchBills(userID: UUID) async throws -> [SupabaseBillRow] {
        let client = try requireClient()
        return try await client
            .from(SupabaseFinancialTableNames.bills)
            .select()
            .eq("user_id", value: userID.uuidString)
            .execute()
            .value
    }

    func upsertBill(_ payload: SupabaseBillUpsertPayload) async throws -> SupabaseBillRow {
        let client = try requireClient()
        return try await client
            .from(SupabaseFinancialTableNames.bills)
            .upsert(payload, onConflict: "user_id,client_record_id")
            .select()
            .single()
            .execute()
            .value
    }

    private func requireClient() throws -> SupabaseClient {
        guard let client = clientProvider() else {
            throw SupabaseBillRemoteStoreError.notConfigured
        }
        return client
    }
}

@MainActor
final class SupabaseBillSyncService: FinancialEntitySyncScheduling {
    static let shared = SupabaseBillSyncService()

    private let persistenceService: PersistenceService
    private let remoteStore: SupabaseBillRemoteStoreProtocol
    private var isSyncInFlight = false
    private var hasQueuedSync = false

    init(
        persistenceService: PersistenceService = .shared,
        remoteStore: SupabaseBillRemoteStoreProtocol = SupabaseBillRemoteStore()
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
            let remoteRows = try await remoteStore.fetchBills(userID: userID)
            try await reconcile(localContext: persistenceService.viewContext, userID: userID, remoteRows: remoteRows)
        } catch {
            print("☁️ SupabaseBillSyncService: sync skipped (\(error))")
        }
    }

    private func reconcile(
        localContext: NSManagedObjectContext,
        userID: UUID,
        remoteRows: [SupabaseBillRow]
    ) async throws {
        let localBills = fetchAllLocalBills(in: localContext)
        var localByClientRecordID: [String: Bill] = [:]
        for bill in localBills {
            let clientRecordID = bill.ensureFinancialSyncClientRecordID()
            localByClientRecordID[clientRecordID] = bill
        }

        let remoteByClientRecordID = Dictionary(uniqueKeysWithValues: remoteRows.map { ($0.clientRecordID, $0) })
        var didMutateLocalState = false
        var shouldRefreshViews = false

        for remoteRow in remoteRows {
            guard let localBill = localByClientRecordID[remoteRow.clientRecordID] else {
                if remoteRow.deletedAt == nil, insertLocalBill(from: remoteRow, into: localContext) != nil {
                    didMutateLocalState = true
                    shouldRefreshViews = true
                }
                continue
            }

            let localTimestamp = localBill.financialSyncMutationTimestamp()
            let remoteTimestamp = FinancialEntitySyncSupport.remoteMutationTimestamp(
                updatedAt: remoteRow.updatedAt,
                deletedAt: remoteRow.deletedAt,
                createdAt: remoteRow.createdAt
            )
            let localDeletedAt = localBill.deletedAt
            let remoteDeletedAt = remoteRow.deletedAt

            if let remoteDeletedAt {
                if localDeletedAt == nil
                    || remoteTimestamp >= localTimestamp
                    || localBill.syncStatus == FinancialEntitySyncStatus.synced.rawValue {
                    applyRemoteRow(remoteRow, to: localBill)
                    localBill.deletedAt = remoteDeletedAt
                    didMutateLocalState = true
                    shouldRefreshViews = true
                } else if let uploadedRow = try? await uploadLocalBill(localBill, for: userID) {
                    applyRemoteTimestamps(from: uploadedRow, to: localBill)
                    didMutateLocalState = true
                }
                continue
            }

            if localDeletedAt != nil {
                if localTimestamp >= remoteTimestamp {
                    if let uploadedRow = try? await uploadLocalBill(localBill, for: userID) {
                        applyRemoteTimestamps(from: uploadedRow, to: localBill)
                        didMutateLocalState = true
                    }
                } else {
                    applyRemoteRow(remoteRow, to: localBill)
                    didMutateLocalState = true
                    shouldRefreshViews = true
                }
                continue
            }

            if remoteTimestamp > localTimestamp {
                applyRemoteRow(remoteRow, to: localBill)
                didMutateLocalState = true
                shouldRefreshViews = true
                continue
            }

            let localNeedsUpload =
                localTimestamp > remoteTimestamp
                || localBill.syncStatus == FinancialEntitySyncStatus.pending.rawValue
                || localBill.syncStatus == FinancialEntitySyncStatus.failed.rawValue
                || localBill.lastSyncedAt == nil

            if localNeedsUpload {
                if let uploadedRow = try? await uploadLocalBill(localBill, for: userID) {
                    applyRemoteRow(uploadedRow, to: localBill)
                    didMutateLocalState = true
                    shouldRefreshViews = true
                } else {
                    localBill.markFinancialSyncFailed("Upload failed")
                    didMutateLocalState = true
                }
            } else if localBill.remoteUpdatedAt != remoteRow.updatedAt {
                applyRemoteRow(remoteRow, to: localBill)
                didMutateLocalState = true
                shouldRefreshViews = true
            }
        }

        for localBill in localBills {
            let clientRecordID = localBill.ensureFinancialSyncClientRecordID()
            guard remoteByClientRecordID[clientRecordID] == nil else { continue }

            if localBill.deletedAt != nil {
                if localBill.lastSyncedAt != nil {
                    localBill.markFinancialSyncSynced(remoteUpdatedAtValue: localBill.remoteUpdatedAt)
                    didMutateLocalState = true
                }
                continue
            }

            if let uploadedRow = try? await uploadLocalBill(localBill, for: userID) {
                applyRemoteRow(uploadedRow, to: localBill)
                didMutateLocalState = true
                shouldRefreshViews = true
            } else {
                localBill.markFinancialSyncFailed("Initial upload failed")
                didMutateLocalState = true
            }
        }

        if didMutateLocalState {
            _ = persistenceService.save()
        }

        if shouldRefreshViews {
            NotificationCenter.default.post(name: BillManager.billUpdatedNotification, object: nil)
        }
    }

    private func uploadLocalBill(_ bill: Bill, for userID: UUID) async throws -> SupabaseBillRow {
        let payload = makePayload(from: bill, userID: userID)
        return try await remoteStore.upsertBill(payload)
    }

    private func makePayload(from bill: Bill, userID: UUID) -> SupabaseBillUpsertPayload {
        SupabaseBillUpsertPayload(
            userID: userID,
            clientRecordID: bill.ensureFinancialSyncClientRecordID(),
            name: normalizedName(bill.name),
            amount: FinancialEntitySyncSupport.decimal(from: bill.amount),
            isRecurring: bill.isRecurring,
            frequency: bill.frequency,
            dueDate: bill.dueDate,
            originalDueDate: bill.originalDueDate,
            categoryLabel: bill.category,
            iconName: bill.iconName,
            colorHex: bill.colorHex,
            notes: bill.notes,
            reminderDaysBefore: Int(bill.reminderDaysBefore),
            isPaid: bill.isPaid,
            paidDate: bill.paidDate,
            paidAmount: bill.paidAmount > 0 ? FinancialEntitySyncSupport.decimal(from: bill.paidAmount) : nil,
            isAutoPay: bill.isAutoPay,
            currencyCode: RecordCurrencySupport.payloadCurrencyCode(storedCode: bill.currencyCode),
            createdAt: bill.createdAt,
            deletedAt: bill.deletedAt
        )
    }

    private func insertLocalBill(from remoteRow: SupabaseBillRow, into context: NSManagedObjectContext) -> Bill? {
        guard let clientUUID = UUID(uuidString: remoteRow.clientRecordID) else {
            print("☁️ SupabaseBillSyncService: skipped remote row with invalid client_record_id")
            return nil
        }

        let bill = Bill(context: context)
        bill.id = clientUUID
        applyRemoteRow(remoteRow, to: bill)
        return bill
    }

    private func applyRemoteRow(_ remoteRow: SupabaseBillRow, to bill: Bill) {
        bill.id = UUID(uuidString: remoteRow.clientRecordID) ?? bill.id
        bill.name = remoteRow.name
        bill.amount = FinancialEntitySyncSupport.double(from: remoteRow.amount)
        bill.isRecurring = remoteRow.isRecurring
        bill.frequency = remoteRow.frequency
        bill.dueDate = remoteRow.dueDate
        bill.originalDueDate = remoteRow.originalDueDate
        bill.category = remoteRow.categoryLabel
        bill.iconName = remoteRow.iconName
        bill.colorHex = remoteRow.colorHex
        bill.notes = remoteRow.notes
        bill.reminderDaysBefore = Int16(clamping: remoteRow.reminderDaysBefore ?? 3)
        bill.isPaid = remoteRow.isPaid
        bill.paidDate = remoteRow.paidDate
        bill.paidAmount = FinancialEntitySyncSupport.double(from: remoteRow.paidAmount ?? 0)
        bill.isAutoPay = remoteRow.isAutoPay
        bill.currencyCode = remoteRow.currencyCode
        bill.createdAt = remoteRow.createdAt ?? bill.createdAt ?? Date()
        bill.lastModified = FinancialEntitySyncSupport.maxDate(
            bill.lastModified,
            remoteRow.updatedAt ?? remoteRow.createdAt
        )
        bill.deletedAt = remoteRow.deletedAt
        bill.markFinancialSyncSynced(remoteUpdatedAtValue: remoteRow.updatedAt ?? remoteRow.createdAt)
    }

    private func applyRemoteTimestamps(from remoteRow: SupabaseBillRow, to bill: Bill) {
        bill.markFinancialSyncSynced(remoteUpdatedAtValue: remoteRow.updatedAt ?? remoteRow.createdAt)
    }

    private func fetchAllLocalBills(in context: NSManagedObjectContext) -> [Bill] {
        let request: NSFetchRequest<Bill> = Bill.fetchRequest()
        do {
            return try context.fetch(request)
        } catch {
            print("☁️ SupabaseBillSyncService: failed fetching local bills (\(error))")
            return []
        }
    }

    private func normalizedName(_ value: String?) -> String {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? "Bill" : trimmed
    }
}

private enum SupabaseBillDateCoding {
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

private extension KeyedDecodingContainer where K == SupabaseBillRow.CodingKeys {
    func decodeDateOnlyIfPresent(forKey key: K) throws -> Date? {
        guard let value = try decodeIfPresent(String.self, forKey: key), !value.isEmpty else {
            return nil
        }
        return SupabaseBillDateCoding.decodeDateOnly(value)
    }

    func decodeTimestampIfPresent(forKey key: K) throws -> Date? {
        guard let value = try decodeIfPresent(String.self, forKey: key), !value.isEmpty else {
            return nil
        }
        return SupabaseBillDateCoding.decodeTimestamp(value)
    }
}

private extension KeyedEncodingContainer where K == SupabaseBillUpsertPayload.CodingKeys {
    mutating func encodeDateOnlyIfPresent(_ value: Date?, forKey key: K) throws {
        guard let value else { return }
        try encode(SupabaseBillDateCoding.encodeDateOnly(value), forKey: key)
    }

    mutating func encodeTimestampIfPresent(_ value: Date?, forKey key: K) throws {
        guard let value else { return }
        try encode(SupabaseBillDateCoding.encodeTimestamp(value), forKey: key)
    }
}
