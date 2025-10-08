//
//  InsightsView.swift
//  BudgetMeter
//
//  Created by BudgetMeter Team on 17.09.2025.
//

import SwiftUI
import Charts

/// Spending Insights dashboard with charts and analytics
struct InsightsView: View {
    
    // MARK: - Properties
    
    @StateObject private var viewModel = InsightsViewModel()
    @State private var selectedTimeRange: TimeRange = .last6Months
    @State private var showingDetailSheet = false
    @State private var selectedChart: ChartType = .monthlyTrends
    
    // MARK: - Enums
    
    enum TimeRange: String, CaseIterable, Identifiable {
        case last3Months = "3months"
        case last6Months = "6months"
        case lastYear = "1year"
        case allTime = "all"
        
        var id: String { self.rawValue }
        
        var displayName: String {
            switch self {
            case .last3Months: return "insights.time_range.3_months".localized(defaultValue: "Last 3 Months")
            case .last6Months: return "insights.time_range.6_months".localized(defaultValue: "Last 6 Months")
            case .lastYear: return "insights.time_range.1_year".localized(defaultValue: "Last Year")
            case .allTime: return "insights.time_range.all_time".localized(defaultValue: "All Time")
            }
        }
    }
    
    enum ChartType: String, CaseIterable, Identifiable {
        case monthlyTrends = "monthly"
        case topCategories = "categories"
        case spendingPatterns = "patterns"
        case healthTrends = "health"
        
        var id: String { self.rawValue }
        
