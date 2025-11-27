//
//  SubscriptionInputView.swift
//  BudgetMeter
//
//  Created by BudgetMeter Team on 14.11.2025.
//

import SwiftUI

/// Input form for adding or editing a subscription
struct SubscriptionInputView: View {

    // MARK: - Properties

    let subscription: Subscription? // nil for add, populated for edit
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?

    // Form fields
    @State private var serviceName: String = ""
    @State private var amount: String = ""
    @State private var billingCycle: BillingCycle = .monthly
    @State private var firstBillDate: Date = Date()
    @State private var selectedCategory: String = "Other"
    @State private var reminderDays: ReminderOption = .threeDays
    @State private var notes: String = ""

    // UI state
    @State private var showDeleteConfirmation = false
    @State private var showError = false
    @State private var errorMessage = ""

    private var currencySymbol: String {
        CurrencyHelper.symbol(for: CurrencyHelper.currentCurrencyCode())
    }

    // MARK: - Enums

    enum Field: Hashable {
        case serviceName
        case amount
        case notes
    }

    enum BillingCycle: String, CaseIterable {
        case monthly = "Monthly"
        case yearly = "Yearly"
        case weekly = "Weekly"

        var value: String {
            switch self {
            case .monthly: return "monthly"
            case .yearly: return "yearly"
            case .weekly: return "weekly"
            }
        }
    }

    enum ReminderOption: Int, CaseIterable {
        case oneDay = 1
        case threeDays = 3
        case sevenDays = 7

        var displayText: String {
            switch self {
            case .oneDay: return "bill.reminder.one_day".localized(defaultValue: "1 day before")
            case .threeDays: return "bill.reminder.three_days".localized(defaultValue: "3 days before")
            case .sevenDays: return "bill.reminder.seven_days".localized(defaultValue: "7 days before")
            }
        }
    }

    // MARK: - Computed Properties

    private var isEditMode: Bool {
        subscription != nil
    }

    private var title: String {
        isEditMode ? "subscription.title.edit".localized(defaultValue: "Edit Subscription") : "subscription.title.add".localized(defaultValue: "Add Subscription")
    }

    private var saveButtonDisabled: Bool {
        serviceName.trimmingCharacters(in: .whitespaces).isEmpty ||
        amount.trimmingCharacters(in: .whitespaces).isEmpty ||
        (parseAmount(amount) ?? 0) <= 0
    }

    private var nextRenewalText: String {
        let nextDate = calculateNextRenewal()
        return String(format: "subscription.next_renewal".localized(defaultValue: "Next renewal: %@"), DateFormattingHelper.shared.formatMedium(nextDate))
    }

    // MARK: - Categories

    private let categories = [
        "Streaming",
        "Software",
        "Fitness",
        "Utilities",
        "Entertainment",
        "News",
        "Other"
    ]

