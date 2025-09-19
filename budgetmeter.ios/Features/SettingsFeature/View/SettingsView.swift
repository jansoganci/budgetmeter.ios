//
//  SettingsView.swift
//  BudgetMeter
//
//  Created by BudgetMeter Team on 17.09.2025.
//

import SwiftUI

/// Settings screen following HIG and Design Rulebook specifications
struct SettingsView: View {
    
    @StateObject private var viewModel = SettingsViewModel()
    
    var body: some View {
        NavigationView {
            List {
                // Appearance Section
                appearanceSection
                
                // Language & Region Section
                languageSection

                // Currency Section
                currencySection
                
                // Data & Privacy Section
                dataPrivacySection
                
                // About Section
                aboutSection
            }
            .navigationTitle("settings.title".localized(defaultValue: "Settings"))
            .navigationBarTitleDisplayMode(.large)
        }
        .preferredColorScheme(viewModel.selectedAppearance.systemColorScheme)
        .sheet(isPresented: $viewModel.isCurrencyPickerPresented) {
            CurrencyPickerView(
                featuredCurrencies: viewModel.featuredCurrencies,
                otherCurrencies: viewModel.otherCurrencies,
                selectedCurrencyCode: viewModel.selectedCurrencyCode,
                onSelect: { currency in
                    viewModel.selectCurrency(currency)
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $viewModel.isLanguagePickerPresented) {
            LanguagePickerView(
                languages: SettingsViewModel.LanguageMode.allCases,
                selectedLanguage: viewModel.selectedLanguage,
                onSelect: { language in
                    viewModel.selectLanguage(language)
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $viewModel.showingPrivacyPolicy) {
            privacyPolicyView
        }
        .sheet(isPresented: $viewModel.showingTermsOfService) {
            termsOfServiceView
        }
        .sheet(isPresented: $viewModel.showingDataExportSheet) {
            dataExportView
        }
        .alert(
            "settings.reset.cumulative.title".localized(defaultValue: "Reset Long-Term Meter"),
            isPresented: $viewModel.showingResetCumulativeAlert
        ) {
            Button("settings.reset.cancel".localized(defaultValue: "Cancel"), role: .cancel) { }
            Button("settings.reset.confirm".localized(defaultValue: "Reset"), role: .destructive) {
                viewModel.resetCumulativeMeter()
            }
        } message: {
            Text("settings.reset.cumulative.message".localized(defaultValue: "This will reset your long-term financial meter to zero. Your income and expense data will remain unchanged."))
        }
        .alert("settings.reset.title".localized(defaultValue: "Reset All Data"), isPresented: $viewModel.showingResetDataAlert) {
            Button("settings.reset.cancel".localized(defaultValue: "Cancel"), role: .cancel) { }
            Button("settings.reset.confirm".localized(defaultValue: "Reset"), role: .destructive) {
                viewModel.resetAllData()
            }
        } message: {
            Text("settings.reset.all.warning".localized(defaultValue: "This will permanently delete all your financial data. This action cannot be undone."))
        }
    }
    
    // MARK: - Appearance Section
    
    private var appearanceSection: some View {
        Section {
            ForEach(SettingsViewModel.AppearanceMode.allCases, id: \.self) { mode in
                HStack {
                    Image(systemName: iconForAppearanceMode(mode))
                        .foregroundColor(Color(hex: "4A90E2"))
                        .frame(width: 24)
                    
                    Text(mode.displayName)
                        .font(.body)
                    
                    Spacer()
                    
                    if viewModel.selectedAppearance == mode {
                        Image(systemName: "checkmark")
                            .foregroundColor(Color(hex: "4A90E2"))
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    viewModel.updateAppearance(mode)
                }
            }
        } header: {
            Text("settings.appearance.title".localized(defaultValue: "Appearance"))
        } footer: {
            Text("settings.appearance.footer".localized(defaultValue: "Choose how the app looks on your device."))
        }
    }
    
    // MARK: - Language Section
    
    private var languageSection: some View {
        Section {
            Button {
                viewModel.showLanguagePicker()
            } label: {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("settings.language.title".localized(defaultValue: "Language"))
                            .font(.body)
                            .foregroundColor(.primary)
                        Text(viewModel.selectedLanguageDisplayText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.system(size: 14, weight: .medium))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("settings.language.title".localized(defaultValue: "Language"))
            .accessibilityValue(viewModel.selectedLanguageDisplayText)
        } footer: {
            Text("settings.language.footer".localized(defaultValue: "Change the app's display language. This setting is independent of your device's system language."))
        }
    }

    // MARK: - Currency Section

    private var currencySection: some View {
        Section {
            Button {
                viewModel.showCurrencyPicker()
            } label: {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("settings.currency.row.label".localized(defaultValue: "Currency"))
                            .font(.body)
                            .foregroundColor(.primary)
                        Text(viewModel.selectedCurrencyDisplayText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.system(size: 14, weight: .medium))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("settings.currency.row.accessibility_label".localized(defaultValue: "Currency"))
            .accessibilityValue(viewModel.selectedCurrencyDisplayText)
        } header: {
            Text("settings.currency.title".localized(defaultValue: "Currency"))
        } footer: {
            Text("settings.currency.footer".localized(defaultValue: "Select your preferred currency for displaying amounts."))
        }
    }
    
    // MARK: - Data & Privacy Section
    
    private var dataPrivacySection: some View {
        Section {
            // Export Data
            Button(action: viewModel.exportData) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(Color(hex: "4A90E2"))
                        .frame(width: 24)
                    
                    Text("settings.export.title".localized(defaultValue: "Export Data"))
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.system(size: 14, weight: .medium))
                }
            }

            // Reset Long-Term Meter
            Button(action: viewModel.showResetCumulativeConfirmation) {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                        .foregroundColor(Color(hex: "4A90E2"))
                        .frame(width: 24)

                    Text("settings.reset.cumulative.title".localized(defaultValue: "Reset Long-Term Meter"))
                        .font(.body)
                        .foregroundColor(.primary)

                    Spacer()
                }
            }

            // Reset Data
            Button(action: viewModel.showResetDataConfirmation) {
                HStack {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .frame(width: 24)
                    
                    Text("settings.reset.title".localized(defaultValue: "Reset All Data"))
                        .font(.body)
                        .foregroundColor(.red)
                    
                    Spacer()
                }
            }
            
            // Privacy Policy
            Button(action: viewModel.showPrivacyPolicy) {
                HStack {
                    Image(systemName: "hand.raised")
                        .foregroundColor(Color(hex: "4A90E2"))
                        .frame(width: 24)
                    
                    Text("settings.privacy.title".localized(defaultValue: "Privacy Policy"))
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.system(size: 14, weight: .medium))
                }
            }
        } header: {
            Text("settings.data.title".localized(defaultValue: "Data & Privacy"))
        }
    }
    
    // MARK: - About Section
    
    private var aboutSection: some View {
        Section {
            // App Version
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(Color(hex: "4A90E2"))
                    .frame(width: 24)
                
                Text("settings.version.title".localized(defaultValue: "Version"))
                    .font(.body)
                
                Spacer()
                
                Text(viewModel.appVersion)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            // Terms of Service
            Button(action: viewModel.showTermsOfService) {
                HStack {
                    Image(systemName: "doc.text")
                        .foregroundColor(Color(hex: "4A90E2"))
                        .frame(width: 24)
                    
                    Text("settings.terms.title".localized(defaultValue: "Terms of Service"))
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.system(size: 14, weight: .medium))
                }
            }
            
            // Contact Support
            Button(action: {}) {
                HStack {
                    Image(systemName: "envelope")
                        .foregroundColor(Color(hex: "4A90E2"))
                        .frame(width: 24)
                    
                    Text("settings.contact.title".localized(defaultValue: "Contact Support"))
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.system(size: 14, weight: .medium))
                }
            }
        } header: {
            Text("settings.about.title".localized(defaultValue: "About"))
        }
    }
    
