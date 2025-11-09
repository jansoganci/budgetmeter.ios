//
//  NotificationSettingsView.swift
//  BudgetMeter
//
//  Phase 1C: Smart Notifications UI - Main View
//  Created by BudgetMeter Team on 17.09.2025.
//

import SwiftUI
import UserNotifications

/// Main notification settings screen
struct NotificationSettingsView: View {

    // MARK: - Properties

    @StateObject private var viewModel = NotificationSettingsViewModel()
    @State private var showWeeklyTimePicker = false
    @State private var showDailyTimePicker = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Permission banner (if denied)
                    if viewModel.permissionStatus == .denied {
                        permissionBanner
                    }

                    // Notification types section
                    notificationTypesSection

                    // Test notification button
                    testNotificationSection

                    // Info section
                    infoSection
                }
                .padding()
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $viewModel.showPaywall) {
                PremiumPaywallView(
                    feature: .advancedNotifications,
                    onDismiss: {
                        viewModel.dismissPaywall()
                    }
                )
            }
            .onAppear {
                viewModel.checkPermissionStatus()
            }
        }
    }

    // MARK: - Permission Banner

    private var permissionBanner: some View {
        NotificationPermissionBanner {
            viewModel.openSystemSettings()
        }
    }

    // MARK: - Notification Types Section

    private var notificationTypesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("NOTIFICATION TYPES")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            VStack(spacing: 0) {
                // Weekly Summary
                VStack(spacing: 0) {
                    NotificationToggleRow(
                        icon: "chart.bar.fill",
                        title: "Weekly Summary",
                        description: weeklyDescription,
                        isOn: $viewModel.weeklyEnabled,
                        onTap: {
                            viewModel.toggleWeekly(!viewModel.weeklyEnabled)
                        }
                    )
                    .onChange(of: viewModel.weeklyEnabled) { newValue in
                        viewModel.toggleWeekly(newValue)
                    }
                    .onTapGesture {
                        if viewModel.weeklyEnabled {
                            withAnimation {
                                showWeeklyTimePicker.toggle()
                            }
                        }
                    }

                    if showWeeklyTimePicker && viewModel.weeklyEnabled {
                        weeklyTimePicker
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }

                Divider()
                    .padding(.leading, 44)

                // Milestone Alerts
                NotificationToggleRow(
                    icon: "star.fill",
                    title: "Milestone Alerts",
                    description: "Celebrate achievements and positive streaks",
                    isOn: $viewModel.milestonesEnabled,
                    onTap: {
                        viewModel.toggleMilestones(!viewModel.milestonesEnabled)
                    }
                )
                .onChange(of: viewModel.milestonesEnabled) { newValue in
                    viewModel.toggleMilestones(newValue)
                }

                Divider()
                    .padding(.leading, 44)

                // Spending Alerts
                NotificationToggleRow(
                    icon: "exclamationmark.triangle.fill",
                    title: "Spending Alerts",
                    description: "Get notified when spending increases >20%",
                    isOn: $viewModel.spendingEnabled,
                    onTap: {
                        viewModel.toggleSpending(!viewModel.spendingEnabled)
                    }
                )
                .onChange(of: viewModel.spendingEnabled) { newValue in
                    viewModel.toggleSpending(newValue)
                }

                Divider()
                    .padding(.leading, 44)

                // Daily Encouragement (Premium)
                VStack(spacing: 0) {
                    NotificationToggleRow(
                        icon: "sun.max.fill",
                        title: "Daily Encouragement",
                        description: dailyDescription,
                        isOn: $viewModel.dailyEnabled,
                        isPremium: true,
                        isLocked: !viewModel.isPremium,
                        onTap: {
                            if !viewModel.isPremium {
                                viewModel.toggleDaily(true)
                            }
                        }
                    )
                    .onChange(of: viewModel.dailyEnabled) { newValue in
                        viewModel.toggleDaily(newValue)
                    }
                    .onTapGesture {
                        if viewModel.dailyEnabled && viewModel.isPremium {
                            withAnimation {
                                showDailyTimePicker.toggle()
                            }
                        }
                    }

                    if showDailyTimePicker && viewModel.dailyEnabled && viewModel.isPremium {
                        dailyTimePicker
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }

    // MARK: - Time Pickers

    private var weeklyTimePicker: some View {
        VStack(spacing: 12) {
            DatePicker(
                "Weekly Time",
                selection: $viewModel.weeklyTime,
                displayedComponents: [.hourAndMinute]
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .onChange(of: viewModel.weeklyTime) { newTime in
                viewModel.updateWeeklyTime(newTime)
            }

            Text("Notification will be sent every Sunday at this time")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    private var dailyTimePicker: some View {
        VStack(spacing: 12) {
            DatePicker(
                "Daily Time",
                selection: $viewModel.dailyTime,
                displayedComponents: [.hourAndMinute]
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .onChange(of: viewModel.dailyTime) { newTime in
                viewModel.updateDailyTime(newTime)
            }

            Text("Notification will be sent every day at this time")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    // MARK: - Test Notification Section

    private var testNotificationSection: some View {
        VStack(spacing: 12) {
            Button {
                viewModel.sendTestNotification()
            } label: {
                HStack {
                    Image(systemName: "paperplane.fill")
                        .font(.subheadline)

                    Text("Send Test Notification")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.blue)
                .cornerRadius(10)
            }
            .disabled(viewModel.permissionStatus != .authorized)

            if viewModel.permissionStatus != .authorized {
                Text("Enable notifications to send test")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Info Section

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("HOW IT WORKS")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 12) {
                infoRow(
                    icon: "chart.bar.fill",
                    title: "Weekly Summary",
                    description: "Get a comprehensive overview of your financial progress every Sunday evening."
                )

                infoRow(
                    icon: "star.fill",
                    title: "Milestone Alerts",
                    description: "Celebrate positive spending streaks and goal achievements as they happen."
                )

                infoRow(
                    icon: "exclamationmark.triangle.fill",
                    title: "Spending Alerts",
                    description: "Receive early warnings when your spending increases significantly."
                )

                infoRow(
                    icon: "sun.max.fill",
                    title: "Daily Encouragement",
                    description: "Start each day with personalized financial tips and motivation. (Premium)"
                )
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }

    private func infoRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Computed Properties

    private var weeklyDescription: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let timeString = formatter.string(from: viewModel.weeklyTime)
        return "Every Sunday at \(timeString)"
    }

    private var dailyDescription: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let timeString = formatter.string(from: viewModel.dailyTime)
        return "Every day at \(timeString)"
    }
}

// MARK: - Preview

#Preview {
    NotificationSettingsView()
}
