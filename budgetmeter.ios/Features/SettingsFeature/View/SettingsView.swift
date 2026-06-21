//
//  SettingsView.swift
//  BudgetMeter
//
//  Created by BudgetMeter Team on 17.09.2025.
//

import SwiftUI

/// Settings screen — v2 UI transformation (calm grouped sections, shared DesignSystem).
struct SettingsView: View {
    
    @StateObject private var viewModel = SettingsViewModel()
    @StateObject private var premiumManager = PremiumManager.shared
    @StateObject private var authService = AuthService.shared
    @State private var showingPremiumPaywall = false
    #if DEBUG
    @AppStorage(PremiumManager.debugPremiumOverrideKey) private var debugPremiumEnabled = false
    #endif

    var body: some View {
        NavigationView {
            ZStack {
                AppBackground()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: LayoutSpacing.sectionGap) {
                        accountSection
                        premiumSection
                        generalSection
                        dataPrivacySection
                        aboutSection

                        #if DEBUG
                        debugSection
                        #endif
                    }
                    .padding(.horizontal, LayoutSpacing.screenPadding)
                    .padding(.vertical, Spacing.md)
                }
            }
            .navigationTitle("settings.title".localized(defaultValue: "Settings", table: "UI"))
            .navigationBarTitleDisplayMode(.inline)
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
            "settings.reset.cumulative.title".localized(defaultValue: "Reset Long-Term Meter", table: "UI"),
            isPresented: $viewModel.showingResetCumulativeAlert
        ) {
            Button("settings.reset.cancel".localized(defaultValue: "Cancel", table: "UI"), role: .cancel) { }
            Button("settings.reset.confirm".localized(defaultValue: "Reset", table: "UI"), role: .destructive) {
                viewModel.resetCumulativeMeter()
            }
        } message: {
            Text("settings.reset.cumulative.message".localized(defaultValue: "This will reset your long-term financial meter to zero. Your income and expense data will remain unchanged.", table: "UI"))
        }
        .alert("settings.reset.title".localized(defaultValue: "Reset All Data", table: "UI"), isPresented: $viewModel.showingResetDataAlert) {
            Button("settings.reset.cancel".localized(defaultValue: "Cancel", table: "UI"), role: .cancel) { }
            Button("settings.reset.confirm".localized(defaultValue: "Reset", table: "UI"), role: .destructive) {
                viewModel.resetAllData()
            }
        } message: {
            Text("settings.reset.all.warning".localized(defaultValue: "This will permanently delete all your financial data. This action cannot be undone.", table: "UI"))
        }
    }
    
    // MARK: - General Section (Notifications, Language, Currency, Appearance combined)

    private var generalSection: some View {
        SettingsSection(title: "settings.general.title".localized(defaultValue: "General", table: "UI")) {
            NavigationLink(destination: NotificationSettingsView()) {
                SettingsRowContent(
                    iconName: "bell.badge",
                    title: "settings.notifications.title".localized(defaultValue: "Notifications", table: "UI"),
                    subtitle: "settings.notifications.subtitle".localized(defaultValue: "Manage alerts and reminders", table: "UI"),
                    showsChevron: true
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                String(
                    format: "settings.notifications.accessibility".localized(defaultValue: "%@, %@", table: "UI"),
                    "settings.notifications.title".localized(defaultValue: "Notifications", table: "UI"),
                    "settings.notifications.subtitle".localized(defaultValue: "Manage alerts and reminders", table: "UI")
                )
            )
            .accessibilityHint("settings.row.hint".localized(defaultValue: "Double tap to open", table: "UI"))

            SettingsDivider()

            SettingsActionRow(
                iconName: "globe",
                title: "settings.language.title".localized(defaultValue: "Language", table: "UI"),
                subtitle: viewModel.selectedLanguageDisplayText,
                action: viewModel.showLanguagePicker
            )

            SettingsDivider()

            SettingsActionRow(
                iconName: "dollarsign.circle",
                title: "settings.currency.row.label".localized(defaultValue: "Currency", table: "UI"),
                subtitle: viewModel.selectedCurrencyDisplayText,
                action: viewModel.showCurrencyPicker
            )

            SettingsDivider()

            SettingsActionRow(
                iconName: "circle.lefthalf.filled",
                title: "settings.appearance.title".localized(defaultValue: "Appearance", table: "UI"),
                subtitle: viewModel.selectedAppearance.displayName,
                action: viewModel.showAppearancePicker
            )
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
            VStack(alignment: .leading, spacing: Spacing.sm) {
                SectionHeader(
                    title: "settings.premium.title".localized(defaultValue: "Premium Features", table: "UI")
                )

                PremiumUpgradeBanner {
                    showingPremiumPaywall = true
                }
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
        SettingsSection(title: "settings.premium.tracking.title".localized(defaultValue: "Tracking & Goals", table: "UI")) {
            NavigationLink(destination: SavingsGoalsView()) {
                SettingsRowContent(
                    iconName: "target",
                    title: "settings.premium.savings_goals".localized(defaultValue: "Savings Goals", table: "UI"),
                    showsChevron: true
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Customization Section (Premium)

    private var customizationSection: some View {
        SettingsSection(
            title: "settings.premium.customization.title".localized(defaultValue: "Customization", table: "UI"),
            headerTrailing: {
                PremiumBadge(variant: .active)
            }
        ) {
            NavigationLink(destination: PremiumThemesView()) {
                SettingsRowContent(
                    iconName: "paintbrush.fill",
                    title: "settings.premium.themes".localized(defaultValue: "Premium Themes", table: "UI"),
                    showsChevron: true
                )
            }
            .buttonStyle(.plain)

            SettingsDivider()

            NavigationLink(destination: WidgetsSetupView()) {
                SettingsRowContent(
                    iconName: "rectangle.3.group",
                    title: "settings.premium.widgets".localized(defaultValue: "Widgets", table: "UI"),
                    showsChevron: true
                )
            }
            .buttonStyle(.plain)

            SettingsDivider()

            NavigationLink(destination: DataExportView()) {
                SettingsRowContent(
                    iconName: "square.and.arrow.up",
                    title: "settings.premium.export".localized(defaultValue: "Data Export", table: "UI"),
                    showsChevron: true
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Security Section (Premium)

    private var securitySection: some View {
        SettingsSection(title: "settings.premium.security.title".localized(defaultValue: "Security", table: "UI")) {
            NavigationLink(destination: BiometricSettingsView()) {
                SettingsRowContent(
                    iconName: "faceid",
                    title: "settings.premium.biometric".localized(defaultValue: "Biometric Lock", table: "UI"),
                    showsChevron: true
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Account Section

    private var accountSection: some View {
        SettingsSection {
            NavigationLink(destination: AccountBackupSettingsView()) {
                SettingsRowContent(
                    iconName: "person.crop.circle",
                    title: "settings.account.title".localized(defaultValue: "Account & Backup", table: "UI"),
                    subtitle: accountStatusText,
                    trailingBadge: premiumManager.isPremium ? .premiumActive : nil,
                    showsChevron: true
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                String(
                    format: "settings.notifications.accessibility".localized(defaultValue: "%@, %@", table: "UI"),
                    "settings.account.title".localized(defaultValue: "Account & Backup", table: "UI"),
                    accountStatusText
                )
            )
            .accessibilityHint("settings.row.hint".localized(defaultValue: "Double tap to open", table: "UI"))
        }
    }

    private var accountStatusText: String {
        if let email = authService.currentEmail, !email.isEmpty {
            return email
        }
        if let userID = authService.currentUserID {
            return userID
        }
        return "account.signed_in".localized(defaultValue: "Signed in", table: "UI")
    }

    // MARK: - Data & Privacy Section
    
    private var dataPrivacySection: some View {
        SettingsSection(title: "settings.data.title".localized(defaultValue: "Data & Privacy", table: "UI")) {
            SettingsActionRow(
                iconName: "arrow.counterclockwise",
                title: "settings.reset.cumulative.title".localized(defaultValue: "Reset Long-Term Meter", table: "UI"),
                showsChevron: false,
                action: viewModel.showResetCumulativeConfirmation
            )

            SettingsDivider()

            SettingsActionRow(
                iconName: "trash",
                title: "settings.reset.title".localized(defaultValue: "Reset All Data", table: "UI"),
                role: .destructive,
                showsChevron: false,
                action: viewModel.showResetDataConfirmation
            )

            SettingsDivider()

            SettingsActionRow(
                iconName: "hand.raised",
                title: "settings.privacy.title".localized(defaultValue: "Privacy Policy", table: "UI"),
                action: viewModel.showPrivacyPolicy
            )
        }
    }
    
    // MARK: - About Section
    
    private var aboutSection: some View {
        SettingsSection(title: "settings.about.title".localized(defaultValue: "About", table: "UI")) {
            SettingsRowContent(
                iconName: "info.circle",
                title: "settings.version.title".localized(defaultValue: "Version", table: "UI"),
                value: viewModel.appVersion,
                showsChevron: false
            )

            SettingsDivider()

            SettingsActionRow(
                iconName: "doc.text",
                title: "settings.terms.title".localized(defaultValue: "Terms of Service", table: "UI"),
                action: viewModel.showTermsOfService
            )

            SettingsDivider()

            SettingsActionRow(
                iconName: "envelope",
                title: "settings.contact.title".localized(defaultValue: "Contact Support", table: "UI"),
                action: {
                if let url = URL(string: "mailto:umursoganci@gmail.com?subject=BudgetMeter%20Support&body=Please%20describe%20your%20issue:%0A%0ADevice:%20\(UIDevice.current.model)%0AiOS:%20\(UIDevice.current.systemVersion)%0AApp%20Version:%201.0") {
                    UIApplication.shared.open(url)
                }
                }
            )
        }
    }
    
    // MARK: - Sheet Views
    
    private var privacyPolicyView: some View {
        NavigationView {
            ZStack {
                AppBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        Text("settings.privacy.policy.title".localized(defaultValue: "BudgetMeter Privacy Policy", table: "UI"))
                            .sectionTitleStyle()

                        Text("settings.privacy.policy.last_updated".localized(defaultValue: "Last Updated: June 2026", table: "UI"))
                            .captionStyle()

                        legalSectionBlock(
                            title: "settings.privacy.policy.data_controller.title".localized(defaultValue: "DATA CONTROLLER", table: "UI"),
                            body: "settings.privacy.policy.data_controller.content".localized(defaultValue: "Umurcan Soganci\nEmail: umursoganci@gmail.com", table: "UI")
                        )
                        legalSectionBlock(
                            title: "settings.privacy.policy.data_collect.title".localized(defaultValue: "DATA WE COLLECT", table: "UI"),
                            body: "settings.privacy.policy.data_collect.content".localized(defaultValue: "• Financial data (income, expenses, categories) - stored locally on your device\n• App preferences (currency, language) - stored locally\n• Premium cloud backup (optional) - stored in your Supabase account when you sign in and back up\n• Legacy iCloud sync may still apply until migration is complete", table: "UI")
                        )
                        legalSectionBlock(
                            title: "settings.privacy.policy.data_use.title".localized(defaultValue: "HOW WE USE DATA", table: "UI"),
                            body: "settings.privacy.policy.data_use.content".localized(defaultValue: "• To provide financial tracking functionality\n• To back up and restore premium cloud data when you sign in\n• All processing happens locally on your device", table: "UI")
                        )
                        legalSectionBlock(
                            title: "settings.privacy.policy.data_sharing.title".localized(defaultValue: "DATA SHARING", table: "UI"),
                            body: "settings.privacy.policy.data_sharing.content".localized(defaultValue: "We do not sell your personal data. Optional premium cloud backup uses Supabase for secure storage. We do not share your data with advertisers or other third parties.", table: "UI")
                        )
                        legalSectionBlock(
                            title: "settings.privacy.policy.data_storage.title".localized(defaultValue: "DATA STORAGE", table: "UI"),
                            body: "settings.privacy.policy.data_storage.content".localized(defaultValue: "• Local: Core Data database on your device\n• Cloud (Premium): Supabase-backed backup linked to your signed-in account\n• Legacy iCloud data may remain until migration is complete", table: "UI")
                        )
                        legalSectionBlock(
                            title: "settings.privacy.policy.your_rights.title".localized(defaultValue: "YOUR RIGHTS", table: "UI"),
                            body: "settings.privacy.policy.your_rights.content".localized(defaultValue: "• Access: View all your data within the app\n• Delete local data: Reset all data via Settings\n• Delete cloud account: Delete account in Account & Backup\n• Control: Sign out anytime; cloud backup is optional and premium", table: "UI")
                        )
                        legalSectionBlock(
                            title: "settings.privacy.policy.contact.title".localized(defaultValue: "CONTACT", table: "UI"),
                            body: "settings.privacy.policy.contact.content".localized(defaultValue: "For privacy questions: umursoganci@gmail.com", table: "UI")
                        )
                    }
                    .padding(LayoutSpacing.cardPadding)
                }
            }
            .navigationTitle("settings.privacy.sheet.nav_title".localized(defaultValue: "Privacy Policy", table: "UI"))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("toolbar.done".localized(defaultValue: "Done", table: "UI")) {
                        viewModel.showingPrivacyPolicy = false
                    }
                }
            }
        }
    }

    private var termsOfServiceView: some View {
        NavigationView {
            ZStack {
                AppBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        Text("settings.terms.policy.title".localized(defaultValue: "BudgetMeter Terms of Service", table: "UI"))
                            .sectionTitleStyle()

                        Text("settings.terms.policy.last_updated".localized(defaultValue: "Last Updated: September 2025", table: "UI"))
                            .captionStyle()

                        legalSectionBlock(
                            title: "settings.terms.policy.acceptance.title".localized(defaultValue: "ACCEPTANCE", table: "UI"),
                            body: "settings.terms.policy.acceptance.content".localized(defaultValue: "By downloading and using BudgetMeter, you agree to these terms of service.", table: "UI")
                        )
                        legalSectionBlock(
                            title: "settings.terms.policy.license.title".localized(defaultValue: "LICENSE", table: "UI"),
                            body: "settings.terms.policy.license.content".localized(defaultValue: "We grant you a personal, non-commercial license to use BudgetMeter for managing your personal finances.", table: "UI")
                        )
                        legalSectionBlock(
                            title: "settings.terms.policy.iap.title".localized(defaultValue: "IN-APP PURCHASES & SUBSCRIPTIONS", table: "UI"),
                            body: "settings.terms.policy.iap.content".localized(defaultValue: "• BudgetMeter Premium is available as an auto-renewing subscription\n• Payment will be charged to your Apple ID account at confirmation of purchase\n• Subscription automatically renews unless canceled at least 24 hours before the end of the current period\n• Your account will be charged for renewal within 24 hours prior to the end of the current period\n• You can manage and cancel your subscriptions in your App Store account settings\n• Any unused portion of a free trial period will be forfeited when purchasing a subscription\n• Subscriptions are processed through Apple's App Store - we do not have access to your payment information\n• Refunds are handled by Apple according to their refund policy", table: "UI")
                        )
                        legalSectionBlock(
                            title: "settings.terms.policy.financial_disclaimer.title".localized(defaultValue: "FINANCIAL DISCLAIMER", table: "UI"),
                            body: "settings.terms.policy.financial_disclaimer.content".localized(defaultValue: "• BudgetMeter is for informational purposes only\n• This app does not provide professional financial advice\n• We are not liable for financial decisions made using this app\n• Calculations may contain errors - verify important figures", table: "UI")
                        )
                        legalSectionBlock(
                            title: "settings.terms.policy.intellectual_property.title".localized(defaultValue: "INTELLECTUAL PROPERTY", table: "UI"),
                            body: "settings.terms.policy.intellectual_property.content".localized(defaultValue: "BudgetMeter app and all content are owned by Umurcan Soganci. All rights reserved.", table: "UI")
                        )
                        legalSectionBlock(
                            title: "settings.terms.policy.warranty.title".localized(defaultValue: "WARRANTY DISCLAIMER", table: "UI"),
                            body: "settings.terms.policy.warranty.content".localized(defaultValue: "The app is provided 'as-is' without warranties of any kind, express or implied.", table: "UI")
                        )
                        legalSectionBlock(
                            title: "settings.terms.policy.liability.title".localized(defaultValue: "LIMITATION OF LIABILITY", table: "UI"),
                            body: "settings.terms.policy.liability.content".localized(defaultValue: "Our maximum liability is limited to the amount you paid for the app or subscription in the 12 months prior to the claim.", table: "UI")
                        )
                        legalSectionBlock(
                            title: "settings.terms.policy.contact.title".localized(defaultValue: "CONTACT", table: "UI"),
                            body: "settings.terms.policy.contact.content".localized(defaultValue: "Questions about these terms: umursoganci@gmail.com", table: "UI")
                        )
                    }
                    .padding(LayoutSpacing.cardPadding)
                }
            }
            .navigationTitle("settings.terms.sheet.nav_title".localized(defaultValue: "Terms of Service", table: "UI"))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("toolbar.done".localized(defaultValue: "Done", table: "UI")) {
                        viewModel.showingTermsOfService = false
                    }
                }
            }
        }
    }

    
    // MARK: - Debug Section
    
    #if DEBUG
    private var debugSection: some View {
        SettingsSection(title: "DEBUG") {
            Toggle(isOn: $debugPremiumEnabled) {
                SettingsRowContent(
                    iconName: "ladybug",
                    title: "Premium Mode",
                    subtitle: "This section is only visible in debug builds.",
                    showsChevron: false
                )
            }
            .tint(.accentPrimary)
            .padding(.trailing, Spacing.md)
                .onChange(of: debugPremiumEnabled) { _, newValue in
                    premiumManager.setDebugPremiumStatus(newValue)
                }
        }
        .onAppear {
            if debugPremiumEnabled != premiumManager.isPremium {
                premiumManager.setDebugPremiumStatus(debugPremiumEnabled)
            }
        }
    }
    #endif

    private func legalSectionBlock(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(title)
                .cardLabelStyle(color: .textPrimary)
            Text(body)
                .bodyStyle(color: .textSecondary)
        }
    }
}

// MARK: - Settings Design Components

enum SettingsRowTrailingBadge {
    case premiumActive
}

struct SettingsSection<HeaderTrailing: View, Content: View>: View {
    let title: String?
    let footer: String?
    @ViewBuilder let headerTrailing: () -> HeaderTrailing
    @ViewBuilder let content: () -> Content

    init(
        title: String? = nil,
        footer: String? = nil,
        @ViewBuilder headerTrailing: @escaping () -> HeaderTrailing,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.footer = footer
        self.headerTrailing = headerTrailing
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            if let title {
                SectionHeader(title: title) {
                    headerTrailing()
                }
            }

            GlassCard(padding: 0) {
                VStack(spacing: 0) {
                    content()
                }
            }

            if let footer {
                Text(footer)
                    .captionStyle()
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, Spacing.xs)
            }
        }
    }
}

extension SettingsSection where HeaderTrailing == EmptyView {
    init(
        title: String? = nil,
        footer: String? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.footer = footer
        self.headerTrailing = { EmptyView() }
        self.content = content
    }
}

struct SettingsActionRow: View {
    let iconName: String
    let title: String
    let subtitle: String?
    let value: String?
    let role: ButtonRole?
    let showsChevron: Bool
    let action: () -> Void

    init(
        iconName: String,
        title: String,
        subtitle: String? = nil,
        value: String? = nil,
        role: ButtonRole? = nil,
        showsChevron: Bool = true,
        action: @escaping () -> Void
    ) {
        self.iconName = iconName
        self.title = title
        self.subtitle = subtitle
        self.value = value
        self.role = role
        self.showsChevron = showsChevron
        self.action = action
    }

    var body: some View {
        Button(role: role) {
            Haptics.light()
            action()
        } label: {
            SettingsRowContent(
                iconName: iconName,
                title: title,
                subtitle: subtitle,
                value: value,
                role: role,
                showsChevron: showsChevron
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(showsChevron ? "settings.row.hint".localized(defaultValue: "Double tap to open", table: "UI") : "")
    }

    private var accessibilityLabel: String {
        var parts = [title]
        if let subtitle, !subtitle.isEmpty { parts.append(subtitle) }
        if let value, !value.isEmpty { parts.append(value) }
        return parts.joined(separator: ", ")
    }
}

struct SettingsRowContent: View {
    let iconName: String
    let title: String
    let subtitle: String?
    let value: String?
    let trailingBadge: SettingsRowTrailingBadge?
    let role: ButtonRole?
    let showsChevron: Bool

    init(
        iconName: String,
        title: String,
        subtitle: String? = nil,
        value: String? = nil,
        trailingBadge: SettingsRowTrailingBadge? = nil,
        role: ButtonRole? = nil,
        showsChevron: Bool = false
    ) {
        self.iconName = iconName
        self.title = title
        self.subtitle = subtitle
        self.value = value
        self.trailingBadge = trailingBadge
        self.role = role
        self.showsChevron = showsChevron
    }

    private var accentColor: Color {
        role == .destructive ? .financialNegative : .accentPrimary
    }

    private var titleColor: Color {
        role == .destructive ? .financialNegative : .textPrimary
    }

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: iconName)
                .font(.body.weight(.medium))
                .foregroundColor(accentColor)
                .frame(width: 32, height: 32)
                .background(accentColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(title)
                    .bodyStyle(color: titleColor)
                    .fixedSize(horizontal: false, vertical: true)

                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .captionStyle()
                        .lineLimit(2)
                        .truncationMode(.middle)
                }
            }

            Spacer(minLength: Spacing.sm)

            if let value, !value.isEmpty {
                Text(value)
                    .bodyStyle(color: .textSecondary)
                    .multilineTextAlignment(.trailing)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            if trailingBadge == .premiumActive {
                PremiumBadge(variant: .active)
            }

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.textTertiary)
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .frame(minHeight: LayoutSpacing.rowHeight)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(accessibilityValue)
    }

    private var accessibilityLabel: String {
        if let subtitle, !subtitle.isEmpty {
            return "\(title), \(subtitle)"
        }
        return title
    }

    private var accessibilityValue: String {
        if let value, !value.isEmpty {
            return value
        }
        return ""
    }
}

struct SettingsDivider: View {
    var body: some View {
        Divider()
            .overlay(Color.dividerSubtle)
            .padding(.leading, 56)
    }
}

struct StatusBanner: View {
    let message: String
    let iconName: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Image(systemName: iconName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
                .accessibilityHidden(true)

            Text(message)
                .captionStyle(color: .textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(Spacing.md)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.badge, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.badge, style: .continuous)
                .stroke(color.opacity(0.25), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message)
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
}
