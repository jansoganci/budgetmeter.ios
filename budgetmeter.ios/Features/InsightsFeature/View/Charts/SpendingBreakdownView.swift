//
//  SpendingBreakdownView.swift
//  BudgetMeter
//
//  Phase 1B: Insights Dashboard - Chart Component
//  Created by BudgetMeter Team on 17.09.2025.
//

import SwiftUI
import Charts

/// Pie chart view showing spending breakdown by category
struct SpendingBreakdownView: View {

    // MARK: - Properties

    let data: [(category: String, amount: Double, percentage: Double)]
    @State private var selectedCategory: String?

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            headerView

            if data.isEmpty {
                emptyStateView
            } else {
                VStack(spacing: 20) {
                    // Pie chart
                    if #available(iOS 17.0, *) {
                        modernPieChart
                    } else {
                        legacyPieChart
                    }

                    // Legend
                    legendView
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Spending breakdown chart showing your expenses by category")
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "chart.pie.fill")
                    .foregroundColor(.blue)
                    .font(.title3)

                Text("charts.spending_breakdown.title".localized(defaultValue: "Spending Breakdown"))
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                if let total = totalAmount {
                    Text(CurrencyHelper.formatAmount(total))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
            }

            Text("charts.spending_breakdown.subtitle".localized(defaultValue: "Your expenses by category"))
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Modern Pie Chart (iOS 17+)

    @available(iOS 17.0, *)
    private var modernPieChart: some View {
        Chart(Array(data.prefix(5).enumerated()), id: \.offset) { index, item in
            SectorMark(
                angle: .value("Amount", item.amount),
                innerRadius: .ratio(0.5),
                angularInset: 1.5
            )
            .cornerRadius(4)
            .foregroundStyle(categoryColor(for: index))
            .opacity(selectedCategory == nil || selectedCategory == item.category ? 1.0 : 0.3)
        }
        .frame(height: 250)
        .chartAngleSelection(value: $selectedCategory)
        .chartBackground { chartProxy in
            GeometryReader { geometry in
                let frame = geometry[chartProxy.plotFrame!]
                VStack {
                    if let selectedCategory = selectedCategory,
                       let item = data.first(where: { $0.category == selectedCategory }) {
                        Text(DataSeedingService.displayName(for: item.category))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(CurrencyHelper.formatAmount(item.amount))
                            .font(.title2)
                            .fontWeight(.bold)
                        Text(PercentageFormatter.formatInteger(item.percentage))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("charts.spending_breakdown.total".localized(defaultValue: "Total"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(CurrencyHelper.formatAmount(totalAmount ?? 0))
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                }
                .position(x: frame.midX, y: frame.midY)
            }
        }
    }

    // MARK: - Legacy Pie Chart (iOS 16)

    private var legacyPieChart: some View {
        Chart(Array(data.prefix(5).enumerated()), id: \.offset) { index, item in
            SectorMark(
                angle: .value("Amount", item.amount),
                innerRadius: .ratio(0.5),
                angularInset: 1.5
            )
            .cornerRadius(4)
            .foregroundStyle(categoryColor(for: index))
        }
        .frame(height: 250)
    }

    // MARK: - Legend

    private var legendView: some View {
        VStack(spacing: 12) {
            ForEach(Array(data.prefix(5).enumerated()), id: \.offset) { index, item in
                HStack(spacing: 12) {
                    // Color indicator
                    RoundedRectangle(cornerRadius: 4)
                        .fill(categoryColor(for: index))
                        .frame(width: 16, height: 16)

                    // Category name
                    Text(DataSeedingService.displayName(for: item.category))
                        .font(.subheadline)
                        .lineLimit(1)

                    Spacer()

                    // Percentage
                    Text(PercentageFormatter.formatInteger(item.percentage))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 40, alignment: .trailing)

                    // Amount
                    Text(CurrencyHelper.formatAmount(item.amount))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(width: 100, alignment: .trailing)
                }
                .padding(.vertical, 4)
                .onTapGesture {
                    withAnimation {
                        selectedCategory = selectedCategory == item.category ? nil : item.category
                    }
                }
            }

            // Show remaining categories count if more than 5
            if data.count > 5 {
                HStack {
                    Image(systemName: "ellipsis.circle.fill")
                        .foregroundColor(.gray)
                        .font(.caption)

                    Text(String(format: "charts.spending_breakdown.more_categories".localized(defaultValue: "%d more categories"), data.count - 5))
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()
                }
                .padding(.top, 4)
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.pie")
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.5))

            Text("charts.spending_breakdown.empty".localized(defaultValue: "No spending data"))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Computed Properties

    private var totalAmount: Double? {
        guard !data.isEmpty else { return nil }
        return data.reduce(0) { $0 + $1.amount }
    }

    // MARK: - Helper Methods

    private func categoryColor(for index: Int) -> Color {
        let colors: [Color] = [
            .blue,
            .green,
            .orange,
            .purple,
            .pink,
            .cyan,
            .indigo,
            .mint
        ]
        return colors[index % colors.count]
    }
}

// MARK: - Preview

#Preview {
    SpendingBreakdownView(data: [
        ("food", 500, 35),
        ("transport", 300, 21),
        ("entertainment", 200, 14),
        ("utilities", 180, 13),
        ("shopping", 120, 8),
        ("healthcare", 100, 7),
        ("other", 30, 2)
    ])
    .padding()
}
