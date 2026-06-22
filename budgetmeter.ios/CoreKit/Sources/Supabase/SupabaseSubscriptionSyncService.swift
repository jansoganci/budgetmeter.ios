//
//  SupabaseSubscriptionSyncService.swift
//  BudgetMeter
//
//  Phase 2C subscription Supabase sync.
//

import CoreData
import Foundation
import Supabase

struct SupabaseSubscriptionRow: Decodable, Equatable {
    let id: UUID
    let userID: UUID
    let clientRecordID: String
    let name: String
    let amount: Decimal
    let billingCycle: String
    let customCycleDays: Int?
    let firstBillDate: Date?
    let nextRenewalDate: Date?
    let categoryLabel: String?
    let notes: String?
    let reminderDaysBefore: Int?
    let isActive: Bool
    let isPaused: Bool
    let createdAt: Date?
    let updatedAt: Date?
    let deletedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case clientRecordID = "client_record_id"
        case name
        case amount
        case billingCycle = "billing_cycle"
        case customCycleDays = "custom_cycle_days"
        case firstBillDate = "first_bill_date"
        case nextRenewalDate = "next_renewal_date"
        case categoryLabel = "category_label"
        case notes
        case reminderDaysBefore = "reminder_days_before"
        case isActive = "is_active"
        case isPaused = "is_paused"
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
        billingCycle: String,
        customCycleDays: Int?,
        firstBillDate: Date?,
        nextRenewalDate: Date?,
        categoryLabel: String?,
        notes: String?,
        reminderDaysBefore: Int?,
        isActive: Bool,
        isPaused: Bool,
        createdAt: Date?,
        updatedAt: Date?,
        deletedAt: Date?
    ) {
        self.id = id
        self.userID = userID
        self.clientRecordID = clientRecordID
        self.name = name
        self.amount = amount
        self.billingCycle = billingCycle
        self.customCycleDays = customCycleDays
        self.firstBillDate = firstBillDate
        self.nextRenewalDate = nextRenewalDate
        self.categoryLabel = categoryLabel
        self.notes = notes
        self.reminderDaysBefore = reminderDaysBefore
        self.isActive = isActive
        self.isPaused = isPaused
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
        billingCycle = try container.decode(String.self, forKey: .billingCycle)
        customCycleDays = try container.decodeIfPresent(Int.self, forKey: .customCycleDays)
        firstBillDate = try container.decodeDateOnlyIfPresent(forKey: .firstBillDate)
        nextRenewalDate = try container.decodeDateOnlyIfPresent(forKey: .nextRenewalDate)
        categoryLabel = try container.decodeIfPresent(String.self, forKey: .categoryLabel)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        reminderDaysBefore = try container.decodeIfPresent(Int.self, forKey: .reminderDaysBefore)
        isActive = try container.decode(Bool.self, forKey: .isActive)
        isPaused = try container.decode(Bool.self, forKey: .isPaused)
        createdAt = try container.decodeTimestampIfPresent(forKey: .createdAt)
        updatedAt = try container.decodeTimestampIfPresent(forKey: .updatedAt)
        deletedAt = try container.decodeTimestampIfPresent(forKey: .deletedAt)
    }
}

struct SupabaseSubscriptionUpsertPayload: Encodable {
    let userID: UUID
    let clientRecordID: String
    let name: String
    let amount: Decimal
    let billingCycle: String
    let customCycleDays: Int?
    let firstBillDate: Date?
    let nextRenewalDate: Date?
    let categoryLabel: String?
    let notes: String?
    let reminderDaysBefore: Int?
    let isActive: Bool
    let isPaused: Bool
    let createdAt: Date?
    let deletedAt: Date?

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case clientRecordID = "client_record_id"
        case name
        case amount
        case billingCycle = "billing_cycle"
        case customCycleDays = "custom_cycle_days"
        case firstBillDate = "first_bill_date"
        case nextRenewalDate = "next_renewal_date"
        case categoryLabel = "category_label"
        case notes
        case reminderDaysBefore = "reminder_days_before"
        case isActive = "is_active"
        case isPaused = "is_paused"
        case createdAt = "created_at"
        case deletedAt = "deleted_at"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(userID, forKey: .userID)
        try container.encode(clientRecordID, forKey: .clientRecordID)
        try container.encode(name, forKey: .name)
        try container.encode(amount, forKey: .amount)
        try container.encode(billingCycle, forKey: .billingCycle)
        try container.encodeIfPresent(customCycleDays, forKey: .customCycleDays)
        try container.encodeDateOnlyIfPresent(firstBillDate, forKey: .firstBillDate)
        try container.encodeDateOnlyIfPresent(nextRenewalDate, forKey: .nextRenewalDate)
        try container.encodeIfPresent(categoryLabel, forKey: .categoryLabel)
        try container.encodeIfPresent(notes, forKey: .notes)
        try container.encodeIfPresent(reminderDaysBefore, forKey: .reminderDaysBefore)
        try container.encode(isActive, forKey: .isActive)
        try container.encode(isPaused, forKey: .isPaused)
        try container.encodeTimestampIfPresent(createdAt, forKey: .createdAt)
        try container.encodeTimestampIfPresent(deletedAt, forKey: .deletedAt)
    }
}

