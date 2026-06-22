//
//  SupabaseAccountDataService.swift
//  BudgetMeter
//
//  Phase 1 account-level settings sync only (no financial data).
//

import CoreData
import Foundation
import Supabase
import UIKit

protocol SupabaseAccountDataSyncing {
    func bootstrapSignedInAccount(profileEmail: String?, provider: String?) async
    func pushPreferredCurrencyCode(_ code: String) async
    func pushSelectedTheme(_ theme: String) async
    func pushAppearanceMode(_ mode: String) async
    func pushLanguageCode(_ code: String) async
    func pushOnboardingCompleted(_ completed: Bool) async
    func pushNotificationPreferences(
        dailyEncouragementEnabled: Bool,
        weeklySummaryEnabled: Bool,
        milestonesEnabled: Bool,
        spendingAlertsEnabled: Bool,
        dailyTime: Date?,
        weeklySummaryTime: Date?
    ) async
}

protocol SupabaseAccountRemoteStoreProtocol {
    func currentAuthenticatedUserID() async -> UUID?
    func fetchProfile(userID: UUID) async throws -> SupabaseProfileRow?
    func upsertProfile(_ row: SupabaseProfileRow) async throws -> SupabaseProfileRow
    func fetchUserSettings(userID: UUID) async throws -> SupabaseUserSettingsRow?
    func upsertUserSettings(_ row: SupabaseUserSettingsRow) async throws -> SupabaseUserSettingsRow
    func updateUserSettings(userID: UUID, update: SupabaseUserSettingsUpdate) async throws -> SupabaseUserSettingsRow
    func fetchNotificationPreferences(userID: UUID) async throws -> SupabaseNotificationPreferencesRow?
    func upsertNotificationPreferences(_ row: SupabaseNotificationPreferencesRow) async throws -> SupabaseNotificationPreferencesRow
    func updateNotificationPreferences(userID: UUID, update: SupabaseNotificationPreferencesUpdate) async throws -> SupabaseNotificationPreferencesRow
}

enum SupabaseAccountRemoteStoreError: Error {
    case notConfigured
}

struct SupabaseAccountRemoteStore: SupabaseAccountRemoteStoreProtocol {
    private let clientProvider: () -> SupabaseClient?

    init(clientProvider: @escaping () -> SupabaseClient? = { SupabaseClientProvider.makeClient() }) {
        self.clientProvider = clientProvider
    }

    func currentAuthenticatedUserID() async -> UUID? {
        guard let client = clientProvider() else { return nil }
        do {
            return try await client.auth.session.user.id
        } catch {
            return nil
        }
    }

    func fetchProfile(userID: UUID) async throws -> SupabaseProfileRow? {
        let client = try requireClient()
        let rows: [SupabaseProfileRow] = try await client
            .from("profiles")
            .select()
            .eq("user_id", value: userID.uuidString)
            .limit(1)
            .execute()
            .value
        return rows.first
    }

    func upsertProfile(_ row: SupabaseProfileRow) async throws -> SupabaseProfileRow {
        let client = try requireClient()
        return try await client
            .from("profiles")
            .upsert(row, onConflict: "user_id")
            .select()
            .single()
            .execute()
            .value
    }

    func fetchUserSettings(userID: UUID) async throws -> SupabaseUserSettingsRow? {
        let client = try requireClient()
        let rows: [SupabaseUserSettingsRow] = try await client
            .from("user_settings")
            .select()
            .eq("user_id", value: userID.uuidString)
            .limit(1)
            .execute()
            .value
        return rows.first
    }

    func upsertUserSettings(_ row: SupabaseUserSettingsRow) async throws -> SupabaseUserSettingsRow {
        let client = try requireClient()
        return try await client
            .from("user_settings")
            .upsert(row, onConflict: "user_id")
            .select()
            .single()
            .execute()
            .value
    }

    func updateUserSettings(userID: UUID, update: SupabaseUserSettingsUpdate) async throws -> SupabaseUserSettingsRow {
        let client = try requireClient()
        return try await client
            .from("user_settings")
            .update(update)
            .eq("user_id", value: userID.uuidString)
            .select()
            .single()
            .execute()
            .value
    }