        var displayName: String {
            switch self {
            case .monthlyTrends: return "insights.chart.monthly_trends".localized(defaultValue: "Monthly Trends")
            case .topCategories: return "insights.chart.top_categories".localized(defaultValue: "Top Categories")
            case .spendingPatterns: return "insights.chart.spending_patterns".localized(defaultValue: "Spending Patterns")
            case .healthTrends: return "insights.chart.health_trends".localized(defaultValue: "Financial Health")
            }
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Summary Cards
                    summaryCardsSection
                    
                    // Time Range Picker
                    timeRangePicker
                    
                    // Charts Section
                    chartsSection
                    
                    // Quick Insights
                    quickInsightsSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .navigationTitle("insights.nav_title".localized(defaultValue: "Insights"))
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                viewModel.refresh()
            }
            .onAppear {
                viewModel.loadInsightsData()
            }
            .sheet(isPresented: $showingDetailSheet) {
                ChartDetailView(
                    chartType: selectedChart,
                    timeRange: selectedTimeRange,
                    viewModel: viewModel
                )
            }
        }
    }
    
    // MARK: - Summary Cards Section
    
    private var summaryCardsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(Color(hex: "4A90E2"))
                Text("insights.summary.title".localized(defaultValue: "Financial Summary"))
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding(.horizontal, 4)
            
            HStack(spacing: 12) {
                // Net Flow Card
                summaryCard(
                    title: "insights.summary.net_flow".localized(defaultValue: "Net Flow"),
                    value: viewModel.netFlow,
                    icon: "arrow.up.arrow.down",
                    color: viewModel.netFlow >= 0 ? .green : .red
                )
                
                // Savings Rate Card
                summaryCard(
                    title: "insights.summary.savings_rate".localized(defaultValue: "Savings Rate"),
                    value: viewModel.savingsRate,
                    icon: "percent",
                    color: .blue,
                    isPercentage: true
                )
                
                // Daily Average Card
                summaryCard(
                    title: "insights.summary.daily_avg".localized(defaultValue: "Daily Avg"),
                    value: viewModel.averageDailySpending,
                    icon: "calendar",
                    color: .orange
                )
            }
        }
    }
    
    private func summaryCard(title: String, value: Double, icon: String, color: Color, isPercentage: Bool = false) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Text(formatValue(value, isPercentage: isPercentage))
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 80)
        .padding(.vertical, 12)
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Time Range Picker
    
    private var timeRangePicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(Color(hex: "4A90E2"))
                Text("insights.time_range.title".localized(defaultValue: "Time Range"))
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding(.horizontal, 4)
            
            Picker("Time Range", selection: $selectedTimeRange) {
                ForEach(TimeRange.allCases) { range in
                    Text(range.displayName).tag(range)
                }
            }
            .pickerStyle(.segmented)
        }
    }
    
    // MARK: - Charts Section
    
    private var chartsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(Color(hex: "4A90E2"))
                Text("insights.charts.title".localized(defaultValue: "Charts & Analytics"))
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding(.horizontal, 4)
            
            // Monthly Trends Chart
            chartCard(
                title: "insights.chart.monthly_trends".localized(defaultValue: "Monthly Trends"),
                subtitle: "insights.chart.monthly_trends.subtitle".localized(defaultValue: "Income vs Expenses over time"),
                chartType: .monthlyTrends
            ) {
                MonthlyTrendsChart(trends: viewModel.monthlyTrends)
            }
            
            // Top Categories Chart
            chartCard(
                title: "insights.chart.top_categories".localized(defaultValue: "Top Spending Categories"),
                subtitle: "insights.chart.top_categories.subtitle".localized(defaultValue: "Where your money goes"),
                chartType: .topCategories
            ) {
                TopCategoriesChart(categories: viewModel.topCategories)
            }
            
            // Spending Patterns Chart
            chartCard(
                title: "insights.chart.spending_patterns".localized(defaultValue: "Spending Patterns"),
                subtitle: "insights.chart.spending_patterns.subtitle".localized(defaultValue: "Daily spending trends"),
                chartType: .spendingPatterns
            ) {
                SpendingPatternsChart(patterns: viewModel.spendingPatterns)
            }
            
            // Financial Health Chart
            chartCard(
                title: "insights.chart.health_trends".localized(defaultValue: "Financial Health"),
                subtitle: "insights.chart.health_trends.subtitle".localized(defaultValue: "Your financial wellness score"),
                chartType: .healthTrends
            ) {
                FinancialHealthChart(trends: viewModel.financialHealthTrends)
            }
        }
    }
    
    private func chartCard<Content: View>(
        title: String,
        subtitle: String,
        chartType: ChartType,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button {
                    selectedChart = chartType
                    showingDetailSheet = true
                } label: {
                    Image(systemName: "arrow.up.right.square")
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "4A90E2"))
                }
            }
            
            content()
                .frame(height: 200)
                .background(Color(uiColor: .secondarySystemBackground))
                .cornerRadius(12)
        }
        .padding()
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Quick Insights Section
    
    private var quickInsightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(Color(hex: "4A90E2"))
                Text("insights.quick_insights.title".localized(defaultValue: "Quick Insights"))
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding(.horizontal, 4)
            
            VStack(spacing: 8) {
                insightRow(
                    icon: "dollarsign.circle.fill",
                    title: "insights.insight.top_category".localized(defaultValue: "Top Spending Category"),
                    value: viewModel.topSpendingCategory,
                    color: .red
                )
                
                insightRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "insights.insight.monthly_income".localized(defaultValue: "Monthly Income"),
                    value: CurrencyHelper.formatAmount(viewModel.totalMonthlyIncome),
                    color: .green
                )
                
                insightRow(
                    icon: "chart.line.downtrend.xyaxis",
                    title: "insights.insight.monthly_expenses".localized(defaultValue: "Monthly Expenses"),
                    value: CurrencyHelper.formatAmount(viewModel.totalMonthlyExpenses),
                    color: .orange
                )
            }
        }
    }
    
    private func insightRow(icon: String, title: String, value: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(title)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(8)
    }
    
    // MARK: - Helper Methods
    
    private func formatValue(_ value: Double, isPercentage: Bool = false) -> String {
        if isPercentage {
            return String(format: "%.1f%%", value)
        } else {
            return CurrencyHelper.formatAmount(value)
        }
    }
}

// MARK: - Chart Components

struct MonthlyTrendsChart: View {
    let trends: [MonthlyTrend]
    
