//
//  BiometricManager.swift
//  BudgetMeter
//
//  Created by BudgetMeter Team on 17.09.2025.
//

import Foundation
import SwiftUI
import LocalAuthentication
import CoreData

/// Manages biometric authentication for securing financial data
@MainActor
final class BiometricManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = BiometricManager()
    
    // MARK: - Published Properties
    
    @Published var isBiometricEnabled: Bool = false
    @Published var isAuthenticated: Bool = false
    @Published var biometricType: BiometricType = .none
    @Published var errorMessage: String?
    @Published var isAvailable: Bool = false
    @Published private(set) var lastAuthenticationWasCancelled: Bool = false
    
    // MARK: - Private Properties
    
    private let persistenceService: PersistenceService
    private let userDefaults: UserDefaults
    private static let biometricEnabledKey = "biometric.lock.enabled"
    
    // MARK: - Initialization
    
    private init(
        persistenceService: PersistenceService = .shared,
        userDefaults: UserDefaults = .standard
    ) {
        self.persistenceService = persistenceService
        self.userDefaults = userDefaults
        checkBiometricAvailability()
        loadBiometricSettings()
    }
    
    // MARK: - Public Methods
    
    /// Checks if biometric authentication is available on the device
    func checkBiometricAvailability() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            isAvailable = true
            
            switch context.biometryType {
            case .faceID:
                biometricType = .faceID
            case .touchID:
                biometricType = .touchID
            case .opticID:
                biometricType = .opticID
            default:
                biometricType = .none
            }
        } else {
            isAvailable = false
            biometricType = .none
            errorMessage = error?.localizedDescription
        }
    }
    
    /// Enables biometric authentication
    func enableBiometric() async -> Bool {
        guard PremiumManager.shared.hasAccess(to: BudgetMeterCapability.biometricLock) else {
            await MainActor.run {
                errorMessage = "security.error.premium_required".localized(defaultValue: "Biometric lock requires BudgetMeter Premium.")
            }
            return false
        }

        guard isAvailable else {
            await MainActor.run {
                errorMessage = "biometric.error.not_available_device".localized(defaultValue: "Biometric authentication is not available on this device")
            }
            return false
        }
        
        let success = await authenticate(
            reason: "biometric.enable.reason".localized(defaultValue: "Enable biometric authentication to secure your financial data"),
            policy: .deviceOwnerAuthenticationWithBiometrics,
            requiresBiometricLockEnabled: false
        )
        
        if success {
            await MainActor.run {
                isBiometricEnabled = true
                isAuthenticated = true
            }
            if !saveBiometricSettings() {
                await MainActor.run {
                    isBiometricEnabled = false
                    isAuthenticated = false
                    errorMessage = "security.settings.enable.error".localized(defaultValue: "Failed to enable biometric authentication")
                }
                return false
            }
        }
        
        return success
    }
    
    /// Disables biometric authentication
    func disableBiometric() {
        isBiometricEnabled = false
        isAuthenticated = false
        if !saveBiometricSettings() {
            print("BiometricManager: Failed to persist biometric disable state")
            errorMessage = "security.settings.enable.error".localized(defaultValue: "Failed to enable biometric authentication")
        }
    }
    
    /// Authenticates the user using biometrics
    func authenticateUser(reason: String = "biometric.auth.reason".localized(defaultValue: "Authenticate to access your financial data")) async -> Bool {
        await authenticate(
            reason: reason,
            policy: .deviceOwnerAuthenticationWithBiometrics,
            requiresBiometricLockEnabled: true
        )
    }
    
    /// Authenticates using device passcode as a fallback when biometrics fail or are unavailable
    func authenticateWithPasscode(reason: String = "biometric.auth.passcode.reason".localized(defaultValue: "Use your passcode to access your financial data")) async -> Bool {
        await authenticate(
            reason: reason,
            policy: .deviceOwnerAuthentication,
            requiresBiometricLockEnabled: true
        )
    }
    
    private func authenticate(
        reason: String,
        policy: LAPolicy,
        requiresBiometricLockEnabled: Bool
    ) async -> Bool {
        if requiresBiometricLockEnabled {
            guard isBiometricEnabled else {
                await MainActor.run {
                    errorMessage = "biometric.error.not_enabled".localized(defaultValue: "Biometric authentication is not enabled")
                    lastAuthenticationWasCancelled = false
                }
                return false
            }
        }
        
        if policy == .deviceOwnerAuthenticationWithBiometrics {
            guard isAvailable else {
                await MainActor.run {
                    errorMessage = "biometric.error.not_available_device".localized(defaultValue: "Biometric authentication is not available on this device")
                    lastAuthenticationWasCancelled = false
                }
                return false
            }
        } else {
            let context = LAContext()
            guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil) else {
                await MainActor.run {
                    errorMessage = "biometric.error.passcode_not_set".localized(defaultValue: "Passcode is not set. Please set up a passcode in Settings")
                    lastAuthenticationWasCancelled = false
                }
                return false
            }
        }
        
        let context = LAContext()
        
        do {
            let success = try await context.evaluatePolicy(policy, localizedReason: reason)
            
            await MainActor.run {
                isAuthenticated = success
                lastAuthenticationWasCancelled = false
                if !success {
                    errorMessage = "biometric.error.auth_failed".localized(defaultValue: "Authentication failed")
                } else {
                    errorMessage = nil
                }
            }
            
            return success
        } catch {
            let wasCancelled = (error as? LAError)?.code == .userCancel
                || (error as? LAError)?.code == .appCancel
                || (error as? LAError)?.code == .systemCancel
            
            await MainActor.run {
                isAuthenticated = false
                lastAuthenticationWasCancelled = wasCancelled
                if wasCancelled {
                    errorMessage = BiometricError.userCancel.errorDescription
                } else if let laError = error as? LAError, laError.code == .authenticationFailed {
                    errorMessage = BiometricError.authenticationFailed.errorDescription
                } else {
                    errorMessage = error.localizedDescription
                }
            }
            return false
        }
    }
    
    /// Checks if the app should require authentication
    func shouldRequireAuthentication() -> Bool {
        return isBiometricEnabled && !isAuthenticated
    }

    /// Reloads the persisted biometric enabled state from local storage.
    func refreshBiometricSettingsFromStore() {
        loadBiometricSettings()
    }
    
    /// Resets authentication state (call when app goes to background)
    func resetAuthentication() {
        isAuthenticated = false
    }
    
    // MARK: - Private Methods
    
    private func loadBiometricSettings() {
        let context = persistenceService.viewContext
        let fetchRequest: NSFetchRequest<AppSettings> = AppSettings.fetchRequest()
        
        do {
            let settings = try context.fetch(fetchRequest)
            let hasDefaultsValue = userDefaults.object(forKey: Self.biometricEnabledKey) != nil
            let defaultsValue = userDefaults.bool(forKey: Self.biometricEnabledKey)
            let coreDataValue = settings.contains(where: { $0.isBiometricEnabled })

            // Use a resilient value in case startup ordering or duplicate rows produce a stale false.
            let resolvedValue = coreDataValue || (hasDefaultsValue && defaultsValue)
            isBiometricEnabled = resolvedValue

            if coreDataValue != resolvedValue {
                for appSettings in settings {
                    appSettings.isBiometricEnabled = resolvedValue
                }
                let didSave = persistenceService.save()
                if !didSave {
                    print("BiometricManager: Failed to heal Core Data biometric state from local preference")
                }
            }

            userDefaults.set(resolvedValue, forKey: Self.biometricEnabledKey)
        } catch {
            print("Failed to load biometric settings: \(error)")
            if userDefaults.object(forKey: Self.biometricEnabledKey) != nil {
                isBiometricEnabled = userDefaults.bool(forKey: Self.biometricEnabledKey)
            } else {
                isBiometricEnabled = false
            }
        }
    }
    
    @discardableResult
    private func saveBiometricSettings() -> Bool {
        let context = persistenceService.viewContext
        let fetchRequest: NSFetchRequest<AppSettings> = AppSettings.fetchRequest()
        
        do {
            let settings = try context.fetch(fetchRequest)

            if settings.isEmpty {
                let appSettings = AppSettings(context: context)
                appSettings.isBiometricEnabled = isBiometricEnabled
            } else {
                for appSettings in settings {
                    appSettings.isBiometricEnabled = isBiometricEnabled
                }
            }

            let saved = persistenceService.save()
            if !saved {
                print("BiometricManager: Failed to persist biometric settings")
                return false
            }
            userDefaults.set(isBiometricEnabled, forKey: Self.biometricEnabledKey)
            userDefaults.synchronize()
            return saved
        } catch {
            print("Failed to save biometric settings: \(error)")
            return false
        }
    }
}

