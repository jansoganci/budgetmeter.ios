//
//  IncomeView.swift
//  BudgetMeter
//
//  Income entry screen with collapsible sections (v2 transformation).
//

import SwiftUI
import CoreData

/// Income entry screen with collapsible sections
struct IncomeView: View {

    @StateObject private var viewModel = IncomeViewModel()
    @StateObject private var localizationManager = LocalizationManager.shared

    @State private var isDailyExpanded = true
    @State private var isWeeklyExpanded = false
    @State private var isMonthlyExpanded = false
    @State private var isYearlyExpanded = false
    @State private var isOneTimeExpanded = false

    @State private var categoryToEdit: FinancialCategory?
    @State private var showingCreateModal = false
    @State private var createModalIntent: FinancialCategoryEntryKind = .recurring
    @State private var createModalFrequency = "monthly"
    @State private var pendingCategoryForAmountEntry: FinancialCategory?
    @State private var showErrorAlert = false

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
        .sheet(isPresented: $showingCreateModal, onDismiss: openPendingAmountEntryIfNeeded) {
            CreateCategoryModal(
                entryIntent: createModalIntent,
                defaultRecurringFrequency: createModalFrequency,
                type: "income",
                onSave: { category in
                    pendingCategoryForAmountEntry = category
                    viewModel.refresh()
                    showingCreateModal = false
                },
                onCancel: {
                    showingCreateModal = false
                }
            )
            .presentationDragIndicator(.visible)
        }
        .onAppear {
            viewModel.refresh()
        }
        .onChange(of: viewModel.errorMessage) { _, message in
            showErrorAlert = message != nil
        }
        .alert(
            String(localized: "alert.error.title", defaultValue: "Error"),
            isPresented: $showErrorAlert
        ) {
            Button(String(localized: "alert.ok", defaultValue: "OK")) {
                viewModel.errorMessage = nil
                showErrorAlert = false
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
            totalMonthly: viewModel.totalMonthlyIncome,
            dailyAverage: viewModel.dailyAverageIncome,
            yearlyProjection: viewModel.yearlyProjectionIncome,
            currencySymbol: viewModel.currencySymbol,
            type: .income,
            sourcesCount: viewModel.activeSourcesCount
        )
    }

    // MARK: - Empty State

    private var emptyStateSection: some View {
        VStack(spacing: LayoutSpacing.cardInternalGap) {
            EmptyStateCard(
                message: String(
                    localized: "income.empty.message",
                    defaultValue: "Add your income sources to see your monthly total and pace."
                )
            )

            PrimaryCTAButton(
                title: "income.add.primary".localized(defaultValue: "Add income"),
                action: { presentCreateModal(entryIntent: .recurring, defaultRecurringFrequency: "monthly") }
            )
        }
    }

    private var secondaryAddButton: some View {
        SecondaryCTAButton(
            title: "income.add.primary".localized(defaultValue: "Add income"),
            action: { presentCreateModal(entryIntent: .recurring, defaultRecurringFrequency: "monthly") }
        )
    }

    // MARK: - Sections

    private var sectionsStack: some View {
        VStack(spacing: Spacing.md) {
            incomeSection(frequency: "daily", isExpanded: $isDailyExpanded)
            incomeSection(frequency: "weekly", isExpanded: $isWeeklyExpanded)
            incomeSection(frequency: "monthly", isExpanded: $isMonthlyExpanded)
            incomeSection(frequency: "yearly", isExpanded: $isYearlyExpanded)
            oneTimeSection
        }
    }

    @ViewBuilder
    private func incomeSection(frequency: String, isExpanded: Binding<Bool>) -> some View {
        let categories = viewModel.categoriesForFrequency(frequency)

        FinancialSection(
            title: viewModel.sectionTitle(frequency),
            subtitle: viewModel.formattedSubtotal(frequency),
            accentColor: .brandPositive,
            isExpanded: isExpanded
        ) {
            categoryList(
                categories: categories,
                entryIntent: .recurring,
                defaultRecurringFrequency: frequency,
                type: "income",
                accentColor: .brandPositive
            )
        }
    }

    private var oneTimeSection: some View {
        FinancialSection(
            title: viewModel.oneTimeSectionTitle,
            subtitle: viewModel.formattedOneTimeSubtotal(),
            accentColor: .brandPositive,
            isExpanded: $isOneTimeExpanded
        ) {
            categoryList(
                categories: viewModel.oneTimeIncomes,
                entryIntent: .oneTime,
                defaultRecurringFrequency: "monthly",
                type: "income",
                accentColor: .brandPositive
            )
        }
    }

    @ViewBuilder
    private func categoryList(
        categories: [FinancialCategory],
        entryIntent: FinancialCategoryEntryKind,
        defaultRecurringFrequency: String,
        type: String,
        accentColor: Color
    ) -> some View {
        let addRowFrequency = entryIntent == .oneTime ? "once" : defaultRecurringFrequency

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
                frequency: addRowFrequency,
                type: type,
                onTap: {
                    presentCreateModal(
                        entryIntent: entryIntent,
                        defaultRecurringFrequency: defaultRecurringFrequency
                    )
                }
            )
        }
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: Spacing.lg) {
            ProgressView()
                .scaleEffect(1.2)
            Text(String(localized: "income.loading", defaultValue: "Loading income..."))
                .captionStyle()
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(localized: "income.loading", defaultValue: "Loading income"))
    }

    // MARK: - Actions

    private func presentCreateModal(
        entryIntent: FinancialCategoryEntryKind,
        defaultRecurringFrequency: String = "monthly"
    ) {
        createModalIntent = entryIntent
        createModalFrequency = defaultRecurringFrequency
        showingCreateModal = true
    }

    private func openPendingAmountEntryIfNeeded() {
        guard let category = pendingCategoryForAmountEntry else { return }
        pendingCategoryForAmountEntry = nil
        categoryToEdit = category
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
