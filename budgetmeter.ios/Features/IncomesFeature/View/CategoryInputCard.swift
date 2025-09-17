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
            Text(String(localized: "currency.symbol"))
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Input Field - Apple NumPad with Toolbar Done Button
            TextField(
                String(localized: "input.placeholder.amount"),
                text: $inputText
            )
            .keyboardType(.decimalPad)
            .multilineTextAlignment(.center)
            .font(.body.weight(.medium))
            .foregroundColor(.primary)
            .focused(focusedField, equals: fieldID)
            .accessibilityLabel("Amount input for \(DataSeedingService.displayName(for: category.uniqueID ?? ""))")
            .accessibilityValue(inputText.isEmpty ? "No amount entered" : "\(inputText) dollars")
            .onTapGesture {
                focusedField.wrappedValue = fieldID
                isEditing = true
            }
            .onChange(of: inputText) { _, newValue in
                if isEditing {
                    let amount = parseAmount(from: newValue)
                    onAmountChange(amount)
                }
            }
            .onSubmit {
                isEditing = false
                focusedField.wrappedValue = nil
            }
            .onChange(of: focusedField.wrappedValue) { _, newValue in
                if newValue != fieldID {
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
    }
    
    // MARK: - Helper Methods
    
    private func updateInputText() {
        inputText = formatInputAmount(category.amount)
    }
    
    private func formatInputAmount(_ amount: Double) -> String {
        if amount <= 0 {
            return ""
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
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
