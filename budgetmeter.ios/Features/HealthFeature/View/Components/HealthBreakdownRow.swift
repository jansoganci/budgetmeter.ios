//
//  HealthBreakdownRow.swift
//  BudgetMeter
//
//  Phase 1D: Financial Health Details - Breakdown Row Component
//  Created by BudgetMeter Team on 17.09.2025.
//

import SwiftUI

/// Individual health component breakdown row with progress bar
struct HealthBreakdownRow: View {

    // MARK: - Properties

    let icon: String
    let title: String
    let score: Int
    let description: String
    let isExpanded: Bool
    let onTap: () -> Void

    @State private var animatedProgress: Double = 0

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Main row content
            Button(action: {
                onTap()
            }) {
                VStack(spacing: 12) {
                    // Icon, Title, Score
                    HStack(spacing: 12) {
                        // Icon
                        Image(systemName: icon)
                            .font(.title2)
                            .foregroundColor(scoreColor)
                            .frame(width: 32)
                            .accessibilityHidden(true)

                        // Title
                        Text(title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)

                        Spacer()

                        // Score
                        Text("\(score)%")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(scoreColor)

                        // Chevron
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 8)

                            // Progress
                            RoundedRectangle(cornerRadius: 4)
                                .fill(scoreColor)
                                .frame(width: geometry.size.width * (animatedProgress / 100), height: 8)
                                .animation(.spring(response: 0.8, dampingFraction: 0.7), value: animatedProgress)
                        }
                    }
                    .frame(height: 8)
                }
                .padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Expanded description
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                        .padding(.bottom, 4)

                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    // Score interpretation
                    Text(scoreInterpretation)
                        .font(.caption)
                        .foregroundColor(scoreColor)
                        .fontWeight(.medium)
                        .padding(.top, 4)
                }
                .padding(.bottom, 12)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, 16)
        .onAppear {
            // Animate progress bar on appear
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1)) {
                animatedProgress = Double(score)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(score) percent")
        .accessibilityHint(isExpanded ? "Expanded. Double tap to collapse" : "Double tap to expand and see details")
        .accessibilityValue(scoreInterpretation)
    }

    // MARK: - Score Color

    private var scoreColor: Color {
        switch score {
        case 90...100:
            return .green
        case 75...89:
            return .blue
        case 60...74:
            return .yellow
        case 40...59:
            return .orange
        default:
            return .red
        }
    }

    // MARK: - Score Interpretation

    private var scoreInterpretation: String {
        switch score {
        case 90...100:
            return "Excellent - You're doing great in this area!"
        case 75...89:
            return "Great - Strong performance with room for minor improvements."
        case 60...74:
            return "Good - On the right track, keep it up!"
        case 40...59:
            return "Fair - This area needs some attention."
        default:
            return "Needs work - Focus on improving this component."
        }
    }
}

// MARK: - Preview

#Preview("Budget Compliance - Excellent") {
    VStack(spacing: 16) {
        HealthBreakdownRow(
            icon: "chart.pie.fill",
            title: "Budget Compliance",
            score: 92,
            description: "Measures how well you're staying within your budget across all categories. Higher scores indicate better budget adherence.",
            isExpanded: false,
            onTap: {}
        )

        HealthBreakdownRow(
            icon: "chart.pie.fill",
            title: "Budget Compliance",
            score: 92,
            description: "Measures how well you're staying within your budget across all categories. Higher scores indicate better budget adherence.",
            isExpanded: true,
            onTap: {}
        )
    }
    .padding()
    .background(Color(.systemBackground))
}

#Preview("All Components") {
    VStack(spacing: 0) {
        HealthBreakdownRow(
            icon: "chart.pie.fill",
            title: "Budget Compliance",
            score: 85,
            description: "How well you're staying within budget.",
            isExpanded: false,
            onTap: {}
        )

        Divider().padding(.leading, 48)

        HealthBreakdownRow(
            icon: "banknote.fill",
            title: "Savings Rate",
            score: 65,
            description: "Percentage of income you're saving.",
            isExpanded: false,
            onTap: {}
        )

        Divider().padding(.leading, 48)

        HealthBreakdownRow(
            icon: "chart.line.uptrend.xyaxis",
            title: "Spending Consistency",
            score: 70,
            description: "How consistent your spending patterns are.",
            isExpanded: false,
            onTap: {}
        )

        Divider().padding(.leading, 48)

        HealthBreakdownRow(
            icon: "dollarsign.circle.fill",
            title: "Income Stability",
            score: 80,
            description: "Consistency of your income over time.",
            isExpanded: false,
            onTap: {}
        )
    }
    .background(Color(.systemBackground))
    .cornerRadius(12)
    .shadow(radius: 4)
    .padding()
}