protocol SupabaseSubscriptionRemoteStoreProtocol {
    func currentAuthenticatedUserID() async -> UUID?
    func fetchSubscriptions(userID: UUID) async throws -> [SupabaseSubscriptionRow]
    func upsertSubscription(_ payload: SupabaseSubscriptionUpsertPayload) async throws -> SupabaseSubscriptionRow
}

enum SupabaseSubscriptionRemoteStoreError: Error {
    case notConfigured
}

struct SupabaseSubscriptionRemoteStore: SupabaseSubscriptionRemoteStoreProtocol {
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

    func fetchSubscriptions(userID: UUID) async throws -> [SupabaseSubscriptionRow] {
        let client = try requireClient()
        return try await client
            .from(SupabaseFinancialTableNames.subscriptions)
            .select()
            .eq("user_id", value: userID.uuidString)
            .execute()
            .value
    }

    func upsertSubscription(_ payload: SupabaseSubscriptionUpsertPayload) async throws -> SupabaseSubscriptionRow {
        let client = try requireClient()
        return try await client
            .from(SupabaseFinancialTableNames.subscriptions)
            .upsert(payload, onConflict: "user_id,client_record_id")
            .select()
            .single()
            .execute()
            .value
    }

    private func requireClient() throws -> SupabaseClient {
        guard let client = clientProvider() else {
            throw SupabaseSubscriptionRemoteStoreError.notConfigured
        }
        return client
    }
}

@MainActor
final class SupabaseSubscriptionSyncService: FinancialEntitySyncScheduling {
    static let shared = SupabaseSubscriptionSyncService()

    private let persistenceService: PersistenceService
    private let remoteStore: SupabaseSubscriptionRemoteStoreProtocol
    private var isSyncInFlight = false
    private var hasQueuedSync = false

