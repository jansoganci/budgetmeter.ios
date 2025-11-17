//
//  SavingsGoalInputView.swift
//  BudgetMeter
//
//  Created by BudgetMeter Team on 14.11.2025.
//

import SwiftUI

/// Input form for adding or editing a savings goal
struct SavingsGoalInputView: View {

    // MARK: - Properties

    let goal: SavingsGoal?
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?

    // Form fields
    @State private var goalName: String = ""
    @State private var targetAmount: String = ""
    @State private var currentAmount: String = ""
    @State private var targetDate: Date = Calendar.current.date(byAdding: .month, value: 6, to: Date()) ?? Date()
    @State private var hasTargetDate: Bool = false
    @State private var selectedEmoji: String = ""
    @State private var selectedCategory: String = "Other"
    @State private var notes: String = ""

    // UI state
    @State private var showDeleteConfirmation = false
    @State private var showError = false
    @State private var errorMessage = ""

    private let currencySymbol = CurrencyHelper.symbol(for: CurrencyHelper.defaultCurrencyCode())

    // MARK: - Enums

    enum Field: Hashable {
        case goalName
        case targetAmount
        case currentAmount
        case notes
    }

    // MARK: - Computed Properties

    private var isEditMode: Bool {
        goal != nil
    }

    private var title: String {
        isEditMode ? "Edit Goal" : "Add Goal"
    }

    private var saveButtonDisabled: Bool {
        goalName.trimmingCharacters(in: .whitespaces).isEmpty ||
        targetAmount.trimmingCharacters(in: .whitespaces).isEmpty ||
        parseAmount(targetAmount) <= 0
    }

    private var requiredMonthlyText: String? {
        guard hasTargetDate else { return nil }
        guard let target = parseAmount(targetAmount), target > 0 else { return nil }
        guard let current = parseAmount(currentAmount) else { return nil }

        let remaining = max(0, target - current)
        guard remaining > 0 else { return "Goal reached!" }

        let calendar = Calendar.current
        let months = calendar.dateComponents([.month], from: Date(), to: targetDate).month ?? 0
        guard months > 0 else { return "Save \(formatAmount(remaining)) immediately" }

        let monthlyRequired = remaining / Double(months)
        return "To reach your goal by \(formatShortDate(targetDate)), save \(formatAmount(monthlyRequired))/month"
    }

    // MARK: - Categories and Emojis

    private let categories = [
        "Travel",
        "Education",
        "Emergency",
        "Home",
        "Vehicle",
        "Electronics",
        "Other"
    ]

    private let emojiOptions = [
        "🏝️", "✈️", "🏖️", "🌴", "🗺️",  // Travel
        "🎓", "📚", "✏️", "🎒",           // Education
        "🚨", "💰", "🏦", "💳",           // Emergency/Money
        "🏠", "🏡", "🔑",                // Home
        "🚗", "🚙", "🏍️",               // Vehicle
        "💻", "📱", "⌚", "📷",          // Electronics
        "💍", "🎉", "🎁", "⭐", "🎯", "💎" // Other
    ]

    // MARK: - Body

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // Goal Name
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Goal Name *")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.textSecondary)

