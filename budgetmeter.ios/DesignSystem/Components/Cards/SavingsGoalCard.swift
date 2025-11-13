//
//  SavingsGoalCard.swift
//  BudgetMeter
//
//  Design System v2.0 - Savings Goal Card
//  Horizontal progress bar with milestone markers
//

import SwiftUI

/// Savings goal card with horizontal progress and milestone markers
/// Shows current progress, target amount, and optional target date
struct SavingsGoalCard: View {

    // MARK: - Properties

    /// Current saved amount
    let currentAmount: Double

    /// Target goal amount
    let targetAmount: Double

    /// Currency symbol
    let currencySymbol: String

    /// Optional target date
    let targetDate: String?

    /// Milestone percentages to show (default: [50, 75, 100])
    let milestones: [Double]

    /// Optional tap action
    let onTap: (() -> Void)?

    // MARK: - State

    @State private var animatedProgress: Double = 0
    @State private var isPressed = false
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    // MARK: - Computed Properties

    private var progress: Double {
        guard targetAmount > 0 else { return 0 }
        let calculated = min(currentAmount / targetAmount, 1.0)
        return reduceMotion ? calculated : animatedProgress
    }

    private var progressPercentage: Int {
        Int(progress * 100)
    }

    private var formattedCurrent: String {
        formatCurrency(currentAmount)
    }

    private var formattedTarget: String {
        formatCurrency(targetAmount)
    }

    private var accessibilityLabel: String {
        var label = "Savings Goal: \(formattedCurrent) of \(formattedTarget), \(progressPercentage)% complete"
        if let date = targetDate {
            label += ". Target date: \(date)"
        }
        return label
    }

    // MARK: - Initialization

    init(
        currentAmount: Double,
        targetAmount: Double,
        currencySymbol: String = "$",
        targetDate: String? = nil,
        milestones: [Double] = [0.5, 0.75, 1.0],
        onTap: (() -> Void)? = nil
    ) {
        self.currentAmount = max(0, currentAmount)
        self.targetAmount = max(0, targetAmount)
        self.currencySymbol = currencySymbol
        self.targetDate = targetDate
        self.milestones = milestones.sorted()
        self.onTap = onTap
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header
            HStack {
                Text("Savings Goal")
                    .sectionTitleStyle()

                Spacer()

                Text("Target: \(formattedTarget)")
                    .cardLabelStyle()
            }

            Spacer()

            // Current Amount
            Text(formattedCurrent)
                .mediumMetricStyle(color: .brandProgress)

            Spacer()

            // Milestone Markers
            HStack(spacing: 0) {
                ForEach(milestones, id: \.self) { milestone in
                    Spacer()
                        .frame(maxWidth: .infinity)
                    milestoneMarker(for: milestone)
                }
            }
            .padding(.bottom, Spacing.xs)

            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: CornerRadius.small)
                        .fill(Color.chartInactive)
                        .frame(height: ChartDimensions.horizontalProgressHeight)

                    // Progress Fill
                    RoundedRectangle(cornerRadius: CornerRadius.small)
                        .fill(LinearGradient.progress)
                        .frame(
                            width: geometry.size.width * progress,
                            height: ChartDimensions.horizontalProgressHeight
                        )
                }
            }
            .frame(height: ChartDimensions.horizontalProgressHeight)

            // Target Date (optional)
            if let date = targetDate {
                Text("Target: \(date)")
                    .captionStyle()
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .frame(height: CardHeight.large)
        .dashboardCard()
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
                    animatedProgress = min(currentAmount / targetAmount, 1.0)
                }
            } else {
                animatedProgress = min(currentAmount / targetAmount, 1.0)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(onTap != nil ? [.isButton] : [])
    }

    // MARK: - Helper Views

    private func milestoneMarker(for milestone: Double) -> some View {
        let isAchieved = progress >= milestone
        return Circle()
            .fill(isAchieved ? Color.brandProgress : Color.chartInactive)
            .frame(
                width: ChartDimensions.milestoneMarkerSize,
                height: ChartDimensions.milestoneMarkerSize
            )
            .overlay(
                Circle()
                    .stroke(Color.cardBackground, lineWidth: 2)
            )
    }

    // MARK: - Helper Methods

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        formatter.groupingSeparator = ","

        let formatted = formatter.string(from: NSNumber(value: value)) ?? "0"
        return "\(currencySymbol)\(formatted)"
    }
}

