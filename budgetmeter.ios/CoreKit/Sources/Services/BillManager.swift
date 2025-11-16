//
//  BillManager.swift
//  BudgetMeter
//
//  Created by BudgetMeter Team on 14.11.2025.
//

import Foundation
import CoreData
import UserNotifications

/// Manages bill tracking, payments, and notifications
final class BillManager {

    // MARK: - Singleton
    static let shared = BillManager()

    // MARK: - Properties
    private let persistence = PersistenceService.shared
    private var context: NSManagedObjectContext {
        persistence.viewContext
    }

    // MARK: - Notification Names
    static let billAddedNotification = Notification.Name("BillAdded")
    static let billUpdatedNotification = Notification.Name("BillUpdated")
    static let billDeletedNotification = Notification.Name("BillDeleted")
    static let billPaidNotification = Notification.Name("BillPaid")

    // MARK: - Private Init
    private init() {}

    // MARK: - CRUD Operations

    /// Create a new bill
    @discardableResult
    func createBill(
        name: String,
        amount: Double,
        dueDate: Date,
        isRecurring: Bool = false,
        frequency: String? = nil,
        category: String = "Other",
        notes: String? = nil,
        reminderDaysBefore: Int = 3,
        isAutoPay: Bool = false,
        iconName: String? = nil,
        colorHex: String? = nil
    ) -> Bill? {

        let bill = Bill(context: context)
        bill.id = UUID()
        bill.name = name
        bill.amount = amount
        bill.dueDate = dueDate
        bill.originalDueDate = dueDate // Store original for recurring bills
        bill.isRecurring = isRecurring
        bill.frequency = frequency
        bill.category = category
        bill.notes = notes
        bill.reminderDaysBefore = Int16(reminderDaysBefore)
        bill.isPaid = false
        bill.isAutoPay = isAutoPay
        bill.iconName = iconName
        bill.colorHex = colorHex
        bill.createdAt = Date()
        bill.lastModified = Date()

        guard persistence.save() else {
            print("❌ BillManager: Failed to create bill")
            return nil
        }

        // Schedule reminder notification if not on autopay
        if !isAutoPay {
            scheduleReminderNotification(for: bill)
        }

        // Post notification
        NotificationCenter.default.post(name: Self.billAddedNotification, object: bill)

        print("✅ BillManager: Created bill '\(name)'")
        return bill
    }

    /// Update an existing bill
    func updateBill(
        id: UUID,
        name: String? = nil,
        amount: Double? = nil,
        dueDate: Date? = nil,
        isRecurring: Bool? = nil,
        frequency: String? = nil,
        category: String? = nil,
        notes: String? = nil,
        reminderDaysBefore: Int? = nil,
        isAutoPay: Bool? = nil,
        iconName: String? = nil,
        colorHex: String? = nil
    ) -> Bool {

        guard let bill = fetchBill(by: id) else {
            print("❌ BillManager: Bill not found")
            return false
        }

        if let name = name { bill.name = name }
        if let amount = amount { bill.amount = amount }
        if let dueDate = dueDate { bill.dueDate = dueDate }
        if let isRecurring = isRecurring { bill.isRecurring = isRecurring }
        if let frequency = frequency { bill.frequency = frequency }
        if let category = category { bill.category = category }
        if let notes = notes { bill.notes = notes }
        if let reminderDaysBefore = reminderDaysBefore { bill.reminderDaysBefore = Int16(reminderDaysBefore) }
        if let isAutoPay = isAutoPay { bill.isAutoPay = isAutoPay }
        if let iconName = iconName { bill.iconName = iconName }
        if let colorHex = colorHex { bill.colorHex = colorHex }

        bill.lastModified = Date()

        guard persistence.save() else {
            print("❌ BillManager: Failed to update bill")
            return false
        }

        // Reschedule notifications
        cancelReminderNotification(for: bill)
        if !bill.isAutoPay {
            scheduleReminderNotification(for: bill)
        }

        NotificationCenter.default.post(name: Self.billUpdatedNotification, object: bill)

        print("✅ BillManager: Updated bill '\(bill.name ?? "")'")
        return true
    }

