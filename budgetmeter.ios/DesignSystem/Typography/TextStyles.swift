//
//  TextStyles.swift
//  BudgetMeter
//
//  Design System v2 — Typography tokens and semantic text styles
//  SF Pro Rounded for financial numbers; SF Pro (system default) for UI text.
//

import SwiftUI

// MARK: - Typography Scale (v2)

enum Typography {
    // v2 semantic scale — reference sizes for @ScaledMetric defaults
    static let heroFinancialSize: CGFloat = 38          // 36–40pt
    static let heroFinancialMaxSize: CGFloat = 44     // max large financial
    static let widgetNumberSize: CGFloat = 30         // 28–32pt
    static let screenTitleSize: CGFloat = 32          // 28–34pt
    static let sectionTitleSize: CGFloat = 20         // 18–22pt
    static let cardTitleSize: CGFloat = 17            // 16–18pt
    static let bodySize: CGFloat = 16                 // 15–17pt
    static let captionSize: CGFloat = 13              // 12–13pt
    static let buttonTextSize: CGFloat = 17           // 16–17pt

    // Supporting UI / compact financial
    static let metricCompactSize: CGFloat = 17
    static let statusTitleSize: CGFloat = 14
    static let badgeSize: CGFloat = 11
    static let trendIndicatorSize: CGFloat = 14

    // Compatibility aliases (preserve existing token names)
    static let paceHeroSize = heroFinancialSize
    static let heroMetricSize = heroFinancialMaxSize
    static let largeMetricSize = screenTitleSize
    static let mediumMetricSize = widgetNumberSize
    static let smallMetricSize = metricCompactSize
    static let cardLabelSize = cardTitleSize

    static let bold: Font.Weight = .bold
    static let semibold: Font.Weight = .semibold
    static let medium: Font.Weight = .medium
    static let regular: Font.Weight = .regular
}

// MARK: - Text Style Modifiers

extension View {

    // MARK: - v2 semantic aliases

    func paceHeroStyle(color: Color = .textPrimary) -> some View {
        modifier(PaceHeroStyle(color: color))
    }

    func metricLargeStyle(color: Color = .textPrimary) -> some View {
        largeMetricStyle(color: color)
    }

    func metricMediumStyle(color: Color = .textPrimary) -> some View {
        mediumMetricStyle(color: color)
    }

    func metricCompactStyle(color: Color = .textPrimary) -> some View {
        smallMetricStyle(color: color)
    }

    func widgetNumberStyle(color: Color = .textPrimary) -> some View {
        mediumMetricStyle(color: color)
    }

    func statusTitleStyle(color: Color = .textPrimary) -> some View {
        modifier(StatusTitleStyle(color: color))
    }

    func bodyStyle(color: Color = .textPrimary) -> some View {
        modifier(BodyStyle(color: color))
    }

    func badgeStyle(color: Color = .textSecondary) -> some View {
        modifier(BadgeStyle(color: color))
    }

    func buttonTextStyle(color: Color = .textPrimary) -> some View {
        modifier(ButtonTextStyle(color: color))
    }

    // MARK: - Legacy compatibility names

    func heroMetricStyle(color: Color = .textPrimary) -> some View {
        modifier(HeroMetricStyle(color: color))
    }

    func largeMetricStyle(color: Color = .textPrimary) -> some View {
        modifier(LargeMetricStyle(color: color))
    }

    func mediumMetricStyle(color: Color = .textPrimary) -> some View {
        modifier(MediumMetricStyle(color: color))
    }

    func smallMetricStyle(color: Color = .textPrimary) -> some View {
        modifier(SmallMetricStyle(color: color))
    }

    func sectionTitleStyle(color: Color = .textPrimary) -> some View {
        modifier(SectionTitleStyle(color: color))
    }

    func cardLabelStyle(color: Color = .textSecondary) -> some View {
        modifier(CardLabelStyle(color: color))
    }

    func cardTitleStyle(color: Color = .textPrimary) -> some View {
        cardLabelStyle(color: color)
    }

    func captionStyle(color: Color = .textSecondary) -> some View {
        modifier(CaptionStyle(color: color))
    }

    func trendStyle(color: Color) -> some View {
        modifier(TrendStyle(color: color))
    }
}

// MARK: - Financial Number Modifiers (SF Pro Rounded + monospacedDigit)

