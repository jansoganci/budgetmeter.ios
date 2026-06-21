//
//  SavingsGoalInputView.swift
//  BudgetMeter
//
//  Add/edit savings goal form — v2 input flow.
//

import SwiftUI

/// Input form for adding or editing a savings goal
struct SavingsGoalInputView: View {

    let goal: SavingsGoal?
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?

    @State private var goalName: String = ""
    @State private var targetAmount: String = ""
    @State private var currentAmount: String = ""
    @State private var targetDate: Date = Calendar.current.date(byAdding: .month, value: 6, to: Date()) ?? Date()
    @State private var hasTargetDate: Bool = false
    @State private var selectedEmoji: String = ""
    @State private var selectedCategory: String = "Other"
    @State private var notes: String = ""

    @State private var showDeleteConfirmation = false
    @State private var showError = false
    @State private var errorMessage = ""

    private var currencySymbol: String {
        CurrencyHelper.symbol(for: CurrencyHelper.currentCurrencyCode())
    }

    enum Field: Hashable {
        case goalName
        case notes
    }

    private var isEditMode: Bool {
        goal != nil
    }

    private var title: String {
        isEditMode
            ? String(localized: "savings.title.edit", defaultValue: "Edit Goal", table: "UI")
            : String(localized: "savings.title.add", defaultValue: "Add Goal", table: "UI")
    }

    private var saveButtonDisabled: Bool {
        goalName.trimmingCharacters(in: .whitespaces).isEmpty
            || targetAmount.trimmingCharacters(in: .whitespaces).isEmpty
            || (parseAmount(targetAmount) ?? 0) <= 0
    }

    private var requiredMonthlyText: String? {
        guard hasTargetDate else { return nil }
        guard let target = parseAmount(targetAmount), target > 0 else { return nil }
        guard let current = parseAmount(currentAmount) else { return nil }

        let remaining = max(0, target - current)
        guard remaining > 0 else {
            return String(localized: "savings.goal_reached", defaultValue: "Goal reached!", table: "UI")
        }

        let calendar = Calendar.current
        let months = calendar.dateComponents([.month], from: Date(), to: targetDate).month ?? 0
        guard months > 0 else {
            return String(format: String(localized: "savings.save_immediately", defaultValue: "Save %@ immediately", table: "UI"), formatAmount(remaining))
        }

        let monthlyRequired = remaining / Double(months)
        return String(format: String(localized: "savings.monthly_required", defaultValue: "To reach your goal by %@, save %@/month", table: "UI"), formatShortDate(targetDate), formatAmount(monthlyRequired))
    }

    private let categories = [
        "Travel", "Education", "Emergency", "Home", "Vehicle", "Electronics", "Other"
    ]

    private let emojiOptions = [
        "🏝️", "✈️", "🏖️", "🌴", "🗺️",
        "🎓", "📚", "✏️", "🎒",
        "🚨", "💰", "🏦", "💳",
        "🏠", "🏡", "🔑",
        "🚗", "🚙", "🏍️",
        "💻", "📱", "⌚", "📷",
        "💍", "🎉", "🎁", "⭐", "🎯", "💎"
    ]

