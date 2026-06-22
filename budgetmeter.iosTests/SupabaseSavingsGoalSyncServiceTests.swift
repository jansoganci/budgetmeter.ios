//
//  SupabaseSavingsGoalSyncServiceTests.swift
//  budgetmeter.iosTests
//
//  Phase 2B savings goal sync tests.
//

import CoreData
import XCTest
@testable import budgetmeter_ios

@MainActor
final class SupabaseSavingsGoalSyncServiceTests: XCTestCase {
    private var persistence: PersistenceService!
    private var context: NSManagedObjectContext!
    private var remoteStore: MockSupabaseSavingsGoalRemoteStore!
    private var userID: UUID!

    override func setUp() {
        super.setUp()
        persistence = PersistenceService.makeInMemoryForTesting()
        context = persistence.viewContext
        remoteStore = MockSupabaseSavingsGoalRemoteStore()
        userID = UUID()
        remoteStore.currentUserID = userID
    }

    override func tearDown() {
        persistence = nil
        context = nil
        remoteStore = nil
        userID = nil
        super.tearDown()
    }

    func test_createGoal_marksPending_andSchedulesSync() {
        let syncSpy = SavingsGoalSyncSpy()
        let manager = SavingsGoalManager(persistence: persistence, syncService: syncSpy)

        let goal = manager.createGoal(name: "Trip", targetAmount: 1200, currentAmount: 100)

        XCTAssertEqual(goal?.syncStatus, SavingsGoalSyncStatus.pending.rawValue)
        XCTAssertNil(goal?.lastSyncedAt)
        XCTAssertEqual(syncSpy.scheduleSyncCount, 1)
    }

    func test_deleteGoal_usesTombstoneInsteadOfHardDelete() {
        let syncSpy = SavingsGoalSyncSpy()
        let manager = SavingsGoalManager(persistence: persistence, syncService: syncSpy)
        let goal = try! XCTUnwrap(manager.createGoal(name: "Laptop", targetAmount: 2000))
        let goalID = try! XCTUnwrap(goal.id)

        XCTAssertTrue(manager.deleteGoal(id: goalID))

        let request: NSFetchRequest<SavingsGoal> = SavingsGoal.fetchRequest()
        let storedGoal = try? context.fetch(request).first
        XCTAssertNotNil(storedGoal)
        XCTAssertNotNil(storedGoal?.deletedAt)
        XCTAssertEqual(storedGoal?.syncStatus, SavingsGoalSyncStatus.pending.rawValue)
        XCTAssertEqual(syncSpy.scheduleSyncCount, 2)
    }

    func test_archiveAndComplete_markPending() {
        let syncSpy = SavingsGoalSyncSpy()
        let manager = SavingsGoalManager(persistence: persistence, syncService: syncSpy)
        let goal = try! XCTUnwrap(manager.createGoal(name: "Emergency", targetAmount: 5000, currentAmount: 300))
        let goalID = try! XCTUnwrap(goal.id)

        XCTAssertTrue(manager.archiveGoal(id: goalID))
        XCTAssertEqual(goal.syncStatus, SavingsGoalSyncStatus.pending.rawValue)
        XCTAssertNotNil(goal.archivedDate)

        XCTAssertTrue(manager.unarchiveGoal(id: goalID))
        XCTAssertEqual(goal.syncStatus, SavingsGoalSyncStatus.pending.rawValue)

        XCTAssertTrue(manager.markAsCompleted(id: goalID))
        XCTAssertEqual(goal.syncStatus, SavingsGoalSyncStatus.pending.rawValue)
        XCTAssertNotNil(goal.completedDate)
    }

    func test_localGoal_uploadsWhenRemoteIsEmpty() async {
        let goal = makeLocalGoal(
            id: UUID(),
            name: "Vacation",
            targetAmount: 2500,
            currentAmount: 400,
            syncStatus: .pending
        )
        goal.lastModified = Date()
        remoteStore.fetchResult = []

        let service = makeService()
        await service.bootstrapSignedInAccount()

        XCTAssertEqual(remoteStore.upsertedPayloads.count, 1)
        XCTAssertEqual(remoteStore.upsertedPayloads.first?.clientRecordID, goal.id?.uuidString)
        XCTAssertEqual(goal.syncStatus, SavingsGoalSyncStatus.synced.rawValue)
        XCTAssertNotNil(goal.lastSyncedAt)
        XCTAssertNotNil(goal.remoteUpdatedAt)
    }

