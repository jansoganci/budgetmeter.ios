//
//  HomeView.swift
//  BudgetMeter
//
//  Home screen — daily money pace dashboard (v2 transformation).
//

import SwiftUI
import CoreData

/// Home screen — daily money pace as visual hero.
struct HomeView: View {

    @StateObject private var viewModel = HomeViewModel()
    @StateObject private var premiumManager = PremiumManager.shared
    @Environment(\.sizeCategory) var sizeCategory

    private enum HomeScrollTarget {
        static let hero = "home-hero"
    }

    var body: some View {
        NavigationView {
            ZStack {
                AppBackground()

                VStack(spacing: 0) {
                    if viewModel.isLoading {
                        loadingView
                    } else if !viewModel.hasAnyData {
                        gettingStartedView
                    } else {
                        ScrollViewReader { proxy in
                            ScrollView(showsIndicators: false) {
                                VStack(spacing: LayoutSpacing.sectionGap) {
                                    BudgetHeader(timeBasedGreeting: true)

                                    moneyPaceHeroSection
                                        .id(HomeScrollTarget.hero)

                                    if hasPaceDetailContent {
                                        paceDetailSection
                                    }

                                    monthSummarySection

                                    healthAndSavingsRow

                                    quickActionsGrid
                                }
                                .padding(.horizontal, LayoutSpacing.screenPadding)
                                .padding(.bottom, Spacing.xl)
                            }
                            .onReceive(NotificationCenter.default.publisher(for: .focusHomeHero)) { _ in
                                withAnimation(.easeInOut(duration: 0.35)) {
                                    proxy.scrollTo(HomeScrollTarget.hero, anchor: .top)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("tab.home.title".localized(defaultValue: "Home"))
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                viewModel.refresh()
            }
        }
        .onAppear {
            viewModel.refresh()
        }
        .sheet(isPresented: $viewModel.showingIncomeSheet) {
            IncomeView()
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $viewModel.showingExpenseSheet) {
            ExpenseView()
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $viewModel.showingSavingsGoalSheet) {
            if shouldOpenFullAddGoalFlow {
                SavingsGoalInputView(goal: nil, onSave: {})
                    .onDisappear {
                        viewModel.refresh()
                    }
                    .presentationDragIndicator(.visible)
            } else {
                QuickSavingsGoalInputView(
                    currentGoal: viewModel.savingsGoal,
                    currencySymbol: viewModel.currencySymbol,
                    onSave: { amount in
                        viewModel.updateSavingsGoal(amount)
                    }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
        .sheet(isPresented: $viewModel.showingDailyBudgetInfo) {
            DailyBudgetInfoView()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    private var shouldOpenFullAddGoalFlow: Bool {
        premiumManager.hasAccess(to: .multipleSavingsGoals)
            && SavingsGoalManager.shared.canCreateAdditionalGoal()
    }

    // MARK: - Money Pace Hero

    private var moneyPaceHeroSection: some View {
        MoneyPaceHeroCard(
            paceStatus: viewModel.paceStatus,
            paceStatusCopy: viewModel.paceStatusCopy,
            netDailyPace: viewModel.netDailyPace,
            netMinutePace: viewModel.netMinutePace,
            currencySymbol: viewModel.currencySymbol
        )
    }

    private var hasPaceDetailContent: Bool {
        viewModel.biggestDrain != nil
            || viewModel.savingsRemaining > 0
            || !viewModel.timeToGoal.isEmpty
    }

    private var paceDetailSection: some View {
        GlassCard {
            VStack(spacing: LayoutSpacing.cardInternalGap) {
                if let drain = viewModel.biggestDrain {
                    HomePaceDrainRow(
                        drain: drain,
                        currencySymbol: viewModel.currencySymbol
                    )
                }

                if viewModel.savingsRemaining > 0 || !viewModel.timeToGoal.isEmpty {
                    HomePaceSavingsRow(
                        savingsRemaining: viewModel.savingsRemaining,
                        savingsTimeLabel: viewModel.timeToGoal,
                        currencySymbol: viewModel.currencySymbol
                    )
                }
            }
        }
    }

    // MARK: - Month Summary Section

    private var monthSummarySection: some View {
        VStack(alignment: .leading, spacing: LayoutSpacing.cardInternalGap) {
            SectionHeader(
                title: String(localized: "home.section.this_month", defaultValue: "This Month")
            )

            HStack(spacing: Spacing.md) {
                MonthSummaryCard(
                    type: .income,
                    amount: viewModel.totalMonthlyIncomeDisplay,
                    currencySymbol: viewModel.currencySymbol,
                    trendPercentage: viewModel.incomeTrendPercentage
                )

                MonthSummaryCard(
                    type: .expenses,
                    amount: viewModel.totalMonthlyExpenseDisplay,
                    currencySymbol: viewModel.currencySymbol,
                    trendPercentage: viewModel.expenseTrendPercentage
                )

                MonthSummaryCard(
                    type: .net,
                    amount: viewModel.monthlyNetFlow,
                    currencySymbol: viewModel.currencySymbol,
                    trendPercentage: viewModel.netFlowTrendPercentage
                )
            }
        }
    }

    // MARK: - Health + Savings Row

    private var healthAndSavingsRow: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            CompactHealthCard(
                score: viewModel.financialHealthScore,
                onTap: {
                    // TODO: Navigate to health details
                }
            )
            .frame(maxWidth: .infinity)

            CompactSavingsCarouselCard(
                goals: viewModel.homeSavingsGoals,
                currencySymbol: viewModel.currencySymbol,
                fallbackTargetAmount: viewModel.savingsGoal,
                onTap: {
                    viewModel.showSavingsGoalEntry()
                }
            )
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Quick Actions

    private var quickActionsGrid: some View {
        VStack(alignment: .leading, spacing: LayoutSpacing.cardInternalGap) {
            SectionHeader(
                title: "home.quick_actions.title".localized(defaultValue: "Quick Actions")
            )

            HStack(spacing: Spacing.md) {
                quickActionButton(
                    iconName: "plus.circle.fill",
                    iconColor: .brandPositive,
                    title: "home.quick_actions.add_income".localized(defaultValue: "Add Income"),
                    hint: "home.quick_actions.add_income.hint".localized(defaultValue: "Tap to add income entry"),
                    action: viewModel.showIncomeEntry
                )

                quickActionButton(
                    iconName: "minus.circle.fill",
                    iconColor: .brandExpense,
                    title: "home.quick_actions.add_expense".localized(defaultValue: "Add Expense"),
                    hint: "home.quick_actions.add_expense.hint".localized(defaultValue: "Tap to add expense entry"),
                    action: viewModel.showExpenseEntry
                )

                quickActionButton(
                    iconName: "target",
                    iconColor: .brandProgress,
                    title: viewModel.savingsGoal > 0
                        ? "home.quick_actions.goal".localized(defaultValue: "Goal")
                        : "home.quick_actions.set_goal".localized(defaultValue: "Set Goal"),
                    hint: "home.quick_actions.goal.hint".localized(defaultValue: "Tap to set or modify savings goal"),
                    action: viewModel.showSavingsGoalEntry
                )
            }
        }
    }

    private func quickActionButton(
        iconName: String,
        iconColor: Color,
        title: String,
        hint: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: Spacing.sm) {
                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundColor(iconColor)

                Text(title)
                    .cardLabelStyle(color: .textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: TouchTarget.large)
            .padding(LayoutSpacing.cardPadding)
            .background(Color.surfaceCard)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.button, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.button, style: .continuous)
                    .stroke(Color.borderSubtle, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityHint(hint)
    }

    // MARK: - Getting Started View

    private var gettingStartedView: some View {
        VStack(spacing: LayoutSpacing.sectionGap) {
            Spacer()

            VStack(spacing: LayoutSpacing.cardInternalGap) {
                Text("home.getting_started.title".localized(defaultValue: "Welcome to BudgetMeter"))
                    .sectionTitleStyle()
                    .multilineTextAlignment(.center)

                EmptyStateCard(
                    message: "home.getting_started.subtitle".localized(defaultValue: "Track your financial flow in real-time")
                )
            }

            VStack(spacing: Spacing.md) {
                PrimaryCTAButton(
                    title: "home.getting_started.add_income".localized(defaultValue: "Add Your First Income"),
                    action: viewModel.showIncomeEntry
                )
                .accessibilityHint("home.getting_started.add_income.hint".localized(defaultValue: "Double tap to add your first income source"))

                SecondaryCTAButton(
                    title: "home.getting_started.add_expense".localized(defaultValue: "Add Your First Expense"),
                    action: viewModel.showExpenseEntry
                )
                .accessibilityHint("home.getting_started.add_expense.hint".localized(defaultValue: "Double tap to add your first expense"))
            }

            PulseyMascotView(state: .empty, size: 48)
                .padding(.top, Spacing.sm)
                .accessibilityHidden(true)

            Spacer()
        }
        .padding(.horizontal, LayoutSpacing.screenPadding)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: Spacing.lg) {
            ProgressView()
                .scaleEffect(1.2)
            Text("home.loading".localized(defaultValue: "Loading..."))
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("home.loading".localized(defaultValue: "Loading"))
    }
}

// MARK: - Pace detail rows (secondary to hero)

private struct HomePaceDrainRow: View {
    let drain: DrainItem
    let currencySymbol: String

    var body: some View {
        HStack(spacing: LayoutSpacing.rowGap) {
            Image(systemName: "drop.fill")
                .foregroundColor(.financialNegative)
            VStack(alignment: .leading, spacing: 2) {
                Text("home.momentum.biggest_drain".localized(defaultValue: "Biggest expense", table: "Home"))
                    .captionStyle()
                Text(drain.label)
                    .metricCompactStyle(color: .textPrimary)
            }
            Spacer()
            Text(formatCurrency(drain.amountInPeriod))
                .metricCompactStyle(color: .financialNegative)
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        let formatted = formatter.string(from: NSNumber(value: amount)) ?? "0"
        return "\(currencySymbol)\(formatted)"
    }
}

private struct HomePaceSavingsRow: View {
    let savingsRemaining: Double
    let savingsTimeLabel: String
    let currencySymbol: String

    var body: some View {
        HStack(spacing: LayoutSpacing.rowGap) {
            Image(systemName: "target")
                .foregroundColor(.accentPrimary)
            VStack(alignment: .leading, spacing: 2) {
                Text("home.momentum.savings_remaining".localized(defaultValue: "Goal remaining", table: "Home"))
                    .captionStyle()
                if savingsRemaining > 0 {
                    Text(formatCurrency(savingsRemaining))
                        .metricCompactStyle(color: .textPrimary)
                }
            }
            Spacer()
            if !savingsTimeLabel.isEmpty {
                Text(savingsTimeLabel)
                    .captionStyle()
                    .multilineTextAlignment(.trailing)
            }
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        let formatted = formatter.string(from: NSNumber(value: amount)) ?? "0"
        return "\(currencySymbol)\(formatted)"
    }
}

// MARK: - Daily Budget Info View

/// Information popup explaining how daily budget is calculated
struct DailyBudgetInfoView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.sizeCategory) private var sizeCategory

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    VStack(spacing: Spacing.md) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 60 * sizeCategory.scaleFactor))
                            .foregroundColor(.brandProgress)

                        Text("home.daily_budget.info.title".localized(defaultValue: "Daily Budget"))
                            .sectionTitleStyle()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, Spacing.lg)

                    Text("home.daily_budget.info.description".localized(
                        defaultValue: "This is your recommended daily spending limit based on your monthly income and expenses. It updates as the month progresses."
                    ))
                    .bodyStyle(color: .textSecondary)
                    .multilineTextAlignment(.leading)

                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("home.daily_budget.info.how_title".localized(defaultValue: "How It Works"))
                            .cardLabelStyle(color: .textPrimary)

                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            InfoBullet(text: "home.daily_budget.info.step1".localized(
                                defaultValue: "We calculate your monthly income minus expenses"))
                            InfoBullet(text: "home.daily_budget.info.step2".localized(
                                defaultValue: "We divide by the days remaining in the month"))
                            InfoBullet(text: "home.daily_budget.info.step3".localized(
                                defaultValue: "This gives you a safe daily spending limit"))
                        }
                    }

                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("home.daily_budget.info.colors_title".localized(defaultValue: "Color Guide"))
                            .cardLabelStyle(color: .textPrimary)

                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            ColorGuideRow(color: .financialPositive, text: "home.daily_budget.info.green".localized(
                                defaultValue: "Green: Healthy budget (>$20/day)"))
                            ColorGuideRow(color: .financialCaution, text: "home.daily_budget.info.yellow".localized(
                                defaultValue: "Yellow: Low budget ($0-$20/day)"))
                            ColorGuideRow(color: .financialNegative, text: "home.daily_budget.info.red".localized(
                                defaultValue: "Red: Over budget (<$0/day)"))
                        }
                    }

                    Text("home.daily_budget.info.note".localized(
                        defaultValue: "Note: This is based on your recurring income and expense patterns, not actual daily spending."
                    ))
                    .captionStyle(color: .textSecondary)
                    .italic()
                }
                .padding(Spacing.lg)
            }
            .background(AppBackground(ignoresSafeArea: false))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
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

private struct InfoBullet: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Text("•")
                .font(.body)
                .foregroundColor(.textSecondary)
            Text(text)
                .bodyStyle(color: .textSecondary)
        }
    }
}

private struct ColorGuideRow: View {
    let color: Color
    let text: String

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            Text(text)
                .bodyStyle(color: .textSecondary)
        }
    }
}

// MARK: - Preview

#Preview {
    HomeView()
        .environment(\.managedObjectContext, PersistenceService.shared.viewContext)
}

#Preview("Dark Mode") {
    HomeView()
        .environment(\.managedObjectContext, PersistenceService.shared.viewContext)
        .preferredColorScheme(.dark)
}
