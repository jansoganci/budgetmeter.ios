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
    @State private var showingPremiumPaywall = false

    var body: some View {
        NavigationView {
            List {
                // Premium Section (top priority - revenue generating)
                premiumSection

                // General Section (Notifications, Language, Currency, Appearance combined)
                generalSection

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
        .sheet(isPresented: $viewModel.isAppearancePickerPresented) {
            AppearancePickerView(
                selectedAppearance: viewModel.selectedAppearance,
                onSelect: { mode in
                    viewModel.updateAppearance(mode)
                }
            )
            .presentationDetents([.height(280)])
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
    
    // MARK: - General Section (Notifications, Language, Currency, Appearance combined)

    private var generalSection: some View {
        Section {
            // Notifications Row
            NavigationLink(destination: NotificationSettingsView()) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("settings.notifications.title".localized(defaultValue: "Notifications"))
                            .font(.body)
                            .foregroundColor(.primary)
                        Text("settings.notifications.subtitle".localized(defaultValue: "Manage alerts and reminders"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
                .contentShape(Rectangle())
            }

            // Language Row
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

            // Currency Row
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

            // Appearance Row
            Button {
                viewModel.showAppearancePicker()
            } label: {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("settings.appearance.title".localized(defaultValue: "Appearance"))
                            .font(.body)
                            .foregroundColor(.primary)
                        Text(viewModel.selectedAppearance.displayName)
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
        } header: {
            Text("settings.general.title".localized(defaultValue: "General"))
        }
    }

    // MARK: - Premium Section (Non-Premium Users)

    @ViewBuilder
    private var premiumSection: some View {
        if premiumManager.isPremium {
            // Premium user: Show categorized feature sections
            trackingAndGoalsSection
            customizationSection
            securitySection
        } else {
            // Non-premium user: Show only the upgrade banner
            Section {
                PremiumUpgradeBanner {
                    showingPremiumPaywall = true
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            } header: {
                Text("settings.premium.title".localized(defaultValue: "Premium Features"))
            }
            .sheet(isPresented: $showingPremiumPaywall) {
                PremiumPaywallView(
                    feature: .subscriptionTracking,
                    onDismiss: { showingPremiumPaywall = false },
                    onPurchase: { showingPremiumPaywall = false },
                    onRestore: { showingPremiumPaywall = false }
                )
            }
        }
    }

    // MARK: - Tracking & Goals Section (Premium)

    private var trackingAndGoalsSection: some View {
        Section {
            NavigationLink(destination: SavingsGoalsView()) {
                premiumFeatureRowSimple(
                    title: "settings.premium.savings_goals".localized(defaultValue: "Savings Goals"),
                    iconName: "target"
                )
            }
        } header: {
            Text("settings.premium.tracking.title".localized(defaultValue: "Tracking & Goals"))
        }
    }

    // MARK: - Customization Section (Premium)

    private var customizationSection: some View {
        Section {
            NavigationLink(destination: PremiumThemesView()) {
                premiumFeatureRowSimple(
                    title: "settings.premium.themes".localized(defaultValue: "Premium Themes"),
                    iconName: "paintbrush.fill"
                )
            }

            NavigationLink(destination: WidgetsSetupView()) {
                premiumFeatureRowSimple(
                    title: "settings.premium.widgets".localized(defaultValue: "Widgets"),
                    iconName: "rectangle.3.group"
                )
            }

            NavigationLink(destination: DataExportView()) {
                premiumFeatureRowSimple(
                    title: "settings.premium.export".localized(defaultValue: "Data Export"),
                    iconName: "square.and.arrow.up"
                )
            }
        } header: {
            Text("settings.premium.customization.title".localized(defaultValue: "Customization"))
        }
    }

    // MARK: - Security Section (Premium)

    private var securitySection: some View {
        Section {
            NavigationLink(destination: BiometricSettingsView()) {
                premiumFeatureRowSimple(
                    title: "settings.premium.biometric".localized(defaultValue: "Biometric Lock"),
                    iconName: "faceid"
                )
            }
        } header: {
            Text("settings.premium.security.title".localized(defaultValue: "Security"))
        }
    }

    // MARK: - Premium Feature Row Helper

    private func premiumFeatureRowSimple(title: String, iconName: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .foregroundColor(.brandProgress)
                .frame(width: 24)

            Text(title)
                .font(.body)
                .foregroundColor(.primary)

            Spacer()
        }
        .contentShape(Rectangle())
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
                    Text("settings.privacy.policy.title".localized(defaultValue: "BudgetMeter Privacy Policy"))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.bottom, 8)
                    
                    Text("settings.privacy.policy.last_updated".localized(defaultValue: "Last Updated: September 2025"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 8)
                    
                    Group {
                        Text("settings.privacy.policy.data_controller.title".localized(defaultValue: "DATA CONTROLLER"))
                            .font(.headline)
                            .fontWeight(.semibold)
                        Text("settings.privacy.policy.data_controller.content".localized(defaultValue: "Umurcan Soganci\nEmail: umursoganci@gmail.com"))
                            .font(.body)
                        
                        Text("settings.privacy.policy.data_collect.title".localized(defaultValue: "DATA WE COLLECT"))
                            .font(.headline)
                            .fontWeight(.semibold)
                            .padding(.top, 8)
                        Text("settings.privacy.policy.data_collect.content".localized(defaultValue: "• Financial data (income, expenses, categories) - stored locally on your device\n• App preferences (currency, language) - stored locally\n• iCloud sync data (when enabled) - stored in your personal iCloud account"))
                            .font(.body)
                        
                        Text("settings.privacy.policy.data_use.title".localized(defaultValue: "HOW WE USE DATA"))
                            .font(.headline)
                            .fontWeight(.semibold)
                            .padding(.top, 8)
                        Text("settings.privacy.policy.data_use.content".localized(defaultValue: "• To provide financial tracking functionality\n• To sync across your devices via iCloud (optional)\n• All processing happens locally on your device"))
                            .font(.body)
                        
                        Text("settings.privacy.policy.data_sharing.title".localized(defaultValue: "DATA SHARING"))
                            .font(.headline)
                            .fontWeight(.semibold)
                            .padding(.top, 8)
                        Text("settings.privacy.policy.data_sharing.content".localized(defaultValue: "We do not share, sell, or transmit your personal data to any third parties."))
                            .font(.body)
                        
                        Text("settings.privacy.policy.data_storage.title".localized(defaultValue: "DATA STORAGE"))
                            .font(.headline)
                            .fontWeight(.semibold)
                            .padding(.top, 8)
                        Text("settings.privacy.policy.data_storage.content".localized(defaultValue: "• Local: Core Data database on your device\n• Cloud: Your private iCloud account (optional)\n• No external servers or third-party databases"))
                            .font(.body)
                        
                        Text("settings.privacy.policy.your_rights.title".localized(defaultValue: "YOUR RIGHTS"))
                            .font(.headline)
                            .fontWeight(.semibold)
                            .padding(.top, 8)
                        Text("settings.privacy.policy.your_rights.content".localized(defaultValue: "• Access: View all your data within the app\n• Delete: Reset all data via Settings\n• Control: Disable iCloud sync anytime"))
                            .font(.body)
                        
                        Text("settings.privacy.policy.contact.title".localized(defaultValue: "CONTACT"))
                            .font(.headline)
                            .fontWeight(.semibold)
                            .padding(.top, 8)
                        Text("settings.privacy.policy.contact.content".localized(defaultValue: "For privacy questions: umursoganci@gmail.com"))
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
                    Text("settings.terms.policy.title".localized(defaultValue: "BudgetMeter Terms of Service"))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.bottom, 8)
                    
                    Text("settings.terms.policy.last_updated".localized(defaultValue: "Last Updated: September 2025"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 8)
                    
                    Group {
                        Text("settings.terms.policy.acceptance.title".localized(defaultValue: "ACCEPTANCE"))
                            .font(.headline)
                            .fontWeight(.semibold)
                        Text("settings.terms.policy.acceptance.content".localized(defaultValue: "By downloading and using BudgetMeter, you agree to these terms of service."))
                            .font(.body)
                        
                        Text("settings.terms.policy.license.title".localized(defaultValue: "LICENSE"))
                            .font(.headline)
                            .fontWeight(.semibold)
                            .padding(.top, 8)
                        Text("settings.terms.policy.license.content".localized(defaultValue: "We grant you a personal, non-commercial license to use BudgetMeter for managing your personal finances."))
                            .font(.body)

                        Text("settings.terms.policy.iap.title".localized(defaultValue: "IN-APP PURCHASES & SUBSCRIPTIONS"))
                            .font(.headline)
                            .fontWeight(.semibold)
                            .padding(.top, 8)
                        Text("settings.terms.policy.iap.content".localized(defaultValue: "• BudgetMeter Premium is available as an auto-renewing subscription\n• Payment will be charged to your Apple ID account at confirmation of purchase\n• Subscription automatically renews unless canceled at least 24 hours before the end of the current period\n• Your account will be charged for renewal within 24 hours prior to the end of the current period\n• You can manage and cancel your subscriptions in your App Store account settings\n• Any unused portion of a free trial period will be forfeited when purchasing a subscription\n• Subscriptions are processed through Apple's App Store - we do not have access to your payment information\n• Refunds are handled by Apple according to their refund policy"))
                            .font(.body)

                        Text("settings.terms.policy.financial_disclaimer.title".localized(defaultValue: "FINANCIAL DISCLAIMER"))
                            .font(.headline)
                            .fontWeight(.semibold)
                            .padding(.top, 8)
                        Text("settings.terms.policy.financial_disclaimer.content".localized(defaultValue: "• BudgetMeter is for informational purposes only\n• This app does not provide professional financial advice\n• We are not liable for financial decisions made using this app\n• Calculations may contain errors - verify important figures"))
                            .font(.body)
                        
                        Text("settings.terms.policy.intellectual_property.title".localized(defaultValue: "INTELLECTUAL PROPERTY"))
                            .font(.headline)
                            .fontWeight(.semibold)
                            .padding(.top, 8)
                        Text("settings.terms.policy.intellectual_property.content".localized(defaultValue: "BudgetMeter app and all content are owned by Umurcan Soganci. All rights reserved."))
                            .font(.body)
                        
                        Text("settings.terms.policy.warranty.title".localized(defaultValue: "WARRANTY DISCLAIMER"))
                            .font(.headline)
                            .fontWeight(.semibold)
                            .padding(.top, 8)
                        Text("settings.terms.policy.warranty.content".localized(defaultValue: "The app is provided 'as-is' without warranties of any kind, express or implied."))
                            .font(.body)
                        
                        Text("settings.terms.policy.liability.title".localized(defaultValue: "LIMITATION OF LIABILITY"))
                            .font(.headline)
                            .fontWeight(.semibold)
                            .padding(.top, 8)
                        Text("settings.terms.policy.liability.content".localized(defaultValue: "Our maximum liability is limited to the amount you paid for the app or subscription in the 12 months prior to the claim."))
                            .font(.body)
                        
                        Text("settings.terms.policy.contact.title".localized(defaultValue: "CONTACT"))
                            .font(.headline)
                            .fontWeight(.semibold)
                            .padding(.top, 8)
                        Text("settings.terms.policy.contact.content".localized(defaultValue: "Questions about these terms: umursoganci@gmail.com"))
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
            Toggle(isOn: $premiumManager.isPremium) {
                HStack(spacing: 12) {
                    Image(systemName: "crown.fill")
                        .foregroundColor(.yellow)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("debug.premium.title".localized(defaultValue: "Premium Mode"))
                            .font(.body)
                            .foregroundColor(.primary)
                        Text("debug.premium.subtitle".localized(defaultValue: "Toggle premium features for testing"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .onChange(of: premiumManager.isPremium) { newValue in
                premiumManager.setDebugPremiumStatus(newValue)
            }
        } header: {
            Text("debug.section.title".localized(defaultValue: "Debug"))
        } footer: {
            Text("debug.section.footer".localized(defaultValue: "This section is only visible in debug builds"))
        }
    }
    #endif
}

// MARK: - Preview

#Preview {
    SettingsView()
}
