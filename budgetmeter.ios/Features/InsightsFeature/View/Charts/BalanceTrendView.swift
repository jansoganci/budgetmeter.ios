//
//  BalanceTrendView.swift
//  BudgetMeter
//
//  Balance trend line chart — ChartCard wrapper, calm presentation.
//

import SwiftUI
import Charts

/// Line chart showing balance trend over time.
struct BalanceTrendView: View {

    let snapshots: [FinancialSnapshot]
    let days: Int

    @State private var selectedDate: Date?
    @State private var selectedBalance: Double?

    var body: some View {
        ChartCard(
            title: "charts.balance_trend.title".localized(defaultValue: "Balance Trend"),
            subtitle: String(format: "charts.balance_trend.subtitle".localized(defaultValue: "Last %d days"), days)
        ) {
            if snapshots.isEmpty {
                compactEmptyState
            } else {
                VStack(spacing: Spacing.lg) {
                    if let trend = trendDirection {
                        HStack {
                            StatusBadge(label: trend.text, style: trend.style, iconName: trend.icon)
                            Spacer()
                        }
                    }

                    lineChartView

                    statsView
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(
            "charts.balance_trend.title".localized(defaultValue: "Balance Trend")
        )
    }

    // MARK: - Line Chart

    private var lineChartView: some View {
        Chart {
            ForEach(Array(snapshots.enumerated()), id: \.offset) { _, snapshot in
                if let date = snapshot.date {
                    LineMark(
                        x: .value("Date", date),
                        y: .value("Balance", snapshot.balance)
                    )
                    .foregroundStyle(snapshot.balance >= 0 ? Color.financialPositive : Color.financialNegative)
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Date", date),
                        y: .value("Balance", snapshot.balance)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                snapshot.balance >= 0
                                    ? Color.financialPositive.opacity(0.12)
                                    : Color.financialNegative.opacity(0.12),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)

                    if let selectedDate = selectedDate,
                       Calendar.current.isDate(date, inSameDayAs: selectedDate) {
                        PointMark(
                            x: .value("Date", date),
                            y: .value("Balance", snapshot.balance)
                        )
                        .foregroundStyle(snapshot.balance >= 0 ? Color.financialPositive : Color.financialNegative)
                        .symbolSize(80)
                    }
                }
            }

            RuleMark(y: .value("Zero", 0))
                .foregroundStyle(Color.chartTrack.opacity(0.7))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
        }
        .frame(height: ChartDimensions.miniChartHeight + 80)
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: max(days / 5, 1))) { _ in
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    .font(.caption)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                    .foregroundStyle(Color.chartTrack.opacity(0.6))
                AxisValueLabel {
                    if let amount = value.as(Double.self) {
                        Text(formatShortAmount(amount))
                            .font(.caption)
                    }
                }
            }
        }
        .chartXSelection(value: $selectedDate)
        .chartBackground { chartProxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                guard let plotFrame = chartProxy.plotFrame else { return }
                                let x = value.location.x - geometry[plotFrame].origin.x
                                if let date: Date = chartProxy.value(atX: x) {
                                    selectedDate = date
                                    if let snapshot = snapshots.first(where: {
                                        Calendar.current.isDate($0.date ?? Date(), inSameDayAs: date)
                                    }) {
                                        selectedBalance = snapshot.balance
                                    }
                                }
                            }
                            .onEnded { _ in
                                selectedDate = nil
                                selectedBalance = nil
                            }
                    )
            }
        }
        .overlay(alignment: .topLeading) {
            if let selectedDate = selectedDate, let selectedBalance = selectedBalance {
                VStack(alignment: .leading, spacing: 4) {
                    Text(selectedDate, format: .dateTime.month().day().year())
                        .captionStyle()
                    Text(CurrencyHelper.formatAmount(selectedBalance))
                        .metricCompactStyle(
                            color: selectedBalance >= 0 ? .financialPositive : .financialNegative
                        )
                }
                .padding(Spacing.sm)
                .glassSurface()
                .padding(Spacing.sm)
            }
        }
    }

    // MARK: - Stats

    private var statsView: some View {
        HStack(spacing: Spacing.md) {
            MetricCard(
                label: "charts.stat.highest".localized(defaultValue: "Highest"),
                amount: highestBalance,
                accentColor: .financialPositive
            )
            MetricCard(
                label: "charts.stat.lowest".localized(defaultValue: "Lowest"),
                amount: lowestBalance,
                accentColor: lowestBalance >= 0 ? .financialPositiveCalm : .financialNegative
            )
            MetricCard(
                label: "charts.stat.average".localized(defaultValue: "Average"),
                amount: averageBalance,
                accentColor: .financialNeutral
            )
        }
    }

  private var compactEmptyState: some View {
        Text("charts.balance_trend.empty.message".localized(defaultValue: "Add financial data to see your balance trend"))
            .captionStyle(color: .textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, Spacing.md)
    }

    // MARK: - Computed

    private var highestBalance: Double {
        snapshots.map(\.balance).max() ?? 0
    }

    private var lowestBalance: Double {
        snapshots.map(\.balance).min() ?? 0
    }

    private var averageBalance: Double {
        guard !snapshots.isEmpty else { return 0 }
        return snapshots.reduce(0) { $0 + $1.balance } / Double(snapshots.count)
    }

    private var trendDirection: (icon: String, text: String, style: StatusBadgeStyle)? {
        guard snapshots.count >= 2 else { return nil }

        let recentBalances = snapshots.suffix(7).map(\.balance)
        let olderBalances = snapshots.prefix(7).map(\.balance)

        let recentAvg = recentBalances.reduce(0, +) / Double(recentBalances.count)
        let olderAvg = olderBalances.reduce(0, +) / Double(olderBalances.count)
        let change = recentAvg - olderAvg

        if abs(change) < 10 {
            return (
                "arrow.right",
                "charts.trend.stable".localized(defaultValue: "Stable"),
                .neutral
            )
        } else if change > 0 {
            return (
                "arrow.up.right",
                "charts.trend.improving".localized(defaultValue: "Improving"),
                .positive
            )
        } else {
            return (
                "arrow.down.right",
                "charts.trend.declining".localized(defaultValue: "Declining"),
                .negative
            )
        }
    }

    private func formatShortAmount(_ amount: Double) -> String {
        let absAmount = abs(amount)
        if absAmount >= 1000 {
            return String(format: "%@%.1fk", amount < 0 ? "-" : "", absAmount / 1000)
        }
        return String(format: "%.0f", amount)
    }
}

#Preview {
    let context = PersistenceService.shared.viewContext
    let calendar = Calendar.current

    let snapshots = (0..<30).map { day -> FinancialSnapshot in
        let snapshot = FinancialSnapshot(context: context)
        snapshot.date = calendar.date(byAdding: .day, value: -day, to: Date())
        snapshot.balance = Double.random(in: -500...2000) + (Double(30 - day) * 30)
        return snapshot
    }.reversed()

    BalanceTrendView(snapshots: Array(snapshots), days: 30)
        .padding()
        .background(Color.appBackground)
}
