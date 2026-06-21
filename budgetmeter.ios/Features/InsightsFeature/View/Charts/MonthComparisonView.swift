//
//  MonthComparisonView.swift
//  BudgetMeter
//
//  Month comparison bar chart — ChartCard, simplified legend and calm rows.
//

import SwiftUI
import Charts

/// Bar chart comparing current month vs previous month.
struct MonthComparisonView: View {

    let currentMonth: FinancialSnapshot?
    let previousMonth: FinancialSnapshot?

    private var lastMonthLabel: String {
        "insights.chart.last_month".localized(defaultValue: "Last Month")
    }

    private var thisMonthLabel: String {
        "insights.chart.this_month".localized(defaultValue: "This Month")
    }

    var body: some View {
        ChartCard(
            title: "charts.month_comparison.title".localized(defaultValue: "Month Comparison"),
            subtitle: "charts.month_comparison.subtitle".localized(defaultValue: "Compare this month vs last month")
        ) {
            if currentMonth == nil || previousMonth == nil {
                compactEmptyState
            } else {
                VStack(spacing: Spacing.lg) {
                    if let change = percentageChange {
                        HStack {
                            let isExpenseIncrease = change > 0
                            StatusBadge(
                                label: "\(abs(Int(change)))%",
                                style: isExpenseIncrease ? .negative : .positive,
                                iconName: isExpenseIncrease ? "arrow.up.right" : "arrow.down.right"
                            )
                            Spacer()
                        }
                    }

                    barChartView

                    ChartLegendView(
                        items: [
                            LegendItem(
                                label: "charts.comparison.income".localized(defaultValue: "Income"),
                                color: .financialPositive
                            ),
                            LegendItem(
                                label: "charts.comparison.expenses".localized(defaultValue: "Expenses"),
                                color: .financialNegative
                            )
                        ],
                        columns: 2
                    )

                    comparisonStatsView
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(
            "charts.month_comparison.title".localized(defaultValue: "Month Comparison")
        )
    }

    private var barChartView: some View {
        Chart {
            if let previous = previousMonth {
                BarMark(
                    x: .value("Month", lastMonthLabel),
                    y: .value("Income", previous.totalIncome)
                )
                .foregroundStyle(Color.financialPositive.opacity(0.85))
                .cornerRadius(4)

                BarMark(
                    x: .value("Month", lastMonthLabel),
                    y: .value("Expenses", previous.totalExpense)
                )
                .foregroundStyle(Color.financialNegative.opacity(0.55))
                .cornerRadius(4)
            }

            if let current = currentMonth {
                BarMark(
                    x: .value("Month", thisMonthLabel),
                    y: .value("Income", current.totalIncome)
                )
                .foregroundStyle(Color.financialPositive)
                .cornerRadius(4)

                BarMark(
                    x: .value("Month", thisMonthLabel),
                    y: .value("Expenses", current.totalExpense)
                )
                .foregroundStyle(Color.financialNegative.opacity(0.75))
                .cornerRadius(4)
            }
        }
        .frame(height: ChartDimensions.miniChartHeight + 80)
        .chartXAxis {
            AxisMarks { value in
                AxisValueLabel {
                    if let month = value.as(String.self) {
                        Text(month)
                            .font(.caption)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                    .foregroundStyle(Color.chartTrack.opacity(0.6))
                AxisValueLabel {
                    if let amount = value.as(Double.self) {
                        Text(formatShortAmount(amount))
                            .font(.caption)
                    }
                }
            }
        }
    }

    private var comparisonStatsView: some View {
        VStack(spacing: Spacing.md) {
            comparisonRow(
                title: "charts.comparison.expenses".localized(defaultValue: "Expenses"),
                previousValue: previousMonth?.totalExpense ?? 0,
                currentValue: currentMonth?.totalExpense ?? 0,
                goodWhenLower: true
            )

            Divider()

            comparisonRow(
                title: "charts.comparison.income".localized(defaultValue: "Income"),
                previousValue: previousMonth?.totalIncome ?? 0,
                currentValue: currentMonth?.totalIncome ?? 0,
                goodWhenLower: false
            )

            Divider()

            comparisonRow(
                title: "charts.comparison.net_flow".localized(defaultValue: "Net Flow"),
                previousValue: (previousMonth?.totalIncome ?? 0) - (previousMonth?.totalExpense ?? 0),
                currentValue: (currentMonth?.totalIncome ?? 0) - (currentMonth?.totalExpense ?? 0),
                goodWhenLower: false
            )
        }
        .padding(Spacing.sm)
        .background(Color.surfaceInset)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
    }

    private func comparisonRow(
        title: String,
        previousValue: Double,
        currentValue: Double,
        goodWhenLower: Bool
    ) -> some View {
        HStack(spacing: Spacing.sm) {
            Text(title)
                .captionStyle(color: .textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(CurrencyHelper.formatAmount(previousValue))
                .captionStyle()
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Image(systemName: "arrow.right")
                .font(.caption2)
                .foregroundColor(.textTertiary)
                .accessibilityHidden(true)

            Text(CurrencyHelper.formatAmount(currentValue))
                .metricCompactStyle()
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            if previousValue > 0 {
                let change = ((currentValue - previousValue) / previousValue) * 100
                let isImprovement = goodWhenLower ? change < 0 : change > 0

                StatusBadge(
                    label: "\(abs(Int(change)))%",
                    style: isImprovement ? .positive : .negative,
                    iconName: change > 0 ? "arrow.up" : "arrow.down"
                )
            }
        }
    }

    private var compactEmptyState: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("charts.month_comparison.empty.title".localized(defaultValue: "Not enough data"))
                .bodyStyle(color: .textSecondary)
            Text("charts.month_comparison.empty.message".localized(defaultValue: "Add expenses for at least 2 months"))
                .captionStyle(color: .textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, Spacing.md)
    }

    private var percentageChange: Double? {
        guard let current = currentMonth,
              let previous = previousMonth,
              previous.totalExpense > 0 else {
            return nil
        }
        return ((current.totalExpense - previous.totalExpense) / previous.totalExpense) * 100
    }

    private func formatShortAmount(_ amount: Double) -> String {
        if amount >= 1000 {
            return String(format: "%.1fk", amount / 1000)
        }
        return String(format: "%.0f", amount)
    }
}

#Preview {
    MonthComparisonView(
        currentMonth: {
            let snapshot = FinancialSnapshot(context: PersistenceService.shared.viewContext)
            snapshot.totalIncome = 5000
            snapshot.totalExpense = 3500
            snapshot.date = Date()
            return snapshot
        }(),
        previousMonth: {
            let snapshot = FinancialSnapshot(context: PersistenceService.shared.viewContext)
            snapshot.totalIncome = 4800
            snapshot.totalExpense = 3200
            snapshot.date = Calendar.current.date(byAdding: .month, value: -1, to: Date())
            return snapshot
        }()
    )
    .padding()
    .background(Color.appBackground)
}