    func fetchNotificationPreferences(userID: UUID) async throws -> SupabaseNotificationPreferencesRow? {
        let client = try requireClient()
        let rows: [SupabaseNotificationPreferencesRow] = try await client
            .from("notification_preferences")
            .select()
            .eq("user_id", value: userID.uuidString)
            .limit(1)
            .execute()
            .value
        return rows.first
    }

    func upsertNotificationPreferences(_ row: SupabaseNotificationPreferencesRow) async throws -> SupabaseNotificationPreferencesRow {
        let client = try requireClient()
        return try await client
            .from("notification_preferences")
            .upsert(row, onConflict: "user_id")
            .select()
            .single()
            .execute()
            .value
    }

    func updateNotificationPreferences(
        userID: UUID,
        update: SupabaseNotificationPreferencesUpdate
    ) async throws -> SupabaseNotificationPreferencesRow {
        let client = try requireClient()
        return try await client
            .from("notification_preferences")
            .update(update)
            .eq("user_id", value: userID.uuidString)
            .select()
            .single()
            .execute()
            .value
    }

    private func requireClient() throws -> SupabaseClient {
        guard let client = clientProvider() else {
            throw SupabaseAccountRemoteStoreError.notConfigured
        }
        return client
    }
}

@MainActor
final class SupabaseAccountDataService: SupabaseAccountDataSyncing {
    static let shared = SupabaseAccountDataService()

    private let persistenceService: PersistenceService
    private let userDefaults: UserDefaults
    private let remoteStore: SupabaseAccountRemoteStoreProtocol

    private enum DefaultsKeys {
        static let onboardingCompleted = "hasCompletedOnboarding"
        static let appearanceMode = "AppearanceMode"
        static let languageMode = "LanguageMode"
        static let appLanguage = "AppLanguage"
        static let dailyEncouragementTime = "DailyEncouragementTime"
    }

    private enum SyncKind: String {
        case userSettings
        case notificationPreferences
    }

    init(
        persistenceService: PersistenceService = .shared,
        userDefaults: UserDefaults = .standard,
        remoteStore: SupabaseAccountRemoteStoreProtocol = SupabaseAccountRemoteStore()
    ) {
        self.persistenceService = persistenceService
        self.userDefaults = userDefaults
        self.remoteStore = remoteStore
    }

    func bootstrapSignedInAccount(profileEmail: String?, provider: String?) async {
        guard let userID = await remoteStore.currentAuthenticatedUserID() else { return }

        do {
            let localSettingsDefaults = loadLocalUserSettingsDefaults(userID: userID)
            let localNotificationDefaults = loadLocalNotificationDefaults(userID: userID)

            _ = try await loadOrCreateProfile(
                userID: userID,
                email: profileEmail,
                provider: provider
            )

            let userSettings = try await loadOrCreateUserSettings(
                userID: userID,
                fallback: localSettingsDefaults
            )
            let notificationPreferences = try await loadOrCreateNotificationPreferences(
                userID: userID,
                fallback: localNotificationDefaults
            )

            if shouldApplyRemote(updatedAt: userSettings.updatedAt, userID: userID, kind: .userSettings) {
                applyUserSettingsToLocalState(userSettings)
                storeServerTimestamp(userSettings.updatedAt, userID: userID, kind: .userSettings)
            }

            if shouldApplyRemote(updatedAt: notificationPreferences.updatedAt, userID: userID, kind: .notificationPreferences) {
                applyNotificationPreferencesToLocalState(notificationPreferences)
                storeServerTimestamp(notificationPreferences.updatedAt, userID: userID, kind: .notificationPreferences)
            }
        } catch {
            print("☁️ SupabaseAccountDataService: bootstrap skipped (\(error))")
        }
    }

    func pushPreferredCurrencyCode(_ code: String) async {
        await updateUserSettings(
            mutationKind: .userSettings,
            update: SupabaseUserSettingsUpdate(preferredCurrencyCode: code)
        )
    }

    func pushSelectedTheme(_ theme: String) async {
        await updateUserSettings(
            mutationKind: .userSettings,
            update: SupabaseUserSettingsUpdate(selectedTheme: theme)
        )
    }

