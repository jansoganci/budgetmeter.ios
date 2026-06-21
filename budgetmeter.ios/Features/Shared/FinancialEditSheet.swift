//
//  FinancialEditSheet.swift
//  BudgetMeter
//
//  Sheet for editing a financial category (amount + delete option) — v2 input flow.
//

import SwiftUI

/// Sheet for editing a financial category
struct FinancialEditSheet: View {

    let category: FinancialCategory
    let currencySymbol: String
    let accentColor: Color
    let onSave: (Double) -> Void
    let onDelete: (() -> Void)?
    var onColorChange: ((CategoryColor) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @StateObject private var premiumManager = PremiumManager.shared

    @State private var amountText: String = ""
    @State private var selectedColor: CategoryColor = .gray
    @State private var showDeleteConfirmation = false
    @FocusState private var isAmountFocused: Bool

    private var categoryName: String {
        DataSeedingService.displayName(for: category)
    }

    private var categoryIcon: String {
        DataSeedingService.sfSymbolName(for: category)
    }

    private var frequencyLabel: String {
        if FinancialCategoryWriteSupport.isOneTimeDisplayCategory(category) {
            return String(localized: "financial.entry.one_time", defaultValue: "One-Time")
        }
        switch category.frequency {
        case "daily": return String(localized: "frequency.daily", defaultValue: "Daily")
        case "weekly": return String(localized: "frequency.weekly", defaultValue: "Weekly")
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
        category.isCustom && premiumManager.hasAccess(to: BudgetMeterCapability.customCategories)
    }

    private var currentCategoryColor: Color {
        DataSeedingService.color(for: category)
    }

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

    var body: some View {
        NavigationView {
            ZStack {
                AppBackground()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: LayoutSpacing.sectionGap) {
                        categoryInfoSection

                        GlassCard {
                            FinancialAmountField(
                                label: String(localized: "financial.edit.amount", defaultValue: "Amount"),
                                currencySymbol: currencySymbol,
                                text: $amountText,
                                accentColor: accentColor,
                                focused: $isAmountFocused
                            )
                        }

                        if category.isCustom {
                            colorPickerSection
                        }

                        if canDelete {
                            deleteSection
                        }

                        PrimaryCTAButton(
                            title: String(localized: "button.save", defaultValue: "Save"),
                            isDisabled: saveButtonDisabled,
                            action: saveChanges
                        )
                    }
                    .padding(.horizontal, LayoutSpacing.screenPadding)
                    .padding(.vertical, Spacing.md)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(String(localized: "button.cancel", defaultValue: "Cancel")) {
                        dismiss()
                    }
                }

                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(String(localized: "button.done", defaultValue: "Done")) {
                        isAmountFocused = false
                    }
                    .foregroundColor(accentColor)
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDragIndicator(.visible)
        .onAppear {
            loadData()
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

    private var categoryInfoSection: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: categoryIcon)
                .font(.system(size: 48, weight: .medium))
                .foregroundColor(category.isCustom ? selectedColor.color : currentCategoryColor)

            Text(categoryName)
                .sectionTitleStyle()

            Text(frequencyLabel)
                .badgeStyle(color: .white)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(category.isCustom ? selectedColor.color : currentCategoryColor)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.md)
    }

    private var colorPickerSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeader(title: String(localized: "financial.edit.color", defaultValue: "Color")) {
                if !premiumManager.hasAccess(to: BudgetMeterCapability.customCategories) {
                    PremiumBadge(locked: true)
                }
            }

            GlassCard {
                ColorPickerGrid(
                    selectedColor: $selectedColor,
                    isPremium: premiumManager.hasAccess(to: BudgetMeterCapability.customCategories)
                )
            }
        }
    }

    private var deleteSection: some View {
        Button(action: { showDeleteConfirmation = true }) {
            HStack {
                Image(systemName: "trash")
                Text(String(localized: "financial.delete.button", defaultValue: "Delete Category"))
            }
            .bodyStyle(color: .financialNegative)
            .frame(maxWidth: .infinity)
            .padding(Spacing.md)
        }
        .buttonStyle(.plain)
    }

    private func loadData() {
        if category.amount > 0 {
            amountText = formatAmount(category.amount)
        } else {
            amountText = ""
        }

        if category.isCustom {
            selectedColor = DataSeedingService.categoryColor(for: category)
        }
    }

    private func saveChanges() {
        let amount = parseAmount(amountText) ?? 0
        onSave(amount)

        if category.isCustom && premiumManager.hasAccess(to: BudgetMeterCapability.customCategories) {
            onColorChange?(selectedColor)
        }

        Haptics.medium()
        dismiss()
    }

    private func deleteCategory() {
        onDelete?()
        dismiss()
    }

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

#Preview("Income Edit") {
    FinancialEditSheet(
        category: PreviewHelper.mockCategory(name: "Salary", amount: 4000, type: "income"),
        currencySymbol: "$",
        accentColor: .brandPositive,
        onSave: { _ in },
        onDelete: nil
    )
}

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
}
