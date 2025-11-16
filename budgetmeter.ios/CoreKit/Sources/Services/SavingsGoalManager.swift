//
//  SavingsGoalManager.swift
//  BudgetMeter
//
//  Created by BudgetMeter Team on 14.11.2025.
//

import Foundation
import CoreData

/// Manages savings goals, progress tracking, and contributions
final class SavingsGoalManager {

    // MARK: - Singleton
    static let shared = SavingsGoalManager()

    // MARK: - Properties
    private let persistence = PersistenceService.shared
    private var context: NSManagedObjectContext {
        persistence.viewContext
    }

    // MARK: - Notification Names
    static let goalAddedNotification = Notification.Name("SavingsGoalAdded")
    static let goalUpdatedNotification = Notification.Name("SavingsGoalUpdated")
    static let goalDeletedNotification = Notification.Name("SavingsGoalDeleted")
    static let goalCompletedNotification = Notification.Name("SavingsGoalCompleted")

    // MARK: - Private Init
    private init() {}

    // MARK: - CRUD Operations

    /// Create a new savings goal
    @discardableResult
    func createGoal(
        name: String,
        targetAmount: Double,
        currentAmount: Double = 0,
        targetDate: Date? = nil,
        emoji: String? = nil,
        colorHex: String? = nil,
        category: String? = nil,
        notes: String? = nil
    ) -> SavingsGoal? {

        let goal = SavingsGoal(context: context)
        goal.id = UUID()
        goal.name = name
        goal.targetAmount = targetAmount
        goal.currentAmount = currentAmount
        goal.targetDate = targetDate
        goal.emoji = emoji
        goal.colorHex = colorHex
        goal.category = category
        goal.notes = notes
        goal.isArchived = false
        goal.createdAt = Date()
        goal.lastModified = Date()

        guard persistence.save() else {
            print("❌ SavingsGoalManager: Failed to create goal")
            return nil
        }

        // Post notification
        NotificationCenter.default.post(name: Self.goalAddedNotification, object: goal)

        print("✅ SavingsGoalManager: Created goal '\(name)'")
        return goal
    }

    /// Update an existing goal
    func updateGoal(
        id: UUID,
        name: String? = nil,
        targetAmount: Double? = nil,
        targetDate: Date? = nil,
        emoji: String? = nil,
        colorHex: String? = nil,
        category: String? = nil,
        notes: String? = nil
    ) -> Bool {

        guard let goal = fetchGoal(by: id) else {
            print("❌ SavingsGoalManager: Goal not found")
            return false
        }

        if let name = name { goal.name = name }
        if let targetAmount = targetAmount { goal.targetAmount = targetAmount }
        if let targetDate = targetDate { goal.targetDate = targetDate }
        if let emoji = emoji { goal.emoji = emoji }
        if let colorHex = colorHex { goal.colorHex = colorHex }
        if let category = category { goal.category = category }
        if let notes = notes { goal.notes = notes }

        goal.lastModified = Date()

        guard persistence.save() else {
            print("❌ SavingsGoalManager: Failed to update goal")
            return false
        }

        NotificationCenter.default.post(name: Self.goalUpdatedNotification, object: goal)

        print("✅ SavingsGoalManager: Updated goal '\(goal.name ?? "")'")
        return true
    }

    /// Delete a goal
    func deleteGoal(id: UUID) -> Bool {
        guard let goal = fetchGoal(by: id) else {
            print("❌ SavingsGoalManager: Goal not found")
            return false
        }

        context.delete(goal)

        guard persistence.save() else {
            print("❌ SavingsGoalManager: Failed to delete goal")
            return false
        }

        NotificationCenter.default.post(name: Self.goalDeletedNotification, object: id)

        print("✅ SavingsGoalManager: Deleted goal")
        return true
    }

