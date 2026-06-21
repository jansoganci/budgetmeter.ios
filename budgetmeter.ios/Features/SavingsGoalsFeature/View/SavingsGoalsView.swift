//
//  SavingsGoalsView.swift
//  BudgetMeter
//
//  Created by BudgetMeter Team on 14.11.2025.
//

import SwiftUI

/// Main savings goals list screen
struct SavingsGoalsView: View {

    // MARK: - Properties

    @StateObject private var viewModel = SavingsGoalsViewModel()
    @State private var showingAddGoal = false
    @State private var goalToEdit: SavingsGoal?
    @State private var goalToView: SavingsGoal?
    @State private var showingPaywall = false
    @StateObject private var premiumManager = PremiumManager.shared

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.xl) {
                        // Active Goals Section
                        if !viewModel.activeGoals.isEmpty {
                            activeGoalsSection
                        }

                        // Completed Goals Section
                        if !viewModel.completedGoals.isEmpty {
                            completedGoalsSection
                        }

                        // Empty State
                        if viewModel.activeGoals.isEmpty && viewModel.completedGoals.isEmpty {
                            emptyState
                        }
                    }
                    .padding(Spacing.lg)
                }
            }
            .navigationTitle(String(localized: "savings.list.title", defaultValue: "Savings Goals", table: "UI"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        if viewModel.canAddAnotherGoal {
                            showingAddGoal = true
                        } else {
                            showingPaywall = true
                        }
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(.brandProgress)
                    }
                    .accessibilityLabel(String(localized: "savings.add_goal", defaultValue: "Add savings goal", table: "UI"))
                    .accessibilityHint(
                        viewModel.canAddAnotherGoal
                            ? String(localized: "savings.add_goal.hint", defaultValue: "Double tap to create a new savings goal", table: "UI")
                            : String(localized: "savings.add_goal.premium_hint", defaultValue: "Premium required for additional goals. Double tap to upgrade.", table: "UI")
                    )
                }
            }
            .sheet(isPresented: $showingAddGoal) {
                SavingsGoalInputView(goal: nil, onSave: {})
            }
            .sheet(isPresented: $showingPaywall) {
                PremiumPaywallView(
                    onDismiss: { showingPaywall = false },
                    onPurchase: { showingPaywall = false },
                    onRestore: { showingPaywall = false }
                )
            }
            .sheet(item: $goalToEdit) { goal in
                // Empty callback - notification observer handles UI update
                SavingsGoalInputView(goal: goal, onSave: {})
            }
            .sheet(item: $goalToView) { goal in
                SavingsGoalDetailView(
                    goal: goal,
                    sharedPaceETAText: viewModel.sharedPaceETAText(for: goal),
                    onUpdate: {}
                )
            }
            .onAppear {
                viewModel.loadGoals()
            }
        }
    }

    // MARK: - Active Goals Section

    private var activeGoalsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(String(localized: "savings.list.active", defaultValue: "Active Goals", table: "UI"))
                .sectionTitleStyle()

            ForEach(viewModel.activeGoals, id: \.id) { goal in
                GoalCard(goal: goal, viewModel: viewModel)
                    .onTapGesture {
                        goalToView = goal
                    }
                    .contextMenu {
                        Button {
                            goalToEdit = goal
                        } label: {
                            Label(String(localized: "common.edit", defaultValue: "Edit", table: "UI"), systemImage: "pencil")
                        }

                        Button(role: .destructive) {
                            viewModel.deleteGoal(goal)
                        } label: {
                            Label(String(localized: "common.delete", defaultValue: "Delete", table: "UI"), systemImage: "trash")
                        }
                    }
            }
        }
    }

    // MARK: - Completed Goals Section

    private var completedGoalsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text(String(localized: "savings.list.completed", defaultValue: "Completed", table: "UI"))
                    .sectionTitleStyle()

                Text("(\(viewModel.completedGoals.count))")
                    .captionStyle()
            }

            ForEach(viewModel.completedGoals, id: \.id) { goal in
                CompletedGoalCard(goal: goal, viewModel: viewModel)
                    .onTapGesture {
                        goalToView = goal
                    }
                    .contextMenu {
                        Button {
                            viewModel.archiveGoal(goal)
                        } label: {
                            Label(String(localized: "common.archive", defaultValue: "Archive", table: "UI"), systemImage: "archivebox")
                        }

                        Button(role: .destructive) {
                            viewModel.deleteGoal(goal)
                        } label: {
                            Label(String(localized: "common.delete", defaultValue: "Delete", table: "UI"), systemImage: "trash")
                        }
                    }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "target")
                .font(.system(size: 64))
                .foregroundColor(.brandProgress.opacity(0.3))

            VStack(spacing: Spacing.sm) {
                Text(String(localized: "savings.empty.title", defaultValue: "No Savings Goals Yet", table: "UI"))
                    .sectionTitleStyle()

                Text(String(localized: "savings.empty.subtitle", defaultValue: "Tap + to create your first savings goal", table: "UI"))
                    .captionStyle()
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.xxl)
        .glassSurface()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            String(
                format: String(localized: "savings.empty.accessibility", defaultValue: "%@. %@", table: "UI"),
                String(localized: "savings.empty.title", defaultValue: "No Savings Goals Yet", table: "UI"),
                String(localized: "savings.empty.subtitle", defaultValue: "Tap + to create your first savings goal", table: "UI")
            )
        )
    }
}

