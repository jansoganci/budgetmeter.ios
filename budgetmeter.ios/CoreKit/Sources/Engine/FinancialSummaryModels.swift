//
//  FinancialSummaryModels.swift
//  BudgetMeter
//
//  Shared financial read models for normalized pace calculations.
//

import Foundation

enum PeriodKind: Equatable {
    case day
    case week
    case month
    case custom
}

enum PaceStatus: Equatable {
    case movingForward
    case slowingDown
    case neutral
    case insufficientData
}

enum MoneyLineSource: Equatable {
    case category
    case subscription
    case bill
    case recurringTransaction
}

struct RecurringMoneyLine: Equatable {
    let id: String
    let source: MoneyLineSource
    let categoryKey: String
    let label: String
    let amount: Double
    let interval: CalculationEngine.RecurringInterval
    let isActive: Bool
}

struct OneTimeMoneyLine: Equatable {
    let id: String
    let categoryKey: String
    let label: String
    let amount: Double
    let occurrenceDate: Date
}

struct DrainItem: Equatable {
    let label: String
    let categoryKey: String
    let amountInPeriod: Double
    let shareOfExpense: Double
    let isRecurring: Bool
}

struct FinancialSummaryInput: Equatable {
    let currencyCode: String
    let asOf: Date
    let selectedPeriod: PeriodKind
    let periodStart: Date
    let periodEnd: Date
    let recurringIncomeLines: [RecurringMoneyLine]
    let recurringExpenseLines: [RecurringMoneyLine]
    let oneTimeIncomeLines: [OneTimeMoneyLine]
    let oneTimeExpenseLines: [OneTimeMoneyLine]
    let savingsTargetAmount: Double
    let savingsCurrentAmount: Double
    let cumulativeBaseline: Double
    let sessionElapsedSeconds: Double
}

struct FinancialSummary: Equatable {
    let generatedAt: Date
    let currencyCode: String
    let selectedPeriod: PeriodKind
    let periodStart: Date
    let periodEnd: Date

    let recurringIncomeDaily: Double
    let recurringIncomeMonthly: Double
    let recurringExpenseDaily: Double
    let recurringExpenseMonthly: Double

    let netPacePerMinute: Double
    let netPacePerHour: Double
    let netPacePerDay: Double
    let netPacePerWeek: Double
    let netPacePerMonth: Double

    let oneTimeIncomeInPeriod: Double
    let oneTimeExpenseInPeriod: Double
    let netPeriodResult: Double

    let biggestDrain: DrainItem?
    let savingsTargetAmount: Double
    let savingsCurrentAmount: Double
    let savingsRemaining: Double
    let savingsTimeToGoal: CalculationEngine.TargetTimeResult?
    let paceStatus: PaceStatus
    let cumulativeNet: Double
    let liveSessionNet: Double
}
