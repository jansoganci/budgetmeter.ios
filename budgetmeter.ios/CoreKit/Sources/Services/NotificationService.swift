//
//  NotificationService.swift
//  BudgetMeter
//
//  Created by BudgetMeter Team on 17.09.2025.
//

import Foundation
import UserNotifications
import CoreData

/// Service for managing smart notifications
final class NotificationService {

    // MARK: - Singleton

    static let shared = NotificationService()

    private let persistenceService: PersistenceService
    private let insightsService: InsightsService
    private let notificationCenter = UNUserNotificationCenter.current()

    // Notification identifiers
    private enum NotificationID {
        static let weeklySummary = "weekly-summary"
        static let milestonePositiveStreak = "milestone-positive-streak"
        static let milestoneGoalProgress = "milestone-goal-progress"
        static let spendingAlert = "spending-alert"
        static let goalAchievement = "goal-achievement"
        static let dailyEncouragement = "daily-encouragement"
    }

    // MARK: - Initialization

    private init(
        persistenceService: PersistenceService = .shared,
        insightsService: InsightsService = .shared
    ) {
        self.persistenceService = persistenceService
        self.insightsService = insightsService
    }

    // MARK: - Permission Management

    /// Request notification permissions
    func requestPermissions(completion: @escaping (Bool) -> Void) {
        notificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("🔔 NotificationService: ❌ Permission request error: \(error)")
            }

