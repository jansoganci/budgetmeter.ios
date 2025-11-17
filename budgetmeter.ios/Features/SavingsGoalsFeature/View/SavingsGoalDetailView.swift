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
    let onUpdate: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showingAddMoney = false
    @State private var showingWithdrawMoney = false
    @State private var showingEdit = false
    @State private var amount: String = ""
    @FocusState private var amountFieldFocused: Bool

    private let currencySymbol = CurrencyHelper.symbol(for: CurrencyHelper.defaultCurrencyCode())
    private let goalManager = SavingsGoalManager.shared

    // MARK: - Computed Properties

    private var progress: Double {
        goalManager.calculateProgress(for: goal) / 100.0
    }

    private var progressPercentage: String {
        String(format: "%.0f%%", goalManager.calculateProgress(for: goal))
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

                        Text(goal.name ?? "Unknown")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.textPrimary)
                    }

                    // Progress Card
                    VStack(spacing: Spacing.lg) {
                        // Progress Bar
                        VStack(spacing: Spacing.sm) {
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(height: 16)

                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.brandProgress)
                                        .frame(width: geometry.size.width * progress, height: 16)
                                }
                            }
                            .frame(height: 16)

                            Text(progressPercentage)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.brandProgress)
                        }

                        // Amounts
                        VStack(spacing: Spacing.xs) {
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text(formatAmount(goal.currentAmount))
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundColor(.textPrimary)

                                Text("of \(formatAmount(goal.targetAmount))")
                                    .font(.title3)
                                    .foregroundColor(.textSecondary)
                            }

                            if remaining > 0 {
                                Text("\(formatAmount(remaining)) to go")
                                    .font(.subheadline)
                                    .foregroundColor(.textSecondary)
                            } else {
                                Text("Goal reached! 🎉")
                                    .font(.subheadline)
                                    .foregroundColor(.brandProgress)
                            }
                        }
                    }
                    .padding(Spacing.lg)
                    .background(Color.cardBackground)
                    .cornerRadius(CornerRadius.card)
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)

                    // Target Date and Pace Info
                    if let targetDate = goal.targetDate {
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(.brandProgress)
                                    .frame(width: 24)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Target Date")
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
                                        Text("Required Monthly")
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
                        .background(Color.cardBackground)
                        .cornerRadius(CornerRadius.card)
                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                    }

                    // Quick Actions
                    if goal.completedDate == nil {
                        HStack(spacing: Spacing.md) {
                            Button(action: { showingAddMoney = true }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add Money")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.brandProgress)
                                .cornerRadius(CornerRadius.button)
                            }

                            Button(action: { showingWithdrawMoney = true }) {
                                HStack {
                                    Image(systemName: "minus.circle.fill")
                                    Text("Withdraw")
                                }
                                .font(.headline)
                                .foregroundColor(.brandProgress)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.cardBackground)
                                .cornerRadius(CornerRadius.button)
                                .overlay(
                                    RoundedRectangle(cornerRadius: CornerRadius.button)
                                        .stroke(Color.brandProgress, lineWidth: 2)
                                )
                            }
                        }
                    }

                    // Notes
                    if let notes = goal.notes, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Notes")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.textPrimary)

                            Text(notes)
                                .font(.body)
                                .foregroundColor(.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(Spacing.lg)
                        .background(Color.cardBackground)
                        .cornerRadius(CornerRadius.card)
                    }
                }
                .padding(Spacing.lg)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Edit") {
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
            VStack(spacing: Spacing.xl) {
                Spacer()

                VStack(spacing: Spacing.sm) {
                    Text("Add Money to Goal")
                        .font(.headline)
                        .foregroundColor(.textPrimary)

                    HStack(spacing: Spacing.sm) {
                        Text(currencySymbol)
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.textSecondary)

                        TextField("0.00", text: $amount)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.plain)
                            .font(.system(size: 40, weight: .bold))
                            .focused($amountFieldFocused)
                            .multilineTextAlignment(.center)
                    }
                    .padding(Spacing.lg)
                    .background(Color.cardBackground)
                    .cornerRadius(CornerRadius.card)
                }

                Button(action: performAddMoney) {
                    Text("Add")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.brandProgress)
                        .cornerRadius(CornerRadius.button)
                }
                .disabled(parseAmount(amount) ?? 0 <= 0)

                Spacer()
            }
            .padding(Spacing.lg)
            .navigationTitle("Add Money")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
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
    }

    // MARK: - Withdraw Money Sheet

    private var withdrawMoneySheet: some View {
        NavigationView {
            VStack(spacing: Spacing.xl) {
                Spacer()

                VStack(spacing: Spacing.sm) {
                    Text("Withdraw from Goal")
                        .font(.headline)
                        .foregroundColor(.textPrimary)

                    Text("Available: \(formatAmount(goal.currentAmount))")
                        .font(.caption)
                        .foregroundColor(.textSecondary)

                    HStack(spacing: Spacing.sm) {
                        Text(currencySymbol)
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.textSecondary)

                        TextField("0.00", text: $amount)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.plain)
                            .font(.system(size: 40, weight: .bold))
                            .focused($amountFieldFocused)
                            .multilineTextAlignment(.center)
                    }
                    .padding(Spacing.lg)
                    .background(Color.cardBackground)
                    .cornerRadius(CornerRadius.card)
                }

                Button(action: performWithdrawMoney) {
                    Text("Withdraw")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.orange)
                        .cornerRadius(CornerRadius.button)
                }
                .disabled((parseAmount(amount) ?? 0) <= 0 || (parseAmount(amount) ?? 0) > goal.currentAmount)

                Spacer()
            }
            .padding(Spacing.lg)
            .navigationTitle("Withdraw Money")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
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
        CurrencyHelper.format(amount: amount, currencyCode: CurrencyHelper.defaultCurrencyCode())
    }

    private func formatDate(_ date: Date) -> String {
        DateFormattingHelper.shared.formatLong(date)
    }

    private func timeRemainingText(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()

        if date < now {
            return "Past due"
        }

        let components = calendar.dateComponents([.month, .day], from: now, to: date)

        if let months = components.month, months > 0 {
            return "\(months) month\(months == 1 ? "" : "s")"
        } else if let days = components.day, days > 0 {
            return "\(days) day\(days == 1 ? "" : "s")"
        } else {
            return "Today"
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
