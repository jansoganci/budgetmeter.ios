//
//  InsightsView.swift
//  BudgetMeter
//
//  Insights screen — v2 UI transformation (calm hierarchy, shared DesignSystem).
//

import SwiftUI

/// Main Insights screen — premium-gated analytics and calm money-pace insights.
struct InsightsView: View {

    @StateObject private var viewModel = InsightsViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                Group {
                    if viewModel.showPaywall && !viewModel.isPremium {
                        paywallView
                    } else if viewModel.isLoading {
                        loadingView
                    } else if !viewModel.hasEnoughData {
                        emptyStateView
                    } else {
                        contentView
                    }
                }
            }
            .navigationTitle("insights.nav.title".localized(defaultValue: "Insights"))
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $viewModel.showPaywall) {
                PremiumPaywallView(
                    feature: nil,
                    onDismiss: {
                        viewModel.dismissPaywall()
                    },
                    onPurchase: {
                        // Purchase handled by PremiumManager
                    },
                    onRestore: {
                        // Restore handled by PremiumManager
                    }
                )
            }
        }
    }

    // MARK: - Content

    private var contentView: some View {
        ScrollView {
            VStack(spacing: LayoutSpacing.sectionGap) {
                BudgetHeader(
                    title: "insights.nav.title".localized(defaultValue: "Insights"),
                    subtitle: "insights.header.subtitle".localized(defaultValue: "See your money pace changes in a simple way.")
                )

                insightsSummarySection
                    .transition(.opacity.combined(with: .move(edge: .top)))

                if #available(iOS 16.0, *) {
                    chartsSection
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .padding(.horizontal, LayoutSpacing.screenPadding)
            .padding(.vertical, Spacing.md)
            .animation(.easeInOut(duration: 0.3), value: viewModel.insights.count)
        }
        .background(AppBackground(ignoresSafeArea: false))
        .refreshable {
            await viewModel.refresh()
        }
    }

    // MARK: - Insights Summary

    private var insightsSummarySection: some View {
        VStack(alignment: .leading, spacing: LayoutSpacing.sectionGap) {
            if viewModel.insights.isEmpty {
                if viewModel.isLoading {
                    SkeletonPrimaryInsightCard()
                } else {
                    EmptyStateCard(
                        message: "insights.empty.message".localized(defaultValue: "No insights available yet. Add your income and expenses to see insights.")
                    )
                }
            } else {
                if let primary = primaryInsight {
                    PrimaryInsightHeroCard(insight: primary)
                }

                if !secondaryInsights.isEmpty {
                    SectionHeader(
                        title: "insights.section.title".localized(defaultValue: "Your Financial Insights")
                    )

                    LazyVGrid(
                        columns: [GridItem(.flexible()), GridItem(.flexible())],
                        spacing: LayoutSpacing.cardInternalGap
                    ) {
                        ForEach(secondaryInsights) { insight in
                            SecondaryInsightCard(insight: insight)
                        }
                    }
                }

                if !observationInsights.isEmpty {
                    observationSection
                }
            }
        }
    }

  private var observationSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: LayoutSpacing.cardInternalGap) {
                SectionHeader(
                    title: "insights.observation.title".localized(defaultValue: "Observations")
                )

                ForEach(observationInsights) { insight in
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        HStack {
                            Text(insight.title)
                                .cardLabelStyle(color: .textPrimary)

                            Spacer()

                            if let trend = insight.trend {
                                InsightTrendBadge(trend: trend)
                            }
                        }

                        if let description = insight.description {
                            Text(description)
                                .captionStyle(color: .textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    if insight.id != observationInsights.last?.id {
                        Divider()
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("insights.observation.title".localized(defaultValue: "Observations"))
    }

    // MARK: - Charts (trend → breakdown → comparison)

    @available(iOS 16.0, *)
    private var chartsSection: some View {
        VStack(spacing: LayoutSpacing.sectionGap) {
            if !viewModel.balanceTrend.isEmpty {
                BalanceTrendView(
                    snapshots: viewModel.balanceTrend,
                    days: 30
                )
            }

            if !viewModel.spendingBreakdown.isEmpty {
                SpendingBreakdownView(data: viewModel.spendingBreakdown)
            }

            if let comparison = viewModel.monthComparison {
                MonthComparisonView(
                    currentMonth: comparison.current,
                    previousMonth: comparison.previous
                )
            }
        }
    }

    // MARK: - Premium Gate

    private var paywallView: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            GlassCard {
                VStack(spacing: LayoutSpacing.cardInternalGap) {
                    VStack(spacing: Spacing.md) {
                        Text("insights.premium.title".localized(defaultValue: "Premium Feature"))
                            .sectionTitleStyle()
                            .multilineTextAlignment(.center)

                        Text("insights.premium.subtitle".localized(defaultValue: "Unlock Insights Dashboard with Premium"))
                            .cardLabelStyle()
                            .multilineTextAlignment(.center)

                        Text("insights.premium.description".localized(defaultValue: "Get automated financial insights, spending breakdowns, and trend analysis to make smarter money decisions."))
                            .bodyStyle(color: .textSecondary)
                            .multilineTextAlignment(.center)
                    }

                    PrimaryCTAButton(
                        title: "insights.premium.upgrade_button".localized(defaultValue: "Upgrade to Premium"),
                        action: { viewModel.upgradeToPremium() }
                    )
                }
            }
            .padding(.horizontal, LayoutSpacing.screenPadding)

            Spacer()
        }
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: Spacing.lg) {
            ProgressView()
            Text("insights.loading".localized(defaultValue: "Loading insights..."))
                .bodyStyle(color: .textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            EmptyStateCard(
                message: "insights.no_data.message".localized(defaultValue: "After you add a few incomes and expenses, your insights will appear here.")
            )
            .padding(.horizontal, LayoutSpacing.screenPadding)

            Spacer()
        }
    }

    // MARK: - Insight Selection (display-only)

    private var primaryInsight: Insight? {
        if let balanceTrend = viewModel.insights.first(where: { $0.icon == "chart.line.uptrend.xyaxis" }) {
            return balanceTrend
        }
        return viewModel.insights.first
    }

    private var secondaryInsights: [Insight] {
        guard let primary = primaryInsight else { return [] }
        return Array(viewModel.insights.filter { $0.id != primary.id }.prefix(4))
    }

    private var observationInsights: [Insight] {
        Array(viewModel.insights.filter { $0.description != nil }.prefix(2))
    }
}

// MARK: - Primary Insight Hero

private struct PrimaryInsightHeroCard: View {
    let insight: Insight

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: LayoutSpacing.cardInternalGap) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("insights.summary.title".localized(defaultValue: "Primary insight"))
                            .badgeStyle(color: .textSecondary)

                        Text(insight.title)
                            .cardLabelStyle(color: .textPrimary)
                    }

                    Spacer(minLength: Spacing.sm)

                    if let trend = insight.trend {
                        InsightTrendBadge(trend: trend)
                    }
                }

                Text(insight.value)
                    .metricLargeStyle(color: .textPrimary)

                if let description = insight.description {
                    Text(description)
                        .captionStyle(color: .textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(primaryAccessibilityLabel)
    }

    private var primaryAccessibilityLabel: String {
        var text = "\(insight.title): \(insight.value)"
        if let description = insight.description {
            text += ". \(description)"
        }
        return text
    }
}

