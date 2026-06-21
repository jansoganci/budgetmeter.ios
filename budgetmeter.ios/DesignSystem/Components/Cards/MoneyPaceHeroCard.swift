//
//  MoneyPaceHeroCard.swift
//  BudgetMeter
//
//  Handoff wrapper — daily money pace hero. Delegates to MomentumHeroCard.
//

import SwiftUI

/// Answers: "Am I moving forward or slowing down today?" Wraps `MomentumHeroCard`.
struct MoneyPaceHeroCard: View {

    let paceStatus: PaceStatus
    let paceStatusCopy: String
    let netDailyPace: Double
    let netMinutePace: Double
    let currencySymbol: String

    var body: some View {
        MomentumHeroCard(
            paceStatus: paceStatus,
            paceStatusCopy: paceStatusCopy,
            netDailyPace: netDailyPace,
            netMinutePace: netMinutePace,
            currencySymbol: currencySymbol
        )
    }
}

#Preview {
    MoneyPaceHeroCard(
        paceStatus: .movingForward,
        paceStatusCopy: "Moving forward",
        netDailyPace: 12,
        netMinutePace: 0.0083,
        currencySymbol: "$"
    )
    .padding()
    .background(Color.appBackground)
}