    func test_remoteGoal_createsLocalWhenLocalStoreIsEmpty() async {
        let clientRecordID = UUID().uuidString
        remoteStore.fetchResult = [
            makeRemoteRow(
                clientRecordID: clientRecordID,
                name: "House",
                targetAmount: 100_000,
                currentAmount: 15_000,
                isArchived: true,
                completedDate: Date(),
                updatedAt: Date()
            )
        ]

        let service = makeService()
        await service.bootstrapSignedInAccount()

        let request: NSFetchRequest<SavingsGoal> = SavingsGoal.fetchRequest()
        let goals = try? context.fetch(request)
        XCTAssertEqual(goals?.count, 1)
        XCTAssertEqual(goals?.first?.id?.uuidString, clientRecordID)
        XCTAssertEqual(goals?.first?.name, "House")
        XCTAssertEqual(goals?.first?.isArchived, true)
        XCTAssertNotNil(goals?.first?.completedDate)
        XCTAssertEqual(goals?.first?.syncStatus, SavingsGoalSyncStatus.synced.rawValue)
    }

    func test_duplicatePrevention_usesClientRecordID() async {
        let id = UUID()
        _ = makeLocalGoal(id: id, name: "Trip", targetAmount: 3000, currentAmount: 500, syncStatus: .synced)
        remoteStore.fetchResult = [
            makeRemoteRow(
                clientRecordID: id.uuidString,
                name: "Trip Updated",
                targetAmount: 3500,
                currentAmount: 750,
                updatedAt: Date().addingTimeInterval(60)
            )
        ]

        let service = makeService()
        await service.bootstrapSignedInAccount()

        let request: NSFetchRequest<SavingsGoal> = SavingsGoal.fetchRequest()
        let goals = try? context.fetch(request)
        XCTAssertEqual(goals?.count, 1)
        XCTAssertEqual(goals?.first?.name, "Trip Updated")
        XCTAssertEqual(goals?.first?.targetAmount, 3500)
    }

    func test_bothExist_prefersRemoteWhenRemoteIsNewer() async {
        let id = UUID()
        let localGoal = makeLocalGoal(
            id: id,
            name: "Camera",
            targetAmount: 1200,
            currentAmount: 100,
            syncStatus: .synced
        )
        localGoal.lastModified = Date(timeIntervalSince1970: 100)
        remoteStore.fetchResult = [
            makeRemoteRow(
                clientRecordID: id.uuidString,
                name: "Camera Updated",
                targetAmount: 1500,
                currentAmount: 250,
                updatedAt: Date(timeIntervalSince1970: 200)
            )
        ]

        let service = makeService()
        await service.bootstrapSignedInAccount()

        XCTAssertEqual(localGoal.name, "Camera Updated")
        XCTAssertEqual(localGoal.targetAmount, 1500)
        XCTAssertEqual(localGoal.currentAmount, 250)
        XCTAssertEqual(remoteStore.upsertedPayloads.count, 0)
    }

    func test_bothExist_prefersLocalWhenLocalIsNewer() async {
        let id = UUID()
        let localGoal = makeLocalGoal(
            id: id,
            name: "Bike",
            targetAmount: 900,
            currentAmount: 200,
            syncStatus: .pending
        )
        localGoal.lastModified = Date(timeIntervalSince1970: 300)
        remoteStore.fetchResult = [
            makeRemoteRow(
                clientRecordID: id.uuidString,
                name: "Bike Old",
                targetAmount: 800,
                currentAmount: 150,
                updatedAt: Date(timeIntervalSince1970: 200)
            )
        ]

        let service = makeService()
        await service.bootstrapSignedInAccount()

        XCTAssertEqual(remoteStore.upsertedPayloads.count, 1)
        XCTAssertEqual(remoteStore.upsertedPayloads.first?.name, "Bike")
        XCTAssertEqual(localGoal.syncStatus, SavingsGoalSyncStatus.synced.rawValue)
    }

