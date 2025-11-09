//
//  HealthTip.swift
//  BudgetMeter
//
//  Created by BudgetMeter Team on 17.09.2025.
//

import Foundation
import SwiftUI

/// Represents an actionable tip to improve financial health
struct HealthTip: Identifiable, Equatable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
    let impact: String  // e.g., "+10 points"
    let actionable: Bool
    let color: Color

    init(
        icon: String,
        title: String,
        description: String,
        impact: String,
        actionable: Bool = true,
        color: Color = .blue
    ) {
        self.icon = icon
        self.title = title
        self.description = description
        self.impact = impact
        self.actionable = actionable
        self.color = color
    }
}

// MARK: - Sample Tips

extension HealthTip {
    static let sampleReduceExpenses = HealthTip(
        icon: "💸",
        title: "Reduce Daily Expenses",
        description: "Cut expenses by $10/day to reach Excellent score",
        impact: "+5 points",
        color: .orange
    )

    static let sampleIncreaseSavings = HealthTip(
        icon: "🏦",
        title: "Increase Savings",
        description: "Save an extra $50/month to maximize your score",
        impact: "+10 points",
        color: .green
    )

    static let sampleSetGoal = HealthTip(
        icon: "🎯",
        title: "Set a Savings Goal",
        description: "Goals help you save more effectively",
        impact: "+10 points",
        color: .purple
    )

    static let sampleIncreaseIncome = HealthTip(
        icon: "💰",
        title: "Increase Your Income",
        description: "Add income sources to improve your score",
        impact: "+5 points",
        color: .blue
    )

    static let sampleMaintain = HealthTip(
        icon: "✨",
        title: "Keep Up the Great Work!",
        description: "You're doing excellent! Maintain your current habits",
        impact: "Excellent",
        actionable: false,
        color: .green
    )

    static let samples: [HealthTip] = [
        sampleReduceExpenses,
        sampleIncreaseSavings,
        sampleSetGoal,
        sampleIncreaseIncome
    ]
}