    /// Add money to a goal
    func addMoney(to goalID: UUID, amount: Double, note: String? = nil) -> Bool {
        guard let goal = fetchGoal(by: goalID) else { return false }
        guard amount > 0 else { return false }

        goal.currentAmount += amount
        goal.lastModified = Date()

        // Check if goal is now complete
        let wasCompleted = goal.completedDate != nil
        if !wasCompleted && goal.currentAmount >= goal.targetAmount {
            completeGoal(goal)
        }

        guard persistence.save() else { return false }

        NotificationCenter.default.post(name: Self.goalUpdatedNotification, object: goal)
        return true
    }

    /// Withdraw money from a goal
    func withdrawMoney(from goalID: UUID, amount: Double, note: String? = nil) -> Bool {
        guard let goal = fetchGoal(by: goalID) else { return false }
        guard amount > 0 else { return false }
        guard goal.currentAmount >= amount else { return false }

        goal.currentAmount -= amount
        goal.lastModified = Date()

        // If it was completed and now it's not, unmark completion
        if goal.completedDate != nil && goal.currentAmount < goal.targetAmount {
            goal.completedDate = nil
        }

        guard persistence.save() else { return false }

        NotificationCenter.default.post(name: Self.goalUpdatedNotification, object: goal)
        return true
    }

    /// Mark goal as completed
    func markAsCompleted(id: UUID) -> Bool {
        guard let goal = fetchGoal(by: id) else { return false }

        goal.currentAmount = goal.targetAmount
        completeGoal(goal)

        guard persistence.save() else { return false }

        NotificationCenter.default.post(name: Self.goalCompletedNotification, object: goal)
        return true
    }

    /// Archive a goal
    func archiveGoal(id: UUID) -> Bool {
        guard let goal = fetchGoal(by: id) else { return false }

        goal.isArchived = true
        goal.archivedDate = Date()
        goal.lastModified = Date()

        guard persistence.save() else { return false }

        NotificationCenter.default.post(name: Self.goalUpdatedNotification, object: goal)
        return true
    }

    /// Unarchive a goal
    func unarchiveGoal(id: UUID) -> Bool {
        guard let goal = fetchGoal(by: id) else { return false }

        goal.isArchived = false
        goal.archivedDate = nil
        goal.lastModified = Date()

        guard persistence.save() else { return false }

        NotificationCenter.default.post(name: Self.goalUpdatedNotification, object: goal)
        return true
    }

    // MARK: - Fetch Operations

    /// Get all active (non-archived) goals
    func getActiveGoals() -> [SavingsGoal] {
        let request: NSFetchRequest<SavingsGoal> = SavingsGoal.fetchRequest()
        request.predicate = NSPredicate(format: "isArchived == NO")
        request.sortDescriptors = [
            NSSortDescriptor(key: "completedDate", ascending: true), // Completed goals last
            NSSortDescriptor(key: "targetDate", ascending: true)
        ]

        do {
            return try context.fetch(request)
        } catch {
            print("❌ SavingsGoalManager: Failed to fetch active goals: \(error)")
            return []
        }
    }

    /// Get completed goals
    func getCompletedGoals() -> [SavingsGoal] {
        let request: NSFetchRequest<SavingsGoal> = SavingsGoal.fetchRequest()
        request.predicate = NSPredicate(format: "completedDate != nil AND isArchived == NO")
        request.sortDescriptors = [NSSortDescriptor(key: "completedDate", ascending: false)]

        do {
            return try context.fetch(request)
        } catch {
            print("❌ SavingsGoalManager: Failed to fetch completed goals: \(error)")
            return []
        }
    }

    /// Get in-progress goals (active but not completed)
    func getInProgressGoals() -> [SavingsGoal] {
        let request: NSFetchRequest<SavingsGoal> = SavingsGoal.fetchRequest()
        request.predicate = NSPredicate(format: "completedDate == nil AND isArchived == NO")
        request.sortDescriptors = [NSSortDescriptor(key: "targetDate", ascending: true)]

        do {
            return try context.fetch(request)
        } catch {
            print("❌ SavingsGoalManager: Failed to fetch in-progress goals: \(error)")
            return []
        }
    }

