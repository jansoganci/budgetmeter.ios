//
//  SettingsViewModel.swift
//  BudgetMeter
//
//  Created by BudgetMeter Team on 17.09.2025.
//

import Foundation
import SwiftUI
import CoreData

/// ViewModel for Settings screen following MVVM architecture and HIG patterns
@MainActor
final class SettingsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var selectedAppearance: AppearanceMode = .system
    @Published var selectedLanguage: LanguageMode = .english
    @Published var showingPrivacyPolicy = false
    @Published var showingTermsOfService = false
    @Published var showingDataExportSheet = false
    @Published var showingResetDataAlert = false
    
    // MARK: - Private Properties
    
    private let userDefaults: UserDefaults
    private let persistenceService: PersistenceService
    
    // MARK: - Settings Keys
    
    private enum SettingsKeys {
        static let appearanceMode = "AppearanceMode"
        static let languageMode = "LanguageMode"
    }
    
    // MARK: - Enums
    
    enum AppearanceMode: String, CaseIterable {
        case light = "Light"
        case dark = "Dark"
        case system = "System"
        
        var displayName: String {
            switch self {
            case .light: return String(localized: "settings.appearance.light")
            case .dark: return String(localized: "settings.appearance.dark")
            case .system: return String(localized: "settings.appearance.system")
            }
        }
        
        var systemColorScheme: ColorScheme? {
            switch self {
            case .light: return .light
            case .dark: return .dark
            case .system: return nil
            }
        }
    }
    
    enum LanguageMode: String, CaseIterable {
        case english = "en"
        case turkish = "tr"
        
        var displayName: String {
            switch self {
            case .english: return "English"
            case .turkish: return "Türkçe"
            }
        }
        
        var flag: String {
            switch self {
            case .english: return "🇺🇸"
            case .turkish: return "🇹🇷"
            }
        }
    }
    
    // MARK: - Initialization
    
    init(
        userDefaults: UserDefaults = .standard,
        persistenceService: PersistenceService = .shared
    ) {
        self.userDefaults = userDefaults
        self.persistenceService = persistenceService
        loadSettings()
    }
    
    // MARK: - Public Methods
    
    /// Updates appearance mode and applies it system-wide
    func updateAppearance(_ mode: AppearanceMode) {
        selectedAppearance = mode
        userDefaults.set(mode.rawValue, forKey: SettingsKeys.appearanceMode)
        applyAppearance()
    }
    
    /// Updates language preference (for future i18n)
    func updateLanguage(_ language: LanguageMode) {
        selectedLanguage = language
        userDefaults.set(language.rawValue, forKey: SettingsKeys.languageMode)
        // Note: Full i18n implementation would require app restart
    }
    
    /// Shows privacy policy
    func showPrivacyPolicy() {
        showingPrivacyPolicy = true
    }
    
    /// Shows terms of service
    func showTermsOfService() {
        showingTermsOfService = true
    }
    
    /// Initiates data export process
    func exportData() {
        showingDataExportSheet = true
    }
    
    /// Shows reset data confirmation
    func showResetDataConfirmation() {
        showingResetDataAlert = true
    }
    
    /// Resets all user data (with confirmation)
    func resetAllData() {
        // Reset Core Data
        persistenceService.performBackgroundTask { context in
            // Delete all FinancialCategory entities
            let categoryRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "FinancialCategory")
            let categoryDeleteRequest = NSBatchDeleteRequest(fetchRequest: categoryRequest)
            
            // Delete all AppSettings entities
            let settingsRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "AppSettings")
            let settingsDeleteRequest = NSBatchDeleteRequest(fetchRequest: settingsRequest)
            
            do {
                try context.execute(categoryDeleteRequest)
                try context.execute(settingsDeleteRequest)
                try context.save()
                
                DispatchQueue.main.async {
                    // Re-seed initial data
                    let seedingService = DataSeedingService()
                    seedingService.seedInitialDataIfNeeded()
                }
            } catch {
                print("Failed to reset data: \(error)")
            }
        }
    }
    
    /// Gets app version string
    var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Version \(version) (\(build))"
    }
    
    /// Gets app build date
    var buildDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: Date())
    }
    
    // MARK: - Private Methods
    
    private func loadSettings() {
        // Load appearance mode
        if let savedAppearance = userDefaults.string(forKey: SettingsKeys.appearanceMode),
           let mode = AppearanceMode(rawValue: savedAppearance) {
            selectedAppearance = mode
        }
        
        // Load language mode
        if let savedLanguage = userDefaults.string(forKey: SettingsKeys.languageMode),
           let language = LanguageMode(rawValue: savedLanguage) {
            selectedLanguage = language
        }
        
        applyAppearance()
    }
    
    private func applyAppearance() {
        // Apply to all windows in the app
        DispatchQueue.main.async {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first else { return }
            
            switch self.selectedAppearance {
            case .light:
                window.overrideUserInterfaceStyle = .light
            case .dark:
                window.overrideUserInterfaceStyle = .dark
            case .system:
                window.overrideUserInterfaceStyle = .unspecified
            }
        }
    }
}
