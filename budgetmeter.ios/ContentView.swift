//
//  ContentView.swift
//  budgetmeter.ios
//
//  Created by Can Soğancı on 17.09.2025.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        // Phase 4: Steve Jobs "focus and simplify" - Home-first design
        // 4 tabs: Home (dashboard) + Income + Expenses + Settings
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "house")
                    Text(String(localized: "tab.home.title"))
                }
            
            IncomeView()
                .tabItem {
                    Image(systemName: "plus.circle")
                    Text(String(localized: "tab.income.title"))
                }
            
            ExpenseView()
                .tabItem {
                    Image(systemName: "minus.circle")
                    Text(String(localized: "tab.expenses.title"))
                }
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape")
                    Text(String(localized: "tab.settings.title"))
                }
        }
        .accentColor(Color(hex: "4A90E2")) // Brand primary color from design rulebook
    }
}

#Preview {
    ContentView()
}
