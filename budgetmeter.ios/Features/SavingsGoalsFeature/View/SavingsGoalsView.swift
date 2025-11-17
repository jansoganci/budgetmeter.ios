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

    // MARK: - Body

    var body: some View {
        NavigationStack {
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
            .navigationTitle("savings_goals.title".localized(defaultValue: "Savings Goals"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddGoal = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(.brandProgress)
                    }
                }
            }
            .sheet(isPresented: $showingAddGoal) {
                // Empty callback - notification observer handles UI update
                SavingsGoalInputView(goal: nil, onSave: {})
            }
            .sheet(item: $goalToEdit) { goal in
                // Empty callback - notification observer handles UI update
                SavingsGoalInputView(goal: goal, onSave: {})
            }
            .sheet(item: $goalToView) { goal in
                // Empty callback - notification observer handles UI update
                SavingsGoalDetailView(goal: goal, onUpdate: {})
            }
            .onAppear {
                viewModel.loadGoals()
            }
        }
    }

    // MARK: - Active Goals Section

    private var activeGoalsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("savings_goals.active".localized(defaultValue: "Active Goals"))
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.textPrimary)

            ForEach(viewModel.activeGoals, id: \.id) { goal in
                GoalCard(goal: goal, viewModel: viewModel)
                    .onTapGesture {
                        goalToView = goal
                    }
                    .contextMenu {
                        Button {
                            goalToEdit = goal
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }

                        Button(role: .destructive) {
                            viewModel.deleteGoal(goal)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
    }

    // MARK: - Completed Goals Section

    private var completedGoalsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("savings_goals.completed".localized(defaultValue: "Completed"))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)

                Text("(\(viewModel.completedGoals.count))")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
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
                            Label("Archive", systemImage: "archivebox")
                        }

                        Button(role: .destructive) {
                            viewModel.deleteGoal(goal)
                        } label: {
                            Label("Delete", systemImage: "trash")
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
                Text("savings_goals.empty.title".localized(defaultValue: "No Savings Goals Yet"))
                    .font(.headline)
                    .foregroundColor(.textPrimary)

                Text("savings_goals.empty.subtitle".localized(defaultValue: "Tap + to create your first savings goal"))
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

                Text(goal.name ?? "Unknown")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }

            // Progress bar
            VStack(alignment: .leading, spacing: Spacing.xs) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 8)

                        // Progress
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.brandProgress)
                            .frame(width: geometry.size.width * viewModel.formatProgressBar(goal), height: 8)
                    }
                }
                .frame(height: 8)

                Text(viewModel.formatProgress(goal))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.brandProgress)
            }

            // Amount
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(viewModel.formatAmount(goal.currentAmount))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)

                Text("of \(viewModel.formatAmount(goal.targetAmount))")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
            }

            // Target date and pace
            if let targetDate = goal.targetDate {
                Divider()
                    .padding(.vertical, Spacing.xs)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack {
                        Text("Target: \(viewModel.formatShortDate(targetDate))")
                            .font(.caption)
                            .foregroundColor(.textSecondary)

                        Text("•")
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
                                Text("•")
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
                Text(viewModel.remainingAmountText(goal))
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
        }
        .padding(Spacing.lg)
        .background(Color.cardBackground)
        .cornerRadius(CornerRadius.card)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
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
                        Text(goal.name ?? "Unknown")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.textPrimary)
                    }
                } else {
                    Text(goal.name ?? "Unknown")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.textPrimary)
                }

                if let completedDate = goal.completedDate {
                    Text("Completed \(viewModel.formatShortDate(completedDate))")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }

                Text(viewModel.formatAmount(goal.targetAmount) + " saved")
                    .font(.caption)
                    .foregroundColor(.brandProgress)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.textSecondary)
        }
        .padding(Spacing.md)
        .background(Color.cardBackground)
        .cornerRadius(CornerRadius.card)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Preview

#Preview {
    SavingsGoalsView()
}
