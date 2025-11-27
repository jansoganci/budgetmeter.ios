//
//  BiometricSettingsView.swift
//  BudgetMeter
//
//  Created by BudgetMeter Team on 17.09.2025.
//

import SwiftUI

struct BiometricSettingsView: View {
    @StateObject private var biometricManager = BiometricManager.shared
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    // DEBUG: For testing biometric features
    #if DEBUG
    @State private var debugMode = true
    #endif
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Toggle(isOn: $biometricManager.isBiometricEnabled) {
                        HStack(spacing: 12) {
                            Image(systemName: biometricManager.biometricType.iconName)
                                .font(.title2)
                                .foregroundColor(.accentColor)
                                .frame(width: 30)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("security.settings.biometric.title".localized(defaultValue: "Biometric Authentication"))
                                    .font(.body)
                                    .foregroundColor(.primary)
                                Text("security.settings.biometric.subtitle".localized(defaultValue: "Protect your financial data with Face ID or Touch ID"))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .onChange(of: biometricManager.isBiometricEnabled) { newValue in
                        if newValue {
                            enableBiometric()
                        } else {
                            disableBiometric()
                        }
                    }
                } header: {
                    Text("security.settings.biometric.header".localized(defaultValue: "Security"))
                } footer: {
                    if biometricManager.isAvailable {
                        Text("security.settings.biometric.footer".localized(defaultValue: "When enabled, you'll need to authenticate with \(biometricManager.biometricType.displayName) to access your financial data."))
                    } else {
                        Text("security.settings.biometric.unavailable".localized(defaultValue: "Biometric authentication is not available on this device."))
                            .foregroundColor(.red)
                    }
                }
                
                if biometricManager.isBiometricEnabled {
                    Section {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .frame(width: 30)
                            
                            VStack(alignment: .leading) {
                                Text("security.settings.status.enabled".localized(defaultValue: "Biometric Lock Enabled"))
                                    .font(.headline)
                                Text("security.settings.status.description".localized(defaultValue: "Your financial data is protected"))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 5)
                    } header: {
                        Text("security.settings.status.header".localized(defaultValue: "Status"))
                    }
                }
                
                if !biometricManager.isAvailable {
                    Section {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text("security.settings.unavailable.title".localized(defaultValue: "Not Available"))
                                    .font(.headline)
                            }
                            
                            Text("security.settings.unavailable.message".localized(defaultValue: "Biometric authentication is not available on this device. This could be because:"))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            VStack(alignment: .leading, spacing: 5) {
                                Text("• \("security.settings.unavailable.reason1".localized(defaultValue: "Face ID or Touch ID is not set up"))")
                                Text("• \("security.settings.unavailable.reason2".localized(defaultValue: "Device doesn't support biometric authentication"))")
                                Text("• \("security.settings.unavailable.reason3".localized(defaultValue: "Biometric authentication is disabled in Settings"))")
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 5)
                    } header: {
                        Text("security.settings.unavailable.header".localized(defaultValue: "Why is this unavailable?"))
                    }
                }
            }
            .navigationTitle("security.settings.nav_title".localized(defaultValue: "Security"))
            .navigationBarTitleDisplayMode(.large)
            .alert("security.settings.alert.title".localized(defaultValue: "Biometric Authentication"), isPresented: $showingAlert) {
                Button("toolbar.ok".localized(defaultValue: "OK")) {
                    showingAlert = false
                }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func enableBiometric() {
        Task {
            let success = await biometricManager.enableBiometric()
            
            await MainActor.run {
                if !success {
                    biometricManager.isBiometricEnabled = false
                    alertMessage = biometricManager.errorMessage ?? "security.settings.enable.error".localized(defaultValue: "Failed to enable biometric authentication")
                    showingAlert = true
                }
            }
        }
    }
    
    private func disableBiometric() {
        biometricManager.disableBiometric()
    }
}

#Preview {
    BiometricSettingsView()
}
