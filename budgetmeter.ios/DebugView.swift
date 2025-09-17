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
                Text("BudgetMeter Debug")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Core Data Status: ✅ Connected")
                    .foregroundColor(.green)
                
                Text("Income Categories: \(incomeCategories.count)")
                    .font(.headline)
                
                if incomeCategories.isEmpty {
                    Text("No categories found. Data seeding may not have run.")
                        .foregroundColor(.orange)
                } else {
                    Text("✅ Categories loaded successfully!")
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
