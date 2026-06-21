//
//  SummaryHeroCard.swift
//  BudgetMeter
//
//  Handoff wrapper — one important summary value with context.
//

import SwiftUI

/// Hero summary for Income/Expense monthly totals. Delegates to `FinancialSummaryCard`.
struct SummaryHeroCard: View {

    let totalMonthly: Double
    let dailyAverage: Double
    let yearlyProjection: Double
    let currencySymbol: String
    let type: FinancialType
    var sourcesCount: Int = 0

    var body: some View {
        FinancialSummaryCard(
            totalMonthly: totalMonthly,
            dailyAverage: dailyAverage,
            yearlyProjection: yearlyProjection,
            currencySymbol: currencySymbol,
            type: type,
            sourcesCount: sourcesCount
        )
    }
}

#Preview {
    SummaryHeroCard(
        totalMonthly: 5200,
        dailyAverage: 173,
        yearlyProjection: 62400,
        currencySymbol: "$",
        type: .income,
        sourcesCount: 2
    )
    .padding()
    .background(Color.appBackground)
}
