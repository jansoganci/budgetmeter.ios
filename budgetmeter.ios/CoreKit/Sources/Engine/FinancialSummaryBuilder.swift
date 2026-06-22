//
//  FinancialSummaryBuilder.swift
//  BudgetMeter
//
//  Builds the shared financial pace summary from Core Data sources.
//

import CoreData
import Foundation

final class FinancialSummaryBuilder {

    private let context: NSManagedObjectContext
    private let calendar: Calendar

    init(
        context: NSManagedObjectContext = PersistenceService.shared.viewContext,
        calendar: Calendar = .current
    ) {
        self.context = context
        self.calendar = calendar
    }

    func build(
        selectedPeriod: PeriodKind = .month,
        asOf: Date = Date(),
        sessionElapsedSeconds: Double = 0
    ) -> FinancialSummary {
        build(
            from: makeInput(
                selectedPeriod: selectedPeriod,
                asOf: asOf,
                sessionElapsedSeconds: sessionElapsedSeconds
            )
        )
    }

    func makeInput(
        selectedPeriod: PeriodKind = .month,
        asOf: Date = Date(),
        sessionElapsedSeconds: Double = 0
    ) -> FinancialSummaryInput {
        let bounds = periodBounds(for: selectedPeriod, asOf: asOf)
        let settings = fetchFirst(AppSettings.fetchRequest())
        let savingsState = SavingsGoalManager.resolvedSavingsTargetAndCurrent(in: context)

        var recurringIncome: [String: RecurringMoneyLine] = [:]
        var recurringExpense: [String: RecurringMoneyLine] = [:]
        var oneTimeIncome: [OneTimeMoneyLine] = []
        var oneTimeExpense: [OneTimeMoneyLine] = []

        addSubscriptionLines(to: &recurringExpense)
        addBillLines(to: &recurringExpense)
        addRecurringTransactionLines(income: &recurringIncome, expense: &recurringExpense)
        addFinancialCategoryLines(
            income: &recurringIncome,
            expense: &recurringExpense,
            oneTimeIncome: &oneTimeIncome,
            oneTimeExpense: &oneTimeExpense
        )

        return FinancialSummaryInput(
            currencyCode: settings?.preferredCurrencyCode ?? "USD",
            asOf: asOf,
            selectedPeriod: selectedPeriod,
            periodStart: bounds.start,
            periodEnd: bounds.end,
            recurringIncomeLines: Array(recurringIncome.values),
            recurringExpenseLines: Array(recurringExpense.values),
            oneTimeIncomeLines: oneTimeIncome,
            oneTimeExpenseLines: oneTimeExpense,
            savingsTargetAmount: savingsState.target,
            savingsCurrentAmount: savingsState.current,
            cumulativeBaseline: settings?.cumulativeTotal ?? 0,
            sessionElapsedSeconds: sessionElapsedSeconds
        )
    }

    func build(from input: FinancialSummaryInput) -> FinancialSummary {
        let recurringIncomeDaily = dailyTotal(input.recurringIncomeLines)
        let recurringExpenseDaily = dailyTotal(input.recurringExpenseLines)
        let recurringIncomeMonthly = monthlyTotal(input.recurringIncomeLines)
        let recurringExpenseMonthly = monthlyTotal(input.recurringExpenseLines)
        let netDaily = recurringIncomeDaily - recurringExpenseDaily
        let netHourly = netDaily / CalculationEngine.hoursPerDay
        let periodDays = daysBetween(input.periodStart, input.periodEnd)
        let oneTimeIncome = periodTotal(input.oneTimeIncomeLines, start: input.periodStart, end: input.periodEnd)
        let oneTimeExpense = periodTotal(input.oneTimeExpenseLines, start: input.periodStart, end: input.periodEnd)
        let netPeriodResult = (netDaily * periodDays) + oneTimeIncome - oneTimeExpense
        let savingsRemaining = max(0, input.savingsTargetAmount - input.savingsCurrentAmount)
        let savingsTime = savingsRemaining > 0 && netHourly > 0
            ? CalculationEngine.targetTime(targetAmount: savingsRemaining, netHourlyFlow: netHourly)
            : nil

        return FinancialSummary(
            generatedAt: input.asOf,
            currencyCode: input.currencyCode,
            selectedPeriod: input.selectedPeriod,
            periodStart: input.periodStart,
            periodEnd: input.periodEnd,
            recurringIncomeDaily: recurringIncomeDaily,
            recurringIncomeMonthly: recurringIncomeMonthly,
            recurringExpenseDaily: recurringExpenseDaily,
            recurringExpenseMonthly: recurringExpenseMonthly,
            netPacePerMinute: netDaily / 1_440,
            netPacePerHour: netHourly,
            netPacePerDay: netDaily,
            netPacePerWeek: CalculationEngine.netWeeklyFlow(
                dailyIncomeTotal: recurringIncomeDaily,
                monthlyIncomeTotal: 0,
                yearlyIncomeTotal: 0,
                dailyExpenseTotal: recurringExpenseDaily,
                monthlyExpenseTotal: 0,
                yearlyExpenseTotal: 0
            ),
            netPacePerMonth: recurringIncomeMonthly - recurringExpenseMonthly,
            oneTimeIncomeInPeriod: oneTimeIncome,
            oneTimeExpenseInPeriod: oneTimeExpense,
            netPeriodResult: netPeriodResult,
            biggestDrain: biggestDrain(
                recurringExpenseLines: input.recurringExpenseLines,
                oneTimeExpenseLines: input.oneTimeExpenseLines,
                periodStart: input.periodStart,
                periodEnd: input.periodEnd,
                periodDays: periodDays
            ),
            savingsTargetAmount: input.savingsTargetAmount,
            savingsCurrentAmount: input.savingsCurrentAmount,
            savingsRemaining: savingsRemaining,
            savingsTimeToGoal: savingsTime,
            paceStatus: paceStatus(hasInput: !input.recurringIncomeLines.isEmpty || !input.recurringExpenseLines.isEmpty, netDaily: netDaily),
            cumulativeNet: input.cumulativeBaseline + netPeriodResult,
            liveSessionNet: CalculationEngine.calculateLiveNetFlow(
                netHourlyFlow: netHourly,
                elapsedSeconds: input.sessionElapsedSeconds
            )
        )
    }

