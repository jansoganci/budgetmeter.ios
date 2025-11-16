//
//  HeroNetFlowCard.swift
//  BudgetMeter
//
//  Design System v2.0 - Hero Net Flow Card
//  Prominent gradient card displaying primary financial metric
//

import SwiftUI

/// Hero card displaying net flow with gradient background and trend indicator
/// Height: 180pt minimum, gradient background, animated value
struct HeroNetFlowCard: View {

    // MARK: - Properties

    /// Net flow value to display
    let value: Double

    /// Label text (e.g., "Net Flow This Month")
    let label: String

    /// Trend percentage (optional)
    let trendPercentage: Double?

    /// Currency symbol
    let currencySymbol: String

    /// Tap action
    let onTap: (() -> Void)?

    // MARK: - State

    @State private var isPressed = false
    @State private var animatedValue: Double = 0
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    // MARK: - Computed Properties

    private var isPositive: Bool {
        value >= 0
    }

    private var gradient: LinearGradient {
        if value > 0 {
            return .positiveFlow
        } else if value < 0 {
            return .negativeFlow
        } else {
            return .neutral
        }
    }

    private var formattedValue: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = ","

        let absValue = abs(reduceMotion ? value : animatedValue)
        let formatted = formatter.string(from: NSNumber(value: absValue)) ?? "0.00"
        let sign = value >= 0 ? "+" : "-"

        return "\(sign)\(currencySymbol)\(formatted)"
    }

    private var accessibilityLabel: String {
        var label = "\(self.label): \(formattedValue)"
        if let trend = trendPercentage {
            let direction = trend > 0 ? "up" : trend < 0 ? "down" : "unchanged"
            label += ", trend \(direction) by \(abs(trend)) percent"
        }
        return label
    }

    // MARK: - Initialization

    init(
        value: Double,
        label: String,
        trendPercentage: Double? = nil,
        currencySymbol: String = "$",
        onTap: (() -> Void)? = nil
    ) {
        self.value = value
        self.label = label
        self.trendPercentage = trendPercentage
        self.currencySymbol = currencySymbol
        self.onTap = onTap
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Label
            Text(label)
                .cardLabelStyle(color: .white.opacity(0.9))

            Spacer()

            // Hero Value
            Text(formattedValue)
                .heroMetricStyle(color: .white)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Trend Indicator
            if let trend = trendPercentage {
                TrendIndicator(percentage: trend, color: .white)
            }

            Spacer()
        }
        .frame(height: CardHeight.hero)
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(gradient)
        .heroCard(padding: 0)
        .pressEffect(isPressed: $isPressed, haptic: true)
        .onTapGesture {
            if let action = onTap {
                Haptics.medium()
                action()
            }
        }
        .onAppear {
            if !reduceMotion {
                withAnimation(AnimationCurve.progressSpring) {
                    animatedValue = value
                }
            } else {
                animatedValue = value
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(onTap != nil ? [.isButton] : [])
    }
}

// MARK: - Preview

#Preview("Positive Flow") {
    VStack(spacing: Spacing.xl) {
        HeroNetFlowCard(
            value: 2450.50,
            label: "Net Flow This Month",
            trendPercentage: 12.5,
            currencySymbol: "$"
        )

        HeroNetFlowCard(
            value: 5820.75,
            label: "Net Flow This Month",
            trendPercentage: 25.3,
            currencySymbol: "€"
        )
    }
    .padding()
    .background(Color.appBackground)
}

#Preview("Negative Flow") {
    VStack(spacing: Spacing.xl) {
        HeroNetFlowCard(
            value: -1250.30,
            label: "Net Flow This Month",
            trendPercentage: -8.2,
            currencySymbol: "$"
        )

        HeroNetFlowCard(
            value: -3450.00,
            label: "Net Flow This Month",
            trendPercentage: -15.7,
            currencySymbol: "£"
        )
    }
    .padding()
    .background(Color.appBackground)
}

#Preview("Zero & No Trend") {
    VStack(spacing: Spacing.xl) {
        HeroNetFlowCard(
            value: 0.00,
            label: "Net Flow This Month",
            trendPercentage: 0.0,
            currencySymbol: "$"
        )

        HeroNetFlowCard(
            value: 1234.56,
            label: "Net Flow This Month",
            trendPercentage: nil,
            currencySymbol: "€"
        )
    }
    .padding()
    .background(Color.appBackground)
}

#Preview("With Tap Action") {
    HeroNetFlowCard(
        value: 4567.89,
        label: "Net Flow This Month",
        trendPercentage: 18.4,
        currencySymbol: "$",
        onTap: {
            print("Hero card tapped!")
        }
    )
    .padding()
    .background(Color.appBackground)
}

#Preview("Dark Mode") {
    VStack(spacing: Spacing.xl) {
        HeroNetFlowCard(
            value: 3250.00,
            label: "Net Flow This Month",
            trendPercentage: 10.5,
            currencySymbol: "$"
        )

        HeroNetFlowCard(
            value: -1850.50,
            label: "Net Flow This Month",
            trendPercentage: -5.3,
            currencySymbol: "€"
        )
    }
    .padding()
    .background(Color.appBackground)
    .preferredColorScheme(.dark)
}

#Preview("Large Values") {
    VStack(spacing: Spacing.xl) {
        HeroNetFlowCard(
            value: 125_450.75,
            label: "Net Flow This Year",
            trendPercentage: 45.2,
            currencySymbol: "$"
        )

        HeroNetFlowCard(
            value: -89_234.50,
            label: "Net Flow This Year",
            trendPercentage: -22.8,
            currencySymbol: "¥"
        )
    }
    .padding()
    .background(Color.appBackground)
}