    func pushAppearanceMode(_ mode: String) async {
        await updateUserSettings(
            mutationKind: .userSettings,
            update: SupabaseUserSettingsUpdate(appearanceMode: normalizedAppearanceMode(mode))
        )
    }

    func pushLanguageCode(_ code: String) async {
        await updateUserSettings(
            mutationKind: .userSettings,
            update: SupabaseUserSettingsUpdate(languageCode: code)
        )
    }

    func pushOnboardingCompleted(_ completed: Bool) async {
        await updateUserSettings(
            mutationKind: .userSettings,
            update: SupabaseUserSettingsUpdate(onboardingCompleted: completed)
        )
    }

    func pushNotificationPreferences(
        dailyEncouragementEnabled: Bool,
        weeklySummaryEnabled: Bool,
        milestonesEnabled: Bool,
        spendingAlertsEnabled: Bool,
        dailyTime: Date?,
        weeklySummaryTime: Date?
    ) async {
        let update = SupabaseNotificationPreferencesUpdate(
            dailyEncouragementEnabled: dailyEncouragementEnabled,
            weeklySummaryEnabled: weeklySummaryEnabled,
            milestonesEnabled: milestonesEnabled,
            spendingAlertsEnabled: spendingAlertsEnabled,
            dailyTime: sqlTime(from: dailyTime),
            weeklySummaryTime: sqlTime(from: weeklySummaryTime)
        )

        guard let userID = await remoteStore.currentAuthenticatedUserID() else { return }
        markLocalMutation(userID: userID, kind: .notificationPreferences)

        do {
            let row = try await remoteStore.updateNotificationPreferences(userID: userID, update: update)
            storeServerTimestamp(row.updatedAt, userID: userID, kind: .notificationPreferences)
        } catch {
            print("☁️ SupabaseAccountDataService: notification preferences update failed (\(error))")
            // TODO(Phase 1.1): add dirty-flag retry for failed account setting writes.
        }
    }

    // MARK: - Internal bootstrap helpers

    private func loadOrCreateProfile(
        userID: UUID,
        email: String?,
        provider: String?
    ) async throws -> SupabaseProfileRow {
        if let existing = try await remoteStore.fetchProfile(userID: userID) {
            return existing
        }

        let row = SupabaseProfileRow(
            userID: userID,
            email: email,
            displayName: nil,
            provider: provider,
            createdAt: nil,
            updatedAt: nil
        )
        return try await remoteStore.upsertProfile(row)
    }

    private func loadOrCreateUserSettings(
        userID: UUID,
        fallback: SupabaseUserSettingsRow
    ) async throws -> SupabaseUserSettingsRow {
        if let existing = try await remoteStore.fetchUserSettings(userID: userID) {
            return existing
        }
        return try await remoteStore.upsertUserSettings(fallback)
    }

    private func loadOrCreateNotificationPreferences(
        userID: UUID,
        fallback: SupabaseNotificationPreferencesRow
    ) async throws -> SupabaseNotificationPreferencesRow {
        if let existing = try await remoteStore.fetchNotificationPreferences(userID: userID) {
            return existing
        }
        return try await remoteStore.upsertNotificationPreferences(fallback)
    }

    private func updateUserSettings(mutationKind: SyncKind, update: SupabaseUserSettingsUpdate) async {
        guard let userID = await remoteStore.currentAuthenticatedUserID() else { return }
        markLocalMutation(userID: userID, kind: mutationKind)

        do {
            let row = try await remoteStore.updateUserSettings(userID: userID, update: update)
            storeServerTimestamp(row.updatedAt, userID: userID, kind: .userSettings)
        } catch {
            print("☁️ SupabaseAccountDataService: user settings update failed (\(error))")
            // TODO(Phase 1.1): add dirty-flag retry for failed account setting writes.
        }
    }

    // MARK: - Local read defaults

