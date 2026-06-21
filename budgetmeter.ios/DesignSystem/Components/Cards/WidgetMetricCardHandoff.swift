//
//  WidgetMetricCardHandoff.swift
//  BudgetMeter
//
//  Design handoff only — layout constants for WidgetKit. Not a live widget View.
//

import SwiftUI

/// Handoff spec for widget daily pace metric layout. See `docs/transformations/widget_transformation.md`.
/// Do not import in-app card Views into the widget target.
enum WidgetMetricCardHandoff {

    static let padding = WidgetDesignTokens.padding
    static let cornerRadius = WidgetDesignTokens.cornerRadius
    static let heroNumberSize = WidgetDesignTokens.widgetNumberSize

    static let backgroundLightHex = "F8FAFC"
    static let backgroundDarkHex = "0F172A"

    static let statusPositiveHex = "00C853"
    static let statusNegativeHex = "FF5A5F"

    /// WidgetKit-native layout hierarchy (documentation constants).
    enum LayoutHierarchy: Int, CaseIterable {
        case appLabel = 0
        case heroMetric = 1
        case statusLabel = 2
        case supportingContext = 3
        case statusIndicator = 4
    }

    static func background(for colorScheme: ColorScheme) -> Color {
        WidgetDesignTokens.background(for: colorScheme)
    }

    static func statusColor(for paceStatus: String, colorScheme: ColorScheme) -> Color {
        WidgetDesignTokens.statusColor(for: paceStatus, colorScheme: colorScheme)
    }
}
