//
//  CategoryInputCard.swift
//  BudgetMeter
//
//  Created by BudgetMeter Team on 17.09.2025.
//

import SwiftUI
import CoreData

/// Reusable card component for category input following design system
struct CategoryInputCard: View {
    
    let category: FinancialCategory
    let accentColor: Color
    let onAmountChange: (Double) -> Void
    let currencySymbol: String
    
    var focusedField: FocusState<String?>.Binding
    @State private var inputText: String = ""
    @State private var isEditing: Bool = false
    
    private var fieldID: String {
        category.objectID.uriRepresentation().absoluteString
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Icon
            Image(systemName: DataSeedingService.sfSymbolName(for: category.uniqueID ?? ""))
                .font(.system(size: 28, weight: .medium))
                .foregroundColor(accentColor)
                .frame(height: 32)
            
            // Category Name
            Text(DataSeedingService.displayName(for: category.uniqueID ?? ""))
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(minHeight: 32)
            
            // Amount Input
            amountInputView
        }
        .padding(12)
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    focusedField.wrappedValue == fieldID
                        ? Color(hex: "4A90E2")
                        : Color.clear,
                    lineWidth: 2
                )
        )
        .onAppear {
            updateInputText()
        }
        .onChange(of: category.amount) { _, _ in
            if !isEditing {
                updateInputText()
            }
        }
    }
    
    private var amountInputView: some View {
        HStack(spacing: 4) {
            // Currency Symbol
            Text(currencySymbol)
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Input Field - Apple NumPad with Toolbar Done Button
            TextField(
                "input.placeholder.amount".localized(defaultValue: "Enter amount"),
                text: $inputText
            )
            .keyboardType(.decimalPad)
            .multilineTextAlignment(.center)
           .font(.body.weight(.medium))
           .foregroundColor(.primary)
           .focused(focusedField, equals: fieldID)
           .textFieldStyle(PlainTextFieldStyle())
            .accessibilityLabel(
                String(
                    format: "category.input.label".localized(defaultValue: "Amount input for %@"),
                    DataSeedingService.displayName(for: category.uniqueID ?? "")
                )
            )
            .accessibilityValue(
                inputText.isEmpty
                    ? "category.input.value.empty".localized(defaultValue: "No amount entered")
                    : "\(inputText) \(currencySymbol)"
            )
            .onChange(of: inputText) { _, newValue in
                let amount = parseAmount(from: newValue)
                onAmountChange(amount)
            }
            .onSubmit {
                isEditing = false
                focusedField.wrappedValue = nil
            }
            .onChange(of: focusedField.wrappedValue) { _, newValue in
                if newValue == fieldID {
                    isEditing = true
                } else if newValue != fieldID {
                    isEditing = false
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(uiColor: .systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(uiColor: .separator), lineWidth: 1)
                )
        )
        .frame(minHeight: 44) // Minimum touch target per HIG
        .onTapGesture {
            // Use DispatchQueue to ensure focus is set after current UI update cycle
            DispatchQueue.main.async {
                focusedField.wrappedValue = fieldID
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func updateInputText() {
        let newText = formatInputAmount(category.amount)
        inputText = newText
    }
    
    private func formatInputAmount(_ amount: Double) -> String {
        if amount <= 0 {
            return ""
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        formatter.locale = Locale(identifier: "en_US") // Standardized formatting (1234.56)
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
}
