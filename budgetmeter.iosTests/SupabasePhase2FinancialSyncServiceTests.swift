//
//  SupabasePhase2FinancialSyncServiceTests.swift
//  budgetmeter.iosTests
//
//  Phase 2C subscriptions, bills, bill payments, recurring transactions sync tests.
//

import CoreData
import XCTest
@testable import budgetmeter_ios

@MainActor
final class SupabasePhase2FinancialSyncServiceTests: XCTestCase {
    private var persistence: PersistenceService!
    private var context: NSManagedObjectContext!
    private var userID: UUID!

    override func setUp() {
        super.setUp()
        persistence = PersistenceService.makeInMemoryForTesting()
        context = persistence.viewContext
        userID = UUID()
    }

    override func tearDown() {
        persistence = nil
        context = nil
        userID = nil
        super.tearDown()
    }

    func test_subscription_localUploadsWhenRemoteEmpty() async {
        let remoteStore = MockSupabaseSubscriptionRemoteStore()
        remoteStore.currentUserID = userID
        remoteStore.fetchResult = []

        let subscription = makeSubscription(name: "Netflix", amount: 15.99)
        subscription.markFinancialSyncPending()
        subscription.lastModified = Date()

        let service = SupabaseSubscriptionSyncService(
            persistenceService: persistence,
            remoteStore: remoteStore
        )
        await service.bootstrapSignedInAccount()

        XCTAssertEqual(remoteStore.upsertedPayloads.count, 1)
        XCTAssertEqual(remoteStore.upsertedPayloads.first?.clientRecordID, subscription.id?.uuidString)
        XCTAssertEqual(subscription.syncStatus, FinancialEntitySyncStatus.synced.rawValue)
    }

    func test_subscription_deleteUsesTombstone() {
        let subscription = makeSubscription(name: "Spotify", amount: 9.99)
        _ = persistence.save()

        subscription.tombstoneForFinancialSync()
        _ = persistence.save()

        XCTAssertNotNil(subscription.deletedAt)
        XCTAssertEqual(subscription.syncStatus, FinancialEntitySyncStatus.pending.rawValue)

        let request: NSFetchRequest<Subscription> = Subscription.fetchRequest()
        request.predicate = NSPredicate(format: "deletedAt == nil")
        let visible = try? context.fetch(request)
        XCTAssertTrue(visible?.isEmpty ?? false)
    }

    func test_bill_localUploadsWhenRemoteEmpty() async {
        let remoteStore = MockSupabaseBillRemoteStore()
        remoteStore.currentUserID = userID
        remoteStore.fetchResult = []

        let bill = makeBill(name: "Rent", amount: 1200)
        bill.markFinancialSyncPending()
        bill.lastModified = Date()

        let service = SupabaseBillSyncService(
            persistenceService: persistence,
            remoteStore: remoteStore
        )
        await service.bootstrapSignedInAccount()

        XCTAssertEqual(remoteStore.upsertedPayloads.count, 1)
        XCTAssertEqual(remoteStore.upsertedPayloads.first?.name, "Rent")
    }

    func test_recurringTransaction_remoteRestoresLocally() async {
        let clientRecordID = UUID().uuidString
        let remoteStore = MockSupabaseRecurringTransactionRemoteStore()
        remoteStore.currentUserID = userID
        remoteStore.fetchResult = [
            SupabaseRecurringTransactionRow(
                id: UUID(),
                userID: userID,
                clientRecordID: clientRecordID,
                title: "Salary",
                amount: 5000,
                categoryName: "Salary",
                categoryType: "income",
                frequency: "monthly",
                startDate: Date(),
                endDate: nil,
                nextDueDate: Date(),
                isActive: true,
                notes: nil,
                lastProcessedDate: nil,
                createdAt: Date(),
                updatedAt: Date(),
                deletedAt: nil
            )
        ]

        let service = SupabaseRecurringTransactionSyncService(
            persistenceService: persistence,
            remoteStore: remoteStore
        )
        await service.bootstrapSignedInAccount()

        let request: NSFetchRequest<RecurringTransaction> = RecurringTransaction.fetchRequest()
        let rows = try? context.fetch(request)
        XCTAssertEqual(rows?.count, 1)
        XCTAssertEqual(rows?.first?.title, "Salary")
    }

    func test_bootstrap_withoutUser_doesNotCrash() async {
        await SupabasePhase2FinancialSyncBootstrap.shared.bootstrapSignedInAccount()
    }

    func test_supabaseFailure_keepsLocalSubscription() async {
        let remoteStore = MockSupabaseSubscriptionRemoteStore()
        remoteStore.currentUserID = userID
        remoteStore.fetchResult = []
        remoteStore.upsertError = MockPhase2SyncError.network

        let subscription = makeSubscription(name: "Hulu", amount: 7.99)
        subscription.markFinancialSyncPending()
        subscription.lastModified = Date()

        let service = SupabaseSubscriptionSyncService(
            persistenceService: persistence,
            remoteStore: remoteStore
        )
        await service.bootstrapSignedInAccount()

        XCTAssertEqual(subscription.amount, 7.99)
        XCTAssertEqual(subscription.syncStatus, FinancialEntitySyncStatus.failed.rawValue)
    }

