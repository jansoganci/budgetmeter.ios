//
//  WidgetDisplayCopy.swift
//  BudgetMeter
//
//  Widget pace status copy with locale-aware currency formatting.
//

import Foundation

enum WidgetDisplayCopy {
    static func paceStatusCopy(
        paceStatus: String,
        netDailyPace: Double,
        currencyCode: String,
        locale: Locale = .current
    ) -> String {
        let amount = WidgetCurrencyFormatting.signedDailyPace(
            netDailyPace,
            currencyCode: currencyCode,
            locale: locale
        )

        switch paceStatus {
        case "movingForward":
            return String(
                format: String(
                    localized: "home.pace.moving_forward",
                    defaultValue: "You're moving forward %@",
                    table: "Home",
                    locale: locale
                ),
                amount
            )
        case "slowingDown":
            return String(
                format: String(
                    localized: "home.pace.slowing_down",
                    defaultValue: "Slowing down %@",
                    table: "Home",
                    locale: locale
                ),
                amount
            )
        case "neutral":
            return String(
                format: String(
                    localized: "home.pace.holding_steady",
                    defaultValue: "Holding steady %@",
                    table: "Home",
                    locale: locale
                ),
                amount
            )
        default:
            return String(
                localized: "home.pace.insufficient_data",
                defaultValue: "Add income or expenses to see your pace",
                table: "Home",
                locale: locale
            )
        }
    }

    /// Short widget status label without duplicating the hero amount (UI table).
    static func shortPaceStatusCopy(paceStatus: String, locale: Locale = .current) -> String {
        switch paceStatus {
        case "movingForward":
            return String(
                localized: "widget.status.moving_forward",
                defaultValue: "Moving forward",
                table: "UI",
                locale: locale
            )
        case "slowingDown":
            return String(
                localized: "widget.status.slowing_down",
                defaultValue: "Pace slowed",
                table: "UI",
                locale: locale
            )
        case "neutral":
            return String(
                localized: "widget.status.neutral",
                defaultValue: "Holding steady",
                table: "UI",
                locale: locale
            )
        default:
            return String(
                localized: "widget.status.insufficient_data",
                defaultValue: "Not enough data yet",
                table: "UI",
                locale: locale
            )
        }
    }
}
