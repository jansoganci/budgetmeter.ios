//
//  HomeView.swift
//  BudgetMeter
//
//  Created by BudgetMeter Team on 17.09.2025.
//

import SwiftUI
import CoreData

/// Home screen - Main entry point following Steve Jobs "focus and simplify" philosophy
struct HomeView: View {
    
    @StateObject private var viewModel = HomeViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                if viewModel.isLoading {
                    loadingView
                } else if !viewModel.hasAnyData {
                    // First-time user experience
                    gettingStartedView
                } else {
                    // Experienced user - full dashboard
                    liveMeterHero
                    quickActionsGrid
                    snapshotCards
                    
                    Spacer()
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
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
    
    // MARK: - Live Meter Hero
    
    private var liveMeterHero: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Text("home.session.label".localized(defaultValue: "Current Session"))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.9))
                Spacer()
                Text(viewModel.sessionDuration)
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundColor(.white.opacity(0.8))
            }

            HStack(spacing: 8) {
                Text(viewModel.isPositive ? "+" : "-")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text(viewModel.formattedLiveValue)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .monospacedDigit()
            }

            Text(viewModel.isPositive ? "home.session.positive".localized(defaultValue: "You're ahead") : "home.session.negative".localized(defaultValue: "You're behind"))
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.9))

            Divider()
                .background(Color.white.opacity(0.2))

            VStack(alignment: .leading, spacing: 4) {
                Text("home.cumulative.label".localized(defaultValue: "Long-Term Total"))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.9))

                Text(viewModel.cumulativeDisplayAmount)
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundColor(viewModel.cumulativeFlowColor.opacity(0.95))
                    .monospacedDigit()

                Text("home.cumulative.since \(viewModel.cumulativeSinceDateText)".localized(defaultValue: "Since \(viewModel.cumulativeSinceDateText)"))
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            // Savings Goal Section (only show if goal is set)
            if viewModel.savingsGoal > 0 {
                Divider()
                    .background(Color.white.opacity(0.2))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("home.savings_goal.label".localized(defaultValue: "Savings Goal"))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.9))
                    
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: "target")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.9))
                            
                            Text(viewModel.formattedSavingsGoal)
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .monospacedDigit()
                        }
                        
                        Spacer()
                        
                        if !viewModel.timeToGoal.isEmpty {
                            Text(viewModel.timeToGoal)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .background(
            LinearGradient(
                colors: [
                    Color(hex: "4A90E2"),
                    Color(hex: "4A90E2").opacity(0.8)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            viewModel.savingsGoal > 0 
                ? "home.session.accessibility.with_goal \(viewModel.formattedLiveValue) \(viewModel.sessionDuration) \(viewModel.cumulativeDisplayAmount) \(viewModel.cumulativeSinceDateText) \(viewModel.formattedSavingsGoal) \(viewModel.timeToGoal)".localized(defaultValue: "Current session: \(viewModel.formattedLiveValue), duration: \(viewModel.sessionDuration), total: \(viewModel.cumulativeDisplayAmount) since \(viewModel.cumulativeSinceDateText), savings goal: \(viewModel.formattedSavingsGoal), time to goal: \(viewModel.timeToGoal)")
                : "home.session.accessibility \(viewModel.formattedLiveValue) \(viewModel.sessionDuration) \(viewModel.cumulativeDisplayAmount) \(viewModel.cumulativeSinceDateText)".localized(defaultValue: "Current session: \(viewModel.formattedLiveValue), duration: \(viewModel.sessionDuration), total: \(viewModel.cumulativeDisplayAmount) since \(viewModel.cumulativeSinceDateText)")
        )
    }
    
    // MARK: - Quick Actions Grid
    
    private var quickActionsGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundColor(Color(hex: "4A90E2"))
                Text("home.quick_actions.title".localized(defaultValue: "Quick Actions"))
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding(.horizontal, 4)
            
            HStack(spacing: 8) {
                // Add Income Button
                Button(action: viewModel.showIncomeEntry) {
                    VStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.green)
                        
                        Text("home.quick_actions.add_income".localized(defaultValue: "Add Income"))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 80)
                    .background(Color(uiColor: .secondarySystemBackground))
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("home.quick_actions.add_income".localized(defaultValue: "Add Income"))
                .accessibilityHint("home.quick_actions.add_income.hint".localized(defaultValue: "Tap to add income entry"))
                
                // Add Expense Button
                Button(action: viewModel.showExpenseEntry) {
                    VStack(spacing: 6) {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.red)
                        
                        Text("home.quick_actions.add_expense".localized(defaultValue: "Add Expense"))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 80)
                    .background(Color(uiColor: .secondarySystemBackground))
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("home.quick_actions.add_expense".localized(defaultValue: "Add Expense"))
                .accessibilityHint("home.quick_actions.add_expense.hint".localized(defaultValue: "Tap to add expense entry"))
                
                // Savings Goal Button
                Button(action: viewModel.showSavingsGoalEntry) {
                    VStack(spacing: 6) {
                        Image(systemName: "target")
                            .font(.system(size: 28))
                            .foregroundColor(.purple)
                        
                        Text(viewModel.savingsGoal > 0 ? "home.quick_actions.goal".localized(defaultValue: "Goal") : "home.quick_actions.set_goal".localized(defaultValue: "Set Goal"))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 80)
                    .background(Color(uiColor: .secondarySystemBackground))
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(viewModel.savingsGoal > 0 ? "home.quick_actions.goal".localized(defaultValue: "Goal") : "home.quick_actions.set_goal".localized(defaultValue: "Set Goal"))
                .accessibilityHint("home.quick_actions.goal.hint".localized(defaultValue: "Tap to set or modify savings goal"))
            }
        }
    }
    
    // MARK: - Today's Snapshot Cards
    
    private var snapshotCards: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(Color(hex: "4A90E2"))
                Text("home.snapshot.title".localized(defaultValue: "Today's Snapshot"))
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding(.horizontal, 4)
            
            HStack(spacing: 12) {
                // Daily Flow Card
                snapshotCard(
                    title: "home.snapshot.daily".localized(defaultValue: "Daily"),
                    value: viewModel.dailyNetFlow,
                    icon: "calendar"
                )
                
                // Monthly Flow Card
                snapshotCard(
                    title: "home.snapshot.monthly".localized(defaultValue: "Monthly"),
                    value: viewModel.monthlyNetFlow,
                    icon: "calendar.badge.clock"
                )
                
                // Health Score Card
                VStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 20))
                        .foregroundColor(viewModel.financialHealthColor)
                    
                    Text("home.snapshot.health".localized(defaultValue: "Health"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(viewModel.financialHealthScore)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(viewModel.financialHealthColor)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 70)
                .padding(.vertical, 12)
                .background(Color(uiColor: .secondarySystemBackground))
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Getting Started View
    
    private var gettingStartedView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Welcome Hero
            VStack(spacing: 16) {
                Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(Color(hex: "4A90E2"))
                
                Text("home.getting_started.title".localized(defaultValue: "Welcome to BudgetMeter"))
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("home.getting_started.subtitle".localized(defaultValue: "Track your financial flow in real-time"))
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Quick Start Actions
            VStack(spacing: 12) {
                Button(action: viewModel.showIncomeEntry) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                        Text("home.getting_started.add_income".localized(defaultValue: "Add Your First Income"))
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color(hex: "4A90E2"))
                    .foregroundColor(.white)
                    .cornerRadius(12)
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
                    .frame(height: 50)
                    .background(Color(uiColor: .secondarySystemBackground))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(uiColor: .separator), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
            
            Spacer()
        }
        .padding(.horizontal, 8)
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("home.loading".localized(defaultValue: "Loading..."))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Helper Views
    
    private func snapshotCard(title: String, value: Double, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(viewModel.colorForFlow(value))
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(viewModel.formatCurrency(value))
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(viewModel.colorForFlow(value))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 70)
        .padding(.vertical, 12)
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Preview

#Preview {
    HomeView()
        .environment(\.managedObjectContext, PersistenceService.shared.viewContext)
}
