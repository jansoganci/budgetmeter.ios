//
//  SavingsGoalDetailView.swift
//  BudgetMeter
//
//  Created by BudgetMeter Team on 14.11.2025.
//

import SwiftUI

/// Detail view for a single savings goal with add/withdraw actions
struct SavingsGoalDetailView: View {

    // MARK: - Properties

    let goal: SavingsGoal
    var sharedPaceETAText: String? = nil
    let onUpdate: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showingAddMoney = false
    @State private var showingWithdrawMoney = false
    @State private var showingEdit = false
    @State private var amount: String = ""
    @FocusState private var amountFieldFocused: Bool

    private var currencySymbol: String {
        CurrencyHelper.symbol(for: CurrencyHelper.currentCurrencyCode())
    }
    private let goalManager = SavingsGoalManager.shared

    // MARK: - Computed Properties

    private var progress: Double {
        goalManager.calculateProgress(for: goal) / 100.0
    }

    private var progressPercentage: String {
        PercentageFormatter.formatInteger(goalManager.calculateProgress(for: goal))
    }

    private var remaining: Double {
        max(0, goal.targetAmount - goal.currentAmount)
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // Header with emoji and name
                    VStack(spacing: Spacing.md) {
                        if let emoji = goal.emoji, !emoji.isEmpty {
                            Text(emoji)
                                .font(.system(size: 64))
                        } else {
                            Image(systemName: "target")
                                .font(.system(size: 64))
                                .foregroundColor(.brandProgress)
                        }

                        Text(goal.name ?? String(localized: "savings.unknown", defaultValue: "Unknown", table: "UI", comment: "Unknown goal name"))
                            .sectionTitleStyle()
                    }

                    // Progress Card
                    VStack(spacing: Spacing.lg) {
                        // Progress Bar
                        VStack(spacing: Spacing.sm) {
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: CornerRadius.badge)
                                        .fill(Color.chartTrack)
                                        .frame(height: 16)

                                    RoundedRectangle(cornerRadius: CornerRadius.badge)
                                        .fill(Color.brandProgress)
                                        .frame(width: geometry.size.width * progress, height: 16)
                                }
                            }
                            .frame(height: 16)

