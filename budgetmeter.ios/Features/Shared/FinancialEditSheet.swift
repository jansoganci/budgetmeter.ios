//
//  FinancialEditSheet.swift
//  BudgetMeter
//
//  Sheet for editing a financial category (amount + delete option)
//

import SwiftUI

/// Sheet for editing a financial category
/// Shows amount input, category info, and delete button for custom categories
struct FinancialEditSheet: View {

    // MARK: - Properties

    let category: FinancialCategory
    let currencySymbol: String
    let accentColor: Color
    let onSave: (Double) -> Void
    let onDelete: (() -> Void)?
    var onColorChange: ((CategoryColor) -> Void)?  // Optional callback for color changes

    @Environment(\.dismiss) private var dismiss
    @StateObject private var premiumManager = PremiumManager.shared

    // MARK: - State

    @State private var amountText: String = ""
    @State private var selectedColor: CategoryColor = .gray
    @State private var showDeleteConfirmation = false
    @FocusState private var isAmountFocused: Bool

    // MARK: - Computed Properties

    private var categoryName: String {
        DataSeedingService.displayName(for: category)
    }

    private var categoryIcon: String {
        DataSeedingService.sfSymbolName(for: category)
    }

    private var frequencyLabel: String {
        switch category.frequency {
        case "daily": return String(localized: "frequency.daily", defaultValue: "Daily")
        case "monthly": return String(localized: "frequency.monthly", defaultValue: "Monthly")
        case "yearly": return String(localized: "frequency.yearly", defaultValue: "Yearly")
        default: return category.frequency?.capitalized ?? "Monthly"
        }
    }

    private var title: String {
        String(localized: "financial.edit.title", defaultValue: "Edit \(categoryName)")
    }

    private var saveButtonDisabled: Bool {
        guard let amount = parseAmount(amountText) else { return true }
        return amount < 0
    }

    private var canDelete: Bool {
        category.isCustom && onDelete != nil
    }

    private var canEditColor: Bool {
        category.isCustom && premiumManager.isPremium
    }

    private var currentCategoryColor: Color {
        DataSeedingService.color(for: category)
    }

    // MARK: - Initialization

