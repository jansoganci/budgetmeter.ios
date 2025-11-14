//
//  MonthComparisonView.swift
//  BudgetMeter
//
//  Phase 1B: Insights Dashboard - Chart Component
//  Created by BudgetMeter Team on 17.09.2025.
//

import SwiftUI
import Charts

/// Bar chart view comparing current month vs previous month
struct MonthComparisonView: View {

    // MARK: - Properties

    let currentMonth: FinancialSnapshot?
    let previousMonth: FinancialSnapshot?
    @State private var selectedMonth: String?

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            headerView

            if currentMonth == nil || previousMonth == nil {
                emptyStateView
            } else {
                VStack(spacing: 20) {
                    // Bar chart
                    barChartView

                    // Comparison stats
                    comparisonStatsView
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Month comparison chart showing this month versus last month's income and expenses")
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.blue)
                    .font(.title3)

                Text("Month Comparison")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                if let change = percentageChange {
                    HStack(spacing: 4) {
                        Image(systemName: change > 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption)
                        Text("\(abs(Int(change)))%")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(change > 0 ? .red : .green)
                }
            }

            Text("Compare this month vs last month")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Bar Chart

    private var barChartView: some View {
        Chart {
            // Previous month
            if let previous = previousMonth {
                BarMark(
                    x: .value("Month", "Last Month"),
                    y: .value("Expenses", previous.totalExpense)
                )
                .foregroundStyle(Color.gray.gradient)
                .cornerRadius(6)

                BarMark(
                    x: .value("Month", "Last Month"),
                    y: .value("Income", previous.totalIncome)
                )
                .foregroundStyle(Color.green.gradient)
                .cornerRadius(6)
            }

            // Current month
            if let current = currentMonth {
                BarMark(
                    x: .value("Month", "This Month"),
                    y: .value("Expenses", current.totalExpense)
                )
                .foregroundStyle(Color.orange.gradient)
                .cornerRadius(6)

                BarMark(
                    x: .value("Month", "This Month"),
                    y: .value("Income", current.totalIncome)
                )
                .foregroundStyle(Color.blue.gradient)
                .cornerRadius(6)
            }
        }
        .frame(height: 250)
        .chartXAxis {
            AxisMarks { value in
                AxisValueLabel {
                    if let month = value.as(String.self) {
                        Text(month)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                    .foregroundStyle(Color.gray.opacity(0.2))
                AxisValueLabel {
                    if let amount = value.as(Double.self) {
                        Text(formatShortAmount(amount))
                            .font(.caption)
                    }
                }
            }
        }
        .chartLegend(position: .top, alignment: .leading) {
            HStack(spacing: 20) {
                // Last month legend
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.gray)
                        .frame(width: 12, height: 12)
                    Text("Last Expenses")
                        .font(.caption)
                }

                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.green)
                        .frame(width: 12, height: 12)
                    Text("Last Income")
                        .font(.caption)
                }

                // This month legend
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.orange)
                        .frame(width: 12, height: 12)
                    Text("This Expenses")
                        .font(.caption)
                }

                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.blue)
                        .frame(width: 12, height: 12)
                    Text("This Income")
                        .font(.caption)
                }
            }
            .padding(.bottom, 8)
        }
    }

    // MARK: - Comparison Stats

    private var comparisonStatsView: some View {
        VStack(spacing: 12) {
            // Expense comparison
            comparisonRow(
                title: "Expenses",
                previousValue: previousMonth?.totalExpense ?? 0,
                currentValue: currentMonth?.totalExpense ?? 0,
                goodWhenLower: true
            )

            Divider()

            // Income comparison
            comparisonRow(
                title: "Income",
                previousValue: previousMonth?.totalIncome ?? 0,
                currentValue: currentMonth?.totalIncome ?? 0,
                goodWhenLower: false
            )

            Divider()

            // Net flow comparison
            comparisonRow(
                title: "Net Flow",
                previousValue: (previousMonth?.totalIncome ?? 0) - (previousMonth?.totalExpense ?? 0),
                currentValue: (currentMonth?.totalIncome ?? 0) - (currentMonth?.totalExpense ?? 0),
                goodWhenLower: false
            )
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private func comparisonRow(title: String, previousValue: Double, currentValue: Double, goodWhenLower: Bool) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)

            Spacer()

            // Previous value
            Text(CurrencyHelper.formatAmount(previousValue))
                .font(.caption)
                .foregroundColor(.secondary)

            Image(systemName: "arrow.right")
                .font(.caption)
                .foregroundColor(.secondary)

            // Current value
            Text(CurrencyHelper.formatAmount(currentValue))
                .font(.subheadline)
                .fontWeight(.semibold)

            // Change indicator
            if previousValue > 0 {
                let change = ((currentValue - previousValue) / previousValue) * 100
                let isImprovement = goodWhenLower ? change < 0 : change > 0

                HStack(spacing: 2) {
                    Image(systemName: change > 0 ? "arrow.up" : "arrow.down")
                        .font(.caption2)
                    Text("\(abs(Int(change)))%")
                        .font(.caption2)
                }
                .foregroundColor(isImprovement ? .green : .red)
                .frame(width: 50, alignment: .trailing)
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar")
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.5))

            Text("Not enough data")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("Add expenses for at least 2 months")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Computed Properties

    private var percentageChange: Double? {
        guard let current = currentMonth,
              let previous = previousMonth,
              previous.totalExpense > 0 else {
            return nil
        }

        return ((current.totalExpense - previous.totalExpense) / previous.totalExpense) * 100
    }

    // MARK: - Helper Methods

    private func formatShortAmount(_ amount: Double) -> String {
        if amount >= 1000 {
            return String(format: "%.1fk", amount / 1000)
        }
        return String(format: "%.0f", amount)
    }
}

// MARK: - Preview

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
}
