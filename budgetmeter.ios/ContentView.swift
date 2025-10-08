//
//  ContentView.swift
//  budgetmeter.ios
//
//  Created by Can Soğancı on 17.09.2025.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        // Phase 4: Steve Jobs "focus and simplify" - Home-first design
        // 5 tabs: Home (dashboard) + Income + Expenses + Insights + Settings
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "house")
                    Text("tab.home.title".localized(defaultValue: "Home"))
                }
            
            IncomeView()
                .tabItem {
                    Image(systemName: "plus.circle")
                    Text("tab.income.title".localized(defaultValue: "Income"))
                }
            
            ExpenseView()
                .tabItem {
                    Image(systemName: "minus.circle")
                    Text("tab.expenses.title".localized(defaultValue: "Expenses"))
                }
            
            PremiumFeatureView(
                premiumFeature: .spendingInsights,
                onDismiss: {},
                content: {
                    InsightsView()
                }
            )
            .tabItem {
                Image(systemName: "chart.bar.fill")
                Text("tab.insights.title".localized(defaultValue: "Insights"))
            }
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape")
                    Text("tab.settings.title".localized(defaultValue: "Settings"))
                }
        }
        .environment(\.locale, localizationManager.currentLocale)
        .accentColor(Color(hex: "4A90E2")) // Brand primary color from design rulebook
    }
}

#Preview {
    ContentView()
}
