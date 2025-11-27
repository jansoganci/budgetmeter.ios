//
//  SubscriptionsViewModel.swift
//  BudgetMeter
//
//  Created by BudgetMeter Team on 14.11.2025.
//

import Foundation
import SwiftUI
import CoreData
import Combine

/// ViewModel for the Subscriptions screen following MVVM architecture
@MainActor
final class SubscriptionsViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var subscriptions: [Subscription] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var sortOption: SortOption = .renewalDate
    @Published private(set) var currencySymbol: String = CurrencyHelper.symbol(for: CurrencyHelper.defaultCurrencyCode())

    // MARK: - Sort Options

    enum SortOption: String, CaseIterable {
        case renewalDate = "Renewal Date"
        case name = "Name"
        
        var displayName: String {
            switch self {
            case .renewalDate: return "subscriptions.sort.renewal_date".localized(defaultValue: "Renewal Date")
            case .name: return "subscriptions.sort.name".localized(defaultValue: "Name")
            }
        }
    }

    // MARK: - Computed Properties

    /// Total monthly cost of all subscriptions
    var totalMonthlyCost: Double {
        return SubscriptionManager.shared.getTotalMonthlyCost()
    }

    /// Total yearly cost of all subscriptions
    var totalYearlyCost: Double {
        return SubscriptionManager.shared.getTotalYearlyCost()
    }

    /// Number of active subscriptions
    var activeCount: Int {
        return subscriptions.count
    }

    /// Subscriptions renewing within 7 days
    var renewingSoon: [Subscription] {
        return SubscriptionManager.shared.getUpcomingRenewals(days: 7)
    }

    /// Subscriptions sorted by current sort option
    var sortedSubscriptions: [Subscription] {
        switch sortOption {
        case .renewalDate:
            return subscriptions.sorted { ($0.nextRenewalDate ?? Date()) < ($1.nextRenewalDate ?? Date()) }
        case .name:
            return subscriptions.sorted { ($0.name ?? "") < ($1.name ?? "") }
        }
    }

    // MARK: - Localized Strings

    var summaryTitle: String {
        return "subscriptions.summary.title".localized(defaultValue: "Monthly Total")
    }

    var renewingSoonTitle: String {
        return "subscriptions.renewing_soon.title".localized(defaultValue: "Renewing Soon")
    }

    var allSubscriptionsTitle: String {
        return "subscriptions.all.title".localized(defaultValue: "All Subscriptions")
    }

    // MARK: - Private Properties

    private var cancellables = Set<AnyCancellable>()
    private let persistenceService: PersistenceService
    private var currencyCode: String = CurrencyHelper.defaultCurrencyCode()

    // MARK: - Initialization

    init(persistenceService: PersistenceService = .shared) {
        self.persistenceService = persistenceService
        setupCurrencyObserver()
        setupLanguageObserver()
        setupSubscriptionObservers()
        loadCurrency()
        loadSubscriptions()
    }

    // MARK: - Public Methods

    /// Load all subscriptions
    func loadSubscriptions() {
        isLoading = true
        errorMessage = nil

        // Fetch from manager
        subscriptions = SubscriptionManager.shared.getAllActiveSubscriptions()

        isLoading = false
    }

    /// Delete a subscription
    func deleteSubscription(_ subscription: Subscription) {
        guard let id = subscription.id else { return }

        let success = SubscriptionManager.shared.deleteSubscription(id: id)
        if success {
            loadSubscriptions() // Reload list
        } else {
            errorMessage = "subscriptions.error.delete_failed".localized(defaultValue: "Failed to delete subscription")
        }
    }

    /// Pause a subscription
    func pauseSubscription(_ subscription: Subscription) {
        guard let id = subscription.id else { return }

        let success = SubscriptionManager.shared.pauseSubscription(id: id)
        if success {
            loadSubscriptions() // Reload list
        } else {
            errorMessage = "subscriptions.error.pause_failed".localized(defaultValue: "Failed to pause subscription")
        }
    }

    /// Resume a paused subscription
    func resumeSubscription(_ subscription: Subscription) {
        guard let id = subscription.id else { return }

        let success = SubscriptionManager.shared.resumeSubscription(id: id)
        if success {
            loadSubscriptions() // Reload list
        } else {
            errorMessage = "subscriptions.error.resume_failed".localized(defaultValue: "Failed to resume subscription")
        }
    }

    /// Format amount for display
    func formatAmount(_ amount: Double) -> String {
        return CurrencyHelper.format(amount: amount, currencyCode: currencyCode)
    }

    /// Format date for display
    func formatDate(_ date: Date) -> String {
        DateFormattingHelper.shared.formatMediumNoTime(date)
    }

    /// Get days until renewal
    func daysUntilRenewal(_ subscription: Subscription) -> Int {
        guard let renewalDate = subscription.nextRenewalDate else { return 0 }
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: Date(), to: renewalDate).day ?? 0
        return max(0, days)
    }

    /// Get renewal text for display
    func renewalText(_ subscription: Subscription) -> String {
        let days = daysUntilRenewal(subscription)

        if days == 0 {
            return "subscriptions.renews.today".localized(defaultValue: "Renews today")
        } else if days == 1 {
            return "subscriptions.renews.tomorrow".localized(defaultValue: "Renews tomorrow")
        } else if days <= 7 {
            return "subscriptions.renews.in_days".localized(defaultValue: "Renews in \(days) days")
        } else {
            return "subscriptions.renews.on_date".localized(defaultValue: "Renews \(formatDate(subscription.nextRenewalDate ?? Date()))")
        }
    }

    /// Get billing cycle display text
    func billingCycleText(_ subscription: Subscription) -> String {
        guard let cycle = subscription.billingCycle else { return "Monthly" }
        switch cycle.lowercased() {
        case "monthly":
            return "subscriptions.cycle.monthly".localized(defaultValue: "Monthly")
        case "yearly":
            return "subscriptions.cycle.yearly".localized(defaultValue: "Yearly")
        case "weekly":
            return "subscriptions.cycle.weekly".localized(defaultValue: "Weekly")
        default:
            return cycle.capitalized
        }
    }

    // MARK: - Private Methods

    private func setupCurrencyObserver() {
        // Listen for currency changes
        NotificationCenter.default.publisher(for: .currencyDidChange)
            .sink { [weak self] notification in
                self?.currencyDidChange(notification)
            }
            .store(in: &cancellables)
    }

    private func setupLanguageObserver() {
        // Listen for language changes
        NotificationCenter.default.publisher(for: .languageDidChange)
            .sink { [weak self] notification in
                self?.languageDidChange(notification)
            }
            .store(in: &cancellables)
    }

    private func setupSubscriptionObservers() {
        // Listen for subscription changes
        NotificationCenter.default.publisher(for: SubscriptionManager.subscriptionAddedNotification)
            .sink { [weak self] _ in
                self?.loadSubscriptions()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: SubscriptionManager.subscriptionUpdatedNotification)
            .sink { [weak self] _ in
                self?.loadSubscriptions()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: SubscriptionManager.subscriptionDeletedNotification)
            .sink { [weak self] _ in
                self?.loadSubscriptions()
            }
            .store(in: &cancellables)
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
        currencySymbol = CurrencyHelper.symbol(for: resolvedCode)
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
}
