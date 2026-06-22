//
//  RecordCurrencyCodeTests.swift
//  budgetmeter.iosTests
//
//  Row-level currency_code stamping, sync payloads, and backfill tests.
//

import CoreData
import XCTest
@testable import budgetmeter_ios

@MainActor
final class RecordCurrencyCodeTests: XCTestCase {
    private var persistence: PersistenceService!
    private var context: NSManagedObjectContext!

    override func setUp() {
        super.setUp()
        persistence = PersistenceService.makeInMemoryForTesting()
        context = persistence.viewContext
        seedAppSettings(currencyCode: "EUR")
    }

    override func tearDown() {
        persistence = nil
        context = nil
        super.tearDown()
    }

    func test_createGoal_stampsCurrentPreferredCurrency() {
        let manager = SavingsGoalManager(persistence: persistence, syncService: SavingsGoalSyncSpy())
        let goal = manager.createGoal(name: "Trip", targetAmount: 500)

        XCTAssertEqual(goal?.currencyCode, "EUR")
    }

    func test_changingPreferredCurrency_doesNotRewriteExistingGoal() {
        let manager = SavingsGoalManager(persistence: persistence, syncService: SavingsGoalSyncSpy())
        let goal = try! XCTUnwrap(manager.createGoal(name: "Trip", targetAmount: 500))
        goal.currencyCode = "GBP"

        seedAppSettings(currencyCode: "TRY")

        XCTAssertEqual(goal.currencyCode, "GBP")
    }

    func test_savingsGoalSyncPayload_includesCurrencyCode() async {
        let remoteStore = RecordCurrencySavingsGoalRemoteStore()
        remoteStore.currentUserID = UUID()
        let goal = SavingsGoal(context: context)
        goal.id = UUID()
        goal.name = "Emergency"
        goal.targetAmount = 1000
        goal.currentAmount = 100
        goal.currencyCode = "GBP"
        goal.createdAt = Date()
        goal.lastModified = Date()
        goal.syncStatus = SavingsGoalSyncStatus.pending.rawValue
        _ = persistence.save()
        remoteStore.fetchResult = []

        let service = SupabaseSavingsGoalSyncService(
            persistenceService: persistence,
            remoteStore: remoteStore
        )
        await service.bootstrapSignedInAccount()

        XCTAssertEqual(remoteStore.upsertedPayloads.first?.currencyCode, "GBP")
    }

    func test_remoteRestore_writesLocalCurrencyCode() async {
        let userID = UUID()
        let clientRecordID = UUID().uuidString
        let remoteStore = RecordCurrencySavingsGoalRemoteStore()
        remoteStore.currentUserID = userID
        remoteStore.fetchResult = [
            SupabaseSavingsGoalRow(
                id: UUID(),
                userID: userID,
                clientRecordID: clientRecordID,
                name: "House",
                targetAmount: 100_000,
                currentAmount: 10_000,
                targetDate: nil,
                emoji: nil,
                colorHex: nil,
                priority: 0,
                isArchived: false,
                archivedDate: nil,
                completedDate: nil,
                notes: nil,
                categoryLabel: nil,
                monthlyContribution: nil,
                currencyCode: "JPY",
                createdAt: Date(),
                updatedAt: Date(),
                deletedAt: nil
            )
        ]

        let service = SupabaseSavingsGoalSyncService(
            persistenceService: persistence,
            remoteStore: remoteStore
        )
        await service.bootstrapSignedInAccount()

        let request: NSFetchRequest<SavingsGoal> = SavingsGoal.fetchRequest()
        let goal = try? context.fetch(request).first
        XCTAssertEqual(goal?.currencyCode, "JPY")
    }

    func test_migrationBackfill_preservesExistingRowsWithoutOverwrite() {
        let defaults = UserDefaults(suiteName: "RecordCurrencyCodeTests.migration")!
        defaults.removePersistentDomain(forName: "RecordCurrencyCodeTests.migration")

        let goal = SavingsGoal(context: context)
        goal.id = UUID()
        goal.name = "Legacy"
        goal.targetAmount = 100
        goal.currentAmount = 0
        goal.currencyCode = "CHF"
        _ = persistence.save()

        let migration = FinancialDataMigrationService(
            persistenceService: persistence,
            userDefaults: defaults,
            savingsGoalManager: SavingsGoalManager(persistence: persistence, syncService: SavingsGoalSyncSpy())
        )
        migration.performMigrationIfNeeded()

        XCTAssertEqual(goal.currencyCode, "CHF")
    }

    func test_fallbackDisplayCode_usesPreferredCurrencyForLegacyRows() {
        let goal = SavingsGoal(context: context)
        goal.currencyCode = nil

        XCTAssertEqual(
            RecordCurrencySupport.resolvedDisplayCode(storedCode: goal.currencyCode, in: context),
            "EUR"
        )
    }

    func test_oneTimeMetadata_stampsCurrencyOnApplyMetadata() {
        let category = FinancialCategory(context: context)
        category.id = UUID()
        category.type = "expense"
        category.amount = 50
        category.isCustom = true

        FinancialCategoryWriteSupport.applyMetadata(
            to: category,
            entryKind: .oneTime,
            recurringFrequency: "monthly"
        )

        XCTAssertEqual(category.currencyCode, "EUR")
    }

    private func seedAppSettings(currencyCode: String) {
        let request: NSFetchRequest<AppSettings> = AppSettings.fetchRequest()
        let settings = (try? context.fetch(request).first) ?? AppSettings(context: context)
        settings.preferredCurrencyCode = currencyCode
        _ = persistence.save()
    }
}

private final class SavingsGoalSyncSpy: SavingsGoalSyncScheduling {
    func scheduleSync() {}
    func bootstrapSignedInAccount() async {}
}

private final class RecordCurrencySavingsGoalRemoteStore: SupabaseSavingsGoalRemoteStoreProtocol {
    var currentUserID: UUID?
    var fetchResult: [SupabaseSavingsGoalRow] = []
    private(set) var upsertedPayloads: [SupabaseSavingsGoalUpsertPayload] = []

    func currentAuthenticatedUserID() async -> UUID? { currentUserID }

    func fetchSavingsGoals(userID: UUID) async throws -> [SupabaseSavingsGoalRow] {
        fetchResult
    }

    func upsertSavingsGoal(_ payload: SupabaseSavingsGoalUpsertPayload) async throws -> SupabaseSavingsGoalRow {
        upsertedPayloads.append(payload)
        return SupabaseSavingsGoalRow(
            id: UUID(),
            userID: payload.userID,
            clientRecordID: payload.clientRecordID,
            name: payload.name,
            targetAmount: payload.targetAmount,
            currentAmount: payload.currentAmount,
            targetDate: payload.targetDate,
            emoji: payload.emoji,
            colorHex: payload.colorHex,
            priority: payload.priority,
            isArchived: payload.isArchived,
            archivedDate: payload.archivedDate,
            completedDate: payload.completedDate,
            notes: payload.notes,
            categoryLabel: payload.categoryLabel,
            monthlyContribution: payload.monthlyContribution,
            currencyCode: payload.currencyCode,
            createdAt: payload.createdAt ?? Date(),
            updatedAt: Date(),
            deletedAt: payload.deletedAt
        )
    }
}
