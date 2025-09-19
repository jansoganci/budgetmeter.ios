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
    @Published var showingResetCumulativeAlert = false
    @Published var selectedCurrencyCode: String = CurrencyHelper.defaultCurrencyCode()
    @Published var isCurrencyPickerPresented = false
    @Published var isLanguagePickerPresented = false
    
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
            case .light: return "settings.appearance.light".localized(defaultValue: "Light")
            case .dark: return "settings.appearance.dark".localized(defaultValue: "Dark")
            case .system: return "settings.appearance.system".localized(defaultValue: "System")
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
        case german = "de"
        case french = "fr"
        case spanish = "es"
        case italian = "it"
        case portuguese = "pt"
        case japanese = "ja"
        case chineseSimplified = "zh-Hans"
        case arabic = "ar"
        
        var displayName: String {
            switch self {
            case .english: return "English"
            case .turkish: return "Türkçe"
            case .german: return "Deutsch"
            case .french: return "Français"
            case .spanish: return "Español"
            case .italian: return "Italiano"
            case .portuguese: return "Português"
            case .japanese: return "日本語"
            case .chineseSimplified: return "简体中文"
            case .arabic: return "العربية"
            }
        }
        
        var flag: String {
            switch self {
            case .english: return "🇺🇸"
            case .turkish: return "🇹🇷"
            case .german: return "🇩🇪"
            case .french: return "🇫🇷"
            case .spanish: return "🇪🇸"
            case .italian: return "🇮🇹"
            case .portuguese: return "🇵🇹"
            case .japanese: return "🇯🇵"
            case .chineseSimplified: return "🇨🇳"
            case .arabic: return "🇸🇦"
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
        loadCurrencyPreference()
    }
    
    // MARK: - Public Methods
    
    /// Updates appearance mode and applies it system-wide
    func updateAppearance(_ mode: AppearanceMode) {
        selectedAppearance = mode
        userDefaults.set(mode.rawValue, forKey: SettingsKeys.appearanceMode)
        applyAppearance()
    }
    
    /// Updates language preference and applies it immediately
    func updateLanguage(_ language: LanguageMode) {
        selectedLanguage = language
        userDefaults.set(language.rawValue, forKey: SettingsKeys.languageMode)
        
        // Apply language change immediately using LocalizationManager
        LocalizationManager.shared.currentLanguage = language.rawValue
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

    var featuredCurrencies: [CurrencyOption] {
        CurrencyHelper.groupedCurrencyOptions().featured
    }

    var otherCurrencies: [CurrencyOption] {
        CurrencyHelper.groupedCurrencyOptions().others
    }

    var selectedCurrencyDisplayText: String {
        guard let option = CurrencyHelper.currencyOption(for: selectedCurrencyCode) else {
            return selectedCurrencyCode
        }

        let format = "settings.currency.subtitle_format".localized(defaultValue: "%@ – %@")
        return String(format: format, option.symbol, option.localizedName)
    }

    func showCurrencyPicker() {
        isCurrencyPickerPresented = true
    }

    func dismissCurrencyPicker() {
        isCurrencyPickerPresented = false
    }

    func selectCurrency(_ currency: CurrencyOption) {
        updateCurrency(currency.code)
        dismissCurrencyPicker()
    }

    // MARK: - Language Picker Methods

    func showLanguagePicker() {
        isLanguagePickerPresented = true
    }

    func dismissLanguagePicker() {
        isLanguagePickerPresented = false
    }

    func selectLanguage(_ language: LanguageMode) {
        updateLanguage(language)
        dismissLanguagePicker()
    }

    var selectedLanguageDisplayText: String {
        let format = "settings.language.subtitle_format".localized(defaultValue: "%@ %@")
        return String(format: format, selectedLanguage.flag, selectedLanguage.displayName)
    }

    /// Updates preferred currency and notifies observers
    func updateCurrency(_ code: String) {
        let resolvedCode = CurrencyHelper.supportedCurrencyCodes.contains(code) ? code : CurrencyHelper.defaultCurrencyCode()
        guard resolvedCode != selectedCurrencyCode else { return }

        selectedCurrencyCode = resolvedCode

        let context = persistenceService.viewContext
        let fetchRequest: NSFetchRequest<AppSettings> = AppSettings.fetchRequest()

        do {
            let settings = try context.fetch(fetchRequest)
            let appSettings: AppSettings

            if let existing = settings.first {
                appSettings = existing
            } else {
                appSettings = AppSettings(context: context)
            }

            appSettings.preferredCurrencyCode = resolvedCode
            persistenceService.save()

            NotificationCenter.default.post(
                name: .currencyDidChange,
                object: nil,
                userInfo: ["code": resolvedCode]
            )
        } catch {
            print("Failed to persist currency: \(error)")
        }
    }

    /// Shows reset long-term meter confirmation
    func showResetCumulativeConfirmation() {
        showingResetCumulativeAlert = true
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
                    seedingService.seedInitialDataIfNeeded(force: true)
                    self.loadCurrencyPreference()
                    NotificationCenter.default.post(
                        name: .currencyDidChange,
                        object: nil,
                        userInfo: ["code": self.selectedCurrencyCode]
                    )
                }
            } catch {
                print("Failed to reset data: \(error)")
            }
        }
    }

    /// Resets the cumulative long-term meter while keeping session data untouched
    func resetCumulativeMeter() {
        let context = persistenceService.viewContext
        let fetchRequest: NSFetchRequest<AppSettings> = AppSettings.fetchRequest()

        do {
            let settings = try context.fetch(fetchRequest)
            let appSettings: AppSettings

            if let existingSettings = settings.first {
                appSettings = existingSettings
            } else {
                appSettings = AppSettings(context: context)
            }

            appSettings.cumulativeTotal = 0.0
            appSettings.cumulativeStartDate = Date()

            persistenceService.save()
        } catch {
            print("Failed to reset cumulative meter: \(error)")
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
        
        // Load language mode and sync with LocalizationManager
        if let savedLanguage = userDefaults.string(forKey: SettingsKeys.languageMode),
           let language = LanguageMode(rawValue: savedLanguage) {
            selectedLanguage = language
            DispatchQueue.main.async {
                LocalizationManager.shared.currentLanguage = language.rawValue
            }
        } else {
            // Initialize LocalizationManager with default language
            DispatchQueue.main.async {
                LocalizationManager.shared.currentLanguage = self.selectedLanguage.rawValue
            }
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

    private func loadCurrencyPreference() {
        let context = persistenceService.viewContext
        let fetchRequest: NSFetchRequest<AppSettings> = AppSettings.fetchRequest()

        if let settings = try? context.fetch(fetchRequest),
           let storedCode = settings.first?.preferredCurrencyCode,
           CurrencyHelper.supportedCurrencyCodes.contains(storedCode) {
            selectedCurrencyCode = storedCode
        } else {
            selectedCurrencyCode = CurrencyHelper.defaultCurrencyCode()
        }
    }
}
