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

    // MARK: - Body

    var body: some View {
        VStack(spacing: 12) {
            // Icon and title
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title2)
                    .foregroundColor(.orange)

                VStack(alignment: .leading, spacing: 4) {
                    Text("notifications.permission.disabled_title".localized(defaultValue: "Notifications Disabled"))
                        .font(.headline)
                        .fontWeight(.semibold)

                    Text("notifications.permission.disabled_message".localized(defaultValue: "Enable in Settings to receive financial alerts"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            // Action button
            Button {
                onOpenSettings()
            } label: {
                HStack {
                    Image(systemName: "gearshape.fill")
                        .font(.subheadline)

                    Text("notifications.permission.open_settings".localized(defaultValue: "Open Settings"))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.blue)
                .cornerRadius(10)
            }
            .accessibilityLabel("Open iOS Settings")
            .accessibilityHint("Opens the Settings app to enable notifications for BudgetMeter")
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
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
