//
//  SupabaseOneTimeTransactionSyncServiceTests.swift
//  budgetmeter.iosTests
//
//  Phase 3A one-time transaction sync tests.
//

import CoreData
import XCTest
@testable import budgetmeter_ios

@MainActor
final class SupabaseOneTimeTransactionSyncServiceTests: XCTestCase {
    private var persistence: PersistenceService!
    private var context: NSManagedObjectContext!
    private var remoteStore: MockSupabaseOneTimeTransactionRemoteStore!
    private var metadataStore: OneTimeTransactionSyncMetadataStore!
    private var userID: UUID!

    override func setUp() {
        super.setUp()
        persistence = PersistenceService.makeInMemoryForTesting()
        context = persistence.viewContext
        remoteStore = MockSupabaseOneTimeTransactionRemoteStore()
        metadataStore = OneTimeTransactionSyncMetadataStore.shared
        userID = UUID()
        remoteStore.currentUserID = userID
    }

    override func tearDown() {
        persistence = nil
        context = nil
        remoteStore = nil
        metadataStore = nil
        userID = nil
        super.tearDown()
    }

    func test_mapper_incomeOneTimeRowIsEligible() {
        let category = makeOneTimeCategory(type: "income", name: "Bonus", amount: 250)

        XCTAssertTrue(OneTimeTransactionSyncMapper.isSyncEligible(category))
        XCTAssertEqual(OneTimeTransactionSyncMapper.resolvedCategoryLabel(for: category), "Bonus")
    }

    func test_mapper_expenseOneTimeRowIsEligible() {
        let category = makeOneTimeCategory(type: "expense", name: "Repair", amount: 80)

        XCTAssertTrue(OneTimeTransactionSyncMapper.isSyncEligible(category))
    }

    func test_mapper_recurringCategoryIsNotEligible() {
        let category = FinancialCategory(context: context)
        category.id = UUID()
        category.type = "income"
        category.frequency = "monthly"
        category.entryKind = "recurring"
        category.amount = 1000
        category.customName = "Salary"
        category.isCustom = true

        XCTAssertFalse(OneTimeTransactionSyncMapper.isSyncEligible(category))
    }

    func test_payloadMapping_incomeUsesClientRecordID() async {
        let category = makeOneTimeCategory(type: "income", name: "Bonus", amount: 250)
        category.lastModified = Date()
        metadataStore.markPending(category, in: context)
        remoteStore.fetchResult = []

        let service = makeService()
        await service.bootstrapSignedInAccount()

        XCTAssertEqual(remoteStore.upsertedPayloads.count, 1)
        XCTAssertEqual(remoteStore.upsertedPayloads.first?.clientRecordID, category.id?.uuidString)
        XCTAssertEqual(remoteStore.upsertedPayloads.first?.type, "income")
        XCTAssertEqual(remoteStore.upsertedPayloads.first?.categoryLabel, "Bonus")
    }

    func test_payloadMapping_expenseUsesClientRecordID() async {
        let category = makeOneTimeCategory(type: "expense", name: "Repair", amount: 80)
        category.lastModified = Date()
        metadataStore.markPending(category, in: context)
        remoteStore.fetchResult = []

        let service = makeService()
        await service.bootstrapSignedInAccount()

        XCTAssertEqual(remoteStore.upsertedPayloads.first?.type, "expense")
        XCTAssertEqual(remoteStore.upsertedPayloads.first?.categoryLabel, "Repair")
    }

    func test_remoteRow_createsLocalFinancialCategory() async {
        let clientRecordID = UUID().uuidString
        remoteStore.fetchResult = [
            makeRemoteRow(
                clientRecordID: clientRecordID,
                type: "income",
                amount: 500,
                categoryLabel: "Gift",
                updatedAt: Date()
            )
        ]

        let service = makeService()
        await service.bootstrapSignedInAccount()

        let request: NSFetchRequest<FinancialCategory> = FinancialCategory.fetchRequest()
        let categories = try? context.fetch(request)
        XCTAssertEqual(categories?.count, 1)
        XCTAssertEqual(categories?.first?.id?.uuidString, clientRecordID)
        XCTAssertEqual(categories?.first?.customName, "Gift")
        XCTAssertTrue(FinancialCategoryWriteSupport.isOneTimeDisplayCategory(categories!.first!))
    }