    var body: some View {
        Chart(trends) { trend in
            BarMark(
                x: .value("Month", trend.formattedMonth),
                y: .value("Income", trend.income)
            )
            .foregroundStyle(.green)
            .opacity(0.7)
            
            BarMark(
                x: .value("Month", trend.formattedMonth),
                y: .value("Expenses", trend.expenses)
            )
            .foregroundStyle(.red)
            .opacity(0.7)
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let amount = value.as(Double.self) {
                        Text(CurrencyHelper.formatAmount(amount))
                            .font(.caption)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks { value in
                AxisValueLabel {
                    if let month = value.as(String.self) {
                        Text(month)
                            .font(.caption)
                    }
                }
            }
        }
        .padding()
    }
}

struct TopCategoriesChart: View {
    let categories: [CategoryInsight]
    
    var body: some View {
        Chart(categories.prefix(5)) { category in
            BarMark(
                x: .value("Amount", category.totalAmount),
                y: .value("Category", category.name)
            )
            .foregroundStyle(.blue)
            .opacity(0.7)
        }
        .chartXAxis {
            AxisMarks(position: .bottom) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let amount = value.as(Double.self) {
                        Text(CurrencyHelper.formatAmount(amount))
                            .font(.caption)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisValueLabel {
                    if let name = value.as(String.self) {
                        Text(name)
                            .font(.caption)
                    }
                }
            }
        }
        .padding()
    }
}

struct SpendingPatternsChart: View {
    let patterns: [SpendingPattern]
    
    var body: some View {
        Chart(patterns.suffix(14)) { pattern in
            LineMark(
                x: .value("Date", pattern.date),
                y: .value("Spending", pattern.totalSpending)
            )
            .foregroundStyle(.orange)
            .lineStyle(StrokeStyle(lineWidth: 2))
            
            AreaMark(
                x: .value("Date", pattern.date),
                y: .value("Spending", pattern.totalSpending)
            )
            .foregroundStyle(.orange.opacity(0.3))
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let amount = value.as(Double.self) {
                        Text(CurrencyHelper.formatAmount(amount))
                            .font(.caption)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks { value in
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text(date, format: .dateTime.month(.abbreviated).day())
                            .font(.caption)
                    }
                }
            }
        }
        .padding()
    }
}

struct FinancialHealthChart: View {
    let trends: [HealthTrend]
    
    var body: some View {
        Chart(trends) { trend in
            LineMark(
                x: .value("Month", trend.month),
                y: .value("Health Score", trend.healthScore)
            )
            .foregroundStyle(.green)
            .lineStyle(StrokeStyle(lineWidth: 3))
            
            AreaMark(
                x: .value("Month", trend.month),
                y: .value("Health Score", trend.healthScore)
            )
            .foregroundStyle(.green.opacity(0.3))
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let score = value.as(Double.self) {
                        Text("\(Int(score))")
                            .font(.caption)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks { value in
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text(date, format: .dateTime.month(.abbreviated))
                            .font(.caption)
                    }
                }
            }
        }
        .padding()
    }
}

// MARK: - Chart Detail View

struct ChartDetailView: View {
    let chartType: InsightsView.ChartType
    let timeRange: InsightsView.TimeRange
    let viewModel: InsightsViewModel
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    switch chartType {
                    case .monthlyTrends:
                        MonthlyTrendsChart(trends: viewModel.monthlyTrends)
                            .frame(height: 400)
                    case .topCategories:
                        TopCategoriesChart(categories: viewModel.topCategories)
                            .frame(height: 400)
                    case .spendingPatterns:
                        SpendingPatternsChart(patterns: viewModel.spendingPatterns)
                            .frame(height: 400)
                    case .healthTrends:
                        FinancialHealthChart(trends: viewModel.financialHealthTrends)
                            .frame(height: 400)
                    }
                }
                .padding()
            }
            .navigationTitle(chartType.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("toolbar.done".localized(defaultValue: "Done")) {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    InsightsView()
}
