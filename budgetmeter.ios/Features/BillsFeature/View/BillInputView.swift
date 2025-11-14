//
//  BillInputView.swift
//  BudgetMeter
//
//  Created by BudgetMeter Team on 14.11.2025.
//

import SwiftUI

/// Input form for adding or editing a bill
struct BillInputView: View {

    // MARK: - Properties

    let bill: Bill? // nil for add, populated for edit
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?

    // Form fields
    @State private var billName: String = ""
    @State private var amount: String = ""
    @State private var dueDate: Date = Date()
    @State private var isRecurring: Bool = false
    @State private var frequency: Frequency = .monthly
    @State private var selectedCategory: String = "Other"
    @State private var reminderDays: ReminderOption = .threeDays
    @State private var isAutoPay: Bool = false
    @State private var notes: String = ""

    // UI state
    @State private var showDeleteConfirmation = false
    @State private var showError = false
    @State private var errorMessage = ""

    private let currencySymbol = CurrencyHelper.symbol(for: CurrencyHelper.defaultCurrencyCode())

    // MARK: - Enums

    enum Field: Hashable {
        case billName
        case amount
        case notes
    }

    enum Frequency: String, CaseIterable {
        case monthly = "Monthly"
        case yearly = "Yearly"
        case quarterly = "Quarterly"

        var value: String {
            switch self {
            case .monthly: return "monthly"
            case .yearly: return "yearly"
            case .quarterly: return "quarterly"
            }
        }
    }

    enum ReminderOption: Int, CaseIterable {
        case oneDay = 1
        case threeDays = 3
        case sevenDays = 7

        var displayText: String {
            switch self {
            case .oneDay: return "1 day before"
            case .threeDays: return "3 days before"
            case .sevenDays: return "7 days before"
            }
        }
    }

    // MARK: - Computed Properties

    private var isEditMode: Bool {
        bill != nil
    }

    private var title: String {
        isEditMode ? "Edit Bill" : "Add Bill"
    }

    private var saveButtonDisabled: Bool {
        billName.trimmingCharacters(in: .whitespaces).isEmpty ||
        amount.trimmingCharacters(in: .whitespaces).isEmpty ||
        parseAmount(amount) <= 0
    }

    // MARK: - Categories

    private let categories = [
        "Utilities",
        "Housing",
        "Services",
        "Insurance",
        "Transportation",
        "Healthcare",
        "Other"
    ]

    // MARK: - Body

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // Bill Name
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Bill Name *")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.textSecondary)

