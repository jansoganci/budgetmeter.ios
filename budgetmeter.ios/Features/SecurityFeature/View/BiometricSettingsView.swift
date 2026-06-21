//
//  BiometricSettingsView.swift
//  BudgetMeter
//
//  Biometric lock settings — v2 glass section layout.
//

import SwiftUI

struct BiometricSettingsView: View {
    @StateObject private var biometricManager = BiometricManager.shared
    @State private var showingAlert = false
    @State private var alertMessage = ""

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: LayoutSpacing.sectionGap) {
                    biometricToggleSection

                    if biometricManager.isBiometricEnabled {
                        statusSection
                    }

                    if !biometricManager.isAvailable {
                        unavailableSection
                    }
                }
                .padding(.horizontal, LayoutSpacing.screenPadding)
                .padding(.vertical, Spacing.md)
            }
        }
        .navigationTitle("security.settings.nav_title".localized(defaultValue: "Security"))
        .navigationBarTitleDisplayMode(.inline)
        .alert("security.settings.alert.title".localized(defaultValue: "Biometric Authentication"), isPresented: $showingAlert) {
            Button("toolbar.ok".localized(defaultValue: "OK")) {
                showingAlert = false
            }
        } message: {
            Text(alertMessage)
        }
    }

    private var biometricToggleSection: some View {
        SettingsSection(
            title: "security.settings.biometric.header".localized(defaultValue: "Security"),
            footer: biometricFooterText
        ) {
            Toggle(isOn: $biometricManager.isBiometricEnabled) {
                SettingsRowContent(
                    iconName: biometricManager.biometricType.iconName,
                    title: "security.settings.biometric.title".localized(defaultValue: "Biometric Authentication"),
                    subtitle: "security.settings.biometric.subtitle".localized(defaultValue: "Protect your financial data with Face ID or Touch ID"),
                    showsChevron: false
                )
            }
            .tint(.accentPrimary)
            .padding(.trailing, Spacing.md)
            .onChange(of: biometricManager.isBiometricEnabled) { _, newValue in
                if newValue {
                    enableBiometric()
                } else {
                    disableBiometric()
                }
            }
        }
    }

    private var statusSection: some View {
        SettingsSection(title: "security.settings.status.header".localized(defaultValue: "Status")) {
            SettingsRowContent(
                iconName: "checkmark.circle.fill",
                title: "security.settings.status.enabled".localized(defaultValue: "Biometric Lock Enabled"),
                subtitle: "security.settings.status.description".localized(defaultValue: "Your financial data is protected"),
                showsChevron: false
            )
        }
    }

    private var unavailableSection: some View {
        SettingsSection(title: "security.settings.unavailable.header".localized(defaultValue: "Why is this unavailable?")) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                SettingsRowContent(
                    iconName: "exclamationmark.triangle.fill",
                    title: "security.settings.unavailable.title".localized(defaultValue: "Not Available"),
                    subtitle: "security.settings.unavailable.message".localized(defaultValue: "Biometric authentication is not available on this device. This could be because:"),
                    showsChevron: false
                )

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("• \("security.settings.unavailable.reason1".localized(defaultValue: "Face ID or Touch ID is not set up"))")
                    Text("• \("security.settings.unavailable.reason2".localized(defaultValue: "Device doesn't support biometric authentication"))")
                    Text("• \("security.settings.unavailable.reason3".localized(defaultValue: "Biometric authentication is disabled in Settings"))")
                }
                .captionStyle(color: .textSecondary)
                .padding(.horizontal, Spacing.md)
                .padding(.bottom, Spacing.sm)
            }
        }
    }

    private var biometricFooterText: String {
        if biometricManager.isAvailable {
            return String(
                format: "security.settings.biometric.footer".localized(
                    defaultValue: "When enabled, you'll need to authenticate with %@ to access your financial data."
                ),
                biometricManager.biometricType.displayName
            )
        }
        return "security.settings.biometric.unavailable".localized(
            defaultValue: "Biometric authentication is not available on this device."
        )
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
    NavigationStack {
        BiometricSettingsView()
    }
}
