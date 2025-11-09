//
//  InsightsView.swift
//  BudgetMeter
//
//  Phase 1B: Insights Dashboard
//  Created by BudgetMeter Team on 17.09.2025.
//

import SwiftUI
import Charts

/// Main view for Phase 1B Insights Dashboard
struct InsightsView: View {

    // MARK: - Properties

    @StateObject private var viewModel = InsightsViewModel()
    @Environment(\.colorScheme) var colorScheme

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.showPaywall && !viewModel.isPremium {
                    // Show paywall for non-premium users
                    paywallView
                } else if viewModel.isLoading {
                    // Loading state
                    loadingView
                } else if !viewModel.hasEnoughData {
                    // Empty state
                    emptyStateView
                } else {
                    // Main content
                    contentView
                }
            }
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $viewModel.showPaywall) {
                PremiumPaywallView(
                    feature: .insightsDashboard,
                    onDismiss: {
                        viewModel.dismissPaywall()
                    }
                )
            }
        }
    }

    // MARK: - Content View

    private var contentView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Insights Cards Section
                insightsSection

                // Charts Section
                if #available(iOS 16.0, *) {
                    chartsSection
                }
            }
            .padding()
        }
        .refreshable {
            await viewModel.refresh()
        }
    }

    // MARK: - Insights Section

    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Financial Insights")
                .font(.title2)
                .fontWeight(.bold)

            if viewModel.insights.isEmpty {
                Text("No insights available yet. Add your income and expenses to see insights.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(viewModel.insights) { insight in
                        InsightCardView(insight: insight)
                    }
                }
            }
        }
    }

    // MARK: - Charts Section

    @available(iOS 16.0, *)
    private var chartsSection: some View {
        VStack(spacing: 24) {
            // Spending Breakdown Pie Chart
            if !viewModel.spendingBreakdown.isEmpty {
                spendingBreakdownChart
            }

            // Month Comparison Bar Chart
            if viewModel.monthComparison != nil {
                monthComparisonChart
            }

            // Balance Trend Line Chart
            if !viewModel.balanceTrend.isEmpty {
                balanceTrendChart
            }
        }
    }

    // MARK: - Spending Breakdown Chart

    @available(iOS 16.0, *)
    private var spendingBreakdownChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Spending Breakdown")
                .font(.title3)
                .fontWeight(.semibold)

            if viewModel.pieChartData.isEmpty {
                Text("No spending data available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                // Simple pie chart representation
                VStack(spacing: 8) {
                    ForEach(Array(viewModel.pieChartData.enumerated()), id: \.offset) { index, data in
                        HStack {
                            Circle()
                                .fill(categoryColor(for: index))
                                .frame(width: 12, height: 12)

                            Text(DataSeedingService.displayName(for: data.0))
                                .font(.subheadline)

                            Spacer()

                            Text(CurrencyHelper.formatAmount(data.1))
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
    }

    // MARK: - Month Comparison Chart

    @available(iOS 16.0, *)
    private var monthComparisonChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Monthly Comparison")
                .font(.title3)
                .fontWeight(.semibold)

            if viewModel.barChartData.isEmpty {
                Text("Not enough data for comparison")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                VStack(spacing: 8) {
                    ForEach(viewModel.barChartData, id: \.0) { data in
                        HStack {
                            Text(data.0)
                                .font(.subheadline)
                                .frame(width: 100, alignment: .leading)

                            GeometryReader { geometry in
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(data.0 == "This Month" ? Color.blue : Color.gray.opacity(0.5))
                                    .frame(width: barWidth(for: data.1, in: geometry.size.width))
                                    .frame(height: 24)
                            }

                            Text(CurrencyHelper.formatAmount(data.1))
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .frame(width: 80, alignment: .trailing)
                        }
                        .frame(height: 24)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
    }

    // MARK: - Balance Trend Chart

    @available(iOS 16.0, *)
    private var balanceTrendChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Balance Trend (30 Days)")
                .font(.title3)
                .fontWeight(.semibold)

            if viewModel.lineChartData.isEmpty {
                Text("Not enough data for trend")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                Chart {
                    ForEach(viewModel.lineChartData, id: \.0) { dataPoint in
                        LineMark(
                            x: .value("Date", dataPoint.0),
                            y: .value("Balance", dataPoint.1)
                        )
                        .foregroundStyle(dataPoint.1 >= 0 ? Color.green : Color.red)
                    }
                }
                .frame(height: 200)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
    }

    // MARK: - Paywall View

    private var paywallView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "chart.bar.doc.horizontal.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)

            VStack(spacing: 12) {
                Text("Premium Feature")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Unlock Insights Dashboard with Premium")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                Text("Get automated financial insights, spending breakdowns, and trend analysis to make smarter money decisions.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Button {
                viewModel.upgradeToPremium()
            } label: {
                Text("Upgrade to Premium")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal)

            Spacer()
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading insights...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 80))
                .foregroundColor(.gray)

            VStack(spacing: 12) {
                Text("No Data Yet")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Add your income and expenses to see insights")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
        .padding()
    }

    // MARK: - Helper Methods

    private func categoryColor(for index: Int) -> Color {
        let colors: [Color] = [.blue, .green, .orange, .purple, .pink]
        return colors[index % colors.count]
    }

    private func barWidth(for value: Double, in totalWidth: Double) -> CGFloat {
        guard let maxValue = viewModel.barChartData.map({ $0.1 }).max(), maxValue > 0 else {
            return 0
        }
        return CGFloat((value / maxValue) * Double(totalWidth))
    }
}

// MARK: - Insight Card View

struct InsightCardView: View {
    let insight: Insight

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: insight.icon)
                    .foregroundColor(insight.color)
                    .font(.title3)

                Spacer()

                if let trend = insight.trend {
                    trendIcon(trend)
                }
            }

            Text(insight.title)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(insight.value)
                .font(.title3)
                .fontWeight(.bold)

            if let description = insight.description {
                Text(description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private func trendIcon(_ trend: Insight.Trend) -> some View {
        Group {
            switch trend {
            case .up:
                Image(systemName: "arrow.up.right")
                    .foregroundColor(.green)
            case .down:
                Image(systemName: "arrow.down.right")
                    .foregroundColor(.red)
            case .neutral:
                Image(systemName: "arrow.right")
                    .foregroundColor(.orange)
            }
        }
        .font(.caption)
    }
}

// MARK: - Premium Paywall View

struct PremiumPaywallView: View {
    let feature: PremiumFeatureType
    let onDismiss: () -> Void

    @StateObject private var premiumManager = PremiumManager.shared
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                // Feature icon and description
                VStack(spacing: 16) {
                    Image(systemName: featureIcon)
                        .font(.system(size: 80))
                        .foregroundColor(.blue)

                    Text(featureTitle)
                        .font(.title)
                        .fontWeight(.bold)

                    Text(featureDescription)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                // Premium features list
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(premiumFeatures, id: \.self) { feature in
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(feature)
                                .font(.subheadline)
                            Spacer()
                        }
                    }
                }
                .padding()

                Spacer()

                // Purchase button
                Button {
                    Task {
                        await premiumManager.purchasePremium()
                        dismiss()
                        onDismiss()
                    }
                } label: {
                    if premiumManager.isLoading {
                        ProgressView()
                            .tint(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        Text("Upgrade to Premium - $4.99")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
                .background(Color.blue)
                .cornerRadius(12)
                .padding(.horizontal)
                .disabled(premiumManager.isLoading)

                // Restore purchases
                Button {
                    Task {
                        await premiumManager.restorePurchases()
                        dismiss()
                        onDismiss()
                    }
                } label: {
                    Text("Restore Purchases")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .navigationTitle("Upgrade to Premium")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                        onDismiss()
                    }
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var featureIcon: String {
        switch feature {
        case .insightsDashboard:
            return "chart.bar.doc.horizontal.fill"
        case .advancedNotifications:
            return "bell.badge.fill"
        }
    }

    private var featureTitle: String {
        switch feature {
        case .insightsDashboard:
            return "Insights Dashboard"
        case .advancedNotifications:
            return "Smart Notifications"
        }
    }

    private var featureDescription: String {
        switch feature {
        case .insightsDashboard:
            return "Get automated insights, spending breakdowns, and trend analysis to make smarter financial decisions."
        case .advancedNotifications:
            return "Receive personalized notifications about your financial progress, milestones, and spending alerts."
        }
    }

    private var premiumFeatures: [String] {
        [
            "Automated Financial Insights",
            "Spending Breakdown Charts",
            "Balance Trend Analysis",
            "Month-over-Month Comparison",
            "Smart Notifications",
            "Unlimited Custom Categories",
            "All Premium Widgets"
        ]
    }
}

// MARK: - Supporting Types

enum PremiumFeatureType {
    case insightsDashboard
    case advancedNotifications
}

// MARK: - Preview

#Preview {
    InsightsView()
}
