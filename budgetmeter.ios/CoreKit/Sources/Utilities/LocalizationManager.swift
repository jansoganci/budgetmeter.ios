//
//  LocalizationManager.swift
//  BudgetMeter
//
//  Created by BudgetMeter Team on 18.09.2025.
//

import Foundation
import SwiftUI

/// Manages app-level localization and language switching
class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()

    @Published var currentLanguage: String = "en" {
        didSet {
            guard oldValue != currentLanguage else { return }
            applyLanguage(currentLanguage, persistSelection: true)
        }
    }

    @Published private(set) var currentLocale: Locale

    private var bundle: Bundle

    private init() {
        // Settings stores LanguageMode; keep AppLanguage in sync for legacy installs.
        let savedLanguage = UserDefaults.standard.string(forKey: "LanguageMode")
            ?? UserDefaults.standard.string(forKey: "AppLanguage")
            ?? "en"
        self.currentLocale = Locale(identifier: savedLanguage)
        self.bundle = Bundle.main

        if savedLanguage != currentLanguage {
            currentLanguage = savedLanguage
        } else {
            applyLanguage(savedLanguage, persistSelection: false)
        }
    }

    /// Changes the app's language at runtime
    func setLanguage(_ languageCode: String) {
        applyLanguage(languageCode, persistSelection: false)
    }
    
    /// Gets localized string for current language from all available string catalogs
    func localizedString(for key: String, defaultValue: String = "", table: String? = nil) -> String {
        if let table {
            let tableValue = bundle.localizedString(forKey: key, value: defaultValue, table: table)
            if tableValue != key && tableValue != defaultValue {
                return tableValue
            }
        }

        // Try to find the string in the appropriate bundle for current language
        let localizedValue = bundle.localizedString(forKey: key, value: defaultValue, table: nil)
        
        // If we got the key back (not found), try different string catalog files
        if localizedValue == key || localizedValue == defaultValue {
            // Try different string catalog tables
            let tables = ["Categories", "UI", "Settings", "Home", "Alerts", "Currency", "Debug"]
            
            for table in tables {
                let tableValue = bundle.localizedString(forKey: key, value: defaultValue, table: table)
                if tableValue != key && tableValue != defaultValue {
                    return tableValue
                }
            }
        }
        
        return localizedValue != key ? localizedValue : defaultValue
    }

    private func applyLanguage(_ languageCode: String, persistSelection: Bool) {
        let resolution = resolveBundle(for: languageCode)

        let applyChanges = {
            if self.bundle.bundlePath != resolution.bundle.bundlePath {
                self.bundle = resolution.bundle
            }

            if self.currentLocale.identifier != resolution.locale.identifier {
                self.currentLocale = resolution.locale
            }

            if persistSelection {
                UserDefaults.standard.set(resolution.code, forKey: "AppLanguage")
                UserDefaults.standard.set(resolution.code, forKey: "LanguageMode")
            }

            NotificationCenter.default.post(name: .languageDidChange, object: nil)
        }

        if resolution.code != languageCode && currentLanguage != resolution.code {
            if Thread.isMainThread {
                self.currentLanguage = resolution.code
            } else {
                DispatchQueue.main.async {
                    self.currentLanguage = resolution.code
                }
            }
            return
        }

        if Thread.isMainThread {
            applyChanges()
        } else {
            DispatchQueue.main.async(execute: applyChanges)
        }
    }

    private func resolveBundle(for languageCode: String) -> (bundle: Bundle, locale: Locale, code: String) {
        if let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return (bundle, Locale(identifier: languageCode), languageCode)
        }

        if let basePath = Bundle.main.path(forResource: "Base", ofType: "lproj"),
           let baseBundle = Bundle(path: basePath) {
            print("⚠️ LocalizationManager: Language \(languageCode) not found, falling back to Base localization")
            return (baseBundle, Locale(identifier: languageCode), languageCode)
        }

        // Fallback to English resources when a matching bundle cannot be located.
        if let fallbackPath = Bundle.main.path(forResource: "en", ofType: "lproj"),
           let fallbackBundle = Bundle(path: fallbackPath) {
            print("⚠️ LocalizationManager: Language \(languageCode) not found, falling back to English")
            return (fallbackBundle, Locale(identifier: "en"), "en")
        }

        print("⚠️ LocalizationManager: Unable to locate localization bundles, using main bundle")
        return (Bundle.main, Locale(identifier: "en"), "en")
    }
}

/// Custom String extension for app-controlled localization
extension String {
    /// Gets localized string using LocalizationManager instead of system locale
    func localized(defaultValue: String? = nil, table: String? = nil) -> String {
        return LocalizationManager.shared.localizedString(
            for: self,
            defaultValue: defaultValue ?? self,
            table: table
        )
    }
}

/// Notification names for language changes
extension Notification.Name {
    static let languageDidChange = Notification.Name("LanguageDidChange")
}
