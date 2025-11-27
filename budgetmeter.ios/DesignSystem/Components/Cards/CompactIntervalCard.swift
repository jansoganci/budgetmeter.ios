//
//  CompactIntervalCard.swift
//  BudgetMeter
//
//  Design System v2.1 - Compact Interval Metric Card
//  Displays hourly/daily/monthly metrics in compact form
//

import SwiftUI

/// Compact card for displaying interval-based financial metrics
/// Used in 3-column grid for hourly/daily/monthly breakdown
struct CompactIntervalCard: View {

    // MARK: - Types

    enum IntervalType {
        case hourly
        case daily
        case monthly

        var label: String {
            switch self {
            case .hourly: return String(localized: "home.interval.hourly", defaultValue: "Hourly")
            case .daily: return String(localized: "home.interval.daily", defaultValue: "Daily")
            case .monthly: return String(localized: "home.interval.monthly", defaultValue: "Monthly")
            }
        }

        var iconName: String {
            switch self {
            case .hourly: return "clock.fill"
            case .daily: return "sun.max.fill"
            case .monthly: return "calendar"
            }
        }
    }

    // MARK: - Properties

    /// Type of interval (hourly, daily, monthly)
    let type: IntervalType

    /// The amount value (positive = income surplus, negative = expense surplus)
    let amount: Double

    /// Currency symbol
    let currencySymbol: String

    /// Optional tap action
    let onTap: (() -> Void)?

    // MARK: - State

    @State private var isPressed = false
    @Environment(\.sizeCategory) var sizeCategory

    // MARK: - Computed Properties

    private var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        formatter.groupingSeparator = ","

        let absValue = abs(amount)

        // Use compact format for large numbers
        if absValue >= 10000 {
            let thousands = absValue / 1000
            formatter.maximumFractionDigits = 1
            let formatted = formatter.string(from: NSNumber(value: thousands)) ?? "0"
            return "\(currencySymbol)\(formatted)K"
        } else if absValue >= 1000 {
            formatter.maximumFractionDigits = 0
            let formatted = formatter.string(from: NSNumber(value: absValue)) ?? "0"
            return "\(currencySymbol)\(formatted)"
        } else {
            let formatted = formatter.string(from: NSNumber(value: absValue)) ?? "0"
            return "\(currencySymbol)\(formatted)"
        }
    }

    private var displayAmount: String {
        if amount >= 0 {
            return "+\(formattedAmount)"
        } else {
            return "-\(formattedAmount)"
        }
    }

    private var amountColor: Color {
        amount >= 0 ? .brandPositive : .brandExpense
    }

    private var accessibilityLabel: String {
        let direction = amount >= 0 ? "positive" : "negative"
        return "\(type.label): \(direction) \(formattedAmount)"
    }

    // MARK: - Initialization

    init(
        type: IntervalType,
        amount: Double,
        currencySymbol: String = "$",
        onTap: (() -> Void)? = nil
    ) {
        self.type = type
        self.amount = amount
        self.currencySymbol = currencySymbol
        self.onTap = onTap
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            // Label with icon
            HStack(spacing: Spacing.xs) {
                Image(systemName: type.iconName)
                    .font(.system(size: 11 * sizeCategory.scaleFactor, weight: .medium))
                    .foregroundColor(.textSecondary)

                Text(type.label)
                    .font(.system(size: 11 * sizeCategory.scaleFactor, weight: .medium))
                    .foregroundColor(.textSecondary)
            }

            Spacer()

            // Amount
            Text(displayAmount)
                .font(.system(size: 17 * sizeCategory.scaleFactor, weight: .bold, design: .rounded))
                .foregroundColor(amountColor)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: CardHeight.interval)
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

#Preview("All Intervals") {
    HStack(spacing: Spacing.md) {
        CompactIntervalCard(
            type: .hourly,
            amount: 3.25
        )
        CompactIntervalCard(
            type: .daily,
            amount: 78.00
        )
        CompactIntervalCard(
            type: .monthly,
            amount: 2340
        )
    }
    .padding()
    .background(Color.appBackground)
}

#Preview("Negative Values") {
    HStack(spacing: Spacing.md) {
        CompactIntervalCard(
            type: .hourly,
            amount: -1.50
        )
        CompactIntervalCard(
            type: .daily,
            amount: -36.00
        )
        CompactIntervalCard(
            type: .monthly,
            amount: -1080
        )
    }
    .padding()
    .background(Color.appBackground)
}

#Preview("Large Numbers") {
    HStack(spacing: Spacing.md) {
        CompactIntervalCard(
            type: .hourly,
            amount: 125.50,
            currencySymbol: "€"
        )
        CompactIntervalCard(
            type: .daily,
            amount: 3012,
            currencySymbol: "€"
        )
        CompactIntervalCard(
            type: .monthly,
            amount: 90360,
            currencySymbol: "€"
        )
    }
    .padding()
    .background(Color.appBackground)
}

#Preview("Dark Mode") {
    HStack(spacing: Spacing.md) {
        CompactIntervalCard(
            type: .hourly,
            amount: 3.25
        )
        CompactIntervalCard(
            type: .daily,
            amount: 78.00
        )
        CompactIntervalCard(
            type: .monthly,
            amount: 2340
        )
    }
    .padding()
    .background(Color.appBackground)
    .preferredColorScheme(.dark)
}
