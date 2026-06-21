//
//  BackupSerializer.swift
//  BudgetMeter
//
//  Serializes Core Data entities into versioned backup payloads.
//

import CoreData
import Foundation

enum BackupSerializerError: Error, Equatable {
    case unsupportedSchemaVersion(Int)
    case encodingFailed
    case decodingFailed
}

struct BackupSerializer {

    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    func exportPayload(from context: NSManagedObjectContext, exportedAt: Date = Date()) throws -> BackupPayload {
        let appSettings = try fetchAppSettings(from: context)
        let categories = try fetchCategories(from: context)
        let recurring = try fetchRecurring(from: context)
        let goals = try fetchSavingsGoals(from: context)
        let subscriptions = try fetchSubscriptions(from: context)
        let bills = try fetchBills(from: context)
        let payments = try fetchBillPayments(from: context)
        let snapshots = try fetchSnapshots(from: context)

        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"

        let payload = BackupPayload(
            schemaVersion: BackupConstants.schemaVersion,
            appVersion: appVersion,
            exportedAt: exportedAt,
            recordCounts: BackupRecordCounts(
                financialCategories: categories.count,
                recurringTransactions: recurring.count,
                savingsGoals: goals.count,
                subscriptions: subscriptions.count,
                bills: bills.count,
                billPayments: payments.count,
                financialSnapshots: snapshots.count
            ),
            appSettings: appSettings,
            financialCategories: categories,
            recurringTransactions: recurring,
            savingsGoals: goals,
            subscriptions: subscriptions,
            bills: bills,
            billPayments: payments,
            financialSnapshots: snapshots
        )

        return payload
    }

    func encode(_ payload: BackupPayload) throws -> Data {
        do {
            return try encoder.encode(payload)
        } catch {
            throw BackupSerializerError.encodingFailed
        }
    }

    func decode(_ data: Data) throws -> BackupPayload {
        let payload: BackupPayload
        do {
            payload = try decoder.decode(BackupPayload.self, from: data)
        } catch {
            throw BackupSerializerError.decodingFailed
        }

        guard payload.schemaVersion <= BackupConstants.schemaVersion else {
            throw BackupSerializerError.unsupportedSchemaVersion(payload.schemaVersion)
        }

        return payload
    }

    func roundTrip(_ payload: BackupPayload) throws -> BackupPayload {
        try decode(try encode(payload))
    }

    // MARK: - Fetch Helpers

    private func fetchAppSettings(from context: NSManagedObjectContext) throws -> BackupAppSettings? {
        let request: NSFetchRequest<AppSettings> = AppSettings.fetchRequest()
        guard let settings = try context.fetch(request).first else { return nil }

        return BackupAppSettings(
            clientRecordID: "app-settings",
            updatedAt: Date(),
            preferredCurrencyCode: settings.preferredCurrencyCode,
            selectedTheme: settings.selectedTheme,
            isBiometricEnabled: settings.isBiometricEnabled,
            weeklySummaryEnabled: settings.weeklySummaryEnabled,
            milestonesEnabled: settings.milestonesEnabled,
            spendingAlertsEnabled: settings.spendingAlertsEnabled,
            dailyEncouragementEnabled: settings.dailyEncouragementEnabled,
            savingsGoalAmount: settings.savingsGoalAmount,
            cumulativeTotal: settings.cumulativeTotal,
            cumulativeStartDate: settings.cumulativeStartDate
        )
    }

    private func fetchCategories(from context: NSManagedObjectContext) throws -> [BackupFinancialCategory] {
        let request: NSFetchRequest<FinancialCategory> = FinancialCategory.fetchRequest()
        return try context.fetch(request).map { category in
            BackupFinancialCategory(
                clientRecordID: clientRecordID(for: category.id, fallback: category.uniqueID),
                updatedAt: category.lastModified ?? category.createdAt ?? Date(),
                id: category.id,
                uniqueID: category.uniqueID,
                amount: category.amount,
                type: category.type,
                frequency: category.frequency,
                customName: category.customName,
                customIconName: category.customIconName,
                customColorHex: category.customColorHex,
                isCustom: category.isCustom,
                entryKind: category.entryKind,
                occurrenceDate: category.occurrenceDate,
                sourceType: category.sourceType,
                sourceID: category.sourceID,
                isActive: category.isActive,
                createdAt: category.createdAt
            )
        }
    }

    private func fetchRecurring(from context: NSManagedObjectContext) throws -> [BackupRecurringTransaction] {
        let request: NSFetchRequest<RecurringTransaction> = RecurringTransaction.fetchRequest()
        return try context.fetch(request).map { item in
            BackupRecurringTransaction(
                clientRecordID: clientRecordID(for: item.id),
                updatedAt: item.createdAt ?? Date(),
                id: item.id,
                title: item.title,
                amount: item.amount,
                categoryName: item.categoryName,
                categoryType: item.categoryType,
                frequency: item.frequency,
                startDate: item.startDate,
                endDate: item.endDate,
                nextDueDate: item.nextDueDate,
                isActive: item.isActive,
                notes: item.notes,
                createdAt: item.createdAt,
                lastProcessedDate: item.lastProcessedDate
            )
        }
    }

