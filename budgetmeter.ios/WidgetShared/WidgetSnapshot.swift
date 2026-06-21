//
//  WidgetSnapshot.swift
//  BudgetMeter
//
//  Codable display cache written by the app and read by the widget extension.
//

import Foundation

enum WidgetDisplayState: String, Codable, Equatable {
    case unlocked
    case lockedTeaser
    case missing
    case stale
    case insufficientData
}

struct WidgetSnapshot: Codable, Equatable {
    let schemaVersion: Int
    let netDailyPace: Double
    let paceStatus: String
    let displayValue: String
    let displayStatusCopy: String
    let currencyCode: String
    let currencySymbol: String
    let isPremium: Bool
    let generatedAt: Date
    let staleAfter: Date
    let isLockedTeaser: Bool
    let lockedTeaserTitle: String
    let lockedTeaserSubtitle: String
    let deepLinkURL: String
    let hasFinancialInput: Bool
    let displayState: WidgetDisplayState
    let missingMessage: String
    let staleMessage: String

    var isStale: Bool {
        Date() > staleAfter
    }

    var resolvedDisplayState: WidgetDisplayState {
        switch displayState {
        case .unlocked:
            return isStale ? .stale : displayState
        default:
            return displayState
        }
    }
}