    private func loadLocalUserSettingsDefaults(userID: UUID) -> SupabaseUserSettingsRow {
        let context = persistenceService.viewContext
        let appSettings = fetchOrCreateAppSettings(context: context)
        let languageCode = userDefaults.string(forKey: DefaultsKeys.languageMode)
            ?? userDefaults.string(forKey: DefaultsKeys.appLanguage)
            ?? "en"

        let preferredCurrencyCode = normalizedCurrencyCode(
            appSettings.preferredCurrencyCode ?? CurrencyHelper.defaultCurrencyCode()
        )
        let selectedTheme = appSettings.selectedTheme ?? AppTheme.coral_default.rawValue

        return SupabaseUserSettingsRow(
            userID: userID,
            onboardingCompleted: userDefaults.bool(forKey: DefaultsKeys.onboardingCompleted),
            preferredCurrencyCode: preferredCurrencyCode,
            selectedTheme: selectedTheme,
            appearanceMode: normalizedAppearanceMode(
                userDefaults.string(forKey: DefaultsKeys.appearanceMode) ?? "System"
            ),
            languageCode: languageCode,
            createdAt: nil,
            updatedAt: nil
        )
    }

    private func loadLocalNotificationDefaults(userID: UUID) -> SupabaseNotificationPreferencesRow {
        let context = persistenceService.viewContext
        let appSettings = fetchOrCreateAppSettings(context: context)

        return SupabaseNotificationPreferencesRow(
            userID: userID,
            dailyEncouragementEnabled: appSettings.dailyEncouragementEnabled,
            weeklySummaryEnabled: appSettings.weeklySummaryEnabled,
            milestonesEnabled: appSettings.milestonesEnabled,
            spendingAlertsEnabled: appSettings.spendingAlertsEnabled,
            dailyTime: sqlTime(from: loadDailyEncouragementTime()),
            weeklySummaryTime: sqlTime(from: appSettings.weeklySummaryTime),
            createdAt: nil,
            updatedAt: nil
        )
    }

    // MARK: - Apply remote to local state

    private func applyUserSettingsToLocalState(_ remote: SupabaseUserSettingsRow) {
        userDefaults.set(remote.onboardingCompleted, forKey: DefaultsKeys.onboardingCompleted)
        userDefaults.set(displayAppearanceMode(from: remote.appearanceMode), forKey: DefaultsKeys.appearanceMode)
        userDefaults.set(remote.languageCode, forKey: DefaultsKeys.languageMode)
        userDefaults.set(remote.languageCode, forKey: DefaultsKeys.appLanguage)

        let context = persistenceService.viewContext
        let appSettings = fetchOrCreateAppSettings(context: context)
        appSettings.preferredCurrencyCode = normalizedCurrencyCode(remote.preferredCurrencyCode)
        appSettings.selectedTheme = remote.selectedTheme
        _ = persistenceService.save()

        LocalizationManager.shared.currentLanguage = remote.languageCode
        applyAppearanceModeToWindow(remote.appearanceMode)

        let resolvedTheme = AppTheme.resolved(from: remote.selectedTheme)
        ThemeManager.shared.applyTheme(resolvedTheme, shouldSyncToAccount: false)

        NotificationCenter.default.post(
            name: .currencyDidChange,
            object: nil,
            userInfo: ["code": normalizedCurrencyCode(remote.preferredCurrencyCode)]
        )
    }

    private func applyNotificationPreferencesToLocalState(_ remote: SupabaseNotificationPreferencesRow) {
        let context = persistenceService.viewContext
        let appSettings = fetchOrCreateAppSettings(context: context)
        appSettings.dailyEncouragementEnabled = remote.dailyEncouragementEnabled
        appSettings.weeklySummaryEnabled = remote.weeklySummaryEnabled
        appSettings.milestonesEnabled = remote.milestonesEnabled
        appSettings.spendingAlertsEnabled = remote.spendingAlertsEnabled
        appSettings.weeklySummaryTime = date(fromSQLTime: remote.weeklySummaryTime) ?? appSettings.weeklySummaryTime
        _ = persistenceService.save()

        if let remoteDailyTime = date(fromSQLTime: remote.dailyTime) {
            persistDailyEncouragementTime(remoteDailyTime)
        }
    }

    // MARK: - Conflict helpers

