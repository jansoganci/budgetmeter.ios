//
//  budgetmeter_iosApp.swift
//  budgetmeter.ios
//
//  Created by Can Soğancı on 17.09.2025.
//

import SwiftUI
import UIKit
import BackgroundTasks

@main
struct budgetmeter_iosApp: App {
    @StateObject private var biometricManager = BiometricManager.shared
    
    init() {
        // Load and apply stored theme preference before any views render
        loadAndApplyStoredTheme()
        
        // Seed initial data on first launch
        let dataSeedingService = DataSeedingService()
        dataSeedingService.seedInitialDataIfNeeded()
        
        // Migrate custom categories to unified FinancialCategory system
        let migrationService = CustomCategoryMigrationService()
        migrationService.performMigrationIfNeeded()
        
        // Initialize background processing
        BackgroundProcessingService.shared.scheduleBackgroundProcessing()
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if biometricManager.shouldRequireAuthentication() {
                    BiometricAuthView {
                        // Authentication successful, show main app
                    }
                } else {
                    ContentView()
                        .environment(\.managedObjectContext, PersistenceService.shared.viewContext)
                }
            }
            .environmentObject(biometricManager)
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                BackgroundProcessingService.shared.applicationDidEnterBackground()
                biometricManager.resetAuthentication()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                BackgroundProcessingService.shared.applicationWillEnterForeground()
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// Loads stored theme preference from UserDefaults and applies it system-wide
    private func loadAndApplyStoredTheme() {
        let userDefaults = UserDefaults.standard
        let appearanceModeKey = "AppearanceMode"
        
        // Load stored appearance mode (same logic as SettingsViewModel)
        let selectedAppearance: AppearanceMode
        if let savedAppearance = userDefaults.string(forKey: appearanceModeKey),
           let mode = AppearanceMode(rawValue: savedAppearance) {
            selectedAppearance = mode
        } else {
            selectedAppearance = .system // Default to system
        }
        
        // Apply appearance to all windows (same logic as SettingsViewModel.applyAppearance)
        DispatchQueue.main.async {
            // Wait for window to be available
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                applyAppearanceToWindow(window, appearance: selectedAppearance)
            } else {
                // If window not ready, observe scene connection
                NotificationCenter.default.addObserver(
                    forName: UIScene.didActivateNotification,
                    object: nil,
                    queue: .main
                ) { _ in
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = windowScene.windows.first {
                        applyAppearanceToWindow(window, appearance: selectedAppearance)
                        NotificationCenter.default.removeObserver(self)
                    }
                }
            }
        }
    }
    
    /// Applies appearance mode to the given window
    private func applyAppearanceToWindow(_ window: UIWindow, appearance: AppearanceMode) {
        switch appearance {
        case .light:
            window.overrideUserInterfaceStyle = .light
        case .dark:
            window.overrideUserInterfaceStyle = .dark
        case .system:
            window.overrideUserInterfaceStyle = .unspecified
        }
    }
}

// MARK: - AppearanceMode Enum

/// Appearance mode enum (extracted from SettingsViewModel for reuse)
private enum AppearanceMode: String, CaseIterable {
    case light = "Light"
    case dark = "Dark"
    case system = "System"
}
