//
//  NotificationSettingsViewModel.swift
//  BudgetMeter
//
//  Phase 1C: Smart Notifications UI
//  Created by BudgetMeter Team on 17.09.2025.
//

import Foundation
import SwiftUI
import UserNotifications
import Combine
import CoreData

/// ViewModel for notification settings screen
/// Manages notification preferences and backend integration
@MainActor
final class NotificationSettingsViewModel: ObservableObject {

    // MARK: - Published Properties

    /// Weekly summary notification enabled
    @Published var weeklyEnabled = false

    /// Weekly notification time
    @Published var weeklyTime = Date()

    /// Milestone alerts enabled
    @Published var milestonesEnabled = false

    /// Spending alerts enabled
    @Published var spendingEnabled = false

    /// Daily encouragement enabled (premium only)
    @Published var dailyEnabled = false

    /// Daily encouragement time
    @Published var dailyTime = Date()

    /// Premium status
    @Published var isPremium = false

    /// Notification permission status
    @Published var permissionStatus: UNAuthorizationStatus = .notDetermined

    /// Show premium paywall
    @Published var showPaywall = false

    /// Loading state
    @Published var isLoading = false

    /// Error message
    @Published var errorMessage: String?

    /// Show error alert
    @Published var showErrorAlert = false

    /// Show notification settings guidance
    @Published var showNotificationSettingsAlert = false

    /// Success message
    @Published var successMessage: String?

    /// Show success alert
    @Published var showSuccessAlert = false

    // MARK: - Private Properties

    private let persistenceService: PersistenceService
    private let notificationService: NotificationService
    private let premiumManager: PremiumManager
    private let supabaseAccountDataService: SupabaseAccountDataSyncing
    private let userDefaults: UserDefaults
    private var cancellables = Set<AnyCancellable>()

    private enum LocalKeys {
        static let dailyEncouragementTime = "DailyEncouragementTime"
    }

    // MARK: - Initialization

    init(
        persistenceService: PersistenceService = .shared,
        notificationService: NotificationService = .shared,
        premiumManager: PremiumManager = .shared,
        supabaseAccountDataService: SupabaseAccountDataSyncing = SupabaseAccountDataService.shared,
        userDefaults: UserDefaults = .standard
    ) {
        self.persistenceService = persistenceService
        self.notificationService = notificationService
        self.premiumManager = premiumManager
        self.supabaseAccountDataService = supabaseAccountDataService
        self.userDefaults = userDefaults

        setupObservers()
        loadSettings()
        checkPermissionStatus()
    }

    // MARK: - Public Methods

    /// Load notification settings from AppSettings
    func loadSettings() {
        let context = persistenceService.viewContext
        let fetchRequest: NSFetchRequest<AppSettings> = AppSettings.fetchRequest()

        do {
            let settings = try context.fetch(fetchRequest)
            if let appSettings = settings.first {
                weeklyEnabled = appSettings.weeklySummaryEnabled
                weeklyTime = appSettings.weeklySummaryTime ?? createDefaultWeeklyTime()
                milestonesEnabled = appSettings.milestonesEnabled
                spendingEnabled = appSettings.spendingAlertsEnabled
                dailyEnabled = appSettings.dailyEncouragementEnabled
                dailyTime = loadPersistedDailyTime()

                print("📱 NotificationSettings: Loaded settings - Weekly: \(weeklyEnabled), Milestones: \(milestonesEnabled), Spending: \(spendingEnabled), Daily: \(dailyEnabled)")
            } else {
                // Create default settings
                let newSettings = AppSettings(context: context)
                newSettings.weeklySummaryEnabled = true
                newSettings.weeklySummaryTime = createDefaultWeeklyTime()
                newSettings.milestonesEnabled = true
                newSettings.spendingAlertsEnabled = true
                newSettings.dailyEncouragementEnabled = false

                persistenceService.save()

                weeklyEnabled = true
                weeklyTime = createDefaultWeeklyTime()
                milestonesEnabled = true
                spendingEnabled = true
                dailyEnabled = false
                dailyTime = loadPersistedDailyTime()

                print("📱 NotificationSettings: Created default settings")
            }
        } catch {
            print("📱 NotificationSettings: ❌ Failed to load settings: \(error)")
            errorMessage = "notifications.error.load_failed".localized(defaultValue: "Failed to load notification settings")
        }
    }

