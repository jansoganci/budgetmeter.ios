//
//  IncomeView.swift
//  BudgetMeter
//
//  Created by BudgetMeter Team on 17.09.2025.
//

import SwiftUI
import CoreData

/// Income entry screen following the design rulebook specifications
struct IncomeView: View {
    
    @StateObject private var viewModel = IncomeViewModel()
    @FocusState private var focusedField: String?
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 24) {
                    if viewModel.isLoading {
                        loadingView
                    } else if !viewModel.hasIncomeData && !viewModel.categoryGroups.isEmpty {
                        emptyStateView
                    }
                    
                    ForEach(viewModel.categoryGroups, id: \.title) { group in
                        categoryGroupView(group)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .navigationTitle(String(localized: "tab.income.title"))
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                viewModel.refresh()
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        focusedField = nil
                    }
                    .foregroundColor(Color(hex: "4A90E2"))
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            viewModel.refresh()
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Subviews
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading income categories...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "plus.circle")
                .font(.system(size: 64))
                .foregroundColor(.green)
            
            Text(String(localized: "empty_state.income.message"))
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .padding()
    }
    
    private func categoryGroupView(_ group: (title: String, categories: [FinancialCategory], color: Color)) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Group Header
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(group.color)
                Text(group.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal, 4)
            
            // Category Grid
            LazyVGrid(columns: createGridColumns(), spacing: 12) {
                ForEach(group.categories, id: \.objectID) { category in
                    CategoryInputCard(
                        category: category,
                        accentColor: group.color,
                        onAmountChange: { amount in
                            viewModel.updateAmount(for: category, amount: amount)
                        },
                        focusedField: $focusedField
                    )
                }
            }
        }
    }
    
    
    // MARK: - Helper Methods
    
    private func createGridColumns() -> [GridItem] {
        // Responsive grid: 2 columns on iPhone, 3 on iPad
        let columnCount = UIDevice.current.userInterfaceIdiom == .pad ? 3 : 2
        return Array(repeating: GridItem(.flexible(), spacing: 12), count: columnCount)
    }
}


// MARK: - Preview

#Preview {
    IncomeView()
        .environment(\.managedObjectContext, PersistenceService.shared.viewContext)
}
