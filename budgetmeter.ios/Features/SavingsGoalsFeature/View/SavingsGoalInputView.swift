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
    @FocusState private var isTargetAmountFocused: Bool
    @FocusState private var isCurrentAmountFocused: Bool

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
            ? "savings.title.edit".localized(defaultValue: "Edit Goal", table: "UI")
            : "savings.title.add".localized(defaultValue: "Add Goal", table: "UI")
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
            return "savings.goal_reached".localized(defaultValue: "Goal reached!", table: "UI")
        }

        let calendar = Calendar.current
        let months = calendar.dateComponents([.month], from: Date(), to: targetDate).month ?? 0
        guard months > 0 else {
            return String(format: "savings.save_immediately".localized(defaultValue: "Save %@ immediately", table: "UI"), formatAmount(remaining))
        }

        let monthlyRequired = remaining / Double(months)
        return String(format: "savings.monthly_required".localized(defaultValue: "To reach your goal by %@, save %@/month", table: "UI"), formatShortDate(targetDate), formatAmount(monthlyRequired))
    }

    private struct CategoryOption {
        let rawValue: String
        let titleKey: String
        let defaultTitle: String
    }

    private let categories = [
        CategoryOption(rawValue: "Travel", titleKey: "savings.category.travel", defaultTitle: "Travel"),
        CategoryOption(rawValue: "Education", titleKey: "savings.category.education", defaultTitle: "Education"),
        CategoryOption(rawValue: "Emergency", titleKey: "savings.category.emergency", defaultTitle: "Emergency"),
        CategoryOption(rawValue: "Home", titleKey: "savings.category.home", defaultTitle: "Home"),
        CategoryOption(rawValue: "Vehicle", titleKey: "savings.category.vehicle", defaultTitle: "Vehicle"),
        CategoryOption(rawValue: "Electronics", titleKey: "savings.category.electronics", defaultTitle: "Electronics"),
        CategoryOption(rawValue: "Other", titleKey: "savings.category.other", defaultTitle: "Other")
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
                                ? "form.save_changes".localized(defaultValue: "Save Changes", table: "UI")
                                : "savings.create_goal".localized(defaultValue: "Create Goal", table: "UI"),
                            isDisabled: saveButtonDisabled,
                            action: saveGoal
                        )

                        if isEditMode {
                            Button(action: { showDeleteConfirmation = true }) {
                                HStack {
                                    Image(systemName: "trash")
                                    Text("savings.delete_goal".localized(defaultValue: "Delete Goal", table: "UI"))
                                }
                                .bodyStyle(color: .financialNegative)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, LayoutSpacing.screenPadding)
                    .padding(.vertical, Spacing.md)
                    .padding(.bottom, LayoutSpacing.buttonHeight)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("form.cancel".localized(defaultValue: "Cancel", table: "UI")) {
                        dismiss()
                    }
                }

                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("form.done".localized(defaultValue: "Done", table: "UI")) {
                        clearAllInputFocus()
                    }
                    .foregroundColor(.accentPrimary)
                    .fontWeight(.semibold)
                }
            }
            .alert("savings.delete_confirm_title".localized(defaultValue: "Delete Goal?", table: "UI"), isPresented: $showDeleteConfirmation) {
                Button("form.cancel".localized(defaultValue: "Cancel", table: "UI"), role: .cancel) { }
                Button("savings.delete_goal".localized(defaultValue: "Delete Goal", table: "UI"), role: .destructive) {
                    deleteGoal()
                }
            } message: {
                Text("savings.delete_confirm_message".localized(defaultValue: "This will permanently delete this savings goal. This action cannot be undone.", table: "UI"))
            }
            .alert("alert.error.title".localized(defaultValue: "Error", table: "UI"), isPresented: $showError) {
                Button("alert.ok".localized(defaultValue: "OK", table: "UI"), role: .cancel) { }
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
            Text("savings.goal_name".localized(defaultValue: "Goal Name *", table: "UI"))
                .statusTitleStyle(color: .textSecondary)

            TextField("savings.goal_name_placeholder".localized(defaultValue: "Vacation Fund, New Car, etc.", table: "UI"), text: $goalName)
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
            Text("savings.choose_emoji".localized(defaultValue: "Choose Emoji (optional)", table: "UI"))
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
            label: "savings.target_amount".localized(defaultValue: "Target Amount *", table: "UI"),
            currencySymbol: currencySymbol,
            text: $targetAmount,
            accentColor: .accentPrimary,
            useHeroTypography: false,
            focused: $isTargetAmountFocused
        )
    }

    private var currentAmountSection: some View {
        FinancialAmountField(
            label: "savings.current_amount".localized(defaultValue: "Current Amount", table: "UI"),
            currencySymbol: currencySymbol,
            text: $currentAmount,
            accentColor: .accentPrimary,
            useHeroTypography: false,
            focused: $isCurrentAmountFocused
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
                        Text("savings.set_target_date".localized(defaultValue: "Set Target Date", table: "UI"))
                            .bodyStyle()
                        Text("savings.target_date_description".localized(defaultValue: "Track your progress toward a deadline", table: "UI"))
                            .captionStyle()
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: .accentPrimary))
                .onChange(of: hasTargetDate) { _ in
                    clearAllInputFocus()
                }

                if hasTargetDate {
                    DatePicker(
                        "savings.target_date".localized(defaultValue: "Target Date", table: "UI"),
                        selection: $targetDate,
                        in: Date()...,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .padding(Spacing.md)
                    .background(Color.surfaceInset)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
                    .onTapGesture {
                        clearAllInputFocus()
                    }

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
            Text("form.category".localized(defaultValue: "Category", table: "UI"))
                .statusTitleStyle(color: .textSecondary)

            Picker("form.category".localized(defaultValue: "Category", table: "UI"), selection: $selectedCategory) {
                ForEach(categories, id: \.rawValue) { category in
                    Text(category.titleKey.localized(defaultValue: category.defaultTitle, table: "UI")).tag(category.rawValue)
                }
            }
            .pickerStyle(.menu)
            .padding(Spacing.md)
            .background(Color.surfaceInset)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
            .onTapGesture {
                clearAllInputFocus()
            }
        }
    }

    private var categoryCard: some View {
        GlassCard {
            categorySection
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("form.notes_optional".localized(defaultValue: "Notes (optional)", table: "UI"))
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
                String(format: "savings.emoji_picker.accessibility".localized(defaultValue: "Emoji option %@", table: "UI"), emoji)
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
            errorMessage = "savings.error.invalid_target".localized(defaultValue: "Please enter a valid target amount", table: "UI")
            showError = true
            return
        }

        let trimmedName = goalName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else {
            errorMessage = "savings.error.enter_name".localized(defaultValue: "Please enter a goal name", table: "UI")
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
                errorMessage = "savings.error.failed_update".localized(defaultValue: "Failed to update goal", table: "UI")
                showError = true
            }
        } else {
            guard SavingsGoalManager.shared.canCreateAdditionalGoal() else {
                errorMessage = "savings.error.premium_required".localized(
                    defaultValue: "Premium is required to create more than one savings goal.",
                    table: "UI"
                )
                showError = true
                return
            }

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
                errorMessage = "savings.error.failed_create".localized(defaultValue: "Failed to create goal", table: "UI")
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
            errorMessage = "savings.error.failed_delete".localized(defaultValue: "Failed to delete goal", table: "UI")
            showError = true
        }
    }

    private func clearAllInputFocus() {
        focusedField = nil
        isTargetAmountFocused = false
        isCurrentAmountFocused = false
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
