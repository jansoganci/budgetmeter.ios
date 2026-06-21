//
//  MetricCard.swift
//  BudgetMeter
//
//  Handoff wrapper — compact supporting metric card.
//

import SwiftUI

/// Compact metric card. Delegates to `CompactIntervalCard` for interval grids.
struct MetricCard: View {

    private let content: AnyView

    /// Generic metric with label and signed amount.
    init(
        label: String,
        amount: Double,
        currencyCode: String? = nil,
        accentColor: Color? = nil,
        onTap: (() -> Void)? = nil
    ) {
        let color = accentColor ?? (amount >= 0 ? Color.financialPositive : Color.financialNegative)
        self.content = AnyView(
            MetricCardGenericBody(
                label: label,
                amount: amount,
                currencyCode: currencyCode,
                accentColor: color,
                onTap: onTap
            )
        )
    }

    /// Delegate to existing interval card (hourly / daily / monthly).
    init(
        intervalType: CompactIntervalCard.IntervalType,
        amount: Double,
        currencySymbol: String,
        onTap: (() -> Void)? = nil
    ) {
        self.content = AnyView(
            CompactIntervalCard(
                type: intervalType,
                amount: amount,
                currencySymbol: currencySymbol,
                onTap: onTap
            )
        )
    }

    var body: some View {
        content
    }
}

private struct MetricCardGenericBody: View {
    let label: String
    let amount: Double
    let currencyCode: String?
    let accentColor: Color
    let onTap: (() -> Void)?

    @Environment(\.sizeCategory) private var sizeCategory

    private var accessibilityAmount: String {
        CurrencyDisplay.format(amount: amount, currencyCode: currencyCode)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(label)
                .font(.system(size: 11 * sizeCategory.scaleFactor, weight: .medium))
                .foregroundColor(.textSecondary)

            Spacer()

            CurrencyText(
                amount: amount,
                currencyCode: currencyCode,
                size: .normal,
                color: accentColor
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: CardHeight.metric)
        .padding(Spacing.md)
        .glassSurface()
        .onTapGesture {
            onTap?()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(accessibilityAmount)")
        .accessibilityAddTraits(onTap != nil ? [.isButton] : [])
    }
}

#Preview {
    HStack(spacing: Spacing.md) {
        MetricCard(intervalType: .daily, amount: 78, currencySymbol: "₺")
        MetricCard(label: "Net", amount: -120, currencyCode: "TRY")
    }
    .padding()
    .background(Color.appBackground)
}
