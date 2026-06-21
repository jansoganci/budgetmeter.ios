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
    
    // MARK: - Private Properties
    
    private let persistenceService: PersistenceService
    private let context = LAContext()
    
    // MARK: - Initialization
    
    private init(persistenceService: PersistenceService = .shared) {
        self.persistenceService = persistenceService
        checkBiometricAvailability()
        loadBiometricSettings()
    }
    
    // MARK: - Public Methods
    
    /// Checks if biometric authentication is available on the device
    func checkBiometricAvailability() {
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
        
        let success = await authenticateUser(reason: "biometric.enable.reason".localized(defaultValue: "Enable biometric authentication to secure your financial data"))
        
        if success {
            await MainActor.run {
                isBiometricEnabled = true
                isAuthenticated = true
            }
            saveBiometricSettings()
        }
        
        return success
    }
    
    /// Disables biometric authentication
    func disableBiometric() {
        isBiometricEnabled = false
        isAuthenticated = false
        saveBiometricSettings()
    }
    
    /// Authenticates the user using biometrics
    func authenticateUser(reason: String = "biometric.auth.reason".localized(defaultValue: "Authenticate to access your financial data")) async -> Bool {
        guard isAvailable && isBiometricEnabled else {
            await MainActor.run {
                errorMessage = "biometric.error.not_enabled".localized(defaultValue: "Biometric authentication is not enabled")
            }
            return false
        }
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            
            await MainActor.run {
                isAuthenticated = success
                if !success {
                    errorMessage = "biometric.error.auth_failed".localized(defaultValue: "Authentication failed")
                }
            }
            
            return success
        } catch {
            await MainActor.run {
                isAuthenticated = false
                errorMessage = error.localizedDescription
            }
            return false
        }
    }
    
    /// Checks if the app should require authentication
    func shouldRequireAuthentication() -> Bool {
        return isBiometricEnabled && !isAuthenticated
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
            if let appSettings = settings.first {
                isBiometricEnabled = appSettings.isBiometricEnabled
            }
        } catch {
            print("Failed to load biometric settings: \(error)")
        }
    }
    
    private func saveBiometricSettings() {
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
            
            appSettings.isBiometricEnabled = isBiometricEnabled
            
            persistenceService.save()
        } catch {
            print("Failed to save biometric settings: \(error)")
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
