//
//  CompactDailyBudgetCard.swift
//  BudgetMeter
//
//  Design System v2.1 - Compact Daily Budget Card
//  Primary card showing daily spending limit with progress bar
//

import SwiftUI

/// Compact primary card displaying daily budget with gradient and progress
/// Height: 100pt (vs 180pt hero card)
struct CompactDailyBudgetCard: View {

    // MARK: - Properties

    /// Daily budget amount to display
    let amount: Double

    /// Number of days left in current month
    let daysLeft: Int

    /// Total days in current month
    let totalDays: Int

    /// Currency symbol
    let currencySymbol: String

    /// Budget status color (green/yellow/red)
    let statusColor: Color

    /// Action when info icon is tapped
    let onInfoTap: () -> Void

    // MARK: - State

    @State private var isPressed = false
    @State private var animatedValue: Double = 0
    @State private var animatedProgress: Double = 0
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @Environment(\.sizeCategory) var sizeCategory

    // MARK: - Computed Properties

    private var gradient: LinearGradient {
        if statusColor == .green || statusColor == .brandPositive {
            return .positiveFlow
        } else if statusColor == .yellow || statusColor == .orange {
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

    private var progress: Double {
        guard totalDays > 0 else { return 0 }
        return Double(totalDays - daysLeft) / Double(totalDays)
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
        "home.daily_budget.subtitle".localized(
            defaultValue: "You can spend per day"
        )
    }

    private var daysLeftText: String {
        if daysLeft == 1 {
            return "home.daily_budget.last_day".localized(defaultValue: "Last day")
        } else {
            return String(localized: "home.daily_budget.days_left_compact", defaultValue: "\(daysLeft) days left")
        }
    }

    private var accessibilityLabel: String {
        "Daily budget: \(formattedValue). \(subtitleText). \(daysLeftText)"
    }

    // MARK: - Initialization

    init(
        amount: Double,
        daysLeft: Int,
        totalDays: Int = 30,
        currencySymbol: String = "$",
        statusColor: Color = .green,
        onInfoTap: @escaping () -> Void
    ) {
        self.amount = amount
        self.daysLeft = daysLeft
        self.totalDays = totalDays
        self.currencySymbol = currencySymbol
        self.statusColor = statusColor
        self.onInfoTap = onInfoTap
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Header Row: Label + Info Icon
            HStack {
                Text("home.daily_budget.title".localized(defaultValue: "Today you can spend"))
                    .font(.system(size: 13 * sizeCategory.scaleFactor, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))

                Spacer()

                Button(action: {
                    Haptics.light()
                    onInfoTap()
                }) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 16 * sizeCategory.scaleFactor, weight: .medium))
                        .foregroundColor(.white.opacity(0.85))
                }
                .accessibilityLabel("Daily budget information")
            }

            // Main Amount (32pt font - compact)
            Text(formattedValue)
                .font(.system(size: 32 * sizeCategory.scaleFactor, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer()

            // Progress bar with days left
            HStack(spacing: Spacing.sm) {
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Track
                        RoundedRectangle(cornerRadius: CornerRadius.tiny)
                            .fill(Color.white.opacity(0.3))
                            .frame(height: 6)

                        // Fill
                        RoundedRectangle(cornerRadius: CornerRadius.tiny)
                            .fill(Color.white.opacity(0.9))
                            .frame(width: geometry.size.width * (reduceMotion ? progress : animatedProgress), height: 6)
                    }
                }
                .frame(height: 6)

                // Days left label
                Text(daysLeftText)
                    .font(.system(size: 11 * sizeCategory.scaleFactor, weight: .semibold))
                    .foregroundColor(.white.opacity(0.85))
                    .fixedSize(horizontal: true, vertical: false)
            }
        }
        .frame(height: CardHeight.primary)
        .frame(maxWidth: .infinity)
        .padding(Spacing.lg)
        .background(gradient)
        .cornerRadius(CornerRadius.card)
        .shadow(
            color: ShadowStyle.hero.color,
            radius: ShadowStyle.hero.radius,
            x: ShadowStyle.hero.offset.width,
            y: ShadowStyle.hero.offset.height
        )
        .pressEffect(isPressed: $isPressed, haptic: false)
        .onAppear {
            if !reduceMotion {
                withAnimation(AnimationCurve.progressSpring) {
                    animatedValue = amount
                    animatedProgress = progress
                }
            } else {
                animatedValue = amount
                animatedProgress = progress
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }
}

// MARK: - Preview

#Preview("Positive Budget") {
    VStack(spacing: Spacing.lg) {
        CompactDailyBudgetCard(
            amount: 82.60,
            daysLeft: 16,
            totalDays: 30,
            currencySymbol: "$",
            statusColor: .green,
            onInfoTap: { print("Info tapped") }
        )

        CompactDailyBudgetCard(
            amount: 156.50,
            daysLeft: 10,
            totalDays: 31,
            currencySymbol: "€",
            statusColor: .green,
            onInfoTap: { print("Info tapped") }
        )
    }
    .padding()
    .background(Color.appBackground)
}

#Preview("Low Budget (Yellow)") {
    VStack(spacing: Spacing.lg) {
        CompactDailyBudgetCard(
            amount: 15.30,
            daysLeft: 5,
            totalDays: 30,
            currencySymbol: "$",
            statusColor: .yellow,
            onInfoTap: { print("Info tapped") }
        )

        CompactDailyBudgetCard(
            amount: 8.75,
            daysLeft: 3,
            totalDays: 28,
            currencySymbol: "£",
            statusColor: .orange,
            onInfoTap: { print("Info tapped") }
        )
    }
    .padding()
    .background(Color.appBackground)
}

#Preview("Negative Budget (Red)") {
    VStack(spacing: Spacing.lg) {
        CompactDailyBudgetCard(
            amount: -45.20,
            daysLeft: 20,
            totalDays: 30,
            currencySymbol: "$",
            statusColor: .red,
            onInfoTap: { print("Info tapped") }
        )

        CompactDailyBudgetCard(
            amount: -120.50,
            daysLeft: 8,
            totalDays: 31,
            currencySymbol: "₺",
            statusColor: .red,
            onInfoTap: { print("Info tapped") }
        )
    }
    .padding()
    .background(Color.appBackground)
}

#Preview("Last Day") {
    CompactDailyBudgetCard(
        amount: 250.00,
        daysLeft: 1,
        totalDays: 30,
        currencySymbol: "$",
        statusColor: .green,
        onInfoTap: { print("Info tapped") }
    )
    .padding()
    .background(Color.appBackground)
}

#Preview("Dark Mode") {
    VStack(spacing: Spacing.lg) {
        CompactDailyBudgetCard(
            amount: 95.30,
            daysLeft: 14,
            totalDays: 30,
            currencySymbol: "$",
            statusColor: .green,
            onInfoTap: { print("Info tapped") }
        )

        CompactDailyBudgetCard(
            amount: -25.40,
            daysLeft: 22,
            totalDays: 31,
            currencySymbol: "€",
            statusColor: .red,
            onInfoTap: { print("Info tapped") }
        )
    }
    .padding()
    .background(Color.appBackground)
    .preferredColorScheme(.dark)
}
