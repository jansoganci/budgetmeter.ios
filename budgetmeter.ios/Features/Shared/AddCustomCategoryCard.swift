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
                Image(systemName: premiumManager.isPremium ? "plus" : "crown.fill")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(premiumManager.isPremium ? accentColor : Color(hex: "4A90E2"))
                    .frame(height: 32)
                
                // Label
                Text(premiumManager.isPremium ? "Add Card" : "Premium")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(minHeight: 32)
                
                // Subtitle for free users
                if !premiumManager.isPremium {
                    Text("Unlock")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(12)
            .background(Color(uiColor: .secondarySystemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        premiumManager.isPremium 
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
        if premiumManager.isPremium {
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