    /// Delete a bill
    func deleteBill(id: UUID) -> Bool {
        guard let bill = fetchBill(by: id) else {
            print("❌ BillManager: Bill not found")
            return false
        }

        // Cancel notifications
        cancelReminderNotification(for: bill)

        context.delete(bill)

        guard persistence.save() else {
            print("❌ BillManager: Failed to delete bill")
            return false
        }

        NotificationCenter.default.post(name: Self.billDeletedNotification, object: id)

        print("✅ BillManager: Deleted bill")
        return true
    }

    /// Mark a bill as paid
    func markAsPaid(id: UUID, paidAmount: Double? = nil, paidDate: Date = Date()) -> Bool {
        guard let bill = fetchBill(by: id) else { return false }

        bill.isPaid = true
        bill.paidDate = paidDate
        bill.paidAmount = paidAmount ?? bill.amount

        // If recurring, create next bill instance
        if bill.isRecurring, let frequency = bill.frequency {
            createNextRecurringBill(from: bill, frequency: frequency)
        }

        guard persistence.save() else { return false }

        // Cancel reminder since it's paid
        cancelReminderNotification(for: bill)

        NotificationCenter.default.post(name: Self.billPaidNotification, object: bill)
        return true
    }

    /// Mark a bill as unpaid
    func markAsUnpaid(id: UUID) -> Bool {
        guard let bill = fetchBill(by: id) else { return false }

        bill.isPaid = false
        bill.paidDate = nil
        bill.paidAmount = 0

        guard persistence.save() else { return false }

        // Reschedule reminder
        if !bill.isAutoPay {
            scheduleReminderNotification(for: bill)
        }

        NotificationCenter.default.post(name: Self.billUpdatedNotification, object: bill)
        return true
    }

    // MARK: - Fetch Operations

