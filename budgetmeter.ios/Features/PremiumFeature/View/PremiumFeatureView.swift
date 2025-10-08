//
//  PremiumFeatureView.swift
//  BudgetMeter
//
//  Created by BudgetMeter Team on 17.09.2025.
//

import SwiftUI

/// Wrapper view that gates premium features behind paywall
struct PremiumFeatureView<Content: View>: View {
    
    // MARK: - Properties
    
    let content: Content
    let premiumFeature: PremiumFeature
    let onDismiss: () -> Void
    
    @StateObject private var premiumManager = PremiumManager.shared
    @State private var showingPaywall = false
    
    // MARK: - Initialization
    
    init(
        premiumFeature: PremiumFeature,
        onDismiss: @escaping () -> Void = {},
        @ViewBuilder content: () -> Content
    ) {
        self.premiumFeature = premiumFeature
        self.onDismiss = onDismiss
        self.content = content()
    }
    
    // MARK: - Body
    
    var body: some View {
        Group {
            if premiumManager.isPremium {
                content
            } else {
                premiumGatedView
            }
        }
        .sheet(isPresented: $showingPaywall) {
            PremiumPaywallView(
                feature: premiumFeature,
                onDismiss: {
                    showingPaywall = false
                    onDismiss()
                },
                onPurchase: {
                    showingPaywall = false
                },
                onRestore: {
                    showingPaywall = false
                }
            )
        }
    }
    
    // MARK: - Premium Gated View
    
    private var premiumGatedView: some View {
        VStack(spacing: 16) {
            // Icon
            Image(systemName: premiumFeature.iconName)
                .font(.system(size: 48, weight: .medium))
                .foregroundColor(Color(hex: "4A90E2"))
            
            // Title
            Text("premium.gated.title".localized(defaultValue: "Premium Feature"))
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            // Description
            Text("premium.gated.description".localized(defaultValue: "This feature is available with BudgetMeter Premium"))
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            // Feature Name
            Text(premiumFeature.displayName)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(Color(hex: "4A90E2"))
            
            // Upgrade Button
            Button(action: {
                showingPaywall = true
            }) {
                HStack {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 16, weight: .medium))
                    
                    Text("premium.gated.upgrade".localized(defaultValue: "Upgrade to Premium"))
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color(hex: "4A90E2"))
                .cornerRadius(12)
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
        .background(Color(uiColor: .systemBackground))
    }
}

// MARK: - Premium Feature Button

struct PremiumFeatureButton: View {
    
    // MARK: - Properties
    
    let title: String
    let iconName: String
    let premiumFeature: PremiumFeature
    let action: () -> Void
    let onDismiss: () -> Void
    
    @StateObject private var premiumManager = PremiumManager.shared
    @State private var showingPaywall = false
    
    // MARK: - Initialization
    
    init(
        title: String,
        iconName: String,
        premiumFeature: PremiumFeature,
        onDismiss: @escaping () -> Void = {},
        action: @escaping () -> Void
    ) {
        self.title = title
        self.iconName = iconName
        self.premiumFeature = premiumFeature
        self.onDismiss = onDismiss
        self.action = action
    }
    
    // MARK: - Body
    
    var body: some View {
        Button(action: handleTap) {
            HStack {
                Image(systemName: iconName)
                    .font(.system(size: 16, weight: .medium))
                
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                
                if !premiumManager.isPremium {
                    Spacer()
                    
                    Image(systemName: "crown.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(hex: "4A90E2"))
                }
            }
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color(uiColor: .secondarySystemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingPaywall) {
            PremiumPaywallView(
                feature: premiumFeature,
                onDismiss: {
                    showingPaywall = false
                    onDismiss()
                },
                onPurchase: {
                    showingPaywall = false
                },
                onRestore: {
                    showingPaywall = false
                }
            )
        }
    }
    
    // MARK: - Actions
    
    private func handleTap() {
        if premiumManager.isPremium {
            action()
        } else {
            showingPaywall = true
        }
    }
}

// MARK: - Premium Feature Row

struct PremiumFeatureRow: View {
    
    // MARK: - Properties
    
    let title: String
    let subtitle: String
    let iconName: String
    let premiumFeature: PremiumFeature
    let onDismiss: () -> Void
    
    @StateObject private var premiumManager = PremiumManager.shared
    @State private var showingPaywall = false
    
    // MARK: - Initialization
    
    init(
        title: String,
        subtitle: String,
        iconName: String,
        premiumFeature: PremiumFeature,
        onDismiss: @escaping () -> Void = {}
    ) {
        self.title = title
        self.subtitle = subtitle
        self.iconName = iconName
        self.premiumFeature = premiumFeature
        self.onDismiss = onDismiss
    }
    
    // MARK: - Body
    
    var body: some View {
        Button(action: {
            if premiumManager.isPremium {
                // Feature is available
            } else {
                showingPaywall = true
            }
        }) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: iconName)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(Color(hex: "4A90E2"))
                    .frame(width: 32, height: 32)
                    .background(Color(hex: "4A90E2").opacity(0.1))
                    .cornerRadius(8)
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Premium Indicator
                if !premiumManager.isPremium {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(hex: "4A90E2"))
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.green)
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingPaywall) {
            PremiumPaywallView(
                feature: premiumFeature,
                onDismiss: {
                    showingPaywall = false
                    onDismiss()
                },
                onPurchase: {
                    showingPaywall = false
                },
                onRestore: {
                    showingPaywall = false
                }
            )
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        PremiumFeatureView(premiumFeature: .customCategories) {
            Text("Premium content here")
        }
        
        PremiumFeatureButton(
            title: "Custom Categories",
            iconName: "tag.fill",
            premiumFeature: .customCategories
        ) {
            print("Button tapped")
        }
        
        PremiumFeatureRow(
            title: "Custom Categories",
            subtitle: "Create unlimited custom categories",
            iconName: "tag.fill",
            premiumFeature: .customCategories
        )
    }
    .padding()
}
