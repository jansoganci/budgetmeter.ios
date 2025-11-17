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
    @State private var showTestSuccess = false
    @State private var showTestError = false

    // Haptic feedback generator
    private let hapticFeedback = UIImpactFeedbackGenerator(style: .medium)
    private let successFeedback = UINotificationFeedbackGenerator()

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.xl) {
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
                .padding(Spacing.lg)
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $viewModel.showPaywall) {
                PremiumPaywallView(
                    feature: nil,
                    onDismiss: {
                        viewModel.dismissPaywall()
                    },
                    onPurchase: {
                        Task {
                            // Purchase will be handled by PremiumManager
                            viewModel.dismissPaywall()
                        }
                    },
                    onRestore: {
                        Task {
                            // Restore will be handled by PremiumManager
                            viewModel.dismissPaywall()
                        }
                    }
                )
            }
            .alert("Test Notification Sent!", isPresented: $showTestSuccess) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Check your notifications in a few seconds!")
            }
            .alert("Notification Failed", isPresented: $showTestError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Please enable notifications in Settings to receive alerts.")
            }
            .alert("Error", isPresented: $viewModel.showErrorAlert) {
                Button("OK", role: .cancel) {
                    viewModel.clearError()
                }
            } message: {
                Text(viewModel.errorMessage ?? "An unexpected error occurred")
            }
            .onAppear {
                viewModel.checkPermissionStatus()
                hapticFeedback.prepare()
                successFeedback.prepare()
            }
        }
    }

    // MARK: - Permission Banner

    private var permissionBanner: some View {
        NotificationPermissionBanner {
            hapticFeedback.impactOccurred()
            viewModel.openSystemSettings()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Notifications are currently disabled")
        .accessibilityHint("Double tap to open Settings and enable notifications")
    }

    // MARK: - Notification Types Section

    private var notificationTypesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
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
                        hapticFeedback.impactOccurred()
                        viewModel.toggleWeekly(newValue)
                    }
                    .onTapGesture {
                        if viewModel.weeklyEnabled {
                            hapticFeedback.impactOccurred()
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                showWeeklyTimePicker.toggle()
                            }
                        }
                    }

                    if showWeeklyTimePicker && viewModel.weeklyEnabled {
                        weeklyTimePicker
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.95).combined(with: .opacity),
                                removal: .scale(scale: 0.95).combined(with: .opacity)
                            ))
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
                    hapticFeedback.impactOccurred()
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
                    hapticFeedback.impactOccurred()
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
                                hapticFeedback.impactOccurred()
                                viewModel.toggleDaily(true)
                            }
                        }
                    )
                    .onChange(of: viewModel.dailyEnabled) { newValue in
                        hapticFeedback.impactOccurred()
                        viewModel.toggleDaily(newValue)
                    }
                    .onTapGesture {
                        if viewModel.dailyEnabled && viewModel.isPremium {
                            hapticFeedback.impactOccurred()
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                showDailyTimePicker.toggle()
                            }
                        }
                    }

                    if showDailyTimePicker && viewModel.dailyEnabled && viewModel.isPremium {
                        dailyTimePicker
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.95).combined(with: .opacity),
                                removal: .scale(scale: 0.95).combined(with: .opacity)
                            ))
                    }
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(CornerRadius.card)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }

    // MARK: - Time Pickers

    private var weeklyTimePicker: some View {
        VStack(spacing: Spacing.md) {
            DatePicker(
                "Weekly Time",
                selection: $viewModel.weeklyTime,
                displayedComponents: [.hourAndMinute]
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .onChange(of: viewModel.weeklyTime) { newTime in
                hapticFeedback.impactOccurred()
                viewModel.updateWeeklyTime(newTime)
            }
            .accessibilityLabel("Weekly notification time picker")
            .accessibilityHint("Select the time for weekly summary notifications every Sunday")

            Text("Notification will be sent every Sunday at this time")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(Spacing.lg)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(CornerRadius.small)
        .padding(.horizontal)
        .padding(.bottom, Spacing.sm)
    }

    private var dailyTimePicker: some View {
        VStack(spacing: Spacing.md) {
            DatePicker(
                "Daily Time",
                selection: $viewModel.dailyTime,
                displayedComponents: [.hourAndMinute]
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .onChange(of: viewModel.dailyTime) { newTime in
                hapticFeedback.impactOccurred()
                viewModel.updateDailyTime(newTime)
            }
            .accessibilityLabel("Daily notification time picker")
            .accessibilityHint("Select the time for daily encouragement notifications. Premium feature")

            Text("Notification will be sent every day at this time")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(Spacing.lg)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(CornerRadius.small)
        .padding(.horizontal)
        .padding(.bottom, Spacing.sm)
    }

    // MARK: - Test Notification Section

    private var testNotificationSection: some View {
        VStack(spacing: Spacing.md) {
            Button {
                if viewModel.permissionStatus == .authorized {
                    successFeedback.notificationOccurred(.success)
                    viewModel.sendTestNotification()
                    showTestSuccess = true
                } else {
                    successFeedback.notificationOccurred(.error)
                    showTestError = true
                }
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
                .background(viewModel.permissionStatus == .authorized ? Color.brandProgress : Color.gray)
                .cornerRadius(CornerRadius.button)
            }
            .disabled(viewModel.permissionStatus != .authorized)

            if viewModel.permissionStatus != .authorized {
                Text("Enable notifications to send test")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Test notification button")
        .accessibilityHint(viewModel.permissionStatus == .authorized ? "Send a test notification to verify your settings" : "Notifications are disabled. Enable them first to send a test notification")
    }

    // MARK: - Info Section

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("HOW IT WORKS")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: Spacing.md) {
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
            .padding(Spacing.lg)
            .background(Color(.systemBackground))
            .cornerRadius(CornerRadius.card)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("How notifications work")
    }

    private func infoRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.brandProgress)
                .frame(width: 24)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(description)")
    }

    // MARK: - Computed Properties

    private var weeklyDescription: String {
        let timeString = DateFormattingHelper.shared.formatTime(viewModel.weeklyTime)
        return "Every Sunday at \(timeString)"
    }

    private var dailyDescription: String {
        let timeString = DateFormattingHelper.shared.formatTime(viewModel.dailyTime)
        return "Every day at \(timeString)"
    }
}

// MARK: - Preview

#Preview {
    NotificationSettingsView()
}
