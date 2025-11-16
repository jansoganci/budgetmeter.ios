//
//  BrandColors.swift
//  BudgetMeter
//
//  Design System v2.0 - Modern Financial Dashboard
//  Adaptive color system with full light/dark mode support
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

// MARK: - Brand Colors (Design System v2.0)

extension Color {

    // MARK: - Primary Colors

    /// Primary positive color - Used for income, net positive flow, success indicators
    /// Light: #10B981 (Emerald Green) | Dark: #34D399 (Brighter Green)
    static let brandPositive = Color(
        light: Color(hex: "10B981"),
        dark: Color(hex: "34D399")
    )

    /// Primary progress color - Used for progress bars, savings goals, action buttons
    /// Light: #3B82F6 (Blue) | Dark: #60A5FA (Brighter Blue)
    /// NOTE: This is the default blue color. For theme-aware color, access ThemeManager.shared.accentColor
    static let brandProgress = Color(
        light: Color(hex: "3B82F6"),
        dark: Color(hex: "60A5FA")
    )

    /// Returns the theme-aware accent color from ThemeManager
    /// Use this in custom components that should adapt to the selected theme
    @MainActor
    static func themedAccent() -> Color {
        return ThemeManager.shared.accentColor
    }

    /// Expense/Negative color - Used for expense values, negative flow, warnings
    /// Light: #EF4444 (Red) | Dark: #F87171 (Softer Red)
    static let brandExpense = Color(
        light: Color(hex: "EF4444"),
        dark: Color(hex: "F87171")
    )

    // MARK: - Background Colors

    /// Main app background color (behind cards)
    /// Light: #F9FAFB (Light Gray) | Dark: #000000 (True Black - OLED optimized)
    static let appBackground = Color(
        light: Color(hex: "F9FAFB"),
        dark: Color(hex: "000000")
    )

    /// Card background color (all card surfaces)
    /// Light: #FFFFFF (Pure White) | Dark: #1F2937 (Elevated Dark Gray)
    static let cardBackground = Color(
        light: Color(hex: "FFFFFF"),
        dark: Color(hex: "1F2937")
    )

    // MARK: - Text Colors

    /// Primary text color - Used for headings, values, primary text
    /// Light: #111827 (Near Black) | Dark: #F9FAFB (Near White)
    static let textPrimary = Color(
        light: Color(hex: "111827"),
        dark: Color(hex: "F9FAFB")
    )

    /// Secondary text color - Used for labels, descriptions, secondary information
    /// Light: #6B7280 (Gray) | Dark: #9CA3AF (Light Gray)
    static let textSecondary = Color(
        light: Color(hex: "6B7280"),
        dark: Color(hex: "9CA3AF")
    )

    // MARK: - Chart Colors

    /// Inactive chart elements - Used for bar chart default state, inactive elements
    /// Light: #E5E7EB (Light Gray) | Dark: #374151 (Dark Gray)
    static let chartInactive = Color(
        light: Color(hex: "E5E7EB"),
        dark: Color(hex: "374151")
    )

    // MARK: - Legacy Support (v1.0 compatibility)

    /// Legacy brand color (v1.0 blue) - Kept for gradual migration
    /// Use brandProgress instead for new components
    @available(*, deprecated, message: "Use brandProgress instead")
    static let brandPrimary = Color(hex: "4A90E2")
}

// MARK: - Semantic Color Helpers

extension Color {

    /// Returns appropriate color based on financial flow value
    /// - Parameter value: The financial value (positive/negative/zero)
    /// - Returns: brandPositive for positive, brandExpense for negative, textSecondary for zero
    static func colorForFlow(_ value: Double) -> Color {
        if value > 0 {
            return .brandPositive
        } else if value < 0 {
            return .brandExpense
        } else {
            return .textSecondary
        }
    }

    /// Returns health score color based on score value
    /// - Parameter score: Health score (0-100)
    /// - Returns: Green for good (70+), Orange for fair (40-69), Red for poor (<40)
    static func colorForHealthScore(_ score: Int) -> Color {
        if score >= 70 {
            return .brandPositive
        } else if score >= 40 {
            return .orange
        } else {
            return .brandExpense
        }
    }
}

// MARK: - Gradient Helpers

extension LinearGradient {

    /// Positive flow gradient (green)
    static var positiveFlow: LinearGradient {
        LinearGradient(
            colors: [
                Color.brandPositive,
                Color.brandPositive.opacity(0.8)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Negative flow gradient (red)
    static var negativeFlow: LinearGradient {
        LinearGradient(
            colors: [
                Color.brandExpense,
                Color.brandExpense.opacity(0.8)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Progress gradient (blue)
    static var progress: LinearGradient {
        LinearGradient(
            colors: [
                Color.brandProgress,
                Color.brandProgress.opacity(0.85)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    /// Neutral flow gradient (gray)
    static var neutral: LinearGradient {
        LinearGradient(
            colors: [
                Color.textSecondary,
                Color.textSecondary.opacity(0.8)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