                        TextField("Vacation Fund, New Car, etc.", text: $goalName)
                            .textFieldStyle(.plain)
                            .font(.body)
                            .padding(Spacing.md)
                            .background(Color.cardBackground)
                            .cornerRadius(CornerRadius.small)
                            .focused($focusedField, equals: .goalName)
                    }

                    // Emoji Picker
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Choose Emoji (optional)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.textSecondary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: Spacing.md) {
                                ForEach(emojiOptions, id: \.self) { emoji in
                                    Text(emoji)
                                        .font(.largeTitle)
                                        .frame(width: 50, height: 50)
                                        .background(selectedEmoji == emoji ? Color.brandProgress.opacity(0.2) : Color.cardBackground)
                                        .cornerRadius(CornerRadius.small)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: CornerRadius.small)
                                                .stroke(selectedEmoji == emoji ? Color.brandProgress : Color.clear, lineWidth: 2)
                                        )
                                        .onTapGesture {
                                            selectedEmoji = selectedEmoji == emoji ? "" : emoji
                                        }
                                }
                            }
                            .padding(.horizontal, 2)
                        }
                    }

                    // Target Amount
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Target Amount *")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.textSecondary)

                        HStack(spacing: Spacing.sm) {
                            Text(currencySymbol)
                                .font(.title3)
                                .foregroundColor(.textSecondary)

                            TextField("0.00", text: $targetAmount)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.plain)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .focused($focusedField, equals: .targetAmount)
                        }
                        .padding(Spacing.md)
                        .background(Color.cardBackground)
                        .cornerRadius(CornerRadius.small)
                    }

                    // Current Amount
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Current Amount")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.textSecondary)

                        HStack(spacing: Spacing.sm) {
                            Text(currencySymbol)
                                .font(.title3)
                                .foregroundColor(.textSecondary)

                            TextField("0.00", text: $currentAmount)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.plain)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .focused($focusedField, equals: .currentAmount)
                        }
                        .padding(Spacing.md)
                        .background(Color.cardBackground)
                        .cornerRadius(CornerRadius.small)
                    }

                    // Target Date Toggle
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Toggle(isOn: $hasTargetDate) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Set Target Date")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.textPrimary)

                                Text("Track your progress toward a deadline")
                                    .font(.caption)
                                    .foregroundColor(.textSecondary)
                            }
                        }
                        .toggleStyle(SwitchToggleStyle(tint: .brandProgress))

                        if hasTargetDate {
                            DatePicker(
                                "Target Date",
                                selection: $targetDate,
                                in: Date()...,
                                displayedComponents: [.date]
                            )
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .padding(Spacing.md)
                            .background(Color.cardBackground)
                            .cornerRadius(CornerRadius.small)

                            if let insightText = requiredMonthlyText {
                                Text(insightText)
                                    .font(.caption)
                                    .foregroundColor(.brandProgress)
                                    .padding(.horizontal, Spacing.sm)
                            }
                        }
                    }
                    .padding(Spacing.md)
                    .background(Color.cardBackground)
                    .cornerRadius(CornerRadius.small)

                    // Category
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Category")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.textSecondary)

                        Picker("Category", selection: $selectedCategory) {
                            ForEach(categories, id: \.self) { category in
                                Text(category).tag(category)
                            }
                        }
                        .pickerStyle(.menu)
                        .padding(Spacing.md)
                        .background(Color.cardBackground)
                        .cornerRadius(CornerRadius.small)
                    }

                    // Notes
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Notes (optional)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.textSecondary)

                        TextEditor(text: $notes)
                            .frame(height: 100)
                            .padding(Spacing.sm)
                            .background(Color.cardBackground)
                            .cornerRadius(CornerRadius.small)
                            .focused($focusedField, equals: .notes)
                    }

                    // Save Button
                    Button(action: saveGoal) {
                        Text(isEditMode ? "Save Changes" : "Create Goal")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(saveButtonDisabled ? Color.gray : Color.brandProgress)
                            .cornerRadius(CornerRadius.button)
                    }
                    .disabled(saveButtonDisabled)

                    // Edit mode actions
                    if isEditMode {
                        VStack(spacing: Spacing.md) {
                            Button(action: { showDeleteConfirmation = true }) {
                                HStack {
                                    Image(systemName: "trash")
                                    Text("Delete Goal")
                                }
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.red)
                            }
                        }
                    }
                }
                .padding(Spacing.lg)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        focusedField = nil
                    }
                    .foregroundColor(.brandProgress)
                    .fontWeight(.semibold)
                }
            }
            .alert("Delete Goal?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteGoal()
                }
            } message: {
                Text("This will permanently delete this savings goal. This action cannot be undone.")
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
        .onAppear {
            loadGoalData()
        }
    }

    // MARK: - Private Methods

    private func loadGoalData() {
        guard let goal = goal else { return }

        goalName = goal.name ?? ""
        targetAmount = String(format: "%.2f", goal.targetAmount)
        currentAmount = String(format: "%.2f", goal.currentAmount)
        selectedEmoji = goal.emoji ?? ""
        selectedCategory = goal.category ?? "Other"
        notes = goal.notes ?? ""

        if let date = goal.targetDate {
            targetDate = date
            hasTargetDate = true
        }
    }

    private func saveGoal() {
        guard let targetValue = parseAmount(targetAmount), targetValue > 0 else {
            errorMessage = "Please enter a valid target amount"
            showError = true
            return
        }

        let trimmedName = goalName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else {
            errorMessage = "Please enter a goal name"
            showError = true
            return
        }

        let current = parseAmount(currentAmount) ?? 0

        if let existingGoal = goal {
            // Update existing
            guard let goalId = existingGoal.id else {
                errorMessage = "Invalid goal ID. Cannot update savings goal."
                showError = true
                return
            }

            let success = SavingsGoalManager.shared.updateGoal(
                id: goalId,
                name: trimmedName,
                targetAmount: targetValue,
                targetDate: hasTargetDate ? targetDate : nil,
                emoji: selectedEmoji.isEmpty ? nil : selectedEmoji,
                colorHex: nil,
                category: selectedCategory,
                notes: notes.isEmpty ? nil : notes
            )

            // Update current amount separately if changed
            if current != existingGoal.currentAmount {
                let difference = current - existingGoal.currentAmount
                if difference > 0 {
                    _ = SavingsGoalManager.shared.addMoney(to: goalId, amount: difference)
                } else if difference < 0 {
                    _ = SavingsGoalManager.shared.withdrawMoney(from: goalId, amount: abs(difference))
                }
            }

            if success {
                // onSave() removed - notification observer handles UI update
                dismiss()
            } else {
                errorMessage = "Failed to update goal"
                showError = true
            }
        } else {
            // Create new
            let newGoal = SavingsGoalManager.shared.createGoal(
                name: trimmedName,
                targetAmount: targetValue,
                currentAmount: current,
                targetDate: hasTargetDate ? targetDate : nil,
                emoji: selectedEmoji.isEmpty ? nil : selectedEmoji,
                colorHex: nil,
                category: selectedCategory,
                notes: notes.isEmpty ? nil : notes
            )

            if newGoal != nil {
                // onSave() removed - notification observer handles UI update
                dismiss()
            } else {
                errorMessage = "Failed to create goal"
                showError = true
            }
        }
    }

    private func deleteGoal() {
        guard let goal = goal, let id = goal.id else { return }

        let success = SavingsGoalManager.shared.deleteGoal(id: id)

        if success {
            // onSave() removed - notification observer handles UI update
            dismiss()
        } else {
            errorMessage = "Failed to delete goal"
            showError = true
        }
    }

    private func parseAmount(_ input: String) -> Double? {
        let cleaned = input.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
        return Double(cleaned)
    }

    private func formatAmount(_ amount: Double) -> String {
        CurrencyHelper.format(amount: amount, currencyCode: CurrencyHelper.defaultCurrencyCode())
    }

    private func formatShortDate(_ date: Date) -> String {
        DateFormattingHelper.shared.formatMonthYear(date)
    }
}

// MARK: - Preview

#Preview("Add Mode") {
    SavingsGoalInputView(goal: nil, onSave: {
        print("Goal saved")
    })
}
