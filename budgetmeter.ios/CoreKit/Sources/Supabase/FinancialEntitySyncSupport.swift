//
//  FinancialEntitySyncSupport.swift
//  BudgetMeter
//
//  Shared Phase 2C financial entity sync helpers.
//

import CoreData
import Foundation

typealias FinancialEntitySyncStatus = SavingsGoalSyncStatus

protocol FinancialEntitySyncScheduling: AnyObject {
    func scheduleSync()
    func bootstrapSignedInAccount() async
}

extension SupabaseFinancialTableNames {
    static let subscriptions = "subscriptions"
    static let bills = "bills"
    static let billPayments = "bill_payments"
    static let recurringTransactions = "recurring_transactions"
    static let financialCategories = "financial_categories"
    static let seededCategoryOverrides = "seeded_category_overrides"
}

enum FinancialEntitySyncSupport {
    static func ensureClientRecordID(
        id: inout UUID?,
        lastModified: inout Date?,
        syncStatus: inout String?
    ) -> String {
        if let id {
            return id.uuidString
        }

        let newID = UUID()
        id = newID
        lastModified = lastModified ?? Date()
        syncStatus = syncStatus ?? FinancialEntitySyncStatus.pending.rawValue
        return newID.uuidString
    }

    static func markPending(syncStatus: inout String?, lastSyncError: inout String?) {
        syncStatus = FinancialEntitySyncStatus.pending.rawValue
        lastSyncError = nil
    }

    static func markSynced(
        syncStatus: inout String?,
        lastSyncedAt: inout Date?,
        remoteUpdatedAt: inout Date?,
        lastSyncError: inout String?,
        remoteUpdatedAtValue: Date?
    ) {
        syncStatus = FinancialEntitySyncStatus.synced.rawValue
        lastSyncedAt = Date()
        remoteUpdatedAt = remoteUpdatedAtValue
        lastSyncError = nil
    }

    static func markFailed(syncStatus: inout String?, lastSyncError: inout String?, error: String) {
        syncStatus = FinancialEntitySyncStatus.failed.rawValue
        lastSyncError = error
    }

    static func tombstone(
        deletedAt: inout Date?,
        lastModified: inout Date?,
        syncStatus: inout String?,
        lastSyncError: inout String?
    ) {
        deletedAt = Date()
        lastModified = Date()
        syncStatus = FinancialEntitySyncStatus.pending.rawValue
        lastSyncError = nil
    }

    static func mutationTimestamp(lastModified: Date?, deletedAt: Date?, createdAt: Date?) -> Date {
        lastModified ?? deletedAt ?? createdAt ?? .distantPast
    }

    static func mutationTimestamp(lastModified: Date?, createdAt: Date?, deletedAt: Date?) -> Date {
        lastModified ?? createdAt ?? deletedAt ?? .distantPast
    }

    static func remoteMutationTimestamp(updatedAt: Date?, deletedAt: Date?, createdAt: Date?) -> Date {
        updatedAt ?? deletedAt ?? createdAt ?? .distantPast
    }

    static func maxDate(_ lhs: Date?, _ rhs: Date?) -> Date? {
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

    static func decimal(from value: Double) -> Decimal {
        Decimal(string: NSDecimalNumber(value: value).stringValue) ?? Decimal(value)
    }

    static func double(from value: Decimal) -> Double {
        NSDecimalNumber(decimal: value).doubleValue
    }
}

/// Row-level currency stamping and display resolution for money-bearing records.
enum RecordCurrencySupport {
    static func preferredCurrencyCode(in context: NSManagedObjectContext) -> String {
        let request: NSFetchRequest<AppSettings> = AppSettings.fetchRequest()
        if let settings = try? context.fetch(request).first,
           let storedCode = settings.preferredCurrencyCode,
           CurrencyHelper.supportedCurrencyCodes.contains(storedCode) {
            return storedCode
        }
        return CurrencyHelper.defaultCurrencyCode()
    }

    static func stampCurrencyCodeIfNeeded(on goal: SavingsGoal) {
        guard normalized(goal.currencyCode).isEmpty else { return }
        let context = goal.managedObjectContext ?? PersistenceService.shared.viewContext
        goal.currencyCode = preferredCurrencyCode(in: context)
    }

