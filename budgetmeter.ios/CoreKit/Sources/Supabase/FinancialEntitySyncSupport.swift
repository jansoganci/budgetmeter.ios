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
