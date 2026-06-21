//
//  SplashView.swift
//  BudgetMeter
//
//  Loading screen shown while auth session is restoring.
//

import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: Spacing.lg) {
                ProgressView()
                    .scaleEffect(1.15)
                Text(String(localized: "auth.splash.loading", defaultValue: "Loading...", table: "UI"))
                    .bodyStyle(color: .textSecondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(String(localized: "auth.splash.loading", defaultValue: "Loading...", table: "UI"))
        }
    }
}