// MARK: - Supporting Types

enum BiometricType {
    case none
    case faceID
    case touchID
    case opticID
    
    var displayName: String {
        switch self {
        case .none:
            return "biometric.type.none".localized(defaultValue: "None")
        case .faceID:
            return "biometric.type.face_id".localized(defaultValue: "Face ID")
        case .touchID:
            return "biometric.type.touch_id".localized(defaultValue: "Touch ID")
        case .opticID:
            return "biometric.type.optic_id".localized(defaultValue: "Optic ID")
        }
    }
    
    var iconName: String {
        switch self {
        case .none:
            return "lock"
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        case .opticID:
            return "opticid"
        }
    }
}

// MARK: - Biometric Authentication Error

enum BiometricError: Error {
    case notAvailable
    case notEnrolled
    case lockedOut
    case authenticationFailed
    case userCancel
    case systemCancel
    case passcodeNotSet
    case biometryNotAvailable
}

extension BiometricError {
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "biometric.error.not_available_device".localized(defaultValue: "Biometric authentication is not available on this device")
        case .notEnrolled:
            return "biometric.error.not_enrolled".localized(defaultValue: "No biometric data is enrolled. Please set up Face ID or Touch ID in Settings")
        case .lockedOut:
            return "biometric.error.locked_out".localized(defaultValue: "Biometric authentication is locked out. Please use your passcode")
        case .authenticationFailed:
            return "biometric.error.auth_failed_retry".localized(defaultValue: "Authentication failed. Please try again")
        case .userCancel:
            return "biometric.error.user_cancel".localized(defaultValue: "Authentication was cancelled by the user")
        case .systemCancel:
            return "biometric.error.system_cancel".localized(defaultValue: "Authentication was cancelled by the system")
        case .passcodeNotSet:
            return "biometric.error.passcode_not_set".localized(defaultValue: "Passcode is not set. Please set up a passcode in Settings")
        case .biometryNotAvailable:
            return "biometric.error.not_available".localized(defaultValue: "Biometric authentication is not available")
        }
    }
}
