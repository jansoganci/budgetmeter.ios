//
//  SubscriptionRowView.swift
//  BudgetMeter
//
//  Row component for displaying a subscription in the expense list
//

import SwiftUI

/// Row view for displaying a subscription item
struct SubscriptionRowView: View {

    // MARK: - Properties

    let subscription: Subscription
    let currencySymbol: String
    let onTap: () -> Void

    // MARK: - Body

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.md) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.brandExpense.opacity(0.15))
                        .frame(width: 40, height: 40)

                    Image(systemName: iconForSubscription)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.brandExpense)
                }

                // Name and billing cycle
                VStack(alignment: .leading, spacing: 2) {
                    Text(subscription.name ?? "Unknown")
                        .bodyStyle()

                    Text(billingCycleText)
                        .captionStyle()
                }

                Spacer()

                // Amount
                Text(formattedAmount)
                    .metricCompactStyle(color: .brandExpense)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Computed Properties

    private var accessibilityLabel: String {
        let name = subscription.name ?? String(localized: "subscription.unknown", defaultValue: "Unknown")
        return String(
            format: String(localized: "subscription.row.accessibility", defaultValue: "%@, %@, %@", table: "UI"),
            name,
            billingCycleText,
            formattedAmount
        )
    }

    private var formattedAmount: String {
        let amount = subscription.amount
        return CurrencyHelper.format(
            amount: amount,
            currencyCode: RecordCurrencySupport.resolvedDisplayCode(storedCode: subscription.currencyCode)
        )
    }

    private var billingCycleText: String {
        guard let cycle = subscription.billingCycle else { return "Monthly" }
        switch cycle.lowercased() {
        case "monthly": return String(localized: "subscription.cycle.monthly", defaultValue: "Monthly")
        case "yearly": return String(localized: "subscription.cycle.yearly", defaultValue: "Yearly")
        case "weekly": return String(localized: "subscription.cycle.weekly", defaultValue: "Weekly")
        default: return cycle.capitalized
        }
    }

    private var iconForSubscription: String {
        guard let name = subscription.name?.lowercased() else { return "creditcard" }

        // Common subscription services
        if name.contains("netflix") { return "play.tv" }
        if name.contains("spotify") { return "music.note" }
        if name.contains("apple") || name.contains("icloud") { return "applelogo" }
        if name.contains("youtube") { return "play.rectangle" }
        if name.contains("amazon") || name.contains("prime") { return "shippingbox" }
        if name.contains("disney") { return "sparkles.tv" }
        if name.contains("hbo") || name.contains("max") { return "tv" }
        if name.contains("gym") || name.contains("fitness") { return "figure.walk" }
        if name.contains("cloud") || name.contains("storage") { return "cloud" }
        if name.contains("music") { return "music.note" }
        if name.contains("game") || name.contains("gaming") { return "gamecontroller" }
        if name.contains("news") { return "newspaper" }
        if name.contains("vpn") { return "lock.shield" }

        return "creditcard"
    }
}

/// Row for adding a new subscription
struct AddSubscriptionRow: View {

    let onTap: () -> Void

    var body: some View {
        Button {
            Haptics.light()
            onTap()
        } label: {
            HStack(spacing: Spacing.md) {
                // Plus icon
                ZStack {
                    Circle()
                        .fill(Color.brandExpense.opacity(0.1))
                        .frame(width: 40, height: 40)

                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.brandExpense)
                }

                // Label
                Text(String(localized: "subscription.add", defaultValue: "Add Subscription"))
                    .font(.body)
                    .foregroundColor(.brandExpense)

                Spacer()
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(String(localized: "subscription.add", defaultValue: "Add Subscription"))
        .accessibilityHint(String(localized: "subscription.add.hint", defaultValue: "Double tap to add a new subscription", table: "UI"))
    }
}

// MARK: - Preview

#Preview("Subscription Row") {
    VStack(spacing: 0) {
        // Note: Preview requires mock data
        AddSubscriptionRow {
            print("Add tapped")
        }
    }
    .background(Color.cardBackground)
    .cornerRadius(CornerRadius.card)
    .padding()
}
