//
//  MonthSummaryCard.swift
//  BudgetMeter
//
//  Design System v2.1 - Compact Summary Card
//  Displays a single metric (Income/Expenses/Net) with trend
//

import SwiftUI

/// Compact card for displaying a single financial metric with trend
/// Used in 3-column grid for monthly summary
struct MonthSummaryCard: View {

    // MARK: - Types

    enum MetricType {
        case income
        case expenses
        case net

        var label: String {
            switch self {
            case .income: return String(localized: "home.summary.income", defaultValue: "Income")
            case .expenses: return String(localized: "home.summary.expenses", defaultValue: "Expenses")
            case .net: return String(localized: "home.summary.net", defaultValue: "Net")
            }
        }

        var iconName: String {
            switch self {
            case .income: return "arrow.down.circle.fill"
            case .expenses: return "arrow.up.circle.fill"
            case .net: return "plusminus.circle.fill"
            }
        }

        var iconColor: Color {
            switch self {
            case .income: return .brandPositive
            case .expenses: return .brandExpense
            case .net: return .brandProgress
            }
        }
    }

    // MARK: - Properties

    /// Type of metric (income, expenses, or net)
    let type: MetricType

    /// The amount value
    let amount: Double

    /// Currency symbol
    let currencySymbol: String

    /// Optional trend percentage
    let trendPercentage: Double?

    /// Optional tap action
    let onTap: (() -> Void)?

    // MARK: - State

    @State private var isPressed = false
    @Environment(\.sizeCategory) var sizeCategory

    // MARK: - Computed Properties

    private var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.groupingSeparator = ","

        let absValue = abs(amount)

        // Use compact format for large numbers
        if absValue >= 10000 {
            let thousands = absValue / 1000
            let formatted = formatter.string(from: NSNumber(value: thousands)) ?? "0"
            return "\(currencySymbol)\(formatted)K"
        } else {
            let formatted = formatter.string(from: NSNumber(value: absValue)) ?? "0"
            return "\(currencySymbol)\(formatted)"
        }
    }

    private var displayAmount: String {
        if type == .net && amount >= 0 {
            return "+\(formattedAmount)"
        } else if type == .net && amount < 0 {
            return "-\(formattedAmount)"
        }
        return formattedAmount
    }

    private var amountColor: Color {
        switch type {
        case .income: return .brandPositive
        case .expenses: return .brandExpense
        case .net: return amount >= 0 ? .brandPositive : .brandExpense
        }
    }

    private var accessibilityLabel: String {
        var label = "\(type.label): \(displayAmount)"
        if let trend = trendPercentage {
            let direction = trend > 0 ? "up" : trend < 0 ? "down" : "unchanged"
            label += ", \(direction) \(abs(Int(trend))) percent"
        }
        return label
    }

    // MARK: - Initialization

    init(
        type: MetricType,
        amount: Double,
        currencySymbol: String = "$",
        trendPercentage: Double? = nil,
        onTap: (() -> Void)? = nil
    ) {
        self.type = type
        self.amount = amount
        self.currencySymbol = currencySymbol
        self.trendPercentage = trendPercentage
        self.onTap = onTap
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            // Label with icon
            HStack(spacing: Spacing.xs) {
                Image(systemName: type.iconName)
                    .font(.system(size: 12 * sizeCategory.scaleFactor, weight: .medium))
                    .foregroundColor(type.iconColor)

                Text(type.label)
                    .font(.system(size: 12 * sizeCategory.scaleFactor, weight: .medium))
                    .foregroundColor(.textSecondary)
            }

            // Amount
            Text(displayAmount)
                .font(.system(size: 18 * sizeCategory.scaleFactor, weight: .bold, design: .rounded))
                .foregroundColor(amountColor)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            // Trend indicator
            if let trend = trendPercentage {
                TrendIndicator(percentage: trend)
            } else {
                // Placeholder to maintain consistent height
                Text(" ")
                    .font(.system(size: 12 * sizeCategory.scaleFactor))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: CardHeight.summary)
        .padding(Spacing.md)
        .background(Color.cardBackground)
        .cornerRadius(CornerRadius.button)
        .shadow(
            color: ShadowStyle.small.color,
            radius: ShadowStyle.small.radius,
            x: ShadowStyle.small.offset.width,
            y: ShadowStyle.small.offset.height
        )
        .pressEffect(isPressed: $isPressed, haptic: onTap != nil)
        .onTapGesture {
            if let action = onTap {
                Haptics.light()
                action()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(onTap != nil ? [.isButton] : [])
    }
}

// MARK: - Preview

#Preview("All Types") {
    VStack(spacing: Spacing.lg) {
        HStack(spacing: Spacing.md) {
            MonthSummaryCard(
                type: .income,
                amount: 5200,
                trendPercentage: 8.5
            )
            MonthSummaryCard(
                type: .expenses,
                amount: 2750,
                trendPercentage: -3.2
            )
            MonthSummaryCard(
                type: .net,
                amount: 2450,
                trendPercentage: 12.0
            )
        }

        HStack(spacing: Spacing.md) {
            MonthSummaryCard(
                type: .income,
                amount: 12500,
                currencySymbol: "€"
            )
            MonthSummaryCard(
                type: .expenses,
                amount: 15200,
                currencySymbol: "€"
            )
            MonthSummaryCard(
                type: .net,
                amount: -2700,
                currencySymbol: "€",
                trendPercentage: -15.0
            )
        }
    }
    .padding()
    .background(Color.appBackground)
}

#Preview("Large Numbers") {
    HStack(spacing: Spacing.md) {
        MonthSummaryCard(
            type: .income,
            amount: 125000,
            trendPercentage: 25.0
        )
        MonthSummaryCard(
            type: .expenses,
            amount: 89500,
            trendPercentage: -5.0
        )
        MonthSummaryCard(
            type: .net,
            amount: 35500,
            trendPercentage: 45.0
        )
    }
    .padding()
    .background(Color.appBackground)
}

#Preview("Dark Mode") {
    HStack(spacing: Spacing.md) {
        MonthSummaryCard(
            type: .income,
            amount: 5200,
            trendPercentage: 8.5
        )
        MonthSummaryCard(
            type: .expenses,
            amount: 2750,
            trendPercentage: -3.2
        )
        MonthSummaryCard(
            type: .net,
            amount: 2450,
            trendPercentage: 12.0
        )
    }
    .padding()
    .background(Color.appBackground)
    .preferredColorScheme(.dark)
}
