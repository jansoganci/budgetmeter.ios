//
//  SupabaseSavingsGoalSyncService.swift
//  BudgetMeter
//
//  Phase 2B savings-goal-only Supabase sync.
//

import CoreData
import Foundation
import Supabase

enum SavingsGoalSyncStatus: String {
    case synced
    case pending
    case failed
}

protocol SavingsGoalSyncScheduling: AnyObject {
    func scheduleSync()
    func bootstrapSignedInAccount() async
}

enum SupabaseFinancialTableNames {
    static let savingsGoals = "savings_goals"
}

struct SupabaseSavingsGoalRow: Decodable, Equatable {
    let id: UUID
    let userID: UUID
    let clientRecordID: String
    let name: String
    let targetAmount: Decimal
    let currentAmount: Decimal
    let targetDate: Date?
    let emoji: String?
    let colorHex: String?
    let priority: Int?
    let isArchived: Bool
    let archivedDate: Date?
    let completedDate: Date?
    let notes: String?
    let categoryLabel: String?
    let monthlyContribution: Decimal?
    let createdAt: Date?
    let updatedAt: Date?
    let deletedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case clientRecordID = "client_record_id"
        case name
        case targetAmount = "target_amount"
        case currentAmount = "current_amount"
        case targetDate = "target_date"
        case emoji
        case colorHex = "color_hex"
        case priority
        case isArchived = "is_archived"
        case archivedDate = "archived_date"
        case completedDate = "completed_date"
        case notes
        case categoryLabel = "category_label"
        case monthlyContribution = "monthly_contribution"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
    }

    init(
        id: UUID,
        userID: UUID,
        clientRecordID: String,
        name: String,
        targetAmount: Decimal,
        currentAmount: Decimal,
        targetDate: Date?,
        emoji: String?,
        colorHex: String?,
        priority: Int?,
        isArchived: Bool,
        archivedDate: Date?,
        completedDate: Date?,
        notes: String?,
        categoryLabel: String?,
        monthlyContribution: Decimal?,
        createdAt: Date?,
        updatedAt: Date?,
        deletedAt: Date?
    ) {
        self.id = id
        self.userID = userID
        self.clientRecordID = clientRecordID
        self.name = name
        self.targetAmount = targetAmount
        self.currentAmount = currentAmount
        self.targetDate = targetDate
        self.emoji = emoji
        self.colorHex = colorHex
        self.priority = priority
        self.isArchived = isArchived
        self.archivedDate = archivedDate
        self.completedDate = completedDate
        self.notes = notes
        self.categoryLabel = categoryLabel
        self.monthlyContribution = monthlyContribution
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
        targetAmount = try container.decode(Decimal.self, forKey: .targetAmount)
        currentAmount = try container.decode(Decimal.self, forKey: .currentAmount)
        targetDate = try container.decodeDateOnlyIfPresent(forKey: .targetDate)
        emoji = try container.decodeIfPresent(String.self, forKey: .emoji)
        colorHex = try container.decodeIfPresent(String.self, forKey: .colorHex)
        priority = try container.decodeIfPresent(Int.self, forKey: .priority)
        isArchived = try container.decode(Bool.self, forKey: .isArchived)
        archivedDate = try container.decodeTimestampIfPresent(forKey: .archivedDate)
        completedDate = try container.decodeTimestampIfPresent(forKey: .completedDate)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        categoryLabel = try container.decodeIfPresent(String.self, forKey: .categoryLabel)
        monthlyContribution = try container.decodeIfPresent(Decimal.self, forKey: .monthlyContribution)
        createdAt = try container.decodeTimestampIfPresent(forKey: .createdAt)
        updatedAt = try container.decodeTimestampIfPresent(forKey: .updatedAt)
        deletedAt = try container.decodeTimestampIfPresent(forKey: .deletedAt)
    }
}

