//
//  FinancialSummaryCard.swift
//  BudgetMeter
//
//  Design System v2.1 - Financial Summary Card
//  Hero card showing total monthly amount with daily/yearly projections
//

import SwiftUI

/// Type of financial data (income or expense)
enum FinancialType {
    case income
    case expense

    var iconName: String {
        switch self {
        case .income: return "arrow.down.circle.fill"
        case .expense: return "arrow.up.circle.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .income: return .brandPositive
        case .expense: return .brandExpense
        }
    }

    var title: String {
        switch self {
        case .income: return String(localized: "financial.type.income", defaultValue: "Monthly Income")
        case .expense: return String(localized: "financial.type.expense", defaultValue: "Monthly Expenses")
        }
    }
}

/// Hero summary card for Income/Expense pages
/// Shows total monthly amount with daily average and yearly projection
struct FinancialSummaryCard: View {

    // MARK: - Properties

    let totalMonthly: Double
    let dailyAverage: Double
    let yearlyProjection: Double
    let currencySymbol: String
    let type: FinancialType
    var sourcesCount: Int = 0  // Number of active sources (optional)

    // MARK: - Computed Properties

    private var formattedMonthly: String {
        formatAmount(totalMonthly)
    }

    private var formattedDaily: String {
        formatCompact(dailyAverage)
    }

    private var formattedYearly: String {
        formatCompact(yearlyProjection)
    }

    private var accessibilitySummary: String {
        var label = "\(formattedMonthly). Daily average: \(formattedDaily). Yearly projection: \(formattedYearly)"
        if sourcesCount > 0 {
            label += ". \(sourcesCount) active sources."
        }
        return label
    }

    private var metadataText: String? {
        guard sourcesCount > 0 else { return nil }
        let sourcesLabel = sourcesCount == 1
            ? String(localized: "financial.sources.singular", defaultValue: "1 source")
            : String(localized: "financial.sources.plural", defaultValue: "\(sourcesCount) sources")
        return sourcesLabel
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: LayoutSpacing.cardInternalGap) {
            Text(type.title)
                .badgeStyle(color: .textSecondary)

            HStack(spacing: Spacing.sm) {
                Image(systemName: type.iconName)
                    .font(.title3.weight(.semibold))
                    .foregroundColor(type.accentColor)
                    .accessibilityHidden(true)

                Text(formattedMonthly)
                    .paceHeroStyle(color: .textPrimary)
            }

            HStack(spacing: Spacing.md) {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "calendar.day.timeline.left")
                        .font(.caption2)
                        .foregroundColor(.textSecondary)
                        .accessibilityHidden(true)

                    Text("\(formattedDaily)\(String(localized: "ui.units.per_day", defaultValue: "/day"))")
                        .captionStyle(color: .textSecondary)
                }

                Text(String(localized: "ui.bullet.point", defaultValue: "•"))
                    .foregroundColor(.textTertiary)
                    .captionStyle()

                HStack(spacing: Spacing.xs) {
                    Image(systemName: "calendar")
                        .font(.caption2)
                        .foregroundColor(.textSecondary)
                        .accessibilityHidden(true)

                    Text("\(formattedYearly)\(String(localized: "ui.units.per_year", defaultValue: "/year"))")
                        .captionStyle(color: .textSecondary)
                }

                Spacer(minLength: 0)

                if let metadata = metadataText {
                    Text(metadata)
                        .captionStyle(color: .textTertiary)
                }
            }
        }
        .padding(LayoutSpacing.cardPadding)
        .glassSurface()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(type.title)
        .accessibilityValue(accessibilitySummary)
    }

    // MARK: - Helper Methods

    private func formatAmount(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        formatter.groupingSeparator = ","

        let formatted = formatter.string(from: NSNumber(value: value)) ?? "0"
        return "\(currencySymbol)\(formatted)"
    }

    private func formatCompact(_ value: Double) -> String {
        if value >= 10000 {
            let thousands = value / 1000
            return "\(currencySymbol)\(String(format: "%.0f", thousands))K"
        } else if value >= 1000 {
            let thousands = value / 1000
            return "\(currencySymbol)\(String(format: "%.1f", thousands))K"
        } else {
            return "\(currencySymbol)\(String(format: "%.0f", value))"
        }
    }
}

// MARK: - Preview

#Preview("Income Summary") {
    VStack(spacing: Spacing.lg) {
        FinancialSummaryCard(
            totalMonthly: 5200,
            dailyAverage: 171,
            yearlyProjection: 62400,
            currencySymbol: "$",
            type: .income
        )

        FinancialSummaryCard(
            totalMonthly: 3450,
            dailyAverage: 113,
            yearlyProjection: 41400,
            currencySymbol: "€",
            type: .expense
        )
    }
    .padding()
    .background(Color.appBackground)
}

#Preview("Large Numbers") {
    VStack(spacing: Spacing.lg) {
        FinancialSummaryCard(
            totalMonthly: 125000,
            dailyAverage: 4110,
            yearlyProjection: 1500000,
            currencySymbol: "$",
            type: .income
        )

        FinancialSummaryCard(
            totalMonthly: 89500,
            dailyAverage: 2940,
            yearlyProjection: 1074000,
            currencySymbol: "$",
            type: .expense
        )
    }
    .padding()
    .background(Color.appBackground)
}

#Preview("Dark Mode") {
    VStack(spacing: Spacing.lg) {
        FinancialSummaryCard(
            totalMonthly: 5200,
            dailyAverage: 171,
            yearlyProjection: 62400,
            currencySymbol: "$",
            type: .income
        )

        FinancialSummaryCard(
            totalMonthly: 2750,
            dailyAverage: 90,
            yearlyProjection: 33000,
            currencySymbol: "$",
            type: .expense
        )
    }
    .padding()
    .background(Color.appBackground)
    .preferredColorScheme(.dark)
}
