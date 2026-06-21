//
//  ChartLegendView.swift
//  BudgetMeter
//
//  Phase 1B: Insights Dashboard - Reusable Component
//  Created by BudgetMeter Team on 17.09.2025.
//

import SwiftUI

/// Reusable legend component for charts
struct ChartLegendView: View {

    // MARK: - Properties

    let items: [LegendItem]
    let columns: Int

    // MARK: - Initialization

    init(items: [LegendItem], columns: Int = 2) {
        self.items = items
        self.columns = columns
    }

    // MARK: - Body

    var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: columns),
            spacing: 12
        ) {
            ForEach(items) { item in
                legendRow(for: item)
            }
        }
    }

    // MARK: - Legend Row

    private func legendRow(for item: LegendItem) -> some View {
        HStack(spacing: 8) {
            // Color indicator
            RoundedRectangle(cornerRadius: item.shape == .circle ? 6 : 3)
                .fill(item.color)
                .frame(width: 12, height: 12)

            // Label
            Text(item.label)
                .captionStyle(color: .textPrimary)
                .lineLimit(1)

            Spacer(minLength: 0)

            // Optional value
            if let value = item.value {
                Text(value)
                    .captionStyle()
            }
        }
    }
}

// MARK: - Legend Item

struct LegendItem: Identifiable {
    let id = UUID()
    let label: String
    let color: Color
    let value: String?
    let shape: Shape

    enum Shape {
        case rectangle
        case circle
    }

    init(label: String, color: Color, value: String? = nil, shape: Shape = .rectangle) {
        self.label = label
        self.color = color
        self.value = value
        self.shape = shape
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 24) {
        // Example 1: Simple legend
        ChartLegendView(items: [
            LegendItem(label: "Income", color: .financialPositive),
            LegendItem(label: "Expenses", color: .financialNegative),
            LegendItem(label: "Savings", color: .brandProgress),
            LegendItem(label: "Investments", color: CategoryColor.purple.color)
        ])
        .padding()
        .background(Color.surfaceInset)
        .cornerRadius(12)

        // Example 2: Legend with values
        ChartLegendView(items: [
            LegendItem(label: "Food", color: CategoryColor.orange.color, value: "$500"),
            LegendItem(label: "Transport", color: CategoryColor.blue.color, value: "$300"),
            LegendItem(label: "Entertainment", color: CategoryColor.purple.color, value: "$200"),
            LegendItem(label: "Utilities", color: CategoryColor.green.color, value: "$150")
        ])
        .padding()
        .background(Color.surfaceInset)
        .cornerRadius(12)

        // Example 3: Single column with circles
        ChartLegendView(
            items: [
                LegendItem(label: "Positive", color: .financialPositive, value: "15 days", shape: .circle),
                LegendItem(label: "Negative", color: .financialNegative, value: "5 days", shape: .circle),
                LegendItem(label: "Neutral", color: .financialCaution, value: "10 days", shape: .circle)
            ],
            columns: 1
        )
        .padding()
        .background(Color.surfaceInset)
        .cornerRadius(12)
    }
    .padding()
}
