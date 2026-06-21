//
//  WidgetSnapshotService.swift
//  BudgetMeter
//
//  Rebuilds and publishes the widget snapshot from current app data.
//

import CoreData
import Foundation

@MainActor
enum WidgetSnapshotService {

    static func refreshFromCurrentData(
        context: NSManagedObjectContext = PersistenceService.shared.viewContext
    ) {
        refreshFromCurrentData(context: context, isPremium: PremiumManager.shared.isPremium)
    }

    static func refreshFromCurrentData(
        context: NSManagedObjectContext,
        isPremium: Bool
    ) {
        let builder = FinancialSummaryBuilder(context: context)
        let summary = builder.build(sessionElapsedSeconds: 0)

        let currencyCode: String
        if let settings = try? context.fetch(AppSettings.fetchRequest()).first,
           let preferred = settings.preferredCurrencyCode,
           CurrencyHelper.supportedCurrencyCodes.contains(preferred) {
            currencyCode = preferred
        } else {
            currencyCode = summary.currencyCode
        }

        let currencySymbol = CurrencyHelper.symbol(for: currencyCode)

        WidgetSnapshotWriter.persistAndReload(
            summary: summary,
            isPremium: isPremium,
            currencySymbol: currencySymbol,
            currencyCode: currencyCode
        )
    }
}
