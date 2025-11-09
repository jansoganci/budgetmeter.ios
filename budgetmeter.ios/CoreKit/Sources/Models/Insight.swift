//
//  Insight.swift
//  BudgetMeter
//
//  Created by BudgetMeter Team on 17.09.2025.
//

import Foundation
import SwiftUI

/// Represents an automated financial insight
struct Insight: Identifiable, Equatable {
    let id = UUID()
    let icon: String
    let title: String
    let value: String
    let trend: Trend?
    let color: Color
    let description: String?

    enum Trend: Equatable {
        case up
        case down
        case neutral

        var iconName: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .neutral: return "minus"
            }
        }

        var color: Color {
            switch self {
            case .up: return .green
            case .down: return .red
            case .neutral: return .gray
            }
        }
    }

    init(
        icon: String,
        title: String,
        value: String,
        trend: Trend? = nil,
        color: Color = .blue,
        description: String? = nil
    ) {
        self.icon = icon
        self.title = title
        self.value = value
        self.trend = trend
        self.color = color
        self.description = description
    }
}

// MARK: - Sample Insights for Preview

extension Insight {
    static let sampleSpendingBreakdown = Insight(
        icon: "chart.pie.fill",
        title: "Spending Breakdown",
        value: "40% on Groceries",
        color: .blue,
        description: "Your largest expense category this month"
    )

    static let sampleSavingsRate = Insight(
        icon: "arrow.up.circle.fill",
        title: "Savings Rate",
        value: "20%",
        trend: .up,
        color: .green,
        description: "You're saving $200 per month"
    )

    static let sampleBalanceTrend = Insight(
        icon: "chart.line.uptrend.xyaxis",
        title: "Balance Trend",
        value: "+$450",
        trend: .up,
        color: .green,
        description: "Your balance improved this month"
    )

    static let sampleSpendingTrend = Insight(
        icon: "chart.bar.fill",
        title: "Monthly Spending",
        value: "-15%",
        trend: .down,
        color: .orange,
        description: "You spent less than last month"
    )

    static let sampleGoalProgress = Insight(
        icon: "target",
        title: "Goal Progress",
        value: "3 months",
        color: .purple,
        description: "You'll reach your $5,000 goal"
    )

    static let samples: [Insight] = [
        sampleSpendingBreakdown,
        sampleSavingsRate,
        sampleBalanceTrend,
        sampleSpendingTrend,
        sampleGoalProgress
    ]
}