struct SupabaseSavingsGoalUpsertPayload: Encodable {
    let userID: UUID
    let clientRecordID: String
    let name: String
    let targetAmount: Decimal
    let currentAmount: Decimal
    let targetDate: Date?
    let emoji: String?
    let colorHex: String?
    let priority: Int?
    let isArchived: Bool
    let archivedDate: Date?
    let completedDate: Date?
    let notes: String?
    let categoryLabel: String?
    let monthlyContribution: Decimal?
    let createdAt: Date?
    let deletedAt: Date?

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case clientRecordID = "client_record_id"
        case name
        case targetAmount = "target_amount"
        case currentAmount = "current_amount"
        case targetDate = "target_date"
        case emoji
        case colorHex = "color_hex"
        case priority
        case isArchived = "is_archived"
        case archivedDate = "archived_date"
        case completedDate = "completed_date"
        case notes
        case categoryLabel = "category_label"
        case monthlyContribution = "monthly_contribution"
        case createdAt = "created_at"
        case deletedAt = "deleted_at"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(userID, forKey: .userID)
        try container.encode(clientRecordID, forKey: .clientRecordID)
        try container.encode(name, forKey: .name)
        try container.encode(targetAmount, forKey: .targetAmount)
        try container.encode(currentAmount, forKey: .currentAmount)
        try container.encodeDateOnlyIfPresent(targetDate, forKey: .targetDate)
        try container.encodeIfPresent(emoji, forKey: .emoji)
        try container.encodeIfPresent(colorHex, forKey: .colorHex)
        try container.encodeIfPresent(priority, forKey: .priority)
        try container.encode(isArchived, forKey: .isArchived)
        try container.encodeTimestampIfPresent(archivedDate, forKey: .archivedDate)
        try container.encodeTimestampIfPresent(completedDate, forKey: .completedDate)
        try container.encodeIfPresent(notes, forKey: .notes)
        try container.encodeIfPresent(categoryLabel, forKey: .categoryLabel)
        try container.encodeIfPresent(monthlyContribution, forKey: .monthlyContribution)
        try container.encodeTimestampIfPresent(createdAt, forKey: .createdAt)
        try container.encodeTimestampIfPresent(deletedAt, forKey: .deletedAt)
    }
}

protocol SupabaseSavingsGoalRemoteStoreProtocol {
    func currentAuthenticatedUserID() async -> UUID?
    func fetchSavingsGoals(userID: UUID) async throws -> [SupabaseSavingsGoalRow]
    func upsertSavingsGoal(_ payload: SupabaseSavingsGoalUpsertPayload) async throws -> SupabaseSavingsGoalRow
}

enum SupabaseSavingsGoalRemoteStoreError: Error {
    case notConfigured
}

struct SupabaseSavingsGoalRemoteStore: SupabaseSavingsGoalRemoteStoreProtocol {
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

    func fetchSavingsGoals(userID: UUID) async throws -> [SupabaseSavingsGoalRow] {
        let client = try requireClient()
        return try await client
            .from(SupabaseFinancialTableNames.savingsGoals)
            .select()
            .eq("user_id", value: userID.uuidString)
            .execute()
            .value
    }

    func upsertSavingsGoal(_ payload: SupabaseSavingsGoalUpsertPayload) async throws -> SupabaseSavingsGoalRow {
        let client = try requireClient()
        return try await client
            .from(SupabaseFinancialTableNames.savingsGoals)
            .upsert(payload, onConflict: "user_id,client_record_id")
            .select()
            .single()
            .execute()
            .value
    }

    private func requireClient() throws -> SupabaseClient {
        guard let client = clientProvider() else {
            throw SupabaseSavingsGoalRemoteStoreError.notConfigured
        }
        return client
    }
}

@MainActor
final class SupabaseSavingsGoalSyncService: SavingsGoalSyncScheduling {
    static let shared = SupabaseSavingsGoalSyncService()

    private let persistenceService: PersistenceService
    private let remoteStore: SupabaseSavingsGoalRemoteStoreProtocol
    private var isSyncInFlight = false
    private var hasQueuedSync = false