    private func fetchSavingsGoals(from context: NSManagedObjectContext) throws -> [BackupSavingsGoal] {
        let request: NSFetchRequest<SavingsGoal> = SavingsGoal.fetchRequest()
        return try context.fetch(request).map { goal in
            BackupSavingsGoal(
                clientRecordID: clientRecordID(for: goal.id),
                updatedAt: goal.lastModified ?? goal.createdAt ?? Date(),
                id: goal.id,
                name: goal.name,
                targetAmount: goal.targetAmount,
                currentAmount: goal.currentAmount,
                targetDate: goal.targetDate,
                emoji: goal.emoji,
                colorHex: goal.colorHex,
                priority: goal.priority,
                isArchived: goal.isArchived,
                archivedDate: goal.archivedDate,
                completedDate: goal.completedDate,
                notes: goal.notes,
                category: goal.category,
                monthlyContribution: goal.monthlyContribution,
                createdAt: goal.createdAt,
                lastModified: goal.lastModified
            )
        }
    }

    private func fetchSubscriptions(from context: NSManagedObjectContext) throws -> [BackupSubscription] {
        let request: NSFetchRequest<Subscription> = Subscription.fetchRequest()
        return try context.fetch(request).map { item in
            BackupSubscription(
                clientRecordID: clientRecordID(for: item.id),
                updatedAt: item.lastModified ?? item.createdAt ?? Date(),
                id: item.id,
                name: item.name,
                amount: item.amount,
                billingCycle: item.billingCycle,
                customCycleDays: item.customCycleDays,
                firstBillDate: item.firstBillDate,
                nextRenewalDate: item.nextRenewalDate,
                category: item.category,
                notes: item.notes,
                reminderDaysBefore: item.reminderDaysBefore,
                isActive: item.isActive,
                isPaused: item.isPaused,
                createdAt: item.createdAt,
                lastModified: item.lastModified
            )
        }
    }

    private func fetchBills(from context: NSManagedObjectContext) throws -> [BackupBill] {
        let request: NSFetchRequest<Bill> = Bill.fetchRequest()
        return try context.fetch(request).map { bill in
            BackupBill(
                clientRecordID: clientRecordID(for: bill.id),
                updatedAt: bill.lastModified ?? bill.createdAt ?? Date(),
                id: bill.id,
                name: bill.name,
                amount: bill.amount,
                isRecurring: bill.isRecurring,
                frequency: bill.frequency,
                dueDate: bill.dueDate,
                originalDueDate: bill.originalDueDate,
                category: bill.category,
                iconName: bill.iconName,
                colorHex: bill.colorHex,
                notes: bill.notes,
                reminderDaysBefore: bill.reminderDaysBefore,
                isPaid: bill.isPaid,
                paidDate: bill.paidDate,
                paidAmount: bill.paidAmount,
                isAutoPay: bill.isAutoPay,
                createdAt: bill.createdAt,
                lastModified: bill.lastModified
            )
        }
    }

    private func fetchBillPayments(from context: NSManagedObjectContext) throws -> [BackupBillPayment] {
        let request: NSFetchRequest<BillPayment> = BillPayment.fetchRequest()
        return try context.fetch(request).map { payment in
            BackupBillPayment(
                clientRecordID: clientRecordID(for: payment.id),
                updatedAt: payment.createdAt ?? Date(),
                id: payment.id,
                billID: payment.billID,
                dueDate: payment.dueDate,
                paidDate: payment.paidDate,
                expectedAmount: payment.expectedAmount,
                actualAmount: payment.actualAmount,
                notes: payment.notes,
                wasLate: payment.wasLate,
                daysLate: payment.daysLate,
                createdAt: payment.createdAt
            )
        }
    }

    private func fetchSnapshots(from context: NSManagedObjectContext) throws -> [BackupFinancialSnapshot] {
        let request: NSFetchRequest<FinancialSnapshot> = FinancialSnapshot.fetchRequest()
        return try context.fetch(request).map { snapshot in
            BackupFinancialSnapshot(
                clientRecordID: clientRecordID(for: snapshot.id),
                updatedAt: snapshot.createdAt ?? Date(),
                id: snapshot.id,
                date: snapshot.date,
                snapshotType: snapshot.snapshotType,
                totalIncome: snapshot.totalIncome,
                totalExpense: snapshot.totalExpense,
                balance: snapshot.balance,
                netFlow: snapshot.netFlow,
                savingsAmount: snapshot.savingsAmount,
                healthScore: snapshot.healthScore,
                savingsRate: snapshot.savingsRate,
                categoryBreakdown: snapshot.categoryBreakdown,
                createdAt: snapshot.createdAt
            )
        }
    }

    private func clientRecordID(for uuid: UUID?, fallback: String? = nil) -> String {
        if let uuid {
            return uuid.uuidString
        }
        if let fallback, !fallback.isEmpty {
            return fallback
        }
        return UUID().uuidString
    }
}
