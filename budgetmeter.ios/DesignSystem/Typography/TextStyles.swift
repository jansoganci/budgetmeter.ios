//
//  TextStyles.swift
//  BudgetMeter
//
//  Design System v2.0 - Typography System
//  Consistent text styles and modifiers
//

import SwiftUI

// MARK: - Typography Scale

/// Typography tokens for consistent text styling
enum Typography {

    // MARK: - Font Sizes

    /// 48pt - Hero metrics (net flow value, large financial numbers)
    static let heroMetricSize: CGFloat = 48

    /// 34pt - Large metrics (secondary metrics, savings amounts)
    static let largeMetricSize: CGFloat = 34

    /// 24pt - Medium metrics (card values, interval amounts)
    static let mediumMetricSize: CGFloat = 24

    /// 17pt - Small metrics (inline metrics, list values)
    static let smallMetricSize: CGFloat = 17

    /// 20pt - Section titles (card titles, section headers)
    static let sectionTitleSize: CGFloat = 20

    /// 15pt - Card labels (labels, descriptions within cards)
    static let cardLabelSize: CGFloat = 15

    /// 13pt - Captions (timestamps, secondary info, footnotes)
    static let captionSize: CGFloat = 13

    /// 14pt - Trend indicators (percentage changes)
    static let trendIndicatorSize: CGFloat = 14

    // MARK: - Font Weights

    static let bold: Font.Weight = .bold
    static let semibold: Font.Weight = .semibold
    static let medium: Font.Weight = .medium
    static let regular: Font.Weight = .regular
}

// MARK: - Text Style Modifiers

extension View {

    // MARK: - Metric Styles

    /// Hero metric style - 48pt bold, monospaced digits
    func heroMetricStyle(color: Color = .textPrimary) -> some View {
        self.modifier(HeroMetricStyle(color: color))
    }

    /// Large metric style - 34pt bold
    func largeMetricStyle(color: Color = .textPrimary) -> some View {
        self.modifier(LargeMetricStyle(color: color))
    }

    /// Medium metric style - 24pt semibold
    func mediumMetricStyle(color: Color = .textPrimary) -> some View {
        self.modifier(MediumMetricStyle(color: color))
    }

    /// Small metric style - 17pt semibold
    func smallMetricStyle(color: Color = .textPrimary) -> some View {
        self.modifier(SmallMetricStyle(color: color))
    }

    // MARK: - Label Styles

    /// Section title style - 20pt semibold
    func sectionTitleStyle(color: Color = .textPrimary) -> some View {
        self.modifier(SectionTitleStyle(color: color))
    }

    /// Card label style - 15pt medium
    func cardLabelStyle(color: Color = .textSecondary) -> some View {
        self.modifier(CardLabelStyle(color: color))
    }

    /// Caption style - 13pt regular
    func captionStyle(color: Color = .textSecondary) -> some View {
        self.modifier(CaptionStyle(color: color))
    }

    /// Trend indicator style - 14pt medium
    func trendStyle(color: Color) -> some View {
        self.modifier(TrendStyle(color: color))
    }
}

// MARK: - View Modifier Implementations

private struct HeroMetricStyle: ViewModifier {
    let color: Color

    func body(content: Content) -> some View {
        content
            .font(.system(size: Typography.heroMetricSize, weight: Typography.bold, design: .default))
            .monospacedDigit()
            .foregroundColor(color)
    }
}

private struct LargeMetricStyle: ViewModifier {
    let color: Color

    func body(content: Content) -> some View {
        content
            .font(.system(size: Typography.largeMetricSize, weight: Typography.bold))
            .monospacedDigit()
            .foregroundColor(color)
    }
}

private struct MediumMetricStyle: ViewModifier {
    let color: Color

    func body(content: Content) -> some View {
        content
            .font(.system(size: Typography.mediumMetricSize, weight: Typography.semibold))
            .monospacedDigit()
            .foregroundColor(color)
    }
}

private struct SmallMetricStyle: ViewModifier {
    let color: Color

    func body(content: Content) -> some View {
        content
            .font(.system(size: Typography.smallMetricSize, weight: Typography.semibold))
            .monospacedDigit()
            .foregroundColor(color)
    }
}

private struct SectionTitleStyle: ViewModifier {
    let color: Color

    func body(content: Content) -> some View {
        content
            .font(.system(size: Typography.sectionTitleSize, weight: Typography.semibold))
            .foregroundColor(color)
    }
}

private struct CardLabelStyle: ViewModifier {
    let color: Color

    func body(content: Content) -> some View {
        content
            .font(.system(size: Typography.cardLabelSize, weight: Typography.medium))
            .foregroundColor(color)
    }
}

private struct CaptionStyle: ViewModifier {
    let color: Color

    func body(content: Content) -> some View {
        content
            .font(.system(size: Typography.captionSize, weight: Typography.regular))
            .foregroundColor(color)
    }
}

private struct TrendStyle: ViewModifier {
    let color: Color

    func body(content: Content) -> some View {
        content
            .font(.system(size: Typography.trendIndicatorSize, weight: Typography.medium))
            .foregroundColor(color)
    }
}