    init(
        category: FinancialCategory,
        currencySymbol: String,
        accentColor: Color,
        onSave: @escaping (Double) -> Void,
        onDelete: (() -> Void)? = nil,
        onColorChange: ((CategoryColor) -> Void)? = nil
    ) {
        self.category = category
        self.currencySymbol = currencySymbol
        self.accentColor = accentColor
        self.onSave = onSave
        self.onDelete = onDelete
        self.onColorChange = onColorChange
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // Category Info
                    categoryInfoSection

                    // Amount Input
                    amountInputSection

                    // Color Picker (custom categories + premium only)
                    if category.isCustom {
                        colorPickerSection
                    }

                    // Delete Button (custom categories only)
                    if canDelete {
                        deleteSection
                    }
                }
                .padding(Spacing.lg)
            }
            .background(Color.appBackground)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(String(localized: "button.cancel", defaultValue: "Cancel")) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(String(localized: "button.save", defaultValue: "Save")) {
                        saveChanges()
                    }
                    .fontWeight(.semibold)
                    .disabled(saveButtonDisabled)
                }

                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(String(localized: "button.done", defaultValue: "Done")) {
                        isAmountFocused = false
                    }
                    .foregroundColor(.brandProgress)
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            loadData()
            // Auto-focus after short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isAmountFocused = true
            }
        }
        .alert(
            String(localized: "financial.delete.title", defaultValue: "Delete Category?"),
            isPresented: $showDeleteConfirmation
        ) {
            Button(String(localized: "button.cancel", defaultValue: "Cancel"), role: .cancel) { }
            Button(String(localized: "button.delete", defaultValue: "Delete"), role: .destructive) {
                deleteCategory()
            }
        } message: {
            Text(String(localized: "financial.delete.message", defaultValue: "This will permanently delete \"\(categoryName)\". This action cannot be undone."))
        }
    }

    // MARK: - Sections

    private var categoryInfoSection: some View {
        VStack(spacing: Spacing.md) {
            // Icon - use selected color for custom categories
            Image(systemName: categoryIcon)
                .font(.system(size: 48, weight: .medium))
                .foregroundColor(category.isCustom ? selectedColor.color : currentCategoryColor)

            // Name
            Text(categoryName)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.textPrimary)

            // Frequency Badge
            Text(frequencyLabel)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(category.isCustom ? selectedColor.color : currentCategoryColor)
                .cornerRadius(CornerRadius.small)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.lg)
    }

    private var amountInputSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(String(localized: "financial.edit.amount", defaultValue: "Amount"))
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.textSecondary)

            HStack(spacing: Spacing.sm) {
                Text(currencySymbol)
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundColor(.textSecondary)

                TextField("0", text: $amountText)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)
                    .focused($isAmountFocused)
                    .multilineTextAlignment(.leading)
            }
            .padding(Spacing.lg)
            .background(Color.cardBackground)
            .cornerRadius(CornerRadius.card)
        }
    }

    private var colorPickerSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text(String(localized: "financial.edit.color", defaultValue: "Color"))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.textSecondary)

                if !premiumManager.isPremium {
                    Text(String(localized: "premium.badge", defaultValue: "Premium"))
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.brandProgress)
                        .cornerRadius(4)
                }
            }

            ColorPickerGrid(
                selectedColor: $selectedColor,
                isPremium: premiumManager.isPremium
            )
            .padding(Spacing.md)
            .background(Color.cardBackground)
            .cornerRadius(CornerRadius.card)
        }
    }

    private var deleteSection: some View {
        Button(action: {
            showDeleteConfirmation = true
        }) {
            HStack {
                Image(systemName: "trash")
                Text(String(localized: "financial.delete.button", defaultValue: "Delete Category"))
            }
            .font(.body)
            .fontWeight(.medium)
            .foregroundColor(.red)
            .frame(maxWidth: .infinity)
            .padding(Spacing.md)
        }
    }

    // MARK: - Actions

    private func loadData() {
        if category.amount > 0 {
            amountText = formatAmount(category.amount)
        } else {
            amountText = ""
        }

        // Load current color for custom categories
        if category.isCustom {
            selectedColor = DataSeedingService.categoryColor(for: category)
        }
    }

    private func saveChanges() {
        let amount = parseAmount(amountText) ?? 0
        onSave(amount)

        // Save color change for custom categories (premium only)
        if category.isCustom && premiumManager.isPremium {
            onColorChange?(selectedColor)
        }

        Haptics.medium()
        dismiss()
    }

    private func deleteCategory() {
        onDelete?()
        dismiss()
    }

    // MARK: - Helpers

    private func formatAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: amount)) ?? "0"
    }

    private func parseAmount(_ input: String) -> Double? {
        let cleaned = input.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
        if cleaned.isEmpty { return 0 }
        return Double(cleaned)
    }
}

// MARK: - Preview

#Preview("Income Edit") {
    FinancialEditSheet(
        category: PreviewHelper.mockCategory(name: "Salary", amount: 4000, type: "income"),
        currencySymbol: "$",
        accentColor: .brandPositive,
        onSave: { amount in print("Save: \(amount)") },
        onDelete: nil  // Predefined category
    )
}

#Preview("Custom Category (Deletable)") {
    FinancialEditSheet(
        category: PreviewHelper.mockCustomCategory(name: "Side Gig", amount: 250, type: "income"),
        currencySymbol: "$",
        accentColor: .brandPositive,
        onSave: { amount in print("Save: \(amount)") },
        onDelete: { print("Delete") }
    )
}

#Preview("Expense Edit") {
    FinancialEditSheet(
        category: PreviewHelper.mockCategory(name: "Rent", amount: 1500, type: "expense"),
        currencySymbol: "€",
        accentColor: .brandExpense,
        onSave: { amount in print("Save: \(amount)") },
        onDelete: nil
    )
}

// MARK: - Preview Helper

private enum PreviewHelper {
    static func mockCategory(name: String, amount: Double, type: String) -> FinancialCategory {
        let context = PersistenceService.shared.viewContext
        let category = FinancialCategory(context: context)
        category.id = UUID()
        category.uniqueID = "preview_\(name.lowercased())"
        category.amount = amount
        category.type = type
        category.frequency = "monthly"
        category.isCustom = false
        category.customIconName = type == "income" ? "dollarsign.circle.fill" : "cart.fill"
        return category
    }

    static func mockCustomCategory(name: String, amount: Double, type: String) -> FinancialCategory {
        let context = PersistenceService.shared.viewContext
        let category = FinancialCategory(context: context)
        category.id = UUID()
        category.customName = name
        category.amount = amount
        category.type = type
        category.frequency = "monthly"
        category.isCustom = true
        category.customIconName = "star.circle.fill"
        return category
    }
}