    /// Save notification settings to AppSettings
    func saveSettings() {
        let context = persistenceService.viewContext
        let fetchRequest: NSFetchRequest<AppSettings> = AppSettings.fetchRequest()

        do {
            let settings = try context.fetch(fetchRequest)
            let appSettings: AppSettings

            if let existing = settings.first {
                appSettings = existing
            } else {
                appSettings = AppSettings(context: context)
            }

            appSettings.weeklySummaryEnabled = weeklyEnabled
            appSettings.weeklySummaryTime = weeklyTime
            appSettings.milestonesEnabled = milestonesEnabled
            appSettings.spendingAlertsEnabled = spendingEnabled
            appSettings.dailyEncouragementEnabled = dailyEnabled
            persistDailyTime(dailyTime)

            persistenceService.save()

            Task {
                await supabaseAccountDataService.pushNotificationPreferences(
                    dailyEncouragementEnabled: dailyEnabled,
                    weeklySummaryEnabled: weeklyEnabled,
                    milestonesEnabled: milestonesEnabled,
                    spendingAlertsEnabled: spendingEnabled,
                    dailyTime: dailyTime,
                    weeklySummaryTime: weeklyTime
                )
            }

            print("📱 NotificationSettings: ✅ Saved settings")
        } catch {
            print("📱 NotificationSettings: ❌ Failed to save settings: \(error)")
            errorMessage = "notifications.error.save_failed".localized(defaultValue: "Failed to save notification settings")
        }
    }

