//
//  SavingsGoalsViewModel.swift
//  BudgetMeter
//
//  Created by BudgetMeter Team on 14.11.2025.
//

import Foundation
import Combine

@MainActor
final class SavingsGoalsViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var goals: [SavingsGoal] = []

    // MARK: - Private Properties

    private var cancellables = Set<AnyCancellable>()
    private let goalManager = SavingsGoalManager.shared
    private let currencyCode = CurrencyHelper.defaultCurrencyCode()

    // MARK: - Initialization

    init() {
        setupObservers()
    }

    // MARK: - Setup

    private func setupObservers() {
        // Listen for goal changes
        NotificationCenter.default.publisher(for: SavingsGoalManager.goalAddedNotification)
            .sink { [weak self] _ in
                self?.loadGoals()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: SavingsGoalManager.goalUpdatedNotification)
            .sink { [weak self] _ in
                self?.loadGoals()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: SavingsGoalManager.goalDeletedNotification)
            .sink { [weak self] _ in
                self?.loadGoals()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: SavingsGoalManager.goalCompletedNotification)
            .sink { [weak self] _ in
                self?.loadGoals()
            }
            .store(in: &cancellables)
    }

    // MARK: - Computed Properties

    /// Active in-progress goals
    var activeGoals: [SavingsGoal] {
        goals.filter { $0.completedDate == nil && !$0.isArchived }
    }

    /// Completed goals
    var completedGoals: [SavingsGoal] {
        goals.filter { $0.completedDate != nil && !$0.isArchived }
    }

    /// Total saved across all goals
    var totalSaved: Double {
        goalManager.getTotalSaved()
    }

    /// Total target across all goals
    var totalTarget: Double {
        goalManager.getTotalTarget()
    }

    /// Overall progress percentage
    var overallProgress: Double {
        guard totalTarget > 0 else { return 0 }
        return (totalSaved / totalTarget) * 100
    }

    // MARK: - Public Methods

    func loadGoals() {
        goals = goalManager.getActiveGoals()
    }

    func deleteGoal(_ goal: SavingsGoal) {
        guard let id = goal.id else { return }
        _ = goalManager.deleteGoal(id: id)
    }

    func archiveGoal(_ goal: SavingsGoal) {
        guard let id = goal.id else { return }
        _ = goalManager.archiveGoal(id: id)
    }

    func markAsCompleted(_ goal: SavingsGoal) {
        guard let id = goal.id else { return }
        _ = goalManager.markAsCompleted(id: id)
    }

    // MARK: - Formatting

    func formatAmount(_ amount: Double) -> String {
        CurrencyHelper.format(amount: amount, currencyCode: currencyCode)
    }

    func formatProgress(_ goal: SavingsGoal) -> String {
        let progress = goalManager.calculateProgress(for: goal)
        return String(format: "%.0f%%", progress)
    }

    func formatProgressBar(_ goal: SavingsGoal) -> Double {
        return goalManager.calculateProgress(for: goal) / 100.0
    }

    func formatDate(_ date: Date) -> String {
        DateFormattingHelper.shared.formatMedium(date)
    }

    func formatShortDate(_ date: Date) -> String {
        DateFormattingHelper.shared.formatMonthYear(date)
    }

    func timeRemainingText(_ goal: SavingsGoal) -> String {
        guard let targetDate = goal.targetDate else {
            return "No target date"
        }

        let calendar = Calendar.current
        let now = Date()

        if targetDate < now {
            return "Target date passed"
        }

        let components = calendar.dateComponents([.month, .day], from: now, to: targetDate)

        if let months = components.month, months > 0 {
            return "\(months) month\(months == 1 ? "" : "s") remaining"
        } else if let days = components.day, days > 0 {
            return "\(days) day\(days == 1 ? "" : "s") remaining"
        } else {
            return "Due today"
        }
    }

    func requiredMonthlyText(_ goal: SavingsGoal) -> String? {
        guard let required = goalManager.calculateRequiredMonthlyContribution(for: goal) else {
            return nil
        }

        if required <= 0 {
            return "Goal reached!"
        }

        return "Save \(formatAmount(required))/month"
    }

    func paceStatusText(_ goal: SavingsGoal) -> String {
        return goalManager.isPaceStatus(for: goal).displayText
    }

    func paceStatusColor(_ goal: SavingsGoal) -> String {
        return goalManager.isPaceStatus(for: goal).color
    }

    func remainingAmountText(_ goal: SavingsGoal) -> String {
        let remaining = max(0, goal.targetAmount - goal.currentAmount)
        return formatAmount(remaining) + " to go"
    }
}
