//
//  HealthScoreCard.swift
//  BudgetMeter
//
//  Design System v2.0 - Health Score Card
//  Circular progress indicator for financial health score
//

import SwiftUI

/// Health score card with circular progress indicator
/// Displays score (0-100), status label, and optional description
struct HealthScoreCard: View {

    // MARK: - Properties

    /// Health score (0-100)
    let score: Int

    /// Status label ("Good", "Fair", "Poor")
    let statusLabel: String?

    /// Optional description text
    let description: String?

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

    private var displayStatus: String {
        statusLabel ?? defaultStatusLabel
    }

    private var defaultStatusLabel: String {
        switch score {
        case 70...100: return "Good"
        case 40..<70: return "Fair"
        default: return "Poor"
        }
    }

    private var accessibilityLabel: String {
        var label = "Financial Health Score: \(score) out of 100, \(displayStatus)"
        if let desc = description {
            label += ". \(desc)"
        }
        return label
    }

    // MARK: - Initialization

    init(
        score: Int,
        statusLabel: String? = nil,
        description: String? = nil,
        onTap: (() -> Void)? = nil
    ) {
        self.score = max(0, min(100, score)) // Clamp to 0-100
        self.statusLabel = statusLabel
        self.description = description
        self.onTap = onTap
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Title
            Text("Financial Health Score")
                .sectionTitleStyle()
                .frame(maxWidth: .infinity, alignment: .leading)

            // Circular Progress
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.chartInactive, lineWidth: ChartDimensions.circularProgressStroke)
                    .frame(
                        width: ChartDimensions.circularProgressDiameter,
                        height: ChartDimensions.circularProgressDiameter
                    )

                // Progress circle
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        scoreColor,
                        style: StrokeStyle(
                            lineWidth: ChartDimensions.circularProgressStroke,
                            lineCap: .round
                        )
                    )
                    .frame(
                        width: ChartDimensions.circularProgressDiameter,
                        height: ChartDimensions.circularProgressDiameter
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(
                        reduceMotion ? .none : AnimationCurve.slowSpring,
                        value: animatedScore
                    )

                // Score text
                VStack(spacing: Spacing.xs) {
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(score)")
                            .font(.system(size: 34 * sizeCategory.scaleFactor, weight: .bold))
                            .foregroundColor(.textPrimary)

                        Text("/100")
                            .smallMetricStyle(color: .textSecondary)
                    }

                    Text(displayStatus)
                        .font(.system(size: 15 * sizeCategory.scaleFactor, weight: .semibold))
                        .foregroundColor(scoreColor)
                }
            }
            .frame(maxWidth: .infinity)

            // Description (optional)
            if let desc = description {
                Text(desc)
                    .cardLabelStyle()
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .frame(height: description != nil ? CardHeight.large + 40 : CardHeight.large)
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
                withAnimation(AnimationCurve.slowSpring) {
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

#Preview("Good Score") {
    VStack(spacing: Spacing.xl) {
        HealthScoreCard(
            score: 78,
            description: "Your financial health is strong"
        )

        HealthScoreCard(
            score: 92,
            statusLabel: "Excellent"
        )
    }
    .padding()
    .background(Color.appBackground)
}

#Preview("Fair Score") {
    VStack(spacing: Spacing.xl) {
        HealthScoreCard(
            score: 55,
            description: "Your financial health needs attention"
        )

        HealthScoreCard(
            score: 48,
            statusLabel: "Fair"
        )
    }
    .padding()
    .background(Color.appBackground)
}

#Preview("Poor Score") {
    VStack(spacing: Spacing.xl) {
        HealthScoreCard(
            score: 28,
            description: "Let's work on improving your health"
        )

        HealthScoreCard(
            score: 15,
            statusLabel: "Needs Work"
        )
    }
    .padding()
    .background(Color.appBackground)
}

#Preview("Edge Cases") {
    VStack(spacing: Spacing.xl) {
        HealthScoreCard(
            score: 100,
            description: "Perfect score!"
        )

        HealthScoreCard(
            score: 0,
            description: "Getting started"
        )

        HealthScoreCard(
            score: 50,
            description: nil
        )
    }
    .padding()
    .background(Color.appBackground)
}

#Preview("With Tap Action") {
    HealthScoreCard(
        score: 78,
        description: "Tap to see details",
        onTap: {
            print("Health card tapped!")
        }
    )
    .padding()
    .background(Color.appBackground)
}

#Preview("Dark Mode") {
    VStack(spacing: Spacing.xl) {
        HealthScoreCard(
            score: 82,
            statusLabel: "Good",
            description: "Your financial health is strong"
        )

        HealthScoreCard(
            score: 45,
            statusLabel: "Fair",
            description: "Room for improvement"
        )
    }
    .padding()
    .background(Color.appBackground)
    .preferredColorScheme(.dark)
}
