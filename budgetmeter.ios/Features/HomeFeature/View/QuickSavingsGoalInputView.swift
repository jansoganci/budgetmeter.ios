//
//  QuickSavingsGoalInputView.swift
//  BudgetMeter
//
//  Set Goal sheet from Home — v2 input flow.
//

import SwiftUI

/// Simple input view for setting savings goal amount from Home screen
struct QuickSavingsGoalInputView: View {

    let currentGoal: Double
    let currencySymbol: String
    let onSave: (Double) -> Void

    @State private var inputText: String = ""
    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeAccent) private var themeAccent
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationView {
            ZStack {
                AppBackground()

                VStack(spacing: LayoutSpacing.sectionGap) {
                    SectionHeader(
                        title: "home.savings_goal_input.title".localized(defaultValue: "Set Savings Goal"),
                        subtitle: "home.savings_goal_input.subtitle".localized(defaultValue: "How much do you want to save?")
                    )

                    GlassCard {
                        VStack(alignment: .leading, spacing: LayoutSpacing.cardInternalGap) {
                            FinancialAmountField(
                                label: nil,
                                currencySymbol: currencySymbol,
                                text: $inputText,
                                accentColor: themeAccent,
                                focused: $isInputFocused
                            )
                            .accessibilityLabel("home.savings_goal_input.accessibility".localized(defaultValue: "Savings goal amount input"))

                            if currentGoal > 0 {
                                Text("home.savings_goal_input.current".localized(defaultValue: "Current goal: \(formatCurrency(currentGoal))"))
                                    .captionStyle()
                            }
                        }
                    }

                    Spacer(minLength: Spacing.md)

                    PrimaryCTAButton(
                        title: "home.savings_goal_input.save".localized(defaultValue: "Save"),
                        isDisabled: inputText.isEmpty,
                        action: saveGoal
                    )

                    if currentGoal > 0 {
                        Button(action: clearGoal) {
                            Text("home.savings_goal_input.clear".localized(defaultValue: "Remove Goal"))
                                .bodyStyle(color: .financialNegative)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(LayoutSpacing.screenPadding)
            }
            .navigationTitle("home.savings_goal_input.nav_title".localized(defaultValue: "Savings Goal"))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("toolbar.cancel".localized(defaultValue: "Cancel")) {
                        dismiss()
                    }
                }

                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("toolbar.done".localized(defaultValue: "Done")) {
                        isInputFocused = false
                    }
                    .foregroundColor(themeAccent)
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            setupInitialInput()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isInputFocused = true
            }
        }
    }

    private func setupInitialInput() {
        if currentGoal > 0 {
            inputText = formatInputAmount(currentGoal)
        }
    }

    private func saveGoal() {
        let amount = parseAmount(from: inputText)
        if amount > 0 {
            onSave(amount)
            dismiss()
        }
    }

    private func clearGoal() {
        onSave(0)
        dismiss()
    }

    private func formatInputAmount(_ amount: Double) -> String {
        if amount <= 0 { return "" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        formatter.locale = Locale(identifier: "en_US")
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "0"
    }

    private func parseAmount(from input: String) -> Double {
        let cleanedInput = input.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
        if cleanedInput.isEmpty { return 0 }
        return Double(cleanedInput) ?? 0
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_US")
        formatter.currencySymbol = currencySymbol
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "\(currencySymbol)0"
    }
}

#Preview {
    QuickSavingsGoalInputView(
        currentGoal: 5000,
        currencySymbol: "$",
        onSave: { _ in }
    )
}
