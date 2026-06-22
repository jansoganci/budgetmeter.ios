//
//  SupabaseBillPaymentSyncService.swift
//  BudgetMeter
//
//  Phase 2C bill payment Supabase sync.
//

import CoreData
import Foundation
import Supabase

struct SupabaseBillPaymentRow: Decodable, Equatable {
    let id: UUID
    let userID: UUID
    let clientRecordID: String
    let billID: UUID
    let billClientRecordID: String?
    let dueDate: Date?
    let paidDate: Date?
    let expectedAmount: Decimal
    let actualAmount: Decimal
    let notes: String?
    let wasLate: Bool
    let daysLate: Int?
    let currencyCode: String
    let createdAt: Date?
    let updatedAt: Date?
    let deletedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case clientRecordID = "client_record_id"
        case billID = "bill_id"
        case billClientRecordID = "bill_client_record_id"
        case dueDate = "due_date"
        case paidDate = "paid_date"
        case expectedAmount = "expected_amount"
        case actualAmount = "actual_amount"
        case notes
        case wasLate = "was_late"
        case daysLate = "days_late"
        case currencyCode = "currency_code"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
    }

    init(
        id: UUID,
        userID: UUID,
        clientRecordID: String,
        billID: UUID,
        billClientRecordID: String?,
        dueDate: Date?,
        paidDate: Date?,
        expectedAmount: Decimal,
        actualAmount: Decimal,
        notes: String?,
        wasLate: Bool,
        daysLate: Int?,
        currencyCode: String,
        createdAt: Date?,
        updatedAt: Date?,
        deletedAt: Date?
    ) {
        self.id = id
        self.userID = userID
        self.clientRecordID = clientRecordID
        self.billID = billID
        self.billClientRecordID = billClientRecordID
        self.dueDate = dueDate
        self.paidDate = paidDate
        self.expectedAmount = expectedAmount
        self.actualAmount = actualAmount
        self.notes = notes
        self.wasLate = wasLate
        self.daysLate = daysLate
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
        billID = try container.decode(UUID.self, forKey: .billID)
        billClientRecordID = try container.decodeIfPresent(String.self, forKey: .billClientRecordID)
        dueDate = try container.decodeDateOnlyIfPresent(forKey: .dueDate)
        paidDate = try container.decodeDateOnlyIfPresent(forKey: .paidDate)
        expectedAmount = try container.decode(Decimal.self, forKey: .expectedAmount)
        actualAmount = try container.decode(Decimal.self, forKey: .actualAmount)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        wasLate = try container.decode(Bool.self, forKey: .wasLate)
        daysLate = try container.decodeIfPresent(Int.self, forKey: .daysLate)
        currencyCode = try container.decode(String.self, forKey: .currencyCode)
        createdAt = try container.decodeTimestampIfPresent(forKey: .createdAt)
        updatedAt = try container.decodeTimestampIfPresent(forKey: .updatedAt)
        deletedAt = try container.decodeTimestampIfPresent(forKey: .deletedAt)
    }
}

struct SupabaseBillPaymentUpsertPayload: Encodable {
    let userID: UUID
    let clientRecordID: String
    let billID: UUID
    let billClientRecordID: String
    let dueDate: Date?
    let paidDate: Date?
    let expectedAmount: Decimal
    let actualAmount: Decimal
    let notes: String?
    let wasLate: Bool
    let daysLate: Int?
    let currencyCode: String
    let createdAt: Date?
    let deletedAt: Date?

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case clientRecordID = "client_record_id"
        case billID = "bill_id"
        case billClientRecordID = "bill_client_record_id"
        case dueDate = "due_date"
        case paidDate = "paid_date"
        case expectedAmount = "expected_amount"
        case actualAmount = "actual_amount"
        case notes
        case wasLate = "was_late"
        case daysLate = "days_late"
        case currencyCode = "currency_code"
        case createdAt = "created_at"
        case deletedAt = "deleted_at"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(userID, forKey: .userID)
        try container.encode(clientRecordID, forKey: .clientRecordID)
        try container.encode(billID, forKey: .billID)
        try container.encode(billClientRecordID, forKey: .billClientRecordID)
        try container.encodeDateOnlyIfPresent(dueDate, forKey: .dueDate)
        try container.encodeDateOnlyIfPresent(paidDate, forKey: .paidDate)
        try container.encode(expectedAmount, forKey: .expectedAmount)
        try container.encode(actualAmount, forKey: .actualAmount)
        try container.encodeIfPresent(notes, forKey: .notes)
        try container.encode(wasLate, forKey: .wasLate)
        try container.encodeIfPresent(daysLate, forKey: .daysLate)
        try container.encode(currencyCode, forKey: .currencyCode)
        try container.encodeTimestampIfPresent(createdAt, forKey: .createdAt)
        try container.encodeTimestampIfPresent(deletedAt, forKey: .deletedAt)
    }
}

