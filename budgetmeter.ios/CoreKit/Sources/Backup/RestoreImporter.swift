//
//  RestoreImporter.swift
//  BudgetMeter
//
//  Imports a backup payload into Core Data with transactional safety.
//

import CoreData
import Foundation

enum RestoreImporterError: Error {
    case importFailed
    case unsupportedSchema(Int)
}

struct RestoreImporter {

    func importPayload(_ payload: BackupPayload, into context: NSManagedObjectContext) throws {
        guard payload.schemaVersion <= BackupConstants.schemaVersion else {
            throw RestoreImporterError.unsupportedSchema(payload.schemaVersion)
        }

        try clearRestorableEntities(in: context)

        if let settings = payload.appSettings {
            try importAppSettings(settings, into: context)
        }

        for category in payload.financialCategories {
            try importCategory(category, into: context)
        }

        for transaction in payload.recurringTransactions {
            try importRecurring(transaction, into: context)
        }

        for goal in payload.savingsGoals {
            try importSavingsGoal(goal, into: context)
        }

        for subscription in payload.subscriptions {
            try importSubscription(subscription, into: context)
        }

        for bill in payload.bills {
            try importBill(bill, into: context)
        }

        for payment in payload.billPayments {
            try importBillPayment(payment, into: context)
        }

        for snapshot in payload.financialSnapshots {
            try importSnapshot(snapshot, into: context)
        }

        if context.hasChanges {
            try context.save()
        }
    }

    private func clearRestorableEntities(in context: NSManagedObjectContext) throws {
        let entityNames = [
            "FinancialCategory",
            "RecurringTransaction",
            "SavingsGoal",
            "Subscription",
            "Bill",
            "BillPayment",
            "FinancialSnapshot"
        ]

        for entityName in entityNames {
            let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
            let objects = try context.fetch(request)
            for object in objects {
                context.delete(object)
            }
        }

        if context.hasChanges {
            try context.save()
        }
    }

    private func importAppSettings(_ backup: BackupAppSettings, into context: NSManagedObjectContext) throws {
        let request: NSFetchRequest<AppSettings> = AppSettings.fetchRequest()
        let settings = try context.fetch(request).first ?? AppSettings(context: context)

        settings.preferredCurrencyCode = backup.preferredCurrencyCode
        settings.selectedTheme = backup.selectedTheme
        settings.isBiometricEnabled = backup.isBiometricEnabled
        settings.weeklySummaryEnabled = backup.weeklySummaryEnabled
        settings.milestonesEnabled = backup.milestonesEnabled
        settings.spendingAlertsEnabled = backup.spendingAlertsEnabled
        settings.dailyEncouragementEnabled = backup.dailyEncouragementEnabled
        settings.savingsGoalAmount = backup.savingsGoalAmount
        settings.cumulativeTotal = backup.cumulativeTotal
        settings.cumulativeStartDate = backup.cumulativeStartDate
    }

    private func importCategory(_ backup: BackupFinancialCategory, into context: NSManagedObjectContext) throws {
        let category = FinancialCategory(context: context)
        category.id = backup.id ?? UUID(uuidString: backup.clientRecordID)
        category.uniqueID = backup.uniqueID ?? backup.clientRecordID
        category.amount = backup.amount
        category.type = backup.type
        category.frequency = backup.frequency
        category.customName = backup.customName
        category.customIconName = backup.customIconName
        category.customColorHex = backup.customColorHex
        category.isCustom = backup.isCustom
        category.entryKind = backup.entryKind
        category.occurrenceDate = backup.occurrenceDate
        category.sourceType = backup.sourceType
        category.sourceID = backup.sourceID
        category.isActive = backup.isActive
        category.createdAt = backup.createdAt
        category.lastModified = backup.updatedAt
    }

    private func importRecurring(_ backup: BackupRecurringTransaction, into context: NSManagedObjectContext) throws {
        let item = RecurringTransaction(context: context)
        item.id = backup.id ?? UUID(uuidString: backup.clientRecordID)
        item.title = backup.title
        item.amount = backup.amount
        item.categoryName = backup.categoryName
        item.categoryType = backup.categoryType
        item.frequency = backup.frequency
        item.startDate = backup.startDate
        item.endDate = backup.endDate
        item.nextDueDate = backup.nextDueDate
        item.isActive = backup.isActive
        item.notes = backup.notes
        item.createdAt = backup.createdAt
        item.lastProcessedDate = backup.lastProcessedDate
    }

