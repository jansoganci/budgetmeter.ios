//
//  PremiumPaywallView.swift
//  BudgetMeter
//
//  Created by BudgetMeter Team on 17.09.2025.
//

import SwiftUI

/// Premium paywall view following Apple HIG and design rulebook
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
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Features List
                    featuresSection
                    
                    // Purchase Button
                    purchaseSection
                    
                    // Footer
                    footerSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .navigationTitle("premium.title".localized(defaultValue: "BudgetMeter Premium"))
            .navigationBarTitleDisplayMode(.large)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("premium.close".localized(defaultValue: "Close")) {
                        onDismiss()
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
        VStack(spacing: 16) {
            // Crown Icon
            Image(systemName: "crown.fill")
                .font(.system(size: 48, weight: .medium))
                .foregroundColor(Color(hex: "4A90E2"))
            
            // Title
            Text("premium.header.title".localized(defaultValue: "Unlock Premium Features"))
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            // Subtitle
            Text("premium.header.subtitle".localized(defaultValue: "Get the most out of BudgetMeter with powerful premium features"))
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }
    
    // MARK: - Features Section
    
    private var featuresSection: some View {
        VStack(spacing: 16) {
            ForEach(PremiumFeature.allCases, id: \.self) { premiumFeature in
                FeatureRowView(feature: premiumFeature)
            }
        }
    }
    
    // MARK: - Purchase Section
    
    private var purchaseSection: some View {
        VStack(spacing: 16) {
            // Price
            VStack(spacing: 4) {
                Text("premium.price".localized(defaultValue: "$4.99"))
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "4A90E2"))
                
                Text("premium.price.subtitle".localized(defaultValue: "One-time purchase • Lifetime access"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Purchase Button
            Button(action: handlePurchase) {
                HStack {
                    if premiumManager.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 16, weight: .medium))
                    }
                    
                    Text("premium.purchase.button".localized(defaultValue: "Upgrade to Premium"))
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color(hex: "4A90E2"))
                .cornerRadius(12)
            }
            .disabled(premiumManager.isLoading)
            
            // Restore Button
            Button(action: handleRestore) {
                Text("premium.restore.button".localized(defaultValue: "Restore Purchases"))
                    .font(.subheadline)
                    .foregroundColor(Color(hex: "4A90E2"))
            }
            .disabled(premiumManager.isLoading)
        }
        .padding(.top, 8)
    }
    
    // MARK: - Footer Section
    
    private var footerSection: some View {
        VStack(spacing: 12) {
            // Error Message
            if let errorMessage = premiumManager.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
            
            // Terms
            VStack(spacing: 4) {
                Text("premium.terms".localized(defaultValue: "By purchasing, you agree to our Terms of Service and Privacy Policy"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                HStack(spacing: 16) {
                    Button("premium.terms.link".localized(defaultValue: "Terms")) {
                        // Open terms
                    }
                    .font(.caption)
                    .foregroundColor(Color(hex: "4A90E2"))
                    
                    Button("premium.privacy.link".localized(defaultValue: "Privacy")) {
                        // Open privacy policy
                    }
                    .font(.caption)
                    .foregroundColor(Color(hex: "4A90E2"))
                }
            }
        }
        .padding(.top, 16)
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

// MARK: - Feature Row View

struct FeatureRowView: View {
    let feature: PremiumFeature
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: feature.iconName)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(Color(hex: "4A90E2"))
                .frame(width: 32, height: 32)
                .background(Color(hex: "4A90E2").opacity(0.1))
                .cornerRadius(8)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(feature.displayName)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(feature.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Preview

#Preview {
    PremiumPaywallView(
        feature: .customCategories,
        onDismiss: { },
        onPurchase: { },
        onRestore: { }
    )
}
