//
//  WidgetConstants.swift
//  BudgetMeter
//
//  Shared constants for app ↔ widget snapshot contract.
//

import Foundation

enum WidgetConstants {
    static let appGroupID = "group.com.budgetmeter.shared"
    static let snapshotStorageKey = "widgetSummarySnapshot"
    static let netDailyPaceWidgetKind = "NetDailyPaceWidget"
    static let schemaVersion = 1
    static let staleInterval: TimeInterval = 6 * 60 * 60
    static let fallbackRefreshInterval: TimeInterval = 60 * 60
    static let unlockedDeepLink = "budgetmeter://home/hero"
    static let lockedDeepLink = "budgetmeter://premium/widgets"
}
