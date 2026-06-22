//
//  budgetmeter_iosApp.swift
//  budgetmeter.ios
//
//  Created by Can Soğancı on 17.09.2025.
//

import SwiftUI
import UIKit
import BackgroundTasks
import UserNotifications

@main
struct budgetmeter_iosApp: App {
    @StateObject private var biometricManager = BiometricManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    private static let notificationPresentationDelegate = NotificationPresentationDelegate()

    init() {
        guard !Self.isRunningUnitTests else { return }

        UNUserNotificationCenter.current().delegate = Self.notificationPresentationDelegate

        // Load and apply stored theme preference before any views render
        loadAndApplyStoredTheme()

        // Phase 2: FinancialCategory v3 fields and legacy savings goal migration
        let financialDataMigrationService = FinancialDataMigrationService()
        financialDataMigrationService.performMigrationIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if Self.isRunningUnitTests {
                    EmptyView()
                } else {
                    RootAuthView()
                        .environment(\.managedObjectContext, PersistenceService.shared.viewContext)
                }
            }
            .environmentObject(biometricManager)
            .environment(\.themeAccent, themeManager.accentColor)
            .accentColor(themeManager.accentColor)
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                BackgroundProcessingService.shared.applicationDidEnterBackground()
                biometricManager.resetAuthentication()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                BackgroundProcessingService.shared.applicationWillEnterForeground()
            }
            .onOpenURL { url in
                handleDeepLink(url)
            }
        }
    }

    private static var isRunningUnitTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    // MARK: - Deep Linking

    /// Handles deep link URLs from widgets and other sources
    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "budgetmeter" else { return }

        let host = url.host ?? ""
        let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))

        switch host {
        case "home":
            if path == "hero" {
                NotificationCenter.default.post(name: .navigateToHomeHero, object: nil)
            } else {
                NotificationCenter.default.post(name: .navigateToHome, object: nil)
            }
        case "expenses":
            NotificationCenter.default.post(name: .navigateToExpenses, object: nil)
        case "income":
            NotificationCenter.default.post(name: .navigateToIncome, object: nil)
        case "premium":
            if path == "widgets" {
                NotificationCenter.default.post(name: .navigateToPremiumWidgets, object: nil)
            }
        default:
            break
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

private final class NotificationPresentationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list, .sound])
    }
}

// MARK: - AppearanceMode Enum

/// Appearance mode enum (extracted from SettingsViewModel for reuse)
private enum AppearanceMode: String, CaseIterable {
    case light = "Light"
    case dark = "Dark"
    case system = "System"
}
