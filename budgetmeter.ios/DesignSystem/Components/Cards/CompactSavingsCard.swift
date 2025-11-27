//
//  CompactSavingsCard.swift
//  BudgetMeter
//
//  Design System v2.1 - Compact Savings Goal Card
//  Shows savings progress in a small card for dashboard
//

import SwiftUI

/// Compact savings goal card with horizontal progress bar
/// Height: 90pt (vs 160pt for full card)
struct CompactSavingsCard: View {

    // MARK: - Properties

    /// Goal name to display
    let goalName: String?

    /// Emoji icon for the goal
    let emoji: String?

    /// Current saved amount
    let currentAmount: Double

    /// Target goal amount
    let targetAmount: Double

    /// Currency symbol
    let currencySymbol: String

    /// Optional tap action
    let onTap: (() -> Void)?

    // MARK: - State

    @State private var animatedProgress: Double = 0
    @State private var isPressed = false
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @Environment(\.sizeCategory) var sizeCategory

    // MARK: - Computed Properties

    private var progress: Double {
        guard targetAmount > 0 else { return 0 }
        let calculated = min(max(0, currentAmount) / targetAmount, 1.0)
        return reduceMotion ? calculated : animatedProgress
    }

    private var progressPercentage: Int {
        guard targetAmount > 0 else { return 0 }
        return Int(min(currentAmount / targetAmount, 1.0) * 100)
    }

    private var displayTitle: String {
        if let name = goalName, !name.isEmpty {
            if let emoji = emoji, !emoji.isEmpty {
                return "\(emoji) \(name)"
            }
            return name
        }
        return String(localized: "home.savings.title", defaultValue: "Savings")
    }

    private var formattedProgress: String {
        let currentFormatted = formatCompact(currentAmount)
        let targetFormatted = formatCompact(targetAmount)
        return "\(currencySymbol)\(currentFormatted)/\(currencySymbol)\(targetFormatted)"
    }

    private var accessibilityLabel: String {
        let current = formatFull(currentAmount)
        let target = formatFull(targetAmount)
        return "\(displayTitle): \(current) of \(target), \(progressPercentage)% complete"
    }

    // MARK: - Initialization

    init(
        goalName: String? = nil,
        emoji: String? = nil,
        currentAmount: Double,
        targetAmount: Double,
        currencySymbol: String = "$",
        onTap: (() -> Void)? = nil
    ) {
        self.goalName = goalName
        self.emoji = emoji
        self.currentAmount = max(0, currentAmount)
        self.targetAmount = max(0, targetAmount)
        self.currencySymbol = currencySymbol
        self.onTap = onTap
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Header: Title
            Text(displayTitle)
                .font(.system(size: 13 * sizeCategory.scaleFactor, weight: .medium))
                .foregroundColor(.textSecondary)
                .lineLimit(1)

            // Amount: Current / Target
            Text(formattedProgress)
                .font(.system(size: 17 * sizeCategory.scaleFactor, weight: .bold, design: .rounded))
                .foregroundColor(.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer()

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: CornerRadius.tiny)
                        .fill(Color.chartInactive)
                        .frame(height: ChartDimensions.compactProgressHeight)

                    // Progress fill
                    RoundedRectangle(cornerRadius: CornerRadius.tiny)
                        .fill(LinearGradient.progress)
                        .frame(
                            width: geometry.size.width * progress,
                            height: ChartDimensions.compactProgressHeight
                        )
                        .animation(
                            reduceMotion ? .none : AnimationCurve.quickSpring,
                            value: animatedProgress
                        )
                }
            }
            .frame(height: ChartDimensions.compactProgressHeight)

            // Percentage
            Text("\(progressPercentage)%")
                .font(.system(size: 11 * sizeCategory.scaleFactor, weight: .semibold))
                .foregroundColor(.brandProgress)
        }
        .frame(height: CardHeight.metric)
        .padding(Spacing.md)
        .background(Color.cardBackground)
        .cornerRadius(CornerRadius.card)
        .shadow(
            color: ShadowStyle.card.color,
            radius: ShadowStyle.card.radius,
            x: ShadowStyle.card.offset.width,
            y: ShadowStyle.card.offset.height
        )
        .pressEffect(isPressed: $isPressed, haptic: onTap != nil)
        .onTapGesture {
            if let action = onTap {
                Haptics.medium()
                action()
            }
        }
        .onAppear {
            let targetProgress = targetAmount > 0 ? min(max(0, currentAmount) / targetAmount, 1.0) : 0
            if !reduceMotion {
                withAnimation(AnimationCurve.quickSpring) {
                    animatedProgress = targetProgress
                }
            } else {
                animatedProgress = targetProgress
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(onTap != nil ? [.isButton] : [])
    }

    // MARK: - Helper Methods

    private func formatCompact(_ value: Double) -> String {
        if value >= 10000 {
            let thousands = value / 1000
            return String(format: "%.0fK", thousands)
        } else if value >= 1000 {
            let thousands = value / 1000
            return String(format: "%.1fK", thousands)
        } else {
            return String(format: "%.0f", value)
        }
    }

    private func formatFull(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        formatter.groupingSeparator = ","
        return "\(currencySymbol)\(formatter.string(from: NSNumber(value: value)) ?? "0")"
    }
}

