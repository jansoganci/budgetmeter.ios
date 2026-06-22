//
//  NotificationPermissionBanner.swift
//  BudgetMeter
//
//  Phase 1C: Smart Notifications UI - Component
//  Created by BudgetMeter Team on 17.09.2025.
//

import SwiftUI

/// Banner shown when notification permissions are denied
struct NotificationPermissionBanner: View {

    // MARK: - Properties

    let onOpenSettings: () -> Void
    @Environment(\.themeAccent) private var themeAccent

    // MARK: - Body

    var body: some View {
        VStack(spacing: Spacing.md) {
            // Icon and title
            HStack(spacing: Spacing.md) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title2)
                    .foregroundColor(.financialCaution)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("notifications.permission.disabled_title".localized(defaultValue: "Notifications Disabled"))
                        .sectionTitleStyle()

                    Text("notifications.permission.disabled_message".localized(defaultValue: "Enable in Settings to receive financial alerts"))
                        .captionStyle()
                }

                Spacer()
            }

            // Action button
            Button {
                onOpenSettings()
            } label: {
                HStack {
                    Image(systemName: "gearshape.fill")
                        .font(.body)

                    Text("notifications.permission.open_settings".localized(defaultValue: "Open Settings"))
                        .bodyStyle(color: .white)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(minHeight: TouchTarget.minimum)
                .background(themeAccent)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.button, style: .continuous))
            }
            .accessibilityLabel("Open iOS Settings")
            .accessibilityHint("Opens the Settings app to enable notifications for BudgetMeter")
        }
        .surfaceCard(borderColor: Color.financialCaution.opacity(0.35))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous)
                .stroke(Color.financialCaution.opacity(0.3), lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Notification permission alert")
        .accessibilityHint("Notifications are currently disabled for BudgetMeter")
    }
}

// MARK: - Preview

#Preview {
    NotificationPermissionBanner {
        print("Open Settings tapped")
    }
    .padding()
}