private struct PaceHeroStyle: ViewModifier {
    let color: Color
    @ScaledMetric(relativeTo: .largeTitle) private var fontSize = Typography.heroFinancialSize

    func body(content: Content) -> some View {
        content
            .font(.system(size: fontSize, weight: .bold, design: .rounded))
            .monospacedDigit()
            .foregroundColor(color)
            .minimumScaleFactor(0.7)
            .lineLimit(2)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct HeroMetricStyle: ViewModifier {
    let color: Color
    @ScaledMetric(relativeTo: .largeTitle) private var fontSize = Typography.heroFinancialMaxSize

    func body(content: Content) -> some View {
        content
            .font(.system(size: fontSize, weight: Typography.bold, design: .rounded))
            .monospacedDigit()
            .foregroundColor(color)
            .minimumScaleFactor(0.7)
            .lineLimit(2)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct LargeMetricStyle: ViewModifier {
    let color: Color
    @ScaledMetric(relativeTo: .title) private var fontSize = Typography.screenTitleSize

    func body(content: Content) -> some View {
        content
            .font(.system(size: fontSize, weight: Typography.bold, design: .rounded))
            .monospacedDigit()
            .foregroundColor(color)
            .minimumScaleFactor(0.75)
            .lineLimit(2)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct MediumMetricStyle: ViewModifier {
    let color: Color
    @ScaledMetric(relativeTo: .title2) private var fontSize = Typography.widgetNumberSize

    func body(content: Content) -> some View {
        content
            .font(.system(size: fontSize, weight: Typography.semibold, design: .rounded))
            .monospacedDigit()
            .foregroundColor(color)
            .minimumScaleFactor(0.75)
            .lineLimit(2)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct SmallMetricStyle: ViewModifier {
    let color: Color
    @ScaledMetric(relativeTo: .headline) private var fontSize = Typography.metricCompactSize

    func body(content: Content) -> some View {
        content
            .font(.system(size: fontSize, weight: Typography.semibold, design: .rounded))
            .monospacedDigit()
            .foregroundColor(color)
            .minimumScaleFactor(0.75)
            .lineLimit(2)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - UI Text Modifiers (SF Pro / system default)

private struct StatusTitleStyle: ViewModifier {
    let color: Color

    func body(content: Content) -> some View {
        content
            .font(.subheadline.weight(.medium))
            .foregroundColor(color)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct BodyStyle: ViewModifier {
    let color: Color

    func body(content: Content) -> some View {
        content
            .font(.body)
            .foregroundColor(color)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct BadgeStyle: ViewModifier {
    let color: Color

    func body(content: Content) -> some View {
        content
            .font(.caption2.weight(.semibold))
            .foregroundColor(color)
            .textCase(.uppercase)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct ButtonTextStyle: ViewModifier {
    let color: Color

    func body(content: Content) -> some View {
        content
            .font(.headline)
            .foregroundColor(color)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct SectionTitleStyle: ViewModifier {
    let color: Color

    func body(content: Content) -> some View {
        content
            .font(.title3.weight(Typography.semibold))
            .foregroundColor(color)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct CardLabelStyle: ViewModifier {
    let color: Color

    func body(content: Content) -> some View {
        content
            .font(.headline.weight(Typography.medium))
            .foregroundColor(color)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct CaptionStyle: ViewModifier {
    let color: Color

    func body(content: Content) -> some View {
        content
            .font(.caption)
            .foregroundColor(color)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct TrendStyle: ViewModifier {
    let color: Color

    func body(content: Content) -> some View {
        content
            .font(.subheadline.weight(Typography.medium))
            .foregroundColor(color)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - ContentSizeCategory Extension (legacy component support)

extension ContentSizeCategory {
    /// Scale factor relative to default (.large) size
    var scaleFactor: CGFloat {
        switch self {
        case .extraSmall: return 0.82
        case .small: return 0.88
        case .medium: return 0.94
        case .large: return 1.0
        case .extraLarge: return 1.12
        case .extraExtraLarge: return 1.24
        case .extraExtraExtraLarge: return 1.35
        case .accessibilityMedium: return 1.6
        case .accessibilityLarge: return 1.9
        case .accessibilityExtraLarge: return 2.3
        case .accessibilityExtraExtraLarge: return 2.8
        case .accessibilityExtraExtraExtraLarge: return 3.5
        @unknown default: return 1.0
        }
    }
}
