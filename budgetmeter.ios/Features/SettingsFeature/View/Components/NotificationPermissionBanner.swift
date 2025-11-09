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
                    Text("Notifications Disabled")
                        .font(.headline)
                        .fontWeight(.semibold)

                    Text("Enable in Settings to receive financial alerts")
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

                    Text("Open Settings")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.blue)
                .cornerRadius(10)
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Notifications are disabled. Tap to open Settings and enable notifications.")
    }
}

// MARK: - Preview

#Preview {
    NotificationPermissionBanner {
        print("Open Settings tapped")
    }
    .padding()
}
