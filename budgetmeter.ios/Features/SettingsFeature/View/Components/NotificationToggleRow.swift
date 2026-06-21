//
//  NotificationToggleRow.swift
//  BudgetMeter
//
//  Reusable toggle row for notification settings — v2 tokens.
//

import SwiftUI

/// Reusable toggle row for notification settings
struct NotificationToggleRow: View {

    let icon: String
    let title: String
    let description: String
    @Binding var isOn: Bool
    let isPremium: Bool
    let isLocked: Bool
    let onTap: () -> Void

    init(
        icon: String,
        title: String,
        description: String,
        isOn: Binding<Bool>,
        isPremium: Bool = false,
        isLocked: Bool = false,
        onTap: @escaping () -> Void = {}
    ) {
        self.icon = icon
        self.title = title
        self.description = description
        self._isOn = isOn
        self.isPremium = isPremium
        self.isLocked = isLocked
        self.onTap = onTap
    }

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.body.weight(.medium))
                .foregroundColor(isLocked ? .financialNeutral : .accentPrimary)
                .frame(width: 32, height: 32)
                .background((isLocked ? Color.financialNeutral : Color.accentPrimary).opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack(spacing: Spacing.sm) {
                    Text(title)
                        .bodyStyle(color: isLocked ? .textSecondary : .textPrimary)

                    if isPremium {
                        PremiumBadge(locked: isLocked)
                    }
                }

                Text(description)
                    .captionStyle()
            }

            Spacer(minLength: Spacing.sm)

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .disabled(isLocked)
                .onChange(of: isOn) { _, _ in
                    if isLocked {
                        onTap()
                    }
                }
        }
        .padding(.vertical, Spacing.sm)
        .padding(.horizontal, Spacing.md)
        .frame(minHeight: LayoutSpacing.rowHeight)
        .contentShape(Rectangle())
        .onTapGesture {
            if isLocked {
                onTap()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(description)")
        .accessibilityValue(isOn ? "enabled" : "disabled")
        .accessibilityHint(isLocked ? "Premium feature. Double tap to view upgrade options" : "Double tap to \(isOn ? "disable" : "enable") \(title.lowercased())")
        .accessibilityAddTraits(isLocked ? [.isButton] : [])
        .accessibilityRemoveTraits(isLocked ? [] : [.isButton])
    }
}

#Preview {
    VStack(spacing: 16) {
        NotificationToggleRow(
            icon: "chart.bar.fill",
            title: "Weekly Summary",
            description: "Every Sunday at 6:00 PM",
            isOn: .constant(true)
        )

        NotificationToggleRow(
            icon: "star.fill",
            title: "Daily Encouragement",
            description: "Every day at 9:00 AM",
            isOn: .constant(false),
            isPremium: true,
            isLocked: true,
            onTap: {}
        )
    }
    .padding()
    .background(Color.appBackground)
}
