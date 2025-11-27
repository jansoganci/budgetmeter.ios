//
//  FinancialRowView.swift
//  BudgetMeter
//
//  Design System v2.1 - Financial Row View
//  Full-width row for displaying a category with inline amount
//

import SwiftUI

/// Full-width row for displaying a financial category
/// Used in collapsible sections for Income/Expense pages
struct FinancialRowView: View {

    // MARK: - Properties

    let category: FinancialCategory
    let currencySymbol: String
    let accentColor: Color  // Fallback color (kept for compatibility)
    let onEditTap: () -> Void

    /// Category-specific color from the color palette
    private var categoryColor: Color {
        DataSeedingService.color(for: category)
    }

    // MARK: - Environment

    @Environment(\.sizeCategory) var sizeCategory

    // MARK: - Computed Properties

    private var categoryName: String {
        DataSeedingService.displayName(for: category)
    }

    private var categoryIcon: String {
        DataSeedingService.sfSymbolName(for: category)
    }

    private var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = ","

        let formatted = formatter.string(from: NSNumber(value: category.amount)) ?? "0"
        return "\(currencySymbol)\(formatted)"
    }

    private var hasAmount: Bool {
        category.amount > 0
    }

    private var accessibilityLabel: String {
        if hasAmount {
            return "\(categoryName): \(formattedAmount). Double tap to edit."
        } else {
            return "\(categoryName): No amount set. Double tap to edit."
        }
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Icon with category-specific color
            Image(systemName: categoryIcon)
                .font(.system(size: 20 * sizeCategory.scaleFactor, weight: .medium))
                .foregroundColor(categoryColor)
                .frame(width: 32, height: 32)

            // Category Name
            Text(categoryName)
                .font(.system(size: 16 * sizeCategory.scaleFactor, weight: .regular))
                .foregroundColor(.textPrimary)
                .lineLimit(1)

            Spacer()

            // Amount
            Text(hasAmount ? formattedAmount : "-")
                .font(.system(size: 16 * sizeCategory.scaleFactor, weight: .semibold, design: .rounded))
                .foregroundColor(hasAmount ? .textPrimary : .textSecondary)
                .lineLimit(1)

            // Edit Button
            Button(action: {
                Haptics.light()
                onEditTap()
            }) {
                Image(systemName: "pencil.circle")
                    .font(.system(size: 20 * sizeCategory.scaleFactor, weight: .medium))
                    .foregroundColor(.textSecondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Edit \(categoryName)")
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .frame(minHeight: 56)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Preview

#Preview("Income Rows") {
    VStack(spacing: 0) {
        FinancialRowView(
            category: PreviewHelper.mockIncomeCategory(name: "Salary", amount: 4000),
            currencySymbol: "$",
            accentColor: .brandPositive,
            onEditTap: { print("Edit Salary") }
        )

        Divider().padding(.leading, 56)

        FinancialRowView(
            category: PreviewHelper.mockIncomeCategory(name: "Rental Income", amount: 800),
            currencySymbol: "$",
            accentColor: .brandPositive,
            onEditTap: { print("Edit Rental") }
        )

        Divider().padding(.leading, 56)

        FinancialRowView(
            category: PreviewHelper.mockIncomeCategory(name: "Side Gig", amount: 0),
            currencySymbol: "$",
            accentColor: .brandPositive,
            onEditTap: { print("Edit Side Gig") }
        )
    }
    .background(Color.cardBackground)
    .cornerRadius(CornerRadius.card)
    .padding()
    .background(Color.appBackground)
}

#Preview("Expense Rows") {
    VStack(spacing: 0) {
        FinancialRowView(
            category: PreviewHelper.mockExpenseCategory(name: "Rent", amount: 1500),
            currencySymbol: "€",
            accentColor: .brandExpense,
            onEditTap: { print("Edit Rent") }
        )

        Divider().padding(.leading, 56)

        FinancialRowView(
            category: PreviewHelper.mockExpenseCategory(name: "Groceries", amount: 450),
            currencySymbol: "€",
            accentColor: .brandExpense,
            onEditTap: { print("Edit Groceries") }
        )
    }
    .background(Color.cardBackground)
    .cornerRadius(CornerRadius.card)
    .padding()
    .background(Color.appBackground)
}

#Preview("Dark Mode") {
    VStack(spacing: 0) {
        FinancialRowView(
            category: PreviewHelper.mockIncomeCategory(name: "Salary", amount: 5200),
            currencySymbol: "$",
            accentColor: .brandPositive,
            onEditTap: { }
        )

        Divider().padding(.leading, 56)

        FinancialRowView(
            category: PreviewHelper.mockIncomeCategory(name: "Investments", amount: 350),
            currencySymbol: "$",
            accentColor: .brandPositive,
            onEditTap: { }
        )
    }
    .background(Color.cardBackground)
    .cornerRadius(CornerRadius.card)
    .padding()
    .background(Color.appBackground)
    .preferredColorScheme(.dark)
}

// MARK: - Preview Helper

private enum PreviewHelper {
    static func mockIncomeCategory(name: String, amount: Double) -> FinancialCategory {
        let context = PersistenceService.shared.viewContext
        let category = FinancialCategory(context: context)
        category.id = UUID()
        category.customName = name
        category.amount = amount
        category.type = "income"
        category.frequency = "monthly"
        category.isCustom = true
        category.customIconName = "dollarsign.circle.fill"
        return category
    }

    static func mockExpenseCategory(name: String, amount: Double) -> FinancialCategory {
        let context = PersistenceService.shared.viewContext
        let category = FinancialCategory(context: context)
        category.id = UUID()
        category.customName = name
        category.amount = amount
        category.type = "expense"
        category.frequency = "monthly"
        category.isCustom = true
        category.customIconName = "cart.fill"
        return category
    }
}
