//
//  WidgetsSetupView.swift
//  BudgetMeter
//
//  Created by BudgetMeter Team on 17.09.2025.
//

import SwiftUI

struct WidgetsSetupView: View {
    @StateObject private var premiumManager = PremiumManager.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "rectangle.3.group")
                    .font(.system(size: 80))
                    .foregroundColor(.accentColor)
                
                Text("Widgets Setup")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Add BudgetMeter widgets to your Home Screen and Lock Screen to quickly view your financial data.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 15) {
                    widgetFeatureRow(
                        icon: "house",
                        title: "Home Screen Widgets",
                        description: "View your current balance and spending summary"
                    )
                    
                    widgetFeatureRow(
                        icon: "lock",
                        title: "Lock Screen Widgets",
                        description: "Quick access to your financial overview"
                    )
                    
                    widgetFeatureRow(
                        icon: "chart.bar.fill",
                        title: "Multiple Sizes",
                        description: "Small, medium, and large widget options"
                    )
                }
                .padding(.horizontal)
                
                Spacer()
                
                Button("Add Widget") {
                    // TODO: Implement widget setup
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.horizontal)
            }
            .padding()
            .navigationTitle("Widgets")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private func widgetFeatureRow(icon: String, title: String, description: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 30)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    WidgetsSetupView()
}
