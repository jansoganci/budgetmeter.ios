//
//  BalanceTrendView.swift
//  BudgetMeter
//
//  Phase 1B: Insights Dashboard - Chart Component
//  Created by BudgetMeter Team on 17.09.2025.
//

import SwiftUI
import Charts

/// Line chart view showing balance trend over time
struct BalanceTrendView: View {

    // MARK: - Properties

    let snapshots: [FinancialSnapshot]
    let days: Int
    @State private var selectedDate: Date?
    @State private var selectedBalance: Double?

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            headerView

            if snapshots.isEmpty {
                emptyStateView
            } else {
                VStack(spacing: 20) {
                    // Line chart
                    lineChartView

                    // Stats summary
                    statsView
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Balance trend chart showing your balance over the last \(days) days")
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.blue)
                    .font(.title3)

                Text("Balance Trend")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                if let trend = trendDirection {
                    HStack(spacing: 4) {
                        Image(systemName: trend.icon)
                            .font(.caption)
                        Text(trend.text)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(trend.color)
                }
            }

            Text("Last \(days) days")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Line Chart

    private var lineChartView: some View {
        Chart {
            ForEach(Array(snapshots.enumerated()), id: \.offset) { _, snapshot in
                if let date = snapshot.date {
                    // Line mark
                    LineMark(
                        x: .value("Date", date),
                        y: .value("Balance", snapshot.balance)
                    )
                    .foregroundStyle(snapshot.balance >= 0 ? Color.green.gradient : Color.red.gradient)
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.catmullRom)

                    // Area mark
                    AreaMark(
                        x: .value("Date", date),
                        y: .value("Balance", snapshot.balance)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                snapshot.balance >= 0 ? Color.green.opacity(0.3) : Color.red.opacity(0.3),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)

                    // Point mark for selected date
                    if let selectedDate = selectedDate,
                       Calendar.current.isDate(date, inSameDayAs: selectedDate) {
                        PointMark(
                            x: .value("Date", date),
                            y: .value("Balance", snapshot.balance)
                        )
                        .foregroundStyle(snapshot.balance >= 0 ? Color.green : Color.red)
                        .symbolSize(100)
                    }
                }
            }

            // Zero line
            RuleMark(y: .value("Zero", 0))
                .foregroundStyle(Color.gray.opacity(0.3))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
        }
        .frame(height: 250)
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: max(days / 5, 1))) { value in
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    .font(.caption)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                    .foregroundStyle(Color.gray.opacity(0.2))
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
                                    if let snapshot = snapshots.first(where: { Calendar.current.isDate($0.date ?? Date(), inSameDayAs: date) }) {
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
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(CurrencyHelper.formatAmount(selectedBalance))
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(selectedBalance >= 0 ? .green : .red)
                }
                .padding(8)
                .background(Color(.systemBackground))
                .cornerRadius(8)
                .shadow(radius: 4)
                .padding()
            }
        }
    }

    // MARK: - Stats View

    private var statsView: some View {
        HStack(spacing: 16) {
            // Highest balance
            statCard(
                title: "Highest",
                value: highestBalance,
                color: .green,
                icon: "arrow.up.circle.fill"
            )

            Divider()
                .frame(height: 50)

            // Lowest balance
            statCard(
                title: "Lowest",
                value: lowestBalance,
                color: lowestBalance >= 0 ? .blue : .red,
                icon: "arrow.down.circle.fill"
            )

            Divider()
                .frame(height: 50)

            // Average balance
            statCard(
                title: "Average",
                value: averageBalance,
                color: .orange,
                icon: "chart.line.flattrend.xyaxis"
            )
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private func statCard(title: String, value: Double, color: Color, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(CurrencyHelper.formatAmount(value))
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.downtrend.xyaxis")
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.5))

            Text("No trend data")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("Add financial data to see your balance trend")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Computed Properties

    private var highestBalance: Double {
        snapshots.map { $0.balance }.max() ?? 0
    }

    private var lowestBalance: Double {
        snapshots.map { $0.balance }.min() ?? 0
    }

    private var averageBalance: Double {
        guard !snapshots.isEmpty else { return 0 }
        return snapshots.reduce(0) { $0 + $1.balance } / Double(snapshots.count)
    }

    private var trendDirection: (icon: String, text: String, color: Color)? {
        guard snapshots.count >= 2 else { return nil }

        let recentBalances = snapshots.suffix(7).map { $0.balance }
        let olderBalances = snapshots.prefix(7).map { $0.balance }

        let recentAvg = recentBalances.reduce(0, +) / Double(recentBalances.count)
        let olderAvg = olderBalances.reduce(0, +) / Double(olderBalances.count)

        let change = recentAvg - olderAvg

        if abs(change) < 10 {
            return ("arrow.right", "Stable", .orange)
        } else if change > 0 {
            return ("arrow.up.right", "Improving", .green)
        } else {
            return ("arrow.down.right", "Declining", .red)
        }
    }

    // MARK: - Helper Methods

    private func formatShortAmount(_ amount: Double) -> String {
        let absAmount = abs(amount)
        if absAmount >= 1000 {
            return String(format: "%@%.1fk", amount < 0 ? "-" : "", absAmount / 1000)
        }
        return String(format: "%.0f", amount)
    }
}

// MARK: - Preview

#Preview {
    let context = PersistenceService.shared.viewContext
    let calendar = Calendar.current

    let snapshots = (0..<30).map { day -> FinancialSnapshot in
        let snapshot = FinancialSnapshot(context: context)
        snapshot.date = calendar.date(byAdding: .day, value: -day, to: Date())
        snapshot.balance = Double.random(in: -500...2000) + (Double(30 - day) * 30) // Upward trend
        return snapshot
    }.reversed()

    BalanceTrendView(snapshots: Array(snapshots), days: 30)
        .padding()
}
