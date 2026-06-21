//
//  WidgetDesignTokens.swift
//  BudgetMeter
//
//  v2 widget design tokens — neutral canvas, status text colors only.
//

import SwiftUI

enum WidgetDesignTokens {
    static let padding: CGFloat = 16
    static let cornerRadius: CGFloat = 22
    static let widgetNumberSize: CGFloat = 28
    static let widgetNumberSizeMedium: CGFloat = 32

    static let backgroundLight = Color(red: 248 / 255, green: 250 / 255, blue: 252 / 255)
    static let backgroundDark = Color(red: 15 / 255, green: 23 / 255, blue: 42 / 255)

    static let textPrimaryLight = Color(red: 15 / 255, green: 23 / 255, blue: 42 / 255)
    static let textPrimaryDark = Color(red: 248 / 255, green: 250 / 255, blue: 252 / 255)

    static let textSecondaryLight = Color(red: 100 / 255, green: 116 / 255, blue: 139 / 255)
    static let textSecondaryDark = Color(red: 148 / 255, green: 163 / 255, blue: 184 / 255)

    static let statusPositive = Color(red: 0 / 255, green: 200 / 255, blue: 83 / 255)
    static let statusPositiveCalm = Color(red: 0 / 255, green: 191 / 255, blue: 165 / 255)
    static let statusNegative = Color(red: 255 / 255, green: 90 / 255, blue: 95 / 255)
    static let statusNeutralLight = textSecondaryLight
    static let statusNeutralDark = textSecondaryDark

    static let lockedAccent = Color(red: 251 / 255, green: 188 / 255, blue: 4 / 255)

    static func background(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? backgroundDark : backgroundLight
    }

    static func textPrimary(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? textPrimaryDark : textPrimaryLight
    }

    static func textSecondary(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? textSecondaryDark : textSecondaryLight
    }

    static func statusColor(for paceStatus: String, colorScheme: ColorScheme) -> Color {
        switch paceStatus {
        case "movingForward":
            return statusPositive
        case "slowingDown":
            return statusNegative
        case "neutral":
            return colorScheme == .dark ? statusNeutralDark : statusNeutralLight
        default:
            return textSecondary(for: colorScheme)
        }
    }
}