                        TextField("Electric Bill, Rent, etc.", text: $billName)
                            .textFieldStyle(.plain)
                            .font(.body)
                            .padding(Spacing.md)
                            .background(Color.cardBackground)
                            .cornerRadius(CornerRadius.small)
                            .focused($focusedField, equals: .billName)
                    }

                    // Amount
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Amount *")
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

                    // Due Date
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Due Date *")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.textSecondary)

                        DatePicker(
                            "Due Date",
                            selection: $dueDate,
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .padding(Spacing.md)
                        .background(Color.cardBackground)
                        .cornerRadius(CornerRadius.small)
                    }

                    // Recurring Bill
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Toggle(isOn: $isRecurring) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Recurring Bill")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.textPrimary)

                                Text("Automatically create next bill when paid")
                                    .font(.caption)
                                    .foregroundColor(.textSecondary)
                            }
                        }
                        .toggleStyle(SwitchToggleStyle(tint: .brandProgress))

                        if isRecurring {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Text("Frequency")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.textSecondary)

                                Picker("Frequency", selection: $frequency) {
                                    ForEach(Frequency.allCases, id: \.self) { freq in
                                        Text(freq.rawValue).tag(freq)
                                    }
                                }
                                .pickerStyle(.segmented)
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

                    // AutoPay
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Toggle(isOn: $isAutoPay) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("AutoPay Enabled")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.textPrimary)

                                Text("This bill is automatically paid")
                                    .font(.caption)
                                    .foregroundColor(.textSecondary)
                            }
                        }
                        .toggleStyle(SwitchToggleStyle(tint: .brandProgress))
                    }
                    .padding(Spacing.md)
                    .background(Color.cardBackground)
                    .cornerRadius(CornerRadius.small)

                    // Reminder (only if not autopay)
                    if !isAutoPay {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Remind me")
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
                    Button(action: saveBill) {
                        Text(isEditMode ? "Save Changes" : "Add Bill")
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
                            // Mark as paid/unpaid button
                            if let currentBill = bill {
                                Button(action: togglePaidStatus) {
                                    HStack {
                                        Image(systemName: currentBill.isPaid ? "arrow.uturn.backward" : "checkmark.circle.fill")
                                        Text(currentBill.isPaid ? "Mark as Unpaid" : "Mark as Paid")
                                    }
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(currentBill.isPaid ? .orange : .brandProgress)
                                }
                            }

                            // Delete button
                            Button(action: { showDeleteConfirmation = true }) {
                                HStack {
                                    Image(systemName: "trash")
                                    Text("Delete Bill")
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
            .alert("Delete Bill?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteBill()
                }
            } message: {
                Text("This will permanently delete this bill. This action cannot be undone.")
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
        .onAppear {
            loadBillData()
        }
    }

    // MARK: - Private Methods

    private func loadBillData() {
        guard let bill = bill else { return }

        billName = bill.name ?? ""
        amount = String(format: "%.2f", bill.amount)
        dueDate = bill.dueDate ?? Date()
        isRecurring = bill.isRecurring
        selectedCategory = bill.category ?? "Other"
        isAutoPay = bill.isAutoPay
        notes = bill.notes ?? ""

        if let freq = bill.frequency {
            switch freq.lowercased() {
            case "monthly": frequency = .monthly
            case "yearly": frequency = .yearly
            case "quarterly": frequency = .quarterly
            default: frequency = .monthly
            }
        }

        let days = Int(bill.reminderDaysBefore)
        reminderDays = ReminderOption(rawValue: days) ?? .threeDays
    }

    private func saveBill() {
        guard let amountValue = parseAmount(amount), amountValue > 0 else {
            errorMessage = "Please enter a valid amount"
            showError = true
            return
        }

        let trimmedName = billName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else {
            errorMessage = "Please enter a bill name"
            showError = true
            return
        }

        if let existingBill = bill {
            // Update existing
            let success = BillManager.shared.updateBill(
                id: existingBill.id ?? UUID(),
                name: trimmedName,
                amount: amountValue,
                dueDate: dueDate,
                isRecurring: isRecurring,
                frequency: isRecurring ? frequency.value : nil,
                category: selectedCategory,
                notes: notes.isEmpty ? nil : notes,
                reminderDaysBefore: reminderDays.rawValue,
                isAutoPay: isAutoPay
            )

            if success {
                onSave()
                dismiss()
            } else {
                errorMessage = "Failed to update bill"
                showError = true
            }
        } else {
            // Create new
            let newBill = BillManager.shared.createBill(
                name: trimmedName,
                amount: amountValue,
                dueDate: dueDate,
                isRecurring: isRecurring,
                frequency: isRecurring ? frequency.value : nil,
                category: selectedCategory,
                notes: notes.isEmpty ? nil : notes,
                reminderDaysBefore: reminderDays.rawValue,
                isAutoPay: isAutoPay
            )

            if newBill != nil {
                onSave()
                dismiss()
            } else {
                errorMessage = "Failed to create bill"
                showError = true
            }
        }
    }

    private func togglePaidStatus() {
        guard let bill = bill, let id = bill.id else { return }

        let success: Bool
        if bill.isPaid {
            success = BillManager.shared.markAsUnpaid(id: id)
        } else {
            success = BillManager.shared.markAsPaid(id: id)
        }

        if success {
            onSave()
            dismiss()
        } else {
            errorMessage = "Failed to update bill status"
            showError = true
        }
    }

    private func deleteBill() {
        guard let bill = bill, let id = bill.id else { return }

        let success = BillManager.shared.deleteBill(id: id)

        if success {
            onSave()
            dismiss()
        } else {
            errorMessage = "Failed to delete bill"
            showError = true
        }
    }

    private func parseAmount(_ input: String) -> Double? {
        let cleaned = input.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
        return Double(cleaned)
    }
}

// MARK: - Preview

#Preview("Add Mode") {
    BillInputView(bill: nil, onSave: {
        print("Bill saved")
    })
}
