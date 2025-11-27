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
                
                Text("widgets.setup.title".localized(defaultValue: "Widgets Setup"))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("widgets.setup.description".localized(defaultValue: "Add BudgetMeter widgets to your Home Screen and Lock Screen to quickly view your financial data."))
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 15) {
                    Text("widgets.setup.how_to_add".localized(defaultValue: "How to Add Widgets"))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .padding(.top, 10)

                    setupStepRow(
                        number: "1",
                        title: "Long Press Home Screen",
                        description: "Press and hold on an empty area of your Home Screen"
                    )

                    setupStepRow(
                        number: "2",
                        title: "Tap the + Button",
                        description: "Tap the + button in the top-left corner"
                    )

                    setupStepRow(
                        number: "3",
                        title: "Search for BudgetMeter",
                        description: "Find BudgetMeter in the widget list"
                    )

                    setupStepRow(
                        number: "4",
                        title: "Choose Widget & Size",
                        description: "Select your preferred widget and size"
                    )

                    setupStepRow(
                        number: "5",
                        title: "Add Widget",
                        description: "Tap \"Add Widget\" to place it on your Home Screen"
                    )
                }
                .padding(.horizontal)

                Spacer()

                VStack(spacing: 12) {
                    Text("widgets.setup.available".localized(defaultValue: "Available Widgets"))
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack(spacing: 12) {
                        widgetBadge(name: "Balance", color: .blue)
                        widgetBadge(name: "Spending", color: .green)
                        widgetBadge(name: "Savings", color: .purple)
                        widgetBadge(name: "Combined", color: .blue)
                    }
                }
                .padding(.horizontal)
            }
            .padding()
            .navigationTitle("Widgets")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private func setupStepRow(number: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.2))
                    .frame(width: 32, height: 32)

                Text(number)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.accentColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }

    private func widgetBadge(name: String, color: Color) -> some View {
        Text(name)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color)
            .cornerRadius(8)
    }
}

#Preview {
    WidgetsSetupView()
}
