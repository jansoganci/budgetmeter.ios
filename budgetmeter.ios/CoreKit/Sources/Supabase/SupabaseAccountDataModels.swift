//
//  SupabaseAccountDataModels.swift
//  BudgetMeter
//
//  Phase 1 account/settings table mappings.
//

import Foundation

enum SupabaseAccountDataTables {
    static let profiles = "profiles"
    static let userSettings = "user_settings"
    static let notificationPreferences = "notification_preferences"
}

struct SupabaseProfileRow: Codable, Equatable {
    let userID: UUID
    var email: String?
    var displayName: String?
    var provider: String?
    var createdAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case email
        case displayName = "display_name"
        case provider
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct SupabaseUserSettingsRow: Codable, Equatable {
    let userID: UUID
    var onboardingCompleted: Bool
    var preferredCurrencyCode: String
    var selectedTheme: String
    var appearanceMode: String
    var languageCode: String
    var createdAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case onboardingCompleted = "onboarding_completed"
        case preferredCurrencyCode = "preferred_currency_code"
        case selectedTheme = "selected_theme"
        case appearanceMode = "appearance_mode"
        case languageCode = "language_code"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    static func defaults(for userID: UUID) -> SupabaseUserSettingsRow {
        SupabaseUserSettingsRow(
            userID: userID,
            onboardingCompleted: false,
            preferredCurrencyCode: "USD",
            selectedTheme: "default",
            appearanceMode: "system",
            languageCode: "en",
            createdAt: nil,
            updatedAt: nil
        )
    }
}

struct SupabaseNotificationPreferencesRow: Codable, Equatable {
    let userID: UUID
    var dailyEncouragementEnabled: Bool
    var weeklySummaryEnabled: Bool
    var milestonesEnabled: Bool
    var spendingAlertsEnabled: Bool
    var dailyTime: String?
    var weeklySummaryTime: String?
    var createdAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case dailyEncouragementEnabled = "daily_encouragement_enabled"
        case weeklySummaryEnabled = "weekly_summary_enabled"
        case milestonesEnabled = "milestones_enabled"
        case spendingAlertsEnabled = "spending_alerts_enabled"
        case dailyTime = "daily_time"
        case weeklySummaryTime = "weekly_summary_time"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    static func defaults(for userID: UUID) -> SupabaseNotificationPreferencesRow {
        SupabaseNotificationPreferencesRow(
            userID: userID,
            dailyEncouragementEnabled: false,
            weeklySummaryEnabled: false,
            milestonesEnabled: true,
            spendingAlertsEnabled: true,
            dailyTime: nil,
            weeklySummaryTime: nil,
            createdAt: nil,
            updatedAt: nil
        )
    }
}

struct SupabaseUserSettingsUpdate: Encodable {
    var onboardingCompleted: Bool? = nil
    var preferredCurrencyCode: String? = nil
    var selectedTheme: String? = nil
    var appearanceMode: String? = nil
    var languageCode: String? = nil

    enum CodingKeys: String, CodingKey {
        case onboardingCompleted = "onboarding_completed"
        case preferredCurrencyCode = "preferred_currency_code"
        case selectedTheme = "selected_theme"
        case appearanceMode = "appearance_mode"
        case languageCode = "language_code"
    }
}

struct SupabaseNotificationPreferencesUpdate: Encodable {
    var dailyEncouragementEnabled: Bool? = nil
    var weeklySummaryEnabled: Bool? = nil
    var milestonesEnabled: Bool? = nil
    var spendingAlertsEnabled: Bool? = nil
    var dailyTime: String? = nil
    var weeklySummaryTime: String? = nil

    enum CodingKeys: String, CodingKey {
        case dailyEncouragementEnabled = "daily_encouragement_enabled"
        case weeklySummaryEnabled = "weekly_summary_enabled"
        case milestonesEnabled = "milestones_enabled"
        case spendingAlertsEnabled = "spending_alerts_enabled"
        case dailyTime = "daily_time"
        case weeklySummaryTime = "weekly_summary_time"
    }
}
