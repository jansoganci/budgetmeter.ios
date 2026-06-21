//
//  MiniBarChart.swift
//  BudgetMeter
//
//  Design System v2.0 - Mini Bar Chart (Sparkline)
//  Compact bar chart for interval metric cards
//

import SwiftUI

/// Mini bar chart component for displaying sparkline data
/// Height: 60pt, animated bars with staggered delay
struct MiniBarChart: View {

    // MARK: - Properties

    /// Data values to display
    let data: [Double]

    /// Whether to animate bars on appear
    let animated: Bool

    /// Color for bars (default: chartTrack)
    let barColor: Color

    // MARK: - State

    @State private var animationTrigger = false
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    // MARK: - Initialization

    init(
        data: [Double],
        animated: Bool = true,
        barColor: Color = .chartTrack
    ) {
        self.data = data
        self.animated = animated
        self.barColor = barColor
    }

    // MARK: - Body

    var body: some View {
        HStack(alignment: .bottom, spacing: ChartDimensions.barSpacing) {
            ForEach(Array(data.enumerated()), id: \.offset) { index, value in
                RoundedRectangle(
                    cornerRadius: CornerRadius.chartBar,
                    style: .continuous
                )
                .fill(barColor)
                .frame(
                    width: ChartDimensions.barWidth,
                    height: animated ? (animationTrigger ? normalizedHeight(value) : 0) : normalizedHeight(value)
                )
                .animation(
                    animated && !reduceMotion
                        ? AnimationCurve.chartSpring.delay(Double(index) * AnimationCurve.staggerDelay)
                        : .none,
                    value: animationTrigger
                )
            }
        }
        .frame(height: ChartDimensions.miniChartHeight)
        .onAppear {
            if animated && !reduceMotion {
                // Slight delay before triggering animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    animationTrigger = true
                }
            } else {
                animationTrigger = true
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityDescription)
    }

    // MARK: - Helper Methods

    /// Normalizes value to fit within chart height
    private func normalizedHeight(_ value: Double) -> CGFloat {
        guard let maxValue = data.max(), maxValue > 0 else {
            return 4 // Minimum height for empty data
        }

        let normalized = value / maxValue
        let height = normalized * ChartDimensions.miniChartHeight

        // Minimum height of 4pt for visibility
        return max(height, 4)
    }

    /// Accessibility description of chart data
    private var accessibilityDescription: String {
        guard !data.isEmpty else {
            return "No data available"
        }

        let trend: String
        if let first = data.first, let last = data.last {
            if last > first {
                trend = "increasing trend"
            } else if last < first {
                trend = "decreasing trend"
            } else {
                trend = "stable trend"
            }
        } else {
            trend = "data"
        }

        return "Chart showing \(trend) with \(data.count) data points"
    }
}

// MARK: - Preview

#Preview("Increasing Trend") {
    VStack(spacing: 24) {
        // Increasing trend
        VStack(alignment: .leading, spacing: 8) {
            Text("Increasing Trend")
                .font(.caption)
                .foregroundColor(.secondary)
            MiniBarChart(
                data: [450, 520, 480, 610, 550, 740, 680, 820, 950, 1100],
                barColor: .brandProgress
            )
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)

        // Decreasing trend
        VStack(alignment: .leading, spacing: 8) {
            Text("Decreasing Trend")
                .font(.caption)
                .foregroundColor(.secondary)
            MiniBarChart(
                data: [1000, 950, 900, 750, 650, 550, 480, 420],
                barColor: .brandExpense
            )
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)

        // Volatile trend
        VStack(alignment: .leading, spacing: 8) {
            Text("Volatile Trend")
                .font(.caption)
                .foregroundColor(.secondary)
            MiniBarChart(
                data: [500, 800, 450, 920, 650, 1100, 480, 850, 620, 950, 720, 890],
                barColor: .chartInactive
            )
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)

        // With many data points
        VStack(alignment: .leading, spacing: 8) {
            Text("Many Data Points")
                .font(.caption)
                .foregroundColor(.secondary)
            MiniBarChart(
                data: Array(0..<30).map { _ in Double.random(in: 400...1000) },
                barColor: .brandPositive
            )
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)
    }
    .padding()
    .background(Color.appBackground)
}

#Preview("Dark Mode") {
    VStack(spacing: 24) {
        VStack(alignment: .leading, spacing: 8) {
            Text("Daily Trend")
                .font(.caption)
                .foregroundColor(.secondary)
            MiniBarChart(
                data: [2450, 3100, 2890, 4120, 3850, 2100, 1890, 2340, 3210, 2540],
                barColor: .chartInactive
            )
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)
    }
    .padding()
    .background(Color.appBackground)
    .preferredColorScheme(.dark)
}
