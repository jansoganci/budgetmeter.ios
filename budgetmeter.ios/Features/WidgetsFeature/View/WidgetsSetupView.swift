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

                Text(String(localized: "widgets.setup.title", defaultValue: "Widgets Setup", table: "UI"))
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text(String(
                    localized: "widgets.setup.description.v1",
                    defaultValue: "Add the BudgetMeter net daily pace widget to your Home Screen to see whether you're moving forward or slowing down.",
                    table: "UI"
                ))
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

                if !premiumManager.hasAccess(to: PremiumFeature.widgets) {
                    VStack(spacing: 8) {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.secondary)
                        Text(String(
                            localized: "widget.locked.subtitle",
                            defaultValue: "Unlock net daily pace on your Home Screen",
                            table: "UI"
                        ))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal)
                }

                VStack(alignment: .leading, spacing: 15) {
                    Text(String(localized: "widgets.setup.how_to_add", defaultValue: "How to Add Widgets", table: "UI"))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .padding(.top, 10)

                    setupStepRow(
                        number: "1",
                        title: String(localized: "widgets.setup.step1.title", defaultValue: "Long Press Home Screen", table: "UI"),
                        description: String(
                            localized: "widgets.setup.step1.description",
                            defaultValue: "Press and hold on an empty area of your Home Screen",
                            table: "UI"
                        )
                    )

                    setupStepRow(
                        number: "2",
                        title: String(localized: "widgets.setup.step2.title", defaultValue: "Tap the + Button", table: "UI"),
                        description: String(
                            localized: "widgets.setup.step2.description",
                            defaultValue: "Tap the + button in the top-left corner",
                            table: "UI"
                        )
                    )

                    setupStepRow(
                        number: "3",
                        title: String(localized: "widgets.setup.step3.title", defaultValue: "Search for BudgetMeter", table: "UI"),
                        description: String(
                            localized: "widgets.setup.step3.description",
                            defaultValue: "Find BudgetMeter in the widget list",
                            table: "UI"
                        )
                    )

                    setupStepRow(
                        number: "4",
                        title: String(localized: "widgets.setup.step4.title", defaultValue: "Choose Net Daily Pace", table: "UI"),
                        description: String(
                            localized: "widgets.setup.step4.description",
                            defaultValue: "Select the small net daily pace widget",
                            table: "UI"
                        )
                    )

                    setupStepRow(
                        number: "5",
                        title: String(localized: "widgets.setup.step5.title", defaultValue: "Add Widget", table: "UI"),
                        description: String(
                            localized: "widgets.setup.step5.description",
                            defaultValue: "Tap \"Add Widget\" to place it on your Home Screen",
                            table: "UI"
                        )
                    )
                }
                .padding(.horizontal)

                Spacer()

                VStack(spacing: 12) {
                    Text(String(localized: "widgets.setup.available.v1", defaultValue: "Available Widget", table: "UI"))
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(String(localized: "widget.pace.title", defaultValue: "Net Daily Pace", table: "UI"))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.accentColor)
                        .cornerRadius(8)
                }
                .padding(.horizontal)
            }
            .padding()
            .navigationTitle(String(localized: "widgets.nav.title", defaultValue: "Widgets", table: "UI"))
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
}

#Preview {
    WidgetsSetupView()
}
