//
//  WidgetSnapshotWriter.swift
//  BudgetMeter
//
//  Maps FinancialSummary into the shared widget snapshot contract.
//

import Foundation
import WidgetKit

enum WidgetSnapshotWriter {

    static func makeSnapshot(
        from summary: FinancialSummary,
        isPremium: Bool,
        currencySymbol: String,
        currencyCode: String? = nil,
        generatedAt: Date = Date()
    ) -> WidgetSnapshot {
        let hasInput = HomeDisplayMapping.hasFinancialInput(in: summary)
        let resolvedCurrencyCode = currencyCode ?? summary.currencyCode
        let displayValue = HomeDisplayMapping.signedDailyAmount(
            summary.netPacePerDay,
            currencySymbol: currencySymbol
        )
        let displayStatusCopy = HomeDisplayMapping.paceStatusCopy(
            status: summary.paceStatus,
            netDailyPace: summary.netPacePerDay,
            currencySymbol: currencySymbol
        )

        let lockedTitle = "widget.locked.title".localized(defaultValue: "Premium Widget")
        let lockedSubtitle = "widget.locked.subtitle".localized(
            defaultValue: "Unlock net daily pace on your Home Screen"
        )
        let missingMessage = "widget.missing.message".localized(
            defaultValue: "Open BudgetMeter to refresh"
        )
        let staleMessage = "widget.stale.message".localized(
            defaultValue: "Open BudgetMeter for the latest pace"
        )

        let isLockedTeaser = !isPremium
        let displayState: WidgetDisplayState
        if isLockedTeaser {
            displayState = .lockedTeaser
        } else if !hasInput || summary.paceStatus == .insufficientData {
            displayState = .insufficientData
        } else {
            displayState = .unlocked
        }

        if isLockedTeaser {
            return WidgetSnapshot(
                schemaVersion: WidgetConstants.schemaVersion,
                netDailyPace: 0,
                paceStatus: "insufficientData",
                displayValue: "",
                displayStatusCopy: "",
                currencyCode: "",
                currencySymbol: "",
                isPremium: false,
                generatedAt: generatedAt,
                staleAfter: generatedAt.addingTimeInterval(WidgetConstants.staleInterval),
                isLockedTeaser: true,
                lockedTeaserTitle: lockedTitle,
                lockedTeaserSubtitle: lockedSubtitle,
                deepLinkURL: WidgetConstants.lockedDeepLink,
                hasFinancialInput: false,
                displayState: .lockedTeaser,
                missingMessage: missingMessage,
                staleMessage: staleMessage
            )
        }

        return WidgetSnapshot(
            schemaVersion: WidgetConstants.schemaVersion,
            netDailyPace: summary.netPacePerDay,
            paceStatus: paceStatusRawValue(summary.paceStatus),
            displayValue: displayValue,
            displayStatusCopy: displayStatusCopy,
            currencyCode: resolvedCurrencyCode,
            currencySymbol: currencySymbol,
            isPremium: isPremium,
            generatedAt: generatedAt,
            staleAfter: generatedAt.addingTimeInterval(WidgetConstants.staleInterval),
            isLockedTeaser: isLockedTeaser,
            lockedTeaserTitle: lockedTitle,
            lockedTeaserSubtitle: lockedSubtitle,
            deepLinkURL: WidgetConstants.unlockedDeepLink,
            hasFinancialInput: hasInput,
            displayState: displayState,
            missingMessage: missingMessage,
            staleMessage: staleMessage
        )
    }

    static func persistAndReload(
        summary: FinancialSummary,
        isPremium: Bool,
        currencySymbol: String,
        currencyCode: String? = nil,
        store: WidgetSnapshotStore = WidgetSnapshotStore(),
        generatedAt: Date = Date()
    ) {
        let snapshot = makeSnapshot(
            from: summary,
            isPremium: isPremium,
            currencySymbol: currencySymbol,
            currencyCode: currencyCode,
            generatedAt: generatedAt
        )
        store.save(snapshot)
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetConstants.netDailyPaceWidgetKind)
    }

    private static func paceStatusRawValue(_ status: PaceStatus) -> String {
        switch status {
        case .movingForward: return "movingForward"
        case .slowingDown: return "slowingDown"
        case .neutral: return "neutral"
        case .insufficientData: return "insufficientData"
        }
    }
}
