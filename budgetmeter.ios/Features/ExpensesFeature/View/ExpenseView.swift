//
//  ExpenseView.swift
//  BudgetMeter
//
//  Expense entry screen with collapsible sections (v2 transformation).
//

import SwiftUI
import CoreData

/// Expense entry screen with collapsible sections
struct ExpenseView: View {

    @StateObject private var viewModel = ExpenseViewModel()
    @StateObject private var localizationManager = LocalizationManager.shared
    @StateObject private var premiumManager = PremiumManager.shared

    @State private var isDailyExpanded = true
    @State private var isMonthlyExpanded = false
    @State private var isSubscriptionsExpanded = false
    @State private var isYearlyExpanded = false
    @State private var isOneTimeExpanded = false

    @State private var categoryToEdit: FinancialCategory?
    @State private var showingCreateModal = false
    @State private var selectedFrequency = ""

    @State private var showingAddSubscription = false
    @State private var showingSubscriptionPaywall = false
    @State private var subscriptionToEdit: Subscription?

    var body: some View {
        NavigationView {
            ZStack {
                AppBackground()

                ScrollView {
                    VStack(spacing: LayoutSpacing.sectionGap) {
                        if viewModel.isLoading {
                            loadingView
                        } else {
                            summaryHeroCard

                            if viewModel.activeSourcesCount == 0 {
                                emptyStateSection
                            } else {
                                secondaryAddButton
                            }

                            sectionsStack
                        }
                    }
                    .padding(.vertical, Spacing.md)
                    .padding(.horizontal, LayoutSpacing.screenPadding)
                }
            }
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
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingAddSubscription) {
            QuickSubscriptionPickerView {
                viewModel.loadSubscriptions()
            }
        }
        .sheet(isPresented: $showingSubscriptionPaywall) {
            PremiumPaywallView(
                onDismiss: { showingSubscriptionPaywall = false },
                onPurchase: { showingSubscriptionPaywall = false },
                onRestore: { showingSubscriptionPaywall = false }
            )
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

    // MARK: - Summary Hero

    private var summaryHeroCard: some View {
        SummaryHeroCard(
            totalMonthly: viewModel.totalMonthlyExpenses,
            dailyAverage: viewModel.dailyAverageExpenses,
            yearlyProjection: viewModel.yearlyProjectionExpenses,
            currencySymbol: viewModel.currencySymbol,
            type: .expense,
            sourcesCount: viewModel.activeSourcesCount
        )
    }

    // MARK: - Empty State

    private var emptyStateSection: some View {
        VStack(spacing: LayoutSpacing.cardInternalGap) {
            EmptyStateCard(
                message: String(
                    localized: "expense.empty.message",
                    defaultValue: "Add your expenses to see your monthly total and pace."
                )
            )

            PrimaryCTAButton(
                title: "expense.add.primary".localized(defaultValue: "Add expense"),
                action: { presentCreateModal(frequency: "monthly") }
            )
        }
    }

    private var secondaryAddButton: some View {
        SecondaryCTAButton(
            title: "expense.add.primary".localized(defaultValue: "Add expense"),
            action: { presentCreateModal(frequency: "monthly") }
        )
    }

    // MARK: - Sections

    private var sectionsStack: some View {
        VStack(spacing: Spacing.md) {
            expenseSection(frequency: "daily", isExpanded: $isDailyExpanded)
            expenseSection(frequency: "monthly", isExpanded: $isMonthlyExpanded)

            if premiumManager.hasAccess(to: BudgetMeterCapability.subscriptionTracking) {
                subscriptionsSection
            } else {
                lockedSubscriptionsSection
            }

            expenseSection(frequency: "yearly", isExpanded: $isYearlyExpanded)
            oneTimeSection
        }
    }

    @ViewBuilder
    private func expenseSection(frequency: String, isExpanded: Binding<Bool>) -> some View {
        let categories = viewModel.categoriesForFrequency(frequency)

        FinancialSection(
            title: viewModel.sectionTitle(frequency),
            subtitle: viewModel.formattedSubtotal(frequency),
            accentColor: .brandExpense,
            isExpanded: isExpanded
        ) {
            categoryList(
                categories: categories,
                frequency: frequency,
                type: "expense",
                accentColor: .brandExpense
            )
        }
    }

    private var lockedSubscriptionsSection: some View {
        FinancialSection(
            title: String(localized: "expense.section.subscriptions", defaultValue: "Subscriptions"),
            subtitle: String(localized: "expense.subscriptions.premium_required", defaultValue: "Premium required"),
            accentColor: .brandExpense,
            isExpanded: $isSubscriptionsExpanded
        ) {
            Button {
                showingSubscriptionPaywall = true
            } label: {
                HStack(spacing: Spacing.md) {
                    Image(systemName: "lock.fill")
                        .font(.title2)
                        .foregroundColor(.brandExpense)

                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(String(localized: "expense.subscriptions.locked.title", defaultValue: "Subscription tracking is premium"))
                            .statusTitleStyle()

                        Text(String(localized: "expense.subscriptions.locked.message", defaultValue: "Unlock subscriptions to track recurring expenses."))
                            .captionStyle()
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .captionStyle()
                }
                .padding(LayoutSpacing.cardPadding)
                .background(Color.surfaceCard)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous)
                        .stroke(Color.borderSubtle, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                String(localized: "expense.subscriptions.locked.accessibility", defaultValue: "Subscription tracking is premium. Double tap to view upgrade options.", table: "UI")
            )
        }
    }

    private var subscriptionsSection: some View {
        FinancialSection(
            title: String(localized: "expense.section.subscriptions", defaultValue: "Subscriptions"),
            subtitle: viewModel.formattedSubscriptionsSubtotal,
            accentColor: .brandExpense,
            isExpanded: $isSubscriptionsExpanded
        ) {
            VStack(spacing: 0) {
                ForEach(viewModel.subscriptions, id: \.id) { subscription in
                    SubscriptionRowView(
                        subscription: subscription,
                        currencySymbol: viewModel.currencySymbol,
                        onTap: {
                            subscriptionToEdit = subscription
                        }
                    )

                    if subscription != viewModel.subscriptions.last {
                        Divider()
                            .padding(.leading, 56)
                    }
                }

                if !viewModel.subscriptions.isEmpty {
                    Divider()
                        .padding(.leading, 56)
                }

                AddSubscriptionRow {
                    showingAddSubscription = true
                }
            }
        }
    }

    private var oneTimeSection: some View {
        FinancialSection(
            title: viewModel.oneTimeSectionTitle,
            subtitle: viewModel.formattedOneTimeSubtotal(),
            accentColor: .brandExpense,
            isExpanded: $isOneTimeExpanded
        ) {
            categoryList(
                categories: viewModel.oneTimeExpenses,
                frequency: "monthly",
                type: "expense",
                accentColor: .brandExpense
            )
        }
    }

    @ViewBuilder
    private func categoryList(
        categories: [FinancialCategory],
        frequency: String,
        type: String,
        accentColor: Color
    ) -> some View {
        VStack(spacing: 0) {
            ForEach(categories, id: \.objectID) { category in
                FinanceListRow(
                    category: category,
                    currencySymbol: viewModel.currencySymbol,
                    accentColor: accentColor,
                    onEditTap: {
                        categoryToEdit = category
                    }
                )

                if category != categories.last {
                    Divider()
                        .padding(.leading, 56)
                }
            }

            if !categories.isEmpty {
                Divider()
                    .padding(.leading, 56)
            }

            AddFinancialItemRow(
                frequency: frequency,
                type: type,
                onTap: {
                    presentCreateModal(frequency: frequency)
                }
            )
        }
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: Spacing.lg) {
            ProgressView()
                .scaleEffect(1.2)
            Text(String(localized: "expenses.loading", defaultValue: "Loading expenses..."))
                .captionStyle()
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(localized: "expenses.loading", defaultValue: "Loading expenses"))
    }

    // MARK: - Actions

    private func presentCreateModal(frequency: String) {
        selectedFrequency = frequency
        showingCreateModal = true
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
