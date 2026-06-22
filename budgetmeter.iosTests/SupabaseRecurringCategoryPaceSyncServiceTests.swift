//
//  SupabaseRecurringCategoryPaceSyncServiceTests.swift
//  budgetmeter.iosTests
//
//  Phase 3C recurring pace FinancialCategory sync tests.
//

import CoreData
import XCTest
@testable import budgetmeter_ios

@MainActor
final class SupabaseRecurringCategoryPaceSyncServiceTests: XCTestCase {
    private var persistence: PersistenceService!
    private var context: NSManagedObjectContext!
    private var remoteStore: MockSupabaseRecurringCategoryPaceRemoteStore!
    private var metadataStore: RecurringCategoryPaceSyncMetadataStore!
    private var userID: UUID!

    override func setUp() {
        super.setUp()
        persistence = PersistenceService.makeInMemoryForTesting()
        context = persistence.viewContext
        remoteStore = MockSupabaseRecurringCategoryPaceRemoteStore()
        metadataStore = RecurringCategoryPaceSyncMetadataStore.shared
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

    func test_mapper_customRecurringCategoryIsEligible() {
        let category = makeCustomRecurringCategory(type: "income", name: "Freelance", frequency: "monthly", amount: 500)
        XCTAssertTrue(RecurringCategoryPaceSyncMapper.isSyncEligible(category, metadata: nil))
    }

    func test_mapper_seededCategoryRequiresPositiveAmountWhenNeverSynced() {
        let category = makeSeededCategory(type: "expense", uniqueID: "rent", frequency: "monthly", amount: 0)
        XCTAssertFalse(RecurringCategoryPaceSyncMapper.isSyncEligible(category, metadata: nil))
    }

    func test_mapper_seededCategoryEligibleWhenAmountPositive() {
        let category = makeSeededCategory(type: "expense", uniqueID: "rent", frequency: "monthly", amount: 1200)
        XCTAssertTrue(RecurringCategoryPaceSyncMapper.isSyncEligible(category, metadata: nil))
    }

    func test_mapper_seededClientRecordIDIncludesFrequency() {
        let category = makeSeededCategory(type: "expense", uniqueID: "rent", frequency: "monthly", amount: 1200)
        XCTAssertEqual(
            RecurringCategoryPaceSyncMapper.clientRecordID(for: category),
            "seed:expense:rent:monthly"
        )
    }

    func test_mapper_customClientRecordIDUsesCategoryID() {
        let category = makeCustomRecurringCategory(type: "income", name: "Side Hustle", frequency: "monthly", amount: 300)
        XCTAssertEqual(
            RecurringCategoryPaceSyncMapper.clientRecordID(for: category),
            category.id?.uuidString
        )
    }

    func test_customCategoryUpload_includesAmountCurrencyAndSourceType() async {
        let category = makeCustomRecurringCategory(type: "income", name: "Side Hustle", frequency: "monthly", amount: 300)
        category.currencyCode = "USD"
        category.lastModified = Date()
        metadataStore.markPending(category, in: context)
        remoteStore.fetchResult = []

        let service = makeService()
        await service.bootstrapSignedInAccount()

        XCTAssertEqual(remoteStore.upsertedPayloads.count, 1)
        let payload = remoteStore.upsertedPayloads.first
        XCTAssertNotNil(payload)
        XCTAssertEqual(payload?.clientRecordID, category.id?.uuidString)
        XCTAssertEqual(payload?.amount, 300)
        XCTAssertEqual(payload?.frequency, "monthly")
        XCTAssertEqual(payload?.currencyCode, "USD")
        XCTAssertEqual(payload?.sourceType, RecurringTransactionSourceType.categoryPace)
        XCTAssertEqual(payload?.categoryType, "income")
    }

    func test_seededCategoryUpload_usesSeedClientRecordID() async {
        let category = makeSeededCategory(type: "expense", uniqueID: "rent", frequency: "monthly", amount: 1500)
        category.lastModified = Date()
        metadataStore.markPending(category, in: context)
        remoteStore.fetchResult = []

        let service = makeService()
        await service.bootstrapSignedInAccount()

        XCTAssertEqual(remoteStore.upsertedPayloads.first?.clientRecordID, "seed:expense:rent:monthly")
        XCTAssertEqual(remoteStore.upsertedPayloads.first?.categoryKey, "rent")
    }

    func test_remoteSeededRow_restoresAmountOnExistingSeededCategory() async {
        let category = makeSeededCategory(type: "expense", uniqueID: "rent", frequency: "monthly", amount: 0)
        _ = persistence.save()

        remoteStore.fetchResult = [
            makeRemoteRow(
                clientRecordID: "seed:expense:rent:monthly",
                title: "Rent",
                amount: 1800,
                categoryType: "expense",
                frequency: "monthly",
                categoryKey: "rent"
            )
        ]

        let service = makeService()
        await service.bootstrapSignedInAccount()

        XCTAssertEqual(category.amount, 1800, accuracy: 0.01)
    }

    func test_automationRemoteRowsAreIgnoredByPaceService() async {
        let category = makeSeededCategory(type: "expense", uniqueID: "rent", frequency: "monthly", amount: 900)
        _ = persistence.save()

        remoteStore.fetchResult = [
            makeRemoteRow(
                clientRecordID: UUID().uuidString,
                title: "Automation",
                amount: 50,
                categoryType: "expense",
                frequency: "monthly",
                sourceType: RecurringTransactionSourceType.automation,
                nextDueDate: Date()
            )
        ]

        let service = makeService()
        await service.bootstrapSignedInAccount()

        XCTAssertEqual(category.amount, 900, accuracy: 0.01)
        XCTAssertTrue(remoteStore.upsertedPayloads.contains { $0.clientRecordID == "seed:expense:rent:monthly" })
    }

    private func makeService() -> SupabaseRecurringCategoryPaceSyncService {
        SupabaseRecurringCategoryPaceSyncService(
            persistenceService: persistence,
            remoteStore: remoteStore,
            metadataStore: metadataStore
        )
    }

    @discardableResult
    private func makeCustomRecurringCategory(
        type: String,
        name: String,
        frequency: String,
        amount: Double
    ) -> FinancialCategory {
        let category = FinancialCategory(context: context)
        category.id = UUID()
        category.type = type
        category.customName = name
        category.frequency = frequency
        category.amount = amount
        category.isCustom = true
        category.uniqueID = "custom_\(UUID().uuidString.lowercased())"
        category.entryKind = FinancialCategoryEntryKind.recurring.rawValue
        category.createdAt = Date()
        category.lastModified = Date()
        category.isActive = true
        return category
    }

    @discardableResult
    private func makeSeededCategory(
        type: String,
        uniqueID: String,
        frequency: String,
        amount: Double
    ) -> FinancialCategory {
        let category = FinancialCategory(context: context)
        category.id = UUID()
        category.type = type
        category.uniqueID = uniqueID
        category.frequency = frequency
        category.amount = amount
        category.isCustom = false
        category.entryKind = FinancialCategoryEntryKind.recurring.rawValue
        category.createdAt = Date()
        category.lastModified = Date()
        category.isActive = true
        return category
    }

    private func makeRemoteRow(
        clientRecordID: String,
        title: String,
        amount: Decimal,
        categoryType: String,
        frequency: String,
        categoryKey: String? = nil,
        sourceType: String = RecurringTransactionSourceType.categoryPace,
        nextDueDate: Date? = nil
    ) -> SupabaseRecurringTransactionRow {
        SupabaseRecurringTransactionRow(
            id: UUID(),
            userID: userID,
            clientRecordID: clientRecordID,
            title: title,
            amount: amount,
            categoryName: title,
            categoryType: categoryType,
            frequency: frequency,
            startDate: Date(),
            endDate: nil,
            nextDueDate: nextDueDate,
            isActive: true,
            notes: nil,
            lastProcessedDate: nil,
            currencyCode: "USD",
            sourceType: sourceType,
            categoryKey: categoryKey,
            createdAt: Date(),
            updatedAt: Date(),
            deletedAt: nil
        )
    }
}

private final class MockSupabaseRecurringCategoryPaceRemoteStore: SupabaseRecurringTransactionRemoteStoreProtocol {
    var currentUserID: UUID?
    var fetchResult: [SupabaseRecurringTransactionRow] = []
    private(set) var upsertedPayloads: [SupabaseRecurringTransactionUpsertPayload] = []

    func currentAuthenticatedUserID() async -> UUID? { currentUserID }

    func fetchRecurringTransactions(userID: UUID) async throws -> [SupabaseRecurringTransactionRow] {
        fetchResult
    }

    func upsertRecurringTransaction(
        _ payload: SupabaseRecurringTransactionUpsertPayload
    ) async throws -> SupabaseRecurringTransactionRow {
        upsertedPayloads.append(payload)
        return SupabaseRecurringTransactionRow(
            id: UUID(),
            userID: payload.userID,
            clientRecordID: payload.clientRecordID,
            title: payload.title,
            amount: payload.amount,
            categoryName: payload.categoryName,
            categoryType: payload.categoryType,
            frequency: payload.frequency,
            startDate: payload.startDate,
            endDate: payload.endDate,
            nextDueDate: payload.nextDueDate,
            isActive: payload.isActive,
            notes: payload.notes,
            lastProcessedDate: payload.lastProcessedDate,
            currencyCode: payload.currencyCode,
            sourceType: payload.sourceType,
            categoryKey: payload.categoryKey,
            createdAt: payload.createdAt,
            updatedAt: Date(),
            deletedAt: payload.deletedAt
        )
    }
}
