//
//  BillsView.swift
//  BudgetMeter
//
//  Created by BudgetMeter Team on 14.11.2025.
//

import SwiftUI

/// Main bills list screen
struct BillsView: View {

    // MARK: - Properties

    @StateObject private var viewModel = BillsViewModel()
    @State private var showingAddBill = false
    @State private var billToEdit: Bill?

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // Summary card
                    summaryCard

                    // Overdue section
                    if !viewModel.overdueBills.isEmpty {
                        overdueSection
                    }

                    // Due soon section
                    if !viewModel.dueSoonBills.isEmpty {
                        dueSoonSection
                    }

                    // Sort and filter
                    sortAndFilterSection

                    // All bills list
                    allBillsSection
                }
                .padding(Spacing.lg)
            }
            .navigationTitle("bills.title".localized(defaultValue: "Bills"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddBill = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(.brandProgress)
                    }
                }
            }
            .sheet(isPresented: $showingAddBill) {
                BillInputView(bill: nil) {
                    viewModel.loadBills()
                }
            }
            .sheet(item: $billToEdit) { bill in
                BillInputView(bill: bill) {
                    viewModel.loadBills()
                }
            }
            .onAppear {
                viewModel.loadBills()
            }
        }
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(viewModel.summaryTitle)
                .font(.subheadline)
                .foregroundColor(.textSecondary)

            HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
                Text(viewModel.formatAmount(viewModel.totalDueThisMonth))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)

                Text("due")
                    .font(.body)
                    .foregroundColor(.textSecondary)
            }

            if viewModel.totalPaidThisMonth > 0 {
                Text(viewModel.formatAmount(viewModel.totalPaidThisMonth) + " paid")
                    .font(.body)
                    .foregroundColor(.brandProgress)
            }

            Divider()
                .padding(.vertical, Spacing.xs)

            HStack(spacing: Spacing.md) {
                Text("\(viewModel.totalBillsThisMonth) total")
                    .font(.caption)
                    .foregroundColor(.textSecondary)

                Text("•")
                    .font(.caption)
                    .foregroundColor(.textSecondary)

                Text("\(viewModel.paidBillsCount) paid")
                    .font(.caption)
                    .foregroundColor(.brandProgress)

                Text("•")
                    .font(.caption)
                    .foregroundColor(.textSecondary)

                Text("\(viewModel.unpaidBillsCount) unpaid")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.lg)
        .background(Color.cardBackground)
        .cornerRadius(CornerRadius.card)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    // MARK: - Overdue Section

    private var overdueSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                    .font(.caption)

                Text(viewModel.overdueSectionTitle)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
            }

            VStack(spacing: Spacing.sm) {
                ForEach(viewModel.overdueBills, id: \.id) { bill in
                    BillRowView(
                        bill: bill,
                        viewModel: viewModel,
                        style: .overdue,
                        showRecurring: false,
                        showAutoPay: false,
                        showPaidStatus: false,
                        enableSwipeActions: false,
                        enableBackground: true,
                        onTap: { billToEdit = bill }
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.lg)
        .background(Color.red.opacity(0.1))
        .cornerRadius(CornerRadius.card)
    }

    // MARK: - Due Soon Section

    private var dueSoonSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .foregroundColor(.orange)
                    .font(.caption)

                Text(viewModel.dueSoonSectionTitle)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
            }

            VStack(spacing: Spacing.sm) {
                ForEach(viewModel.dueSoonBills, id: \.id) { bill in
                    BillRowView(
                        bill: bill,
                        viewModel: viewModel,
                        style: .dueSoon,
                        showRecurring: true,
                        showAutoPay: false,
                        showPaidStatus: false,
                        enableSwipeActions: false,
                        enableBackground: true,
                        onTap: { billToEdit = bill }
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.lg)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(CornerRadius.card)
    }

    // MARK: - Sort and Filter Section

    private var sortAndFilterSection: some View {
        VStack(spacing: Spacing.md) {
            // Sort picker
            HStack {
                Text("bills.sort_by".localized(defaultValue: "Sort by:"))
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)

                Picker("Sort", selection: $viewModel.sortOption) {
                    ForEach(BillsViewModel.SortOption.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.segmented)
            }

            // Filter picker
            HStack {
                Text("bills.filter".localized(defaultValue: "Show:"))
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)

                Picker("Filter", selection: $viewModel.filterOption) {
                    ForEach(BillsViewModel.FilterOption.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }

    // MARK: - All Bills Section

    private var allBillsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(viewModel.allBillsSectionTitle)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.textPrimary)

            if viewModel.sortedAndFilteredBills.isEmpty {
                emptyState
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.sortedAndFilteredBills.enumerated()), id: \.element.id) { index, bill in
                        BillRowView(
                            bill: bill,
                            viewModel: viewModel,
                            style: .standard,
                            showRecurring: true,
                            showAutoPay: true,
                            showPaidStatus: true,
                            enableSwipeActions: true,
                            enableBackground: false,
                            onTap: { billToEdit = bill }
                        )
                        .background(Color.cardBackground)

                        if index < viewModel.sortedAndFilteredBills.count - 1 {
                            Divider()
                                .padding(.leading, 56)
                        }
                    }
                }
                .background(Color.cardBackground)
                .cornerRadius(CornerRadius.card)
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "doc.text")
                .font(.system(size: 64))
                .foregroundColor(.brandProgress.opacity(0.3))

            VStack(spacing: Spacing.sm) {
                Text("bills.empty.title".localized(defaultValue: "No Bills Yet"))
                    .font(.headline)
                    .foregroundColor(.textPrimary)

                Text("bills.empty.subtitle".localized(defaultValue: "Tap + to add your first bill"))
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.xxl)
        .background(Color.cardBackground)
        .cornerRadius(CornerRadius.card)
    }
}

// MARK: - Preview

#Preview {
    BillsView()
}
