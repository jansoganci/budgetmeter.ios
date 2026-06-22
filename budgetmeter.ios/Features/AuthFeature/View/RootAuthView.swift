//
//  RootAuthView.swift
//  BudgetMeter
//
//  Auth gate that routes between splash, welcome, and main app.
//

import SwiftUI
import UIKit

struct RootAuthView: View {
    @StateObject private var authService = AuthService.shared
    @EnvironmentObject private var biometricManager: BiometricManager
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        Group {
            switch authService.phase {
            case .unknown, .restoring:
                SplashView()
            case .signedOut:
                WelcomeView()
            case .signedIn:
                if biometricManager.shouldRequireAuthentication() {
                    BiometricAuthView()
                } else if !hasCompletedOnboarding {
                    OnboardingView()
                } else {
                    ContentView()
                }
            }
        }
        .onChange(of: authService.phase) { oldPhase, newPhase in
            if newPhase == .signedIn && oldPhase != .signedIn {
                biometricManager.refreshBiometricSettingsFromStore()
                DataSeedingService().seedInitialDataIfNeeded()
                CustomCategoryMigrationService().performMigrationIfNeeded()
                BackgroundProcessingService.shared.scheduleBackgroundProcessing()
            }
            if newPhase != .signedIn {
                biometricManager.resetAuthentication()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            guard authService.phase == .signedIn, biometricManager.isBiometricEnabled else { return }
            biometricManager.resetAuthentication()
        }
    }
}
