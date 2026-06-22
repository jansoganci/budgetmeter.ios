//
//  ContentView.swift
//  budgetmeter.ios
//
//  Created by Can Soğancı on 17.09.2025.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @ObservedObject private var themeManager = ThemeManager.shared

    @State private var selectedTab: AppTab = .home
    @State private var showingWidgetPaywall = false

    var body: some View {
        // Phase 4: Steve Jobs "focus and simplify" - Home-first design
        // 5 tabs: Home (dashboard) + Income + Expenses + Insights + Settings
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: "house")
                    Text("tab.home.title".localized(defaultValue: "Home"))
                }
                .tag(AppTab.home)

            IncomeView()
                .tabItem {
                    Image(systemName: "plus.circle")
                    Text("tab.income.title".localized(defaultValue: "Income"))
                }
                .tag(AppTab.income)

            ExpenseView()
                .tabItem {
                    Image(systemName: "minus.circle")
                    Text("tab.expenses.title".localized(defaultValue: "Expenses"))
                }
                .tag(AppTab.expenses)

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
            .tag(AppTab.insights)

            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape")
                    Text("tab.settings.title".localized(defaultValue: "Settings"))
                }
                .tag(AppTab.settings)
        }
        .environment(\.locale, localizationManager.currentLocale)
        .environment(\.themeAccent, themeManager.accentColor)
        .accentColor(themeManager.accentColor)
        .onReceive(NotificationCenter.default.publisher(for: .navigateToHome)) { _ in
            selectedTab = .home
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToHomeHero)) { _ in
            selectedTab = .home
            NotificationCenter.default.post(name: .focusHomeHero, object: nil)
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToExpenses)) { _ in
            selectedTab = .expenses
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToIncome)) { _ in
            selectedTab = .income
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToPremiumWidgets)) { _ in
            showingWidgetPaywall = true
        }
        .sheet(isPresented: $showingWidgetPaywall) {
            PremiumPaywallView(
                feature: .widgets,
                onDismiss: { showingWidgetPaywall = false },
                onPurchase: { showingWidgetPaywall = false },
                onRestore: { showingWidgetPaywall = false }
            )
        }
    }
}

private enum AppTab: Int, Hashable {
    case home
    case income
    case expenses
    case insights
    case settings
}

#Preview {
    ContentView()
}
