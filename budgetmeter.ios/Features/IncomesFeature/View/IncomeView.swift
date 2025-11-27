//
//  IncomeView.swift
//  BudgetMeter
//
//  Redesigned with collapsible sections and full-width rows
//

import SwiftUI
import CoreData

/// Income entry screen with collapsible sections
struct IncomeView: View {

    @StateObject private var viewModel = IncomeViewModel()
    @StateObject private var localizationManager = LocalizationManager.shared

    // MARK: - State

    // Section expand state (Daily expanded by default)
    @State private var isDailyExpanded = true
    @State private var isMonthlyExpanded = false
    @State private var isYearlyExpanded = false

    // Edit sheet state
    @State private var categoryToEdit: FinancialCategory?

    // Create modal state
    @State private var showingCreateModal = false
    @State private var selectedFrequency = ""

    // MARK: - Body

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    if viewModel.isLoading {
                        loadingView
                    } else {
                        // Hero Summary Card
                        FinancialSummaryCard(
                            totalMonthly: viewModel.totalMonthlyIncome,
                            dailyAverage: viewModel.dailyAverageIncome,
                            yearlyProjection: viewModel.yearlyProjectionIncome,
                            currencySymbol: viewModel.currencySymbol,
                            type: .income,
                            sourcesCount: viewModel.activeSourcesCount
                        )
                        .padding(.horizontal, Spacing.lg)

                        // Collapsible Sections
                        VStack(spacing: Spacing.md) {
                            // Daily Income Section (expanded by default)
                            incomeSection(
                                frequency: "daily",
                                isExpanded: $isDailyExpanded
                            )

                            // Monthly Income Section
                            incomeSection(
                                frequency: "monthly",
                                isExpanded: $isMonthlyExpanded
                            )

                            // Yearly Income Section
                            incomeSection(
                                frequency: "yearly",
                                isExpanded: $isYearlyExpanded
                            )
                        }
                    }
                }
                .padding(.vertical, Spacing.md)
            }
            .background(Color.appBackground)
            .navigationTitle(String(localized: "tab.income.title", defaultValue: "Income"))
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                viewModel.refresh()
            }
        }
        .environment(\.locale, localizationManager.currentLocale)
        .sheet(item: $categoryToEdit) { category in
            FinancialEditSheet(
                category: category,
                currencySymbol: viewModel.currencySymbol,
                accentColor: .brandPositive,
                onSave: { amount in
                    viewModel.updateAmount(for: category, amount: amount)
                },
                onDelete: category.isCustom ? {
                    viewModel.deleteCategory(category)
                } : nil,
                onColorChange: category.isCustom ? { color in
                    viewModel.updateColor(for: category, color: color)
                } : nil
            )
        }
        .sheet(isPresented: $showingCreateModal) {
            CreateCategoryModal(
                frequency: selectedFrequency,
                type: "income",
                onSave: { _ in
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
        .alert(
            String(localized: "alert.error.title", defaultValue: "Error"),
            isPresented: .constant(viewModel.errorMessage != nil)
        ) {
            Button(String(localized: "alert.ok", defaultValue: "OK")) {
                viewModel.errorMessage = nil
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Income Section

    @ViewBuilder
    private func incomeSection(frequency: String, isExpanded: Binding<Bool>) -> some View {
        let categories = viewModel.categoriesForFrequency(frequency)

        FinancialSection(
            title: viewModel.sectionTitle(frequency),
            subtitle: viewModel.formattedSubtotal(frequency),
            accentColor: .brandPositive,
            isExpanded: isExpanded
        ) {
            VStack(spacing: 0) {
                // Category rows
                ForEach(categories, id: \.objectID) { category in
                    FinancialRowView(
                        category: category,
                        currencySymbol: viewModel.currencySymbol,
                        accentColor: .brandPositive,
                        onEditTap: {
                            categoryToEdit = category
                        }
                    )

                    // Divider between rows (not after last item)
                    if category != categories.last {
                        Divider()
                            .padding(.leading, 56)
                    }
                }

                // Add row divider if there are categories
                if !categories.isEmpty {
                    Divider()
                        .padding(.leading, 56)
                }

                // Add new category row
                AddFinancialItemRow(
                    frequency: frequency,
                    type: "income",
                    onTap: {
                        selectedFrequency = frequency
                        showingCreateModal = true
                    }
                )
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: Spacing.lg) {
            ProgressView()
                .scaleEffect(1.2)
            Text(String(localized: "income.loading", defaultValue: "Loading income..."))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
}

// MARK: - Preview

#Preview("Income View") {
    IncomeView()
        .environment(\.managedObjectContext, PersistenceService.shared.viewContext)
}

#Preview("Dark Mode") {
    IncomeView()
        .environment(\.managedObjectContext, PersistenceService.shared.viewContext)
        .preferredColorScheme(.dark)
}