    var body: some View {
        NavigationView {
            ZStack {
                AppBackground()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: LayoutSpacing.sectionGap) {
                        goalNameCard
                        emojiCard
                        amountsCard
                        targetDateSection
                        categoryCard
                        notesCard

                        PrimaryCTAButton(
                            title: isEditMode
                                ? String(localized: "form.save_changes", defaultValue: "Save Changes", table: "UI")
                                : String(localized: "savings.create_goal", defaultValue: "Create Goal", table: "UI"),
                            isDisabled: saveButtonDisabled,
                            action: saveGoal
                        )

                        if isEditMode {
                            Button(action: { showDeleteConfirmation = true }) {
                                HStack {
                                    Image(systemName: "trash")
                                    Text(String(localized: "savings.delete_goal", defaultValue: "Delete Goal", table: "UI"))
                                }
                                .bodyStyle(color: .financialNegative)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, LayoutSpacing.screenPadding)
                    .padding(.vertical, Spacing.md)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(String(localized: "form.cancel", defaultValue: "Cancel", table: "UI")) {
                        dismiss()
                    }
                }

                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(String(localized: "form.done", defaultValue: "Done", table: "UI")) {
                        focusedField = nil
                    }
                    .foregroundColor(.accentPrimary)
                    .fontWeight(.semibold)
                }
            }
            .alert(String(localized: "savings.delete_confirm_title", defaultValue: "Delete Goal?", table: "UI"), isPresented: $showDeleteConfirmation) {
                Button(String(localized: "form.cancel", defaultValue: "Cancel", table: "UI"), role: .cancel) { }
                Button(String(localized: "savings.delete_goal", defaultValue: "Delete Goal", table: "UI"), role: .destructive) {
                    deleteGoal()
                }
            } message: {
                Text(String(localized: "savings.delete_confirm_message", defaultValue: "This will permanently delete this savings goal. This action cannot be undone.", table: "UI"))
            }
            .alert(String(localized: "alert.error.title", defaultValue: "Error", table: "UI"), isPresented: $showError) {
                Button(String(localized: "alert.ok", defaultValue: "OK", table: "UI"), role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
        .presentationDragIndicator(.visible)
        .onAppear {
            loadGoalData()
        }
    }

    private var goalNameSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(String(localized: "savings.goal_name", defaultValue: "Goal Name *", table: "UI"))
                .statusTitleStyle(color: .textSecondary)

            TextField(String(localized: "savings.goal_name_placeholder", defaultValue: "Vacation Fund, New Car, etc.", table: "UI"), text: $goalName)
                .textFieldStyle(.plain)
                .bodyStyle()
                .padding(Spacing.md)
                .background(Color.surfaceInset)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
                .focused($focusedField, equals: .goalName)
        }
    }

    private var goalNameCard: some View {
        GlassCard {
            goalNameSection
        }
    }

