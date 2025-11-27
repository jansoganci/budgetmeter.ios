//
//  PremiumPaywallView.swift
//  BudgetMeter
//
//  Created by BudgetMeter Team on 17.09.2025.
//

import SwiftUI

/// Premium paywall view - compact and effective design
struct PremiumPaywallView: View {

    // MARK: - Properties

    let feature: PremiumFeature?
    let onDismiss: () -> Void
    let onPurchase: () -> Void
    let onRestore: () -> Void

    @StateObject private var premiumManager = PremiumManager.shared
    @State private var showingRestoreAlert = false
    @State private var showingPurchaseAlert = false

    // MARK: - Initialization

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

    // MARK: - Body

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        // Header with crown
                        headerSection

                        // Price card
                        priceCard

                        // Compact features list
                        featuresSection
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.lg)
                    .padding(.bottom, Spacing.md)
                }

                // Fixed bottom section with buttons
                bottomSection
            }
            .background(Color.appBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .alert("premium.restore.success".localized(defaultValue: "Purchases Restored"), isPresented: $showingRestoreAlert) {
            Button("premium.ok".localized(defaultValue: "OK")) { }
        } message: {
            Text("premium.restore.success.message".localized(defaultValue: "Your previous purchases have been restored successfully."))
        }
        .alert("premium.purchase.success".localized(defaultValue: "Welcome to Premium!"), isPresented: $showingPurchaseAlert) {
            Button("premium.ok".localized(defaultValue: "OK")) { }
        } message: {
            Text("premium.purchase.success.message".localized(defaultValue: "Thank you for upgrading to BudgetMeter Premium!"))
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: Spacing.md) {
            // Crown Icon
            Image(systemName: "crown.fill")
                .font(.system(size: 56, weight: .medium))
                .foregroundColor(.orange)

            // Title
            Text("premium.header.title".localized(defaultValue: "BudgetMeter Premium"))
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
        }
        .padding(.top, Spacing.md)
    }

    // MARK: - Price Card

    private var priceCard: some View {
        VStack(spacing: Spacing.sm) {
            // Price
            Text("premium.price".localized(defaultValue: "$4.99"))
                .font(.system(size: 44, weight: .bold))
                .foregroundColor(.brandProgress)

            // One-time purchase emphasis
            Text("premium.price.subtitle".localized(defaultValue: "One-time purchase • Lifetime access"))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.brandPositive)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.lg)
        .background(Color.cardBackground)
        .cornerRadius(CornerRadius.card)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.card)
                .stroke(Color.brandProgress.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Features Section

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("premium.features.title".localized(defaultValue: "Everything included:"))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .padding(.bottom, Spacing.xs)

            ForEach(PremiumFeature.allCases, id: \.self) { premiumFeature in
                featureRow(premiumFeature)
            }
        }
        .padding(Spacing.lg)
        .background(Color.cardBackground)
        .cornerRadius(CornerRadius.card)
    }

    private func featureRow(_ feature: PremiumFeature) -> some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .font(.body)
                .foregroundColor(.brandPositive)

            Text(feature.displayName)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.primary)

            Spacer()
        }
        .padding(.vertical, Spacing.xs)
    }

    // MARK: - Bottom Section (Fixed)

    private var bottomSection: some View {
        VStack(spacing: Spacing.md) {
            // Error Message
            if let errorMessage = premiumManager.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.brandExpense)
                    .multilineTextAlignment(.center)
            }

            // Purchase Button
            Button(action: handlePurchase) {
                HStack(spacing: Spacing.sm) {
                    if premiumManager.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "crown.fill")
                            .font(.body)
                    }

                    Text("premium.purchase.button".localized(defaultValue: "Upgrade to Premium"))
                        .font(.headline)
                        .fontWeight(.bold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Color.brandProgress)
                .cornerRadius(CornerRadius.button)
            }
            .disabled(premiumManager.isLoading)

            // Restore Button
            Button(action: handleRestore) {
                Text("premium.restore.button".localized(defaultValue: "Restore Purchases"))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.brandProgress)
            }
            .disabled(premiumManager.isLoading)

            // Terms & Privacy
            HStack(spacing: Spacing.lg) {
                Button("premium.terms.link".localized(defaultValue: "Terms")) {
                    // Open terms
                }
                .font(.caption)
                .foregroundColor(.secondary)

                Text("•")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Button("premium.privacy.link".localized(defaultValue: "Privacy")) {
                    // Open privacy policy
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.md)
        .padding(.bottom, Spacing.xl)
        .background(
            Color.cardBackground
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: -4)
        )
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

// MARK: - Preview

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
