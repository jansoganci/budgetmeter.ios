//
//  RootAuthView.swift
//  BudgetMeter
//
//  Auth gate that routes between splash, welcome, and main app.
//

import SwiftUI

struct RootAuthView: View {
    @StateObject private var authService = AuthService.shared
    @EnvironmentObject private var biometricManager: BiometricManager
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var biometricUnlocked = false

    var body: some View {
        Group {
            switch authService.phase {
            case .unknown, .restoring:
                SplashView()
            case .signedOut:
                WelcomeView()
            case .signedIn:
                if biometricManager.shouldRequireAuthentication() && !biometricUnlocked {
                    BiometricAuthView {
                        biometricUnlocked = true
                    }
                } else if !hasCompletedOnboarding {
                    OnboardingView()
                } else {
                    ContentView()
                }
            }
        }
        .onChange(of: authService.phase) { oldPhase, newPhase in
            if newPhase == .signedIn && oldPhase != .signedIn {
                DataSeedingService().seedInitialDataIfNeeded()
                CustomCategoryMigrationService().performMigrationIfNeeded()
                BackgroundProcessingService.shared.scheduleBackgroundProcessing()
            }
            if newPhase != .signedIn {
                biometricUnlocked = false
            }
        }
    }
}