protocol SupabaseBillPaymentRemoteStoreProtocol {
    func currentAuthenticatedUserID() async -> UUID?
    func fetchBillPayments(userID: UUID) async throws -> [SupabaseBillPaymentRow]
    func fetchBills(userID: UUID) async throws -> [SupabaseBillRow]
    func upsertBillPayment(_ payload: SupabaseBillPaymentUpsertPayload) async throws -> SupabaseBillPaymentRow
}

enum SupabaseBillPaymentRemoteStoreError: Error {
    case notConfigured
}

struct SupabaseBillPaymentRemoteStore: SupabaseBillPaymentRemoteStoreProtocol {
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

    func fetchBillPayments(userID: UUID) async throws -> [SupabaseBillPaymentRow] {
        let client = try requireClient()
        return try await client
            .from(SupabaseFinancialTableNames.billPayments)
            .select()
            .eq("user_id", value: userID.uuidString)
            .execute()
            .value
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

    func upsertBillPayment(_ payload: SupabaseBillPaymentUpsertPayload) async throws -> SupabaseBillPaymentRow {
        let client = try requireClient()
        return try await client
            .from(SupabaseFinancialTableNames.billPayments)
            .upsert(payload, onConflict: "user_id,client_record_id")
            .select()
            .single()
            .execute()
            .value
    }

    private func requireClient() throws -> SupabaseClient {
        guard let client = clientProvider() else {
            throw SupabaseBillPaymentRemoteStoreError.notConfigured
        }
        return client
    }
}

@MainActor
final class SupabaseBillPaymentSyncService: FinancialEntitySyncScheduling {
    static let shared = SupabaseBillPaymentSyncService()

    private let persistenceService: PersistenceService
    private let remoteStore: SupabaseBillPaymentRemoteStoreProtocol
    private var isSyncInFlight = false
    private var hasQueuedSync = false

    init(
        persistenceService: PersistenceService = .shared,
        remoteStore: SupabaseBillPaymentRemoteStoreProtocol = SupabaseBillPaymentRemoteStore()
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
            let remoteRows = try await remoteStore.fetchBillPayments(userID: userID)
            let remoteBills = try await remoteStore.fetchBills(userID: userID)
            let billRemoteIDByClientRecordID = Dictionary(
                uniqueKeysWithValues: remoteBills.map { ($0.clientRecordID, $0.id) }
            )
            try await reconcile(
                localContext: persistenceService.viewContext,
                userID: userID,
                remoteRows: remoteRows,
                billRemoteIDByClientRecordID: billRemoteIDByClientRecordID
            )
        } catch {
            print("☁️ SupabaseBillPaymentSyncService: sync skipped (\(error))")
        }
    }

