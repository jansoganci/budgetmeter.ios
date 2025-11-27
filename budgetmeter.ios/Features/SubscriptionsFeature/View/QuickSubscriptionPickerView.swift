//
//  QuickSubscriptionPickerView.swift
//  BudgetMeter
//
//  Quick subscription picker with popular templates and amount input
//

import SwiftUI
import CoreData

/// Quick picker for adding subscriptions from popular templates
struct QuickSubscriptionPickerView: View {

    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = QuickSubscriptionPickerViewModel()

    let onSave: () -> Void

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Custom subscription button at top
                    customSubscriptionButton

                    // Category sections
                    ForEach(SubscriptionCategory.allCases) { category in
                        categorySection(category)
                    }
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.md)
                .padding(.bottom, Spacing.xl)
            }
            .background(Color.appBackground)
            .navigationTitle(String(localized: "subscription.picker.title", defaultValue: "Add Subscription"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(String(localized: "toolbar.cancel", defaultValue: "Cancel")) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(String(localized: "toolbar.save", defaultValue: "Save")) {
                        viewModel.saveSubscriptions()
                        onSave()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(!viewModel.hasAnyAmount)
                }
            }
            .sheet(isPresented: $viewModel.showingCustomInput) {
                SubscriptionInputView(subscription: nil) {
                    onSave()
                    dismiss()
                }
            }
        }
    }

    // MARK: - Category Section

    private func categorySection(_ category: SubscriptionCategory) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Category header
            Text(category.localizedName)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .padding(.leading, Spacing.xs)

            // Subscription rows
            VStack(spacing: 0) {
                let subs = PopularSubscriptionProvider.subscriptions(for: category)
                ForEach(Array(subs.enumerated()), id: \.element.id) { index, subscription in
                    SubscriptionTemplateRow(
                        subscription: subscription,
                        currencySymbol: viewModel.currencySymbol,
                        amount: viewModel.binding(for: subscription)
                    )

                    if index < subs.count - 1 {
                        Divider()
                            .padding(.leading, 56)
                    }
                }
            }
            .background(Color.cardBackground)
            .cornerRadius(CornerRadius.card)
        }
    }

    // MARK: - Custom Subscription Button

    private var customSubscriptionButton: some View {
        Button {
            viewModel.showingCustomInput = true
        } label: {
            HStack(spacing: Spacing.md) {
                ZStack {
                    Circle()
                        .fill(Color.brandProgress.opacity(0.15))
                        .frame(width: 40, height: 40)

                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.brandProgress)
                }

                Text(String(localized: "subscription.add.custom", defaultValue: "Add Custom Subscription"))
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.brandProgress)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .background(Color.cardBackground)
            .cornerRadius(CornerRadius.card)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Subscription Template Row

struct SubscriptionTemplateRow: View {

    let subscription: PopularSubscription
    let currencySymbol: String
    @Binding var amount: String

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.brandExpense.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: subscription.iconName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.brandExpense)
            }

            // Name
            Text(subscription.name)
                .font(.body)
                .foregroundColor(.primary)

            Spacer()

            // Amount input
            HStack(spacing: 4) {
                Text(currencySymbol)
                    .font(.body)
                    .foregroundColor(.secondary)

                TextField("0", text: $amount)
                    .font(.body)
                    .fontWeight(.medium)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 70)
                    .focused($isFocused)
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(Color.appBackground)
            .cornerRadius(CornerRadius.small)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
        .contentShape(Rectangle())
        .onTapGesture {
            isFocused = true
        }
    }
}

// MARK: - ViewModel

@MainActor
final class QuickSubscriptionPickerViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var amounts: [String: String] = [:]
    @Published var showingCustomInput = false
    @Published private(set) var currencySymbol: String = "$"

    // MARK: - Private Properties

    private let persistenceService = PersistenceService.shared

    // MARK: - Initialization

    init() {
        loadCurrency()
    }

    // MARK: - Computed Properties

    var hasAnyAmount: Bool {
        amounts.values.contains { amount in
            guard let value = Double(amount.replacingOccurrences(of: ",", with: ".")) else { return false }
            return value > 0
        }
    }

    // MARK: - Methods

    func binding(for subscription: PopularSubscription) -> Binding<String> {
        Binding(
            get: { self.amounts[subscription.id] ?? "" },
            set: { self.amounts[subscription.id] = $0 }
        )
    }

    func saveSubscriptions() {
        for (subscriptionId, amountString) in amounts {
            // Parse amount
            let cleanedAmount = amountString.replacingOccurrences(of: ",", with: ".")
            guard let amount = Double(cleanedAmount), amount > 0 else { continue }

            // Find the subscription template
            guard let template = PopularSubscriptionProvider.flatList.first(where: { $0.id == subscriptionId }) else { continue }

            // Create subscription via manager
            _ = SubscriptionManager.shared.createSubscription(
                name: template.name,
                amount: amount,
                billingCycle: "monthly",
                firstBillDate: Date(),
                category: template.category.rawValue,
                notes: nil
            )
        }
    }

    // MARK: - Private Methods

    private func loadCurrency() {
        let context = persistenceService.viewContext
        let fetchRequest: NSFetchRequest<AppSettings> = AppSettings.fetchRequest()

        if let settings = try? context.fetch(fetchRequest),
           let storedCode = settings.first?.preferredCurrencyCode,
           CurrencyHelper.supportedCurrencyCodes.contains(storedCode) {
            currencySymbol = CurrencyHelper.symbol(for: storedCode)
        } else {
            currencySymbol = CurrencyHelper.symbol(for: CurrencyHelper.defaultCurrencyCode())
        }
    }
}

// MARK: - Preview

#Preview("Quick Picker") {
    QuickSubscriptionPickerView {
        print("Saved")
    }
}

#Preview("Dark Mode") {
    QuickSubscriptionPickerView {
        print("Saved")
    }
    .preferredColorScheme(.dark)
}
