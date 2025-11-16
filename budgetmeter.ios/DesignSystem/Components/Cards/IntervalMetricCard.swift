//
//  IntervalMetricCard.swift
//  BudgetMeter
//
//  Design System v2.0 - Interval Metric Card
//  Card displaying metric with mini bar chart (Hourly/Daily/Monthly)
//

import SwiftUI

/// Interval metric card with title, value, and sparkline chart
/// Used for Hourly, Daily, Monthly metric displays
struct IntervalMetricCard: View {

    // MARK: - Properties

    /// Title (e.g., "Hourly", "Daily", "Monthly")
    let title: String

    /// Current value to display
    let value: Double

    /// Currency symbol
    let currencySymbol: String

    /// Historical data for sparkline chart
    let chartData: [Double]

    /// Optional tap action
    let onTap: (() -> Void)?

    // MARK: - State

    @State private var isPressed = false

    // MARK: - Computed Properties

    private var formattedValue: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        formatter.groupingSeparator = ","

        let formatted = formatter.string(from: NSNumber(value: abs(value))) ?? "0"
        return "\(currencySymbol)\(formatted)"
    }

    private var accessibilityLabel: String {
        "\(title): \(formattedValue)"
    }

    // MARK: - Initialization

    init(
        title: String,
        value: Double,
        currencySymbol: String = "$",
        chartData: [Double] = [],
        onTap: (() -> Void)? = nil
    ) {
        self.title = title
        self.value = value
        self.currencySymbol = currencySymbol
        self.chartData = chartData
        self.onTap = onTap
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Title
            Text(title)
                .cardLabelStyle()
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            // Value
            Text(formattedValue)
                .mediumMetricStyle()
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            // Mini Bar Chart
            if !chartData.isEmpty {
                MiniBarChart(
                    data: chartData,
                    animated: true,
                    barColor: .chartInactive
                )
            } else {
                // Empty state
                Rectangle()
                    .fill(Color.chartInactive.opacity(0.3))
                    .frame(height: ChartDimensions.miniChartHeight)
                    .cornerRadius(CornerRadius.tiny)
            }
        }
        .frame(height: CardHeight.medium)
        .dashboardCard()
        .pressEffect(isPressed: $isPressed, haptic: true)
        .onTapGesture {
            if let action = onTap {
                Haptics.medium()
                action()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(chartData.isEmpty ? "No data available" : "Chart showing trend data")
        .accessibilityAddTraits(onTap != nil ? [.isButton] : [])
    }
}

// MARK: - Preview

#Preview("Hourly") {
    VStack(spacing: Spacing.xl) {
        IntervalMetricCard(
            title: "Hourly",
            value: 2450,
            currencySymbol: "€",
            chartData: [450, 520, 480, 610, 550, 740, 680]
        )

        IntervalMetricCard(
            title: "Hourly",
            value: 1850,
            currencySymbol: "$",
            chartData: [320, 450, 380, 520, 410, 600, 550, 720]
        )
    }
    .padding()
    .background(Color.appBackground)
}

#Preview("Daily") {
    VStack(spacing: Spacing.xl) {
        IntervalMetricCard(
            title: "Daily",
            value: 18620,
            currencySymbol: "$",
            chartData: [2450, 3100, 2890, 4120, 3850, 2100, 1890, 2340, 3210, 2540, 3890, 2670, 4100, 3450, 4320]
        )

        IntervalMetricCard(
            title: "Daily",
            value: 12340,
            currencySymbol: "£",
            chartData: [1500, 2100, 1800, 2500, 2200, 1900, 1600, 2000, 2400, 1700]
        )
    }
    .padding()
    .background(Color.appBackground)
}

#Preview("Monthly") {
    VStack(spacing: Spacing.xl) {
        IntervalMetricCard(
            title: "Monthly",
            value: 562400,
            currencySymbol: "$",
            chartData: [42000, 48000, 45000, 52000, 58000, 61000, 59000, 63000, 67000, 65000, 69000, 71000]
        )

        IntervalMetricCard(
            title: "Monthly",
            value: 425000,
            currencySymbol: "¥",
            chartData: [35000, 38000, 42000, 39000, 45000, 48000, 51000, 49000, 53000, 56000]
        )
    }
    .padding()
    .background(Color.appBackground)
}

#Preview("Large Values") {
    VStack(spacing: Spacing.xl) {
        IntervalMetricCard(
            title: "Yearly",
            value: 6_748_500,
            currencySymbol: "$",
            chartData: [520000, 580000, 610000, 640000, 690000]
        )

        IntervalMetricCard(
            title: "All Time",
            value: 12_450_000,
            currencySymbol: "€",
            chartData: [1000000, 1500000, 2200000, 3100000, 4200000]
        )
    }
    .padding()
    .background(Color.appBackground)
}

#Preview("Empty Data") {
    VStack(spacing: Spacing.xl) {
        IntervalMetricCard(
            title: "Hourly",
            value: 0,
            currencySymbol: "$",
            chartData: []
        )

        IntervalMetricCard(
            title: "Daily",
            value: 1234,
            currencySymbol: "€",
            chartData: []
        )
    }
    .padding()
    .background(Color.appBackground)
}

#Preview("With Tap Action") {
    IntervalMetricCard(
        title: "Daily",
        value: 15620,
        currencySymbol: "$",
        chartData: [2100, 2800, 2400, 3200, 2900, 2300, 1900, 2500],
        onTap: {
            print("Interval card tapped!")
        }
    )
    .padding()
    .background(Color.appBackground)
}

#Preview("Grid Layout") {
    LazyVGrid(
        columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ],
        spacing: Spacing.md
    ) {
        IntervalMetricCard(
            title: "Hourly",
            value: 2450,
            currencySymbol: "$",
            chartData: [450, 520, 480, 610, 550, 740, 680]
        )

        IntervalMetricCard(
            title: "Daily",
            value: 18620,
            currencySymbol: "$",
            chartData: [2450, 3100, 2890, 4120, 3850, 2100]
        )

        IntervalMetricCard(
            title: "Monthly",
            value: 562400,
            currencySymbol: "$",
            chartData: [42000, 48000, 45000, 52000, 58000, 61000]
        )
    }
    .padding()
    .background(Color.appBackground)
}

#Preview("Dark Mode") {
    LazyVGrid(
        columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ],
        spacing: Spacing.md
    ) {
        IntervalMetricCard(
            title: "Hourly",
            value: 2450,
            currencySymbol: "€",
            chartData: [450, 520, 480, 610, 550, 740, 680]
        )

        IntervalMetricCard(
            title: "Daily",
            value: 18620,
            currencySymbol: "€",
            chartData: [2450, 3100, 2890, 4120, 3850]
        )

        IntervalMetricCard(
            title: "Monthly",
            value: 562400,
            currencySymbol: "€",
            chartData: [42000, 48000, 45000, 52000, 58000]
        )
    }
    .padding()
    .background(Color.appBackground)
    .preferredColorScheme(.dark)
}