    /// Toggle weekly summary notifications
    func toggleWeekly(_ enabled: Bool) {
        guard permissionStatus == .authorized || !enabled else {
            showError("Please enable notifications in Settings first")
            weeklyEnabled = false
            return
        }

        weeklyEnabled = enabled
        saveSettings()

        if enabled {
            notificationService.scheduleWeeklySummary()
            print("📱 NotificationSettings: ✅ Scheduled weekly summary")
        } else {
            // Cancel weekly notifications
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["weekly-summary"])
            print("📱 NotificationSettings: ❌ Cancelled weekly summary")
        }
    }

    /// Update weekly notification time
    func updateWeeklyTime(_ time: Date) {
        weeklyTime = time
        saveSettings()

        if weeklyEnabled {
            notificationService.scheduleWeeklySummary()
            print("📱 NotificationSettings: ⏰ Updated weekly time to \(time)")
        }
    }

    /// Toggle milestone alerts
    func toggleMilestones(_ enabled: Bool) {
        milestonesEnabled = enabled
        saveSettings()
        print("📱 NotificationSettings: Milestones \(enabled ? "enabled" : "disabled")")
    }

    /// Toggle spending alerts
    func toggleSpending(_ enabled: Bool) {
        spendingEnabled = enabled
        saveSettings()
        print("📱 NotificationSettings: Spending alerts \(enabled ? "enabled" : "disabled")")
    }

    /// Toggle daily encouragement (premium feature)
    func toggleDaily(_ enabled: Bool) {
        // Check premium status
        guard premiumManager.hasAdvancedNotifications else {
            showPaywall = true
            dailyEnabled = false
            print("📱 NotificationSettings: ⭐ Premium required for daily encouragement")
            return
        }

        guard enabled else {
            dailyEnabled = false
            saveSettings()
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily-encouragement"])
            print("📱 NotificationSettings: ❌ Cancelled daily encouragement")
            return
        }

        switch permissionStatus {
        case .authorized, .provisional, .ephemeral:
            enableDailyEncouragement()
        case .notDetermined:
            dailyEnabled = false
            Task {
                await requestDailyNotificationPermissionAndEnable()
            }
        case .denied:
            dailyEnabled = false
            showNotificationSettingsAlert = true
        @unknown default:
            dailyEnabled = false
            showNotificationSettingsAlert = true
        }
    }

    /// Request notification permission before enabling daily encouragement.
    func requestDailyNotificationPermissionAndEnable() async {
        let granted = await requestPermissions()

        if granted {
            enableDailyEncouragement()
        } else {
            dailyEnabled = false
            saveSettings()
            showNotificationSettingsAlert = true
        }
    }

    /// Enable and schedule daily encouragement after permission is usable.
    func enableDailyEncouragement() {
        dailyEnabled = true
        saveSettings()
        notificationService.scheduleDailyEncouragement()
        print("📱 NotificationSettings: ✅ Scheduled daily encouragement")
    }

    /// Whether current permission status can deliver user-visible notifications.
    var hasUsableNotificationPermission: Bool {
        permissionStatus == .authorized || permissionStatus == .provisional || permissionStatus == .ephemeral
    }

    /// Update daily notification time
    func updateDailyTime(_ time: Date) {
        dailyTime = time
        saveSettings()

        if dailyEnabled && premiumManager.hasAdvancedNotifications {
            notificationService.scheduleDailyEncouragement()
            print("📱 NotificationSettings: ⏰ Updated daily time to \(time)")
        }
    }

    /// Request notification permissions from iOS
    func requestPermissions() async -> Bool {
        do {
            let granted = await withCheckedContinuation { continuation in
                notificationService.requestPermissions { granted in
                    continuation.resume(returning: granted)
                }
            }
            await checkPermissionStatus()

            if granted {
                print("📱 NotificationSettings: ✅ Permissions granted")
            } else {
                print("📱 NotificationSettings: ❌ Permissions denied")
            }

            return granted
        } catch {
            print("📱 NotificationSettings: ❌ Permission request failed: \(error)")
            errorMessage = "notifications.error.permission_failed".localized(defaultValue: "Failed to request notification permissions")
            return false
        }
    }

    /// Check current notification permission status
    func checkPermissionStatus() {
        Task {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            await MainActor.run {
                permissionStatus = settings.authorizationStatus
                print("📱 NotificationSettings: Permission status: \(settings.authorizationStatus.rawValue)")
            }
        }
    }

    /// Send test notification
    func sendTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Test Notification"
        content.body = "Your notifications are working! You'll receive updates about your financial progress."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let request = UNNotificationRequest(identifier: "test-notification", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("📱 NotificationSettings: ❌ Test notification failed: \(error)")
            } else {
                print("📱 NotificationSettings: ✅ Test notification sent")
            }
        }
    }

    /// Open iOS Settings app
    func openSystemSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
            print("📱 NotificationSettings: Opening system settings")
        }
    }

    /// Dismiss paywall
    func dismissPaywall() {
        showPaywall = false

        // Recheck premium status after dismissal
        isPremium = premiumManager.hasAdvancedNotifications

        print("📱 NotificationSettings: Paywall dismissed, premium: \(isPremium)")
    }

    // MARK: - Private Methods

    private func setupObservers() {
        // Observe premium status changes
        premiumManager.$isPremium
            .sink { [weak self] isPremium in
                self?.isPremium = PremiumManager.hasAccess(to: BudgetMeterCapability.advancedNotifications, isPremium: isPremium)

                // Auto-enable daily encouragement if user upgrades
                if PremiumManager.hasAccess(to: BudgetMeterCapability.advancedNotifications, isPremium: isPremium), let self = self {
                    print("📱 NotificationSettings: User upgraded to premium")
                }
            }
            .store(in: &cancellables)

        // Observe AppSettings changes
        NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                // Reload settings if changed externally
                print("📱 NotificationSettings: Core Data changed, reloading...")
            }
            .store(in: &cancellables)

        // Listen for language changes
        NotificationCenter.default.publisher(for: .languageDidChange)
            .sink { [weak self] _ in
                // Trigger UI refresh to re-evaluate localized strings
                DispatchQueue.main.async {
                    self?.objectWillChange.send()
                }
            }
            .store(in: &cancellables)
    }

    private func createDefaultWeeklyTime() -> Date {
        // Sunday at 6:00 PM
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: Date())
        components.weekday = 1 // Sunday
        components.hour = 18
        components.minute = 0
        return calendar.date(from: components) ?? Date()
    }

    private func createDefaultDailyTime() -> Date {
        // Every day at 9:00 AM
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: Date())
        components.hour = 9
        components.minute = 0
        return calendar.date(from: components) ?? Date()
    }

    private func loadPersistedDailyTime() -> Date {
        if let storedTime = userDefaults.object(forKey: LocalKeys.dailyEncouragementTime) as? Date {
            return storedTime
        }
        let defaultTime = createDefaultDailyTime()
        userDefaults.set(defaultTime, forKey: LocalKeys.dailyEncouragementTime)
        return defaultTime
    }

    private func persistDailyTime(_ time: Date) {
        userDefaults.set(time, forKey: LocalKeys.dailyEncouragementTime)
    }

    /// Show error message to user
    private func showError(_ message: String) {
        errorMessage = message
        showErrorAlert = true
        print("📱 NotificationSettings: ❌ Error: \(message)")
    }

    /// Show success message to user
    private func showSuccess(_ message: String) {
        successMessage = message
        showSuccessAlert = true
        print("📱 NotificationSettings: ✅ Success: \(message)")
    }

    /// Clear error state
    func clearError() {
        errorMessage = nil
        showErrorAlert = false
    }

    /// Clear success state
    func clearSuccess() {
        successMessage = nil
        showSuccessAlert = false
    }
}
