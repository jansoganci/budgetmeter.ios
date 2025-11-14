//
//  HealthTipCard.swift
//  BudgetMeter
//
//  Phase 1D: Financial Health Details - Health Tip Card Component
//  Created by BudgetMeter Team on 17.09.2025.
//

import SwiftUI

/// Health tip card with priority badge and description
struct HealthTipCard: View {

    // MARK: - Properties

    let tip: HealthTip
    let isPremium: Bool

    @State private var showCard: Bool = false

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Impact badge and title
            HStack(spacing: 8) {
                // Impact icon
                Image(systemName: priorityIcon)
                    .font(.subheadline)
                    .foregroundColor(priorityColor)
                    .accessibilityHidden(true)

                // Impact text
                Text(tip.impact)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(priorityColor)

                Spacer()

                // Premium badge if applicable
                if !isPremium {
                    premiumBadge
                }
            }

            // Title
            Text(tip.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            // Description
            Text(tip.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            // Impact tag
            HStack(spacing: 4) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.caption2)
                    .foregroundColor(.secondary.opacity(0.7))

                Text(tip.impact)
                    .font(.caption2)
                    .foregroundColor(.secondary.opacity(0.7))
            }
            .padding(.top, 4)
        }
        .padding(16)
        .background(backgroundColor)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(priorityColor.opacity(0.3), lineWidth: 1.5)
        )
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .opacity(showCard ? 1 : 0)
        .scaleEffect(showCard ? 1 : 0.95)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.1)) {
                showCard = true
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Tip: \(tip.title), Impact: \(tip.impact)")
        .accessibilityValue(tip.description)
        .accessibilityHint(isPremium ? "" : "Premium feature. Unlock to see all tips")
    }

    // MARK: - Priority Icon

    private var priorityIcon: String {
        if tip.color == .red {
            return "exclamationmark.triangle.fill"
        } else if tip.color == .orange {
            return "exclamationmark.circle.fill"
        } else {
            return "info.circle.fill"
        }
    }

    // MARK: - Priority Color

    private var priorityColor: Color {
        return tip.color
    }

    // MARK: - Background Color

    private var backgroundColor: Color {
        return tip.color.opacity(0.05)
    }

    // MARK: - Premium Badge

    private var premiumBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "crown.fill")
                .font(.caption2)
                .foregroundColor(Color(hex: "FFD700"))

            Text("PREMIUM")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(Color(hex: "FFD700"))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(hex: "FFD700").opacity(0.15))
        .cornerRadius(6)
        .accessibilityLabel("Premium feature")
    }
}

// MARK: - Preview

#Preview("High Priority Tip") {
    HealthTipCard(
        tip: HealthTip(
            icon: "💸",
            title: "Increase Your Savings Rate",
            description: "You're currently saving only 5% of your income. Aim to increase this to at least 15% to build better financial security. Start by identifying areas where you can cut back on discretionary spending.",
            impact: "+10 points",
            color: .red
        ),
        isPremium: true
    )
    .padding()
}

#Preview("Medium Priority Tip") {
    HealthTipCard(
        tip: HealthTip(
            icon: "📊",
            title: "Review Your Spending Patterns",
            description: "Your spending varies significantly week to week. Creating a consistent spending routine can help you better manage your budget and reduce financial stress.",
            impact: "+5 points",
            color: .orange
        ),
        isPremium: true
    )
    .padding()
}

#Preview("Low Priority Tip - Locked") {
    HealthTipCard(
        tip: HealthTip(
            icon: "🎯",
            title: "Optimize Your Budget Categories",
            description: "Consider reviewing and adjusting your budget categories to better match your actual spending patterns. This can improve your overall budget compliance.",
            impact: "+3 points",
            color: .blue
        ),
        isPremium: false
    )
    .padding()
}

#Preview("All Tips") {
    ScrollView {
        VStack(spacing: 16) {
            HealthTipCard(
                tip: HealthTip(
                    icon: "💸",
                    title: "Increase Your Savings Rate",
                    description: "You're currently saving only 5% of your income. Try to reach 15%.",
                    impact: "+10 points",
                    color: .red
                ),
                isPremium: true
            )

            HealthTipCard(
                tip: HealthTip(
                    icon: "📊",
                    title: "Review Your Spending Patterns",
                    description: "Your spending varies significantly week to week.",
                    impact: "+5 points",
                    color: .orange
                ),
                isPremium: true
            )

            HealthTipCard(
                tip: HealthTip(
                    icon: "🎯",
                    title: "Optimize Your Budget Categories",
                    description: "Consider adjusting your budget categories.",
                    impact: "+3 points",
                    color: .blue
                ),
                isPremium: false
            )
        }
        .padding()
    }
}
