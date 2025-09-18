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
                
                // Data & Privacy Section
                dataPrivacySection
                
                // About Section
                aboutSection
            }
            .navigationTitle(String(localized: "settings.title"))
            .navigationBarTitleDisplayMode(.large)
        }
        .preferredColorScheme(viewModel.selectedAppearance.systemColorScheme)
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
            String(localized: "settings.reset.cumulative.title"),
            isPresented: $viewModel.showingResetCumulativeAlert
        ) {
            Button(String(localized: "settings.reset.cancel"), role: .cancel) { }
            Button(String(localized: "settings.reset.confirm"), role: .destructive) {
                viewModel.resetCumulativeMeter()
            }
        } message: {
            Text(String(localized: "settings.reset.cumulative.message"))
        }
        .alert(String(localized: "settings.reset.title"), isPresented: $viewModel.showingResetDataAlert) {
            Button(String(localized: "settings.reset.cancel"), role: .cancel) { }
            Button(String(localized: "settings.reset.confirm"), role: .destructive) {
                viewModel.resetAllData()
            }
        } message: {
            Text("This will permanently delete all your financial data. This action cannot be undone.")
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
            Text(String(localized: "settings.appearance.title"))
        } footer: {
            Text(String(localized: "settings.appearance.footer"))
        }
    }
    
    // MARK: - Language Section
    
    private var languageSection: some View {
        Section {
            ForEach(SettingsViewModel.LanguageMode.allCases, id: \.self) { language in
                HStack {
                    Text(language.flag)
                        .font(.title2)
                        .frame(width: 24)
                    
                    Text(language.displayName)
                        .font(.body)
                    
                    Spacer()
                    
                    if viewModel.selectedLanguage == language {
                        Image(systemName: "checkmark")
                            .foregroundColor(Color(hex: "4A90E2"))
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    viewModel.updateLanguage(language)
                }
            }
        } header: {
            Text(String(localized: "settings.language.title"))
        } footer: {
            Text(String(localized: "settings.language.footer"))
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
                    
                    Text(String(localized: "settings.export.title"))
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

                    Text(String(localized: "settings.reset.cumulative.title"))
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
                    
                    Text(String(localized: "settings.reset.title"))
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
                    
                    Text(String(localized: "settings.privacy.title"))
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.system(size: 14, weight: .medium))
                }
            }
        } header: {
            Text(String(localized: "settings.data.title"))
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
                
                Text(String(localized: "settings.version.title"))
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
                    
                    Text(String(localized: "settings.terms.title"))
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
                    
                    Text(String(localized: "settings.contact.title"))
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.system(size: 14, weight: .medium))
                }
            }
        } header: {
            Text(String(localized: "settings.about.title"))
        }
    }
    
    // MARK: - Sheet Views
    
    private var privacyPolicyView: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Privacy Policy")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.bottom, 8)
                    
                    Text("BudgetMeter is committed to protecting your privacy. This app:")
                        .font(.body)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("• Stores all data locally on your device")
                        Text("• Uses iCloud for private sync across your devices")
                        Text("• Does not collect any personal information")
                        Text("• Does not use third-party analytics")
                        Text("• Does not share data with external services")
                    }
                    .font(.body)
                    .padding(.leading, 8)
                    
                    Spacer()
                }
                .padding(16)
            }
            .navigationTitle("Privacy")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
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
                    Text("Terms of Service")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.bottom, 8)
                    
                    Text("By using BudgetMeter, you agree to these terms:")
                        .font(.body)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("• This app is provided 'as is' without warranty")
                        Text("• Use at your own risk for financial planning")
                        Text("• We are not liable for financial decisions")
                        Text("• Terms may be updated without notice")
                    }
                    .font(.body)
                    .padding(.leading, 8)
                    
                    Spacer()
                }
                .padding(16)
            }
            .navigationTitle("Terms")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
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
                
                Text("Export Your Data")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Your financial data will be exported as a CSV file that you can save or share.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                Button("Export CSV") {
                    // TODO: Implement CSV export
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(hex: "4A90E2"))
                
                Spacer()
            }
            .padding(16)
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
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