    func test_duplicatePrevention_usesClientRecordID() async {
        let id = UUID()
        let category = makeOneTimeCategory(id: id, type: "income", name: "Bonus", amount: 100)
        category.lastModified = Date(timeIntervalSince1970: 100)
        metadataStore.markSynced(
            clientRecordID: id.uuidString,
            remoteUpdatedAt: Date(timeIntervalSince1970: 500),
            in: context
        )
        _ = persistence.save()

        remoteStore.fetchResult = [
            makeRemoteRow(
                clientRecordID: id.uuidString,
                type: "income",
                amount: 100,
                categoryLabel: "Bonus",
                updatedAt: Date(timeIntervalSince1970: 500)
            )
        ]

        let service = makeService()
        await service.bootstrapSignedInAccount()

        let request: NSFetchRequest<FinancialCategory> = FinancialCategory.fetchRequest()
        let categories = try? context.fetch(request)
        XCTAssertEqual(categories?.count, 1)
        XCTAssertEqual(remoteStore.upsertedPayloads.count, 0)
    }

    func test_localUpdate_marksPendingAndUploads() async {
        let category = makeOneTimeCategory(type: "income", name: "Bonus", amount: 100)
        category.lastModified = Date()
        _ = persistence.save()

        let service = makeService()
        service.registerLocalOneTimeRow(category)

        let metadata = metadataStore.metadata(for: category, in: context)
        XCTAssertEqual(metadata.syncStatus, OneTimeTransactionSyncStatus.pending.rawValue)
    }

    func test_localDelete_usesTombstoneInsteadOfHardDelete() {
        let category = makeOneTimeCategory(type: "expense", name: "Repair", amount: 50)
        _ = persistence.save()

        let service = makeService()
        service.tombstoneLocalOneTimeRow(category)

        let request: NSFetchRequest<FinancialCategory> = FinancialCategory.fetchRequest()
        let stored = try? context.fetch(request).first
        XCTAssertNotNil(stored)
        XCTAssertFalse(stored?.isActive ?? true)
        let metadata = metadataStore.metadata(for: category, in: context)
        XCTAssertNotNil(metadata.deletedAt)
        XCTAssertEqual(metadata.syncStatus, OneTimeTransactionSyncStatus.pending.rawValue)
    }

    func test_remoteDeletedAt_hidesLocalRowViaTombstone() async {
        let id = UUID()
        let category = makeOneTimeCategory(id: id, type: "expense", name: "Repair", amount: 50)
        category.lastModified = Date(timeIntervalSince1970: 100)
        metadataStore.markSynced(clientRecordID: id.uuidString, remoteUpdatedAt: Date(timeIntervalSince1970: 100), in: context)
        _ = persistence.save()

        remoteStore.fetchResult = [
            makeRemoteRow(
                clientRecordID: id.uuidString,
                type: "expense",
                amount: 50,
                categoryLabel: "Repair",
                updatedAt: Date(timeIntervalSince1970: 500),
                deletedAt: Date(timeIntervalSince1970: 500)
            )
        ]

        let service = makeService()
        await service.bootstrapSignedInAccount()

        XCTAssertTrue(metadataStore.isTombstoned(category, in: context))
        XCTAssertFalse(category.isActive)
    }

    func test_supabaseFailure_keepsLocalDataAndMarksFailed() async {
        let category = makeOneTimeCategory(type: "income", name: "Bonus", amount: 100)
        category.lastModified = Date()
        metadataStore.markPending(category, in: context)
        remoteStore.fetchResult = []
        remoteStore.upsertError = MockOneTimeSyncError.network

        let service = makeService()
        await service.bootstrapSignedInAccount()

        let metadata = metadataStore.metadata(for: category, in: context)
        XCTAssertEqual(metadata.syncStatus, OneTimeTransactionSyncStatus.failed.rawValue)
        XCTAssertEqual(category.amount, 100)
    }