    /// Get archived goals
    func getArchivedGoals() -> [SavingsGoal] {
        let request: NSFetchRequest<SavingsGoal> = SavingsGoal.fetchRequest()
        request.predicate = NSPredicate(format: "isArchived == YES")
        request.sortDescriptors = [NSSortDescriptor(key: "archivedDate", ascending: false)]

        do {
            return try context.fetch(request)
        } catch {
            print("❌ SavingsGoalManager: Failed to fetch archived goals: \(error)")
            return []
        }
    }

    /// Get goal by ID
    func fetchGoal(by id: UUID) -> SavingsGoal? {
        let request: NSFetchRequest<SavingsGoal> = SavingsGoal.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1

        do {
            return try context.fetch(request).first
        } catch {
            print("❌ SavingsGoalManager: Failed to fetch goal: \(error)")
            return nil
        }
    }

    // MARK: - Calculations

    /// Calculate progress percentage for a goal
    func calculateProgress(for goal: SavingsGoal) -> Double {
        guard goal.targetAmount > 0 else { return 0 }
        let progress = (goal.currentAmount / goal.targetAmount) * 100
        return min(progress, 100)
    }

    /// Calculate required monthly contribution to reach goal by target date
    func calculateRequiredMonthlyContribution(for goal: SavingsGoal) -> Double? {
        guard let targetDate = goal.targetDate else { return nil }
        guard targetDate > Date() else { return nil }

        let remaining = goal.targetAmount - goal.currentAmount
        guard remaining > 0 else { return 0 }

        let calendar = Calendar.current
        let months = calendar.dateComponents([.month], from: Date(), to: targetDate).month ?? 0
        guard months > 0 else { return remaining } // Less than a month away

        return remaining / Double(months)
    }

    /// Calculate if goal is on pace to meet target date
    func isPaceStatus(for goal: SavingsGoal) -> PaceStatus {
        guard let required = calculateRequiredMonthlyContribution(for: goal) else {
            return .unknown
        }

        guard required > 0 else {
            return .completed
        }

        // Simple heuristic: check if current amount is >= expected amount at this point
        guard let targetDate = goal.targetDate else { return .unknown }
        guard let createdAt = goal.createdAt else { return .unknown }

        let calendar = Calendar.current
        let totalMonths = calendar.dateComponents([.month], from: createdAt, to: targetDate).month ?? 1
        let elapsedMonths = calendar.dateComponents([.month], from: createdAt, to: Date()).month ?? 0

        guard totalMonths > 0 else { return .unknown }

        let expectedProgress = Double(elapsedMonths) / Double(totalMonths)
        let expectedAmount = goal.targetAmount * expectedProgress
        let actualAmount = goal.currentAmount

        if actualAmount >= expectedAmount * 1.1 {
            return .ahead // 10% ahead
        } else if actualAmount >= expectedAmount * 0.9 {
            return .onPace // Within 10%
        } else {
            return .behind // More than 10% behind
        }
    }

    /// Get total saved across all active goals
    func getTotalSaved() -> Double {
        return getActiveGoals().reduce(0) { $0 + $1.currentAmount }
    }

    /// Get total target across all active goals
    func getTotalTarget() -> Double {
        return getActiveGoals().reduce(0) { $0 + $1.targetAmount }
    }

    // MARK: - Private Methods

    private func completeGoal(_ goal: SavingsGoal) {
        guard goal.completedDate == nil else { return }
        goal.completedDate = Date()
        goal.lastModified = Date()
    }
}

// MARK: - Supporting Types

enum PaceStatus {
    case ahead
    case onPace
    case behind
    case completed
    case unknown

    var displayText: String {
        switch self {
        case .ahead:
            return "Ahead of pace!"
        case .onPace:
            return "On pace"
        case .behind:
            return "Behind pace"
        case .completed:
            return "Goal reached!"
        case .unknown:
            return ""
        }
    }

    var color: String {
        switch self {
        case .ahead:
            return "brandProgress"
        case .onPace:
            return "brandProgress"
        case .behind:
            return "orange"
        case .completed:
            return "brandProgress"
        case .unknown:
            return "textSecondary"
        }
    }
}
