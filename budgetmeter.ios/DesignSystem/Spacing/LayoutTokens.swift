//
//  LayoutTokens.swift
//  BudgetMeter
//
//  Design System v2.0 - Spacing and Layout Constants
//  Consistent spacing scale for the Modern Financial Dashboard
//

import SwiftUI

// MARK: - Spacing System

/// Spacing tokens for consistent layout throughout the app
enum Spacing {
    /// 4pt - Icon-to-text spacing, tight groupings
    static let xs: CGFloat = 4

    /// 8pt - Related elements within a card
    static let sm: CGFloat = 8

    /// 12pt - Vertical spacing between card content sections
    static let md: CGFloat = 12

    /// 16pt - Horizontal screen padding (mobile)
    static let lg: CGFloat = 16

    /// 24pt - Card gap spacing, section separation, desktop padding
    static let xl: CGFloat = 24

    /// 32pt - Major section breaks
    static let xxl: CGFloat = 32
}

// MARK: - Corner Radius

/// Corner radius tokens for consistent rounded corners
enum CornerRadius {
    /// 16pt - Cards (primary)
    static let card: CGFloat = 16

    /// 12pt - Buttons, secondary elements
    static let button: CGFloat = 12

    /// 8pt - Small elements (badges, chips, progress bars)
    static let small: CGFloat = 8

    /// 4pt - Tiny elements
    static let tiny: CGFloat = 4

    /// 2pt - Chart bars (top only)
    static let chartBar: CGFloat = 2
}

// MARK: - Touch Targets

/// Minimum touch target sizes (HIG compliance)
enum TouchTarget {
    /// 44pt - HIG minimum touch target
    static let minimum: CGFloat = 44

    /// 50pt - Recommended for primary actions
    static let recommended: CGFloat = 50

    /// 80pt - Large action buttons
    static let large: CGFloat = 80
}

// MARK: - Card Heights

/// Standard card heights for consistency
enum CardHeight {
    /// 180pt - Hero card (legacy)
    static let hero: CGFloat = 180

    /// 160pt - Health score, savings goal (legacy)
    static let large: CGFloat = 160

    /// 140pt - Interval metric cards (legacy)
    static let medium: CGFloat = 140

    /// 100pt - Insight cards
    static let small: CGFloat = 100

    /// 70pt - Snapshot cards
    static let compact: CGFloat = 70

    // MARK: - Compact Dashboard Heights (v2.1)

    /// 100pt - Primary card (Daily Budget)
    static let primary: CGFloat = 100

    /// 70pt - Summary cards (Income/Expense/Net)
    static let summary: CGFloat = 70

    /// 90pt - Metric cards (Health + Savings)
    static let metric: CGFloat = 90

    /// 70pt - Interval cards (Hourly/Daily/Monthly)
    static let interval: CGFloat = 70
}

// MARK: - Chart Dimensions

/// Chart-specific dimensions
enum ChartDimensions {
    /// 60pt - Mini bar chart height
    static let miniChartHeight: CGFloat = 60

    /// 4pt - Bar width
    static let barWidth: CGFloat = 4

    /// 2pt - Bar spacing
    static let barSpacing: CGFloat = 2

    /// 100pt - Circular progress diameter (legacy)
    static let circularProgressDiameter: CGFloat = 100

    /// 10pt - Circular progress stroke width (legacy)
    static let circularProgressStroke: CGFloat = 10

    /// 12pt - Horizontal progress bar height
    static let horizontalProgressHeight: CGFloat = 12

    /// 6pt - Milestone marker diameter
    static let milestoneMarkerSize: CGFloat = 6

    // MARK: - Compact Dimensions (v2.1)

    /// 50pt - Compact circular progress diameter
    static let compactCircleDiameter: CGFloat = 50

    /// 5pt - Compact circular progress stroke
    static let compactCircleStroke: CGFloat = 5

    /// 8pt - Compact progress bar height
    static let compactProgressHeight: CGFloat = 8
}

// MARK: - Shadow Styles

/// Shadow configurations for cards and elevated elements
enum ShadowStyle {
    case card
    case hero
    case small

    var color: Color {
        .black.opacity(opacity)
    }

    var opacity: Double {
        switch self {
        case .card: return 0.08
        case .hero: return 0.15
        case .small: return 0.06
        }
    }

    var radius: CGFloat {
        switch self {
        case .card: return 8
        case .hero: return 12
        case .small: return 6
        }
    }

    var offset: CGSize {
        switch self {
        case .card: return CGSize(width: 0, height: 2)
        case .hero: return CGSize(width: 0, height: 4)
        case .small: return CGSize(width: 0, height: 2)
        }
    }
}

// MARK: - View Modifiers

extension View {
    /// Applies standard dashboard card styling
    func dashboardCard(padding: CGFloat = 20) -> some View {
        self
            .padding(padding)
            .background(Color.cardBackground)
            .cornerRadius(CornerRadius.card)
            .shadow(
                color: ShadowStyle.card.color,
                radius: ShadowStyle.card.radius,
                x: ShadowStyle.card.offset.width,
                y: ShadowStyle.card.offset.height
            )
    }

    /// Applies hero card styling (larger shadow)
    func heroCard(padding: CGFloat = 20) -> some View {
        self
            .padding(padding)
            .cornerRadius(CornerRadius.card)
            .shadow(
                color: ShadowStyle.hero.color,
                radius: ShadowStyle.hero.radius,
                x: ShadowStyle.hero.offset.width,
                y: ShadowStyle.hero.offset.height
            )
    }

    /// Applies small card styling (subtle shadow)
    func smallCard(padding: CGFloat = 12) -> some View {
        self
            .padding(padding)
            .background(Color.cardBackground)
            .cornerRadius(CornerRadius.button)
            .shadow(
                color: ShadowStyle.small.color,
                radius: ShadowStyle.small.radius,
                x: ShadowStyle.small.offset.width,
                y: ShadowStyle.small.offset.height
            )
    }
}
