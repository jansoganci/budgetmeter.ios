//
//  LayoutTokens.swift
//  BudgetMeter
//
//  Design System v2 — Spacing, surfaces, radius, and elevation tokens
//

import SwiftUI

// MARK: - Spacing Scale

enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let section: CGFloat = 20
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
}

// MARK: - Semantic Spacing (v2)

enum LayoutSpacing {
    static let screenPadding = Spacing.lg
    static let dashboardScreenPadding: CGFloat = 20
    static let sectionGap = Spacing.section
    static let cardPadding = Spacing.lg
    static let cardInternalGap = Spacing.md
    static let modalPadding = Spacing.xl
    static let widgetPadding = Spacing.lg
    static let rowHeight: CGFloat = 48
    static let buttonHeight: CGFloat = 52
    static let rowGap = Spacing.sm
    static let controlGap = Spacing.sm
}

// MARK: - Corner Radius (v2)

enum CornerRadius {
    static let card: CGFloat = 20
    static let button: CGFloat = 14
    static let modal: CGFloat = 24
    static let widget: CGFloat = 22
    static let badge: CGFloat = 8
    static let small: CGFloat = 8
    static let tiny: CGFloat = 4
    static let chartBar: CGFloat = 2
}

// MARK: - Compatibility Aliases (Phase 5)

enum LayoutTokens {
    static let screenHorizontalPadding: CGFloat = LayoutSpacing.screenPadding
    static let cardRadius: CGFloat = CornerRadius.card
    static let buttonRadius: CGFloat = CornerRadius.button
    static let modalRadius: CGFloat = CornerRadius.modal
    static let widgetRadius: CGFloat = CornerRadius.widget
}

// MARK: - Touch Targets

enum TouchTarget {
    static let minimum = LayoutSpacing.rowHeight
    static let recommended = LayoutSpacing.buttonHeight
    static let large: CGFloat = 80
}

// MARK: - Card Heights

enum CardHeight {
    static let hero: CGFloat = 180
    static let large: CGFloat = 160
    static let medium: CGFloat = 140
    static let small: CGFloat = 100
    static let compact: CGFloat = 70
    static let primary: CGFloat = 100
    static let summary: CGFloat = 70
    static let metric: CGFloat = 90
    static let interval: CGFloat = 70
}

// MARK: - Chart Dimensions

enum ChartDimensions {
    static let miniChartHeight: CGFloat = 60
    static let barWidth: CGFloat = 4
    static let barSpacing: CGFloat = 2
    static let circularProgressDiameter: CGFloat = 100
    static let circularProgressStroke: CGFloat = 10
    static let horizontalProgressHeight: CGFloat = 12
    static let milestoneMarkerSize: CGFloat = 6
    static let compactCircleDiameter: CGFloat = 50
    static let compactCircleStroke: CGFloat = 5
    static let compactProgressHeight: CGFloat = 8
}

// MARK: - Glass Surface (v2)

enum GlassSurfaceStyle {
    static let cornerRadius = CornerRadius.card
    static let borderLineWidth: CGFloat = 0.5

    /// Dark mode border — rgba(248, 250, 252, 0.12)
    static let borderDark = Color(red: 248 / 255, green: 250 / 255, blue: 252 / 255, opacity: 0.12)

    /// Light mode border — rgba(15, 23, 42, 0.08)
    static let borderLight = Color(red: 15 / 255, green: 23 / 255, blue: 42 / 255, opacity: 0.08)

    /// Opaque fallback — white (light) / slate-800 #1E293B (dark)
    static let opaqueFallback = Color.surfaceCard
}

// MARK: - Shadow Styles

enum ShadowStyle {
    case card
    case hero
    case small

    var color: Color { .black.opacity(opacity) }

    var opacity: Double {
        switch self {
        case .card: return 0.10
        case .hero: return 0.14
        case .small: return 0.08
        }
    }

    var radius: CGFloat {
        switch self {
        case .card: return 6
        case .hero: return 10
        case .small: return 4
        }
    }

    var offset: CGSize {
        switch self {
        case .card: return CGSize(width: 0, height: 2)
        case .hero: return CGSize(width: 0, height: 3)
        case .small: return CGSize(width: 0, height: 1)
        }
    }
}

// MARK: - Surface & Card Modifiers (v2)

extension View {

    /// Standard raised card on app background
    func surfaceCard(
        padding: CGFloat = LayoutSpacing.cardPadding,
        borderColor: Color = .borderSubtle,
        raised: Bool = false
    ) -> some View {
        self
            .padding(padding)
            .background(raised ? Color.surfaceRaised : Color.surfaceCard)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous)
                    .stroke(borderColor, lineWidth: 1)
            )
            .shadow(
                color: ShadowStyle.card.color,
                radius: ShadowStyle.card.radius,
                x: ShadowStyle.card.offset.width,
                y: ShadowStyle.card.offset.height
            )
    }

    /// Inset well for nested rows / progress tracks
    func surfaceInset(padding: CGFloat = Spacing.sm) -> some View {
        self
            .padding(padding)
            .background(Color.surfaceInset)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.badge, style: .continuous))
    }

    /// Sheet / overlay panel styling
    func surfaceOverlay(padding: CGFloat = LayoutSpacing.modalPadding) -> some View {
        self
            .padding(padding)
            .background(Color.surfaceOverlay)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.modal, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.modal, style: .continuous)
                    .stroke(Color.borderSubtle, lineWidth: 1)
            )
    }

    func dashboardCard(padding: CGFloat = LayoutSpacing.cardPadding) -> some View {
        surfaceCard(padding: padding)
    }

    func heroCard(padding: CGFloat = LayoutSpacing.cardPadding) -> some View {
        self
            .padding(padding)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
            .shadow(
                color: ShadowStyle.hero.color,
                radius: ShadowStyle.hero.radius,
                x: ShadowStyle.hero.offset.width,
                y: ShadowStyle.hero.offset.height
            )
    }

    func smallCard(padding: CGFloat = Spacing.md) -> some View {
        self
            .padding(padding)
            .background(Color.surfaceCard)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.button, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.button, style: .continuous)
                    .stroke(Color.borderSubtle, lineWidth: 1)
            )
            .shadow(
                color: ShadowStyle.small.color,
                radius: ShadowStyle.small.radius,
                x: ShadowStyle.small.offset.width,
                y: ShadowStyle.small.offset.height
            )
    }
}
