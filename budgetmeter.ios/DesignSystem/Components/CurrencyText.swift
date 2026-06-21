//
//  CurrencyText.swift
//  BudgetMeter
//
//  Phase 7 — Shared currency display view with v2 SF Pro Rounded typography.
//

import SwiftUI

/// Renders a formatted currency amount using the shared v2 display contract.
struct CurrencyText: View {

    enum DisplaySize {
        /// Large hero financial amount (Home pace, primary dashboard number).
        case compact
        /// Standard body financial amount (rows, cards, totals).
        case normal
        /// Supporting caption-sized financial amount.
        case caption
    }

    let amount: Double
    var currencyCode: String? = nil
    var locale: Locale? = nil
    var size: DisplaySize = .normal
    var color: Color = .textPrimary

    private var formattedText: String {
        CurrencyDisplay.format(amount: amount, currencyCode: currencyCode, locale: locale)
    }

    var body: some View {
        styledText
            .accessibilityLabel(formattedText)
    }

    @ViewBuilder
    private var styledText: some View {
        switch size {
        case .compact:
            Text(formattedText)
                .paceHeroStyle(color: color)
        case .normal:
            Text(formattedText)
                .metricCompactStyle(color: color)
        case .caption:
            Text(formattedText)
                .modifier(CurrencyCaptionFinancialStyle(color: color))
        }
    }
}

// MARK: - Caption Financial Style (SF Pro Rounded)

private struct CurrencyCaptionFinancialStyle: ViewModifier {
    let color: Color
    @Environment(\.sizeCategory) private var sizeCategory

    func body(content: Content) -> some View {
        content
            .font(.system(
                size: Typography.captionSize * sizeCategory.scaleFactor,
                weight: .semibold,
                design: .rounded
            ))
            .monospacedDigit()
            .foregroundColor(color)
    }
}

// MARK: - Preview

#Preview("Currency Text Sizes") {
    VStack(alignment: .leading, spacing: 16) {
        CurrencyText(amount: 1_234.56, currencyCode: "USD", size: .compact)
        CurrencyText(amount: 45.67, currencyCode: "USD", size: .normal)
        CurrencyText(amount: 12.5, currencyCode: "EUR", locale: Locale(identifier: "de_DE"), size: .caption)
        CurrencyText(amount: 250, currencyCode: "TRY", locale: Locale(identifier: "tr_TR"), size: .normal)
    }
    .padding()
}