            print("🔔 NotificationService: Permissions \(granted ? "granted" : "denied")")
            completion(granted)
        }
    }

    /// Check current notification permission status
    func checkPermissionStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
        notificationCenter.getNotificationSettings { settings in
            completion(settings.authorizationStatus)
        }
    }

    // MARK: - Weekly Summary

    /// Schedule weekly summary notification
    func scheduleWeeklySummary() {
        checkPermissionStatus { [weak self] status in
            guard status == .authorized else { return }

            guard let self = self else { return }

            let context = self.persistenceService.viewContext
            let settingsRequest: NSFetchRequest<AppSettings> = AppSettings.fetchRequest()

            guard let settings = try? context.fetch(settingsRequest).first,
                  settings.weeklySummaryEnabled else {
                return
            }

            // Get summary time (default: Sunday 6 PM)
            let summaryTime = settings.weeklySummaryTime ?? self.defaultWeeklySummaryTime()

            let calendar = Calendar.current
            let components = calendar.dateComponents([.hour, .minute], from: summaryTime)

            // Create content
            let content = self.createWeeklySummaryContent()

            // Trigger every Sunday
            var dateComponents = DateComponents()
            dateComponents.weekday = 1 // Sunday
            dateComponents.hour = components.hour
            dateComponents.minute = components.minute

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

            let request = UNNotificationRequest(
                identifier: NotificationID.weeklySummary,
                content: content,
                trigger: trigger
            )

            self.notificationCenter.add(request) { error in
                if let error = error {
                    print("🔔 NotificationService: ❌ Failed to schedule weekly summary: \(error)")
                } else {
                    print("🔔 NotificationService: ✅ Weekly summary scheduled")
                }
            }
        }
    }

    /// Create weekly summary notification content
    private func createWeeklySummaryContent() -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "📊 Weekly Summary"

        // Get financial data
        if let financialData = getCurrentFinancialData() {
            let savingsAmount = max(0, financialData.totalIncome - financialData.totalExpense)
            let formattedSavings = CurrencyHelper.formatAmount(savingsAmount)
            let formattedBalance = CurrencyHelper.formatAmount(financialData.balance)

            if savingsAmount > 0 {
                content.body = "You saved \(formattedSavings) this week! Balance: \(formattedBalance)"
            } else {
                content.body = "Your balance: \(formattedBalance). Tap for insights."
            }

            content.subtitle = "Tap to see your weekly overview"
        } else {
            content.body = "Check your financial progress this week"
        }

        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "WEEKLY_SUMMARY"
        content.userInfo = ["type": "weekly_summary"]

        return content
    }

    // MARK: - Milestone Notifications

    /// Check and send milestone notifications
    func checkMilestones() {
        checkPermissionStatus { [weak self] status in
            guard status == .authorized else { return }
            guard let self = self else { return }

            let context = self.persistenceService.viewContext
            let settingsRequest: NSFetchRequest<AppSettings> = AppSettings.fetchRequest()

            guard let settings = try? context.fetch(settingsRequest).first,
                  settings.milestonesEnabled else {
                return
            }

            // Check positive streak
            self.checkPositiveStreakMilestone()

            // Check goal progress
            self.checkGoalProgressMilestone()
        }
    }

    /// Check for positive balance streak milestone
    private func checkPositiveStreakMilestone() {
        let snapshots = HistoricalDataService.shared.getDailyTrend(days: 7)

        guard snapshots.count == 7 else { return }

        let allPositive = snapshots.allSatisfy { $0.balance >= 0 }

        guard allPositive else { return }

        // Check if we already sent this notification recently
        let context = persistenceService.viewContext
        let settingsRequest: NSFetchRequest<AppSettings> = AppSettings.fetchRequest()

        guard let settings = try? context.fetch(settingsRequest).first else { return }

        if let lastCheck = settings.lastMilestoneCheck,
           Date().timeIntervalSince(lastCheck) < 7 * 24 * 60 * 60 {
            return // Don't spam - wait 7 days between milestone checks
        }

        // Send notification
        let content = UNMutableNotificationContent()
        content.title = "🎉 Achievement Unlocked!"
        content.body = "Your balance has been positive for 7 days straight! Keep up the great work!"
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "MILESTONE"
        content.userInfo = ["type": "milestone_positive_streak"]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        let request = UNNotificationRequest(
            identifier: NotificationID.milestonePositiveStreak,
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request) { [weak self] error in
            if error == nil {
                // Update last check
                settings.lastMilestoneCheck = Date()
                self?.persistenceService.save()
            }
        }
    }

    /// Check goal progress milestones (25%, 50%, 75%, 100%)
    private func checkGoalProgressMilestone() {
        guard let financialData = getCurrentFinancialData() else { return }

        let context = persistenceService.viewContext
        let settingsRequest: NSFetchRequest<AppSettings> = AppSettings.fetchRequest()

        guard let settings = try? context.fetch(settingsRequest).first,
              settings.savingsGoalAmount > 0 else {
            return
        }

        let savingsGoal = settings.savingsGoalAmount
        let savingsAmount = max(0, financialData.totalIncome - financialData.totalExpense)

        let progress = savingsAmount / savingsGoal
        let percentage = Int(progress * 100)

        // Check for milestone percentages
        let milestones = [25, 50, 75, 100]

        for milestone in milestones {
            if percentage >= milestone && percentage < milestone + 5 {
                sendGoalProgressNotification(percentage: milestone, goal: savingsGoal)
                break
            }
        }
    }

    /// Send goal progress notification
    private func sendGoalProgressNotification(percentage: Int, goal: Double) {
        let content = UNMutableNotificationContent()

        if percentage == 100 {
            content.title = "💰 Goal Achieved!"
            content.body = "Congratulations! You hit your \(CurrencyHelper.formatAmount(goal)) savings goal!"
        } else {
            content.title = "🎯 Goal Progress"
            content.body = "You're \(percentage)% of the way to your \(CurrencyHelper.formatAmount(goal)) goal!"

            let remaining = goal * Double(100 - percentage) / 100
            content.subtitle = "Only \(CurrencyHelper.formatAmount(remaining)) to go!"
        }

        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "MILESTONE"
        content.userInfo = ["type": "milestone_goal_progress", "percentage": percentage]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        let request = UNNotificationRequest(
            identifier: "\(NotificationID.milestoneGoalProgress)-\(percentage)",
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request)
    }

    // MARK: - Spending Alert

    /// Check for spending alerts (spending up >20%)
    func checkSpendingAlert() {
        checkPermissionStatus { [weak self] status in
            guard status == .authorized else { return }
            guard let self = self else { return }

            let context = self.persistenceService.viewContext
            let settingsRequest: NSFetchRequest<AppSettings> = AppSettings.fetchRequest()

            guard let settings = try? context.fetch(settingsRequest).first,
                  settings.spendingAlertsEnabled else {
                return
            }

            // Get last 2 weeks of snapshots
            let calendar = Calendar.current
            let endDate = Date()
            guard let startDate = calendar.date(byAdding: .day, value: -14, to: endDate) else { return }

            let snapshots = HistoricalDataService.shared.getSnapshots(from: startDate, to: endDate, type: "daily")

            guard snapshots.count >= 14 else { return }

            // Split into this week and last week
            let thisWeek = snapshots.suffix(7)
            let lastWeek = snapshots.prefix(7)

            let thisWeekExpense = thisWeek.reduce(0) { $0 + $1.totalExpense } / 7.0
            let lastWeekExpense = lastWeek.reduce(0) { $0 + $1.totalExpense } / 7.0

            guard lastWeekExpense > 0 else { return }

            let percentageChange = ((thisWeekExpense - lastWeekExpense) / lastWeekExpense) * 100

            // Alert if spending is up >20%
            if percentageChange > 20 {
                self.sendSpendingAlert(
                    thisWeek: thisWeekExpense * 7,
                    lastWeek: lastWeekExpense * 7,
                    percentage: percentageChange
                )
            }
        }
    }

    /// Send spending alert notification
    private func sendSpendingAlert(thisWeek: Double, lastWeek: Double, percentage: Double) {
        let content = UNMutableNotificationContent()
        content.title = "⚠️ Spending Alert"
        content.body = "You're spending \(String(format: "%.0f", percentage))% more than last week"

        let formattedThis = CurrencyHelper.formatAmount(thisWeek)
        let formattedLast = CurrencyHelper.formatAmount(lastWeek)
        content.subtitle = "This week: \(formattedThis) | Last week: \(formattedLast)"

        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "SPENDING_ALERT"
        content.userInfo = ["type": "spending_alert"]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        let request = UNNotificationRequest(
            identifier: NotificationID.spendingAlert,
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request)
    }

    // MARK: - Daily Encouragement

    /// Schedule daily encouragement (premium feature)
    func scheduleDailyEncouragement() {
        checkPermissionStatus { [weak self] status in
            guard status == .authorized else { return }
            guard let self = self else { return }

            let context = self.persistenceService.viewContext
            let settingsRequest: NSFetchRequest<AppSettings> = AppSettings.fetchRequest()

            guard let settings = try? context.fetch(settingsRequest).first,
                  settings.dailyEncouragementEnabled,
                  settings.isPremiumUser else {
                return
            }

            // Schedule for 9 AM daily
            var dateComponents = DateComponents()
            dateComponents.hour = 9
            dateComponents.minute = 0

            let content = self.createDailyEncouragementContent()

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

            let request = UNNotificationRequest(
                identifier: NotificationID.dailyEncouragement,
                content: content,
                trigger: trigger
            )

            self.notificationCenter.add(request) { error in
                if let error = error {
                    print("🔔 NotificationService: ❌ Failed to schedule daily encouragement: \(error)")
                } else {
                    print("🔔 NotificationService: ✅ Daily encouragement scheduled")
                }
            }
        }
    }

    /// Create daily encouragement content
    private func createDailyEncouragementContent() -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()

        if let financialData = getCurrentFinancialData() {
            let settingsRequest: NSFetchRequest<AppSettings> = AppSettings.fetchRequest()
            let settings = try? persistenceService.viewContext.fetch(settingsRequest).first
            let savingsGoal = settings?.savingsGoalAmount ?? 0.0

            let healthScore = CalculationEngine.calculateFinancialHealthScore(
                monthlyIncome: financialData.totalIncome,
                monthlyExpense: financialData.totalExpense,
                savingsGoal: savingsGoal
            )

            let scoreText = CalculationEngine.healthScoreText(for: healthScore)

            content.title = "💪 Daily Reminder"
            content.body = "Your financial health score is \(healthScore) - \(scoreText)!"
            content.subtitle = "Keep up the great work!"
        } else {
            content.title = "💪 Daily Reminder"
            content.body = "Stay on track with your financial goals today!"
        }

        content.sound = .default
        content.categoryIdentifier = "DAILY_ENCOURAGEMENT"
        content.userInfo = ["type": "daily_encouragement"]

        return content
    }

    // MARK: - Notification Management

    /// Cancel all notifications
    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        print("🔔 NotificationService: Cancelled all notifications")
    }

    /// Cancel specific notification
    func cancelNotification(identifier: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    /// Get pending notifications
    func getPendingNotifications(completion: @escaping ([UNNotificationRequest]) -> Void) {
        notificationCenter.getPendingNotificationRequests(completionHandler: completion)
    }

    // MARK: - Helper Methods

    private func defaultWeeklySummaryTime() -> Date {
        let calendar = Calendar.current
        var components = DateComponents()
        components.hour = 18 // 6 PM
        components.minute = 0
        return calendar.date(from: components) ?? Date()
    }

    private func getCurrentFinancialData() -> (totalIncome: Double, totalExpense: Double, balance: Double)? {
        let context = persistenceService.viewContext
        let request: NSFetchRequest<FinancialCategory> = FinancialCategory.fetchRequest()

        do {
            let categories = try context.fetch(request)

            let incomeCategories = categories.filter { $0.type == "income" }
            let expenseCategories = categories.filter { $0.type == "expense" }

            let dailyIncome = incomeCategories.filter { $0.frequency == "daily" }.reduce(0) { $0 + $1.amount }
            let monthlyIncome = incomeCategories.filter { $0.frequency == "monthly" }.reduce(0) { $0 + $1.amount }
            let yearlyIncome = incomeCategories.filter { $0.frequency == "yearly" }.reduce(0) { $0 + $1.amount }

            let dailyExpense = expenseCategories.filter { $0.frequency == "daily" }.reduce(0) { $0 + $1.amount }
            let monthlyExpense = expenseCategories.filter { $0.frequency == "monthly" }.reduce(0) { $0 + $1.amount }
            let yearlyExpense = expenseCategories.filter { $0.frequency == "yearly" }.reduce(0) { $0 + $1.amount }

            let totalIncome = CalculationEngine.totalMonthlyIncome(
                dailyIncomeTotal: dailyIncome,
                monthlyIncomeTotal: monthlyIncome,
                yearlyIncomeTotal: yearlyIncome
            )

            let totalExpense = CalculationEngine.totalMonthlyExpense(
                dailyTotal: dailyExpense,
                monthlyTotal: monthlyExpense,
                yearlyTotal: yearlyExpense
            )

            let balance = totalIncome - totalExpense

            return (totalIncome, totalExpense, balance)
        } catch {
            print("🔔 NotificationService: ❌ Failed to fetch financial data: \(error)")
            return nil
        }
    }
}
