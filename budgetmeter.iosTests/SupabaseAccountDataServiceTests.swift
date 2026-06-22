//
//  SupabaseAccountDataServiceTests.swift
//  budgetmeter.iosTests
//
//  Phase 1 Supabase account/settings integration tests.
//

import CoreData
import XCTest
@testable import budgetmeter_ios

@MainActor
final class SupabaseAccountDataServiceTests: XCTestCase {
    private var persistence: PersistenceService!
    private var context: NSManagedObjectContext!
    private var userDefaults: UserDefaults!
    private var userDefaultsSuiteName: String!
    private var remoteStore: MockSupabaseAccountRemoteStore!

    override func setUp() {
        super.setUp()
        persistence = PersistenceService.makeInMemoryForTesting()
        context = persistence.viewContext
        userDefaultsSuiteName = "SupabaseAccountDataServiceTests.\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: userDefaultsSuiteName)
        userDefaults.removePersistentDomain(forName: userDefaultsSuiteName)
        remoteStore = MockSupabaseAccountRemoteStore()
        remoteStore.currentUserID = UUID()
    }

    override func tearDown() {
        persistence = nil
        context = nil
        remoteStore = nil
        userDefaults?.removePersistentDomain(forName: userDefaultsSuiteName)
        userDefaults = nil
        userDefaultsSuiteName = nil
        super.tearDown()
    }

    func test_bootstrap_createsMissingRowsAndAppliesRemoteSettings() async {
        let userID = try! XCTUnwrap(remoteStore.currentUserID)
        remoteStore.fetchProfileResult = nil
        remoteStore.fetchUserSettingsResult = nil
        remoteStore.fetchNotificationPreferencesResult = nil

        remoteStore.upsertProfileResult = SupabaseProfileRow(
            userID: userID,
            email: "test@example.com",
            displayName: nil,
            provider: "email",
            createdAt: Date(),
            updatedAt: Date()
        )
        remoteStore.upsertUserSettingsResult = SupabaseUserSettingsRow(
            userID: userID,
            onboardingCompleted: true,
            preferredCurrencyCode: "EUR",
            selectedTheme: AppTheme.google_blue.rawValue,
            appearanceMode: "dark",
            languageCode: "tr",
            createdAt: Date(),
            updatedAt: Date()
        )
        remoteStore.upsertNotificationPreferencesResult = SupabaseNotificationPreferencesRow(
            userID: userID,
            dailyEncouragementEnabled: true,
            weeklySummaryEnabled: true,
            milestonesEnabled: true,
            spendingAlertsEnabled: false,
            dailyTime: "08:30:00",
            weeklySummaryTime: "18:00:00",
            createdAt: Date(),
            updatedAt: Date()
        )

        let service = SupabaseAccountDataService(
            persistenceService: persistence,
            userDefaults: userDefaults,
            remoteStore: remoteStore
        )

        await service.bootstrapSignedInAccount(profileEmail: "test@example.com", provider: "email")

        XCTAssertTrue(remoteStore.didUpsertProfile)
        XCTAssertTrue(remoteStore.didUpsertUserSettings)
        XCTAssertTrue(remoteStore.didUpsertNotificationPreferences)
        XCTAssertEqual(userDefaults.bool(forKey: "hasCompletedOnboarding"), true)
        XCTAssertEqual(userDefaults.string(forKey: "AppearanceMode"), "Dark")
        XCTAssertEqual(userDefaults.string(forKey: "LanguageMode"), "tr")

        let request: NSFetchRequest<AppSettings> = AppSettings.fetchRequest()
        let appSettings = try? context.fetch(request).first
        XCTAssertEqual(appSettings?.preferredCurrencyCode, "EUR")
        XCTAssertEqual(appSettings?.weeklySummaryEnabled, true)
        XCTAssertEqual(appSettings?.dailyEncouragementEnabled, true)
        XCTAssertEqual(appSettings?.spendingAlertsEnabled, false)
    }

