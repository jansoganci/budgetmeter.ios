//
//  FinancialSection.swift
//  BudgetMeter
//
//  Design System v2.1 - Financial Section
//  Collapsible section wrapper using DisclosureGroup
//

import SwiftUI

/// Collapsible section for Income/Expense categories
/// Wraps DisclosureGroup with custom styling
struct FinancialSection<Content: View>: View {

    // MARK: - Properties

    let title: String
    let subtitle: String
    let accentColor: Color
    @Binding var isExpanded: Bool
    @ViewBuilder let content: () -> Content

    // MARK: - Environment

    @Environment(\.sizeCategory) var sizeCategory

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Custom Header (replaces DisclosureGroup's default)
            Button(action: {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
                Haptics.light()
            }) {
                HStack(spacing: Spacing.sm) {
                    // Chevron
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12 * sizeCategory.scaleFactor, weight: .semibold))
                        .foregroundColor(accentColor)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))

                    // Title
                    Text(title)
                        .font(.system(size: 15 * sizeCategory.scaleFactor, weight: .semibold))
                        .foregroundColor(.textPrimary)

                    Spacer()

                    // Subtitle (amount)
                    Text(subtitle)
                        .font(.system(size: 15 * sizeCategory.scaleFactor, weight: .semibold, design: .rounded))
                        .foregroundColor(accentColor)
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.md)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(title), \(subtitle)")
            .accessibilityHint(isExpanded ? "Expanded. Double tap to collapse." : "Collapsed. Double tap to expand.")
            .accessibilityAddTraits(.isButton)

            // Content (visible when expanded)
            if isExpanded {
                VStack(spacing: 0) {
                    content()
                }
                .background(Color.cardBackground)
                .cornerRadius(CornerRadius.card)
                .shadow(
                    color: ShadowStyle.small.color,
                    radius: ShadowStyle.small.radius,
                    x: ShadowStyle.small.offset.width,
                    y: ShadowStyle.small.offset.height
                )
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.xs)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// MARK: - Preview

#Preview("Expanded Section") {
    VStack(spacing: Spacing.lg) {
        FinancialSection(
            title: "Monthly Income",
            subtitle: "$4,800",
            accentColor: .brandPositive,
            isExpanded: .constant(true)
        ) {
            VStack(spacing: 0) {
                previewRow(name: "Salary", amount: "$4,000")
                Divider().padding(.leading, 56)
                previewRow(name: "Rental", amount: "$800")
                Divider().padding(.leading, 56)
                previewAddRow()
            }
        }

        FinancialSection(
            title: "Daily Income",
            subtitle: "$50/day",
            accentColor: .brandPositive,
            isExpanded: .constant(false)
        ) {
            EmptyView()
        }

        FinancialSection(
            title: "Yearly Income",
            subtitle: "$5,000/yr",
            accentColor: .brandPositive,
            isExpanded: .constant(false)
        ) {
            EmptyView()
        }
    }
    .padding(.vertical)
    .background(Color.appBackground)
}

#Preview("Expense Sections") {
    VStack(spacing: Spacing.lg) {
        FinancialSection(
            title: "Monthly Expenses",
            subtitle: "$2,450",
            accentColor: .brandExpense,
            isExpanded: .constant(true)
        ) {
            VStack(spacing: 0) {
                previewRow(name: "Rent", amount: "$1,500", color: .brandExpense)
                Divider().padding(.leading, 56)
                previewRow(name: "Groceries", amount: "$450", color: .brandExpense)
                Divider().padding(.leading, 56)
                previewRow(name: "Utilities", amount: "$200", color: .brandExpense)
                Divider().padding(.leading, 56)
                previewAddRow()
            }
        }

        FinancialSection(
            title: "Daily Expenses",
            subtitle: "$25/day",
            accentColor: .brandExpense,
            isExpanded: .constant(false)
        ) {
            EmptyView()
        }
    }
    .padding(.vertical)
    .background(Color.appBackground)
}

#Preview("Dark Mode") {
    VStack(spacing: Spacing.lg) {
        FinancialSection(
            title: "Monthly Income",
            subtitle: "$5,200",
            accentColor: .brandPositive,
            isExpanded: .constant(true)
        ) {
            VStack(spacing: 0) {
                previewRow(name: "Salary", amount: "$5,200")
                Divider().padding(.leading, 56)
                previewAddRow()
            }
        }

        FinancialSection(
            title: "Yearly Income",
            subtitle: "$10K/yr",
            accentColor: .brandPositive,
            isExpanded: .constant(false)
        ) {
            EmptyView()
        }
    }
    .padding(.vertical)
    .background(Color.appBackground)
    .preferredColorScheme(.dark)
}

// MARK: - Preview Helpers

@ViewBuilder
private func previewRow(name: String, amount: String, color: Color = .brandPositive) -> some View {
    HStack(spacing: Spacing.md) {
        Image(systemName: "dollarsign.circle.fill")
            .font(.system(size: 20, weight: .medium))
            .foregroundColor(color)
            .frame(width: 32, height: 32)

        Text(name)
            .font(.system(size: 16, weight: .regular))
            .foregroundColor(.textPrimary)

        Spacer()

        Text(amount)
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .foregroundColor(.textPrimary)

        Image(systemName: "pencil.circle")
            .font(.system(size: 20, weight: .medium))
            .foregroundColor(.textSecondary)
    }
    .padding(.horizontal, Spacing.md)
    .padding(.vertical, Spacing.sm)
    .frame(minHeight: 56)
}

@ViewBuilder
private func previewAddRow() -> some View {
    HStack(spacing: Spacing.md) {
        Image(systemName: "plus.circle.fill")
            .font(.system(size: 20, weight: .medium))
            .foregroundColor(.brandProgress)
            .frame(width: 32, height: 32)

        Text("ui.add_monthly_income".localized(defaultValue: "Add monthly income"))
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.brandProgress)

        Spacer()
    }
    .padding(.horizontal, Spacing.md)
    .padding(.vertical, Spacing.sm)
    .frame(minHeight: 56)
}
