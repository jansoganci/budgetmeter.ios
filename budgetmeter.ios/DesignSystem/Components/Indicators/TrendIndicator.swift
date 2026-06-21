//
//  TrendIndicator.swift
//  BudgetMeter
//
//  Design System v2.0 - Trend Indicator Component
//  Shows percentage change with directional arrow
//

import SwiftUI

/// Trend indicator showing percentage change with arrow
/// Format: ↑ +12.5% (positive) or ↓ -3.2% (negative)
struct TrendIndicator: View {

    // MARK: - Properties

    /// Percentage value (e.g., 12.5 for +12.5%)
    let percentage: Double

    /// Optional custom color (overrides automatic color)
    let customColor: Color?

    // MARK: - Computed Properties

    private var isPositive: Bool {
        percentage > 0
    }

    private var isNegative: Bool {
        percentage < 0
    }

    private var isNeutral: Bool {
        percentage == 0
    }

    private var color: Color {
        if let customColor = customColor {
            return customColor
        }

        if isPositive {
            return .financialPositive
        } else if isNegative {
            return .financialNegative
        } else {
            return .textSecondary
        }
    }

    private var iconName: String {
        if isPositive {
            return "arrow.up"
        } else if isNegative {
            return "arrow.down"
        } else {
            return "arrow.forward"
        }
    }

    private var formattedPercentage: String {
        PercentageFormatter.formatChange(percentage)
    }

    private var accessibilityLabel: String {
        let direction = isPositive ? "increased" : isNegative ? "decreased" : "unchanged"
        return "\(direction) by \(abs(percentage)) percent"
    }

    // MARK: - Initialization

    init(percentage: Double, color: Color? = nil) {
        self.percentage = percentage
        self.customColor = color
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: iconName)
                .font(.caption2.weight(Typography.medium))

            Text(formattedPercentage)
                .trendStyle(color: color)
        }
        .foregroundColor(color)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }
}

// MARK: - Convenience Initializers

extension TrendIndicator {
    /// Creates a trend indicator from two values (calculates percentage change)
    /// - Parameters:
    ///   - from: Previous value
    ///   - to: Current value
    ///   - color: Optional custom color
    init(from: Double, to: Double, color: Color? = nil) {
        let percentageChange: Double
        if from == 0 {
            percentageChange = to > 0 ? 100 : 0
        } else {
            percentageChange = ((to - from) / abs(from)) * 100
        }
        self.init(percentage: percentageChange, color: color)
    }
}

// MARK: - Preview

#Preview("All States") {
    VStack(spacing: 24) {
        // Positive trend
        VStack(alignment: .leading, spacing: 8) {
            Text("Positive Trend")
                .font(.caption)
                .foregroundColor(.secondary)
            HStack {
                Text("Net Flow This Month")
                    .font(.body)
                Spacer()
                TrendIndicator(percentage: 12.5)
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)

        // Negative trend
        VStack(alignment: .leading, spacing: 8) {
            Text("Negative Trend")
                .font(.caption)
                .foregroundColor(.secondary)
            HStack {
                Text("Spending")
                    .font(.body)
                Spacer()
                TrendIndicator(percentage: -8.3)
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)

        // Neutral trend
        VStack(alignment: .leading, spacing: 8) {
            Text("Neutral Trend")
                .font(.caption)
                .foregroundColor(.secondary)
            HStack {
                Text("Savings Rate")
                    .font(.body)
                Spacer()
                TrendIndicator(percentage: 0.0)
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)

        // Large changes
        VStack(alignment: .leading, spacing: 8) {
            Text("Large Changes")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack {
                Text("Huge increase")
                    .font(.caption)
                Spacer()
                TrendIndicator(percentage: 150.7)
            }

            Divider()

            HStack {
                Text("Big decrease")
                    .font(.caption)
                Spacer()
                TrendIndicator(percentage: -45.2)
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)

        // Custom colors
        VStack(alignment: .leading, spacing: 8) {
            Text("Custom Colors")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack {
                Text("With blue")
                    .font(.caption)
                Spacer()
                TrendIndicator(percentage: 25.0, color: .brandProgress)
            }

            Divider()

            HStack {
                Text("With purple")
                    .font(.caption)
                Spacer()
                TrendIndicator(percentage: 15.0, color: .purple)
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)

        // From/To convenience init
        VStack(alignment: .leading, spacing: 8) {
            Text("From/To Constructor")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack {
                Text("$1000 → $1250")
                    .font(.caption)
                Spacer()
                TrendIndicator(from: 1000, to: 1250)
            }

            Divider()

            HStack {
                Text("$2000 → $1800")
                    .font(.caption)
                Spacer()
                TrendIndicator(from: 2000, to: 1800)
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)
    }
    .padding()
    .background(Color.appBackground)
}

#Preview("Dark Mode") {
    VStack(spacing: 16) {
        HStack {
            Text("Income")
            Spacer()
            TrendIndicator(percentage: 8.5)
        }

        HStack {
            Text("Expenses")
            Spacer()
            TrendIndicator(percentage: -12.3)
        }

        HStack {
            Text("Neutral")
            Spacer()
            TrendIndicator(percentage: 0.0)
        }
    }
    .padding()
    .background(Color.cardBackground)
    .cornerRadius(12)
    .padding()
    .background(Color.appBackground)
    .preferredColorScheme(.dark)
}
