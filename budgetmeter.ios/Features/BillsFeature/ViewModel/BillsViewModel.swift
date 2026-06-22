//
//  BillsViewModel.swift
//  BudgetMeter
//
//  Created by BudgetMeter Team on 14.11.2025.
//

import Foundation
import CoreData
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
    private let persistenceService: PersistenceService
    private var currencyCode: String = CurrencyHelper.defaultCurrencyCode()

    // MARK: - Enums

    enum SortOption: String, CaseIterable {
        case dueDate = "Due Date"
        case amount = "Amount"
        case name = "Name"
        
        var displayName: String {
            switch self {
            case .dueDate: return "bills.sort.due_date".localized(defaultValue: "Due Date")
            case .amount: return "bills.sort.amount".localized(defaultValue: "Amount")
            case .name: return "bills.sort.name".localized(defaultValue: "Name")
            }
        }
    }

    enum FilterOption: String, CaseIterable {
        case all = "All"
        case paid = "Paid"
        case unpaid = "Unpaid"
        
        var displayName: String {
            switch self {
            case .all: return "bills.filter.all".localized(defaultValue: "All")
            case .paid: return "bills.filter.paid".localized(defaultValue: "Paid")
            case .unpaid: return "bills.filter.unpaid".localized(defaultValue: "Unpaid")
            }
        }
    }

    // MARK: - Initialization

    init(persistenceService: PersistenceService = .shared) {
        self.persistenceService = persistenceService
        setupObservers()
        loadCurrency()
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

        // Listen for currency changes
        NotificationCenter.default.publisher(for: .currencyDidChange)
            .sink { [weak self] notification in
                self?.currencyDidChange(notification)
            }
            .store(in: &cancellables)

        // Listen for language changes
        NotificationCenter.default.publisher(for: .languageDidChange)
            .sink { [weak self] notification in
                self?.languageDidChange(notification)
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
        "bills.summary.title".localized(defaultValue: "This Month")
    }

    var overdueSectionTitle: String {
        String(format: "bills.summary.overdue".localized(defaultValue: "Overdue (%d)"), overdueBills.count)
    }

    var dueSoonSectionTitle: String {
        "bills.summary.due_soon".localized(defaultValue: "Due Soon (Next 7 days)")
    }

    var allBillsSectionTitle: String {
        "bills.summary.all_bills".localized(defaultValue: "All Bills")
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

    // MARK: - Currency Management

    func loadCurrency() {
        let context = persistenceService.viewContext
        let fetchRequest: NSFetchRequest<AppSettings> = AppSettings.fetchRequest()
        if let settings = try? context.fetch(fetchRequest),
           let storedCode = settings.first?.preferredCurrencyCode,
           CurrencyHelper.supportedCurrencyCodes.contains(storedCode) {
            updateCurrency(code: storedCode)
        } else {
            updateCurrency(code: CurrencyHelper.defaultCurrencyCode())
        }
    }

    func updateCurrency(code: String) {
        let resolvedCode = CurrencyHelper.supportedCurrencyCodes.contains(code) ? code : CurrencyHelper.defaultCurrencyCode()
        currencyCode = resolvedCode
    }

    @objc func currencyDidChange(_ notification: Notification) {
        if let code = notification.userInfo?["code"] as? String {
            updateCurrency(code: code)
        } else {
            loadCurrency()
        }
    }

    @objc func languageDidChange(_ notification: Notification) {
        // Trigger UI refresh to re-evaluate localized strings
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }

    // MARK: - Formatting

    func formatAmount(_ amount: Double, currencyCode: String? = nil) -> String {
        CurrencyHelper.format(
            amount: amount,
            currencyCode: RecordCurrencySupport.resolvedDisplayCode(storedCode: currencyCode ?? self.currencyCode)
        )
    }

    func formatAmount(for bill: Bill, _ amount: Double) -> String {
        formatAmount(amount, currencyCode: bill.currencyCode)
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
            return String(format: "bills.due_date.paid".localized(defaultValue: "Paid %@"), formatShortDate(bill.paidDate ?? Date()))
        }

        let days = daysUntilDue(bill)
        if days < 0 {
            let overdue = abs(days)
            let formatString = "bills.due_date.overdue".localized(defaultValue: "\(overdue) day\(overdue == 1 ? "" : "s") overdue")
            return String(format: formatString, overdue)
        } else if days == 0 {
            return "bills.due_date.today".localized(defaultValue: "Due today")
        } else if days == 1 {
            return "bills.due_date.tomorrow".localized(defaultValue: "Due tomorrow")
        } else if days <= 7 {
            return String(format: "bills.due_date.in_days".localized(defaultValue: "Due in %d days"), days)
        } else {
            return String(format: "bills.due_date.due".localized(defaultValue: "Due %@"), formatShortDate(bill.dueDate ?? Date()))
        }
    }

    func frequencyText(_ bill: Bill) -> String {
        guard bill.isRecurring, let frequency = bill.frequency else {
            return "bills.frequency.one_time".localized(defaultValue: "One-time")
        }
        
        switch frequency.lowercased() {
        case "daily": return "recurring.frequency.daily".localized(defaultValue: "Daily")
        case "weekly": return "recurring.frequency.weekly".localized(defaultValue: "Weekly")
        case "monthly": return "recurring.frequency.monthly".localized(defaultValue: "Monthly")
        case "quarterly": return "recurring.frequency.quarterly".localized(defaultValue: "Quarterly")
        case "yearly": return "recurring.frequency.yearly".localized(defaultValue: "Yearly")
        default: return frequency.capitalized
        }
    }
}
