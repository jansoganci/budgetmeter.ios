//
//  SubscriptionsView.swift
//  BudgetMeter
//
//  Created by BudgetMeter Team on 14.11.2025.
//

import SwiftUI

/// Main subscriptions list screen
struct SubscriptionsView: View {

    // MARK: - Properties

    @StateObject private var viewModel = SubscriptionsViewModel()
    @State private var showingAddSubscription = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // Summary card
                    summaryCard

                    // Renewing soon section
                    if !viewModel.renewingSoon.isEmpty {
                        renewingSoonSection
                    }

                    // Sort picker
                    sortPicker

                    // All subscriptions list
                    allSubscriptionsSection
                }
                .padding(Spacing.lg)
            }
            .navigationTitle("subscriptions.title".localized(defaultValue: "Subscriptions"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddSubscription = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(.brandProgress)
                    }
                }
            }
            .sheet(isPresented: $showingAddSubscription) {
                // TODO: Add SubscriptionInputView here
                Text("Add Subscription Form")
            }
            .onAppear {
                viewModel.loadSubscriptions()
            }
        }
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(viewModel.summaryTitle)
                .font(.subheadline)
                .foregroundColor(.textSecondary)

            HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
                Text(viewModel.formatAmount(viewModel.totalMonthlyCost))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)

                Text("/month")
                    .font(.body)
                    .foregroundColor(.textSecondary)
            }

            Text(viewModel.formatAmount(viewModel.totalYearlyCost) + "/year")
                .font(.body)
                .foregroundColor(.textSecondary)

            Divider()
                .padding(.vertical, Spacing.xs)

            Text("\(viewModel.activeCount) active subscription\(viewModel.activeCount == 1 ? "" : "s")")
                .font(.caption)
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.lg)
        .background(Color.cardBackground)
        .cornerRadius(CornerRadius.card)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    // MARK: - Renewing Soon Section

    private var renewingSoonSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.caption)

                Text(viewModel.renewingSoonTitle)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
            }

            VStack(spacing: Spacing.sm) {
                ForEach(viewModel.renewingSoon, id: \.id) { subscription in
                    RenewingSoonRow(subscription: subscription, viewModel: viewModel)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.lg)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(CornerRadius.card)
    }

    // MARK: - Sort Picker

    private var sortPicker: some View {
        HStack {
            Text("subscriptions.sort_by".localized(defaultValue: "Sort by:"))
                .font(.subheadline)
                .foregroundColor(.textSecondary)

            Picker("Sort", selection: $viewModel.sortOption) {
                ForEach(SubscriptionsViewModel.SortOption.allCases, id: \.self) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    // MARK: - All Subscriptions Section

    private var allSubscriptionsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(viewModel.allSubscriptionsTitle)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.textPrimary)

            if viewModel.sortedSubscriptions.isEmpty {
                emptyState
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.sortedSubscriptions.enumerated()), id: \.element.id) { index, subscription in
                        SubscriptionRow(subscription: subscription, viewModel: viewModel)
                            .background(Color.cardBackground)

                        if index < viewModel.sortedSubscriptions.count - 1 {
                            Divider()
                                .padding(.leading, 56)
                        }
                    }
                }
                .background(Color.cardBackground)
                .cornerRadius(CornerRadius.card)
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "creditcard")
                .font(.system(size: 64))
                .foregroundColor(.brandProgress.opacity(0.3))

            VStack(spacing: Spacing.sm) {
                Text("subscriptions.empty.title".localized(defaultValue: "No Subscriptions Yet"))
                    .font(.headline)
                    .foregroundColor(.textPrimary)

                Text("subscriptions.empty.subtitle".localized(defaultValue: "Tap + to add your first subscription"))
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.xxl)
        .background(Color.cardBackground)
        .cornerRadius(CornerRadius.card)
    }
}

// MARK: - Renewing Soon Row

struct RenewingSoonRow: View {
    let subscription: Subscription
    let viewModel: SubscriptionsViewModel

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Icon placeholder
            Text(String(subscription.name?.prefix(1).uppercased() ?? "?"))
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(Color.brandProgress)
                .cornerRadius(CornerRadius.small)

            VStack(alignment: .leading, spacing: 4) {
                Text(subscription.name ?? "Unknown")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)

                Text(viewModel.renewalText(subscription))
                    .font(.caption)
                    .foregroundColor(.orange)
            }

            Spacer()

            Text(viewModel.formatAmount(subscription.amount))
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(.textPrimary)

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.textSecondary)
        }
        .padding(Spacing.md)
        .background(Color.cardBackground)
        .cornerRadius(CornerRadius.small)
    }
}

// MARK: - Subscription Row

struct SubscriptionRow: View {
    let subscription: Subscription
    let viewModel: SubscriptionsViewModel

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Icon placeholder (first letter of name)
            Text(String(subscription.name?.prefix(1).uppercased() ?? "?"))
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(Color.brandProgress)
                .cornerRadius(CornerRadius.small)

            VStack(alignment: .leading, spacing: 4) {
                Text(subscription.name ?? "Unknown")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)

                HStack(spacing: 4) {
                    Text(viewModel.billingCycleText(subscription))
                        .font(.caption)
                        .foregroundColor(.textSecondary)

                    Text("•")
                        .font(.caption)
                        .foregroundColor(.textSecondary)

                    Text("Next: " + viewModel.formatDate(subscription.nextRenewalDate ?? Date()))
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(viewModel.formatAmount(subscription.amount))
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)

                if subscription.isPaused {
                    Text("Paused")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.textSecondary)
        }
        .padding(Spacing.md)
        .contentShape(Rectangle())
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                viewModel.deleteSubscription(subscription)
            } label: {
                Label("Delete", systemImage: "trash")
            }

            Button {
                if subscription.isPaused {
                    viewModel.resumeSubscription(subscription)
                } else {
                    viewModel.pauseSubscription(subscription)
                }
            } label: {
                Label(subscription.isPaused ? "Resume" : "Pause", systemImage: subscription.isPaused ? "play.fill" : "pause.fill")
            }
            .tint(.orange)
        }
    }
}

// MARK: - Preview

#Preview {
    SubscriptionsView()
}