    init(
        persistenceService: PersistenceService = .shared,
        remoteStore: SupabaseSavingsGoalRemoteStoreProtocol = SupabaseSavingsGoalRemoteStore()
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
            let remoteRows = try await remoteStore.fetchSavingsGoals(userID: userID)
            try await reconcile(localContext: persistenceService.viewContext, userID: userID, remoteRows: remoteRows)
        } catch {
            print("☁️ SupabaseSavingsGoalSyncService: sync skipped (\(error))")
        }
    }

    private func reconcile(
        localContext: NSManagedObjectContext,
        userID: UUID,
        remoteRows: [SupabaseSavingsGoalRow]
    ) async throws {
        let localGoals = fetchAllLocalGoals(in: localContext)
        var localByClientRecordID: [String: SavingsGoal] = [:]
        for goal in localGoals {
            let clientRecordID = ensureClientRecordID(for: goal)
            localByClientRecordID[clientRecordID] = goal
        }

        let remoteByClientRecordID = Dictionary(uniqueKeysWithValues: remoteRows.map { ($0.clientRecordID, $0) })
        var didMutateLocalState = false
        var shouldRefreshSavingsGoalViews = false

        for remoteRow in remoteRows {
            guard let localGoal = localByClientRecordID[remoteRow.clientRecordID] else {
                if remoteRow.deletedAt == nil, insertLocalGoal(from: remoteRow, into: localContext) != nil {
                    didMutateLocalState = true
                    shouldRefreshSavingsGoalViews = true
                }
                continue
            }

            let localTimestamp = mutationTimestamp(for: localGoal)
            let remoteTimestamp = remoteMutationTimestamp(for: remoteRow)
            let localDeletedAt = localGoal.deletedAt
            let remoteDeletedAt = remoteRow.deletedAt

            if let remoteDeletedAt {
                if localDeletedAt == nil || remoteTimestamp >= localTimestamp || localGoal.syncStatus == SavingsGoalSyncStatus.synced.rawValue {
                    applyRemoteRow(remoteRow, to: localGoal)
                    localGoal.deletedAt = remoteDeletedAt
                    didMutateLocalState = true
                    shouldRefreshSavingsGoalViews = true
                } else {
                    if let uploadedRow = try? await uploadLocalGoal(localGoal, for: userID) {
                        applyRemoteTimestamps(from: uploadedRow, to: localGoal)
                        didMutateLocalState = true
                    }
                }
                continue
            }

            if localDeletedAt != nil {
                if localTimestamp >= remoteTimestamp {
                    if let uploadedRow = try? await uploadLocalGoal(localGoal, for: userID) {
                        applyRemoteTimestamps(from: uploadedRow, to: localGoal)
                        didMutateLocalState = true
                    }
                } else {
                    applyRemoteRow(remoteRow, to: localGoal)
                    didMutateLocalState = true
                    shouldRefreshSavingsGoalViews = true
                }
                continue
            }

            if remoteTimestamp > localTimestamp {
                applyRemoteRow(remoteRow, to: localGoal)
                didMutateLocalState = true
                shouldRefreshSavingsGoalViews = true
                continue
            }

            let localNeedsUpload =
                localTimestamp > remoteTimestamp
                || localGoal.syncStatus == SavingsGoalSyncStatus.pending.rawValue
                || localGoal.syncStatus == SavingsGoalSyncStatus.failed.rawValue
                || localGoal.lastSyncedAt == nil

            if localNeedsUpload {
                if let uploadedRow = try? await uploadLocalGoal(localGoal, for: userID) {
                    applyRemoteRow(uploadedRow, to: localGoal)
                    didMutateLocalState = true
                    shouldRefreshSavingsGoalViews = true
                } else {
                    markGoal(localGoal, syncStatus: .failed, error: "Upload failed")
                    didMutateLocalState = true
                }
            } else if localGoal.remoteUpdatedAt != remoteRow.updatedAt {
                applyRemoteRow(remoteRow, to: localGoal)
                didMutateLocalState = true
                shouldRefreshSavingsGoalViews = true
            }
        }

        for localGoal in localGoals {
            let clientRecordID = ensureClientRecordID(for: localGoal)
            guard remoteByClientRecordID[clientRecordID] == nil else { continue }

            if localGoal.deletedAt != nil {
                if localGoal.lastSyncedAt != nil {
                    markGoalAsSynced(localGoal, remoteUpdatedAt: localGoal.remoteUpdatedAt)
                    didMutateLocalState = true
                }
                continue
            }

            if let uploadedRow = try? await uploadLocalGoal(localGoal, for: userID) {
                applyRemoteRow(uploadedRow, to: localGoal)
                didMutateLocalState = true
                shouldRefreshSavingsGoalViews = true
            } else {
                markGoal(localGoal, syncStatus: .failed, error: "Initial upload failed")
                didMutateLocalState = true
            }
        }

        if didMutateLocalState {
            _ = persistenceService.save()
        }

        if shouldRefreshSavingsGoalViews {
            NotificationCenter.default.post(name: SavingsGoalManager.goalUpdatedNotification, object: nil)
        }
    }

    private func uploadLocalGoal(_ goal: SavingsGoal, for userID: UUID) async throws -> SupabaseSavingsGoalRow {
        let payload = makePayload(from: goal, userID: userID)
        return try await remoteStore.upsertSavingsGoal(payload)
    }

    private func makePayload(from goal: SavingsGoal, userID: UUID) -> SupabaseSavingsGoalUpsertPayload {
        let clientRecordID = ensureClientRecordID(for: goal)
        return SupabaseSavingsGoalUpsertPayload(
            userID: userID,
            clientRecordID: clientRecordID,
            name: normalizedName(goal.name),
            targetAmount: Self.decimal(from: goal.targetAmount),
            currentAmount: Self.decimal(from: goal.currentAmount),
            targetDate: goal.targetDate,
            emoji: goal.emoji,
            colorHex: goal.colorHex,
            priority: Int(goal.priority),
            isArchived: goal.isArchived,
            archivedDate: goal.archivedDate,
            completedDate: goal.completedDate,
            notes: goal.notes,
            categoryLabel: goal.category,
            monthlyContribution: goal.monthlyContribution > 0 ? Self.decimal(from: goal.monthlyContribution) : nil,
            createdAt: goal.createdAt,
            deletedAt: goal.deletedAt
        )
    }

    private func insertLocalGoal(from remoteRow: SupabaseSavingsGoalRow, into context: NSManagedObjectContext) -> SavingsGoal? {
        guard let clientUUID = UUID(uuidString: remoteRow.clientRecordID) else {
            print("☁️ SupabaseSavingsGoalSyncService: skipped remote row with invalid client_record_id")
            return nil
        }

        let goal = SavingsGoal(context: context)
        goal.id = clientUUID
        applyRemoteRow(remoteRow, to: goal)
        return goal
    }

    private func applyRemoteRow(_ remoteRow: SupabaseSavingsGoalRow, to goal: SavingsGoal) {
        goal.id = UUID(uuidString: remoteRow.clientRecordID) ?? goal.id
        goal.name = remoteRow.name
        goal.targetAmount = Self.double(from: remoteRow.targetAmount)
        goal.currentAmount = Self.double(from: remoteRow.currentAmount)
        goal.targetDate = remoteRow.targetDate
        goal.emoji = remoteRow.emoji
        goal.colorHex = remoteRow.colorHex
        goal.priority = Int16(clamping: remoteRow.priority ?? 0)
        goal.isArchived = remoteRow.isArchived
        goal.archivedDate = remoteRow.archivedDate
        goal.completedDate = remoteRow.completedDate
        goal.notes = remoteRow.notes
        goal.category = remoteRow.categoryLabel
        goal.monthlyContribution = Self.double(from: remoteRow.monthlyContribution ?? 0)
        goal.createdAt = remoteRow.createdAt ?? goal.createdAt ?? Date()
        goal.lastModified = maxDate(goal.lastModified, remoteRow.updatedAt ?? remoteRow.createdAt)
        goal.deletedAt = remoteRow.deletedAt
        markGoalAsSynced(goal, remoteUpdatedAt: remoteRow.updatedAt ?? remoteRow.createdAt)
    }

    private func applyRemoteTimestamps(from remoteRow: SupabaseSavingsGoalRow, to goal: SavingsGoal) {
        goal.remoteUpdatedAt = remoteRow.updatedAt ?? remoteRow.createdAt
        goal.lastSyncedAt = Date()
        goal.syncStatus = SavingsGoalSyncStatus.synced.rawValue
        goal.lastSyncError = nil
    }

    private func markGoal(_ goal: SavingsGoal, syncStatus: SavingsGoalSyncStatus, error: String?) {
        goal.syncStatus = syncStatus.rawValue
        goal.lastSyncError = error
    }

    private func markGoalAsSynced(_ goal: SavingsGoal, remoteUpdatedAt: Date?) {
        goal.syncStatus = SavingsGoalSyncStatus.synced.rawValue
        goal.lastSyncedAt = Date()
        goal.remoteUpdatedAt = remoteUpdatedAt
        goal.lastSyncError = nil
    }

    private func fetchAllLocalGoals(in context: NSManagedObjectContext) -> [SavingsGoal] {
        let request: NSFetchRequest<SavingsGoal> = SavingsGoal.fetchRequest()
        do {
            return try context.fetch(request)
        } catch {
            print("☁️ SupabaseSavingsGoalSyncService: failed fetching local goals (\(error))")
            return []
        }
    }

    private func ensureClientRecordID(for goal: SavingsGoal) -> String {
        if let id = goal.id {
            return id.uuidString
        }

        let id = UUID()
        goal.id = id
        goal.lastModified = goal.lastModified ?? Date()
        goal.syncStatus = goal.syncStatus ?? SavingsGoalSyncStatus.pending.rawValue
        return id.uuidString
    }

    private func mutationTimestamp(for goal: SavingsGoal) -> Date {
        goal.lastModified ?? goal.deletedAt ?? goal.createdAt ?? .distantPast
    }

    private func remoteMutationTimestamp(for row: SupabaseSavingsGoalRow) -> Date {
        row.updatedAt ?? row.deletedAt ?? row.createdAt ?? .distantPast
    }

    private func normalizedName(_ value: String?) -> String {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? "Savings Goal" : trimmed
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

private enum SupabaseSavingsGoalDateCoding {
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

private extension KeyedDecodingContainer where K == SupabaseSavingsGoalRow.CodingKeys {
    func decodeDateOnlyIfPresent(forKey key: K) throws -> Date? {
        guard let value = try decodeIfPresent(String.self, forKey: key), !value.isEmpty else {
            return nil
        }
        return SupabaseSavingsGoalDateCoding.decodeDateOnly(value)
    }

    func decodeTimestampIfPresent(forKey key: K) throws -> Date? {
        guard let value = try decodeIfPresent(String.self, forKey: key), !value.isEmpty else {
            return nil
        }
        return SupabaseSavingsGoalDateCoding.decodeTimestamp(value)
    }
}

private extension KeyedEncodingContainer where K == SupabaseSavingsGoalUpsertPayload.CodingKeys {
    mutating func encodeDateOnlyIfPresent(_ value: Date?, forKey key: K) throws {
        guard let value else { return }
        try encode(SupabaseSavingsGoalDateCoding.encodeDateOnly(value), forKey: key)
    }

    mutating func encodeTimestampIfPresent(_ value: Date?, forKey key: K) throws {
        guard let value else { return }
        try encode(SupabaseSavingsGoalDateCoding.encodeTimestamp(value), forKey: key)
    }
}
