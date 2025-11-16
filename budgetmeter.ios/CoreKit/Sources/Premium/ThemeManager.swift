//
//  ThemeManager.swift
//  BudgetMeter
//
//  Created by BudgetMeter Team
//

import Foundation
import SwiftUI
import Combine
import CoreData

/// Manages app-wide theme selection and application
/// Singleton service that persists theme preferences and notifies observers of changes
@MainActor
final class ThemeManager: ObservableObject {

    // MARK: - Singleton
    static let shared = ThemeManager()

    // MARK: - Published Properties

    /// Currently active theme
    @Published private(set) var currentTheme: AppTheme = .default

    // MARK: - Private Properties

    private let persistenceService: PersistenceService
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Notification

    /// Notification posted when theme changes
    static let themeDidChangeNotification = Notification.Name("ThemeDidChange")

    // MARK: - Initialization

    private init(persistenceService: PersistenceService = .shared) {
        self.persistenceService = persistenceService
        loadTheme()
    }

    // MARK: - Public Methods

    /// Apply a new theme
    /// - Parameter theme: The theme to apply
    func applyTheme(_ theme: AppTheme) {
        currentTheme = theme
        saveTheme(theme)
        applyAppIcon(for: theme)
        notifyThemeChange()
    }

    /// Get the accent color for the current theme
    var accentColor: Color {
        return currentTheme.primaryColor
    }

    /// Get the gradient colors for the current theme
    var gradientColors: [Color] {
        return currentTheme.gradientColors
    }

    /// Apply app icon for the selected theme
    /// Note: Requires alternate icons configured in Assets.xcassets and Info.plist
    private func applyAppIcon(for theme: AppTheme) {
        guard UIApplication.shared.supportsAlternateIcons else {
            print("🎨 ThemeManager: ⚠️ Alternate icons not supported")
            return
        }

        let iconName = theme.appIconName

        UIApplication.shared.setAlternateIconName(iconName) { error in
            if let error = error {
                print("🎨 ThemeManager: ❌ Failed to set app icon: \(error.localizedDescription)")
            } else {
                let displayName = iconName ?? "Default"
                print("🎨 ThemeManager: ✅ App icon set to: \(displayName)")
            }
        }
    }

    // MARK: - Private Methods

    /// Load theme from Core Data
    private func loadTheme() {
        let context = persistenceService.viewContext
        let fetchRequest: NSFetchRequest<AppSettings> = AppSettings.fetchRequest()

        do {
            let settings = try context.fetch(fetchRequest)
            if let appSettings = settings.first,
               let themeString = appSettings.selectedTheme,
               let theme = AppTheme(rawValue: themeString) {
                currentTheme = theme
            } else {
                // Default theme if none saved
                currentTheme = .default
            }
        } catch {
            print("🎨 ThemeManager: ❌ Failed to load theme: \(error)")
            currentTheme = .default
        }
    }

    /// Save theme to Core Data
    private func saveTheme(_ theme: AppTheme) {
        persistenceService.performBackgroundTask { context in
            let fetchRequest: NSFetchRequest<AppSettings> = AppSettings.fetchRequest()

            do {
                let settings = try context.fetch(fetchRequest)
                let appSettings: AppSettings

                if let existingSettings = settings.first {
                    appSettings = existingSettings
                } else {
                    appSettings = AppSettings(context: context)
                }

                appSettings.selectedTheme = theme.rawValue

                // Save is automatically handled by performBackgroundTask
                print("🎨 ThemeManager: ✅ Theme saved: \(theme.rawValue)")

            } catch {
                print("🎨 ThemeManager: ❌ Failed to save theme: \(error)")
            }
        }
    }

    /// Notify observers that theme changed
    private func notifyThemeChange() {
        NotificationCenter.default.post(
            name: ThemeManager.themeDidChangeNotification,
            object: nil,
            userInfo: ["theme": currentTheme.rawValue]
        )
    }
}

// MARK: - App Theme Definition

enum AppTheme: String, CaseIterable {
    case `default` = "default"
    case ocean = "ocean"
    case forest = "forest"
    case sunset = "sunset"
    case purple = "purple"
    case midnight = "midnight"

    /// Display name for the theme
    var displayName: String {
        switch self {
        case .default: return "Default"
        case .ocean: return "Ocean"
        case .forest: return "Forest"
        case .sunset: return "Sunset"
        case .purple: return "Purple"
        case .midnight: return "Midnight"
        }
    }

    /// Primary color for the theme
    var primaryColor: Color {
        switch self {
        case .default: return .blue
        case .ocean: return .cyan
        case .forest: return .green
        case .sunset: return .orange
        case .purple: return .purple
        case .midnight: return .indigo
        }
    }

    /// Secondary color for the theme
    var secondaryColor: Color {
        switch self {
        case .default: return Color.blue.opacity(0.7)
        case .ocean: return Color.cyan.opacity(0.7)
        case .forest: return Color.green.opacity(0.7)
        case .sunset: return Color.orange.opacity(0.7)
        case .purple: return Color.purple.opacity(0.7)
        case .midnight: return Color.indigo.opacity(0.7)
        }
    }

    /// Gradient colors for the theme
    var gradientColors: [Color] {
        switch self {
        case .default:
            return [Color.blue, Color.blue.opacity(0.6)]
        case .ocean:
            return [Color.cyan, Color.blue]
        case .forest:
            return [Color.green, Color.mint]
        case .sunset:
            return [Color.orange, Color.pink]
        case .purple:
            return [Color.purple, Color.pink]
        case .midnight:
            return [Color.indigo, Color.purple]
        }
    }

    /// SF Symbol icon for the theme
    var icon: String {
        switch self {
        case .default: return "paintbrush"
        case .ocean: return "drop.fill"
        case .forest: return "leaf.fill"
        case .sunset: return "sun.max.fill"
        case .purple: return "sparkles"
        case .midnight: return "moon.stars.fill"
        }
    }

    /// App icon name for alternate icon switching
    /// Returns nil for default theme (uses primary app icon)
    /// To enable: Add alternate icon sets to Assets.xcassets and configure Info.plist
    var appIconName: String? {
        switch self {
        case .default: return nil // Primary icon
        case .ocean: return "AppIcon-Ocean"
        case .forest: return "AppIcon-Forest"
        case .sunset: return "AppIcon-Sunset"
        case .purple: return "AppIcon-Purple"
        case .midnight: return "AppIcon-Midnight"
        }
    }

    /// Get all themes as an array
    static var allThemes: [AppTheme] {
        return AppTheme.allCases
    }
}

// MARK: - SwiftUI Environment Key

struct ThemeKey: EnvironmentKey {
    static let defaultValue: AppTheme = .default
}

extension EnvironmentValues {
    var appTheme: AppTheme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

// MARK: - View Extension for Theme Access

extension View {
    /// Apply the current app theme as the accent color
    func themedAccent() -> some View {
        self.accentColor(ThemeManager.shared.accentColor)
    }
}
