//
//  ExpenseView.swift
//  BudgetMeter
//
//  Redesigned with collapsible sections and full-width rows
//

import SwiftUI
import CoreData

/// Expense entry screen with collapsible sections
struct ExpenseView: View {

    @StateObject private var viewModel = ExpenseViewModel()
    @StateObject private var localizationManager = LocalizationManager.shared

    // MARK: - State

    // Section expand state (Daily expanded by default)
    @State private var isDailyExpanded = true
    @State private var isMonthlyExpanded = false
    @State private var isSubscriptionsExpanded = false
    @State private var isYearlyExpanded = false

    // Edit sheet state
    @State private var categoryToEdit: FinancialCategory?

    // Create modal state
    @State private var showingCreateModal = false
    @State private var selectedFrequency = ""

    // Subscription sheet state
    @State private var showingAddSubscription = false
    @State private var subscriptionToEdit: Subscription?

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
                            totalMonthly: viewModel.totalMonthlyExpenses,
                            dailyAverage: viewModel.dailyAverageExpenses,
                            yearlyProjection: viewModel.yearlyProjectionExpenses,
                            currencySymbol: viewModel.currencySymbol,
                            type: .expense,
                            sourcesCount: viewModel.activeSourcesCount
                        )
                        .padding(.horizontal, Spacing.lg)

                        // Collapsible Sections
                        VStack(spacing: Spacing.md) {
                            // Daily Expenses Section (expanded by default)
                            expenseSection(
                                frequency: "daily",
                                isExpanded: $isDailyExpanded
                            )

                            // Monthly Expenses Section
                            expenseSection(
                                frequency: "monthly",
                                isExpanded: $isMonthlyExpanded
                            )

                            // Subscriptions Section
                            subscriptionsSection

                            // Yearly Expenses Section
                            expenseSection(
                                frequency: "yearly",
                                isExpanded: $isYearlyExpanded
                            )
                        }
                    }
                }
                .padding(.vertical, Spacing.md)
            }
            .background(Color.appBackground)
            .navigationTitle(String(localized: "tab.expenses.title", defaultValue: "Expenses"))
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
                accentColor: .brandExpense,
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
                type: "expense",
                onSave: { _ in
                    viewModel.refresh()
                    showingCreateModal = false
                },
                onCancel: {
                    showingCreateModal = false
                }
            )
        }
        .sheet(isPresented: $showingAddSubscription) {
            QuickSubscriptionPickerView {
                viewModel.loadSubscriptions()
            }
        }
        .sheet(item: $subscriptionToEdit) { subscription in
            SubscriptionInputView(subscription: subscription) {
                viewModel.loadSubscriptions()
            }
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

    // MARK: - Expense Section

    @ViewBuilder
    private func expenseSection(frequency: String, isExpanded: Binding<Bool>) -> some View {
        let categories = viewModel.categoriesForFrequency(frequency)

        FinancialSection(
            title: viewModel.sectionTitle(frequency),
            subtitle: viewModel.formattedSubtotal(frequency),
            accentColor: .brandExpense,
            isExpanded: isExpanded
        ) {
            VStack(spacing: 0) {
                // Category rows
                ForEach(categories, id: \.objectID) { category in
                    FinancialRowView(
                        category: category,
                        currencySymbol: viewModel.currencySymbol,
                        accentColor: .brandExpense,
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
                    type: "expense",
                    onTap: {
                        selectedFrequency = frequency
                        showingCreateModal = true
                    }
                )
            }
        }
    }

    // MARK: - Subscriptions Section

    private var subscriptionsSection: some View {
        FinancialSection(
            title: String(localized: "expense.section.subscriptions", defaultValue: "Subscriptions"),
            subtitle: viewModel.formattedSubscriptionsSubtotal,
            accentColor: .brandExpense,
            isExpanded: $isSubscriptionsExpanded
        ) {
            VStack(spacing: 0) {
                // Subscription rows
                ForEach(viewModel.subscriptions, id: \.id) { subscription in
                    SubscriptionRowView(
                        subscription: subscription,
                        currencySymbol: viewModel.currencySymbol,
                        onTap: {
                            subscriptionToEdit = subscription
                        }
                    )

                    // Divider between rows
                    if subscription != viewModel.subscriptions.last {
                        Divider()
                            .padding(.leading, 56)
                    }
                }

                // Add row divider if there are subscriptions
                if !viewModel.subscriptions.isEmpty {
                    Divider()
                        .padding(.leading, 56)
                }

                // Add new subscription row
                AddSubscriptionRow {
                    showingAddSubscription = true
                }
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: Spacing.lg) {
            ProgressView()
                .scaleEffect(1.2)
            Text(String(localized: "expenses.loading", defaultValue: "Loading expenses..."))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
}

// MARK: - Preview

#Preview("Expense View") {
    ExpenseView()
        .environment(\.managedObjectContext, PersistenceService.shared.viewContext)
}

#Preview("Dark Mode") {
    ExpenseView()
        .environment(\.managedObjectContext, PersistenceService.shared.viewContext)
        .preferredColorScheme(.dark)
}
