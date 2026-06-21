//
//  HomeDisplayMapping.swift
//  BudgetMeter
//
//  Maps FinancialSummary values to Home display state.
//

import Foundation

enum HomeDisplayMapping {

    static func paceStatusCopy(
        status: PaceStatus,
        netDailyPace: Double,
        currencySymbol: String
    ) -> String {
        let amount = signedDailyAmount(netDailyPace, currencySymbol: currencySymbol)
        switch status {
        case .movingForward:
            return String(
                format: "home.pace.moving_forward".localized(
                    defaultValue: "You're moving forward %@",
                    table: "Home"
                ),
                amount
            )
        case .slowingDown:
            return String(
                format: "home.pace.slowing_down".localized(
                    defaultValue: "Slowing down %@",
                    table: "Home"
                ),
                amount
            )
        case .neutral:
            return String(
                format: "home.pace.holding_steady".localized(
                    defaultValue: "Holding steady %@",
                    table: "Home"
                ),
                amount
            )
        case .insufficientData:
            return "home.pace.insufficient_data".localized(
                defaultValue: "Add income or expenses to see your pace",
                table: "Home"
            )
        }
    }

    static func signedDailyAmount(_ amount: Double, currencySymbol: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = abs(amount) >= 100 ? 0 : 2
        formatter.minimumFractionDigits = 0
        formatter.groupingSeparator = ","

        let formatted = formatter.string(from: NSNumber(value: abs(amount))) ?? "0"
        let sign = amount >= 0 ? "+" : "-"
        let perDay = "ui.units.per_day".localized(defaultValue: "/day", table: "UI")
        return "\(sign)\(currencySymbol)\(formatted)\(perDay)"
    }

    static func signedMinuteAmount(_ amount: Double, currencySymbol: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 4
        formatter.minimumFractionDigits = 2
        formatter.groupingSeparator = ","

        let formatted = formatter.string(from: NSNumber(value: abs(amount))) ?? "0.00"
        let sign = amount >= 0 ? "+" : "-"
        return "\(sign)\(currencySymbol)\(formatted)/min"
    }

    static func formatSavingsTimeToGoal(_ result: CalculationEngine.TargetTimeResult?) -> String {
        guard let result else { return "" }
        if let message = result.message { return message }

        if result.days < 1 {
            let hoursText = String(localized: "home.time_to_goal.hours", defaultValue: "hours")
            return String(format: "%.1f %@", result.hours, hoursText)
        }
        if result.days < 30 {
            let daysText = String(localized: "home.time_to_goal.days", defaultValue: "days")
            return String(format: "%.0f %@", result.days, daysText)
        }
        if result.months < 12 {
            let monthsText = String(localized: "home.time_to_goal.months", defaultValue: "months")
            return String(format: "%.1f %@", result.months, monthsText)
        }
        let yearsText = String(localized: "home.time_to_goal.years", defaultValue: "years")
        return String(format: "%.1f %@", result.years, yearsText)
    }

    /// Formats savings ETA copy from shared summary, including calm fallback states.
    static func formatSavingsETA(from summary: FinancialSummary) -> String {
        guard summary.savingsTargetAmount > 0 else { return "" }

        if summary.savingsRemaining <= 0 {
            return String(localized: "savings.goal_reached", defaultValue: "Goal reached!")
        }

        if let result = summary.savingsTimeToGoal {
            if let message = result.message { return message }
            let timeText = formatSavingsTimeToGoal(result)
            guard !timeText.isEmpty else { return "" }
            return String(
                format: String(
                    localized: "savings.eta.at_pace",
                    defaultValue: "At your current pace: %@"
                ),
                timeText
            )
        }

        if summary.netPacePerHour <= 0 {
            return String(
                localized: "savings.eta.negative_pace",
                defaultValue: "Your pace needs to turn positive before we can estimate a timeline."
            )
        }

        return String(
            localized: "savings.eta.unavailable",
            defaultValue: "Add income or expenses to estimate time to goal."
        )
    }

    static func hasFinancialInput(in summary: FinancialSummary) -> Bool {
        summary.recurringIncomeDaily > 0
            || summary.recurringExpenseDaily > 0
            || summary.recurringIncomeMonthly > 0
            || summary.recurringExpenseMonthly > 0
            || summary.savingsTargetAmount > 0
    }
}
