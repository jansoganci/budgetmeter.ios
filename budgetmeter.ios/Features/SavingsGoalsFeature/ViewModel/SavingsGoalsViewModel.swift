//
//  SavingsGoalsViewModel.swift
//  BudgetMeter
//
//  Created by BudgetMeter Team on 14.11.2025.
//

import Foundation
import CoreData
import Combine

@MainActor
final class SavingsGoalsViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var goals: [SavingsGoal] = []
    @Published private(set) var latestSummary: FinancialSummary?

    // MARK: - Private Properties

    private var cancellables = Set<AnyCancellable>()
    private let goalManager: SavingsGoalManager
    private let summaryBuilder: FinancialSummaryBuilder
    private let persistenceService: PersistenceService
    private var currencyCode: String = CurrencyHelper.defaultCurrencyCode()

    // MARK: - Initialization

    init(
        persistenceService: PersistenceService = .shared,
        goalManager: SavingsGoalManager? = nil,
        summaryBuilder: FinancialSummaryBuilder? = nil
    ) {
        self.persistenceService = persistenceService
        self.goalManager = goalManager ?? SavingsGoalManager(persistence: persistenceService)
        self.summaryBuilder = summaryBuilder ?? FinancialSummaryBuilder(context: persistenceService.viewContext)
        setupObservers()
        loadCurrency()
        loadGoals()
    }

    // MARK: - Setup

    private func setupObservers() {
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

        NotificationCenter.default.publisher(for: .currencyDidChange)
            .sink { [weak self] notification in
                self?.currencyDidChange(notification)
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .languageDidChange)
            .sink { [weak self] notification in
                self?.languageDidChange(notification)
            }
            .store(in: &cancellables)

        PremiumManager.shared.$isPremium
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    // MARK: - Computed Properties

    var primaryGoal: SavingsGoal? {
        goalManager.getPrimaryActiveGoal()
    }

    var activeGoals: [SavingsGoal] {
        goals.filter { $0.completedDate == nil && !$0.isArchived }
    }

    var completedGoals: [SavingsGoal] {
        goals.filter { $0.completedDate != nil && !$0.isArchived }
    }

    var totalSaved: Double {
        goalManager.getTotalSaved()
    }

    var totalTarget: Double {
        goalManager.getTotalTarget()
    }

    var overallProgress: Double {
        guard totalTarget > 0 else { return 0 }
        return (totalSaved / totalTarget) * 100
    }

    var canAddAnotherGoal: Bool {
        goalManager.canCreateAdditionalGoal()
    }

    // MARK: - Public Methods

    func loadGoals() {
        goals = goalManager.getActiveGoals()
        refreshSummary()
    }

    func refreshSummary() {
        latestSummary = summaryBuilder.build(selectedPeriod: .month)
    }

    func isPrimaryGoal(_ goal: SavingsGoal) -> Bool {
        guard let primary = primaryGoal, let goalID = goal.id, let primaryID = primary.id else {
            return false
        }
        return goalID == primaryID
    }

    func sharedPaceETAText(for goal: SavingsGoal) -> String? {
        guard isPrimaryGoal(goal), let summary = latestSummary else { return nil }
        let text = HomeDisplayMapping.formatSavingsETA(from: summary)
        return text.isEmpty ? nil : text
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

    func formatAmount(_ amount: Double, currencyCode: String? = nil) -> String {
        CurrencyHelper.format(
            amount: amount,
            currencyCode: RecordCurrencySupport.resolvedDisplayCode(storedCode: currencyCode ?? self.currencyCode)
        )
    }

    func formatAmount(for goal: SavingsGoal, _ amount: Double) -> String {
        formatAmount(amount, currencyCode: goal.currencyCode)
    }

    func formatProgress(_ goal: SavingsGoal) -> String {
        let progress = goalManager.calculateProgress(for: goal)
        return PercentageFormatter.formatInteger(progress)
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
            return "savings.no_target_date".localized(defaultValue: "No target date")
        }

        let calendar = Calendar.current
        let now = Date()

        if targetDate < now {
            return "savings.target_date_passed".localized(defaultValue: "Target date passed")
        }

        let components = calendar.dateComponents([.month, .day], from: now, to: targetDate)

        if let months = components.month, months > 0 {
            let formatString = "savings.months_remaining".localized(defaultValue: "\(months) month\(months == 1 ? "" : "s") remaining")
            return String(format: formatString, months)
        } else if let days = components.day, days > 0 {
            let formatString = "savings.days_remaining".localized(defaultValue: "\(days) day\(days == 1 ? "" : "s") remaining")
            return String(format: formatString, days)
        } else {
            return "savings.due_today".localized(defaultValue: "Due today")
        }
    }

    func requiredMonthlyText(_ goal: SavingsGoal) -> String? {
        guard goal.targetDate != nil else { return nil }
        guard let required = goalManager.calculateRequiredMonthlyContribution(for: goal) else {
            return nil
        }

        if required <= 0 {
            return "savings.goal_reached".localized(defaultValue: "Goal reached!")
        }

        return String(format: "savings.save_month".localized(defaultValue: "Save %@/month"), formatAmount(required))
    }

    func paceStatusText(_ goal: SavingsGoal) -> String {
        guard goal.targetDate != nil else { return "" }
        return goalManager.isPaceStatus(for: goal).displayText
    }

    func paceStatusColor(_ goal: SavingsGoal) -> String {
        guard goal.targetDate != nil else { return "textSecondary" }
        return goalManager.isPaceStatus(for: goal).color
    }

    func remainingAmountText(_ goal: SavingsGoal) -> String {
        let remaining = max(0, goal.targetAmount - goal.currentAmount)
        return formatAmount(remaining) + " " + "savings.to_go".localized(defaultValue: "to go")
    }

    // MARK: - Currency Management

    func loadCurrency() {
        let context = persistenceService.viewContext
        let fetchRequest: NSFetchRequest<AppSettings> = AppSettings.fetchRequest()
        if let settings = try? context.fetch(fetchRequest),
           let storedCode = settings.first?.preferredCurrencyCode,
           CurrencyHelper.supportedCurrencyCodes.contains(storedCode) {
            updateCurrency(code: storedCode)
        } else {
            updateCurrency(code: CurrencyHelper.defaultCurrencyCode())
        }
    }

    func updateCurrency(code: String) {
        let resolvedCode = CurrencyHelper.supportedCurrencyCodes.contains(code) ? code : CurrencyHelper.defaultCurrencyCode()
        currencyCode = resolvedCode
    }

    @objc func currencyDidChange(_ notification: Notification) {
        if let code = notification.userInfo?["code"] as? String {
            updateCurrency(code: code)
        } else {
            loadCurrency()
        }
    }

    @objc func languageDidChange(_ notification: Notification) {
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
}
