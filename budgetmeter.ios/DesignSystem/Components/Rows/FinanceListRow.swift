//
//  FinanceListRow.swift
//  BudgetMeter
//
//  Handoff wrapper — standard financial list row.
//

import SwiftUI

/// Handoff name for `FinancialRowView`. Forwards without changing row behavior.
struct FinanceListRow: View {

    let category: FinancialCategory
    let currencySymbol: String
    let accentColor: Color
    let onEditTap: () -> Void

    var body: some View {
        FinancialRowView(
            category: category,
            currencySymbol: currencySymbol,
            accentColor: accentColor,
            onEditTap: onEditTap
        )
    }
}