    // MARK: - Sheet Views
    
    private var privacyPolicyView: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("settings.privacy.sheet.title".localized(defaultValue: "Privacy Policy"))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.bottom, 8)
                    
                    Text("settings.privacy.sheet.intro".localized(defaultValue: "Your privacy is important to us. Here's how we handle your data:"))
                        .font(.body)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("settings.privacy.sheet.bullet.local".localized(defaultValue: "• All data is stored locally on your device"))
                        Text("settings.privacy.sheet.bullet.icloud".localized(defaultValue: "• Optional iCloud sync for your convenience"))
                        Text("settings.privacy.sheet.bullet.personal".localized(defaultValue: "• No personal information is collected"))
                        Text("settings.privacy.sheet.bullet.analytics".localized(defaultValue: "• No analytics or tracking"))
                        Text("settings.privacy.sheet.bullet.share".localized(defaultValue: "• We never share your data with third parties"))
                    }
                    .font(.body)
                    .padding(.leading, 8)
                    
                    Spacer()
                }
                .padding(16)
            }
            .navigationTitle("settings.privacy.sheet.nav_title".localized(defaultValue: "Privacy Policy"))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("toolbar.done".localized(defaultValue: "Done")) {
                        viewModel.showingPrivacyPolicy = false
                    }
                }
            }
        }
    }

    private var termsOfServiceView: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("settings.terms.sheet.title".localized(defaultValue: "Terms of Service"))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.bottom, 8)
                    
                    Text("settings.terms.sheet.intro".localized(defaultValue: "By using BudgetMeter, you agree to these terms:"))
                        .font(.body)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("settings.terms.sheet.bullet.warranty".localized(defaultValue: "• The app is provided as-is without warranty"))
                        Text("settings.terms.sheet.bullet.risk".localized(defaultValue: "• You use the app at your own risk"))
                        Text("settings.terms.sheet.bullet.liability".localized(defaultValue: "• We are not liable for any financial decisions"))
                        Text("settings.terms.sheet.bullet.update".localized(defaultValue: "• Terms may be updated with app updates"))
                    }
                    .font(.body)
                    .padding(.leading, 8)
                    
                    Spacer()
                }
                .padding(16)
            }
            .navigationTitle("settings.terms.sheet.nav_title".localized(defaultValue: "Terms of Service"))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("toolbar.done".localized(defaultValue: "Done")) {
                        viewModel.showingTermsOfService = false
                    }
                }
            }
        }
    }

    private var dataExportView: some View {
        NavigationView {
            VStack(spacing: 24) {
                Image(systemName: "square.and.arrow.up.circle")
                    .font(.system(size: 64))
                    .foregroundColor(Color(hex: "4A90E2"))
                
                Text("settings.export.sheet.title".localized(defaultValue: "Export Your Data"))
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("settings.export.sheet.body".localized(defaultValue: "Export all your financial data as a CSV file for backup or analysis."))
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                Button("settings.export.sheet.button.export".localized(defaultValue: "Export CSV")) {
                    // TODO: Implement CSV export
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(hex: "4A90E2"))
                
                Spacer()
            }
            .padding(16)
            .navigationTitle("settings.export.sheet.nav_title".localized(defaultValue: "Export Data"))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("toolbar.done".localized(defaultValue: "Done")) {
                        viewModel.showingDataExportSheet = false
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func iconForAppearanceMode(_ mode: SettingsViewModel.AppearanceMode) -> String {
        switch mode {
        case .light: return "sun.max"
        case .dark: return "moon"
        case .system: return "circle.lefthalf.filled"
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
}
