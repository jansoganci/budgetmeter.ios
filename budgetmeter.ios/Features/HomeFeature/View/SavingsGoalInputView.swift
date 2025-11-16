//
//  SavingsGoalInputView.swift
//  BudgetMeter
//
//  Created by BudgetMeter Team on 19.09.2025.
//

import SwiftUI
import CoreData

/// Simple input view for setting savings goal amount
struct SavingsGoalInputView: View {
    
    let currentGoal: Double
    let currencySymbol: String
    let onSave: (Double) -> Void
    
    @State private var inputText: String = ""
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: Spacing.xl) {
                Spacer()

                // Header
                VStack(spacing: Spacing.lg) {
                    Image(systemName: "target")
                        .font(.system(size: 64))
                        .foregroundColor(.brandProgress)
                    
                    Text("home.savings_goal_input.title".localized(defaultValue: "Set Savings Goal"))
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("home.savings_goal_input.subtitle".localized(defaultValue: "Enter the amount you want to save"))
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Amount Input
                VStack(spacing: Spacing.sm) {
                    HStack {
                        Text(currencySymbol)
                            .font(.title)
                            .foregroundColor(.secondary)

                        TextField(
                            "home.savings_goal_input.placeholder".localized(defaultValue: "Enter amount"),
                            text: $inputText
                        )
                        .keyboardType(.decimalPad)
                        .font(.title)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.leading)
                        .focused($isInputFocused)
                        .accessibilityLabel("home.savings_goal_input.accessibility".localized(defaultValue: "Savings goal amount input"))
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.lg)
                    .background(Color(uiColor: .secondarySystemBackground))
                    .cornerRadius(CornerRadius.card)
                    
                    if currentGoal > 0 {
                        Text("home.savings_goal_input.current".localized(defaultValue: "Current goal: \(formatCurrency(currentGoal))"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: Spacing.md) {
                    // Save Button
                    Button(action: saveGoal) {
                        Text("home.savings_goal_input.save".localized(defaultValue: "Save"))
                            .font(.headline)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.brandProgress)
                            .foregroundColor(.white)
                            .cornerRadius(CornerRadius.button)
                    }
                    .disabled(inputText.isEmpty)
                    .opacity(inputText.isEmpty ? 0.6 : 1.0)
                    
                    // Clear Goal Button (only if current goal exists)
                    if currentGoal > 0 {
                        Button(action: clearGoal) {
                            Text("home.savings_goal_input.clear".localized(defaultValue: "Remove Goal"))
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .padding(Spacing.lg)
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
                    .foregroundColor(.brandProgress)
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            setupInitialInput()
            // Focus on input field when view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isInputFocused = true
            }
        }
    }
    
    // MARK: - Private Methods
    
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
        if amount <= 0 {
            return ""
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        formatter.locale = Locale(identifier: "en_US") // Standardized formatting
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        
        return formatter.string(from: NSNumber(value: amount)) ?? "0"
    }
    
    private func parseAmount(from input: String) -> Double {
        // Remove any non-numeric characters except decimal point
        let cleanedInput = input.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
        
        // Handle empty input
        if cleanedInput.isEmpty {
            return 0
        }
        
        return Double(cleanedInput) ?? 0
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_US") // Standardized formatting
        formatter.currencySymbol = currencySymbol
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        
        return formatter.string(from: NSNumber(value: amount)) ?? "\(currencySymbol)0"
    }
}

// MARK: - Preview

#Preview {
    SavingsGoalInputView(
        currentGoal: 5000,
        currencySymbol: "$",
        onSave: { amount in
            print("Savings goal set to: \(amount)")
        }
    )
}