    private func importSavingsGoal(_ backup: BackupSavingsGoal, into context: NSManagedObjectContext) throws {
        let goal = SavingsGoal(context: context)
        goal.id = backup.id ?? UUID(uuidString: backup.clientRecordID)
        goal.name = backup.name
        goal.targetAmount = backup.targetAmount
        goal.currentAmount = backup.currentAmount
        goal.targetDate = backup.targetDate
        goal.emoji = backup.emoji
        goal.colorHex = backup.colorHex
        goal.priority = backup.priority
        goal.isArchived = backup.isArchived
        goal.archivedDate = backup.archivedDate
        goal.completedDate = backup.completedDate
        goal.notes = backup.notes
        goal.category = backup.category
        goal.monthlyContribution = backup.monthlyContribution
        goal.createdAt = backup.createdAt
        goal.lastModified = backup.lastModified ?? backup.updatedAt
    }

    private func importSubscription(_ backup: BackupSubscription, into context: NSManagedObjectContext) throws {
        let item = Subscription(context: context)
        item.id = backup.id ?? UUID(uuidString: backup.clientRecordID)
        item.name = backup.name
        item.amount = backup.amount
        item.billingCycle = backup.billingCycle
        item.customCycleDays = backup.customCycleDays
        item.firstBillDate = backup.firstBillDate
        item.nextRenewalDate = backup.nextRenewalDate
        item.category = backup.category
        item.notes = backup.notes
        item.reminderDaysBefore = backup.reminderDaysBefore
        item.isActive = backup.isActive
        item.isPaused = backup.isPaused
        item.createdAt = backup.createdAt
        item.lastModified = backup.lastModified ?? backup.updatedAt
    }

    private func importBill(_ backup: BackupBill, into context: NSManagedObjectContext) throws {
        let bill = Bill(context: context)
        bill.id = backup.id ?? UUID(uuidString: backup.clientRecordID)
        bill.name = backup.name
        bill.amount = backup.amount
        bill.isRecurring = backup.isRecurring
        bill.frequency = backup.frequency
        bill.dueDate = backup.dueDate
        bill.originalDueDate = backup.originalDueDate
        bill.category = backup.category
        bill.iconName = backup.iconName
        bill.colorHex = backup.colorHex
        bill.notes = backup.notes
        bill.reminderDaysBefore = backup.reminderDaysBefore
        bill.isPaid = backup.isPaid
        bill.paidDate = backup.paidDate
        bill.paidAmount = backup.paidAmount
        bill.isAutoPay = backup.isAutoPay
        bill.createdAt = backup.createdAt
        bill.lastModified = backup.lastModified ?? backup.updatedAt
    }

    private func importBillPayment(_ backup: BackupBillPayment, into context: NSManagedObjectContext) throws {
        let payment = BillPayment(context: context)
        payment.id = backup.id ?? UUID(uuidString: backup.clientRecordID)
        payment.billID = backup.billID
        payment.dueDate = backup.dueDate
        payment.paidDate = backup.paidDate
        payment.expectedAmount = backup.expectedAmount
        payment.actualAmount = backup.actualAmount
        payment.notes = backup.notes
        payment.wasLate = backup.wasLate
        payment.daysLate = backup.daysLate
        payment.createdAt = backup.createdAt
    }

    private func importSnapshot(_ backup: BackupFinancialSnapshot, into context: NSManagedObjectContext) throws {
        let snapshot = FinancialSnapshot(context: context)
        snapshot.id = backup.id ?? UUID(uuidString: backup.clientRecordID)
        snapshot.date = backup.date
        snapshot.snapshotType = backup.snapshotType
        snapshot.totalIncome = backup.totalIncome
        snapshot.totalExpense = backup.totalExpense
        snapshot.balance = backup.balance
        snapshot.netFlow = backup.netFlow
        snapshot.savingsAmount = backup.savingsAmount
        snapshot.healthScore = backup.healthScore
        snapshot.savingsRate = backup.savingsRate
        snapshot.categoryBreakdown = backup.categoryBreakdown
        snapshot.createdAt = backup.createdAt ?? backup.updatedAt
    }
}