    private var emojiSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(String(localized: "savings.choose_emoji", defaultValue: "Choose Emoji (optional)", table: "UI"))
                .statusTitleStyle(color: .textSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.md) {
                    ForEach(emojiOptions, id: \.self) { emoji in
                        emojiPickerCell(emoji)
                    }
                }
                .padding(.horizontal, Spacing.xs)
            }
        }
    }

    private var emojiCard: some View {
        GlassCard {
            emojiSection
        }
    }

    private var targetAmountSection: some View {
        FinancialAmountField(
            label: String(localized: "savings.target_amount", defaultValue: "Target Amount *", table: "UI"),
            currencySymbol: currencySymbol,
            text: $targetAmount,
            accentColor: .accentPrimary,
            useHeroTypography: false
        )
    }

    private var currentAmountSection: some View {
        FinancialAmountField(
            label: String(localized: "savings.current_amount", defaultValue: "Current Amount", table: "UI"),
            currencySymbol: currencySymbol,
            text: $currentAmount,
            accentColor: .accentPrimary,
            useHeroTypography: false
        )
    }

    private var amountsCard: some View {
        GlassCard {
            VStack(spacing: LayoutSpacing.cardInternalGap) {
                targetAmountSection
                currentAmountSection
            }
        }
    }

    private var targetDateSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: LayoutSpacing.cardInternalGap) {
                Toggle(isOn: $hasTargetDate) {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(String(localized: "savings.set_target_date", defaultValue: "Set Target Date", table: "UI"))
                            .bodyStyle()
                        Text(String(localized: "savings.target_date_description", defaultValue: "Track your progress toward a deadline", table: "UI"))
                            .captionStyle()
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: .accentPrimary))

                if hasTargetDate {
                    DatePicker(
                        String(localized: "savings.target_date", defaultValue: "Target Date", table: "UI"),
                        selection: $targetDate,
                        in: Date()...,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .padding(Spacing.md)
                    .background(Color.surfaceInset)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))

                    if let insightText = requiredMonthlyText {
                        Text(insightText)
                            .captionStyle(color: .accentPrimary)
                    }
                }
            }
        }
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(String(localized: "form.category", defaultValue: "Category", table: "UI"))
                .statusTitleStyle(color: .textSecondary)

            Picker("Category", selection: $selectedCategory) {
                ForEach(categories, id: \.self) { category in
                    Text(category).tag(category)
                }
            }
            .pickerStyle(.menu)
            .padding(Spacing.md)
            .background(Color.surfaceInset)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
        }
    }

    private var categoryCard: some View {
        GlassCard {
            categorySection
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(String(localized: "form.notes_optional", defaultValue: "Notes (optional)", table: "UI"))
                .statusTitleStyle(color: .textSecondary)

            TextEditor(text: $notes)
                .frame(height: 100)
                .padding(Spacing.sm)
                .background(Color.surfaceInset)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
                .focused($focusedField, equals: .notes)
        }
    }

    private var notesCard: some View {
        GlassCard {
            notesSection
        }
    }

    @ViewBuilder
    private func emojiPickerCell(_ emoji: String) -> some View {
        let isSelected = selectedEmoji == emoji
        Text(emoji)
            .font(.largeTitle)
            .frame(width: 50, height: 50)
            .background(isSelected ? Color.accentPrimary.opacity(0.2) : Color.surfaceInset)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
                    .stroke(isSelected ? Color.accentPrimary : Color.clear, lineWidth: 2)
            )
            .onTapGesture {
                selectedEmoji = isSelected ? "" : emoji
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(
                String(format: String(localized: "savings.emoji_picker.accessibility", defaultValue: "Emoji option %@", table: "UI"), emoji)
            )
            .accessibilityAddTraits(.isButton)
    }

    private func loadGoalData() {
        guard let goal else { return }

        goalName = goal.name ?? ""
        targetAmount = CurrencyHelper.formatForTextField(goal.targetAmount)
        currentAmount = CurrencyHelper.formatForTextField(goal.currentAmount)
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
            errorMessage = String(localized: "savings.error.invalid_target", defaultValue: "Please enter a valid target amount", table: "UI")
            showError = true
            return
        }

        let trimmedName = goalName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else {
            errorMessage = String(localized: "savings.error.enter_name", defaultValue: "Please enter a goal name", table: "UI")
            showError = true
            return
        }

        let current = parseAmount(currentAmount) ?? 0

        if let existingGoal = goal {
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

            if current != existingGoal.currentAmount {
                let difference = current - existingGoal.currentAmount
                if difference > 0 {
                    _ = SavingsGoalManager.shared.addMoney(to: goalId, amount: difference)
                } else if difference < 0 {
                    _ = SavingsGoalManager.shared.withdrawMoney(from: goalId, amount: abs(difference))
                }
            }

            if success {
                dismiss()
            } else {
                errorMessage = String(localized: "savings.error.failed_update", defaultValue: "Failed to update goal", table: "UI")
                showError = true
            }
        } else {
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
                dismiss()
            } else {
                errorMessage = String(localized: "savings.error.failed_create", defaultValue: "Failed to create goal", table: "UI")
                showError = true
            }
        }
    }

    private func deleteGoal() {
        guard let goal, let id = goal.id else { return }

        let success = SavingsGoalManager.shared.deleteGoal(id: id)

        if success {
            dismiss()
        } else {
            errorMessage = String(localized: "savings.error.failed_delete", defaultValue: "Failed to delete goal", table: "UI")
            showError = true
        }
    }

    private func parseAmount(_ input: String) -> Double? {
        let cleaned = input.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
        return Double(cleaned)
    }

    private func formatAmount(_ amount: Double) -> String {
        CurrencyHelper.format(amount: amount, currencyCode: CurrencyHelper.currentCurrencyCode())
    }

    private func formatShortDate(_ date: Date) -> String {
        DateFormattingHelper.shared.formatMonthYear(date)
    }
}

#Preview("Add Mode") {
    SavingsGoalInputView(goal: nil, onSave: {})
}