// MARK: - Goal Card

struct GoalCard: View {
    let goal: SavingsGoal
    let viewModel: SavingsGoalsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header with emoji and name
            HStack(spacing: Spacing.sm) {
                if let emoji = goal.emoji, !emoji.isEmpty {
                    Text(emoji)
                        .font(.title)
                } else {
                    Image(systemName: "target")
                        .font(.title3)
                        .foregroundColor(.brandProgress)
                }

                Text(goal.name ?? String(localized: "savings.unknown", defaultValue: "Unknown", table: "UI"))
                    .cardLabelStyle(color: .textPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .captionStyle()
            }

            // Progress bar
            VStack(alignment: .leading, spacing: Spacing.xs) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: CornerRadius.tiny)
                            .fill(Color.chartTrack)
                            .frame(height: 8)

                        // Progress
                        RoundedRectangle(cornerRadius: CornerRadius.tiny)
                            .fill(Color.brandProgress)
                            .frame(width: geometry.size.width * viewModel.formatProgressBar(goal), height: 8)
                    }
                }
                .frame(height: 8)

                Text(viewModel.formatProgress(goal))
                    .badgeStyle(color: .brandProgress)
            }

            // Amount
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(viewModel.formatAmount(goal.currentAmount))
                    .metricCompactStyle(color: .textPrimary)

                Text(String(format: String(localized: "savings.of_amount", defaultValue: "of %@", table: "UI"), viewModel.formatAmount(goal.targetAmount)))
                    .captionStyle()
            }

            // Target date and pace
            if let targetDate = goal.targetDate {
                Divider()
                    .padding(.vertical, Spacing.xs)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack {
                        Text(String(format: String(localized: "savings.target_label", defaultValue: "Target: %@", table: "UI"), viewModel.formatShortDate(targetDate)))
                            .font(.caption)
                            .foregroundColor(.textSecondary)

                        Text(String(localized: "ui.bullet.point", defaultValue: "•", table: "UI"))
                            .font(.caption)
                            .foregroundColor(.textSecondary)

                        Text(viewModel.timeRemainingText(goal))
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }

                    // Pace status
                    if let paceText = viewModel.requiredMonthlyText(goal) {
                        HStack(spacing: 4) {
                            Text(paceText)
                                .font(.caption)
                                .foregroundColor(.textSecondary)

                            if !viewModel.paceStatusText(goal).isEmpty {
                                Text(String(localized: "ui.bullet.point", defaultValue: "•", table: "UI"))
                                    .font(.caption)
                                    .foregroundColor(.textSecondary)

                                Text(viewModel.paceStatusText(goal))
                                    .font(.caption)
                                    .foregroundColor(colorFromString(viewModel.paceStatusColor(goal)))
                            }
                        }
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(viewModel.remainingAmountText(goal))
                        .font(.caption)
                        .foregroundColor(.textSecondary)

                    if let etaText = viewModel.sharedPaceETAText(for: goal) {
                        Text(etaText)
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                            .accessibilityLabel(
                                String(
                                    format: String(localized: "savings.eta.accessibility", defaultValue: "Estimated time to goal: %@", table: "UI"),
                                    etaText
                                )
                            )
                    }
                }
            }

            if viewModel.isPrimaryGoal(goal),
               goal.targetDate != nil,
               let etaText = viewModel.sharedPaceETAText(for: goal) {
                Text(etaText)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                    .padding(.top, Spacing.xs)
            }
        }
        .padding(Spacing.lg)
        .glassSurface()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(goalAccessibilityLabel)
        .accessibilityHint(String(localized: "savings.goal.hint", defaultValue: "Double tap to view goal details", table: "UI"))
        .accessibilityAddTraits(.isButton)
    }

    private var goalAccessibilityLabel: String {
        let name = goal.name ?? String(localized: "savings.unknown", defaultValue: "Unknown", table: "UI")
        let progress = viewModel.formatProgress(goal)
        let current = viewModel.formatAmount(goal.currentAmount)
        let target = viewModel.formatAmount(goal.targetAmount)
        return String(
            format: String(localized: "savings.goal.accessibility", defaultValue: "%@, %@ complete, %@ of %@", table: "UI"),
            name,
            progress,
            current,
            target
        )
    }

    private func colorFromString(_ colorString: String) -> Color {
        switch colorString {
        case "brandProgress": return .brandProgress
        case "orange": return .orange
        case "textSecondary": return .textSecondary
        default: return .textSecondary
        }
    }
}

