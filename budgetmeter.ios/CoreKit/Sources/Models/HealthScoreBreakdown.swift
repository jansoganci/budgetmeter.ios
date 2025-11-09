//
//  HealthScoreBreakdown.swift
//  BudgetMeter
//
//  Created by BudgetMeter Team on 17.09.2025.
//

import Foundation
import SwiftUI

/// Detailed breakdown of the financial health score
struct HealthScoreBreakdown: Equatable {
    let totalScore: Int        // 0-100
    let incomeScore: Int       // 0-30 points
    let expenseScore: Int      // 0-30 points
    let savingsScore: Int      // 0-40 points

    let incomeReason: String
    let expenseReason: String
    let savingsReason: String

    /// Maximum possible score for income component
    static let maxIncomeScore = 30

    /// Maximum possible score for expense component
    static let maxExpenseScore = 30

    /// Maximum possible score for savings component
    static let maxSavingsScore = 40

    /// Maximum total score
    static let maxTotalScore = 100

    /// Progress percentage for income (0.0 to 1.0)
    var incomeProgress: Double {
        Double(incomeScore) / Double(Self.maxIncomeScore)
    }

    /// Progress percentage for expense (0.0 to 1.0)
    var expenseProgress: Double {
        Double(expenseScore) / Double(Self.maxExpenseScore)
    }

    /// Progress percentage for savings (0.0 to 1.0)
    var savingsProgress: Double {
        Double(savingsScore) / Double(Self.maxSavingsScore)
    }

    /// Color for income score
    var incomeColor: Color {
        scoreColor(for: incomeScore, max: Self.maxIncomeScore)
    }

    /// Color for expense score
    var expenseColor: Color {
        scoreColor(for: expenseScore, max: Self.maxExpenseScore)
    }

    /// Color for savings score
    var savingsColor: Color {
        scoreColor(for: savingsScore, max: Self.maxSavingsScore)
    }

    /// Get color based on score percentage
    private func scoreColor(for score: Int, max: Int) -> Color {
        let percentage = Double(score) / Double(max)
        if percentage >= 0.8 {
            return .green
        } else if percentage >= 0.5 {
            return .orange
        } else {
            return .red
        }
    }
}

// MARK: - Sample Data

extension HealthScoreBreakdown {
    static let sampleExcellent = HealthScoreBreakdown(
        totalScore: 95,
        incomeScore: 30,
        expenseScore: 28,
        savingsScore: 37,
        incomeReason: "Great income level ($3,500+/month)",
        expenseReason: "Expenses well managed (45% of income)",
        savingsReason: "Excellent savings rate (25%)"
    )

    static let sampleGood = HealthScoreBreakdown(
        totalScore: 75,
        incomeScore: 25,
        expenseScore: 25,
        savingsScore: 25,
        incomeReason: "Good income level ($2,500/month)",
        expenseReason: "Moderate expenses (60% of income)",
        savingsReason: "Good savings progress (15%)"
    )

    static let sampleNeedsWork = HealthScoreBreakdown(
        totalScore: 45,
        incomeScore: 15,
        expenseScore: 15,
        savingsScore: 15,
        incomeReason: "Limited income ($1,200/month)",
        expenseReason: "High expenses (80% of income)",
        savingsReason: "Low savings rate (5%)"
    )
}