    static func stampCurrencyCodeIfNeeded(on subscription: Subscription) {
        guard normalized(subscription.currencyCode).isEmpty else { return }
        let context = subscription.managedObjectContext ?? PersistenceService.shared.viewContext
        subscription.currencyCode = preferredCurrencyCode(in: context)
    }

    static func stampCurrencyCodeIfNeeded(on bill: Bill) {
        guard normalized(bill.currencyCode).isEmpty else { return }
        let context = bill.managedObjectContext ?? PersistenceService.shared.viewContext
        bill.currencyCode = preferredCurrencyCode(in: context)
    }

    static func stampCurrencyCodeIfNeeded(on payment: BillPayment) {
        guard normalized(payment.currencyCode).isEmpty else { return }
        let context = payment.managedObjectContext ?? PersistenceService.shared.viewContext
        payment.currencyCode = preferredCurrencyCode(in: context)
    }

    static func stampCurrencyCodeIfNeeded(on transaction: RecurringTransaction) {
        guard normalized(transaction.currencyCode).isEmpty else { return }
        let context = transaction.managedObjectContext ?? PersistenceService.shared.viewContext
        transaction.currencyCode = preferredCurrencyCode(in: context)
    }

    static func stampCurrencyCodeIfNeeded(on category: FinancialCategory) {
        guard normalized(category.currencyCode).isEmpty else { return }
        let context = category.managedObjectContext ?? PersistenceService.shared.viewContext
        category.currencyCode = preferredCurrencyCode(in: context)
    }

    static func resolvedDisplayCode(storedCode: String?, in context: NSManagedObjectContext? = nil) -> String {
        let code = normalized(storedCode)
        if !code.isEmpty, CurrencyHelper.supportedCurrencyCodes.contains(code) {
            return code
        }
        if let context {
            return preferredCurrencyCode(in: context)
        }
        return CurrencyHelper.currentCurrencyCode()
    }

    static func payloadCurrencyCode(storedCode: String?, in context: NSManagedObjectContext? = nil) -> String {
        resolvedDisplayCode(storedCode: storedCode, in: context)
    }

    static func backfillCurrencyCodeIfNeeded(on entity: NSManagedObject, preferredCode: String) {
        let fallback = normalized(preferredCode).isEmpty
            ? CurrencyHelper.defaultCurrencyCode()
            : preferredCode

        switch entity {
        case let goal as SavingsGoal where normalized(goal.currencyCode).isEmpty:
            goal.currencyCode = fallback
        case let subscription as Subscription where normalized(subscription.currencyCode).isEmpty:
            subscription.currencyCode = fallback
        case let bill as Bill where normalized(bill.currencyCode).isEmpty:
            bill.currencyCode = fallback
        case let payment as BillPayment where normalized(payment.currencyCode).isEmpty:
            payment.currencyCode = fallback
        case let transaction as RecurringTransaction where normalized(transaction.currencyCode).isEmpty:
            transaction.currencyCode = fallback
        case let category as FinancialCategory where normalized(category.currencyCode).isEmpty:
            guard FinancialCategoryWriteSupport.isOneTimeDisplayCategory(category) else { return }
            category.currencyCode = fallback
        default:
            break
        }
    }

    private static func normalized(_ value: String?) -> String {
        value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}

extension Subscription {
    func ensureFinancialSyncClientRecordID() -> String {
        if let id {
            return id.uuidString
        }

        let newID = UUID()
        id = newID
        lastModified = lastModified ?? Date()
        syncStatus = syncStatus ?? FinancialEntitySyncStatus.pending.rawValue
        return newID.uuidString
    }

    func markFinancialSyncPending() {
        syncStatus = FinancialEntitySyncStatus.pending.rawValue
        lastSyncError = nil
    }

    func markFinancialSyncSynced(remoteUpdatedAtValue: Date?) {
        syncStatus = FinancialEntitySyncStatus.synced.rawValue
        lastSyncedAt = Date()
        remoteUpdatedAt = remoteUpdatedAtValue
        lastSyncError = nil
    }

    func markFinancialSyncFailed(_ error: String) {
        syncStatus = FinancialEntitySyncStatus.failed.rawValue
        lastSyncError = error
    }

    func tombstoneForFinancialSync() {
        deletedAt = Date()
        lastModified = Date()
        syncStatus = FinancialEntitySyncStatus.pending.rawValue
        lastSyncError = nil
    }

