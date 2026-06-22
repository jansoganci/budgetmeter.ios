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
    @Published private(set) var currentTheme: AppTheme = .coral_default

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
    func applyTheme(_ theme: AppTheme, shouldSyncToAccount: Bool = true) {
        guard !theme.requiresPremium || PremiumManager.shared.hasAccess(to: BudgetMeterCapability.premiumThemes) else {
            print("🎨 ThemeManager: ⭐ Premium required for theme: \(theme.rawValue)")
            return
        }

        currentTheme = theme
        saveTheme(theme)
        applyAppIcon(for: theme)
        notifyThemeChange()

        if shouldSyncToAccount {
            Task {
                await SupabaseAccountDataService.shared.pushSelectedTheme(theme.rawValue)
            }
        }
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

    /// Load theme from Core Data and migrate legacy IDs to v2
    private func loadTheme() {
        let context = persistenceService.viewContext
        let fetchRequest: NSFetchRequest<AppSettings> = AppSettings.fetchRequest()

        do {
            let settings = try context.fetch(fetchRequest)
            if let appSettings = settings.first,
               let themeString = appSettings.selectedTheme {
                let theme = AppTheme.resolved(from: themeString)
                currentTheme = theme

                if themeString != theme.rawValue {
                    saveTheme(theme)
                    print("🎨 ThemeManager: ✅ Migrated theme \(themeString) -> \(theme.rawValue)")
                }
            } else {
                currentTheme = .coral_default
            }
        } catch {
            print("🎨 ThemeManager: ❌ Failed to load theme: \(error)")
            currentTheme = .coral_default
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

// MARK: - App Theme Definition (v2)

enum AppTheme: String, CaseIterable {
    case coral_default = "coral_default"
    case google_blue = "google_blue"
    case fresh_green = "fresh_green"
    case mint_green = "mint_green"
    case google_yellow = "google_yellow"
    case google_red = "google_red"
    case purple = "purple"
    case sky_cyan = "sky_cyan"
    case orange = "orange"

    /// Resolves a persisted or legacy theme ID to a v2 preset
    static func resolved(from rawValue: String) -> AppTheme {
        if let theme = AppTheme(rawValue: rawValue) {
            return theme
        }

        switch rawValue {
        case "default":
            return .coral_default
        case "ocean":
            return .google_blue
        case "forest":
            return .mint_green
        case "sunset":
            return .orange
        case "midnight":
            return .sky_cyan
        default:
            return .coral_default
        }
    }

    /// Display name for the theme
    var displayName: String {
        switch self {
        case .coral_default:
            return "theme.name.coral_default".localized(defaultValue: "Coral Default")
        case .google_blue:
            return "theme.name.google_blue".localized(defaultValue: "Google Blue")
        case .fresh_green:
            return "theme.name.fresh_green".localized(defaultValue: "Fresh Green")
        case .mint_green:
            return "theme.name.mint_green".localized(defaultValue: "Mint Green")
        case .google_yellow:
            return "theme.name.google_yellow".localized(defaultValue: "Google Yellow")
        case .google_red:
            return "theme.name.google_red".localized(defaultValue: "Google Red")
        case .purple:
            return "theme.name.purple".localized(defaultValue: "Purple")
        case .sky_cyan:
            return "theme.name.sky_cyan".localized(defaultValue: "Sky Cyan")
        case .orange:
            return "theme.name.orange".localized(defaultValue: "Orange")
        }
    }

    var requiresPremium: Bool {
        self != .coral_default
    }

    /// v2 accent hex — accent layer only
    var accentHex: String {
        switch self {
        case .coral_default: return "FF5A5F"
        case .google_blue: return "4285F4"
        case .fresh_green: return "00C853"
        case .mint_green: return "00BFA5"
        case .google_yellow: return "FBBC04"
        case .google_red: return "EA4335"
        case .purple: return "A142F4"
        case .sky_cyan: return "24C6DC"
        case .orange: return "FF8A00"
        }
    }

    /// Primary accent color for the theme
    var primaryColor: Color {
        Color(hex: accentHex)
    }

    /// Secondary accent tint
    var secondaryColor: Color {
        primaryColor.opacity(0.72)
    }

    /// Accent gradient for previews and highlights
    var gradientColors: [Color] {
        [primaryColor, primaryColor.opacity(0.75)]
    }

    /// SF Symbol icon for the theme
    var icon: String {
        switch self {
        case .coral_default: return "paintbrush.fill"
        case .google_blue: return "drop.fill"
        case .fresh_green: return "leaf.fill"
        case .mint_green: return "leaf.circle.fill"
        case .google_yellow: return "sun.max.fill"
        case .google_red: return "flame.fill"
        case .purple: return "sparkles"
        case .sky_cyan: return "wind"
        case .orange: return "sun.horizon.fill"
        }
    }

    /// App icon name for alternate icon switching
    /// Returns nil for default theme (uses primary app icon)
    var appIconName: String? {
        switch self {
        case .coral_default: return nil
        case .google_blue: return "AppIcon-Ocean"
        case .mint_green: return "AppIcon-Forest"
        case .orange: return "AppIcon-Sunset"
        case .purple: return "AppIcon-Purple"
        case .sky_cyan: return "AppIcon-Midnight"
        case .fresh_green, .google_yellow, .google_red: return nil
        }
    }

    /// All v2 theme presets in display order
    static var allThemes: [AppTheme] {
        AppTheme.allCases
    }
}

// MARK: - SwiftUI Environment Key

struct ThemeKey: EnvironmentKey {
    static let defaultValue: AppTheme = .coral_default
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
