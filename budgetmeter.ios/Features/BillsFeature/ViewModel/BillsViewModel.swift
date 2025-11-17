//
//  BillsViewModel.swift
//  BudgetMeter
//
//  Created by BudgetMeter Team on 14.11.2025.
//

import Foundation
import Combine

@MainActor
final class BillsViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var bills: [Bill] = []
    @Published var sortOption: SortOption = .dueDate
    @Published var filterOption: FilterOption = .all

    // MARK: - Private Properties

    private var cancellables = Set<AnyCancellable>()
    private let billManager = BillManager.shared
    private let currencyCode = CurrencyHelper.defaultCurrencyCode()

    // MARK: - Enums

    enum SortOption: String, CaseIterable {
        case dueDate = "Due Date"
        case amount = "Amount"
        case name = "Name"
    }

    enum FilterOption: String, CaseIterable {
        case all = "All"
        case paid = "Paid"
        case unpaid = "Unpaid"
    }

    // MARK: - Initialization

    init() {
        setupObservers()
    }

    // MARK: - Setup

    private func setupObservers() {
        // Listen for bill changes
        NotificationCenter.default.publisher(for: BillManager.billAddedNotification)
            .sink { [weak self] _ in
                self?.loadBills()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: BillManager.billUpdatedNotification)
            .sink { [weak self] _ in
                self?.loadBills()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: BillManager.billDeletedNotification)
            .sink { [weak self] _ in
                self?.loadBills()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: BillManager.billPaidNotification)
            .sink { [weak self] _ in
                self?.loadBills()
            }
            .store(in: &cancellables)
    }

    // MARK: - Computed Properties

    /// Total amount due this month (unpaid bills)
    var totalDueThisMonth: Double {
        billManager.getTotalDueThisMonth()
    }

    /// Total amount paid this month
    var totalPaidThisMonth: Double {
        billManager.getTotalPaidThisMonth()
    }

    /// Total bills this month
    var totalBillsThisMonth: Int {
        billManager.getBillsForCurrentMonth().count
    }

    /// Paid bills count this month
    var paidBillsCount: Int {
        billManager.getBillsForCurrentMonth().filter { $0.isPaid }.count
    }

    /// Unpaid bills count this month
    var unpaidBillsCount: Int {
        billManager.getBillsForCurrentMonth().filter { !$0.isPaid }.count
    }

    /// Overdue bills
    var overdueBills: [Bill] {
        billManager.getOverdueBills()
    }

    /// Bills due soon (next 7 days)
    var dueSoonBills: [Bill] {
        billManager.getDueSoonBills(days: 7)
    }

    /// Sorted and filtered bills
    var sortedAndFilteredBills: [Bill] {
        var filteredBills: [Bill]

        switch filterOption {
        case .all:
            filteredBills = bills
        case .paid:
            filteredBills = bills.filter { $0.isPaid }
        case .unpaid:
            filteredBills = bills.filter { !$0.isPaid }
        }

        switch sortOption {
        case .dueDate:
            return filteredBills.sorted { ($0.dueDate ?? Date()) < ($1.dueDate ?? Date()) }
        case .amount:
            return filteredBills.sorted { $0.amount > $1.amount }
        case .name:
            return filteredBills.sorted { ($0.name ?? "") < ($1.name ?? "") }
        }
    }

    // MARK: - UI Strings

    var summaryTitle: String {
        "This Month"
    }

    var overdueSectionTitle: String {
        "Overdue (\(overdueBills.count))"
    }

    var dueSoonSectionTitle: String {
        "Due Soon (Next 7 days)"
    }

    var allBillsSectionTitle: String {
        "All Bills"
    }

    // MARK: - Public Methods

    func loadBills() {
        bills = billManager.getAllBills()
    }

    func deleteBill(_ bill: Bill) {
        guard let id = bill.id else { return }
        _ = billManager.deleteBill(id: id)
    }

    func markAsPaid(_ bill: Bill) {
        guard let id = bill.id else { return }
        _ = billManager.markAsPaid(id: id)
    }

    func markAsUnpaid(_ bill: Bill) {
        guard let id = bill.id else { return }
        _ = billManager.markAsUnpaid(id: id)
    }

    // MARK: - Formatting

    func formatAmount(_ amount: Double) -> String {
        CurrencyHelper.format(amount: amount, currencyCode: currencyCode)
    }

    func formatDate(_ date: Date) -> String {
        DateFormattingHelper.shared.formatMedium(date)
    }

    func formatShortDate(_ date: Date) -> String {
        DateFormattingHelper.shared.formatMonthDay(date)
    }

    func daysUntilDue(_ bill: Bill) -> Int {
        guard let dueDate = bill.dueDate else { return 0 }
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: Date(), to: dueDate).day ?? 0
        return days
    }

    func daysOverdue(_ bill: Bill) -> Int {
        guard let dueDate = bill.dueDate else { return 0 }
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: dueDate, to: Date()).day ?? 0
        return max(0, days)
    }

    func dueDateText(_ bill: Bill) -> String {
        if bill.isPaid {
            return "Paid \(formatShortDate(bill.paidDate ?? Date()))"
        }

        let days = daysUntilDue(bill)
        if days < 0 {
            let overdue = abs(days)
            return "\(overdue) day\(overdue == 1 ? "" : "s") overdue"
        } else if days == 0 {
            return "Due today"
        } else if days == 1 {
            return "Due tomorrow"
        } else if days <= 7 {
            return "Due in \(days) days"
        } else {
            return "Due \(formatShortDate(bill.dueDate ?? Date()))"
        }
    }

    func frequencyText(_ bill: Bill) -> String {
        guard bill.isRecurring, let frequency = bill.frequency else {
            return "One-time"
        }
        return frequency.capitalized
    }
}