// MARK: - Preview

#Preview("Progress Stages") {
    VStack(spacing: Spacing.xl) {
        // 25% progress
        SavingsGoalCard(
            currentAmount: 12500,
            targetAmount: 50000,
            currencySymbol: "€",
            targetDate: "Dec 2025"
        )

        // 50% progress
        SavingsGoalCard(
            currentAmount: 25000,
            targetAmount: 50000,
            currencySymbol: "$",
            targetDate: "Dec 2025"
        )

        // 77% progress
        SavingsGoalCard(
            currentAmount: 38500,
            targetAmount: 50000,
            currencySymbol: "$",
            targetDate: "Dec 2025"
        )

        // 100% progress
        SavingsGoalCard(
            currentAmount: 50000,
            targetAmount: 50000,
            currencySymbol: "£",
            targetDate: "Dec 2025"
        )
    }
    .padding()
    .background(Color.appBackground)
}

#Preview("Different Amounts") {
    VStack(spacing: Spacing.xl) {
        // Small goal
        SavingsGoalCard(
            currentAmount: 1500,
            targetAmount: 5000,
            currencySymbol: "$",
            targetDate: "Jun 2025"
        )

        // Medium goal
        SavingsGoalCard(
            currentAmount: 35000,
            targetAmount: 100000,
            currencySymbol: "€"
        )

        // Large goal
        SavingsGoalCard(
            currentAmount: 450000,
            targetAmount: 1000000,
            currencySymbol: "$",
            targetDate: "2030"
        )
    }
    .padding()
    .background(Color.appBackground)
}

#Preview("No Target Date") {
    SavingsGoalCard(
        currentAmount: 28500,
        targetAmount: 50000,
        currencySymbol: "$",
        targetDate: nil
    )
    .padding()
    .background(Color.appBackground)
}

#Preview("Custom Milestones") {
    VStack(spacing: Spacing.xl) {
        // 25%, 50%, 75%, 100%
        SavingsGoalCard(
            currentAmount: 30000,
            targetAmount: 50000,
            currencySymbol: "$",
            targetDate: "Dec 2025",
            milestones: [0.25, 0.5, 0.75, 1.0]
        )

        // Only 50% and 100%
        SavingsGoalCard(
            currentAmount: 30000,
            targetAmount: 50000,
            currencySymbol: "$",
            targetDate: "Dec 2025",
            milestones: [0.5, 1.0]
        )
    }
    .padding()
    .background(Color.appBackground)
}

#Preview("Over 100%") {
    SavingsGoalCard(
        currentAmount: 65000,
        targetAmount: 50000,
        currencySymbol: "$",
        targetDate: "Achieved!"
    )
    .padding()
    .background(Color.appBackground)
}

#Preview("Zero Progress") {
    SavingsGoalCard(
        currentAmount: 0,
        targetAmount: 50000,
        currencySymbol: "€",
        targetDate: "Dec 2025"
    )
    .padding()
    .background(Color.appBackground)
}

#Preview("With Tap Action") {
    SavingsGoalCard(
        currentAmount: 38500,
        targetAmount: 50000,
        currencySymbol: "$",
        targetDate: "Dec 2025",
        onTap: {
            print("Savings goal card tapped!")
        }
    )
    .padding()
    .background(Color.appBackground)
}

#Preview("Dark Mode") {
    VStack(spacing: Spacing.xl) {
        SavingsGoalCard(
            currentAmount: 38500,
            targetAmount: 50000,
            currencySymbol: "$",
            targetDate: "Dec 2025"
        )

        SavingsGoalCard(
            currentAmount: 15000,
            targetAmount: 50000,
            currencySymbol: "€",
            targetDate: "Dec 2025"
        )
    }
    .padding()
    .background(Color.appBackground)
    .preferredColorScheme(.dark)
}
