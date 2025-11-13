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
