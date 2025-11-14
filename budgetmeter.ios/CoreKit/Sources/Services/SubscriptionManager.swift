//
//  SubscriptionManager.swift
//  BudgetMeter
//
//  Created by BudgetMeter Team on 13.11.2025.
//

import Foundation
import CoreData
import UserNotifications

/// Manages subscription tracking, renewals, and notifications
final class SubscriptionManager {

    // MARK: - Singleton
    static let shared = SubscriptionManager()

    // MARK: - Properties
    private let persistence = PersistenceService.shared
    private var context: NSManagedObjectContext {
        persistence.viewContext
    }

    // MARK: - Notification Names
    static let subscriptionAddedNotification = Notification.Name("SubscriptionAdded")
    static let subscriptionUpdatedNotification = Notification.Name("SubscriptionUpdated")
    static let subscriptionDeletedNotification = Notification.Name("SubscriptionDeleted")

    // MARK: - Private Init
    private init() {}

    // MARK: - CRUD Operations

    /// Create a new subscription
    @discardableResult
    func createSubscription(
        name: String,
        amount: Double,
        billingCycle: String,
        firstBillDate: Date,
        category: String = "Other",
        notes: String? = nil,
        reminderDaysBefore: Int = 3
    ) -> Subscription? {

        let subscription = Subscription(context: context)
        subscription.id = UUID()
        subscription.name = name
        subscription.amount = amount
        subscription.billingCycle = billingCycle
        subscription.firstBillDate = firstBillDate
        subscription.nextRenewalDate = calculateNextRenewalDate(from: firstBillDate, cycle: billingCycle)
        subscription.category = category
        subscription.notes = notes
        subscription.isActive = true
        subscription.isPaused = false
        subscription.reminderDaysBefore = Int16(reminderDaysBefore)
        subscription.createdAt = Date()
        subscription.lastModified = Date()

        guard persistence.save() else {
            print("❌ SubscriptionManager: Failed to create subscription")
            return nil
        }

        // Schedule renewal notification
        scheduleRenewalNotification(for: subscription)

        // Post notification
        NotificationCenter.default.post(name: Self.subscriptionAddedNotification, object: subscription)

        print("✅ SubscriptionManager: Created subscription '\(name)'")
        return subscription
    }

    /// Update an existing subscription
    func updateSubscription(
        id: UUID,
        name: String? = nil,
        amount: Double? = nil,
        billingCycle: String? = nil,
        category: String? = nil,
        notes: String? = nil,
        reminderDaysBefore: Int? = nil
    ) -> Bool {

        guard let subscription = fetchSubscription(by: id) else {
            print("❌ SubscriptionManager: Subscription not found")
            return false
        }

        if let name = name { subscription.name = name }
        if let amount = amount { subscription.amount = amount }
        if let billingCycle = billingCycle {
            subscription.billingCycle = billingCycle
            // Recalculate next renewal date
            subscription.nextRenewalDate = calculateNextRenewalDate(
                from: subscription.firstBillDate ?? Date(),
                cycle: billingCycle
            )
        }
        if let category = category { subscription.category = category }
        if let notes = notes { subscription.notes = notes }
        if let reminderDaysBefore = reminderDaysBefore { subscription.reminderDaysBefore = Int16(reminderDaysBefore) }

        subscription.lastModified = Date()

        guard persistence.save() else {
            print("❌ SubscriptionManager: Failed to update subscription")
            return false
        }

        // Reschedule notifications
        cancelRenewalNotification(for: subscription)
        scheduleRenewalNotification(for: subscription)

        NotificationCenter.default.post(name: Self.subscriptionUpdatedNotification, object: subscription)

        print("✅ SubscriptionManager: Updated subscription '\(subscription.name ?? "")'")
        return true
    }

    /// Delete a subscription
    func deleteSubscription(id: UUID) -> Bool {
        guard let subscription = fetchSubscription(by: id) else {
            print("❌ SubscriptionManager: Subscription not found")
            return false
        }

        // Cancel notifications
        cancelRenewalNotification(for: subscription)

        context.delete(subscription)

        guard persistence.save() else {
            print("❌ SubscriptionManager: Failed to delete subscription")
            return false
        }

        NotificationCenter.default.post(name: Self.subscriptionDeletedNotification, object: id)

        print("✅ SubscriptionManager: Deleted subscription")
        return true
    }

    /// Pause a subscription (stops notifications)
    func pauseSubscription(id: UUID) -> Bool {
        guard let subscription = fetchSubscription(by: id) else { return false }

        subscription.isPaused = true
        subscription.lastModified = Date()

        // Cancel notifications while paused
        cancelRenewalNotification(for: subscription)

        guard persistence.save() else { return false }

        NotificationCenter.default.post(name: Self.subscriptionUpdatedNotification, object: subscription)
        return true
    }

    /// Resume a paused subscription
    func resumeSubscription(id: UUID) -> Bool {
        guard let subscription = fetchSubscription(by: id) else { return false }

        subscription.isPaused = false
        subscription.lastModified = Date()

        // Re-schedule notifications
        scheduleRenewalNotification(for: subscription)

        guard persistence.save() else { return false }

        NotificationCenter.default.post(name: Self.subscriptionUpdatedNotification, object: subscription)
        return true
    }


    // MARK: - Fetch Operations

