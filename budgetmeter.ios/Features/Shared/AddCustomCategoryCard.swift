//
//  AddCustomCategoryCard.swift
//  BudgetMeter
//
//  Created by BudgetMeter Team on 17.09.2025.
//

import SwiftUI

/// Shared card component for adding custom categories - shows "+" for premium users, paywall prompt for free users
struct AddCustomCategoryCard: View {
    
    // MARK: - Properties
    
    let frequency: String
    let type: String
    let accentColor: Color
    let onAddCategory: () -> Void
    
    @StateObject private var premiumManager = PremiumManager.shared
    @State private var showingPaywall = false
    
    // MARK: - Body
    
    var body: some View {
        Button(action: handleTap) {
            VStack(spacing: 12) {
                // Icon
                Image(systemName: premiumManager.hasAccess(to: BudgetMeterCapability.customCategories) ? "plus" : "crown.fill")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(premiumManager.hasAccess(to: BudgetMeterCapability.customCategories) ? accentColor : Color(hex: "4A90E2"))
                    .frame(height: 32)
                
                // Label
                Text(premiumManager.hasAccess(to: BudgetMeterCapability.customCategories) ? "Add Card" : "Premium")
                    .captionStyle(color: .textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(minHeight: 32)
                
                // Subtitle for free users
                if !premiumManager.hasAccess(to: BudgetMeterCapability.customCategories) {
                    Text("ui.unlock".localized(defaultValue: "Unlock"))
                        .badgeStyle()
                        .multilineTextAlignment(.center)
                }
            }
            .padding(Spacing.md)
            .glassSurface()
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous)
                    .stroke(
                        premiumManager.hasAccess(to: BudgetMeterCapability.customCategories)
                            ? Color.clear
                            : Color(hex: "4A90E2").opacity(0.3),
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingPaywall) {
            PremiumPaywallView(
                feature: .customCategories,
                onDismiss: {
                    showingPaywall = false
                },
                onPurchase: {
                    showingPaywall = false
                },
                onRestore: {
                    showingPaywall = false
                }
            )
        }
    }
    
    // MARK: - Actions
    
    private func handleTap() {
        if premiumManager.hasAccess(to: BudgetMeterCapability.customCategories) {
            onAddCategory()
        } else {
            showingPaywall = true
        }
    }
}

// MARK: - Preview

#Preview("Premium User") {
    VStack {
        AddCustomCategoryCard(
            frequency: "daily",
            type: "income",
            accentColor: .green,
            onAddCategory: {
                print("Add category tapped")
            }
        )
        .frame(width: 120, height: 120)
    }
    .padding()
}

#Preview("Free User") {
    VStack {
        AddCustomCategoryCard(
            frequency: "monthly",
            type: "expense", 
            accentColor: .red,
            onAddCategory: {
                print("Add category tapped")
            }
        )
        .frame(width: 120, height: 120)
    }
    .padding()
}
