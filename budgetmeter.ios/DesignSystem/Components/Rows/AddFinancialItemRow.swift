//
//  AddFinancialItemRow.swift
//  BudgetMeter
//
//  Design System v2.1 - Add Financial Item Row
//  The + row inside collapsible sections for adding new categories
//

import SwiftUI

/// Row for adding a new financial category
/// Appears at the bottom of each collapsible section
struct AddFinancialItemRow: View {

    // MARK: - Properties

    let frequency: String  // "daily", "monthly", "yearly"
    let type: String       // "income" or "expense"
    let onTap: () -> Void

    // MARK: - Environment

    @Environment(\.sizeCategory) var sizeCategory
    @StateObject private var premiumManager = PremiumManager.shared

    // MARK: - State

    @State private var showingPaywall = false

    // MARK: - Computed Properties

    private var buttonText: String {
        let frequencyText = frequency.capitalized
        let typeText = type == "income"
            ? String(localized: "financial.add.income", defaultValue: "income")
            : String(localized: "financial.add.expense", defaultValue: "expense")
        return String(localized: "financial.add.button", defaultValue: "Add \(frequencyText.lowercased()) \(typeText)")
    }

    private var accessibilityLabel: String {
        if premiumManager.hasAccess(to: BudgetMeterCapability.customCategories) {
            return buttonText
        } else {
            return "\(buttonText). Premium feature. Double tap to unlock."
        }
    }

    // MARK: - Body

    var body: some View {
        Button(action: handleTap) {
            HStack(spacing: Spacing.md) {
                // Icon
                Image(systemName: premiumManager.hasAccess(to: BudgetMeterCapability.customCategories) ? "plus.circle.fill" : "crown.fill")
                    .font(.system(size: 20 * sizeCategory.scaleFactor, weight: .medium))
                    .foregroundColor(.brandProgress)
                    .frame(width: 32, height: 32)

                // Text
                Text(buttonText)
                    .bodyStyle(color: .brandProgress)

                Spacer()

                if !premiumManager.hasAccess(to: BudgetMeterCapability.customCategories) {
                    Text(String(localized: "premium.badge", defaultValue: "Premium"))
                        .badgeStyle(color: .white)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xs)
                        .background(Color.brandProgress)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.tiny, style: .continuous))
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .frame(minHeight: 56)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .sheet(isPresented: $showingPaywall) {
            PremiumPaywallView(
                feature: .customCategories,
                onDismiss: { showingPaywall = false },
                onPurchase: { showingPaywall = false },
                onRestore: { showingPaywall = false }
            )
        }
    }

    // MARK: - Actions

    private func handleTap() {
        Haptics.light()
        if premiumManager.hasAccess(to: BudgetMeterCapability.customCategories) {
            onTap()
        } else {
            showingPaywall = true
        }
    }
}

// MARK: - Preview

#Preview("Premium User - Income") {
    VStack(spacing: 0) {
        AddFinancialItemRow(
            frequency: "monthly",
            type: "income",
            onTap: { print("Add monthly income") }
        )

        Divider().padding(.leading, 56)

        AddFinancialItemRow(
            frequency: "daily",
            type: "income",
            onTap: { print("Add daily income") }
        )

        Divider().padding(.leading, 56)

        AddFinancialItemRow(
            frequency: "yearly",
            type: "income",
            onTap: { print("Add yearly income") }
        )
    }
    .background(Color.cardBackground)
    .cornerRadius(CornerRadius.card)
    .padding()
    .background(Color.appBackground)
}

#Preview("Premium User - Expense") {
    VStack(spacing: 0) {
        AddFinancialItemRow(
            frequency: "monthly",
            type: "expense",
            onTap: { print("Add monthly expense") }
        )

        Divider().padding(.leading, 56)

        AddFinancialItemRow(
            frequency: "daily",
            type: "expense",
            onTap: { print("Add daily expense") }
        )
    }
    .background(Color.cardBackground)
    .cornerRadius(CornerRadius.card)
    .padding()
    .background(Color.appBackground)
}

#Preview("Dark Mode") {
    VStack(spacing: 0) {
        AddFinancialItemRow(
            frequency: "monthly",
            type: "income",
            onTap: { }
        )

        Divider().padding(.leading, 56)

        AddFinancialItemRow(
            frequency: "yearly",
            type: "expense",
            onTap: { }
        )
    }
    .background(Color.cardBackground)
    .cornerRadius(CornerRadius.card)
    .padding()
    .background(Color.appBackground)
    .preferredColorScheme(.dark)
}