    func test_bootstrap_usesExistingRows_withoutCreatingNewRows() async {
        let userID = try! XCTUnwrap(remoteStore.currentUserID)
        remoteStore.fetchProfileResult = SupabaseProfileRow(
            userID: userID,
            email: "existing@example.com",
            displayName: nil,
            provider: "email",
            createdAt: Date(),
            updatedAt: Date()
        )
        remoteStore.fetchUserSettingsResult = SupabaseUserSettingsRow(
            userID: userID,
            onboardingCompleted: false,
            preferredCurrencyCode: "USD",
            selectedTheme: AppTheme.coral_default.rawValue,
            appearanceMode: "system",
            languageCode: "en",
            createdAt: Date(),
            updatedAt: Date()
        )
        remoteStore.fetchNotificationPreferencesResult = SupabaseNotificationPreferencesRow(
            userID: userID,
            dailyEncouragementEnabled: false,
            weeklySummaryEnabled: false,
            milestonesEnabled: true,
            spendingAlertsEnabled: true,
            dailyTime: nil,
            weeklySummaryTime: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        let service = SupabaseAccountDataService(
            persistenceService: persistence,
            userDefaults: userDefaults,
            remoteStore: remoteStore
        )

        await service.bootstrapSignedInAccount(profileEmail: nil, provider: nil)

        XCTAssertFalse(remoteStore.didUpsertProfile)
        XCTAssertFalse(remoteStore.didUpsertUserSettings)
        XCTAssertFalse(remoteStore.didUpsertNotificationPreferences)
    }

    func test_pushPreferredCurrency_callsSupabaseUserSettingsUpdate() async {
        let service = makeService()
        await service.pushPreferredCurrencyCode("GBP")

        XCTAssertEqual(remoteStore.userSettingsUpdateCount, 1)
        XCTAssertEqual(remoteStore.lastUserSettingsPayload?["preferred_currency_code"] as? String, "GBP")
    }

    func test_pushSelectedTheme_callsSupabaseUserSettingsUpdate() async {
        let service = makeService()
        await service.pushSelectedTheme(AppTheme.purple.rawValue)

        XCTAssertEqual(remoteStore.userSettingsUpdateCount, 1)
        XCTAssertEqual(remoteStore.lastUserSettingsPayload?["selected_theme"] as? String, AppTheme.purple.rawValue)
    }

    func test_pushLanguageCode_callsSupabaseUserSettingsUpdate() async {
        let service = makeService()
        await service.pushLanguageCode("de")

        XCTAssertEqual(remoteStore.userSettingsUpdateCount, 1)
        XCTAssertEqual(remoteStore.lastUserSettingsPayload?["language_code"] as? String, "de")
    }

    func test_pushNotificationPreferences_updatesExpectedKeysOnly() async {
        let service = makeService()
        await service.pushNotificationPreferences(
            dailyEncouragementEnabled: true,
            weeklySummaryEnabled: true,
            milestonesEnabled: false,
            spendingAlertsEnabled: true,
            dailyTime: Date(timeIntervalSince1970: 0),
            weeklySummaryTime: Date(timeIntervalSince1970: 0)
        )

        XCTAssertEqual(remoteStore.notificationUpdateCount, 1)
        let payload = remoteStore.lastNotificationPayload ?? [:]
        XCTAssertNotNil(payload["daily_encouragement_enabled"])
        XCTAssertNotNil(payload["weekly_summary_enabled"])
        XCTAssertNotNil(payload["milestones_enabled"])
        XCTAssertNotNil(payload["spending_alerts_enabled"])
        XCTAssertNotNil(payload["daily_time"])
        XCTAssertNotNil(payload["weekly_summary_time"])
        XCTAssertNil(payload["permission_status"])
        XCTAssertNil(payload["biometric_enabled"])
    }

    func test_settingsViewModel_keepsLocalCurrencyWhenSupabaseFails() {
        let vm = SettingsViewModel(
            userDefaults: userDefaults,
            persistenceService: persistence,
            supabaseAccountDataService: FailingSupabaseAccountSyncService()
        )

        vm.updateCurrency("EUR")

        let request: NSFetchRequest<AppSettings> = AppSettings.fetchRequest()
        let appSettings = try? context.fetch(request).first
        XCTAssertEqual(vm.selectedCurrencyCode, "EUR")
        XCTAssertEqual(appSettings?.preferredCurrencyCode, "EUR")
    }

    func test_noFinancialDataFieldsAreUploadedInPhase1() async {
        let service = makeService()
        await service.pushPreferredCurrencyCode("JPY")
        await service.pushOnboardingCompleted(true)
        await service.pushSelectedTheme(AppTheme.google_red.rawValue)
        await service.pushNotificationPreferences(
            dailyEncouragementEnabled: false,
            weeklySummaryEnabled: true,
            milestonesEnabled: true,
            spendingAlertsEnabled: false,
            dailyTime: nil,
            weeklySummaryTime: nil
        )

        let disallowedKeys = Set([
            "financial_categories",
            "income",
            "expense",
            "savings_goals",
            "subscriptions",
            "bills",
            "recurring_transactions"
        ])

        let uploadedKeys = Set(remoteStore.allUploadedKeys)
        XCTAssertTrue(disallowedKeys.isDisjoint(with: uploadedKeys))
    }

    private func makeService() -> SupabaseAccountDataService {
        SupabaseAccountDataService(
            persistenceService: persistence,
            userDefaults: userDefaults,
            remoteStore: remoteStore
        )
    }
}

private final class FailingSupabaseAccountSyncService: SupabaseAccountDataSyncing {
    func bootstrapSignedInAccount(profileEmail: String?, provider: String?) async {}
    func pushPreferredCurrencyCode(_ code: String) async {}
    func pushSelectedTheme(_ theme: String) async {}
    func pushAppearanceMode(_ mode: String) async {}
    func pushLanguageCode(_ code: String) async {}
    func pushOnboardingCompleted(_ completed: Bool) async {}
    func pushNotificationPreferences(
        dailyEncouragementEnabled: Bool,
        weeklySummaryEnabled: Bool,
        milestonesEnabled: Bool,
        spendingAlertsEnabled: Bool,
        dailyTime: Date?,
        weeklySummaryTime: Date?
    ) async {}
}

private final class MockSupabaseAccountRemoteStore: SupabaseAccountRemoteStoreProtocol {
    var currentUserID: UUID?