    // MARK: - Core Data Mapping

    private func addFinancialCategoryLines(
        income: inout [String: RecurringMoneyLine],
        expense: inout [String: RecurringMoneyLine],
        oneTimeIncome: inout [OneTimeMoneyLine],
        oneTimeExpense: inout [OneTimeMoneyLine]
    ) {
        for category in fetchAll(FinancialCategory.fetchRequest()) {
            guard category.isActive else { continue }
            if FinancialCategoryWriteSupport.isOneTimeDisplayCategory(category),
               OneTimeTransactionSyncMetadataStore.shared.isTombstoned(category, in: context) {
                continue
            }
            guard category.amount > 0 else { continue }
            guard let type = category.type else { continue }

            let label = category.customName ?? category.uniqueID ?? type
            let categoryKey = category.uniqueID ?? category.customName ?? type
            let sourceID = normalized(category.sourceID)
            let stableID = sourceID.isEmpty
                ? "category:\(category.id?.uuidString ?? category.objectID.uriRepresentation().absoluteString)"
                : sourceID

            if normalized(category.entryKind) == "oneTime" {
                guard let occurrenceDate = category.occurrenceDate else { continue }
                let line = OneTimeMoneyLine(
                    id: stableID,
                    categoryKey: categoryKey,
                    label: label,
                    amount: category.amount,
                    occurrenceDate: occurrenceDate
                )
                if type == "income" {
                    oneTimeIncome.append(line)
                } else if type == "expense" {
                    oneTimeExpense.append(line)
                }
                continue
            }

            guard let interval = interval(from: category.frequency, customDays: 0) else { continue }
            let line = RecurringMoneyLine(
                id: stableID,
                source: .category,
                categoryKey: categoryKey,
                label: label,
                amount: category.amount,
                interval: interval,
                isActive: true
            )

            if type == "income" {
                income[stableID] = income[stableID] ?? line
            } else if type == "expense" {
                expense[stableID] = expense[stableID] ?? line
            }
        }
    }

    private func addSubscriptionLines(to lines: inout [String: RecurringMoneyLine]) {
        for subscription in fetchAll(Subscription.fetchRequest()) {
            guard subscription.isActive, !subscription.isPaused else { continue }
            guard subscription.amount > 0 else { continue }
            guard let interval = interval(
                from: subscription.billingCycle,
                customDays: Double(subscription.customCycleDays)
            ) else { continue }

            let id = "subscription:\(subscription.id?.uuidString ?? subscription.objectID.uriRepresentation().absoluteString)"
            lines[id] = RecurringMoneyLine(
                id: id,
                source: .subscription,
                categoryKey: subscription.category ?? "subscription",
                label: subscription.name ?? subscription.category ?? "Subscription",
                amount: subscription.amount,
                interval: interval,
                isActive: true
            )
        }
    }

    private func addBillLines(to lines: inout [String: RecurringMoneyLine]) {
        for bill in fetchAll(Bill.fetchRequest()) {
            guard bill.isRecurring, !bill.isPaid else { continue }
            guard bill.amount > 0 else { continue }
            guard let interval = interval(from: bill.frequency, customDays: 0) else { continue }

            let id = "bill:\(bill.id?.uuidString ?? bill.objectID.uriRepresentation().absoluteString)"
            lines[id] = RecurringMoneyLine(
                id: id,
                source: .bill,
                categoryKey: bill.category ?? "bill",
                label: bill.name ?? bill.category ?? "Bill",
                amount: bill.amount,
                interval: interval,
                isActive: true
            )
        }
    }

