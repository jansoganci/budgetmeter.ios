//
//  CurrencyPickerView.swift
//  BudgetMeter
//
//  Created by BudgetMeter Team on 08.11.2023.
//

import SwiftUI

struct CurrencyPickerView: View {
    let featuredCurrencies: [CurrencyOption]
    let otherCurrencies: [CurrencyOption]
    let selectedCurrencyCode: String
    let onSelect: (CurrencyOption) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if !featuredCurrencies.isEmpty {
                    Section(header: Text("settings.currency.section.featured".localized(defaultValue: "Featured"))) {
                        ForEach(featuredCurrencies) { currency in
                            currencyRow(for: currency)
                        }
                    }
                }

                if !otherCurrencies.isEmpty {
                    Section(header: Text("settings.currency.section.all".localized(defaultValue: "All Currencies"))) {
                        ForEach(otherCurrencies) { currency in
                            currencyRow(for: currency)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("settings.currency.picker.title".localized(defaultValue: "Currency"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    @ViewBuilder
    private func currencyRow(for currency: CurrencyOption) -> some View {
        Button {
            onSelect(currency)
            dismiss()
        } label: {
            HStack(spacing: 12) {
                Text(currency.symbol)
                    .font(.title3)
                    .frame(width: 32, alignment: .leading)

                VStack(alignment: .leading, spacing: 2) {
                    Text(currency.localizedName)
                        .font(.body)
                        .foregroundColor(.primary)
                    Text(currency.code)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if selectedCurrencyCode == currency.code {
                    Image(systemName: "checkmark")
                        .foregroundColor(Color(hex: "4A90E2"))
                        .font(.system(size: 16, weight: .semibold))
                        .accessibilityHidden(true)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel(for: currency))
        .accessibilityValue(selectedCurrencyCode == currency.code ? "settings.currency.row.accessibility_selected".localized(defaultValue: "Selected") : "")
    }

    private func accessibilityLabel(for currency: CurrencyOption) -> String {
        let format = "settings.currency.accessibility_format".localized(defaultValue: "%@ – %@")
        return String(format: format, currency.symbol, currency.localizedName)
    }
}

#Preview {
    CurrencyPickerView(
        featuredCurrencies: CurrencyHelper.groupedCurrencyOptions().featured,
        otherCurrencies: CurrencyHelper.groupedCurrencyOptions().others,
        selectedCurrencyCode: "USD",
        onSelect: { _ in }
    )
}
