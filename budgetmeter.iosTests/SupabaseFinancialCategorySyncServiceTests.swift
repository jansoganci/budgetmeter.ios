//
//  SupabaseFinancialCategorySyncServiceTests.swift
//  budgetmeter.iosTests
//
//  Phase 3B financial category sync tests.
//

import CoreData
import XCTest
@testable import budgetmeter_ios

@MainActor
final class SupabaseFinancialCategorySyncServiceTests: XCTestCase {
    private var persistence: PersistenceService!
    private var context: NSManagedObjectContext!
    private var remoteStore: MockSupabaseFinancialCategoryRemoteStore!
    private var metadataStore: FinancialCategorySyncMetadataStore!
    private var userID: UUID!

    override func setUp() {
        super.setUp()
        persistence = PersistenceService.makeInMemoryForTesting()
        context = persistence.viewContext
        remoteStore = MockSupabaseFinancialCategoryRemoteStore()
        metadataStore = FinancialCategorySyncMetadataStore.shared
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

    func test_mapper_customRecurringIncomeCategoryIsEligible() {
        let category = makeCustomRecurringCategory(type: "income", name: "Freelance", frequency: "monthly")
        XCTAssertTrue(FinancialCategorySyncMapper.isCustomRecurringSyncEligible(category))
    }

    func test_mapper_customRecurringExpenseCategoryIsEligible() {
        let category = makeCustomRecurringCategory(type: "expense", name: "Gym", frequency: "monthly")
        XCTAssertTrue(FinancialCategorySyncMapper.isCustomRecurringSyncEligible(category))
    }

    func test_mapper_oneTimeCategoryIsNotEligibleForCategorySync() {
        let category = makeOneTimeCategory(type: "expense", name: "Repair")
        XCTAssertFalse(FinancialCategorySyncMapper.isCustomRecurringSyncEligible(category))
    }

    func test_mapper_customRecurringWithAutomationSourceRemainsCategoryEligible() {
        let category = makeCustomRecurringCategory(type: "expense", name: "Auto", frequency: "monthly")
        category.sourceType = "recurringAutomation"
        category.sourceID = UUID().uuidString
        XCTAssertTrue(FinancialCategorySyncMapper.isCustomRecurringSyncEligible(category))
    }

    func test_mapper_seededDefaultRowWithoutOverrideIsNotEligible() {
        let category = makeSeededCategory(type: "expense", uniqueID: "food", frequency: "daily")
        XCTAssertFalse(FinancialCategorySyncMapper.isSeededOverrideSyncEligible(category))
    }

    func test_mapper_seededOverrideWithCustomColorIsEligible() {
        let category = makeSeededCategory(type: "expense", uniqueID: "food", frequency: "daily")
        category.customColorHex = "blue"
        XCTAssertTrue(FinancialCategorySyncMapper.isSeededOverrideSyncEligible(category))
    }

    func test_customCategoryUpload_usesClientRecordID() async {
        let category = makeCustomRecurringCategory(type: "income", name: "Side Hustle", frequency: "monthly")
        category.lastModified = Date()
        metadataStore.markCustomPending(category, in: context)
        remoteStore.customFetchResult = []
        remoteStore.overrideFetchResult = []

        let service = makeService()
        await service.bootstrapSignedInAccount()

        XCTAssertEqual(remoteStore.upsertedCustomPayloads.count, 1)
        XCTAssertEqual(remoteStore.upsertedCustomPayloads.first?.clientRecordID, category.id?.uuidString)
        XCTAssertEqual(remoteStore.upsertedCustomPayloads.first?.type, "income")
        XCTAssertEqual(remoteStore.upsertedCustomPayloads.first?.name, "Side Hustle")
    }

    func test_seededOverrideUpload_usesCategoryKey() async {
        let category = makeSeededCategory(type: "expense", uniqueID: "rent", frequency: "monthly")
        category.customIconName = "house.fill"
        category.lastModified = Date()
        metadataStore.markSeededOverridePending(category, in: context)
        remoteStore.customFetchResult = []
        remoteStore.overrideFetchResult = []

        let service = makeService()
        await service.bootstrapSignedInAccount()

        XCTAssertEqual(remoteStore.upsertedOverridePayloads.count, 1)
        XCTAssertEqual(remoteStore.upsertedOverridePayloads.first?.categoryKey, "rent")
        XCTAssertEqual(remoteStore.upsertedOverridePayloads.first?.type, "expense")
    }

    func test_remoteCustomCategory_createsLocalRow() async {
        let clientRecordID = UUID().uuidString
        remoteStore.customFetchResult = [
            makeCustomRemoteRow(
                clientRecordID: clientRecordID,
                type: "expense",
                name: "Pets",
                updatedAt: Date()
            )
        ]
        remoteStore.overrideFetchResult = []

        let service = makeService()
        await service.bootstrapSignedInAccount()

        let request: NSFetchRequest<FinancialCategory> = FinancialCategory.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", UUID(uuidString: clientRecordID)! as CVarArg)
        let restored = try? context.fetch(request).first

        XCTAssertNotNil(restored)
        XCTAssertEqual(restored?.customName, "Pets")
        XCTAssertTrue(restored?.isCustom == true)
        XCTAssertTrue(FinancialCategoryWriteSupport.isRecurringDisplayCategory(restored!))
    }

    func test_seededRemoteOverride_doesNotDuplicateSeededCatalogRows() async {
        _ = makeSeededCategory(type: "expense", uniqueID: "food", frequency: "daily")
        _ = makeSeededCategory(type: "expense", uniqueID: "food", frequency: "monthly")
        _ = persistence.save()

        remoteStore.customFetchResult = []
        remoteStore.overrideFetchResult = [
            makeOverrideRemoteRow(categoryKey: "food", type: "expense", customColorHex: "red", updatedAt: Date())
        ]

        let service = makeService()
        await service.bootstrapSignedInAccount()

        let request: NSFetchRequest<FinancialCategory> = FinancialCategory.fetchRequest()
        request.predicate = NSPredicate(format: "isCustom == NO AND uniqueID == %@", "food")
        let foodRows = (try? context.fetch(request)) ?? []

        XCTAssertEqual(foodRows.count, 2)
        XCTAssertTrue(foodRows.allSatisfy { $0.customColorHex == "red" })
    }

    func test_oneTimeRowsAreNotUploadedAsCategories() async {
        let oneTime = makeOneTimeCategory(type: "income", name: "Bonus")
        oneTime.lastModified = Date()
        OneTimeTransactionSyncMetadataStore.shared.markPending(oneTime, in: context)
        remoteStore.customFetchResult = []
        remoteStore.overrideFetchResult = []

        let service = makeService()
        await service.bootstrapSignedInAccount()

        XCTAssertTrue(remoteStore.upsertedCustomPayloads.isEmpty)
        XCTAssertTrue(remoteStore.upsertedOverridePayloads.isEmpty)
    }

    func test_recurringTransactionRowsAreNotUploadedAsCategories() async {
        let recurring = RecurringTransaction(context: context)
        recurring.id = UUID()
        recurring.title = "Rent"
        recurring.amount = 1000
        recurring.categoryType = "expense"
        recurring.frequency = "monthly"
        recurring.isActive = true
        recurring.createdAt = Date()
        recurring.lastModified = Date()
        _ = persistence.save()

        remoteStore.customFetchResult = []
        remoteStore.overrideFetchResult = []

        let service = makeService()
        await service.bootstrapSignedInAccount()

        XCTAssertTrue(remoteStore.upsertedCustomPayloads.isEmpty)
        XCTAssertTrue(remoteStore.upsertedOverridePayloads.isEmpty)
    }

    func test_customCategoryTombstone_setsDeletedAtOnPayload() async {
        let category = makeCustomRecurringCategory(type: "expense", name: "Coffee", frequency: "daily")
        metadataStore.tombstoneCustomCategory(category, in: context)
        category.lastModified = Date()
        _ = persistence.save()
        remoteStore.customFetchResult = []
        remoteStore.overrideFetchResult = []

        let service = makeService()
        await service.bootstrapSignedInAccount()

        XCTAssertEqual(remoteStore.upsertedCustomPayloads.count, 1)
        XCTAssertNotNil(remoteStore.upsertedCustomPayloads.first?.deletedAt)
    }

    func test_supabaseFailure_keepsLocalCustomCategory() async {
        let category = makeCustomRecurringCategory(type: "income", name: "Bonus Lane", frequency: "yearly")
        category.lastModified = Date()
        metadataStore.markCustomPending(category, in: context)
        remoteStore.customFetchResult = []
        remoteStore.overrideFetchResult = []
        remoteStore.customUpsertError = MockCategorySyncError.network

        let service = makeService()
        await service.bootstrapSignedInAccount()

        let metadata = metadataStore.metadata(forCustom: category, in: context)
        XCTAssertEqual(metadata.syncStatus, FinancialCategorySyncStatus.failed.rawValue)
        XCTAssertEqual(category.customName, "Bonus Lane")
    }

    func test_duplicateCustomCategoryPrevention_matchesByClientRecordID() async {
        let clientRecordID = UUID().uuidString
        let local = makeCustomRecurringCategory(
            id: UUID(uuidString: clientRecordID)!,
            type: "expense",
            name: "Local Name",
            frequency: "monthly"
        )
        local.lastModified = Date().addingTimeInterval(-3600)
        metadataStore.markCustomPending(local, in: context)

        remoteStore.customFetchResult = [
            makeCustomRemoteRow(
                clientRecordID: clientRecordID,
                type: "expense",
                name: "Remote Name",
                updatedAt: Date()
            )
        ]
        remoteStore.overrideFetchResult = []

        let service = makeService()
        await service.bootstrapSignedInAccount()

        let request: NSFetchRequest<FinancialCategory> = FinancialCategory.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", UUID(uuidString: clientRecordID)! as CVarArg)
        let rows = try? context.fetch(request)

        XCTAssertEqual(rows?.count, 1)
        XCTAssertEqual(rows?.first?.customName, "Remote Name")
    }

    private func makeService() -> SupabaseFinancialCategorySyncService {
        SupabaseFinancialCategorySyncService(
            persistenceService: persistence,
            remoteStore: remoteStore,
            metadataStore: metadataStore
        )
    }

    @discardableResult
    private func makeCustomRecurringCategory(
        id: UUID = UUID(),
        type: String,
        name: String,
        frequency: String
    ) -> FinancialCategory {
        let category = FinancialCategory(context: context)
        category.id = id
        category.type = type
        category.customName = name
        category.isCustom = true
        category.uniqueID = "custom_\(UUID().uuidString.lowercased())"
        category.createdAt = Date()
        category.lastModified = Date()
        FinancialCategoryWriteSupport.applyMetadata(
            to: category,
            entryKind: .recurring,
            recurringFrequency: frequency
        )
        return category
    }

    @discardableResult
    private func makeSeededCategory(type: String, uniqueID: String, frequency: String) -> FinancialCategory {
        let category = FinancialCategory(context: context)
        category.id = UUID()
        category.type = type
        category.uniqueID = uniqueID
        category.isCustom = false
        category.frequency = frequency
        category.entryKind = FinancialCategoryEntryKind.recurring.rawValue
        category.isActive = true
        category.createdAt = Date()
        category.lastModified = Date()
        return category
    }

    @discardableResult
    private func makeOneTimeCategory(type: String, name: String) -> FinancialCategory {
        let category = FinancialCategory(context: context)
        category.id = UUID()
        category.type = type
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

    private func makeCustomRemoteRow(
        clientRecordID: String,
        type: String,
        name: String,
        updatedAt: Date,
        deletedAt: Date? = nil
    ) -> SupabaseCustomFinancialCategoryRow {
        SupabaseCustomFinancialCategoryRow(
            id: UUID(),
            userID: userID,
            clientRecordID: clientRecordID,
            type: type,
            name: name,
            iconName: "tag.fill",
            colorHex: "blue",
            isActive: deletedAt == nil,
            sortOrder: nil,
            createdAt: updatedAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt
        )
    }

    private func makeOverrideRemoteRow(
        categoryKey: String,
        type: String,
        customColorHex: String?,
        updatedAt: Date
    ) -> SupabaseSeededCategoryOverrideRow {
        SupabaseSeededCategoryOverrideRow(
            id: UUID(),
            userID: userID,
            categoryKey: categoryKey,
            type: type,
            customLabel: nil,
            customIconName: nil,
            customColorHex: customColorHex,
            isHidden: false,
            sortOrder: nil,
            createdAt: updatedAt,
            updatedAt: updatedAt,
            deletedAt: nil
        )
    }
}

private enum MockCategorySyncError: Error {
    case network
}

private final class MockSupabaseFinancialCategoryRemoteStore: SupabaseFinancialCategoryRemoteStoreProtocol {
    var currentUserID: UUID?
    var customFetchResult: [SupabaseCustomFinancialCategoryRow] = []
    var overrideFetchResult: [SupabaseSeededCategoryOverrideRow] = []
    var customUpsertError: Error?
    var overrideUpsertError: Error?
    private(set) var upsertedCustomPayloads: [SupabaseCustomFinancialCategoryUpsertPayload] = []
    private(set) var upsertedOverridePayloads: [SupabaseSeededCategoryOverrideUpsertPayload] = []

    func currentAuthenticatedUserID() async -> UUID? {
        currentUserID
    }

    func fetchCustomCategories(userID: UUID) async throws -> [SupabaseCustomFinancialCategoryRow] {
        customFetchResult
    }

    func fetchSeededCategoryOverrides(userID: UUID) async throws -> [SupabaseSeededCategoryOverrideRow] {
        overrideFetchResult
    }

    func upsertCustomCategory(_ payload: SupabaseCustomFinancialCategoryUpsertPayload) async throws -> SupabaseCustomFinancialCategoryRow {
        if let customUpsertError {
            throw customUpsertError
        }
        upsertedCustomPayloads.append(payload)
        return SupabaseCustomFinancialCategoryRow(
            id: UUID(),
            userID: payload.userID,
            clientRecordID: payload.clientRecordID,
            type: payload.type,
            name: payload.name,
            iconName: payload.iconName,
            colorHex: payload.colorHex,
            isActive: payload.isActive,
            sortOrder: payload.sortOrder,
            createdAt: payload.createdAt,
            updatedAt: Date(),
            deletedAt: payload.deletedAt
        )
    }

    func upsertSeededCategoryOverride(_ payload: SupabaseSeededCategoryOverrideUpsertPayload) async throws -> SupabaseSeededCategoryOverrideRow {
        if let overrideUpsertError {
            throw overrideUpsertError
        }
        upsertedOverridePayloads.append(payload)
        return SupabaseSeededCategoryOverrideRow(
            id: UUID(),
            userID: payload.userID,
            categoryKey: payload.categoryKey,
            type: payload.type,
            customLabel: payload.customLabel,
            customIconName: payload.customIconName,
            customColorHex: payload.customColorHex,
            isHidden: payload.isHidden,
            sortOrder: payload.sortOrder,
            createdAt: payload.createdAt,
            updatedAt: Date(),
            deletedAt: payload.deletedAt
        )
    }
}
