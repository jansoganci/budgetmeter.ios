//
//  PremiumPaywallView.swift
//  BudgetMeter
//
//  Premium paywall — v2 DesignSystem layout (calm premium fintech).
//

import SwiftUI

/// Premium paywall sheet — purchase, restore, and feature overview.
struct PremiumPaywallView: View {

    let feature: PremiumFeature?
    let onDismiss: () -> Void
    let onPurchase: () -> Void
    let onRestore: () -> Void

    @StateObject private var premiumManager = PremiumManager.shared
    @State private var showingRestoreAlert = false
    @State private var showingPurchaseAlert = false

    init(
        feature: PremiumFeature? = nil,
        onDismiss: @escaping () -> Void,
        onPurchase: @escaping () -> Void,
        onRestore: @escaping () -> Void
    ) {
        self.feature = feature
        self.onDismiss = onDismiss
        self.onPurchase = onPurchase
        self.onRestore = onRestore
    }

    var body: some View {
        NavigationView {
            ZStack {
                AppBackground()

                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: LayoutSpacing.sectionGap) {
                            heroSection
                            priceSection
                            featuresSection
                        }
                        .padding(.horizontal, LayoutSpacing.screenPadding)
                        .padding(.top, Spacing.md)
                        .padding(.bottom, Spacing.md)
                    }

                    bottomSection
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.body.weight(.medium))
                            .foregroundColor(.textSecondary)
                            .frame(width: TouchTarget.minimum, height: TouchTarget.minimum)
                    }
                    .accessibilityLabel(
                        String(localized: "premium.dismiss", defaultValue: "Close", table: "UI")
                    )
                }
            }
        }
        .alert(String(localized: "premium.restore.success", defaultValue: "Purchases Restored", table: "UI"), isPresented: $showingRestoreAlert) {
            Button(String(localized: "premium.ok", defaultValue: "OK", table: "UI")) { }
        } message: {
            Text(String(localized: "premium.restore.success.message", defaultValue: "Your previous purchases have been restored successfully.", table: "UI"))
        }
        .alert(String(localized: "premium.purchase.success", defaultValue: "Welcome to Premium!", table: "UI"), isPresented: $showingPurchaseAlert) {
            Button(String(localized: "premium.ok", defaultValue: "OK", table: "UI")) { }
        } message: {
            Text(String(localized: "premium.purchase.success.message", defaultValue: "Thank you for upgrading to BudgetMeter Premium!", table: "UI"))
        }
    }

    // MARK: - Hero (Pulsey slot + value proposition)

    private var heroSection: some View {
        GlassCard {
            VStack(spacing: LayoutSpacing.cardInternalGap) {
                PremiumBadge(locked: false)

                HStack {
                    Spacer(minLength: 0)
                    pulseyHeroSlot
                    Spacer(minLength: 0)
                }

                VStack(spacing: Spacing.xs) {
                    Text(String(localized: "premium.header.title", defaultValue: "Make BudgetMeter yours", table: "UI"))
                        .sectionTitleStyle()
                        .multilineTextAlignment(.center)

                    Text(String(
                        localized: "premium.header.subtitle",
                        defaultValue: "Continue with themes, widgets, and deeper insights.",
                        table: "UI"
                    ))
                    .bodyStyle(color: .textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    /// Reserved hero slot for future Pulsey mascot — no assets in this phase.
    private var pulseyHeroSlot: some View {
        RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous)
            .fill(Color.surfaceInset.opacity(0.45))
            .frame(width: 80, height: 80)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous)
                    .stroke(Color.borderSubtle, lineWidth: 1)
            )
            .accessibilityHidden(true)
    }

    // MARK: - Price

    private var priceSection: some View {
        GlassCard {
            VStack(spacing: Spacing.sm) {
                Text(displayPrice)
                    .heroMetricStyle(color: .accentPrimary)

                Text(String(localized: "premium.price.subtitle", defaultValue: "One-time purchase • Lifetime access", table: "UI"))
                    .captionStyle(color: .textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var displayPrice: String {
        premiumManager.premiumDisplayPrice ?? String(localized: "premium.price", defaultValue: "$4.99", table: "UI")
    }

    // MARK: - Features

    private var featuresSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: LayoutSpacing.cardInternalGap) {
                SectionHeader(
                    title: String(localized: "premium.features.title", defaultValue: "Everything included", table: "UI")
                )

                VStack(spacing: Spacing.sm) {
                    ForEach(PremiumFeature.allCases, id: \.self) { premiumFeature in
                        featureRow(premiumFeature)
                    }
                }
            }
        }
    }

    private func featureRow(_ feature: PremiumFeature) -> some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: feature.iconName)
                .font(.body.weight(.medium))
                .foregroundColor(.accentPrimary)
                .frame(width: 32, height: 32)
                .background(Color.accentPrimary.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(feature.displayName)
                    .cardLabelStyle(color: .textPrimary)

                Text(feature.description)
                    .captionStyle(color: .textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, Spacing.xs)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(feature.displayName). \(feature.description)")
    }

    // MARK: - Bottom CTA

    private var bottomSection: some View {
        VStack(spacing: Spacing.md) {
            if let errorMessage = premiumManager.errorMessage {
                Text(errorMessage)
                    .captionStyle(color: .financialNegative)
                    .multilineTextAlignment(.center)
            }

            PrimaryCTAButton(
                title: String(localized: "premium.purchase.button", defaultValue: "Upgrade to Premium", table: "UI"),
                isLoading: premiumManager.isLoading,
                action: handlePurchase
            )

            SecondaryCTAButton(
                title: String(localized: "premium.restore.button", defaultValue: "Restore Purchases", table: "UI"),
                action: handleRestore
            )
            .disabled(premiumManager.isLoading)

            HStack(spacing: Spacing.lg) {
                Button(String(localized: "premium.terms.link", defaultValue: "Terms", table: "UI")) {
                    // Open terms
                }
                .font(.caption)
                .foregroundColor(.textTertiary)

                Text("•")
                    .font(.caption)
                    .foregroundColor(.textTertiary)
                    .accessibilityHidden(true)

                Button(String(localized: "premium.privacy.link", defaultValue: "Privacy", table: "UI")) {
                    // Open privacy policy
                }
                .font(.caption)
                .foregroundColor(.textTertiary)
            }
        }
        .padding(.horizontal, LayoutSpacing.screenPadding)
        .padding(.top, Spacing.md)
        .padding(.bottom, Spacing.xl)
        .background(AppBackground(ignoresSafeArea: false))
        .overlay(alignment: .top) {
            Divider()
                .background(Color.borderSubtle)
        }
    }

    // MARK: - Actions

    private func handlePurchase() {
        Task {
            await premiumManager.purchasePremium()
            if premiumManager.isPremium {
                showingPurchaseAlert = true
                onPurchase()
            }
        }
    }

    private func handleRestore() {
        Task {
            await premiumManager.restorePurchases()
            if premiumManager.isPremium {
                showingRestoreAlert = true
                onRestore()
            }
        }
    }
}

#Preview("Paywall") {
    PremiumPaywallView(
        feature: .customCategories,
        onDismiss: { },
        onPurchase: { },
        onRestore: { }
    )
}

#Preview("Dark Mode") {
    PremiumPaywallView(
        feature: nil,
        onDismiss: { },
        onPurchase: { },
        onRestore: { }
    )
    .preferredColorScheme(.dark)
}
