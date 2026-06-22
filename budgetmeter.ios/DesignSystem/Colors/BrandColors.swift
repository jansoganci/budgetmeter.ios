//
//  BrandColors.swift
//  BudgetMeter
//
//  Design System v2 — Slate fintech semantic tokens
//  Light/dark canvas with Coral Default accent and Fresh Green positive status.
//

import SwiftUI

// MARK: - Adaptive Color Extension

extension Color {
    /// Creates a color that adapts to light/dark mode automatically
    init(light: Color, dark: Color) {
        self.init(UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(dark)
            default:
                return UIColor(light)
            }
        })
    }
}

// MARK: - Semantic Surfaces (v4)

extension Color {

    /// Slate fintech app canvas (v2 background.main)
    static let surfaceObsidian = Color(
        light: Color(hex: "F8FAFC"),
        dark: Color(hex: "0F172A")
    )

    /// Primary slate card surface
    static let surfaceCard = Color(
        light: Color(hex: "FFFFFF"),
        dark: Color(hex: "1E293B")
    )

    /// Elevated card / hover surface
    static let surfaceRaised = Color(
        light: Color(hex: "FFFFFF"),
        dark: Color(hex: "243047")
    )

    /// Inset wells, progress tracks, input backgrounds
    static let surfaceInset = Color(
        light: Color(hex: "E5E7EB"),
        dark: Color(hex: "111827")
    )

    /// Sheets, overlays, secondary panels
    static let surfaceOverlay = Color(
        light: Color(hex: "FFFFFF"),
        dark: Color(hex: "162032")
    )

    // MARK: - Compatibility aliases

    static let appBackground = surfaceObsidian
    static let cardBackground = surfaceCard
}

// MARK: - Accent & Financial States (v4)

extension Color {

    /// Coral Default — free brand accent (v2 theme.accent.primary)
    /// Light mode uses a darker coral for WCAG AA text contrast on white surfaces.
    static let accentPrimary = Color(
        light: Color(hex: "CC4A4F"),
        dark: Color(hex: "FF5A5F")
    )

    /// Restrained indigo secondary accent
    static let accentSecondary = Color(
        light: Color(hex: "4F46E5"),
        dark: Color(hex: "818CF8")
    )

    /// Fresh Green — moving forward / income / positive flow (v2 status.positive)
    /// Light mode uses a darker green for WCAG AA text contrast on white surfaces.
    static let financialPositive = Color(
        light: Color(hex: "007A36"),
        dark: Color(hex: "00C853")
    )

    /// Mint Green — calmer positive state (v2 status.positive.calm)
    static let financialPositiveCalm = Color(
        light: Color(hex: "008F7A"),
        dark: Color(hex: "00BFA5")
    )

    /// Amber — caution / fair health / attention
    static let financialCaution = Color(
        light: Color(hex: "B45309"),
        dark: Color(hex: "FBBF24")
    )

    /// Coral Default — slowing down / drain / negative pace (v2 status.negative)
    static let financialNegative = accentPrimary

    /// Google Red — premium high-energy negative accent (v2 status.negative.alt)
    static let statusNegativeAlt = Color(hex: "EA4335")

    /// Blue-gray neutral / insufficient steady state
    static let financialNeutral = Color(
        light: Color(hex: "64748B"),
        dark: Color(hex: "94A3B8")
    )

    // MARK: - Compatibility aliases

    static let brandPositive = financialPositive
    static let brandProgress = accentPrimary
    static let brandExpense = financialNegative
}

// MARK: - Runtime Theme Accent

private struct ThemeAccentKey: EnvironmentKey {
    static let defaultValue: Color = .accentPrimary
}

extension EnvironmentValues {
    /// Runtime accent selected by Premium Themes. Use only for accent-layer UI.
    var themeAccent: Color {
        get { self[ThemeAccentKey.self] }
        set { self[ThemeAccentKey.self] = newValue }
    }
}

// MARK: - Text (v4)

extension Color {

    static let textPrimary = Color(
        light: Color(hex: "0F172A"),
        dark: Color(hex: "F8FAFC")
    )

    static let textSecondary = Color(
        light: Color(hex: "64748B"),
        dark: Color(hex: "94A3B8")
    )

    /// Tertiary text — hints and disabled-adjacent copy (v2 text.tertiary).
    static let textTertiary = Color(
        light: Color(hex: "94A3B8"),
        dark: Color(hex: "64748B")
    )
}

// MARK: - Borders, Dividers, Charts (v4)

extension Color {

    static let borderSubtle = Color(
        light: Color(hex: "E5E7EB"),
        dark: Color(hex: "334155")
    )

    static let borderFocus = accentPrimary

    static let dividerSubtle = Color(
        light: Color(hex: "E5E7EB"),
        dark: Color(hex: "1E293B")
    )

    static let chartTrack = Color(
        light: Color(hex: "E5E7EB"),
        dark: Color(hex: "334155")
    )

    static let chartInactive = chartTrack

    static let chartPositive = financialPositive
    static let chartCaution = financialCaution
    static let chartNegative = financialNegative
}

// MARK: - Legacy Support

extension Color {
    @available(*, deprecated, message: "Use accentPrimary instead")
    static let brandPrimary = Color(hex: "4A90E2")
}

// MARK: - Semantic Color Helpers

extension Color {

    static func colorForFlow(_ value: Double) -> Color {
        if value > 0 { return .financialPositive }
        if value < 0 { return .financialNegative }
        return .textSecondary
    }

    static func colorForHealthScore(_ score: Int) -> Color {
        if score >= 70 { return .financialPositive }
        if score >= 40 { return .financialCaution }
        return .financialNegative
    }

    static func color(for paceStatus: PaceStatus) -> Color {
        switch paceStatus {
        case .movingForward: return .financialPositive
        case .slowingDown: return .financialNegative
        case .neutral: return .accentPrimary
        case .insufficientData: return .financialNeutral
        }
    }
}

// MARK: - Gradient Helpers (restrained — no loud AI gradients)

extension LinearGradient {

    static var positiveFlow: LinearGradient {
        LinearGradient(
            colors: [Color.financialPositive, Color.financialPositive.opacity(0.85)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    static var negativeFlow: LinearGradient {
        LinearGradient(
            colors: [Color.financialNegative, Color.financialNegative.opacity(0.85)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    static var progress: LinearGradient {
        LinearGradient(
            colors: [Color.accentPrimary, Color.accentPrimary.opacity(0.88)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    static var neutral: LinearGradient {
        LinearGradient(
            colors: [Color.financialNeutral, Color.financialNeutral.opacity(0.85)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}
