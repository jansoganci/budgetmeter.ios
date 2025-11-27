//
//  EmptyStateRow.swift
//  BudgetMeter
//
//  Design System v2.1 - Empty State Row
//  Friendly prompt when a section has no data
//

import SwiftUI

/// Friendly empty state row for financial sections
/// Shows when all categories in a section have $0 amount
struct EmptyStateRow: View {

    // MARK: - Properties

    let frequency: String  // "daily", "monthly", "yearly"
    let type: String       // "income" or "expense"

    // MARK: - Environment

    @Environment(\.sizeCategory) var sizeCategory

    // MARK: - Computed Properties

    private var message: String {
        let frequencyText = frequencyDisplayText
        if type == "income" {
            switch frequency {
            case "daily":
                return String(localized: "empty.income.daily", defaultValue: "No daily income yet — tap + to add your first!")
            case "monthly":
                return String(localized: "empty.income.monthly", defaultValue: "No monthly income yet — tap + to add your first!")
            case "yearly":
                return String(localized: "empty.income.yearly", defaultValue: "No yearly income yet — tap + to add your first!")
            default:
                return "No \(frequencyText) income yet — tap + to add your first!"
            }
        } else {
            switch frequency {
            case "daily":
                return String(localized: "empty.expense.daily", defaultValue: "No daily expenses tracked — tap + to add!")
            case "monthly":
                return String(localized: "empty.expense.monthly", defaultValue: "No monthly expenses tracked — tap + to add!")
            case "yearly":
                return String(localized: "empty.expense.yearly", defaultValue: "No yearly expenses tracked — tap + to add!")
            default:
                return "No \(frequencyText) expenses tracked — tap + to add!"
            }
        }
    }

    private var frequencyDisplayText: String {
        switch frequency {
        case "daily": return String(localized: "frequency.daily.lowercase", defaultValue: "daily")
        case "monthly": return String(localized: "frequency.monthly.lowercase", defaultValue: "monthly")
        case "yearly": return String(localized: "frequency.yearly.lowercase", defaultValue: "yearly")
        default: return frequency
        }
    }

    private var iconName: String {
        switch frequency {
        case "daily": return "sun.max"
        case "monthly": return "calendar"
        case "yearly": return "calendar.badge.clock"
        default: return "info.circle"
        }
    }

    private var iconColor: Color {
        type == "income" ? .brandPositive.opacity(0.6) : .brandExpense.opacity(0.6)
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Icon
            Image(systemName: iconName)
                .font(.system(size: 20 * sizeCategory.scaleFactor, weight: .medium))
                .foregroundColor(iconColor)
                .frame(width: 32, height: 32)

            // Message
            Text(message)
                .font(.system(size: 14 * sizeCategory.scaleFactor, weight: .regular))
                .foregroundColor(.textSecondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.md)
        .frame(minHeight: 56)
    }
}

// MARK: - Preview

#Preview("Income Empty States") {
    VStack(spacing: Spacing.md) {
        EmptyStateRow(frequency: "daily", type: "income")
        Divider()
        EmptyStateRow(frequency: "monthly", type: "income")
        Divider()
        EmptyStateRow(frequency: "yearly", type: "income")
    }
    .background(Color.cardBackground)
    .cornerRadius(CornerRadius.card)
    .padding()
    .background(Color.appBackground)
}

#Preview("Expense Empty States") {
    VStack(spacing: Spacing.md) {
        EmptyStateRow(frequency: "daily", type: "expense")
        Divider()
        EmptyStateRow(frequency: "monthly", type: "expense")
        Divider()
        EmptyStateRow(frequency: "yearly", type: "expense")
    }
    .background(Color.cardBackground)
    .cornerRadius(CornerRadius.card)
    .padding()
    .background(Color.appBackground)
}

#Preview("Dark Mode") {
    VStack(spacing: Spacing.md) {
        EmptyStateRow(frequency: "daily", type: "income")
        Divider()
        EmptyStateRow(frequency: "monthly", type: "expense")
    }
    .background(Color.cardBackground)
    .cornerRadius(CornerRadius.card)
    .padding()
    .background(Color.appBackground)
    .preferredColorScheme(.dark)
}
