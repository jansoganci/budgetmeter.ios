//
//  NotificationToggleRow.swift
//  BudgetMeter
//
//  Phase 1C: Smart Notifications UI - Reusable Component
//  Created by BudgetMeter Team on 17.09.2025.
//

import SwiftUI

/// Reusable toggle row for notification settings
struct NotificationToggleRow: View {

    // MARK: - Properties

    let icon: String
    let title: String
    let description: String
    @Binding var isOn: Bool
    let isPremium: Bool
    let isLocked: Bool
    let onTap: () -> Void

    // MARK: - Initialization

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

    // MARK: - Body

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(isLocked ? .gray : .blue)
                .frame(width: 32, height: 32)
                .accessibilityHidden(true)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(isLocked ? .secondary : .primary)

                    if isPremium {
                        premiumBadge
                    }
                }

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Toggle
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .disabled(isLocked)
                .onChange(of: isOn) { _ in
                    if isLocked {
                        onTap()
                    }
                }
        }
        .padding(.vertical, 8)
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

    // MARK: - Premium Badge

    private var premiumBadge: some View {
        Text("PREMIUM")
            .font(.system(size: 9, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(4)
    }
}

// MARK: - Preview

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
            onTap: {
                print("Premium required!")
            }
        )
    }
    .padding()
}
