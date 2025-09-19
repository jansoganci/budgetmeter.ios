//
//  DebugView.swift
//  BudgetMeter
//
//  Created by BudgetMeter Team on 17.09.2025.
//  Temporary view for testing Core Data setup
//

import SwiftUI
import CoreData

struct DebugView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \FinancialCategory.uniqueID, ascending: true)],
        predicate: NSPredicate(format: "type == %@", "income"),
        animation: .default
    )
    private var incomeCategories: FetchedResults<FinancialCategory>
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("debug.title".localized())
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("debug.coredata.status".localized())
                    .foregroundColor(.green)
                
                Text(
                    "debug.income.count"
                        .localized(defaultValue: "Income Categories: %lld")
                        .replacingOccurrences(of: "%lld", with: "\(incomeCategories.count)")
                )
                    .font(.headline)
                
                if incomeCategories.isEmpty {
                    Text("debug.categories.error".localized())
                        .foregroundColor(.orange)
                } else {
                    Text("debug.categories.success".localized())
                        .foregroundColor(.green)
                }
                
                Button("Test Data Seeding") {
                    let seedingService = DataSeedingService()
                    seedingService.seedInitialDataIfNeeded()
                }
                .buttonStyle(.borderedProminent)
                
                Button("Show Income View") {
                    // This will be handled by navigation
                }
                .buttonStyle(.bordered)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Debug")
        }
    }
}

#Preview {
    DebugView()
        .environment(\.managedObjectContext, PersistenceService.shared.viewContext)
}
