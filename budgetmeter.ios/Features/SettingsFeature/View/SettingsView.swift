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
    @StateObject private var premiumManager = PremiumManager.shared
    
    var body: some View {
        NavigationView {
            List {
                // Appearance Section
                appearanceSection
                
                // Language & Region Section
                languageSection

                // Currency Section
                currencySection

                // Notifications Section
                notificationsSection

                // Premium Section
                premiumSection
                
                // Data & Privacy Section
                dataPrivacySection
                
                // About Section
                aboutSection
                
                // Debug Section (DEBUG builds only)
                #if DEBUG
                debugSection
                #endif
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
                        .foregroundColor(.brandProgress)
                        .frame(width: 24)

                    Text(mode.displayName)
                        .font(.body)

                    Spacer()

                    if viewModel.selectedAppearance == mode {
                        Image(systemName: "checkmark")
                            .foregroundColor(.brandProgress)
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

    // MARK: - Notifications Section

    private var notificationsSection: some View {
        Section {
            NavigationLink(destination: NotificationSettingsView()) {
                HStack(spacing: 12) {
                    Image(systemName: "bell.fill")
                        .foregroundColor(.brandProgress)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Notifications")
                            .font(.body)
                            .foregroundColor(.primary)
                        Text("Manage alerts and reminders")
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
        } header: {
            Text("NOTIFICATIONS")
        } footer: {
            Text("Control how BudgetMeter notifies you about your financial progress")
        }
    }

    // MARK: - Premium Section

    private var premiumSection: some View {
        Section {
            NavigationLink(destination: RecurringTransactionsView()) {
                PremiumFeatureRow(
                    title: "settings.premium.recurring".localized(defaultValue: "Recurring Transactions"),
                    subtitle: "settings.premium.recurring.subtitle".localized(defaultValue: "Automate repeating transactions"),
                    iconName: "repeat",
                    premiumFeature: .recurringTransactions
                )
            }
            
            NavigationLink(destination: DataExportView()) {
                PremiumFeatureRow(
                    title: "settings.premium.export".localized(defaultValue: "Data Export"),
                    subtitle: "settings.premium.export.subtitle".localized(defaultValue: "Export your data in multiple formats"),
                    iconName: "square.and.arrow.up",
                    premiumFeature: .dataExport
                )
            }
            
            NavigationLink(destination: WidgetsSetupView()) {
                PremiumFeatureRow(
                    title: "settings.premium.widgets".localized(defaultValue: "Widgets"),
                    subtitle: "settings.premium.widgets.subtitle".localized(defaultValue: "Display data on Home Screen"),
                    iconName: "rectangle.3.group",
                    premiumFeature: .widgets
                )
            }
            
            NavigationLink(destination: InsightsView()) {
                PremiumFeatureRow(
                    title: "settings.premium.insights".localized(defaultValue: "Spending Insights"),
                    subtitle: "settings.premium.insights.subtitle".localized(defaultValue: "Visual charts and analytics"),
                    iconName: "chart.bar.fill",
                    premiumFeature: .spendingInsights
                )
            }
            
            NavigationLink(destination: BiometricSettingsView()) {
                HStack {
                    Image(systemName: "faceid")
                        .foregroundColor(.accentColor)
                        .frame(width: 24)

                    VStack(alignment: .leading) {
                        Text("settings.premium.biometric".localized(defaultValue: "Biometric Lock"))
                            .font(.body)
                            .foregroundColor(.primary)
                        Text("settings.premium.biometric.subtitle".localized(defaultValue: "Protect with Face ID or Touch ID"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    // DEBUG: Always show as available for testing
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.brandPositive)
                        .font(.caption)
                }
                .contentShape(Rectangle())
            }
            
            NavigationLink(destination: PremiumThemesView()) {
                PremiumFeatureRow(
                    title: "settings.premium.themes".localized(defaultValue: "Premium Themes"),
                    subtitle: "settings.premium.themes.subtitle".localized(defaultValue: "Beautiful themes and app icons"),
                    iconName: "paintbrush.fill",
                    premiumFeature: .premiumThemes
                )
            }
        } header: {
            Text("settings.premium.title".localized(defaultValue: "Premium Features"))
        } footer: {
            Text("settings.premium.footer".localized(defaultValue: "Unlock all premium features with a one-time purchase of $4.99"))
        }
    }
    
    // MARK: - Data & Privacy Section
    
    private var dataPrivacySection: some View {
        Section {
            // Reset Long-Term Meter
            Button(action: viewModel.showResetCumulativeConfirmation) {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                        .foregroundColor(.brandProgress)
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
                        .foregroundColor(.brandProgress)
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
                    .foregroundColor(.brandProgress)
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
                        .foregroundColor(.brandProgress)
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
            Button(action: {
                if let url = URL(string: "mailto:umursoganci@gmail.com?subject=BudgetMeter%20Support&body=Please%20describe%20your%20issue:%0A%0ADevice:%20\(UIDevice.current.model)%0AiOS:%20\(UIDevice.current.systemVersion)%0AApp%20Version:%201.0") {
                    UIApplication.shared.open(url)
                }
            }) {
                HStack {
                    Image(systemName: "envelope")
                        .foregroundColor(.brandProgress)
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
                    Text("BudgetMeter Privacy Policy")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.bottom, 8)
                    
                    Text("Last Updated: September 2025")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 8)
                    
                    Group {
                        Text("DATA CONTROLLER")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Text("Umurcan Soganci\nEmail: umursoganci@gmail.com")
                            .font(.body)
                        
                        Text("DATA WE COLLECT")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .padding(.top, 8)
                        Text("• Financial data (income, expenses, categories) - stored locally on your device\n• App preferences (currency, language) - stored locally\n• iCloud sync data (when enabled) - stored in your personal iCloud account")
                            .font(.body)
                        
                        Text("HOW WE USE DATA")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .padding(.top, 8)
                        Text("• To provide financial tracking functionality\n• To sync across your devices via iCloud (optional)\n• All processing happens locally on your device")
                            .font(.body)
                        
                        Text("DATA SHARING")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .padding(.top, 8)
                        Text("We do not share, sell, or transmit your personal data to any third parties.")
                            .font(.body)
                        
                        Text("DATA STORAGE")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .padding(.top, 8)
                        Text("• Local: Core Data database on your device\n• Cloud: Your private iCloud account (optional)\n• No external servers or third-party databases")
                            .font(.body)
                        
                        Text("YOUR RIGHTS")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .padding(.top, 8)
                        Text("• Access: View all your data within the app\n• Delete: Reset all data via Settings\n• Control: Disable iCloud sync anytime")
                            .font(.body)
                        
                        Text("CONTACT")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .padding(.top, 8)
                        Text("For privacy questions: umursoganci@gmail.com")
                            .font(.body)
                    }

                    Spacer()
                }
                .padding(Spacing.lg)
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
                    Text("BudgetMeter Terms of Service")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.bottom, 8)
                    
                    Text("Last Updated: September 2025")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 8)
                    
                    Group {
                        Text("ACCEPTANCE")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Text("By downloading and using BudgetMeter, you agree to these terms of service.")
                            .font(.body)
                        
                        Text("LICENSE")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .padding(.top, 8)
                        Text("We grant you a personal, non-commercial license to use BudgetMeter for managing your personal finances.")
                            .font(.body)
                        
                        Text("FINANCIAL DISCLAIMER")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .padding(.top, 8)
                        Text("• BudgetMeter is for informational purposes only\n• This app does not provide professional financial advice\n• We are not liable for financial decisions made using this app\n• Calculations may contain errors - verify important figures")
                            .font(.body)
                        
                        Text("INTELLECTUAL PROPERTY")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .padding(.top, 8)
                        Text("BudgetMeter app and all content are owned by Umurcan Soganci. All rights reserved.")
                            .font(.body)
                        
                        Text("WARRANTY DISCLAIMER")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .padding(.top, 8)
                        Text("The app is provided 'as-is' without warranties of any kind, express or implied.")
                            .font(.body)
                        
                        Text("LIMITATION OF LIABILITY")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .padding(.top, 8)
                        Text("Our maximum liability is limited to the amount you paid for the app (currently free).")
                            .font(.body)
                        
                        Text("CONTACT")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .padding(.top, 8)
                        Text("Questions about these terms: umursoganci@gmail.com")
                            .font(.body)
                    }
                    
                    Spacer()
                }
                .padding(Spacing.lg)
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

    
    // MARK: - Debug Section
    
    #if DEBUG
    private var debugSection: some View {
        Section {
            HStack {
                Image(systemName: "crown.fill")
                    .foregroundColor(.yellow)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("debug.premium.title".localized(defaultValue: "Premium Mode"))
                        .font(.headline)
                    Text("debug.premium.subtitle".localized(defaultValue: "Toggle premium features for testing"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: $premiumManager.isPremium)
                    .onChange(of: premiumManager.isPremium) { newValue in
                        premiumManager.setDebugPremiumStatus(newValue)
                    }
            }
            .padding(.vertical, 5)
        } header: {
            Text("debug.section.title".localized(defaultValue: "Debug"))
        } footer: {
            Text("debug.section.footer".localized(defaultValue: "This section is only visible in debug builds"))
        }
    }
    #endif
    
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
