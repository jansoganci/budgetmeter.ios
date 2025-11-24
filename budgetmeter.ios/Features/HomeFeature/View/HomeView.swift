//
//  HomeView.swift
//  BudgetMeter
//
//  Design System v2.0 - Modern Financial Dashboard
//  Created by BudgetMeter Team on 17.09.2025.
//

import SwiftUI
import CoreData

/// Home screen - Modern Financial Dashboard
struct HomeView: View {

    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    if viewModel.isLoading {
                        loadingView
                    } else if !viewModel.hasAnyData {
                        // First-time user experience
                        gettingStartedView
                    } else {
                        // Experienced user - Modern Financial Dashboard
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: Spacing.xl) {
                                // Daily Budget Card
                                dailyBudgetCard

                                // Hero Net Flow Card
                                heroNetFlowCard

                                // Health Score Card (prominent)
                                healthScoreCard

                                // Interval Metric Grid (Hourly, Daily, Monthly)
                                intervalMetricGrid

                                // Savings Goal Card (if goal is set)
                                if viewModel.savingsGoal > 0 {
                                    savingsGoalCard
                                }

                                // Quick Actions
                                quickActionsGrid
                            }
                            .padding(.bottom, Spacing.xl)
                        }
                        .padding(.horizontal, Spacing.lg)
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
        }
        .sheet(isPresented: $viewModel.showingExpenseSheet) {
            ExpenseView()
        }
        .sheet(isPresented: $viewModel.showingSavingsGoalSheet) {
            SavingsGoalInputView(
                currentGoal: viewModel.savingsGoal,
                currencySymbol: CurrencyHelper.symbol(for: viewModel.currencyCode),
                onSave: { amount in
                    viewModel.updateSavingsGoal(amount)
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $viewModel.showingDailyBudgetInfo) {
            DailyBudgetInfoView()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Daily Budget Card

    private var dailyBudgetCard: some View {
        DailyBudgetCard(
            amount: viewModel.dailyBudgetAmount,
            daysLeft: viewModel.daysLeftInMonth,
            monthlyNet: viewModel.monthlyNetFlow,
            currencySymbol: CurrencyHelper.symbol(for: viewModel.currencyCode),
            color: viewModel.dailyBudgetColor,
            onInfoTap: {
                viewModel.showDailyBudgetInfo()
            }
        )
    }

    // MARK: - Hero Net Flow Card

    private var heroNetFlowCard: some View {
        HeroNetFlowCard(
            value: viewModel.monthlyNetFlow,
            label: "home.net_flow_this_month".localized(defaultValue: "Net Flow This Month"),
            trendPercentage: viewModel.netFlowTrendPercentage,
            currencySymbol: CurrencyHelper.symbol(for: viewModel.currencyCode),
            onTap: nil
        )
    }

    // MARK: - Health Score Card

    private var healthScoreCard: some View {
        HealthScoreCard(
            score: viewModel.financialHealthScore,
            statusLabel: viewModel.financialHealthText,
            description: healthScoreDescription,
            onTap: {
                // TODO: Navigate to health details
            }
        )
    }

    private var healthScoreDescription: String? {
        switch viewModel.financialHealthScore {
        case 70...100:
            return "home.health.good".localized(defaultValue: "Your financial health is strong")
        case 40..<70:
            return "home.health.fair".localized(defaultValue: "Your financial health needs attention")
        default:
            return "home.health.poor".localized(defaultValue: "Let's work on improving your health")
        }
    }

    // MARK: - Interval Metric Grid

    private var intervalMetricGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ],
            spacing: Spacing.md
        ) {
            // Hourly Card
            IntervalMetricCard(
                title: "home.interval.hourly".localized(defaultValue: "Hourly"),
                value: viewModel.hourlyNetFlow,
                currencySymbol: CurrencyHelper.symbol(for: viewModel.currencyCode),
                chartData: viewModel.hourlyChartData,
                onTap: nil
            )

            // Daily Card
            IntervalMetricCard(
                title: "home.interval.daily".localized(defaultValue: "Daily"),
                value: viewModel.dailyNetFlow,
                currencySymbol: CurrencyHelper.symbol(for: viewModel.currencyCode),
                chartData: viewModel.dailyChartData,
                onTap: nil
            )

            // Monthly Card (full width)
            IntervalMetricCard(
                title: "home.interval.monthly".localized(defaultValue: "Monthly"),
                value: viewModel.monthlyNetFlow,
                currencySymbol: CurrencyHelper.symbol(for: viewModel.currencyCode),
                chartData: viewModel.monthlyChartData,
                onTap: nil
            )
            .gridCellColumns(2) // Full width on grid
        }
    }

    // MARK: - Savings Goal Card

    private var savingsGoalCard: some View {
        SavingsGoalCard(
            currentAmount: viewModel.liveValue > 0 ? viewModel.liveValue : 0,
            targetAmount: viewModel.savingsGoal,
            currencySymbol: CurrencyHelper.symbol(for: viewModel.currencyCode),
            targetDate: viewModel.timeToGoal.isEmpty ? nil : viewModel.timeToGoal,
            onTap: {
                viewModel.showSavingsGoalEntry()
            }
        )
    }

    // MARK: - Quick Actions Grid

    private var quickActionsGrid: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundColor(.brandProgress)
                Text("home.quick_actions.title".localized(defaultValue: "Quick Actions"))
                    .sectionTitleStyle()
                Spacer()
            }
            .padding(.horizontal, Spacing.xs)

            HStack(spacing: Spacing.sm) {
                // Add Income Button
                Button(action: viewModel.showIncomeEntry) {
                    VStack(spacing: Spacing.sm) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.brandPositive)

                        Text("home.quick_actions.add_income".localized(defaultValue: "Add Income"))
                            .cardLabelStyle(color: .textPrimary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: TouchTarget.large)
                    .background(Color.cardBackground)
                    .cornerRadius(CornerRadius.button)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("home.quick_actions.add_income".localized(defaultValue: "Add Income"))
                .accessibilityHint("home.quick_actions.add_income.hint".localized(defaultValue: "Tap to add income entry"))

                // Add Expense Button
                Button(action: viewModel.showExpenseEntry) {
                    VStack(spacing: Spacing.sm) {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.brandExpense)

                        Text("home.quick_actions.add_expense".localized(defaultValue: "Add Expense"))
                            .cardLabelStyle(color: .textPrimary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: TouchTarget.large)
                    .background(Color.cardBackground)
                    .cornerRadius(CornerRadius.button)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("home.quick_actions.add_expense".localized(defaultValue: "Add Expense"))
                .accessibilityHint("home.quick_actions.add_expense.hint".localized(defaultValue: "Tap to add expense entry"))

                // Savings Goal Button
                Button(action: viewModel.showSavingsGoalEntry) {
                    VStack(spacing: Spacing.sm) {
                        Image(systemName: "target")
                            .font(.system(size: 28))
                            .foregroundColor(.brandProgress)

                        Text(viewModel.savingsGoal > 0 ? "home.quick_actions.goal".localized(defaultValue: "Goal") : "home.quick_actions.set_goal".localized(defaultValue: "Set Goal"))
                            .cardLabelStyle(color: .textPrimary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: TouchTarget.large)
                    .background(Color.cardBackground)
                    .cornerRadius(CornerRadius.button)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(viewModel.savingsGoal > 0 ? "home.quick_actions.goal".localized(defaultValue: "Goal") : "home.quick_actions.set_goal".localized(defaultValue: "Set Goal"))
                .accessibilityHint("home.quick_actions.goal.hint".localized(defaultValue: "Tap to set or modify savings goal"))
            }
        }
    }

    // MARK: - Getting Started View

    private var gettingStartedView: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            // Welcome Hero
            VStack(spacing: Spacing.lg) {
                Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.brandProgress)

                Text("home.getting_started.title".localized(defaultValue: "Welcome to BudgetMeter"))
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.textPrimary)

                Text("home.getting_started.subtitle".localized(defaultValue: "Track your financial flow in real-time"))
                    .font(.body)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }

            // Quick Start Actions
            VStack(spacing: Spacing.md) {
                Button(action: viewModel.showIncomeEntry) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                        Text("home.getting_started.add_income".localized(defaultValue: "Add Your First Income"))
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: TouchTarget.recommended)
                    .background(Color.brandProgress)
                    .foregroundColor(.white)
                    .cornerRadius(CornerRadius.button)
                }
                .buttonStyle(.plain)

                Button(action: viewModel.showExpenseEntry) {
                    HStack {
                        Image(systemName: "minus.circle")
                            .font(.title2)
                        Text("home.getting_started.add_expense".localized(defaultValue: "Add Your First Expense"))
                            .font(.headline)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: TouchTarget.recommended)
                    .background(Color.cardBackground)
                    .foregroundColor(.textPrimary)
                    .cornerRadius(CornerRadius.button)
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.button)
                            .stroke(Color.chartInactive, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
        .padding(.horizontal, Spacing.xl)
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
    }
}

