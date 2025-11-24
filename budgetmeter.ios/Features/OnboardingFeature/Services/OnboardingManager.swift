//
//  OnboardingManager.swift
//  BudgetMeter
//
//  Created by BudgetMeter Team
//

import Foundation

/// Manages onboarding state and completion tracking
/// Singleton service that checks/stores onboarding completion status in UserDefaults
@MainActor
final class OnboardingManager: ObservableObject {

    // MARK: - Singleton

    static let shared = OnboardingManager()

    // MARK: - Published Properties

    @Published var hasCompletedOnboarding: Bool {
        didSet {
            userDefaults.set(hasCompletedOnboarding, forKey: OnboardingKeys.hasCompletedOnboarding)
        }
    }

    // MARK: - Private Properties

    private let userDefaults: UserDefaults

    // MARK: - Keys

    private enum OnboardingKeys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let onboardingVersion = "onboardingVersion"
        static let onboardingSkipped = "onboardingSkipped"
        static let onboardingCompletedAt = "onboardingCompletedAt"
    }

    // MARK: - Initialization

    private init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.hasCompletedOnboarding = userDefaults.bool(forKey: OnboardingKeys.hasCompletedOnboarding)
    }

    // MARK: - Public Methods

    /// Marks onboarding as completed (user finished all screens or skipped)
    func markOnboardingComplete(skipped: Bool = false) {
        hasCompletedOnboarding = true
        userDefaults.set("1.0", forKey: OnboardingKeys.onboardingVersion)
        userDefaults.set(skipped, forKey: OnboardingKeys.onboardingSkipped)
        userDefaults.set(Date(), forKey: OnboardingKeys.onboardingCompletedAt)

        print("✅ Onboarding completed (skipped: \(skipped))")
    }

    /// Resets onboarding state (for debugging/testing)
    func resetOnboarding() {
        hasCompletedOnboarding = false
        userDefaults.removeObject(forKey: OnboardingKeys.hasCompletedOnboarding)
        userDefaults.removeObject(forKey: OnboardingKeys.onboardingVersion)
        userDefaults.removeObject(forKey: OnboardingKeys.onboardingSkipped)
        userDefaults.removeObject(forKey: OnboardingKeys.onboardingCompletedAt)

        print("🔄 Onboarding reset")
    }

    /// Returns whether user skipped onboarding
    var wasOnboardingSkipped: Bool {
        userDefaults.bool(forKey: OnboardingKeys.onboardingSkipped)
    }

    /// Returns onboarding version (for future migrations)
    var onboardingVersion: String? {
        userDefaults.string(forKey: OnboardingKeys.onboardingVersion)
    }

    /// Returns when onboarding was completed
    var onboardingCompletedAt: Date? {
        userDefaults.object(forKey: OnboardingKeys.onboardingCompletedAt) as? Date
    }

    // MARK: - Analytics Helpers (Privacy-Respecting)

    /// Returns onboarding completion summary (for internal metrics only, never sent anywhere)
    var completionSummary: [String: Any] {
        return [
            "completed": hasCompletedOnboarding,
            "skipped": wasOnboardingSkipped,
            "version": onboardingVersion ?? "unknown",
            "completedAt": onboardingCompletedAt?.description ?? "unknown"
        ]
    }
}
