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
            // Priority badge and title
            HStack(spacing: 8) {
                // Priority icon
                Image(systemName: priorityIcon)
                    .font(.subheadline)
                    .foregroundColor(priorityColor)
                    .accessibilityHidden(true)

                // Priority text
                Text(tip.priority.rawValue.uppercased())
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

            // Category tag if available
            if let category = tip.category {
                HStack(spacing: 4) {
                    Image(systemName: "tag.fill")
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.7))

                    Text(category)
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.7))
                }
                .padding(.top, 4)
            }
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
        .accessibilityLabel("\(tip.priority.rawValue.capitalized) priority tip: \(tip.title)")
        .accessibilityValue(tip.description)
        .accessibilityHint(isPremium ? "" : "Premium feature. Unlock to see all tips")
    }

    // MARK: - Priority Icon

    private var priorityIcon: String {
        switch tip.priority {
        case .high:
            return "exclamationmark.triangle.fill"
        case .medium:
            return "exclamationmark.circle.fill"
        case .low:
            return "info.circle.fill"
        }
    }

    // MARK: - Priority Color

    private var priorityColor: Color {
        switch tip.priority {
        case .high:
            return .red
        case .medium:
            return .orange
        case .low:
            return .blue
        }
    }

    // MARK: - Background Color

    private var backgroundColor: Color {
        switch tip.priority {
        case .high:
            return Color.red.opacity(0.05)
        case .medium:
            return Color.orange.opacity(0.05)
        case .low:
            return Color.blue.opacity(0.05)
        }
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
            title: "Increase Your Savings Rate",
            description: "You're currently saving only 5% of your income. Aim to increase this to at least 15% to build better financial security. Start by identifying areas where you can cut back on discretionary spending.",
            priority: .high,
            category: "Savings"
        ),
        isPremium: true
    )
    .padding()
}

#Preview("Medium Priority Tip") {
    HealthTipCard(
        tip: HealthTip(
            title: "Review Your Spending Patterns",
            description: "Your spending varies significantly week to week. Creating a consistent spending routine can help you better manage your budget and reduce financial stress.",
            priority: .medium,
            category: "Budgeting"
        ),
        isPremium: true
    )
    .padding()
}

#Preview("Low Priority Tip - Locked") {
    HealthTipCard(
        tip: HealthTip(
            title: "Optimize Your Budget Categories",
            description: "Consider reviewing and adjusting your budget categories to better match your actual spending patterns. This can improve your overall budget compliance.",
            priority: .low,
            category: "Optimization"
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
                    title: "Increase Your Savings Rate",
                    description: "You're currently saving only 5% of your income. Try to reach 15%.",
                    priority: .high,
                    category: "Savings"
                ),
                isPremium: true
            )

            HealthTipCard(
                tip: HealthTip(
                    title: "Review Your Spending Patterns",
                    description: "Your spending varies significantly week to week.",
                    priority: .medium,
                    category: "Budgeting"
                ),
                isPremium: true
            )

            HealthTipCard(
                tip: HealthTip(
                    title: "Optimize Your Budget Categories",
                    description: "Consider adjusting your budget categories.",
                    priority: .low,
                    category: "Optimization"
                ),
                isPremium: false
            )
        }
        .padding()
    }
}