                            Text(progressPercentage)
                                .metricMediumStyle(color: .brandProgress)
                        }

                        // Amounts
                        VStack(spacing: Spacing.xs) {
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text(formatAmount(goal.currentAmount))
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundColor(.textPrimary)

                                Text(String(format: String(localized: "savings.of_amount", defaultValue: "of %@", table: "UI"), formatAmount(goal.targetAmount)))
                                    .font(.title3)
                                    .foregroundColor(.textSecondary)
                            }

                            if remaining > 0 {
                                Text(String(format: String(localized: "savings.to_go", defaultValue: "%@ to go", table: "UI"), formatAmount(remaining)))
                                    .font(.subheadline)
                                    .foregroundColor(.textSecondary)
                            } else {
                                Text(String(localized: "savings.goal_reached_message", defaultValue: "Goal reached! 🎉", table: "UI"))
                                    .font(.subheadline)
                                    .foregroundColor(.brandProgress)
                            }
                        }
                    }
                    .padding(Spacing.lg)
                    .glassSurface()
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(
                        String(
                            format: String(localized: "savings.detail.progress.accessibility", defaultValue: "Goal progress %@. %@ saved out of %@.", table: "UI"),
                            progressPercentage,
                            formatAmount(goal.currentAmount),
                            formatAmount(goal.targetAmount)
                        )
                    )

                    if let sharedPaceETAText, !sharedPaceETAText.isEmpty {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text(String(localized: "savings.eta.shared_pace_title", defaultValue: "Shared pace estimate"))
                                .font(.caption)
                                .foregroundColor(.textSecondary)

                            Text(sharedPaceETAText)
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.textPrimary)
                                .accessibilityLabel(
                                    String(
                                        localized: "savings.eta.accessibility",
                                        defaultValue: "Estimated time to goal: \(sharedPaceETAText)"
                                    )
                                )
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(Spacing.lg)
                        .padding(Spacing.lg)
                        .glassSurface()
                    }

                    // Target Date and Pace Info
                    if let targetDate = goal.targetDate {
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(.brandProgress)
                                    .frame(width: 24)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(String(localized: "savings.target_date", defaultValue: "Target Date", table: "UI"))
                                        .font(.caption)
                                        .foregroundColor(.textSecondary)

                                    Text(formatDate(targetDate))
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundColor(.textPrimary)
                                }

                                Spacer()

                                Text(timeRemainingText(targetDate))
                                    .font(.caption)
                                    .foregroundColor(.textSecondary)
                            }

                            if let required = goalManager.calculateRequiredMonthlyContribution(for: goal), required > 0 {
                                Divider()

                                HStack {
                                    Image(systemName: "chart.line.uptrend.xyaxis")
                                        .foregroundColor(.brandProgress)
                                        .frame(width: 24)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(String(localized: "savings.required_monthly", defaultValue: "Required Monthly", table: "UI"))
                                            .font(.caption)
                                            .foregroundColor(.textSecondary)

                                        Text(formatAmount(required))
                                            .font(.body)
                                            .fontWeight(.medium)
                                            .foregroundColor(.textPrimary)
                                    }

                                    Spacer()

                                    Text(goalManager.isPaceStatus(for: goal).displayText)
                                        .font(.caption)
                                        .foregroundColor(paceColor)
                                }
                            }
                        }
                        .padding(Spacing.lg)
                        .padding(Spacing.lg)
                        .glassSurface()
                    }

                    // Quick Actions
                    if goal.completedDate == nil {
                        HStack(spacing: Spacing.md) {
                            Button(action: { showingAddMoney = true }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text(String(localized: "savings.add_money", defaultValue: "Add Money", table: "UI"))
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: LayoutSpacing.buttonHeight)
                                .background(Color.brandProgress)
                                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.button, style: .continuous))
                            }
                            .accessibilityHint(String(localized: "savings.add_money.hint", defaultValue: "Double tap to add funds to this goal", table: "UI"))

                            Button(action: { showingWithdrawMoney = true }) {
                                HStack {
                                    Image(systemName: "minus.circle.fill")
                                    Text(String(localized: "savings.withdraw", defaultValue: "Withdraw", table: "UI"))
                                }
                                .font(.headline)
                                .foregroundColor(.brandProgress)
                                .frame(maxWidth: .infinity)
                                .frame(height: LayoutSpacing.buttonHeight)
                                .padding(LayoutSpacing.cardPadding)
                                .glassSurface()
                                .overlay(
                                    RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous)
                                        .stroke(Color.brandProgress, lineWidth: 2)
                                )
                            }
                            .accessibilityHint(String(localized: "savings.withdraw.hint", defaultValue: "Double tap to withdraw funds from this goal", table: "UI"))
                        }
                    }

                    // Notes
                    if let notes = goal.notes, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text(String(localized: "savings.notes", defaultValue: "Notes", table: "UI"))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.textPrimary)

                            Text(notes)
                                .font(.body)
                                .foregroundColor(.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(Spacing.lg)
                        .padding(Spacing.lg)
                        .glassSurface()
                    }
                }
                .padding(Spacing.lg)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(String(localized: "Done", defaultValue: "Done", comment: "Dismiss detail view")) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(String(localized: "Edit", defaultValue: "Edit", comment: "Edit savings goal")) {
                        showingEdit = true
                    }
                }
            }
            .sheet(isPresented: $showingAddMoney) {
                addMoneySheet
            }
            .sheet(isPresented: $showingWithdrawMoney) {
                withdrawMoneySheet
            }
            .sheet(isPresented: $showingEdit) {
                SavingsGoalInputView(goal: goal) {
                    onUpdate()
                }
            }
        }
    }

    // MARK: - Add Money Sheet

    private var addMoneySheet: some View {
        NavigationView {
            ZStack {
                AppBackground()

                VStack(spacing: LayoutSpacing.sectionGap) {
                    SectionHeader(
                        title: String(localized: "savings.add_money_to_goal", defaultValue: "Add Money to Goal", table: "UI")
                    )

                    FinancialAmountField(
                        label: nil,
                        currencySymbol: currencySymbol,
                        text: $amount,
                        accentColor: .accentPrimary,
                        alignment: .center,
                        focused: $amountFieldFocused
                    )

                    Spacer(minLength: Spacing.md)

                    PrimaryCTAButton(
                        title: String(localized: "savings.add", defaultValue: "Add", table: "UI"),
                        isDisabled: parseAmount(amount) ?? 0 <= 0,
                        action: performAddMoney
                    )
                }
                .padding(LayoutSpacing.screenPadding)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(String(localized: "Cancel", defaultValue: "Cancel", comment: "Cancel add money")) {
                        showingAddMoney = false
                    }
                }
            }
            .onAppear {
                amount = ""
                amountFieldFocused = true
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Withdraw Money Sheet

    private var withdrawMoneySheet: some View {
        NavigationView {
            ZStack {
                AppBackground()

                VStack(spacing: LayoutSpacing.sectionGap) {
                    SectionHeader(
                        title: String(localized: "savings.withdraw_from_goal", defaultValue: "Withdraw from Goal", table: "UI"),
                        subtitle: String(format: String(localized: "savings.available_amount", defaultValue: "Available: %@", table: "UI"), formatAmount(goal.currentAmount))
                    )

                    FinancialAmountField(
                        label: nil,
                        currencySymbol: currencySymbol,
                        text: $amount,
                        accentColor: .financialCaution,
                        alignment: .center,
                        focused: $amountFieldFocused
                    )

                    Spacer(minLength: Spacing.md)

                    PrimaryCTAButton(
                        title: String(localized: "savings.withdraw", defaultValue: "Withdraw", table: "UI"),
                        isDisabled: (parseAmount(amount) ?? 0) <= 0 || (parseAmount(amount) ?? 0) > goal.currentAmount,
                        action: performWithdrawMoney
                    )
                }
                .padding(LayoutSpacing.screenPadding)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(String(localized: "Cancel", defaultValue: "Cancel", comment: "Cancel withdraw money")) {
                        showingWithdrawMoney = false
                    }
                }
            }
            .onAppear {
                amount = ""
                amountFieldFocused = true
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Private Methods

    private func performAddMoney() {
        guard let amountValue = parseAmount(amount), amountValue > 0 else { return }
        guard let id = goal.id else { return }

        _ = goalManager.addMoney(to: id, amount: amountValue)
        // onUpdate() removed - notification observer handles UI update
        showingAddMoney = false
    }

    private func performWithdrawMoney() {
        guard let amountValue = parseAmount(amount), amountValue > 0 else { return }
        guard amountValue <= goal.currentAmount else { return }
        guard let id = goal.id else { return }

        _ = goalManager.withdrawMoney(from: id, amount: amountValue)
        // onUpdate() removed - notification observer handles UI update
        showingWithdrawMoney = false
    }

    private func parseAmount(_ input: String) -> Double? {
        let cleaned = input.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
        return Double(cleaned)
    }

    private func formatAmount(_ amount: Double) -> String {
        CurrencyHelper.format(amount: amount, currencyCode: CurrencyHelper.currentCurrencyCode())
    }

    private func formatDate(_ date: Date) -> String {
        DateFormattingHelper.shared.formatLong(date)
    }

    private func timeRemainingText(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()

        if date < now {
            return String(localized: "savings.target_date_passed", defaultValue: "Target date passed", table: "UI")
        }

        let components = calendar.dateComponents([.month, .day], from: now, to: date)

        if let months = components.month, months > 0 {
            let formatString = String(localized: "savings.months_remaining", defaultValue: "\(months) month\(months == 1 ? "" : "s") remaining", table: "UI")
            return String(format: formatString, months)
        } else if let days = components.day, days > 0 {
            let formatString = String(localized: "savings.days_remaining", defaultValue: "\(days) day\(days == 1 ? "" : "s") remaining", table: "UI")
            return String(format: formatString, days)
        } else {
            return String(localized: "savings.due_today", defaultValue: "Due today", table: "UI")
        }
    }

    private var paceColor: Color {
        switch goalManager.isPaceStatus(for: goal) {
        case .ahead, .onPace, .completed:
            return .brandProgress
        case .behind:
            return .orange
        case .unknown:
            return .textSecondary
        }
    }
}

// MARK: - Preview

#Preview {
    SavingsGoalDetailView(goal: SavingsGoal(), onUpdate: {})
}