    init(
        persistenceService: PersistenceService = .shared,
        remoteStore: SupabaseSubscriptionRemoteStoreProtocol = SupabaseSubscriptionRemoteStore()
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
            let remoteRows = try await remoteStore.fetchSubscriptions(userID: userID)
            try await reconcile(
                localContext: persistenceService.viewContext,
                userID: userID,
                remoteRows: remoteRows
            )
        } catch {
            print("☁️ SupabaseSubscriptionSyncService: sync skipped (\(error))")
        }
    }

    private func reconcile(
        localContext: NSManagedObjectContext,
        userID: UUID,
        remoteRows: [SupabaseSubscriptionRow]
    ) async throws {
        let localSubscriptions = fetchAllLocalSubscriptions(in: localContext)
        var localByClientRecordID: [String: Subscription] = [:]
        for subscription in localSubscriptions {
            let clientRecordID = subscription.ensureFinancialSyncClientRecordID()
            localByClientRecordID[clientRecordID] = subscription
        }

        let remoteByClientRecordID = Dictionary(uniqueKeysWithValues: remoteRows.map { ($0.clientRecordID, $0) })
        var didMutateLocalState = false
        var shouldRefreshViews = false

        for remoteRow in remoteRows {
            guard let localSubscription = localByClientRecordID[remoteRow.clientRecordID] else {
                if remoteRow.deletedAt == nil, insertLocalSubscription(from: remoteRow, into: localContext) != nil {
                    didMutateLocalState = true
                    shouldRefreshViews = true
                }
                continue
            }

            let localTimestamp = localSubscription.financialSyncMutationTimestamp()
            let remoteTimestamp = FinancialEntitySyncSupport.remoteMutationTimestamp(
                updatedAt: remoteRow.updatedAt,
                deletedAt: remoteRow.deletedAt,
                createdAt: remoteRow.createdAt
            )
            let localDeletedAt = localSubscription.deletedAt
            let remoteDeletedAt = remoteRow.deletedAt

            if let remoteDeletedAt {
                if localDeletedAt == nil
                    || remoteTimestamp >= localTimestamp
                    || localSubscription.syncStatus == FinancialEntitySyncStatus.synced.rawValue {
                    applyRemoteRow(remoteRow, to: localSubscription)
                    localSubscription.deletedAt = remoteDeletedAt
                    didMutateLocalState = true
                    shouldRefreshViews = true
                } else if let uploadedRow = try? await uploadLocalSubscription(localSubscription, for: userID) {
                    applyRemoteTimestamps(from: uploadedRow, to: localSubscription)
                    didMutateLocalState = true
                }
                continue
            }

            if localDeletedAt != nil {
                if localTimestamp >= remoteTimestamp {
                    if let uploadedRow = try? await uploadLocalSubscription(localSubscription, for: userID) {
                        applyRemoteTimestamps(from: uploadedRow, to: localSubscription)
                        didMutateLocalState = true
                    }
                } else {
                    applyRemoteRow(remoteRow, to: localSubscription)
                    didMutateLocalState = true
                    shouldRefreshViews = true
                }
                continue
            }

            if remoteTimestamp > localTimestamp {
                applyRemoteRow(remoteRow, to: localSubscription)
                didMutateLocalState = true
                shouldRefreshViews = true
                continue
            }

            let localNeedsUpload =
                localTimestamp > remoteTimestamp
                || localSubscription.syncStatus == FinancialEntitySyncStatus.pending.rawValue
                || localSubscription.syncStatus == FinancialEntitySyncStatus.failed.rawValue
                || localSubscription.lastSyncedAt == nil

            if localNeedsUpload {
                if let uploadedRow = try? await uploadLocalSubscription(localSubscription, for: userID) {
                    applyRemoteRow(uploadedRow, to: localSubscription)
                    didMutateLocalState = true
                    shouldRefreshViews = true
                } else {
                    localSubscription.markFinancialSyncFailed("Upload failed")
                    didMutateLocalState = true
                }
            } else if localSubscription.remoteUpdatedAt != remoteRow.updatedAt {
                applyRemoteRow(remoteRow, to: localSubscription)
                didMutateLocalState = true
                shouldRefreshViews = true
            }
        }

        for localSubscription in localSubscriptions {
            let clientRecordID = localSubscription.ensureFinancialSyncClientRecordID()
            guard remoteByClientRecordID[clientRecordID] == nil else { continue }

            if localSubscription.deletedAt != nil {
                if localSubscription.lastSyncedAt != nil {
                    localSubscription.markFinancialSyncSynced(remoteUpdatedAtValue: localSubscription.remoteUpdatedAt)
                    didMutateLocalState = true
                }
                continue
            }

            if let uploadedRow = try? await uploadLocalSubscription(localSubscription, for: userID) {
                applyRemoteRow(uploadedRow, to: localSubscription)
                didMutateLocalState = true
                shouldRefreshViews = true
            } else {
                localSubscription.markFinancialSyncFailed("Initial upload failed")
                didMutateLocalState = true
            }
        }

        if didMutateLocalState {
            _ = persistenceService.save()
        }

        if shouldRefreshViews {
            NotificationCenter.default.post(name: SubscriptionManager.subscriptionUpdatedNotification, object: nil)
        }
    }

    private func uploadLocalSubscription(
        _ subscription: Subscription,
        for userID: UUID
    ) async throws -> SupabaseSubscriptionRow {
        let payload = makePayload(from: subscription, userID: userID)
        return try await remoteStore.upsertSubscription(payload)
    }

    private func makePayload(from subscription: Subscription, userID: UUID) -> SupabaseSubscriptionUpsertPayload {
        SupabaseSubscriptionUpsertPayload(
            userID: userID,
            clientRecordID: subscription.ensureFinancialSyncClientRecordID(),
            name: normalizedName(subscription.name),
            amount: FinancialEntitySyncSupport.decimal(from: subscription.amount),
            billingCycle: subscription.billingCycle ?? "monthly",
            customCycleDays: subscription.customCycleDays > 0 ? Int(subscription.customCycleDays) : nil,
            firstBillDate: subscription.firstBillDate,
            nextRenewalDate: subscription.nextRenewalDate,
            categoryLabel: subscription.category,
            notes: subscription.notes,
            reminderDaysBefore: Int(subscription.reminderDaysBefore),
            isActive: subscription.isActive,
            isPaused: subscription.isPaused,
            createdAt: subscription.createdAt,
            deletedAt: subscription.deletedAt
        )
    }

    private func insertLocalSubscription(
        from remoteRow: SupabaseSubscriptionRow,
        into context: NSManagedObjectContext
    ) -> Subscription? {
        guard let clientUUID = UUID(uuidString: remoteRow.clientRecordID) else {
            print("☁️ SupabaseSubscriptionSyncService: skipped remote row with invalid client_record_id")
            return nil
        }

        let subscription = Subscription(context: context)
        subscription.id = clientUUID
        applyRemoteRow(remoteRow, to: subscription)
        return subscription
    }

    private func applyRemoteRow(_ remoteRow: SupabaseSubscriptionRow, to subscription: Subscription) {
        subscription.id = UUID(uuidString: remoteRow.clientRecordID) ?? subscription.id
        subscription.name = remoteRow.name
        subscription.amount = FinancialEntitySyncSupport.double(from: remoteRow.amount)
        subscription.billingCycle = remoteRow.billingCycle
        subscription.customCycleDays = Int16(clamping: remoteRow.customCycleDays ?? 0)
        subscription.firstBillDate = remoteRow.firstBillDate
        subscription.nextRenewalDate = remoteRow.nextRenewalDate
        subscription.category = remoteRow.categoryLabel
        subscription.notes = remoteRow.notes
        subscription.reminderDaysBefore = Int16(clamping: remoteRow.reminderDaysBefore ?? 3)
        subscription.isActive = remoteRow.isActive
        subscription.isPaused = remoteRow.isPaused
        subscription.createdAt = remoteRow.createdAt ?? subscription.createdAt ?? Date()
        subscription.lastModified = FinancialEntitySyncSupport.maxDate(
            subscription.lastModified,
            remoteRow.updatedAt ?? remoteRow.createdAt
        )
        subscription.deletedAt = remoteRow.deletedAt
        subscription.markFinancialSyncSynced(remoteUpdatedAtValue: remoteRow.updatedAt ?? remoteRow.createdAt)
    }

    private func applyRemoteTimestamps(from remoteRow: SupabaseSubscriptionRow, to subscription: Subscription) {
        subscription.markFinancialSyncSynced(remoteUpdatedAtValue: remoteRow.updatedAt ?? remoteRow.createdAt)
    }

    private func fetchAllLocalSubscriptions(in context: NSManagedObjectContext) -> [Subscription] {
        let request: NSFetchRequest<Subscription> = Subscription.fetchRequest()
        do {
            return try context.fetch(request)
        } catch {
            print("☁️ SupabaseSubscriptionSyncService: failed fetching local subscriptions (\(error))")
            return []
        }
    }

    private func normalizedName(_ value: String?) -> String {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? "Subscription" : trimmed
    }
}

