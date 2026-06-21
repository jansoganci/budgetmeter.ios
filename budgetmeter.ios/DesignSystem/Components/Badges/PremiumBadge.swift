//
//  PremiumBadge.swift
//  BudgetMeter
//
//  Handoff premium indicator — no StoreKit or entitlement logic.
//

import SwiftUI

enum PremiumBadgeVariant {
    case active
    case locked
}

/// Subtle premium indicator. Caller supplies locked/active state.
struct PremiumBadge: View {

    let variant: PremiumBadgeVariant

    init(locked: Bool) {
        self.variant = locked ? .locked : .active
    }

    init(variant: PremiumBadgeVariant) {
        self.variant = variant
    }

    private var label: String {
        switch variant {
        case .active:
            return String(localized: "premium.badge.active", defaultValue: "Premium", table: "UI")
        case .locked:
            return String(localized: "premium.badge.locked", defaultValue: "Premium required", table: "UI")
        }
    }

    private var iconName: String {
        switch variant {
        case .active: return "star.fill"
        case .locked: return "lock.fill"
        }
    }

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: iconName)
                .font(.caption2.weight(.semibold))
                .accessibilityHidden(true)

            Text(label)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
        }
        .foregroundColor(variant == .locked ? .financialCaution : .accentPrimary)
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(Color.accentPrimary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.badge, style: .continuous))
        .accessibilityLabel(label)
    }
}

#Preview {
    HStack(spacing: Spacing.md) {
        PremiumBadge(variant: .active)
        PremiumBadge(locked: true)
    }
    .padding()
    .background(Color.appBackground)
}
