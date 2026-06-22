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
    private let persistence: PersistenceService
    private let syncService: SavingsGoalSyncScheduling
    private var context: NSManagedObjectContext {
        persistence.viewContext
    }

    // MARK: - Notification Names
    static let goalAddedNotification = Notification.Name("SavingsGoalAdded")
    static let goalUpdatedNotification = Notification.Name("SavingsGoalUpdated")
    static let goalDeletedNotification = Notification.Name("SavingsGoalDeleted")
    static let goalCompletedNotification = Notification.Name("SavingsGoalCompleted")

    // MARK: - Init
    init(
        persistence: PersistenceService = .shared,
        syncService: SavingsGoalSyncScheduling = SupabaseSavingsGoalSyncService.shared
    ) {
        self.persistence = persistence
        self.syncService = syncService
    }

    // MARK: - CRUD Operations

    /// Whether the user may create another savings goal (first goal always allowed on free tier).
    func canCreateAdditionalGoal() -> Bool {
        canCreateAdditionalGoal(in: context)
    }

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
        notes: String? = nil,
        enforceFreeGoalLimit: Bool = true
    ) -> SavingsGoal? {
        if enforceFreeGoalLimit && !canCreateAdditionalGoal(in: context) {
            print("❌ SavingsGoalManager: Savings goal limit reached")
            return nil
        }

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
        goal.priority = 0
        goal.createdAt = Date()
        goal.lastModified = Date()
        RecordCurrencySupport.stampCurrencyCodeIfNeeded(on: goal)
        markPendingSync(for: goal)

        guard persistence.save() else {
            print("❌ SavingsGoalManager: Failed to create goal")
            return nil
        }

        // Post notification
        NotificationCenter.default.post(name: Self.goalAddedNotification, object: goal)
        syncService.scheduleSync()

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
        markPendingSync(for: goal)

        guard persistence.save() else {
            print("❌ SavingsGoalManager: Failed to update goal")
            return false
        }

        NotificationCenter.default.post(name: Self.goalUpdatedNotification, object: goal)
        syncService.scheduleSync()

        print("✅ SavingsGoalManager: Updated goal '\(goal.name ?? "")'")
        return true
    }

    /// Delete a goal
    func deleteGoal(id: UUID) -> Bool {
        guard let goal = fetchGoal(by: id) else {
            print("❌ SavingsGoalManager: Goal not found")
            return false
        }

        goal.deletedAt = Date()
        goal.lastModified = Date()
        markPendingSync(for: goal)

        guard persistence.save() else {
            print("❌ SavingsGoalManager: Failed to delete goal")
            return false
        }

        NotificationCenter.default.post(name: Self.goalDeletedNotification, object: id)
        syncService.scheduleSync()

        print("✅ SavingsGoalManager: Deleted goal")
        return true
    }

    /// Add money to a goal
    func addMoney(to goalID: UUID, amount: Double, note: String? = nil) -> Bool {
        guard let goal = fetchGoal(by: goalID) else { return false }
        guard amount > 0 else { return false }

        goal.currentAmount += amount
        goal.lastModified = Date()
        goal.deletedAt = nil
        markPendingSync(for: goal)

        // Check if goal is now complete
        let wasCompleted = goal.completedDate != nil
        if !wasCompleted && goal.currentAmount >= goal.targetAmount {
            completeGoal(goal)
        }

        guard persistence.save() else { return false }

        NotificationCenter.default.post(name: Self.goalUpdatedNotification, object: goal)
        syncService.scheduleSync()
        return true
    }

    /// Withdraw money from a goal
    func withdrawMoney(from goalID: UUID, amount: Double, note: String? = nil) -> Bool {
        guard let goal = fetchGoal(by: goalID) else { return false }
        guard amount > 0 else { return false }
        guard goal.currentAmount >= amount else { return false }

        goal.currentAmount -= amount
        goal.lastModified = Date()
        goal.deletedAt = nil
        markPendingSync(for: goal)

        // If it was completed and now it's not, unmark completion
        if goal.completedDate != nil && goal.currentAmount < goal.targetAmount {
            goal.completedDate = nil
        }

        guard persistence.save() else { return false }

        NotificationCenter.default.post(name: Self.goalUpdatedNotification, object: goal)
        syncService.scheduleSync()
        return true
    }

    /// Mark goal as completed
    func markAsCompleted(id: UUID) -> Bool {
        guard let goal = fetchGoal(by: id) else { return false }

        goal.currentAmount = goal.targetAmount
        completeGoal(goal)

        guard persistence.save() else { return false }

        NotificationCenter.default.post(name: Self.goalCompletedNotification, object: goal)
        syncService.scheduleSync()
        return true
    }

    /// Archive a goal
    func archiveGoal(id: UUID) -> Bool {
        guard let goal = fetchGoal(by: id) else { return false }

        goal.isArchived = true
        goal.archivedDate = Date()
        goal.lastModified = Date()
        markPendingSync(for: goal)

        guard persistence.save() else { return false }

        NotificationCenter.default.post(name: Self.goalUpdatedNotification, object: goal)
        syncService.scheduleSync()
        return true
    }

    /// Unarchive a goal
    func unarchiveGoal(id: UUID) -> Bool {
        guard let goal = fetchGoal(by: id) else { return false }

        goal.isArchived = false
        goal.archivedDate = nil
        goal.lastModified = Date()
        markPendingSync(for: goal)

        guard persistence.save() else { return false }

        NotificationCenter.default.post(name: Self.goalUpdatedNotification, object: goal)
        syncService.scheduleSync()
        return true
    }

    // MARK: - Fetch Operations

    /// Get all active (non-archived) goals
    func getActiveGoals() -> [SavingsGoal] {
        let request: NSFetchRequest<SavingsGoal> = SavingsGoal.fetchRequest()
        request.predicate = NSPredicate(format: "isArchived == NO AND deletedAt == nil")

        do {
            return Self.sortedGoals(try context.fetch(request))
        } catch {
            print("❌ SavingsGoalManager: Failed to fetch active goals: \(error)")
            return []
        }
    }

    /// Get the deterministic primary active savings goal used by Home and summary calculations.
    func getPrimaryActiveGoal() -> SavingsGoal? {
        Self.primaryActiveGoal(in: context)
    }

    /// Fetch the deterministic primary active savings goal from a supplied context.
    static func primaryActiveGoal(in context: NSManagedObjectContext) -> SavingsGoal? {
        let request: NSFetchRequest<SavingsGoal> = SavingsGoal.fetchRequest()
        request.predicate = NSPredicate(format: "isArchived == NO AND deletedAt == nil")

        do {
            let nonArchivedGoals = try context.fetch(request)
            let inProgressGoals = nonArchivedGoals.filter { $0.completedDate == nil }
            if let inProgressPrimary = sortedGoals(inProgressGoals).first {
                return inProgressPrimary
            }

            let completedGoals = nonArchivedGoals.filter { $0.completedDate != nil }
            return sortedGoals(completedGoals).first
        } catch {
            print("❌ SavingsGoalManager: Failed to fetch primary active goal: \(error)")
            return nil
        }
    }

    /// Resolves savings target/current using the canonical source-of-truth rule.
    /// Priority: primary active goal -> AppSettings fallback target, current defaults to 0.
    static func resolvedSavingsTargetAndCurrent(in context: NSManagedObjectContext) -> (target: Double, current: Double) {
        if let primary = primaryActiveGoal(in: context) {
            return (target: primary.targetAmount, current: primary.currentAmount)
        }

        let settingsRequest: NSFetchRequest<AppSettings> = AppSettings.fetchRequest()
        settingsRequest.fetchLimit = 1
        let legacyTarget = (try? context.fetch(settingsRequest).first?.savingsGoalAmount) ?? 0
        return (target: legacyTarget, current: 0)
    }

    /// Get completed goals
    func getCompletedGoals() -> [SavingsGoal] {
        let request: NSFetchRequest<SavingsGoal> = SavingsGoal.fetchRequest()
        request.predicate = NSPredicate(format: "completedDate != nil AND isArchived == NO AND deletedAt == nil")
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
        request.predicate = NSPredicate(format: "completedDate == nil AND isArchived == NO AND deletedAt == nil")
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
        request.predicate = NSPredicate(format: "isArchived == YES AND deletedAt == nil")
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
        request.predicate = NSPredicate(format: "id == %@ AND deletedAt == nil", id as CVarArg)
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
    func isPaceStatus(for goal: SavingsGoal) -> SavingsGoalPaceStatus {
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

    /// Creates or updates the free basic savings goal used by Home quick entry.
    @discardableResult
    func upsertPrimaryBasicGoal(
        targetAmount: Double,
        name: String = "My Savings Goal"
    ) -> SavingsGoal? {
        let clampedTarget = max(0, targetAmount)

        if let existing = getPrimaryActiveGoal() {
            existing.targetAmount = clampedTarget
            existing.lastModified = Date()
            markPendingSync(for: existing)
            guard persistence.save() else { return nil }
            NotificationCenter.default.post(name: Self.goalUpdatedNotification, object: existing)
            syncService.scheduleSync()
            return existing
        }

        let goal = SavingsGoal(context: context)
        goal.id = UUID()
        goal.name = name
        goal.targetAmount = clampedTarget
        goal.currentAmount = 0
        goal.isArchived = false
        goal.priority = 0
        goal.emoji = "🎯"
        goal.createdAt = Date()
        goal.lastModified = Date()
        markPendingSync(for: goal)

        guard persistence.save() else { return nil }
        NotificationCenter.default.post(name: Self.goalAddedNotification, object: goal)
        syncService.scheduleSync()
        return goal
    }

    // MARK: - Private Methods

    private func completeGoal(_ goal: SavingsGoal) {
        guard goal.completedDate == nil else { return }
        goal.completedDate = Date()
        goal.lastModified = Date()
        markPendingSync(for: goal)
    }

    private func canCreateAdditionalGoal(in context: NSManagedObjectContext) -> Bool {
        if hasMultipleSavingsGoalsAccess(in: context) {
            return true
        }

        let request: NSFetchRequest<SavingsGoal> = SavingsGoal.fetchRequest()
        request.predicate = NSPredicate(format: "isArchived == NO AND deletedAt == nil")
        let count = (try? context.count(for: request)) ?? 0
        return count == 0
    }

    private func markPendingSync(for goal: SavingsGoal) {
        goal.syncStatus = SavingsGoalSyncStatus.pending.rawValue
        goal.lastSyncError = nil
        if goal.id == nil {
            goal.id = UUID()
        }
    }

    private func hasMultipleSavingsGoalsAccess(in context: NSManagedObjectContext) -> Bool {
        if isPremiumUser(in: context) {
            return true
        }

        #if DEBUG
        if UserDefaults.standard.bool(forKey: PremiumManager.debugPremiumOverrideKey) {
            return true
        }
        #endif

        if Thread.isMainThread {
            return MainActor.assumeIsolated {
                PremiumManager.shared.hasAccess(to: BudgetMeterCapability.multipleSavingsGoals)
            }
        }

        return false
    }

    private func isPremiumUser(in context: NSManagedObjectContext) -> Bool {
        let settingsRequest: NSFetchRequest<AppSettings> = AppSettings.fetchRequest()
        settingsRequest.fetchLimit = 1
        return (try? context.fetch(settingsRequest).first?.isPremiumUser) ?? false
    }

    private static func sortedGoals(_ goals: [SavingsGoal]) -> [SavingsGoal] {
        goals.sorted(by: compareGoals)
    }

    private static func compareGoals(_ lhs: SavingsGoal, _ rhs: SavingsGoal) -> Bool {
        let lhsPriority = normalizedPriority(for: lhs)
        let rhsPriority = normalizedPriority(for: rhs)
        if lhsPriority != rhsPriority { return lhsPriority < rhsPriority }

        let lhsCreatedAt = lhs.createdAt ?? .distantFuture
        let rhsCreatedAt = rhs.createdAt ?? .distantFuture
        if lhsCreatedAt != rhsCreatedAt { return lhsCreatedAt < rhsCreatedAt }

        let lhsTargetDate = lhs.targetDate ?? .distantFuture
        let rhsTargetDate = rhs.targetDate ?? .distantFuture
        if lhsTargetDate != rhsTargetDate { return lhsTargetDate < rhsTargetDate }

        let lhsName = lhs.name?.lowercased() ?? "\u{10FFFF}"
        let rhsName = rhs.name?.lowercased() ?? "\u{10FFFF}"
        if lhsName != rhsName { return lhsName < rhsName }

        let lhsID = lhs.id?.uuidString ?? "zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz"
        let rhsID = rhs.id?.uuidString ?? "zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz"
        return lhsID < rhsID
    }

    private static func normalizedPriority(for goal: SavingsGoal) -> Int {
        if let number = goal.primitiveValue(forKey: "priority") as? NSNumber {
            return number.intValue
        }
        return Int(Int16.max)
    }
}

// MARK: - Supporting Types

enum SavingsGoalPaceStatus {
    case ahead
    case onPace
    case behind
    case completed
    case unknown

    var displayText: String {
        switch self {
        case .ahead:
            return "savings.pace.ahead".localized(defaultValue: "Saving faster than planned", table: "UI")
        case .onPace:
            return "savings.pace.on_pace".localized(defaultValue: "On track for your date", table: "UI")
        case .behind:
            return "savings.pace.behind".localized(defaultValue: "Behind your plan", table: "UI")
        case .completed:
            return "savings.goal_reached".localized(defaultValue: "Goal reached!", table: "UI")
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