    private func addRecurringTransactionLines(
        income: inout [String: RecurringMoneyLine],
        expense: inout [String: RecurringMoneyLine]
    ) {
        for transaction in fetchAll(RecurringTransaction.fetchRequest()) {
            guard transaction.deletedAt == nil else { continue }
            guard transaction.isActive else { continue }
            guard transaction.amount > 0 else { continue }
            guard let type = transaction.categoryType else { continue }
            guard let interval = interval(from: transaction.frequency, customDays: 0) else { continue }

            let id = "recurring:\(transaction.id?.uuidString ?? transaction.objectID.uriRepresentation().absoluteString)"
            let line = RecurringMoneyLine(
                id: id,
                source: .recurringTransaction,
                categoryKey: transaction.categoryName ?? type,
                label: transaction.title ?? transaction.categoryName ?? "Recurring",
                amount: transaction.amount,
                interval: interval,
                isActive: true
            )

            if type == "income" {
                income[id] = income[id] ?? line
            } else if type == "expense" {
                expense[id] = expense[id] ?? line
            }
        }
    }

    // MARK: - Calculation Helpers

    private func dailyTotal(_ lines: [RecurringMoneyLine]) -> Double {
        lines.filter(\.isActive).reduce(0) { total, line in
            total + CalculationEngine.dailyAmount(amount: line.amount, interval: line.interval)
        }
    }

    private func monthlyTotal(_ lines: [RecurringMoneyLine]) -> Double {
        lines.filter(\.isActive).reduce(0) { total, line in
            total + CalculationEngine.monthlyAmount(amount: line.amount, interval: line.interval)
        }
    }

    private func periodTotal(_ lines: [OneTimeMoneyLine], start: Date, end: Date) -> Double {
        lines.reduce(0) { total, line in
            guard line.occurrenceDate >= start, line.occurrenceDate < end else { return total }
            return total + line.amount
        }
    }

    private func biggestDrain(
        recurringExpenseLines: [RecurringMoneyLine],
        oneTimeExpenseLines: [OneTimeMoneyLine],
        periodStart: Date,
        periodEnd: Date,
        periodDays: Double
    ) -> DrainItem? {
        struct DrainAccumulator {
            var label: String
            var amount: Double
            var isRecurring: Bool
        }

        var drains: [String: DrainAccumulator] = [:]

        for line in recurringExpenseLines where line.isActive {
            let amount = CalculationEngine.periodAmount(amount: line.amount, interval: line.interval, days: periodDays)
            guard amount > 0 else { continue }
            var accumulator = drains[line.categoryKey] ?? DrainAccumulator(label: line.label, amount: 0, isRecurring: true)
            accumulator.amount += amount
            accumulator.isRecurring = true
            drains[line.categoryKey] = accumulator
        }

        for line in oneTimeExpenseLines where line.occurrenceDate >= periodStart && line.occurrenceDate < periodEnd {
            guard line.amount > 0 else { continue }
            var accumulator = drains[line.categoryKey] ?? DrainAccumulator(label: line.label, amount: 0, isRecurring: false)
            accumulator.amount += line.amount
            drains[line.categoryKey] = accumulator
        }

        let total = drains.values.reduce(0) { $0 + $1.amount }
        guard total > 0 else { return nil }
        guard let largest = drains.max(by: { $0.value.amount < $1.value.amount }) else { return nil }

        return DrainItem(
            label: largest.value.label,
            categoryKey: largest.key,
            amountInPeriod: largest.value.amount,
            shareOfExpense: largest.value.amount / total,
            isRecurring: largest.value.isRecurring
        )
    }

    private func paceStatus(hasInput: Bool, netDaily: Double) -> PaceStatus {
        guard hasInput else { return .insufficientData }
        if netDaily > 0.005 { return .movingForward }
        if netDaily < -0.005 { return .slowingDown }
        return .neutral
    }

    private func daysBetween(_ start: Date, _ end: Date) -> Double {
        max(end.timeIntervalSince(start) / CalculationEngine.secondsPerDay, 1)
    }

    private func interval(from rawValue: String?, customDays: Double) -> CalculationEngine.RecurringInterval? {
        switch normalized(rawValue).lowercased() {
        case "daily":
            return .daily
        case "weekly":
            return .weekly
        case "monthly", "":
            return .monthly
        case "quarterly":
            return .quarterly
        case "yearly", "annual", "annually":
            return .yearly
        case "custom":
            return customDays > 0 ? .custom(days: customDays) : nil
        default:
            return nil
        }
    }

    private func periodBounds(for period: PeriodKind, asOf: Date) -> (start: Date, end: Date) {
        switch period {
        case .day:
            let start = calendar.startOfDay(for: asOf)
            let end = calendar.date(byAdding: .day, value: 1, to: start) ?? asOf
            return (start, end)
        case .week:
            let interval = calendar.dateInterval(of: .weekOfYear, for: asOf)
            return (interval?.start ?? asOf, interval?.end ?? asOf)
        case .month, .custom:
            let interval = calendar.dateInterval(of: .month, for: asOf)
            return (interval?.start ?? asOf, interval?.end ?? asOf)
        }
    }

    private func fetchAll<T: NSManagedObject>(_ request: NSFetchRequest<T>) -> [T] {
        (try? context.fetch(request)) ?? []
    }

    private func fetchFirst<T: NSManagedObject>(_ request: NSFetchRequest<T>) -> T? {
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }

    private func normalized(_ value: String?) -> String {
        value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}