    private func shouldApplyRemote(updatedAt: Date?, userID: UUID, kind: SyncKind) -> Bool {
        guard let remoteUpdatedAt = updatedAt else { return true }
        guard let localMutationDate = userDefaults.object(forKey: localMutationKey(for: userID, kind: kind)) as? Date else {
            return true
        }
        return remoteUpdatedAt >= localMutationDate
    }

    private func markLocalMutation(userID: UUID, kind: SyncKind) {
        userDefaults.set(Date(), forKey: localMutationKey(for: userID, kind: kind))
    }

    private func storeServerTimestamp(_ date: Date?, userID: UUID, kind: SyncKind) {
        guard let date else { return }
        userDefaults.set(date, forKey: serverTimestampKey(for: userID, kind: kind))
        userDefaults.removeObject(forKey: localMutationKey(for: userID, kind: kind))
    }

    private func localMutationKey(for userID: UUID, kind: SyncKind) -> String {
        "supabase.phase1.\(kind.rawValue).localMutation.\(userID.uuidString)"
    }

    private func serverTimestampKey(for userID: UUID, kind: SyncKind) -> String {
        "supabase.phase1.\(kind.rawValue).serverUpdatedAt.\(userID.uuidString)"
    }

    // MARK: - Helpers

    private func fetchOrCreateAppSettings(context: NSManagedObjectContext) -> AppSettings {
        let request: NSFetchRequest<AppSettings> = AppSettings.fetchRequest()
        if let existing = try? context.fetch(request).first {
            return existing
        }
        return AppSettings(context: context)
    }

    private func normalizedCurrencyCode(_ code: String) -> String {
        let uppercased = code.uppercased()
        return CurrencyHelper.supportedCurrencyCodes.contains(uppercased)
            ? uppercased
            : CurrencyHelper.defaultCurrencyCode()
    }

    private func normalizedAppearanceMode(_ value: String) -> String {
        switch value.lowercased() {
        case "light":
            return "light"
        case "dark":
            return "dark"
        default:
            return "system"
        }
    }

    private func displayAppearanceMode(from remoteValue: String) -> String {
        switch remoteValue.lowercased() {
        case "light":
            return "Light"
        case "dark":
            return "Dark"
        default:
            return "System"
        }
    }

    private func sqlTime(from date: Date?) -> String? {
        guard let date else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }

    private func date(fromSQLTime sqlTime: String?) -> Date? {
        guard let sqlTime, !sqlTime.isEmpty else { return nil }

        let parser = DateFormatter()
        parser.locale = Locale(identifier: "en_US_POSIX")
        parser.timeZone = .current
        parser.dateFormat = "HH:mm:ss"
        let parsedDate = parser.date(from: sqlTime) ?? {
            parser.dateFormat = "HH:mm"
            return parser.date(from: sqlTime)
        }()
        guard let parsedDate else { return nil }

        let calendar = Calendar.current
        let parsedComponents = calendar.dateComponents([.hour, .minute, .second], from: parsedDate)
        var todayComponents = calendar.dateComponents([.year, .month, .day], from: Date())
        todayComponents.hour = parsedComponents.hour
        todayComponents.minute = parsedComponents.minute
        todayComponents.second = parsedComponents.second ?? 0
        return calendar.date(from: todayComponents)
    }

    private func persistDailyEncouragementTime(_ date: Date) {
        userDefaults.set(date, forKey: DefaultsKeys.dailyEncouragementTime)
    }

    private func loadDailyEncouragementTime() -> Date {
        if let stored = userDefaults.object(forKey: DefaultsKeys.dailyEncouragementTime) as? Date {
            return stored
        }
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = 9
        components.minute = 0
        components.second = 0
        return Calendar.current.date(from: components) ?? Date()
    }

    private func applyAppearanceModeToWindow(_ appearanceMode: String) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return
        }

        switch normalizedAppearanceMode(appearanceMode) {
        case "light":
            window.overrideUserInterfaceStyle = .light
        case "dark":
            window.overrideUserInterfaceStyle = .dark
        default:
            window.overrideUserInterfaceStyle = .unspecified
        }
    }
}