    // MARK: - Body

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // Service Name
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("subscription.service_name".localized(defaultValue: "Service Name *"))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.textSecondary)

                        TextField("subscription.service_name_placeholder".localized(defaultValue: "Netflix, Spotify, etc."), text: $serviceName)
                            .textFieldStyle(.plain)
                            .font(.body)
                            .padding(Spacing.md)
                            .background(Color.cardBackground)
                            .cornerRadius(CornerRadius.small)
                            .focused($focusedField, equals: .serviceName)
                    }

                    // Amount
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("form.amount".localized(defaultValue: "Amount *"))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.textSecondary)

                        HStack(spacing: Spacing.sm) {
                            Text(currencySymbol)
                                .font(.title3)
                                .foregroundColor(.textSecondary)

                            TextField("0.00", text: $amount)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.plain)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .focused($focusedField, equals: .amount)
                        }
                        .padding(Spacing.md)
                        .background(Color.cardBackground)
                        .cornerRadius(CornerRadius.small)
                    }

                    // Billing Cycle
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("subscription.billing_cycle".localized(defaultValue: "How often? *"))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.textSecondary)

                        Picker("Billing Cycle", selection: $billingCycle) {
                            ForEach(BillingCycle.allCases, id: \.self) { cycle in
                                Text(cycle.rawValue).tag(cycle)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    // First Payment Date
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("subscription.first_payment_date".localized(defaultValue: "First payment date *"))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.textSecondary)

                        DatePicker(
                            "subscription.first_payment_date".localized(defaultValue: "First payment date"),
                            selection: $firstBillDate,
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .padding(Spacing.md)
                        .background(Color.cardBackground)
                        .cornerRadius(CornerRadius.small)

                        Text(nextRenewalText)
                            .font(.caption)
                            .foregroundColor(.brandProgress)
                    }

                    // Category
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("form.category".localized(defaultValue: "Category"))
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

                    // Reminder
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("bill.remind_me".localized(defaultValue: "Remind me"))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.textSecondary)

                        Picker("Reminder", selection: $reminderDays) {
                            ForEach(ReminderOption.allCases, id: \.self) { option in
                                Text(option.displayText).tag(option)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    // Notes
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("form.notes_optional".localized(defaultValue: "Notes (optional)"))
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
                    Button(action: saveSubscription) {
                        Text(isEditMode ? "form.save_changes".localized(defaultValue: "Save Changes") : "subscription.title.add".localized(defaultValue: "Add Subscription"))
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
                            // Pause button
                            Button(action: pauseSubscription) {
                                HStack {
                                    Image(systemName: subscription?.isPaused == true ? "play.fill" : "pause.fill")
                                    Text(subscription?.isPaused == true ? "subscription.resume".localized(defaultValue: "Resume Subscription") : "subscription.pause".localized(defaultValue: "Pause Subscription"))
                                }
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.orange)
                            }

                            // Delete button
                            Button(action: { showDeleteConfirmation = true }) {
                                HStack {
                                    Image(systemName: "trash")
                                    Text("subscription.delete".localized(defaultValue: "Delete Subscription"))
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
                    Button("form.cancel".localized(defaultValue: "Cancel")) {
                        dismiss()
                    }
                }

                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("form.done".localized(defaultValue: "Done")) {
                        focusedField = nil
                    }
                    .foregroundColor(.brandProgress)
                    .fontWeight(.semibold)
                }
            }
            .alert("subscription.delete_confirm_title".localized(defaultValue: "Delete Subscription?"), isPresented: $showDeleteConfirmation) {
                Button("form.cancel".localized(defaultValue: "Cancel"), role: .cancel) { }
                Button("subscription.delete".localized(defaultValue: "Delete Subscription"), role: .destructive) {
                    deleteSubscription()
                }
            } message: {
                Text("subscription.delete_confirm_message".localized(defaultValue: "This will permanently delete this subscription. This action cannot be undone."))
            }
            .alert("alert.error.title".localized(defaultValue: "Error"), isPresented: $showError) {
                Button("alert.ok".localized(defaultValue: "OK"), role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
        .onAppear {
            loadSubscriptionData()
        }
    }

    // MARK: - Private Methods

    private func loadSubscriptionData() {
        guard let subscription = subscription else { return }

        serviceName = subscription.name ?? ""
        amount = CurrencyHelper.formatForTextField(subscription.amount)

        if let cycle = subscription.billingCycle {
            switch cycle {
            case "monthly": billingCycle = .monthly
            case "yearly": billingCycle = .yearly
            case "weekly": billingCycle = .weekly
            default: billingCycle = .monthly
            }
        }

        firstBillDate = subscription.firstBillDate ?? Date()
        selectedCategory = subscription.category ?? "Other"

        let days = Int(subscription.reminderDaysBefore)
        reminderDays = ReminderOption(rawValue: days) ?? .threeDays

        notes = subscription.notes ?? ""
    }

    private func saveSubscription() {
        guard let amountValue = parseAmount(amount), amountValue > 0 else {
            errorMessage = "form.error.invalid_amount".localized(defaultValue: "Please enter a valid amount")
            showError = true
            return
        }

        let trimmedName = serviceName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else {
            errorMessage = "subscription.error.enter_name".localized(defaultValue: "Please enter a service name")
            showError = true
            return
        }

        if let existingSubscription = subscription {
            // Update existing
            guard let subscriptionId = existingSubscription.id else {
                errorMessage = "Invalid subscription ID. Cannot update subscription."
                showError = true
                return
            }

            let success = SubscriptionManager.shared.updateSubscription(
                id: subscriptionId,
                name: trimmedName,
                amount: amountValue,
                billingCycle: billingCycle.value,
                category: selectedCategory,
                notes: notes.isEmpty ? nil : notes,
                reminderDaysBefore: reminderDays.rawValue
            )

            if success {
                onSave()
                dismiss()
            } else {
                errorMessage = "subscription.error.failed_update".localized(defaultValue: "Failed to update subscription")
                showError = true
            }
        } else {
            // Create new
            let newSubscription = SubscriptionManager.shared.createSubscription(
                name: trimmedName,
                amount: amountValue,
                billingCycle: billingCycle.value,
                firstBillDate: firstBillDate,
                category: selectedCategory,
                notes: notes.isEmpty ? nil : notes,
                reminderDaysBefore: reminderDays.rawValue
            )

            if newSubscription != nil {
                onSave()
                dismiss()
            } else {
                errorMessage = "subscription.error.failed_create".localized(defaultValue: "Failed to create subscription")
                showError = true
            }
        }
    }

    private func pauseSubscription() {
        guard let subscription = subscription, let id = subscription.id else { return }

        let success: Bool
        if subscription.isPaused {
            success = SubscriptionManager.shared.resumeSubscription(id: id)
        } else {
            success = SubscriptionManager.shared.pauseSubscription(id: id)
        }

        if success {
            onSave()
            dismiss()
        } else {
            let action = subscription.isPaused ? "subscription.resume".localized(defaultValue: "resume") : "subscription.pause".localized(defaultValue: "pause")
            errorMessage = String(format: "Failed to %@ subscription", action)
            showError = true
        }
    }

    private func deleteSubscription() {
        guard let subscription = subscription, let id = subscription.id else { return }

        let success = SubscriptionManager.shared.deleteSubscription(id: id)

        if success {
            onSave()
            dismiss()
        } else {
            errorMessage = "subscription.error.failed_delete".localized(defaultValue: "Failed to delete subscription")
            showError = true
        }
    }

    private func parseAmount(_ input: String) -> Double? {
        let cleaned = input.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
        return Double(cleaned)
    }

    private func calculateNextRenewal() -> Date {
        let calendar = Calendar.current
        switch billingCycle {
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: firstBillDate) ?? firstBillDate
        case .yearly:
            return calendar.date(byAdding: .year, value: 1, to: firstBillDate) ?? firstBillDate
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: firstBillDate) ?? firstBillDate
        }
    }
}

// MARK: - Preview

#Preview("Add Mode") {
    SubscriptionInputView(subscription: nil, onSave: {
        print("Subscription saved")
    })
}
