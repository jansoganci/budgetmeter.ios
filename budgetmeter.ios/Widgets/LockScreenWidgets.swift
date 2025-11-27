//
//  LockScreenWidgets.swift
//  BudgetMeter
//
//  Created by BudgetMeter Team on 17.09.2025.
//

import WidgetKit
import SwiftUI
import CoreData

// MARK: - Lock Screen Circular Widget

@available(iOS 16.0, *)
struct LockScreenBalanceCircular: Widget {
    let kind: String = "LockScreenBalanceCircular"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LockScreenBalanceProvider()) { entry in
            LockScreenCircularView(entry: entry)
        }
        .configurationDisplayName("Balance (Circular)")
        .description("Shows your current balance in a circular lock screen widget")
        .supportedFamilies([.accessoryCircular])
    }
}

// MARK: - Lock Screen Rectangular Widget

@available(iOS 16.0, *)
struct LockScreenBalanceRectangular: Widget {
    let kind: String = "LockScreenBalanceRectangular"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LockScreenBalanceProvider()) { entry in
            LockScreenRectangularView(entry: entry)
        }
        .configurationDisplayName("Balance (Rectangular)")
        .description("Shows your balance and daily flow in a rectangular lock screen widget")
        .supportedFamilies([.accessoryRectangular])
    }
}

// MARK: - Lock Screen Inline Widget

@available(iOS 16.0, *)
struct LockScreenBalanceInline: Widget {
    let kind: String = "LockScreenBalanceInline"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LockScreenBalanceProvider()) { entry in
            LockScreenInlineView(entry: entry)
        }
        .configurationDisplayName("Balance (Inline)")
        .description("Shows your balance in an inline lock screen widget")
        .supportedFamilies([.accessoryInline])
    }
}

// MARK: - Timeline Entry

struct LockScreenBalanceEntry: TimelineEntry {
    let date: Date
    let balance: Double
    let dailyNet: Double
    let currency: String
    let isPositive: Bool
}

// MARK: - Timeline Provider

struct LockScreenBalanceProvider: TimelineProvider {
    func placeholder(in context: Context) -> LockScreenBalanceEntry {
        LockScreenBalanceEntry(
            date: Date(),
            balance: 1250.75,
            dailyNet: 45.50,
            currency: "USD",
            isPositive: true
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (LockScreenBalanceEntry) -> ()) {
        let entry = LockScreenBalanceEntry(
            date: Date(),
            balance: 1250.75,
            dailyNet: 45.50,
            currency: "USD",
            isPositive: true
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LockScreenBalanceEntry>) -> ()) {
        let currentDate = Date()
        let entry = createBalanceEntry(for: currentDate)

        // Update every hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate) ?? currentDate.addingTimeInterval(3600)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func createBalanceEntry(for date: Date) -> LockScreenBalanceEntry {
        let persistenceService = PersistenceService.shared
        let context = persistenceService.viewContext

        do {
            // Fetch financial categories
            let request: NSFetchRequest<FinancialCategory> = FinancialCategory.fetchRequest()
            let categories = try context.fetch(request)

            let incomeCategories = categories.filter { $0.type == "income" }
            let expenseCategories = categories.filter { $0.type == "expense" }

            // Calculate monthly totals using CalculationEngine
            let dailyIncome = incomeCategories.filter { $0.frequency == "daily" }.reduce(0) { $0 + $1.amount }
            let monthlyIncome = incomeCategories.filter { $0.frequency == "monthly" }.reduce(0) { $0 + $1.amount }
            let yearlyIncome = incomeCategories.filter { $0.frequency == "yearly" }.reduce(0) { $0 + $1.amount }

            let dailyExpense = expenseCategories.filter { $0.frequency == "daily" }.reduce(0) { $0 + $1.amount }
            let monthlyExpense = expenseCategories.filter { $0.frequency == "monthly" }.reduce(0) { $0 + $1.amount }
            let yearlyExpense = expenseCategories.filter { $0.frequency == "yearly" }.reduce(0) { $0 + $1.amount }

            // Calculate monthly equivalents
            let totalMonthlyIncome = CalculationEngine.totalMonthlyIncome(
                dailyIncomeTotal: dailyIncome,
                monthlyIncomeTotal: monthlyIncome,
                yearlyIncomeTotal: yearlyIncome
            )

            let totalMonthlyExpense = CalculationEngine.totalMonthlyExpense(
                dailyTotal: dailyExpense,
                monthlyTotal: monthlyExpense,
                yearlyTotal: yearlyExpense
            )

            let balance = totalMonthlyIncome - totalMonthlyExpense

            // Calculate daily net flow (daily only)
            let dailyNet = dailyIncome - dailyExpense

            // Get app settings for currency
            let settingsRequest: NSFetchRequest<AppSettings> = AppSettings.fetchRequest()
            let settings = try context.fetch(settingsRequest).first
            let currency = settings?.preferredCurrencyCode ?? "USD"

            return LockScreenBalanceEntry(
                date: date,
                balance: balance,
                dailyNet: dailyNet,
                currency: currency,
                isPositive: balance >= 0
            )
        } catch {
            return LockScreenBalanceEntry(
                date: date,
                balance: 0.0,
                dailyNet: 0.0,
                currency: "USD",
                isPositive: true
            )
        }
    }
}

// MARK: - Circular View

@available(iOS 16.0, *)
struct LockScreenCircularView: View {
    let entry: LockScreenBalanceEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()

