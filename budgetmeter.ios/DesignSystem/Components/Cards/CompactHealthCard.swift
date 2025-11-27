//
//  CompactHealthCard.swift
//  BudgetMeter
//
//  Design System v2.1 - Compact Health Score Card
//  Small circular progress indicator for financial health
//

import SwiftUI

/// Compact health score card with 50pt circular indicator
/// Height: 90pt (vs 160pt+ for full card)
struct CompactHealthCard: View {

    // MARK: - Properties

    /// Health score (0-100)
    let score: Int

    /// Optional tap action
    let onTap: (() -> Void)?

    // MARK: - State

    @State private var animatedScore: Double = 0
    @State private var isPressed = false
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @Environment(\.sizeCategory) var sizeCategory

    // MARK: - Computed Properties

    private var progress: Double {
        reduceMotion ? Double(score) / 100.0 : animatedScore / 100.0
    }

    private var scoreColor: Color {
        Color.colorForHealthScore(score)
    }

    private var statusLabel: String {
        switch score {
        case 80...100:
            return String(localized: "home.health.excellent", defaultValue: "Excellent")
        case 70..<80:
            return String(localized: "home.health.good", defaultValue: "Good")
        case 50..<70:
            return String(localized: "home.health.fair", defaultValue: "Fair")
        case 30..<50:
            return String(localized: "home.health.needs_work", defaultValue: "Needs Work")
        default:
            return String(localized: "home.health.poor", defaultValue: "Poor")
        }
    }

    private var accessibilityLabel: String {
        "Financial Health: \(score) out of 100, \(statusLabel)"
    }

    // MARK: - Initialization

    init(
        score: Int,
        onTap: (() -> Void)? = nil
    ) {
        self.score = max(0, min(100, score))
        self.onTap = onTap
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Left side: Title and status
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(String(localized: "home.health.title", defaultValue: "Health"))
                    .font(.system(size: 13 * sizeCategory.scaleFactor, weight: .medium))
                    .foregroundColor(.textSecondary)

                // Score number
                Text("\(score)")
                    .font(.system(size: 28 * sizeCategory.scaleFactor, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)

                // Status label
                Text(statusLabel)
                    .font(.system(size: 12 * sizeCategory.scaleFactor, weight: .semibold))
                    .foregroundColor(scoreColor)
            }

            Spacer()

            // Right side: Compact circular progress
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.chartInactive, lineWidth: ChartDimensions.compactCircleStroke)

                // Progress circle
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        scoreColor,
                        style: StrokeStyle(
                            lineWidth: ChartDimensions.compactCircleStroke,
                            lineCap: .round
                        )
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(
                        reduceMotion ? .none : AnimationCurve.quickSpring,
                        value: animatedScore
                    )

                // Percentage in circle
                Text("\(score)%")
                    .font(.system(size: 11 * sizeCategory.scaleFactor, weight: .bold))
                    .foregroundColor(.textSecondary)
            }
            .frame(width: ChartDimensions.compactCircleDiameter, height: ChartDimensions.compactCircleDiameter)
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
            if !reduceMotion {
                withAnimation(AnimationCurve.quickSpring) {
                    animatedScore = Double(score)
                }
            } else {
                animatedScore = Double(score)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(onTap != nil ? [.isButton] : [])
    }
}

// MARK: - Preview

#Preview("All Scores") {
    VStack(spacing: Spacing.lg) {
        CompactHealthCard(score: 92)
        CompactHealthCard(score: 78)
        CompactHealthCard(score: 55)
        CompactHealthCard(score: 35)
        CompactHealthCard(score: 18)
    }
    .padding()
    .background(Color.appBackground)
}

#Preview("With Tap") {
    CompactHealthCard(
        score: 78,
        onTap: { print("Health card tapped") }
    )
    .padding()
    .background(Color.appBackground)
}

#Preview("Edge Cases") {
    VStack(spacing: Spacing.lg) {
        CompactHealthCard(score: 100)
        CompactHealthCard(score: 0)
        CompactHealthCard(score: 50)
    }
    .padding()
    .background(Color.appBackground)
}

#Preview("Dark Mode") {
    VStack(spacing: Spacing.lg) {
        CompactHealthCard(score: 85)
        CompactHealthCard(score: 45)
    }
    .padding()
    .background(Color.appBackground)
    .preferredColorScheme(.dark)
}

#Preview("In 2-Column Layout") {
    HStack(spacing: Spacing.md) {
        CompactHealthCard(score: 78)
        // Savings card would go here
        RoundedRectangle(cornerRadius: CornerRadius.card)
            .fill(Color.cardBackground)
            .frame(height: CardHeight.metric)
            .overlay(
                Text("ui.savings_card".localized(defaultValue: "Savings Card"))
                    .foregroundColor(.textSecondary)
            )
    }
    .padding()
    .background(Color.appBackground)
}