private enum SupabaseSubscriptionDateCoding {
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

private extension KeyedDecodingContainer where K == SupabaseSubscriptionRow.CodingKeys {
    func decodeDateOnlyIfPresent(forKey key: K) throws -> Date? {
        guard let value = try decodeIfPresent(String.self, forKey: key), !value.isEmpty else {
            return nil
        }
        return SupabaseSubscriptionDateCoding.decodeDateOnly(value)
    }

    func decodeTimestampIfPresent(forKey key: K) throws -> Date? {
        guard let value = try decodeIfPresent(String.self, forKey: key), !value.isEmpty else {
            return nil
        }
        return SupabaseSubscriptionDateCoding.decodeTimestamp(value)
    }
}

private extension KeyedEncodingContainer where K == SupabaseSubscriptionUpsertPayload.CodingKeys {
    mutating func encodeDateOnlyIfPresent(_ value: Date?, forKey key: K) throws {
        guard let value else { return }
        try encode(SupabaseSubscriptionDateCoding.encodeDateOnly(value), forKey: key)
    }

    mutating func encodeTimestampIfPresent(_ value: Date?, forKey key: K) throws {
        guard let value else { return }
        try encode(SupabaseSubscriptionDateCoding.encodeTimestamp(value), forKey: key)
    }
}
