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
                    .transition(.opacity.combined(with: .move(edge: .top)))

                // Charts Section
                if #available(iOS 16.0, *) {
                    chartsSection
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .padding()
            .animation(.easeInOut(duration: 0.3), value: viewModel.insights.count)
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
                if viewModel.isLoading {
                    // Loading state with skeleton cards
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(0..<6, id: \.self) { _ in
                            SkeletonInsightCard()
                        }
                    }
                } else {
                    Text("No insights available yet. Add your income and expenses to see insights.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding()
                }
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(Array(viewModel.insights.enumerated()), id: \.element.id) { index, insight in
                        InsightCardView(insight: insight)
                            .transition(.asymmetric(
                                insertion: .scale.combined(with: .opacity),
                                removal: .opacity
                            ))
                            .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(Double(index) * 0.05), value: viewModel.insights.count)
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
                SpendingBreakdownView(data: viewModel.spendingBreakdown)
            }

            // Month Comparison Bar Chart
            if let comparison = viewModel.monthComparison {
                MonthComparisonView(
                    currentMonth: comparison.current,
                    previousMonth: comparison.previous
                )
            }

            // Balance Trend Line Chart
            if !viewModel.balanceTrend.isEmpty {
                BalanceTrendView(
                    snapshots: viewModel.balanceTrend,
                    days: 30
                )
            }
        }
    }

    // MARK: - Paywall View

    private var paywallView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "chart.bar.doc.horizontal.fill")
                .font(.system(size: 80))
                .foregroundColor(.brandProgress)

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
                    .background(Color.brandProgress)
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
                .foregroundColor(.chartInactive)

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
                    .accessibilityHidden(true)

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
        .background(Color.cardBackground)
        .cornerRadius(12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        var text = "\(insight.title): \(insight.value)"
        if let description = insight.description {
            text += ". \(description)"
        }
        if let trend = insight.trend {
            text += ". Trend: \(trendAccessibilityText(trend))"
        }
        return text
    }

    private func trendAccessibilityText(_ trend: Insight.Trend) -> String {
        switch trend {
        case .up: return "increasing"
        case .down: return "decreasing"
        case .neutral: return "stable"
        }
    }

    private func trendIcon(_ trend: Insight.Trend) -> some View {
        Group {
            switch trend {
            case .up:
                Image(systemName: "arrow.up.right")
                    .foregroundColor(.brandPositive)
            case .down:
                Image(systemName: "arrow.down.right")
                    .foregroundColor(.brandExpense)
            case .neutral:
                Image(systemName: "arrow.right")
                    .foregroundColor(.orange)
            }
        }
        .font(.caption)
        .accessibilityHidden(true)
    }
}

// MARK: - Skeleton Insight Card

struct SkeletonInsightCard: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 24, height: 24)

                Spacer()
            }

            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.3))
                .frame(height: 12)
                .frame(maxWidth: 80)

            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.3))
                .frame(height: 20)
                .frame(maxWidth: 120)

            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.3))
                .frame(height: 10)
                .frame(maxWidth: .infinity)
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)
        .opacity(isAnimating ? 0.5 : 1.0)
        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)
        .onAppear {
            isAnimating = true
        }
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
                        .foregroundColor(.brandProgress)

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
                                .foregroundColor(.brandPositive)
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
                .background(Color.brandProgress)
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
                        .foregroundColor(.brandProgress)
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
