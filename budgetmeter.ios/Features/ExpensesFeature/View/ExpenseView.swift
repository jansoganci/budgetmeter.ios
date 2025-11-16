//
//  ExpenseView.swift
//  BudgetMeter
//
//  Created by BudgetMeter Team on 17.09.2025.
//

import SwiftUI
import CoreData

/// Expense entry screen following the design rulebook specifications
struct ExpenseView: View {
    
    @StateObject private var viewModel = ExpenseViewModel()
    @StateObject private var localizationManager = LocalizationManager.shared
    @FocusState private var focusedField: String?
    
    // Modal state
    @State private var showingCreateModal = false
    @State private var selectedFrequency = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: Spacing.xl) {
                    if viewModel.isLoading {
                        loadingView
                    } else if viewModel.categoryGroups.isEmpty {
                        emptyStateView
                    } else {
                        // Summary Card
                        expenseSummaryCard

                        ForEach(viewModel.categoryGroups, id: \.title) { group in
                            categoryGroupView(group)
                        }
                    }
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.sm)
            }
            .navigationTitle("tab.expenses.title".localized(defaultValue: "Expenses"))
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                viewModel.refresh()
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("toolbar.done".localized(defaultValue: "Done")) {
                        focusedField = nil
                    }
                    .foregroundColor(.brandProgress)
                    .fontWeight(.semibold)
                }
            }
        }
        .environment(\.locale, localizationManager.currentLocale)
        .sheet(isPresented: $showingCreateModal) {
            CreateCategoryModal(
                frequency: selectedFrequency,
                type: "expense",
                onSave: { category in
                    // Refresh the view model to show the new category
                    viewModel.refresh()
                    showingCreateModal = false
                },
                onCancel: {
                    showingCreateModal = false
                }
            )
        }
        .onAppear {
            viewModel.refresh()
        }
        .alert("alert.error.title".localized(defaultValue: "Error"), isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("alert.ok".localized(defaultValue: "OK")) {
                viewModel.errorMessage = nil
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Subviews
    
    private var expenseSummaryCard: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack {
                Image(systemName: "chart.pie.fill")
                    .foregroundColor(.brandExpense)
                Text(viewModel.summaryTitle)
                    .sectionTitleStyle()
                Spacer()
            }
            .padding(.horizontal, Spacing.xs)

            HStack(spacing: Spacing.md) {
                // Daily Average Card
                summaryInfoCard(
                    title: viewModel.dailyAvgTitle,
                    value: viewModel.dailyAverageExpenses,
                    icon: "calendar.day.timeline.left",
                    color: .brandExpense
                )

                // Monthly Total Card
                summaryInfoCard(
                    title: viewModel.monthlyTitle,
                    value: viewModel.totalMonthlyExpenses,
                    icon: "calendar",
                    color: .brandExpense
                )

                // Yearly Projection Card
                summaryInfoCard(
                    title: viewModel.yearlyTitle,
                    value: viewModel.yearlyProjectionExpenses,
                    icon: "chart.line.uptrend.xyaxis",
                    color: .brandExpense.opacity(0.8)
                )
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: Spacing.lg) {
            ProgressView()
                .scaleEffect(1.2)
            Text("expenses.loading".localized(defaultValue: "Loading expenses..."))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }

    private var emptyStateView: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "minus.circle")
                .font(.system(size: 64))
                .foregroundColor(.brandExpense)

            Text("empty_state.expenses.message".localized(defaultValue: "No expenses yet. Tap the + button to add your first expense."))
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .padding()
    }
    
    private func categoryGroupView(_ group: (title: String, categories: [FinancialCategory], color: Color)) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Group Header
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(group.color)
                Text(group.title)
                    .sectionTitleStyle()
                Spacer()
            }
            .padding(.horizontal, Spacing.xs)

            // Category Grid
            LazyVGrid(columns: createGridColumns(), spacing: Spacing.md) {
                ForEach(group.categories, id: \.objectID) { category in
                    CategoryInputCard(
                        category: category,
                        accentColor: group.color,
                        onAmountChange: { amount in
                            viewModel.updateAmount(for: category, amount: amount)
                        },
                        currencySymbol: viewModel.currencySymbol,
                        focusedField: $focusedField
                    )
                }
                
                // Add Custom Category Card
                AddCustomCategoryCard(
                    frequency: group.title.lowercased(),
                    type: "expense",
                    accentColor: group.color,
                    onAddCategory: {
                        selectedFrequency = group.title.lowercased()
                        showingCreateModal = true
                    }
                )
            }
        }
    }
    
    
    // MARK: - Helper Methods
    
    private func summaryInfoCard(title: String, value: Double, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)

            Text(title)
                .cardLabelStyle()

            Text(viewModel.formatCurrencyDisplay(value))
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 80)
        .padding(.vertical, Spacing.md)
        .background(Color.cardBackground)
        .cornerRadius(CornerRadius.card)
    }

    private func createGridColumns() -> [GridItem] {
        // Responsive grid: 2 columns on iPhone, 3 on iPad
        let columnCount = UIDevice.current.userInterfaceIdiom == .pad ? 3 : 2
        return Array(repeating: GridItem(.flexible(), spacing: Spacing.md), count: columnCount)
    }
}

// MARK: - Preview

#Preview {
    ExpenseView()
        .environment(\.managedObjectContext, PersistenceService.shared.viewContext)
}