// MARK: - Secondary Insight Card

private struct SecondaryInsightCard: View {
    let insight: Insight

    var body: some View {
        GlassCard(padding: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    Image(systemName: insight.icon)
                        .foregroundColor(insight.color)
                        .font(.body)
                        .accessibilityHidden(true)

                    Spacer()

                    if let trend = insight.trend {
                        InsightTrendBadge(trend: trend)
                    }
                }

                Text(insight.title)
                    .captionStyle(color: .textSecondary)
                    .lineLimit(2)

                Text(insight.value)
                    .metricCompactStyle(color: .textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(insight.title): \(insight.value)")
    }
}

// MARK: - Trend Badge

private struct InsightTrendBadge: View {
    let trend: Insight.Trend

    var body: some View {
        switch trend {
        case .up:
            StatusBadge(
                label: "insights.trend.increasing".localized(defaultValue: "increasing"),
                style: .positive,
                iconName: "arrow.up.right"
            )
        case .down:
            StatusBadge(
                label: "insights.trend.decreasing".localized(defaultValue: "decreasing"),
                style: .negative,
                iconName: "arrow.down.right"
            )
        case .neutral:
            StatusBadge(
                label: "insights.trend.stable".localized(defaultValue: "stable"),
                style: .neutral,
                iconName: "arrow.right"
            )
        }
    }
}

// MARK: - Skeleton

private struct SkeletonPrimaryInsightCard: View {
    @State private var isAnimating = false

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.chartTrack.opacity(0.35))
                    .frame(height: 12)
                    .frame(maxWidth: 100)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.chartTrack.opacity(0.35))
                    .frame(height: 28)
                    .frame(maxWidth: 180)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.chartTrack.opacity(0.35))
                    .frame(height: 10)
                    .frame(maxWidth: .infinity)
            }
        }
        .opacity(isAnimating ? 0.5 : 1.0)
        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)
        .onAppear { isAnimating = true }
    }
}

#Preview {
    InsightsView()
}