// MARK: - Completed Goal Card

struct CompletedGoalCard: View {
    let goal: SavingsGoal
    let viewModel: SavingsGoalsViewModel

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Checkmark icon
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundColor(.brandProgress)

            VStack(alignment: .leading, spacing: 4) {
                if let emoji = goal.emoji, !emoji.isEmpty {
                    HStack(spacing: Spacing.xs) {
                        Text(emoji)
                            .font(.body)
                        Text(goal.name ?? String(localized: "savings.unknown", defaultValue: "Unknown", table: "UI"))
                            .bodyStyle()
                    }
                } else {
                    Text(goal.name ?? String(localized: "savings.unknown", defaultValue: "Unknown", table: "UI"))
                        .bodyStyle()
                }

                if let completedDate = goal.completedDate {
                    Text(String(format: String(localized: "savings.completed_label", defaultValue: "Completed %@", table: "UI"), viewModel.formatShortDate(completedDate)))
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }

                Text(String(format: String(localized: "savings.amount_saved", defaultValue: "%@ saved", table: "UI"), viewModel.formatAmount(goal.targetAmount)))
                    .font(.caption)
                    .foregroundColor(.brandProgress)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.textSecondary)
        }
        .padding(Spacing.md)
        .glassSurface()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(completedGoalAccessibilityLabel)
        .accessibilityHint(String(localized: "savings.goal.hint", defaultValue: "Double tap to view goal details", table: "UI"))
        .accessibilityAddTraits(.isButton)
    }

    private var completedGoalAccessibilityLabel: String {
        let name = goal.name ?? String(localized: "savings.unknown", defaultValue: "Unknown", table: "UI")
        let saved = String(
            format: String(localized: "savings.amount_saved", defaultValue: "%@ saved", table: "UI"),
            viewModel.formatAmount(goal.targetAmount)
        )
        if let completedDate = goal.completedDate {
            let dateText = String(
                format: String(localized: "savings.completed_label", defaultValue: "Completed %@", table: "UI"),
                viewModel.formatShortDate(completedDate)
            )
            return String(
                format: String(localized: "savings.completed.accessibility", defaultValue: "Completed goal %@, %@, %@", table: "UI"),
                name,
                saved,
                dateText
            )
        }
        return String(
            format: String(localized: "savings.completed.accessibility_short", defaultValue: "Completed goal %@, %@", table: "UI"),
            name,
            saved
        )
    }
}

// MARK: - Preview

#Preview {
    SavingsGoalsView()
}