// MARK: - Daily Budget Info View

/// Information popup explaining how daily budget is calculated
struct DailyBudgetInfoView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    // Icon and Title
                    VStack(spacing: Spacing.md) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.brandProgress)

                        Text("home.daily_budget.info.title".localized(defaultValue: "Daily Budget"))
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, Spacing.lg)

                    // Description
                    Text("home.daily_budget.info.description".localized(
                        defaultValue: "This is your recommended daily spending limit based on your monthly income and expenses. It updates as the month progresses."
                    ))
                    .font(.body)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.leading)

                    // How It Works Section
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("home.daily_budget.info.how_title".localized(defaultValue: "How It Works"))
                            .font(.headline)
                            .fontWeight(.semibold)

                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            InfoBullet(text: "home.daily_budget.info.step1".localized(
                                defaultValue: "We calculate your monthly income minus expenses"))
                            InfoBullet(text: "home.daily_budget.info.step2".localized(
                                defaultValue: "We divide by the days remaining in the month"))
                            InfoBullet(text: "home.daily_budget.info.step3".localized(
                                defaultValue: "This gives you a safe daily spending limit"))
                        }
                    }

                    // Color Guide Section
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("home.daily_budget.info.colors_title".localized(defaultValue: "Color Guide"))
                            .font(.headline)
                            .fontWeight(.semibold)

                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            ColorGuideRow(color: .green, text: "home.daily_budget.info.green".localized(
                                defaultValue: "Green: Healthy budget (>$20/day)"))
                            ColorGuideRow(color: .yellow, text: "home.daily_budget.info.yellow".localized(
                                defaultValue: "Yellow: Low budget ($0-$20/day)"))
                            ColorGuideRow(color: .red, text: "home.daily_budget.info.red".localized(
                                defaultValue: "Red: Over budget (<$0/day)"))
                        }
                    }

                    // Note
                    Text("home.daily_budget.info.note".localized(
                        defaultValue: "Note: This is based on your recurring income and expense patterns, not actual daily spending."
                    ))
                    .font(.caption)
                    .foregroundColor(.textTertiary)
                    .italic()
                }
                .padding(Spacing.lg)
            }
            .background(Color.appBackground)
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

/// Info bullet point for Daily Budget Info
private struct InfoBullet: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Text("•")
                .font(.body)
                .foregroundColor(.textSecondary)
            Text(text)
                .font(.body)
                .foregroundColor(.textSecondary)
        }
    }
}

/// Color guide row for Daily Budget Info
private struct ColorGuideRow: View {
    let color: Color
    let text: String

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            Text(text)
                .font(.body)
                .foregroundColor(.textSecondary)
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
