//
//  IncomeView.swift
//  BudgetMeter
//
//  Created by BudgetMeter Team on 17.09.2025.
//

import SwiftUI
import CoreData

/// Income entry screen following the design rulebook specifications
struct IncomeView: View {
    
    @StateObject private var viewModel = IncomeViewModel()
    @StateObject private var localizationManager = LocalizationManager.shared
    @FocusState private var focusedField: String?
    
    // Modal state
    @State private var showingCreateModal = false
    @State private var selectedFrequency = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 24) {
                    if viewModel.isLoading {
                        loadingView
                    } else if viewModel.categoryGroups.isEmpty {
                        emptyStateView
                    } else {
                        // Summary Card
                        incomeSummaryCard
                        
                        ForEach(viewModel.categoryGroups, id: \.title) { group in
                            categoryGroupView(group)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .navigationTitle("tab.income.title".localized(defaultValue: "Income"))
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
                type: "income",
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
    
    private var incomeSummaryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.brandPositive)
                Text(viewModel.summaryTitle)
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding(.horizontal, 4)
            
            HStack(spacing: 12) {
                // Daily Average Card
                summaryInfoCard(
                    title: viewModel.dailyAvgTitle,
                    value: viewModel.dailyAverageIncome,
                    icon: "calendar.day.timeline.left",
                    color: .brandPositive
                )

                // Monthly Total Card
                summaryInfoCard(
                    title: viewModel.monthlyTitle,
                    value: viewModel.totalMonthlyIncome,
                    icon: "calendar",
                    color: .brandPositive
                )

                // Yearly Projection Card
                summaryInfoCard(
                    title: viewModel.yearlyTitle,
                    value: viewModel.yearlyProjectionIncome,
                    icon: "chart.line.uptrend.xyaxis",
                    color: .brandPositive.opacity(0.8)
                )
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("income.loading".localized(defaultValue: "Loading income..."))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "plus.circle")
                .font(.system(size: 64))
                .foregroundColor(.brandPositive)

            Text("empty_state.income.message".localized(defaultValue: "No income yet. Tap the + button to add your first income source."))
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .padding()
    }
    
    private func categoryGroupView(_ group: (title: String, categories: [FinancialCategory], color: Color)) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Group Header
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(group.color)
                Text(group.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal, 4)
            
            // Category Grid
            LazyVGrid(columns: createGridColumns(), spacing: 12) {
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
                    type: "income",
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
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(viewModel.formatCurrencyDisplay(value))
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 80)
        .padding(.vertical, 12)
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private func createGridColumns() -> [GridItem] {
        // Responsive grid: 2 columns on iPhone, 3 on iPad
        let columnCount = UIDevice.current.userInterfaceIdiom == .pad ? 3 : 2
        return Array(repeating: GridItem(.flexible(), spacing: 12), count: columnCount)
    }
}


// MARK: - Preview

#Preview {
    IncomeView()
        .environment(\.managedObjectContext, PersistenceService.shared.viewContext)
}
