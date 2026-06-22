//
//  AccountBackupSettingsView.swift
//  BudgetMeter
//
//  Account, sign-in, account sync, and premium manual backup controls.
//

import SwiftUI

struct AccountBackupSettingsView: View {

    @StateObject private var authService = AuthService.shared
    @StateObject private var backupService = BackupService.shared
    @StateObject private var premiumManager = PremiumManager.shared

    @State private var cloudSummary: CloudBackupSummary?
    @State private var firstSignInScenario: FirstSignInScenario?
    @State private var showingRestoreConfirm = false
    @State private var showingDeleteAccountConfirm = false
    @State private var showingPremiumPaywall = false
    @State private var statusMessage: String?

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: LayoutSpacing.sectionGap) {
                    accountSection
                    syncSection
                    backupSection
                    if authService.isAuthenticated {
                        dangerSection
                    }

                    if let statusMessage {
                        StatusBanner(message: statusMessage, iconName: "checkmark.circle.fill", color: .financialPositive)
                            .accessibilityLabel(statusMessage)
                    }

                    if let error = authService.errorMessage ?? backupService.syncState.lastErrorMessage {
                        StatusBanner(message: error, iconName: "xmark.octagon.fill", color: .financialNegative)
                            .accessibilityLabel(error)
                    }
                }
                .padding(.horizontal, LayoutSpacing.screenPadding)
                .padding(.vertical, Spacing.md)
            }
        }
        .navigationTitle("account.title".localized(defaultValue: "Account", table: "UI"))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await refreshCloudState()
        }
        .alert(
            "backup.restore.confirm.title".localized(defaultValue: "Restore Manual Backup", table: "UI"),
            isPresented: $showingRestoreConfirm
        ) {
            Button("common.cancel".localized(defaultValue: "Cancel", table: "UI"), role: .cancel) { }
            Button("backup.restore.confirm.action".localized(defaultValue: "Restore", table: "UI"), role: .destructive) {
                Task { await restoreConfirmed() }
            }
        } message: {
            Text("backup.restore.confirm.message".localized(defaultValue: "This replaces local data on this device with your manual backup.", table: "UI"))
        }
        .alert(
            "account.delete.title".localized(defaultValue: "Delete Account", table: "UI"),
            isPresented: $showingDeleteAccountConfirm
        ) {
            Button("common.cancel".localized(defaultValue: "Cancel", table: "UI"), role: .cancel) { }
            Button("account.delete.confirm".localized(defaultValue: "Delete", table: "UI"), role: .destructive) {
                Task { await deleteAccount() }
            }
        } message: {
            Text("account.delete.message".localized(defaultValue: "This permanently deletes your account and synced data on our servers. Data on this device stays unless you reset it separately in Settings.", table: "UI"))
        }
        .sheet(isPresented: $showingPremiumPaywall) {
            PremiumPaywallView(
                feature: nil,
                onDismiss: { showingPremiumPaywall = false },
                onPurchase: { showingPremiumPaywall = false },
                onRestore: { showingPremiumPaywall = false }
            )
        }
    }

    private var accountSection: some View {
        SettingsSection(
            title: "account.section.title".localized(defaultValue: "Account", table: "UI"),
            footer: "account.footer".localized(defaultValue: "Sign in is free and syncs your data to your account. Manual backup & restore is a Premium feature.", table: "UI")
        ) {
            if authService.isAuthenticated {
                SettingsRowContent(
                    iconName: "person.crop.circle.fill",
                    title: "account.signed_in".localized(defaultValue: "Signed in", table: "UI"),
                    subtitle: accountIdentifier,
                    showsChevron: false
                )

                SettingsDivider()

                SettingsActionRow(
                    iconName: "rectangle.portrait.and.arrow.right",
                    title: "account.sign_out".localized(defaultValue: "Sign Out", table: "UI"),
                    role: .destructive,
                    showsChevron: false
                ) {
                    Task { await signOut() }
                }
            } else {
                SettingsRowContent(
                    iconName: "person.crop.circle",
                    title: "account.sign_in_prompt".localized(defaultValue: "Sign in to sync your account data.", table: "UI"),
                    subtitle: "account.footer".localized(defaultValue: "Sign in is free and syncs your data to your account. Manual backup & restore is a Premium feature.", table: "UI"),
                    showsChevron: false
                )
            }
        }
    }

    private var syncSection: some View {
        SettingsSection(
            title: "sync.section.title".localized(defaultValue: "Account Sync", table: "UI"),
            footer: authService.isAuthenticated
                ? "sync.footer.signed_in".localized(defaultValue: "When you sign in, your BudgetMeter data syncs securely to your account. Sync runs after sign-in and when you make changes. It may take a moment to appear on another device.", table: "UI")
                : "sync.footer.signed_out".localized(defaultValue: "Sign in to save your settings and financial data to your account and use it on another device.", table: "UI")
        ) {
            if authService.isAuthenticated {
                SettingsRowContent(
                    iconName: "arrow.triangle.2.circlepath",
                    title: "sync.status.active".localized(defaultValue: "Sync enabled for your account", table: "UI"),
                    subtitle: "sync.status.detail".localized(defaultValue: "Updates when you sign in or save changes", table: "UI"),
                    showsChevron: false
                )
            } else {
                SettingsRowContent(
                    iconName: "arrow.triangle.2.circlepath",
                    title: "account.sign_in_prompt".localized(defaultValue: "Sign in to sync your account data.", table: "UI"),
                    showsChevron: false
                )
            }
        }
    }

    private var backupSection: some View {
        SettingsSection(
            title: "backup.section.title".localized(defaultValue: "Manual Backup & Restore", table: "UI"),
            footer: "backup.footer".localized(defaultValue: "Optional full-device snapshot for advanced recovery. This is separate from everyday account sync. Local data is snapshotted before backup or restore.", table: "UI")
        ) {
            if !premiumManager.hasAccess(to: .backupSync) {
                SettingsActionRow(
                    iconName: "crown.fill",
                    title: "backup.premium_required".localized(defaultValue: "Upgrade for Manual Backup & Restore", table: "UI")
                ) {
                    showingPremiumPaywall = true
                }
            } else if !authService.isAuthenticated {
                SettingsRowContent(
                    iconName: "icloud.slash",
                    title: "backup.sign_in_required".localized(defaultValue: "Sign in to use manual backup & restore.", table: "UI"),
                    showsChevron: false
                )
            } else {
                if let scenario = firstSignInScenario, scenario == .overlap {
                    StatusBanner(
                        message: "backup.overlap.message".localized(defaultValue: "This device and your manual backup both contain data. Choose backup or restore carefully.", table: "UI"),
                        iconName: "exclamationmark.triangle.fill",
                        color: .financialCaution
                    )
                    .padding(Spacing.md)

                    SettingsDivider()
                }

                if let lastBackup = backupService.syncState.lastBackupDate {
                    SettingsRowContent(
                        iconName: "clock.arrow.circlepath",
                        title: String(format: "backup.last_backup".localized(defaultValue: "Last backup: %@", table: "UI"), formattedDate(lastBackup)),
                        showsChevron: false
                    )
                } else {
                    SettingsRowContent(
                        iconName: "clock",
                        title: "backup.never".localized(defaultValue: "No manual backup yet", table: "UI"),
                        showsChevron: false
                    )
                }

                if let cloudSummary {
                    SettingsDivider()

                    SettingsRowContent(
                        iconName: "icloud.fill",
                        title: String(format: "backup.cloud_summary".localized(defaultValue: "Manual backup: %lld records, %@", table: "UI"), cloudSummary.recordCount, formattedDate(cloudSummary.updatedAt)),
                        showsChevron: false
                    )
                }

                SettingsDivider()

                SettingsActionRow(
                    iconName: "icloud.and.arrow.up",
                    title: "backup.now".localized(defaultValue: "Back Up Now", table: "UI"),
                    showsChevron: false
                ) {
                    Task { await backupNow() }
                }
                .disabled(authService.isLoading || backupService.syncState.status == .backingUp)

                SettingsDivider()

                SettingsActionRow(
                    iconName: "icloud.and.arrow.down",
                    title: "backup.restore".localized(defaultValue: "Restore Manual Backup", table: "UI"),
                    showsChevron: false
                ) {
                    showingRestoreConfirm = true
                }
                .disabled(authService.isLoading || backupService.syncState.status == .restoring || cloudSummary == nil)
            }
        }
    }

    private var dangerSection: some View {
        SettingsSection {
            SettingsActionRow(
                iconName: "trash",
                title: "account.delete.title".localized(defaultValue: "Delete Account", table: "UI"),
                role: .destructive,
                showsChevron: false
            ) {
                showingDeleteAccountConfirm = true
            }
        }
    }

    private var accountIdentifier: String? {
        if let email = authService.currentEmail, !email.isEmpty {
            return email
        }
        return authService.currentUserID
    }

    private func formattedDate(_ date: Date) -> String {
        DateFormattingHelper.shared.formatMedium(date)
    }

    private func refreshCloudState() async {
        guard authService.isAuthenticated else { return }
        cloudSummary = try? await backupService.fetchCloudBackupSummary(userID: authService.currentUserID)
        let evaluation = backupService.evaluateFirstSignIn(
            isSignedIn: authService.isAuthenticated,
            cloudBackup: cloudSummary,
            cloudKitAvailable: PersistenceService.shared.isCloudKitAvailable
        )
        firstSignInScenario = evaluation.0
        backupService.markFirstSignInCompleted()
    }

    private func signOut() async {
        await authService.signOut()
        cloudSummary = nil
        firstSignInScenario = nil
        statusMessage = authService.errorMessage
            ?? "account.sign_out_success".localized(defaultValue: "Signed out.", table: "UI")
    }

    private func backupNow() async {
        do {
            try await backupService.backupNow(
                isPremium: premiumManager.hasAccess(to: .backupSync),
                userID: authService.currentUserID
            )
            statusMessage = "backup.success".localized(defaultValue: "Backup completed.", table: "UI")
            await refreshCloudState()
        } catch {
            statusMessage = (error as? Foundation.LocalizedError)?.errorDescription ?? BackupServiceError.backupFailed.errorDescription
        }
    }

    private func restoreConfirmed() async {
        do {
            try await backupService.restoreFromCloud(
                isPremium: premiumManager.hasAccess(to: .backupSync),
                userID: authService.currentUserID,
                confirmedOverwrite: true
            )
            statusMessage = "backup.restore.success".localized(defaultValue: "Restore completed.", table: "UI")
            await refreshCloudState()
        } catch {
            statusMessage = (error as? Foundation.LocalizedError)?.errorDescription ?? BackupServiceError.restoreFailed.errorDescription
        }
    }

    private func deleteAccount() async {
        do {
            try await authService.deleteAccount()
            cloudSummary = nil
            statusMessage = "account.delete.success".localized(defaultValue: "Account deleted.", table: "UI")
        } catch {
            statusMessage = authService.errorMessage
        }
    }
}