    func test_remoteDeletedAt_appliesLocalTombstone() async {
        let id = UUID()
        let localGoal = makeLocalGoal(id: id, name: "Desk", targetAmount: 600, currentAmount: 100, syncStatus: .synced)
        remoteStore.fetchResult = [
            makeRemoteRow(
                clientRecordID: id.uuidString,
                name: "Desk",
                targetAmount: 600,
                currentAmount: 100,
                updatedAt: Date(timeIntervalSince1970: 500),
                deletedAt: Date(timeIntervalSince1970: 500)
            )
        ]

        let service = makeService()
        await service.bootstrapSignedInAccount()

        XCTAssertNotNil(localGoal.deletedAt)
        XCTAssertEqual(localGoal.syncStatus, SavingsGoalSyncStatus.synced.rawValue)
    }

    func test_upsertFailure_keepsLocalGoalAndMarksFailed() async {
        let goal = makeLocalGoal(id: UUID(), name: "Phone", targetAmount: 1000, currentAmount: 100, syncStatus: .pending)
        remoteStore.fetchResult = []
        remoteStore.upsertError = MockSavingsGoalSyncError.network

        let service = makeService()
        await service.bootstrapSignedInAccount()

        XCTAssertEqual(goal.syncStatus, SavingsGoalSyncStatus.failed.rawValue)
        XCTAssertEqual(goal.name, "Phone")
    }

    private func makeService() -> SupabaseSavingsGoalSyncService {
        SupabaseSavingsGoalSyncService(
            persistenceService: persistence,
            remoteStore: remoteStore
        )
    }

    @discardableResult
    private func makeLocalGoal(
        id: UUID,
        name: String,
        targetAmount: Double,
        currentAmount: Double,
        syncStatus: SavingsGoalSyncStatus
    ) -> SavingsGoal {
        let goal = SavingsGoal(context: context)
        goal.id = id
        goal.name = name
        goal.targetAmount = targetAmount
        goal.currentAmount = currentAmount
        goal.createdAt = Date(timeIntervalSince1970: 10)
        goal.lastModified = Date(timeIntervalSince1970: 10)
        goal.syncStatus = syncStatus.rawValue
        _ = persistence.save()
        return goal
    }

    private func makeRemoteRow(
        clientRecordID: String,
        name: String,
        targetAmount: Double,
        currentAmount: Double,
        isArchived: Bool = false,
        completedDate: Date? = nil,
        updatedAt: Date,
        deletedAt: Date? = nil
    ) -> SupabaseSavingsGoalRow {
        SupabaseSavingsGoalRow(
            id: UUID(),
            userID: userID,
            clientRecordID: clientRecordID,
            name: name,
            targetAmount: Decimal(string: "\(targetAmount)") ?? 0,
            currentAmount: Decimal(string: "\(currentAmount)") ?? 0,
            targetDate: nil,
            emoji: "🎯",
            colorHex: "#FF0000",
            priority: 0,
            isArchived: isArchived,
            archivedDate: isArchived ? updatedAt : nil,
            completedDate: completedDate,
            notes: "notes",
            categoryLabel: "Other",
            monthlyContribution: 100,
            createdAt: Date(timeIntervalSince1970: 1),
            updatedAt: updatedAt,
            deletedAt: deletedAt
        )
    }
}

private final class SavingsGoalSyncSpy: SavingsGoalSyncScheduling {
    private(set) var scheduleSyncCount = 0

    func scheduleSync() {
        scheduleSyncCount += 1
    }

    func bootstrapSignedInAccount() async {}
}

private enum MockSavingsGoalSyncError: Error {
    case network
}

private final class MockSupabaseSavingsGoalRemoteStore: SupabaseSavingsGoalRemoteStoreProtocol {
    var currentUserID: UUID?
    var fetchResult: [SupabaseSavingsGoalRow] = []
    var fetchError: Error?
    var upsertError: Error?
    var upsertedPayloads: [SupabaseSavingsGoalUpsertPayload] = []

    func currentAuthenticatedUserID() async -> UUID? {
        currentUserID
    }

    func fetchSavingsGoals(userID: UUID) async throws -> [SupabaseSavingsGoalRow] {
        if let fetchError { throw fetchError }
        return fetchResult
    }

    func upsertSavingsGoal(_ payload: SupabaseSavingsGoalUpsertPayload) async throws -> SupabaseSavingsGoalRow {
        if let upsertError { throw upsertError }
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
            createdAt: payload.createdAt ?? Date(),
            updatedAt: Date(),
            deletedAt: payload.deletedAt
        )
    }
}
