//
//  HomeView.swift
//  BudgetMeter
//
//  Design System v2.1 - Compact Financial Dashboard
//  Created by BudgetMeter Team on 17.09.2025.
//

import SwiftUI
import CoreData

/// Home screen - Compact Financial Dashboard (v2.1)
struct HomeView: View {

    @StateObject private var viewModel = HomeViewModel()
    @Environment(\.sizeCategory) var sizeCategory

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
                        // Compact Financial Dashboard (v2.1)
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: Spacing.lg) {
                                // 1. Greeting Header
                                greetingHeader

                                // 2. Compact Daily Budget Card (100pt)
                                compactDailyBudgetCard

                                // 3. Month Summary Section (3-column)
                                monthSummarySection

                                // 4. Health + Savings Row (2-column, 90pt)
                                healthAndSavingsRow

                                // 5. Quick Actions
                                quickActionsGrid
                            }
                            .padding(.horizontal, Spacing.lg)
                            .padding(.bottom, Spacing.xl)
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
        }
        .sheet(isPresented: $viewModel.showingExpenseSheet) {
            ExpenseView()
        }
        .sheet(isPresented: $viewModel.showingSavingsGoalSheet) {
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
        .sheet(isPresented: $viewModel.showingDailyBudgetInfo) {
            DailyBudgetInfoView()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Greeting Header

    private var greetingHeader: some View {
        GreetingHeader(
            greeting: viewModel.greetingText,
            iconName: viewModel.greetingIcon
        )
    }

    // MARK: - Compact Daily Budget Card (100pt)

    private var compactDailyBudgetCard: some View {
        CompactDailyBudgetCard(
            amount: viewModel.dailyBudgetAmount,
            daysLeft: viewModel.daysLeftInMonth,
            totalDays: viewModel.totalDaysInMonth,
            currencySymbol: viewModel.currencySymbol,
            statusColor: viewModel.dailyBudgetColor,
            onInfoTap: {
                viewModel.showDailyBudgetInfo()
            }
        )
    }

    // MARK: - Month Summary Section (3-column)

    private var monthSummarySection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(String(localized: "home.section.this_month", defaultValue: "This Month"))
                .font(.system(size: 14 * sizeCategory.scaleFactor, weight: .semibold))
                .foregroundColor(.textSecondary)
                .padding(.leading, Spacing.xs)

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

    // MARK: - Health + Savings Row (2-column, 90pt)

    private var healthAndSavingsRow: some View {
        HStack(spacing: Spacing.md) {
            CompactHealthCard(
                score: viewModel.financialHealthScore,
                onTap: {
                    // TODO: Navigate to health details
                }
            )

            CompactSavingsCard(
                goalName: viewModel.primarySavingsGoalName,
                emoji: viewModel.primarySavingsGoalEmoji,
                currentAmount: viewModel.primarySavingsGoalCurrent,
                targetAmount: viewModel.primarySavingsGoalTarget > 0 ? viewModel.primarySavingsGoalTarget : viewModel.savingsGoal,
                currencySymbol: viewModel.currencySymbol,
                onTap: {
                    viewModel.showSavingsGoalEntry()
                }
            )
        }
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
                            .font(.system(size: 28 * sizeCategory.scaleFactor))
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
                            .font(.system(size: 28 * sizeCategory.scaleFactor))
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
                            .font(.system(size: 28 * sizeCategory.scaleFactor))
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
                    .font(.system(size: 80 * sizeCategory.scaleFactor))
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
    @Environment(\.sizeCategory) private var sizeCategory

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    // Icon and Title
                    VStack(spacing: Spacing.md) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 60 * sizeCategory.scaleFactor))
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
                    .foregroundColor(.textSecondary.opacity(0.8))
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