            VStack(spacing: 2) {
                // Balance indicator dot
                Circle()
                    .fill(entry.isPositive ? Color.green : Color.red)
                    .frame(width: 6, height: 6)

                // Balance amount (compact)
                Text(formatCompactAmount(entry.balance))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)

                // Currency symbol
                Text(CurrencyHelper.symbol(for: entry.currency))
                    .font(.system(size: 10, weight: .medium))
                    .opacity(0.7)
            }
        }
        .widgetURL(URL(string: "budgetmeter://home"))
    }

    /// Format amount for compact display (e.g., 1.2K, 45.5K, 1.2M)
    private func formatCompactAmount(_ amount: Double) -> String {
        let absAmount = abs(amount)
        let sign = amount < 0 ? "-" : ""

        if absAmount >= 1_000_000 {
            return String(format: "%@%.1fM", sign, absAmount / 1_000_000)
        } else if absAmount >= 1_000 {
            return String(format: "%@%.1fK", sign, absAmount / 1_000)
        } else {
            return String(format: "%@%.0f", sign, absAmount)
        }
    }
}

// MARK: - Rectangular View

@available(iOS 16.0, *)
struct LockScreenRectangularView: View {
    let entry: LockScreenBalanceEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Title row
            HStack {
                Text("widget.balance".localized(defaultValue: "Balance"))
                    .font(.system(size: 12, weight: .semibold))
                Spacer()
                Circle()
                    .fill(entry.isPositive ? Color.green : Color.red)
                    .frame(width: 6, height: 6)
            }

            // Balance amount
            Text(CurrencyHelper.formatAmount(entry.balance))
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.7)
                .lineLimit(1)

            // Daily net flow
            HStack(spacing: 4) {
                Text("widget.today".localized(defaultValue: "Today:"))
                    .font(.system(size: 11))
                    .opacity(0.7)

                Text(formatDailyNet(entry.dailyNet))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(entry.dailyNet >= 0 ? .green : .red)
            }
        }
        .widgetURL(URL(string: "budgetmeter://home"))
    }

    private func formatDailyNet(_ amount: Double) -> String {
        let sign = amount >= 0 ? "+" : ""
        return "\(sign)\(CurrencyHelper.formatAmount(amount))"
    }
}

// MARK: - Inline View

@available(iOS 16.0, *)
struct LockScreenInlineView: View {
    let entry: LockScreenBalanceEntry

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: entry.isPositive ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                .foregroundColor(entry.isPositive ? .green : .red)

            Text(CurrencyHelper.formatAmount(entry.balance))
                .font(.system(.body, design: .rounded).weight(.medium))
        }
        .widgetURL(URL(string: "budgetmeter://home"))
    }
}

// MARK: - Previews

@available(iOS 16.0, *)
#Preview("Circular", as: .accessoryCircular) {
    LockScreenBalanceCircular()
} timeline: {
    LockScreenBalanceEntry(
        date: Date(),
        balance: 1250.75,
        dailyNet: 45.50,
        currency: "USD",
        isPositive: true
    )
}

@available(iOS 16.0, *)
#Preview("Rectangular", as: .accessoryRectangular) {
    LockScreenBalanceRectangular()
} timeline: {
    LockScreenBalanceEntry(
        date: Date(),
        balance: 1250.75,
        dailyNet: 45.50,
        currency: "USD",
        isPositive: true
    )
}

@available(iOS 16.0, *)
#Preview("Inline", as: .accessoryInline) {
    LockScreenBalanceInline()
} timeline: {
    LockScreenBalanceEntry(
        date: Date(),
        balance: 1250.75,
        dailyNet: 45.50,
        currency: "USD",
        isPositive: true
    )
}