    func financialSyncMutationTimestamp() -> Date {
        FinancialEntitySyncSupport.mutationTimestamp(
            lastModified: lastModified,
            deletedAt: deletedAt,
            createdAt: createdAt
        )
    }
}

extension Bill {
    func ensureFinancialSyncClientRecordID() -> String {
        if let id {
            return id.uuidString
        }

        let newID = UUID()
        id = newID
        lastModified = lastModified ?? Date()
        syncStatus = syncStatus ?? FinancialEntitySyncStatus.pending.rawValue
        return newID.uuidString
    }

    func markFinancialSyncPending() {
        syncStatus = FinancialEntitySyncStatus.pending.rawValue
        lastSyncError = nil
    }

    func markFinancialSyncSynced(remoteUpdatedAtValue: Date?) {
        syncStatus = FinancialEntitySyncStatus.synced.rawValue
        lastSyncedAt = Date()
        remoteUpdatedAt = remoteUpdatedAtValue
        lastSyncError = nil
    }

    func markFinancialSyncFailed(_ error: String) {
        syncStatus = FinancialEntitySyncStatus.failed.rawValue
        lastSyncError = error
    }

    func tombstoneForFinancialSync() {
        deletedAt = Date()
        lastModified = Date()
        syncStatus = FinancialEntitySyncStatus.pending.rawValue
        lastSyncError = nil
    }

    func financialSyncMutationTimestamp() -> Date {
        FinancialEntitySyncSupport.mutationTimestamp(
            lastModified: lastModified,
            deletedAt: deletedAt,
            createdAt: createdAt
        )
    }
}

extension BillPayment {
    func ensureFinancialSyncClientRecordID() -> String {
        if let id {
            return id.uuidString
        }

        let newID = UUID()
        id = newID
        lastModified = lastModified ?? Date()
        syncStatus = syncStatus ?? FinancialEntitySyncStatus.pending.rawValue
        return newID.uuidString
    }

    func markFinancialSyncPending() {
        syncStatus = FinancialEntitySyncStatus.pending.rawValue
        lastSyncError = nil
    }

    func markFinancialSyncSynced(remoteUpdatedAtValue: Date?) {
        syncStatus = FinancialEntitySyncStatus.synced.rawValue
        lastSyncedAt = Date()
        remoteUpdatedAt = remoteUpdatedAtValue
        lastSyncError = nil
    }

    func markFinancialSyncFailed(_ error: String) {
        syncStatus = FinancialEntitySyncStatus.failed.rawValue
        lastSyncError = error
    }

    func tombstoneForFinancialSync() {
        deletedAt = Date()
        lastModified = Date()
        syncStatus = FinancialEntitySyncStatus.pending.rawValue
        lastSyncError = nil
    }

    func financialSyncMutationTimestamp() -> Date {
        FinancialEntitySyncSupport.mutationTimestamp(
            lastModified: lastModified,
            deletedAt: deletedAt,
            createdAt: createdAt
        )
    }
}

extension RecurringTransaction {
    func ensureFinancialSyncClientRecordID() -> String {
        if let id {
            return id.uuidString
        }

        let newID = UUID()
        id = newID
        lastModified = lastModified ?? Date()
        syncStatus = syncStatus ?? FinancialEntitySyncStatus.pending.rawValue
        return newID.uuidString
    }

    func markFinancialSyncPending() {
        syncStatus = FinancialEntitySyncStatus.pending.rawValue
        lastSyncError = nil
    }

    func markFinancialSyncSynced(remoteUpdatedAtValue: Date?) {
        syncStatus = FinancialEntitySyncStatus.synced.rawValue
        lastSyncedAt = Date()
        remoteUpdatedAt = remoteUpdatedAtValue
        lastSyncError = nil
    }

    func markFinancialSyncFailed(_ error: String) {
        syncStatus = FinancialEntitySyncStatus.failed.rawValue
        lastSyncError = error
    }

    func tombstoneForFinancialSync() {
        deletedAt = Date()
        lastModified = Date()
        syncStatus = FinancialEntitySyncStatus.pending.rawValue
        lastSyncError = nil
    }

    func financialSyncMutationTimestamp() -> Date {
        FinancialEntitySyncSupport.mutationTimestamp(
            lastModified: lastModified,
            createdAt: createdAt,
            deletedAt: deletedAt
        )
    }
}
