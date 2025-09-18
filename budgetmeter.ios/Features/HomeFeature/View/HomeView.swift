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
            .navigationTitle(String(localized: "tab.home.title"))
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
    }
    
    // MARK: - Live Meter Hero
    
    private var liveMeterHero: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Text(String(localized: "home.session.label"))
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

            Text(viewModel.isPositive ? String(localized: "home.session.positive") : String(localized: "home.session.negative"))
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.9))

            Divider()
                .background(Color.white.opacity(0.2))

            VStack(alignment: .leading, spacing: 4) {
                Text(String(localized: "home.cumulative.label"))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.9))

                Text(viewModel.cumulativeDisplayAmount)
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundColor(viewModel.cumulativeFlowColor.opacity(0.95))
                    .monospacedDigit()

                Text(String(localized: "home.cumulative.since \(viewModel.cumulativeSinceDateText)"))
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.8))
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
            String(
                localized: "home.session.accessibility \(viewModel.formattedLiveValue) \(viewModel.sessionDuration) \(viewModel.cumulativeDisplayAmount) \(viewModel.cumulativeSinceDateText)"
            )
        )
    }
    
    // MARK: - Quick Actions Grid
    
    private var quickActionsGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundColor(Color(hex: "4A90E2"))
                Text("Quick Actions")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding(.horizontal, 4)
            
            HStack(spacing: 12) {
                // Add Income Button
                Button(action: viewModel.showIncomeEntry) {
                    VStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.green)
                        
                        Text("Add Income")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 80)
                    .background(Color(uiColor: .secondarySystemBackground))
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add Income")
                .accessibilityHint("Opens income entry screen to add your income sources")
                
                // Add Expense Button
                Button(action: viewModel.showExpenseEntry) {
                    VStack(spacing: 8) {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.red)
                        
                        Text("Add Expense")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 80)
                    .background(Color(uiColor: .secondarySystemBackground))
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add Expense")
                .accessibilityHint("Opens expense entry screen to add your expenses")
            }
        }
    }
    
    // MARK: - Today's Snapshot Cards
    
    private var snapshotCards: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(Color(hex: "4A90E2"))
                Text("Today's Snapshot")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding(.horizontal, 4)
            
            HStack(spacing: 12) {
                // Daily Flow Card
                snapshotCard(
                    title: "Daily",
                    value: viewModel.dailyNetFlow,
                    icon: "calendar"
                )
                
                // Monthly Flow Card
                snapshotCard(
                    title: "Monthly",
                    value: viewModel.monthlyNetFlow,
                    icon: "calendar.badge.clock"
                )
                
                // Health Score Card
                VStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 20))
                        .foregroundColor(viewModel.financialHealthColor)
                    
                    Text("Health")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(viewModel.financialHealthScore)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(viewModel.financialHealthColor)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 70)
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
                
                Text("Welcome to BudgetMeter")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Track your money flow in real-time.\nStart by adding your income sources.")
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
                        Text("Add Your First Income")
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
                        Text("Add Expenses")
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
            Text("Loading your financial data...")
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
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Preview

#Preview {
    HomeView()
        .environment(\.managedObjectContext, PersistenceService.shared.viewContext)
}