    /// Get all active subscriptions
    func getAllActiveSubscriptions() -> [Subscription] {
        let request: NSFetchRequest<Subscription> = Subscription.fetchRequest()
        request.predicate = NSPredicate(format: "isActive == YES AND isPaused == NO")
        request.sortDescriptors = [NSSortDescriptor(key: "nextRenewalDate", ascending: true)]

        do {
            return try context.fetch(request)
        } catch {
            print("❌ SubscriptionManager: Failed to fetch active subscriptions: \(error)")
            return []
        }
    }

    /// Get subscription by ID
    func fetchSubscription(by id: UUID) -> Subscription? {
        let request: NSFetchRequest<Subscription> = Subscription.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1

        do {
            return try context.fetch(request).first
        } catch {
            print("❌ SubscriptionManager: Failed to fetch subscription: \(error)")
            return nil
        }
    }

    /// Get upcoming renewals within specified days
    func getUpcomingRenewals(days: Int = 7) -> [Subscription] {
        let endDate = Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()

        let request: NSFetchRequest<Subscription> = Subscription.fetchRequest()
        request.predicate = NSPredicate(
            format: "isActive == YES AND isPaused == NO AND nextRenewalDate >= %@ AND nextRenewalDate <= %@",
            Date() as CVarArg,
            endDate as CVarArg
        )
        request.sortDescriptors = [NSSortDescriptor(key: "nextRenewalDate", ascending: true)]

        do {
            return try context.fetch(request)
        } catch {
            print("❌ SubscriptionManager: Failed to fetch upcoming renewals: \(error)")
            return []
        }
    }


    /// Get subscriptions grouped by category
    func getSubscriptionsByCategory() -> [String: [Subscription]] {
        let subscriptions = getAllActiveSubscriptions()
        return Dictionary(grouping: subscriptions) { $0.category ?? "Other" }
    }

    // MARK: - Cost Calculations

    /// Calculate total monthly cost of all active subscriptions
    func getTotalMonthlyCost() -> Double {
        let subscriptions = getAllActiveSubscriptions()
        return subscriptions.reduce(0.0) { total, subscription in
            total + calculateMonthlyCost(for: subscription)
        }
    }

    /// Calculate total yearly cost
    func getTotalYearlyCost() -> Double {
        return getTotalMonthlyCost() * 12
    }

    /// Calculate monthly cost for a single subscription
    private func calculateMonthlyCost(for subscription: Subscription) -> Double {
        switch subscription.billingCycle {
        case "monthly":
            return subscription.amount
        case "yearly":
            return subscription.amount / 12
        case "weekly":
            return subscription.amount * 4.33 // Average weeks per month
        case "custom":
            let days = Double(subscription.customCycleDays)
            if days > 0 {
                return (subscription.amount / days) * 30 // Approximate monthly
            }
            return subscription.amount
        default:
            return subscription.amount
        }
    }

    // MARK: - Date Calculations

    /// Calculate next renewal date based on billing cycle
    private func calculateNextRenewalDate(from startDate: Date, cycle: String) -> Date {
        let calendar = Calendar.current
        let now = Date()

        // If start date is in the future, use it
        if startDate > now {
            return startDate
        }

        var nextDate = startDate

        switch cycle {
        case "monthly":
            while nextDate <= now {
                nextDate = calendar.date(byAdding: .month, value: 1, to: nextDate) ?? nextDate
            }
        case "yearly":
            while nextDate <= now {
                nextDate = calendar.date(byAdding: .year, value: 1, to: nextDate) ?? nextDate
            }
        case "weekly":
            while nextDate <= now {
                nextDate = calendar.date(byAdding: .weekOfYear, value: 1, to: nextDate) ?? nextDate
            }
        default:
            // Default to monthly if unknown cycle
            nextDate = calendar.date(byAdding: .month, value: 1, to: startDate) ?? startDate
        }

        return nextDate
    }

    // MARK: - Notifications

    /// Schedule renewal notification for subscription
    private func scheduleRenewalNotification(for subscription: Subscription) {
        guard subscription.isActive, !subscription.isPaused else { return }

        let notificationDate = Calendar.current.date(
            byAdding: .day,
            value: -Int(subscription.reminderDaysBefore),
            to: subscription.nextRenewalDate ?? Date()
        ) ?? Date()

        // Only schedule if in the future
        guard notificationDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Subscription Renewing Soon"
        content.body = "\(subscription.name ?? "Subscription") ($\(String(format: "%.2f", subscription.amount))) renews in \(subscription.reminderDaysBefore) days"
        content.sound = .default
        content.categoryIdentifier = "SUBSCRIPTION_REMINDER"
        content.userInfo = ["subscriptionID": subscription.id?.uuidString ?? ""]

        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: notificationDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)

        let identifier = "subscription-\(subscription.id?.uuidString ?? "")"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ SubscriptionManager: Failed to schedule notification: \(error)")
            } else {
                print("✅ SubscriptionManager: Scheduled renewal notification for '\(subscription.name ?? "")'")
            }
        }
    }

    /// Cancel renewal notification
    private func cancelRenewalNotification(for subscription: Subscription) {
        let identifier = "subscription-\(subscription.id?.uuidString ?? "")"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    /// Reschedule all notifications (call after app updates or date changes)
    func rescheduleAllNotifications() {
        let subscriptions = getAllActiveSubscriptions()
        for subscription in subscriptions {
            cancelRenewalNotification(for: subscription)
            scheduleRenewalNotification(for: subscription)
        }
        print("✅ SubscriptionManager: Rescheduled \(subscriptions.count) notifications")
    }
}
