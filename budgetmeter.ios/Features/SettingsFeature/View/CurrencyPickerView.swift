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
            ZStack {
                AppBackground()

                ScrollView {
                    VStack(spacing: LayoutSpacing.sectionGap) {
                        if !featuredCurrencies.isEmpty {
                            currencySection(
                                title: "settings.currency.section.featured".localized(defaultValue: "Featured", table: "UI"),
                                currencies: featuredCurrencies
                            )
                        }

                        if !otherCurrencies.isEmpty {
                            currencySection(
                                title: "settings.currency.section.all".localized(defaultValue: "All Currencies", table: "UI"),
                                currencies: otherCurrencies
                            )
                        }
                    }
                    .padding(.horizontal, LayoutSpacing.screenPadding)
                    .padding(.vertical, Spacing.md)
                }
            }
            .navigationTitle("settings.currency.picker.title".localized(defaultValue: "Currency", table: "UI"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("toolbar.done".localized(defaultValue: "Done", table: "UI")) {
                        dismiss()
                    }
                }
            }
        }
    }

    private func currencySection(title: String, currencies: [CurrencyOption]) -> some View {
        SettingsSection(title: title) {
            ForEach(Array(currencies.enumerated()), id: \.element.id) { index, currency in
                currencyRow(for: currency)

                if index != currencies.count - 1 {
                    SettingsDivider()
                }
            }
        }
    }

    @ViewBuilder
    private func currencyRow(for currency: CurrencyOption) -> some View {
        HStack(spacing: Spacing.md) {
            Text(currency.symbol)
                .metricCompactStyle(color: .accentPrimary)
                .frame(width: 32, alignment: .leading)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(currency.localizedName)
                    .bodyStyle()
                Text(currency.code)
                    .captionStyle()
            }

            Spacer()

            if selectedCurrencyCode == currency.code {
                Image(systemName: "checkmark")
                    .foregroundColor(.accentPrimary)
                    .font(.system(size: 16, weight: .semibold))
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .frame(minHeight: LayoutSpacing.rowHeight)
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect(currency)
            dismiss()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel(for: currency))
        .accessibilityValue(selectedCurrencyCode == currency.code ? "settings.currency.row.accessibility_selected".localized(defaultValue: "Selected", table: "UI") : "")
    }

    private func accessibilityLabel(for currency: CurrencyOption) -> String {
        let format = "settings.currency.accessibility_format".localized(defaultValue: "%@ – %@", table: "UI")
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
