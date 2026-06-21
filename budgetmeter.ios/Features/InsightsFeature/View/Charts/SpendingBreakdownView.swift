//
//  SpendingBreakdownView.swift
//  BudgetMeter
//
//  Spending breakdown pie chart — ChartCard, restrained category colors.
//

import SwiftUI
import Charts

/// Pie chart showing spending breakdown by category.
struct SpendingBreakdownView: View {

    let data: [(category: String, amount: Double, percentage: Double)]

    @State private var selectedCategory: String?

    private static let chartPalette: [CategoryColor] = [.blue, .teal, .orange, .purple, .green, .pink, .red, .gray]
    private static let donutHeight: CGFloat = 168
    private static let donutInnerRadius: CGFloat = 0.62

    var body: some View {
        ChartCard(
            title: "charts.spending_breakdown.title".localized(defaultValue: "Spending Breakdown"),
            subtitle: "charts.spending_breakdown.subtitle".localized(defaultValue: "Your expenses by category")
        ) {
            if data.isEmpty {
                compactEmptyState
            } else {
                VStack(spacing: Spacing.lg) {
                    if #available(iOS 17.0, *) {
                        modernPieChart
                    } else {
                        legacyPieChart
                    }

                    chartSummaryView

                    legendView
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(
            "charts.spending_breakdown.title".localized(defaultValue: "Spending Breakdown")
        )
    }

    @available(iOS 17.0, *)
    private var modernPieChart: some View {
        Chart(Array(data.prefix(5).enumerated()), id: \.offset) { index, item in
            SectorMark(
                angle: .value("Amount", item.amount),
                innerRadius: .ratio(Self.donutInnerRadius),
                angularInset: 1.5
            )
            .cornerRadius(4)
            .foregroundStyle(categoryColor(for: index))
            .opacity(selectedCategory == nil || selectedCategory == item.category ? 1.0 : 0.35)
        }
        .frame(maxWidth: .infinity)
        .frame(height: Self.donutHeight)
        .chartAngleSelection(value: $selectedCategory)
    }

    private var legacyPieChart: some View {
        Chart(Array(data.prefix(5).enumerated()), id: \.offset) { index, item in
            SectorMark(
                angle: .value("Amount", item.amount),
                innerRadius: .ratio(Self.donutInnerRadius),
                angularInset: 1.5
            )
            .cornerRadius(4)
            .foregroundStyle(categoryColor(for: index))
        }
        .frame(maxWidth: .infinity)
        .frame(height: Self.donutHeight)
    }

    private var chartSummaryView: some View {
        VStack(spacing: Spacing.xs) {
            if let selectedCategory,
               let item = data.first(where: { $0.category == selectedCategory }) {
                Text(DataSeedingService.displayName(for: item.category))
                    .captionStyle(color: .textSecondary)
                Text(CurrencyHelper.formatAmount(item.amount))
                    .metricMediumStyle(color: .textPrimary)
                Text(PercentageFormatter.formatInteger(item.percentage))
                    .captionStyle(color: .textSecondary)
            } else {
                Text("charts.spending_breakdown.total".localized(defaultValue: "Total"))
                    .captionStyle(color: .textSecondary)
                Text(CurrencyHelper.formatAmount(totalAmount ?? 0))
                    .metricMediumStyle(color: .textPrimary)
            }
        }
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.center)
        .padding(.vertical, Spacing.xs)
        .accessibilityElement(children: .combine)
    }

    private var legendView: some View {
        VStack(spacing: Spacing.sm) {
            ChartLegendView(
                items: Array(data.prefix(5).enumerated()).map { index, item in
                    LegendItem(
                        label: DataSeedingService.displayName(for: item.category),
                        color: categoryColor(for: index),
                        value: "\(PercentageFormatter.formatInteger(item.percentage)) · \(CurrencyHelper.formatAmount(item.amount))"
                    )
                },
                columns: 1
            )

            if data.count > 5 {
                Text(
                    String(
                        format: "charts.spending_breakdown.more_categories".localized(defaultValue: "%d more categories"),
                        data.count - 5
                    )
                )
                .captionStyle(color: .textTertiary)
            }
        }
    }

    private var compactEmptyState: some View {
        Text("charts.spending_breakdown.empty".localized(defaultValue: "No spending data"))
            .captionStyle(color: .textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, Spacing.md)
    }

    private var totalAmount: Double? {
        guard !data.isEmpty else { return nil }
        return data.reduce(0) { $0 + $1.amount }
    }

    private func categoryColor(for index: Int) -> Color {
        Self.chartPalette[index % Self.chartPalette.count].color
    }
}

#Preview {
    SpendingBreakdownView(data: [
        ("food", 500, 35),
        ("transport", 300, 21),
        ("entertainment", 200, 14),
        ("utilities", 180, 13),
        ("shopping", 120, 8)
    ])
    .padding()
    .background(Color.appBackground)
}
