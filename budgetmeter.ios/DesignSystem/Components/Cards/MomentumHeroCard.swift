//
//  MomentumHeroCard.swift
//  BudgetMeter
//
//  Phase 3/4 — Hero card for Home momentum pace dashboard.
//

import SwiftUI

/// Hero card answering: "Am I moving forward or slowing down today?"
struct MomentumHeroCard: View {

    let paceStatus: PaceStatus
    let paceStatusCopy: String
    let netDailyPace: Double
    let netMinutePace: Double
    let currencySymbol: String

    private var dailyPaceText: String {
        HomeDisplayMapping.signedDailyAmount(netDailyPace, currencySymbol: currencySymbol)
    }

    private var paceColor: Color {
        Color.color(for: paceStatus)
    }

    private var statusIconName: String {
        switch paceStatus {
        case .movingForward: return "arrow.up.circle.fill"
        case .slowingDown: return "arrow.down.circle.fill"
        case .neutral: return "equal.circle.fill"
        case .insufficientData: return "questionmark.circle.fill"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: LayoutSpacing.cardInternalGap) {
            Text("home.momentum.title".localized(defaultValue: "Today's pace", table: "Home"))
                .badgeStyle(color: .textSecondary)

            Text("home.momentum.subtitle".localized(
                defaultValue: "Is your money moving forward or slowing down today?",
                table: "Home"
            ))
                .captionStyle(color: .textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(alignment: .center, spacing: LayoutSpacing.sectionGap) {
                MomentumRingView(paceStatus: paceStatus)
                    .frame(width: 72, height: 72)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(dailyPaceText)
                        .paceHeroStyle(color: paceColor)

                    HStack(spacing: Spacing.xs) {
                        Image(systemName: statusIconName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(paceColor)
                            .accessibilityHidden(true)

                        Text(paceStatusCopy)
                            .statusTitleStyle(color: .textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer(minLength: 0)
            }
        }
        .padding(LayoutSpacing.cardPadding)
        .glassSurface()
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous)
                .stroke(paceColor.opacity(0.22), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        [
            "home.momentum.title".localized(defaultValue: "Today's pace", table: "Home"),
            dailyPaceText,
            paceStatusCopy
        ].joined(separator: ", ")
    }
}

#Preview {
    MomentumHeroCard(
        paceStatus: .movingForward,
        paceStatusCopy: "Moving forward +$12/day",
        netDailyPace: 12,
        netMinutePace: 0.0083,
        currencySymbol: "$"
    )
    .padding()
    .background(Color.appBackground)
    .preferredColorScheme(.dark)
}
