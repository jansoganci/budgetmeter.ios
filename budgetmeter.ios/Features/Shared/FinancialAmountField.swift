//
//  FinancialAmountField.swift
//  BudgetMeter
//
//  Shared amount input styling for modals and sheets (layout only).
//

import SwiftUI

/// Standard currency-prefixed amount field for input flows.
struct FinancialAmountField: View {

    let label: String?
    let currencySymbol: String
    @Binding var text: String
    var accentColor: Color = .textSecondary
    var useHeroTypography: Bool = true
    var alignment: TextAlignment = .leading
    private var focusBinding: FocusState<Bool>.Binding?

    init(
        label: String?,
        currencySymbol: String,
        text: Binding<String>,
        accentColor: Color = .textSecondary,
        useHeroTypography: Bool = true,
        alignment: TextAlignment = .leading
    ) {
        self.label = label
        self.currencySymbol = currencySymbol
        self._text = text
        self.accentColor = accentColor
        self.useHeroTypography = useHeroTypography
        self.alignment = alignment
        self.focusBinding = nil
    }

    init(
        label: String?,
        currencySymbol: String,
        text: Binding<String>,
        accentColor: Color = .textSecondary,
        useHeroTypography: Bool = true,
        alignment: TextAlignment = .leading,
        focused: FocusState<Bool>.Binding
    ) {
        self.label = label
        self.currencySymbol = currencySymbol
        self._text = text
        self.accentColor = accentColor
        self.useHeroTypography = useHeroTypography
        self.alignment = alignment
        self.focusBinding = focused
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            if let label {
                Text(label)
                    .statusTitleStyle(color: .textSecondary)
            }

            HStack(spacing: Spacing.sm) {
                currencySymbolLabel

                amountTextField
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(alignment)
            }
            .padding(Spacing.lg)
            .background(Color.surfaceInset)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
        }
    }

    @ViewBuilder
    private var currencySymbolLabel: some View {
        if useHeroTypography {
            Text(currencySymbol)
                .metricMediumStyle(color: accentColor)
        } else {
            Text(currencySymbol)
                .bodyStyle(color: accentColor)
        }
    }

    @ViewBuilder
    private var amountTextField: some View {
        if useHeroTypography {
            if let focusBinding {
                TextField("0", text: $text)
                    .focused(focusBinding)
                    .paceHeroStyle()
            } else {
                TextField("0", text: $text)
                    .paceHeroStyle()
            }
        } else {
            if let focusBinding {
                TextField("0", text: $text)
                    .focused(focusBinding)
                    .font(.title3.weight(.semibold))
            } else {
                TextField("0", text: $text)
                    .font(.title3.weight(.semibold))
            }
        }
    }
}