    var fetchProfileResult: SupabaseProfileRow?
    var fetchUserSettingsResult: SupabaseUserSettingsRow?
    var fetchNotificationPreferencesResult: SupabaseNotificationPreferencesRow?

    var upsertProfileResult: SupabaseProfileRow?
    var upsertUserSettingsResult: SupabaseUserSettingsRow?
    var upsertNotificationPreferencesResult: SupabaseNotificationPreferencesRow?

    var didUpsertProfile = false
    var didUpsertUserSettings = false
    var didUpsertNotificationPreferences = false

    var userSettingsUpdateCount = 0
    var notificationUpdateCount = 0
    var lastUserSettingsPayload: [String: Any]?
    var lastNotificationPayload: [String: Any]?
    var allUploadedKeys: [String] = []

    func currentAuthenticatedUserID() async -> UUID? {
        currentUserID
    }

    func fetchProfile(userID: UUID) async throws -> SupabaseProfileRow? {
        fetchProfileResult
    }

    func upsertProfile(_ row: SupabaseProfileRow) async throws -> SupabaseProfileRow {
        didUpsertProfile = true
        return upsertProfileResult ?? row
    }

    func fetchUserSettings(userID: UUID) async throws -> SupabaseUserSettingsRow? {
        fetchUserSettingsResult
    }

    func upsertUserSettings(_ row: SupabaseUserSettingsRow) async throws -> SupabaseUserSettingsRow {
        didUpsertUserSettings = true
        return upsertUserSettingsResult ?? row
    }

    func updateUserSettings(userID: UUID, update: SupabaseUserSettingsUpdate) async throws -> SupabaseUserSettingsRow {
        userSettingsUpdateCount += 1
        let payload = try decodePayload(update)
        lastUserSettingsPayload = payload
        allUploadedKeys.append(contentsOf: payload.keys)

        return SupabaseUserSettingsRow(
            userID: userID,
            onboardingCompleted: payload["onboarding_completed"] as? Bool ?? false,
            preferredCurrencyCode: payload["preferred_currency_code"] as? String ?? "USD",
            selectedTheme: payload["selected_theme"] as? String ?? AppTheme.coral_default.rawValue,
            appearanceMode: payload["appearance_mode"] as? String ?? "system",
            languageCode: payload["language_code"] as? String ?? "en",
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    func fetchNotificationPreferences(userID: UUID) async throws -> SupabaseNotificationPreferencesRow? {
        fetchNotificationPreferencesResult
    }

    func upsertNotificationPreferences(_ row: SupabaseNotificationPreferencesRow) async throws -> SupabaseNotificationPreferencesRow {
        didUpsertNotificationPreferences = true
        return upsertNotificationPreferencesResult ?? row
    }

    func updateNotificationPreferences(
        userID: UUID,
        update: SupabaseNotificationPreferencesUpdate
    ) async throws -> SupabaseNotificationPreferencesRow {
        notificationUpdateCount += 1
        let payload = try decodePayload(update)
        lastNotificationPayload = payload
        allUploadedKeys.append(contentsOf: payload.keys)

        return SupabaseNotificationPreferencesRow(
            userID: userID,
            dailyEncouragementEnabled: payload["daily_encouragement_enabled"] as? Bool ?? false,
            weeklySummaryEnabled: payload["weekly_summary_enabled"] as? Bool ?? false,
            milestonesEnabled: payload["milestones_enabled"] as? Bool ?? true,
            spendingAlertsEnabled: payload["spending_alerts_enabled"] as? Bool ?? true,
            dailyTime: payload["daily_time"] as? String,
            weeklySummaryTime: payload["weekly_summary_time"] as? String,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    private func decodePayload<T: Encodable>(_ payload: T) throws -> [String: Any] {
        let data = try JSONEncoder().encode(payload)
        let object = try JSONSerialization.jsonObject(with: data, options: [])
        return object as? [String: Any] ?? [:]
    }
}
