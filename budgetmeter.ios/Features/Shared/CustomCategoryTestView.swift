//
//  CustomCategoryTestView.swift
//  BudgetMeter
//
//  Created by BudgetMeter Team on 17.09.2025.
//

import SwiftUI

#if DEBUG
/// Test view for verifying custom category creation functionality during development
struct CustomCategoryTestView: View {
    
    @State private var showingIncomeModal = false
    @State private var showingExpenseModal = false
    @StateObject private var premiumManager = PremiumManager.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // Premium Status
                    VStack {
                        Text("Premium Status: \(premiumManager.isPremium ? "Premium" : "Free")")
                            .font(.headline)
                            .foregroundColor(premiumManager.isPremium ? .green : .orange)
                        
                        Button("Toggle Premium (Debug)") {
                            premiumManager.setDebugPremiumStatus(!premiumManager.isPremium)
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemBackground))
                    .cornerRadius(12)
                    
                    // Add Custom Category Cards Test
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Add Custom Category Cards")
                            .font(.headline)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                            // Income Cards
                            AddCustomCategoryCard(
                                frequency: "daily",
                                type: "income",
                                accentColor: .green,
                                onAddCategory: { showingIncomeModal = true }
                            )
                            
                            AddCustomCategoryCard(
                                frequency: "monthly",
                                type: "income",
                                accentColor: .blue,
                                onAddCategory: { showingIncomeModal = true }
                            )
                            
                            AddCustomCategoryCard(
                                frequency: "yearly",
                                type: "income",
                                accentColor: .purple,
                                onAddCategory: { showingIncomeModal = true }
                            )
                            
                            // Expense Cards
                            AddCustomCategoryCard(
                                frequency: "daily",
                                type: "expense",
                                accentColor: .red,
                                onAddCategory: { showingExpenseModal = true }
                            )
                            
                            AddCustomCategoryCard(
                                frequency: "monthly",
                                type: "expense",
                                accentColor: .orange,
                                onAddCategory: { showingExpenseModal = true }
                            )
                            
                            AddCustomCategoryCard(
                                frequency: "yearly",
                                type: "expense",
                                accentColor: .gray,
                                onAddCategory: { showingExpenseModal = true }
                            )
                        }
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemBackground))
                    .cornerRadius(12)
                    
                    // Test Buttons
                    VStack(spacing: 12) {
                        Text("Test Modals")
                            .font(.headline)
                        
                        Button("Test Income Category Modal") {
                            showingIncomeModal = true
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button("Test Expense Category Modal") {
                            showingExpenseModal = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemBackground))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Custom Category Test")
        }
        .sheet(isPresented: $showingIncomeModal) {
            CreateCategoryModal(
                entryIntent: .recurring,
                defaultRecurringFrequency: "monthly",
                type: "income",
                onSave: { category in
                    print("✅ Created income category: \(category.customName ?? "Unknown")")
                    showingIncomeModal = false
                },
                onCancel: {
                    showingIncomeModal = false
                }
            )
        }
        .sheet(isPresented: $showingExpenseModal) {
            CreateCategoryModal(
                entryIntent: .recurring,
                defaultRecurringFrequency: "monthly",
                type: "expense",
                onSave: { category in
                    print("✅ Created expense category: \(category.customName ?? "Unknown")")
                    showingExpenseModal = false
                },
                onCancel: {
                    showingExpenseModal = false
                }
            )
        }
    }
}

#Preview {
    CustomCategoryTestView()
}
#endif

