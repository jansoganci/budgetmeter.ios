//
//  PremiumGateMatrixTests.swift
//  budgetmeter.iosTests
//
//  Phase 7 - canonical premium/free feature boundary tests.
//

import XCTest
@testable import budgetmeter_ios

@MainActor
final class PremiumGateMatrixTests: XCTestCase {

    func test_freeCoreCapabilitiesRemainAvailableWithoutPremium() {
        let freeCapabilities: [BudgetMeterCapability] = [
            .homeDashboard,
            .sharedFinancialSummary,
            .incomeEntry,
            .expenseEntry,
            .oneTimeEntry,
            .basicRecurringEntry,
            .oneBasicSavingsGoal,
            .defaultTheme
        ]

        for capability in freeCapabilities {
            XCTAssertEqual(capability.accessLevel, .free, "\(capability.rawValue) should be free")
            XCTAssertTrue(PremiumManager.hasAccess(to: capability, isPremium: false), "\(capability.rawValue) should be available to free users")
            XCTAssertTrue(PremiumManager.hasAccess(to: capability, isPremium: true), "\(capability.rawValue) should remain available to premium users")
        }
    }

    func test_premiumCapabilitiesRequirePremium() {
        let premiumCapabilities: [BudgetMeterCapability] = [
            .customCategories,
            .subscriptionTracking,
            .billReminders,
            .multipleSavingsGoals,
            .recurringAutomation,
            .dataExport,
            .widgets,
            .spendingInsights,
            .biometricLock,
            .premiumThemes,
            .advancedNotifications,
            .advancedHistoryReporting,
            .forecasting
        ]

        for capability in premiumCapabilities {
            XCTAssertEqual(capability.accessLevel, .premium, "\(capability.rawValue) should be premium")
            XCTAssertFalse(PremiumManager.hasAccess(to: capability, isPremium: false), "\(capability.rawValue) should be locked for free users")
            XCTAssertTrue(PremiumManager.hasAccess(to: capability, isPremium: true), "\(capability.rawValue) should unlock for premium users")
        }
    }

    func test_postponedCapabilitiesStayUnavailableInPhase7() {
        let postponedCapabilities: [BudgetMeterCapability] = [
            .adsFree
        ]

        for capability in postponedCapabilities {
            XCTAssertEqual(capability.accessLevel, .postponed, "\(capability.rawValue) should be postponed")
            XCTAssertFalse(PremiumManager.hasAccess(to: capability, isPremium: false), "\(capability.rawValue) should not unlock for free users")
            XCTAssertFalse(PremiumManager.hasAccess(to: capability, isPremium: true), "\(capability.rawValue) should not unlock while postponed")
        }
    }

    func test_backupSyncRequiresPremiumInPhase9() {
        XCTAssertEqual(BudgetMeterCapability.backupSync.accessLevel, .premium)
        XCTAssertFalse(PremiumManager.hasAccess(to: .backupSync, isPremium: false))
        XCTAssertTrue(PremiumManager.hasAccess(to: .backupSync, isPremium: true))
    }

    func test_premiumFeatureCasesMapToPremiumCapabilities() {
        let expectedMapping: [PremiumFeature: BudgetMeterCapability] = [
            .customCategories: .customCategories,
            .subscriptionTracking: .subscriptionTracking,
            .billReminders: .billReminders,
            .savingsGoals: .multipleSavingsGoals,
            .recurringTransactions: .recurringAutomation,
            .dataExport: .dataExport,
            .widgets: .widgets,
            .spendingInsights: .spendingInsights,
            .biometricLock: .biometricLock,
            .premiumThemes: .premiumThemes
        ]

        XCTAssertEqual(PremiumFeature.allCases.count, expectedMapping.count)

        for feature in PremiumFeature.allCases {
            XCTAssertEqual(feature.capability, expectedMapping[feature])
            XCTAssertTrue(feature.requiresPremium, "\(feature.rawValue) should require premium")
            XCTAssertFalse(PremiumManager.hasAccess(to: feature.capability, isPremium: false))
            XCTAssertTrue(PremiumManager.hasAccess(to: feature.capability, isPremium: true))
        }
    }

    func test_oneBasicSavingsGoalIsFreeButMultipleSavingsGoalsArePremium() {
        XCTAssertTrue(PremiumManager.hasAccess(to: BudgetMeterCapability.oneBasicSavingsGoal, isPremium: false))
        XCTAssertFalse(PremiumManager.hasAccess(to: BudgetMeterCapability.multipleSavingsGoals, isPremium: false))
        XCTAssertTrue(PremiumManager.hasAccess(to: BudgetMeterCapability.multipleSavingsGoals, isPremium: true))
        XCTAssertEqual(PremiumFeature.savingsGoals.capability, .multipleSavingsGoals)
    }

    func test_basicRecurringEntryIsFreeButRecurringAutomationIsPremium() {
        XCTAssertTrue(PremiumManager.hasAccess(to: BudgetMeterCapability.basicRecurringEntry, isPremium: false))
        XCTAssertFalse(PremiumManager.hasAccess(to: BudgetMeterCapability.recurringAutomation, isPremium: false))
        XCTAssertTrue(PremiumManager.hasAccess(to: BudgetMeterCapability.recurringAutomation, isPremium: true))
        XCTAssertEqual(PremiumFeature.recurringTransactions.capability, .recurringAutomation)
    }

    func test_coralDefaultThemeIsFreeAndOtherThemesRequirePremium() {
        XCTAssertFalse(AppTheme.coral_default.requiresPremium)

        for theme in AppTheme.allCases where theme != .coral_default {
            XCTAssertTrue(theme.requiresPremium, "\(theme.rawValue) should require premium")
        }
    }

    func test_legacyThemeIDsMigrateToV2() {
        XCTAssertEqual(AppTheme.resolved(from: "default"), .coral_default)
        XCTAssertEqual(AppTheme.resolved(from: "ocean"), .google_blue)
        XCTAssertEqual(AppTheme.resolved(from: "forest"), .mint_green)
        XCTAssertEqual(AppTheme.resolved(from: "sunset"), .orange)
        XCTAssertEqual(AppTheme.resolved(from: "purple"), .purple)
        XCTAssertEqual(AppTheme.resolved(from: "midnight"), .sky_cyan)
        XCTAssertEqual(AppTheme.resolved(from: "coral_default"), .coral_default)
        XCTAssertEqual(AppTheme.resolved(from: "unknown_theme"), .coral_default)
    }
}
