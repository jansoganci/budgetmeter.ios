//
//  DailyBudgetCard.swift
//  BudgetMeter
//
//  Daily Budget Card - Shows recommended daily spending limit
//  Created by BudgetMeter Team on 24.11.2025.
//

import SwiftUI

/// Card displaying daily budget with color-coded gradient background
/// Shows recommended daily spending based on monthly income/expense patterns
struct DailyBudgetCard: View {

    // MARK: - Properties

    /// Daily budget amount to display
    let amount: Double

    /// Number of days left in current month
    let daysLeft: Int

    /// Monthly net flow (for subtitle)
    let monthlyNet: Double

    /// Currency symbol
    let currencySymbol: String

    /// Color for the card (green/yellow/red)
    let color: Color

    /// Action when info icon is tapped
    let onInfoTap: () -> Void

    // MARK: - State

    @State private var isPressed = false
    @State private var animatedValue: Double = 0
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    // MARK: - Computed Properties

    private var gradient: LinearGradient {
        if color == .green {
            return .positiveFlow
        } else if color == .yellow {
            return LinearGradient(
                colors: [
                    Color.yellow.opacity(0.8),
                    Color.orange.opacity(0.6)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return .negativeFlow
        }
    }

    private var formattedValue: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        formatter.groupingSeparator = ","

        let absValue = abs(reduceMotion ? amount : animatedValue)
        let formatted = formatter.string(from: NSNumber(value: absValue)) ?? "0"
        let sign = amount >= 0 ? "" : "-"

        return "\(sign)\(currencySymbol)\(formatted)"
    }

    private var subtitleText: String {
        return "home.daily_budget.subtitle".localized(
            defaultValue: "You can spend per day"
        )
    }

    private var daysLeftText: String {
        if daysLeft == 1 {
            return "home.daily_budget.last_day".localized(defaultValue: "Last day of month")
        } else {
            return "home.daily_budget.days_left".localized(
                defaultValue: "\(daysLeft) days left this month"
            )
        }
    }

    private var accessibilityLabel: String {
        "Daily budget: \(formattedValue). \(subtitleText). \(daysLeftText)"
    }

    // MARK: - Initialization

    init(
        amount: Double,
        daysLeft: Int,
        monthlyNet: Double,
        currencySymbol: String = "$",
        color: Color = .green,
        onInfoTap: @escaping () -> Void
    ) {
        self.amount = amount
        self.daysLeft = daysLeft
        self.monthlyNet = monthlyNet
        self.currencySymbol = currencySymbol
        self.color = color
        self.onInfoTap = onInfoTap
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header: Label with Info Icon
            HStack {
                Text("home.daily_budget.title".localized(defaultValue: "Daily Budget"))
                    .cardLabelStyle(color: .white.opacity(0.9))

                Spacer()

                // Info Icon Button
                Button(action: {
                    Haptics.light()
                    onInfoTap()
                }) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                }
                .accessibilityLabel("Daily budget information")
                .accessibilityHint("Tap to learn how daily budget is calculated")
            }

            Spacer()

            // Main Amount (60pt font as specified)
            Text(formattedValue)
                .font(.system(size: 60, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Subtitle
            Text(subtitleText)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.white.opacity(0.85))

            // Days Left Footer
            Text(daysLeftText)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.75))

            Spacer()
        }
        .frame(height: CardHeight.hero)
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(gradient)
        .heroCard(padding: 0)
        .pressEffect(isPressed: $isPressed, haptic: false)
        .onAppear {
            if !reduceMotion {
                withAnimation(AnimationCurve.progressSpring) {
                    animatedValue = amount
                }
            } else {
                animatedValue = amount
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }
}

// MARK: - Preview

#Preview("Positive Budget") {
    VStack(spacing: Spacing.xl) {
        DailyBudgetCard(
            amount: 82.60,
            daysLeft: 16,
            monthlyNet: 2478.12,
            currencySymbol: "$",
            color: .green,
            onInfoTap: {
                print("Info tapped")
            }
        )

        DailyBudgetCard(
            amount: 156.50,
            daysLeft: 10,
            monthlyNet: 4500.00,
            currencySymbol: "€",
            color: .green,
            onInfoTap: {
                print("Info tapped")
            }
        )
    }
    .padding()
    .background(Color.appBackground)
}

#Preview("Low Budget (Yellow)") {
    VStack(spacing: Spacing.xl) {
        DailyBudgetCard(
            amount: 15.30,
            daysLeft: 5,
            monthlyNet: 76.50,
            currencySymbol: "$",
            color: .yellow,
            onInfoTap: {
                print("Info tapped")
            }
        )

        DailyBudgetCard(
            amount: 8.75,
            daysLeft: 12,
            monthlyNet: 105.00,
            currencySymbol: "£",
            color: .yellow,
            onInfoTap: {
                print("Info tapped")
            }
        )
    }
    .padding()
    .background(Color.appBackground)
}

#Preview("Negative Budget (Red)") {
    VStack(spacing: Spacing.xl) {
        DailyBudgetCard(
            amount: -45.20,
            daysLeft: 20,
            monthlyNet: -904.00,
            currencySymbol: "$",
            color: .red,
            onInfoTap: {
                print("Info tapped")
            }
        )

        DailyBudgetCard(
            amount: -120.50,
            daysLeft: 8,
            monthlyNet: -964.00,
            currencySymbol: "₺",
            color: .red,
            onInfoTap: {
                print("Info tapped")
            }
        )
    }
    .padding()
    .background(Color.appBackground)
}

#Preview("Last Day of Month") {
    DailyBudgetCard(
        amount: 250.00,
        daysLeft: 1,
        monthlyNet: 250.00,
        currencySymbol: "$",
        color: .green,
        onInfoTap: {
            print("Info tapped")
        }
    )
    .padding()
    .background(Color.appBackground)
}

#Preview("Dark Mode") {
    VStack(spacing: Spacing.xl) {
        DailyBudgetCard(
            amount: 95.30,
            daysLeft: 14,
            monthlyNet: 2860.00,
            currencySymbol: "$",
            color: .green,
            onInfoTap: {
                print("Info tapped")
            }
        )

        DailyBudgetCard(
            amount: -25.40,
            daysLeft: 22,
            monthlyNet: -558.80,
            currencySymbol: "€",
            color: .red,
            onInfoTap: {
                print("Info tapped")
            }
        )
    }
    .padding()
    .background(Color.appBackground)
    .preferredColorScheme(.dark)
}