    @discardableResult
    private func makeSubscription(name: String, amount: Double) -> Subscription {
        let subscription = Subscription(context: context)
        subscription.id = UUID()
        subscription.name = name
        subscription.amount = amount
        subscription.billingCycle = "monthly"
        subscription.firstBillDate = Date()
        subscription.nextRenewalDate = Date()
        subscription.isActive = true
        subscription.isPaused = false
        subscription.createdAt = Date()
        subscription.lastModified = Date()
        return subscription
    }

    @discardableResult
    private func makeBill(name: String, amount: Double) -> Bill {
        let bill = Bill(context: context)
        bill.id = UUID()
        bill.name = name
        bill.amount = amount
        bill.dueDate = Date()
        bill.isPaid = false
        bill.createdAt = Date()
        bill.lastModified = Date()
        return bill
    }
}

private enum MockPhase2SyncError: Error {
    case network
}

private final class FinancialEntitySyncSpy: FinancialEntitySyncScheduling {
    func scheduleSync() {}
    func bootstrapSignedInAccount() async {}
}

private final class MockSupabaseSubscriptionRemoteStore: SupabaseSubscriptionRemoteStoreProtocol {
    var currentUserID: UUID?
    var fetchResult: [SupabaseSubscriptionRow] = []
    var upsertError: Error?
    private(set) var upsertedPayloads: [SupabaseSubscriptionUpsertPayload] = []

    func currentAuthenticatedUserID() async -> UUID? { currentUserID }
    func fetchSubscriptions(userID: UUID) async throws -> [SupabaseSubscriptionRow] { fetchResult }
    func upsertSubscription(_ payload: SupabaseSubscriptionUpsertPayload) async throws -> SupabaseSubscriptionRow {
        if let upsertError { throw upsertError }
        upsertedPayloads.append(payload)
        return SupabaseSubscriptionRow(
            id: UUID(), userID: payload.userID, clientRecordID: payload.clientRecordID,
            name: payload.name, amount: payload.amount, billingCycle: payload.billingCycle,
            customCycleDays: payload.customCycleDays, firstBillDate: payload.firstBillDate,
            nextRenewalDate: payload.nextRenewalDate, categoryLabel: payload.categoryLabel,
            notes: payload.notes, reminderDaysBefore: payload.reminderDaysBefore,
            isActive: payload.isActive, isPaused: payload.isPaused,
            createdAt: payload.createdAt, updatedAt: Date(), deletedAt: payload.deletedAt
        )
    }
}

private final class MockSupabaseBillRemoteStore: SupabaseBillRemoteStoreProtocol {
    var currentUserID: UUID?
    var fetchResult: [SupabaseBillRow] = []
    private(set) var upsertedPayloads: [SupabaseBillUpsertPayload] = []

    func currentAuthenticatedUserID() async -> UUID? { currentUserID }
    func fetchBills(userID: UUID) async throws -> [SupabaseBillRow] { fetchResult }
    func upsertBill(_ payload: SupabaseBillUpsertPayload) async throws -> SupabaseBillRow {
        upsertedPayloads.append(payload)
        return SupabaseBillRow(
            id: UUID(), userID: payload.userID, clientRecordID: payload.clientRecordID,
            name: payload.name, amount: payload.amount, isRecurring: payload.isRecurring,
            frequency: payload.frequency, dueDate: payload.dueDate, originalDueDate: payload.originalDueDate,
            categoryLabel: payload.categoryLabel, iconName: payload.iconName, colorHex: payload.colorHex,
            notes: payload.notes, reminderDaysBefore: payload.reminderDaysBefore, isPaid: payload.isPaid,
            paidDate: payload.paidDate, paidAmount: payload.paidAmount, isAutoPay: payload.isAutoPay,
            createdAt: payload.createdAt, updatedAt: Date(), deletedAt: payload.deletedAt
        )
    }
}

private final class MockSupabaseRecurringTransactionRemoteStore: SupabaseRecurringTransactionRemoteStoreProtocol {
    var currentUserID: UUID?
    var fetchResult: [SupabaseRecurringTransactionRow] = []

    func currentAuthenticatedUserID() async -> UUID? { currentUserID }
    func fetchRecurringTransactions(userID: UUID) async throws -> [SupabaseRecurringTransactionRow] { fetchResult }
    func upsertRecurringTransaction(_ payload: SupabaseRecurringTransactionUpsertPayload) async throws -> SupabaseRecurringTransactionRow {
        fetchResult.first!
    }
}