// MARK: - Preview

#Preview("With Goal Name") {
    VStack(spacing: Spacing.lg) {
        CompactSavingsCard(
            goalName: "Vacation Fund",
            emoji: "🏖️",
            currentAmount: 2500,
            targetAmount: 5000
        )

        CompactSavingsCard(
            goalName: "New Car",
            emoji: "🚗",
            currentAmount: 12500,
            targetAmount: 30000,
            currencySymbol: "€"
        )

        CompactSavingsCard(
            goalName: "Emergency Fund",
            emoji: "🚨",
            currentAmount: 8000,
            targetAmount: 10000
        )
    }
    .padding()
    .background(Color.appBackground)
}

#Preview("Progress States") {
    VStack(spacing: Spacing.lg) {
        CompactSavingsCard(
            goalName: "Starting Out",
            currentAmount: 500,
            targetAmount: 10000
        )

        CompactSavingsCard(
            goalName: "Halfway There",
            currentAmount: 5000,
            targetAmount: 10000
        )

        CompactSavingsCard(
            goalName: "Almost Done",
            currentAmount: 9500,
            targetAmount: 10000
        )

        CompactSavingsCard(
            goalName: "Achieved!",
            emoji: "🎉",
            currentAmount: 10000,
            targetAmount: 10000
        )
    }
    .padding()
    .background(Color.appBackground)
}

#Preview("Large Numbers") {
    VStack(spacing: Spacing.lg) {
        CompactSavingsCard(
            goalName: "House",
            emoji: "🏠",
            currentAmount: 75000,
            targetAmount: 200000
        )

        CompactSavingsCard(
            goalName: "Retirement",
            emoji: "🏝️",
            currentAmount: 450000,
            targetAmount: 1000000
        )
    }
    .padding()
    .background(Color.appBackground)
}

#Preview("No Goal Name") {
    CompactSavingsCard(
        currentAmount: 3500,
        targetAmount: 5000
    )
    .padding()
    .background(Color.appBackground)
}

#Preview("In 2-Column Layout") {
    HStack(spacing: Spacing.md) {
        CompactHealthCard(score: 78)
        CompactSavingsCard(
            goalName: "Vacation",
            emoji: "🏖️",
            currentAmount: 2500,
            targetAmount: 5000
        )
    }
    .padding()
    .background(Color.appBackground)
}

#Preview("Dark Mode") {
    VStack(spacing: Spacing.lg) {
        CompactSavingsCard(
            goalName: "Emergency Fund",
            emoji: "🚨",
            currentAmount: 7500,
            targetAmount: 10000
        )

        CompactSavingsCard(
            goalName: "Vacation",
            emoji: "✈️",
            currentAmount: 1200,
            targetAmount: 3000
        )
    }
    .padding()
    .background(Color.appBackground)
    .preferredColorScheme(.dark)
}
