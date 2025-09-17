//
//  budgetmeter_iosApp.swift
//  budgetmeter.ios
//
//  Created by Can Soğancı on 17.09.2025.
//

import SwiftUI

@main
struct budgetmeter_iosApp: App {
    
    init() {
        // Seed initial data on first launch
        let dataSeedingService = DataSeedingService()
        dataSeedingService.seedInitialDataIfNeeded()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, PersistenceService.shared.viewContext)
        }
    }
}