    /// Get all bills (paid and unpaid)
    func getAllBills() -> [Bill] {
        let request: NSFetchRequest<Bill> = Bill.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "dueDate", ascending: true)]

        do {
            return try context.fetch(request)
        } catch {
            print("❌ BillManager: Failed to fetch bills: \(error)")
            return []
        }
    }

    /// Get unpaid bills only
    func getUnpaidBills() -> [Bill] {
        let request: NSFetchRequest<Bill> = Bill.fetchRequest()
        request.predicate = NSPredicate(format: "isPaid == NO")
        request.sortDescriptors = [NSSortDescriptor(key: "dueDate", ascending: true)]

        do {
            return try context.fetch(request)
        } catch {
            print("❌ BillManager: Failed to fetch unpaid bills: \(error)")
            return []
        }
    }

    /// Get paid bills only
    func getPaidBills() -> [Bill] {
        let request: NSFetchRequest<Bill> = Bill.fetchRequest()
        request.predicate = NSPredicate(format: "isPaid == YES")
        request.sortDescriptors = [NSSortDescriptor(key: "paidDate", ascending: false)]

        do {
            return try context.fetch(request)
        } catch {
            print("❌ BillManager: Failed to fetch paid bills: \(error)")
            return []
        }
    }

    /// Get overdue bills
    func getOverdueBills() -> [Bill] {
        let now = Date()
        let request: NSFetchRequest<Bill> = Bill.fetchRequest()
        request.predicate = NSPredicate(format: "isPaid == NO AND dueDate < %@", now as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: "dueDate", ascending: true)]

        do {
            return try context.fetch(request)
        } catch {
            print("❌ BillManager: Failed to fetch overdue bills: \(error)")
            return []
        }
    }

    /// Get bills due soon (within specified days)
    func getDueSoonBills(days: Int = 7) -> [Bill] {
        let now = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: days, to: now) ?? now

        let request: NSFetchRequest<Bill> = Bill.fetchRequest()
        request.predicate = NSPredicate(
            format: "isPaid == NO AND dueDate >= %@ AND dueDate <= %@",
            now as CVarArg,
            endDate as CVarArg
        )
        request.sortDescriptors = [NSSortDescriptor(key: "dueDate", ascending: true)]

        do {
            return try context.fetch(request)
        } catch {
            print("❌ BillManager: Failed to fetch due soon bills: \(error)")
            return []
        }
    }

    /// Get bill by ID
    func fetchBill(by id: UUID) -> Bill? {
        let request: NSFetchRequest<Bill> = Bill.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1

        do {
            return try context.fetch(request).first
        } catch {
            print("❌ BillManager: Failed to fetch bill: \(error)")
            return nil
        }
    }

    /// Get bills for current month
    func getBillsForCurrentMonth() -> [Bill] {
        let calendar = Calendar.current
        let now = Date()

        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)),
              let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else {
            return []
        }

        let request: NSFetchRequest<Bill> = Bill.fetchRequest()
        request.predicate = NSPredicate(
            format: "dueDate >= %@ AND dueDate <= %@",
            startOfMonth as CVarArg,
            endOfMonth as CVarArg
        )
        request.sortDescriptors = [NSSortDescriptor(key: "dueDate", ascending: true)]

        do {
            return try context.fetch(request)
        } catch {
            print("❌ BillManager: Failed to fetch current month bills: \(error)")
            return []
        }
    }

    // MARK: - Calculations

    /// Get total amount due this month (unpaid bills only)
    func getTotalDueThisMonth() -> Double {
        let bills = getBillsForCurrentMonth().filter { !$0.isPaid }
        return bills.reduce(0.0) { $0 + $1.amount }
    }

    /// Get total paid this month
    func getTotalPaidThisMonth() -> Double {
        let bills = getBillsForCurrentMonth().filter { $0.isPaid }
        return bills.reduce(0.0) { $0 + $1.paidAmount }
    }

    // MARK: - Helper Methods

    /// Create next bill instance for recurring bills
    private func createNextRecurringBill(from bill: Bill, frequency: String) {
        guard let originalDueDate = bill.originalDueDate else { return }

        let calendar = Calendar.current
        var nextDueDate: Date?

        switch frequency.lowercased() {
        case "monthly":
            nextDueDate = calendar.date(byAdding: .month, value: 1, to: originalDueDate)
        case "yearly":
            nextDueDate = calendar.date(byAdding: .year, value: 1, to: originalDueDate)
        case "quarterly":
            nextDueDate = calendar.date(byAdding: .month, value: 3, to: originalDueDate)
        default:
            return
        }

        guard let nextDate = nextDueDate else { return }

        // Create new bill for next cycle
        createBill(
            name: bill.name ?? "",
            amount: bill.amount,
            dueDate: nextDate,
            isRecurring: true,
            frequency: frequency,
            category: bill.category,
            notes: bill.notes,
            reminderDaysBefore: Int(bill.reminderDaysBefore),
            isAutoPay: bill.isAutoPay,
            iconName: bill.iconName,
            colorHex: bill.colorHex
        )
    }

    // MARK: - Notifications

    /// Schedule reminder notification for bill
    private func scheduleReminderNotification(for bill: Bill) {
        guard !bill.isPaid, !bill.isAutoPay else { return }

        let notificationDate = Calendar.current.date(
            byAdding: .day,
            value: -Int(bill.reminderDaysBefore),
            to: bill.dueDate ?? Date()
        ) ?? Date()

        // Only schedule if in the future
        guard notificationDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Bill Due Soon"
        content.body = "\(bill.name ?? "Bill") ($\(String(format: "%.2f", bill.amount))) is due in \(bill.reminderDaysBefore) days"
        content.sound = .default
        content.categoryIdentifier = "BILL_REMINDER"
        content.userInfo = ["billID": bill.id?.uuidString ?? ""]

        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: notificationDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)

        let identifier = "bill-\(bill.id?.uuidString ?? "")"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ BillManager: Failed to schedule notification: \(error)")
            } else {
                print("✅ BillManager: Scheduled reminder notification for '\(bill.name ?? "")'")
            }
        }
    }

    /// Cancel reminder notification
    private func cancelReminderNotification(for bill: Bill) {
        let identifier = "bill-\(bill.id?.uuidString ?? "")"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    /// Reschedule all notifications
    func rescheduleAllNotifications() {
        let bills = getUnpaidBills()
        for bill in bills where !bill.isAutoPay {
            cancelReminderNotification(for: bill)
            scheduleReminderNotification(for: bill)
        }
        print("✅ BillManager: Rescheduled \(bills.count) notifications")
    }
}
