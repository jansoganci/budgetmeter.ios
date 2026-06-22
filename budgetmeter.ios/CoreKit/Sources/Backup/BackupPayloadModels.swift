//
//  BackupPayloadModels.swift
//  BudgetMeter
//
//  Versioned cloud backup payload contract for Phase 9 premium backup/sync.
//

import Foundation

enum BackupConstants {
    static let schemaVersion = 1
    static let snapshotDirectoryName = "BudgetMeterSnapshots"
}

// MARK: - Root Payload

struct BackupPayload: Codable, Equatable {
    let schemaVersion: Int
    let appVersion: String
    let exportedAt: Date
    let recordCounts: BackupRecordCounts
    let appSettings: BackupAppSettings?
    let financialCategories: [BackupFinancialCategory]
    let recurringTransactions: [BackupRecurringTransaction]
    let savingsGoals: [BackupSavingsGoal]
    let subscriptions: [BackupSubscription]
    let bills: [BackupBill]
    let billPayments: [BackupBillPayment]
    let financialSnapshots: [BackupFinancialSnapshot]
}

struct BackupRecordCounts: Codable, Equatable {
    let financialCategories: Int
    let recurringTransactions: Int
    let savingsGoals: Int
    let subscriptions: Int
    let bills: Int
    let billPayments: Int
    let financialSnapshots: Int

    static func from(_ payload: BackupPayload) -> BackupRecordCounts {
        BackupRecordCounts(
            financialCategories: payload.financialCategories.count,
            recurringTransactions: payload.recurringTransactions.count,
            savingsGoals: payload.savingsGoals.count,
            subscriptions: payload.subscriptions.count,
            bills: payload.bills.count,
            billPayments: payload.billPayments.count,
            financialSnapshots: payload.financialSnapshots.count
        )
    }

    var totalRecords: Int {
        financialCategories + recurringTransactions + savingsGoals
            + subscriptions + bills + billPayments + financialSnapshots
    }
}

// MARK: - Entity Records

struct BackupAppSettings: Codable, Equatable {
    let clientRecordID: String
    let updatedAt: Date
    let preferredCurrencyCode: String?
    let selectedTheme: String?
    let isBiometricEnabled: Bool
    let weeklySummaryEnabled: Bool
    let milestonesEnabled: Bool
    let spendingAlertsEnabled: Bool
    let dailyEncouragementEnabled: Bool
    let savingsGoalAmount: Double
    let cumulativeTotal: Double
    let cumulativeStartDate: Date?
}

struct BackupFinancialCategory: Codable, Equatable {
    let clientRecordID: String
    let updatedAt: Date
    let id: UUID?
    let uniqueID: String?
    let amount: Double
    let type: String?
    let frequency: String?
    let customName: String?
    let customIconName: String?
    let customColorHex: String?
    let isCustom: Bool
    let entryKind: String?
    let occurrenceDate: Date?
    let sourceType: String?
    let sourceID: String?
    let isActive: Bool
    let createdAt: Date?
    let currencyCode: String?
}

struct BackupRecurringTransaction: Codable, Equatable {
    let clientRecordID: String
    let updatedAt: Date
    let id: UUID?
    let title: String?
    let amount: Double
    let categoryName: String?
    let categoryType: String?
    let frequency: String?
    let startDate: Date?
    let endDate: Date?
    let nextDueDate: Date?
    let isActive: Bool
    let notes: String?
    let createdAt: Date?
    let lastProcessedDate: Date?
    let currencyCode: String?
}

struct BackupSavingsGoal: Codable, Equatable {
    let clientRecordID: String
    let updatedAt: Date
    let id: UUID?
    let name: String?
    let targetAmount: Double
    let currentAmount: Double
    let targetDate: Date?
    let emoji: String?
    let colorHex: String?
    let priority: Int16
    let isArchived: Bool
    let archivedDate: Date?
    let completedDate: Date?
    let notes: String?
    let category: String?
    let monthlyContribution: Double
    let createdAt: Date?
    let lastModified: Date?
    let currencyCode: String?
}

struct BackupSubscription: Codable, Equatable {
    let clientRecordID: String
    let updatedAt: Date
    let id: UUID?
    let name: String?
    let amount: Double
    let billingCycle: String?
    let customCycleDays: Int16
    let firstBillDate: Date?
    let nextRenewalDate: Date?
    let category: String?
    let notes: String?
    let reminderDaysBefore: Int16
    let isActive: Bool
    let isPaused: Bool
    let createdAt: Date?
    let lastModified: Date?
    let currencyCode: String?
}

struct BackupBill: Codable, Equatable {
    let clientRecordID: String
    let updatedAt: Date
    let id: UUID?
    let name: String?
    let amount: Double
    let isRecurring: Bool
    let frequency: String?
    let dueDate: Date?
    let originalDueDate: Date?
    let category: String?
    let iconName: String?
    let colorHex: String?
    let notes: String?
    let reminderDaysBefore: Int16
    let isPaid: Bool
    let paidDate: Date?
    let paidAmount: Double
    let isAutoPay: Bool
    let createdAt: Date?
    let lastModified: Date?
    let currencyCode: String?
}

struct BackupBillPayment: Codable, Equatable {
    let clientRecordID: String
    let updatedAt: Date
    let id: UUID?
    let billID: UUID?
    let dueDate: Date?
    let paidDate: Date?
    let expectedAmount: Double
    let actualAmount: Double
    let notes: String?
    let wasLate: Bool
    let daysLate: Int16
    let createdAt: Date?
    let currencyCode: String?
}

struct BackupFinancialSnapshot: Codable, Equatable {
    let clientRecordID: String
    let updatedAt: Date
    let id: UUID?
    let date: Date?
    let snapshotType: String?
    let totalIncome: Double
    let totalExpense: Double
    let balance: Double
    let netFlow: Double
    let savingsAmount: Double
    let healthScore: Int16
    let savingsRate: Double
    let categoryBreakdown: String?
    let createdAt: Date?
}

// MARK: - Local Snapshot Wrapper

struct LocalBackupSnapshot: Codable, Equatable {
    let sessionID: UUID
    let createdAt: Date
    let schemaVersion: Int
    let appVersion: String
    let authenticatedUserID: String?
    let payload: BackupPayload
}

// MARK: - Cloud Row

struct CloudBackupRow: Codable {
    let userId: UUID
    let schemaVersion: Int
    let appVersion: String
    let payload: BackupPayload
    let recordCounts: BackupRecordCounts
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case schemaVersion = "schema_version"
        case appVersion = "app_version"
        case payload
        case recordCounts = "record_counts"
        case updatedAt = "updated_at"
    }
}