    func test_bootstrap_withoutAuthenticatedUser_doesNotCrash() async {
        remoteStore.currentUserID = nil
        let service = makeService()
        await service.bootstrapSignedInAccount()
        XCTAssertTrue(remoteStore.upsertedPayloads.isEmpty)
    }

    func test_tombstoneUpload_setsDeletedAtOnPayload() async {
        let category = makeOneTimeCategory(type: "expense", name: "Repair", amount: 40)
        metadataStore.tombstone(category, in: context)
        category.lastModified = Date()
        _ = persistence.save()
        remoteStore.fetchResult = []

        let service = makeService()
        await service.bootstrapSignedInAccount()

        XCTAssertEqual(remoteStore.upsertedPayloads.count, 1)
        XCTAssertNotNil(remoteStore.upsertedPayloads.first?.deletedAt)
    }

    private func makeService() -> SupabaseOneTimeTransactionSyncService {
        SupabaseOneTimeTransactionSyncService(
            persistenceService: persistence,
            remoteStore: remoteStore,
            metadataStore: metadataStore
        )
    }

    @discardableResult
    private func makeOneTimeCategory(
        id: UUID = UUID(),
        type: String,
        name: String,
        amount: Double
    ) -> FinancialCategory {
        let category = FinancialCategory(context: context)
        category.id = id
        category.type = type
        category.amount = amount
        category.customName = name
        category.isCustom = true
        category.uniqueID = "custom_\(UUID().uuidString.lowercased())"
        category.createdAt = Date()
        category.lastModified = Date()
        FinancialCategoryWriteSupport.applyMetadata(
            to: category,
            entryKind: .oneTime,
            recurringFrequency: "once",
            occurrenceDate: Date()
        )
        return category
    }

    private func makeRemoteRow(
        clientRecordID: String,
        type: String,
        amount: Decimal,
        categoryLabel: String,
        updatedAt: Date,
        deletedAt: Date? = nil
    ) -> SupabaseOneTimeTransactionRow {
        SupabaseOneTimeTransactionRow(
            id: UUID(),
            userID: userID,
            clientRecordID: clientRecordID,
            type: type,
            amount: amount,
            occurrenceDate: Date(),
            categoryKey: nil,
            categoryLabel: categoryLabel,
            customIconName: nil,
            customColorHex: nil,
            sourceType: nil,
            sourceClientRecordID: nil,
            notes: nil,
            createdAt: updatedAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt
        )
    }
}

private enum MockOneTimeSyncError: Error {
    case network
}

private final class MockSupabaseOneTimeTransactionRemoteStore: SupabaseOneTimeTransactionRemoteStoreProtocol {
    var currentUserID: UUID?
    var fetchResult: [SupabaseOneTimeTransactionRow] = []
    var upsertError: Error?
    private(set) var upsertedPayloads: [SupabaseOneTimeTransactionUpsertPayload] = []

    func currentAuthenticatedUserID() async -> UUID? {
        currentUserID
    }

    func fetchOneTimeTransactions(userID: UUID) async throws -> [SupabaseOneTimeTransactionRow] {
        fetchResult
    }

    func upsertOneTimeTransaction(_ payload: SupabaseOneTimeTransactionUpsertPayload) async throws -> SupabaseOneTimeTransactionRow {
        if let upsertError {
            throw upsertError
        }
        upsertedPayloads.append(payload)
        return SupabaseOneTimeTransactionRow(
            id: UUID(),
            userID: payload.userID,
            clientRecordID: payload.clientRecordID,
            type: payload.type,
            amount: payload.amount,
            occurrenceDate: payload.occurrenceDate,
            categoryKey: payload.categoryKey,
            categoryLabel: payload.categoryLabel,
            customIconName: payload.customIconName,
            customColorHex: payload.customColorHex,
            sourceType: payload.sourceType,
            sourceClientRecordID: payload.sourceClientRecordID,
            notes: payload.notes,
            createdAt: payload.createdAt,
            updatedAt: Date(),
            deletedAt: payload.deletedAt
        )
    }
}