    private func reconcile(
        localContext: NSManagedObjectContext,
        userID: UUID,
        remoteRows: [SupabaseBillPaymentRow],
        billRemoteIDByClientRecordID: [String: UUID]
    ) async throws {
        let localPayments = fetchAllLocalBillPayments(in: localContext)
        var localByClientRecordID: [String: BillPayment] = [:]
        for payment in localPayments {
            let clientRecordID = payment.ensureFinancialSyncClientRecordID()
            localByClientRecordID[clientRecordID] = payment
        }

        let remoteByClientRecordID = Dictionary(uniqueKeysWithValues: remoteRows.map { ($0.clientRecordID, $0) })
        var didMutateLocalState = false
        var shouldRefreshViews = false

        for remoteRow in remoteRows {
            guard let localPayment = localByClientRecordID[remoteRow.clientRecordID] else {
                if remoteRow.deletedAt == nil, insertLocalBillPayment(from: remoteRow, into: localContext) != nil {
                    didMutateLocalState = true
                    shouldRefreshViews = true
                }
                continue
            }

            let localTimestamp = localPayment.financialSyncMutationTimestamp()
            let remoteTimestamp = FinancialEntitySyncSupport.remoteMutationTimestamp(
                updatedAt: remoteRow.updatedAt,
                deletedAt: remoteRow.deletedAt,
                createdAt: remoteRow.createdAt
            )
            let localDeletedAt = localPayment.deletedAt
            let remoteDeletedAt = remoteRow.deletedAt

            if let remoteDeletedAt {
                if localDeletedAt == nil
                    || remoteTimestamp >= localTimestamp
                    || localPayment.syncStatus == FinancialEntitySyncStatus.synced.rawValue {
                    applyRemoteRow(remoteRow, to: localPayment)
                    localPayment.deletedAt = remoteDeletedAt
                    didMutateLocalState = true
                    shouldRefreshViews = true
                } else if let uploadedRow = try? await uploadLocalBillPayment(
                    localPayment,
                    for: userID,
                    billRemoteIDByClientRecordID: billRemoteIDByClientRecordID
                ) {
                    applyRemoteTimestamps(from: uploadedRow, to: localPayment)
                    didMutateLocalState = true
                }
                continue
            }

            if localDeletedAt != nil {
                if localTimestamp >= remoteTimestamp {
                    if let uploadedRow = try? await uploadLocalBillPayment(
                        localPayment,
                        for: userID,
                        billRemoteIDByClientRecordID: billRemoteIDByClientRecordID
                    ) {
                        applyRemoteTimestamps(from: uploadedRow, to: localPayment)
                        didMutateLocalState = true
                    }
                } else {
                    applyRemoteRow(remoteRow, to: localPayment)
                    didMutateLocalState = true
                    shouldRefreshViews = true
                }
                continue
            }

            if remoteTimestamp > localTimestamp {
                applyRemoteRow(remoteRow, to: localPayment)
                didMutateLocalState = true
                shouldRefreshViews = true
                continue
            }

            let localNeedsUpload =
                localTimestamp > remoteTimestamp
                || localPayment.syncStatus == FinancialEntitySyncStatus.pending.rawValue
                || localPayment.syncStatus == FinancialEntitySyncStatus.failed.rawValue
                || localPayment.lastSyncedAt == nil

            if localNeedsUpload {
                if let uploadedRow = try? await uploadLocalBillPayment(
                    localPayment,
                    for: userID,
                    billRemoteIDByClientRecordID: billRemoteIDByClientRecordID
                ) {
                    applyRemoteRow(uploadedRow, to: localPayment)
                    didMutateLocalState = true
                    shouldRefreshViews = true
                } else {
                    localPayment.markFinancialSyncFailed("Upload failed")
                    didMutateLocalState = true
                }
            } else if localPayment.remoteUpdatedAt != remoteRow.updatedAt {
                applyRemoteRow(remoteRow, to: localPayment)
                didMutateLocalState = true
                shouldRefreshViews = true
            }
        }

        for localPayment in localPayments {
            let clientRecordID = localPayment.ensureFinancialSyncClientRecordID()
            guard remoteByClientRecordID[clientRecordID] == nil else { continue }

            if localPayment.deletedAt != nil {
                if localPayment.lastSyncedAt != nil {
                    localPayment.markFinancialSyncSynced(remoteUpdatedAtValue: localPayment.remoteUpdatedAt)
                    didMutateLocalState = true
                }
                continue
            }

            if let uploadedRow = try? await uploadLocalBillPayment(
                localPayment,
                for: userID,
                billRemoteIDByClientRecordID: billRemoteIDByClientRecordID
            ) {
                applyRemoteRow(uploadedRow, to: localPayment)
                didMutateLocalState = true
                shouldRefreshViews = true
            } else {
                localPayment.markFinancialSyncFailed("Initial upload failed")
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

    private func uploadLocalBillPayment(
        _ payment: BillPayment,
        for userID: UUID,
        billRemoteIDByClientRecordID: [String: UUID]
    ) async throws -> SupabaseBillPaymentRow {
        let payload = try makePayload(
            from: payment,
            userID: userID,
            billRemoteIDByClientRecordID: billRemoteIDByClientRecordID
        )
        return try await remoteStore.upsertBillPayment(payload)
    }

    private func makePayload(
        from payment: BillPayment,
        userID: UUID,
        billRemoteIDByClientRecordID: [String: UUID]
    ) throws -> SupabaseBillPaymentUpsertPayload {
        guard let billID = payment.billID else {
            throw BillPaymentSyncError.missingParentBill
        }

        let billClientRecordID = billID.uuidString
        guard let remoteBillID = billRemoteIDByClientRecordID[billClientRecordID] else {
            throw BillPaymentSyncError.parentBillNotSynced
        }

        return SupabaseBillPaymentUpsertPayload(
            userID: userID,
            clientRecordID: payment.ensureFinancialSyncClientRecordID(),
            billID: remoteBillID,
            billClientRecordID: billClientRecordID,
            dueDate: payment.dueDate,
            paidDate: payment.paidDate,
            expectedAmount: FinancialEntitySyncSupport.decimal(from: payment.expectedAmount),
            actualAmount: FinancialEntitySyncSupport.decimal(from: payment.actualAmount),
            notes: payment.notes,
            wasLate: payment.wasLate,
            daysLate: payment.daysLate > 0 ? Int(payment.daysLate) : nil,
            currencyCode: RecordCurrencySupport.payloadCurrencyCode(storedCode: payment.currencyCode),
            createdAt: payment.createdAt,
            deletedAt: payment.deletedAt
        )
    }

    private func insertLocalBillPayment(
        from remoteRow: SupabaseBillPaymentRow,
        into context: NSManagedObjectContext
    ) -> BillPayment? {
        guard let clientUUID = UUID(uuidString: remoteRow.clientRecordID) else {
            print("☁️ SupabaseBillPaymentSyncService: skipped remote row with invalid client_record_id")
            return nil
        }

        let payment = BillPayment(context: context)
        payment.id = clientUUID
        applyRemoteRow(remoteRow, to: payment)
        return payment
    }

    private func applyRemoteRow(_ remoteRow: SupabaseBillPaymentRow, to payment: BillPayment) {
        payment.id = UUID(uuidString: remoteRow.clientRecordID) ?? payment.id
        if let billClientRecordID = remoteRow.billClientRecordID,
           let billUUID = UUID(uuidString: billClientRecordID) {
            payment.billID = billUUID
        }
        payment.dueDate = remoteRow.dueDate
        payment.paidDate = remoteRow.paidDate
        payment.expectedAmount = FinancialEntitySyncSupport.double(from: remoteRow.expectedAmount)
        payment.actualAmount = FinancialEntitySyncSupport.double(from: remoteRow.actualAmount)
        payment.notes = remoteRow.notes
        payment.wasLate = remoteRow.wasLate
        payment.daysLate = Int16(clamping: remoteRow.daysLate ?? 0)
        payment.currencyCode = remoteRow.currencyCode
        payment.createdAt = remoteRow.createdAt ?? payment.createdAt ?? Date()
        payment.lastModified = FinancialEntitySyncSupport.maxDate(
            payment.lastModified,
            remoteRow.updatedAt ?? remoteRow.createdAt
        )
        payment.deletedAt = remoteRow.deletedAt
        payment.markFinancialSyncSynced(remoteUpdatedAtValue: remoteRow.updatedAt ?? remoteRow.createdAt)
    }

    private func applyRemoteTimestamps(from remoteRow: SupabaseBillPaymentRow, to payment: BillPayment) {
        payment.markFinancialSyncSynced(remoteUpdatedAtValue: remoteRow.updatedAt ?? remoteRow.createdAt)
    }

    private func fetchAllLocalBillPayments(in context: NSManagedObjectContext) -> [BillPayment] {
        let request: NSFetchRequest<BillPayment> = BillPayment.fetchRequest()
        do {
            return try context.fetch(request)
        } catch {
            print("☁️ SupabaseBillPaymentSyncService: failed fetching local bill payments (\(error))")
            return []
        }
    }
}

private enum BillPaymentSyncError: Error {
    case missingParentBill
    case parentBillNotSynced
}

private enum SupabaseBillPaymentDateCoding {
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

private extension KeyedDecodingContainer where K == SupabaseBillPaymentRow.CodingKeys {
    func decodeDateOnlyIfPresent(forKey key: K) throws -> Date? {
        guard let value = try decodeIfPresent(String.self, forKey: key), !value.isEmpty else {
            return nil
        }
        return SupabaseBillPaymentDateCoding.decodeDateOnly(value)
    }

    func decodeTimestampIfPresent(forKey key: K) throws -> Date? {
        guard let value = try decodeIfPresent(String.self, forKey: key), !value.isEmpty else {
            return nil
        }
        return SupabaseBillPaymentDateCoding.decodeTimestamp(value)
    }
}

private extension KeyedEncodingContainer where K == SupabaseBillPaymentUpsertPayload.CodingKeys {
    mutating func encodeDateOnlyIfPresent(_ value: Date?, forKey key: K) throws {
        guard let value else { return }
        try encode(SupabaseBillPaymentDateCoding.encodeDateOnly(value), forKey: key)
    }

    mutating func encodeTimestampIfPresent(_ value: Date?, forKey key: K) throws {
        guard let value else { return }
        try encode(SupabaseBillPaymentDateCoding.encodeTimestamp(value), forKey: key)
    }
}
