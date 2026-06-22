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
    @Environment(\.themeAccent) private var themeAccent
    
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
            if premiumManager.hasAccess(to: premiumFeature) {
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
        ZStack {
            Color.surfaceObsidian.ignoresSafeArea()

            VStack(spacing: Spacing.lg) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 44, weight: .medium))
                    .foregroundColor(.textSecondary)

                Text(String(localized: "premium.gated.title", defaultValue: "Premium Feature", table: "UI"))
                    .sectionTitleStyle()
                    .multilineTextAlignment(.center)

                Text(String(
                    localized: "premium.gated.description",
                    defaultValue: "Unlock themes, widgets, and deeper insights with Premium.",
                    table: "UI"
                ))
                .bodyStyle(color: .textSecondary)
                .multilineTextAlignment(.center)

                Text(premiumFeature.displayName)
                    .cardLabelStyle(color: .textPrimary)

                Button(action: {
                    showingPaywall = true
                }) {
                    Text(String(localized: "premium.gated.upgrade", defaultValue: "Upgrade to Premium", table: "UI"))
                        .buttonTextStyle(color: .white)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: TouchTarget.minimum)
                        .background(themeAccent)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.button, style: .continuous))
                }
            }
            .padding(Spacing.lg)
            .glassSurface()
            .padding(LayoutSpacing.screenPadding)
        }
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
    @Environment(\.themeAccent) private var themeAccent
    
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
                
                if !premiumManager.hasAccess(to: premiumFeature) {
                    Spacer()
                    
                    Image(systemName: "crown.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(themeAccent)
                }
            }
            .foregroundColor(.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color.surfaceInset)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.button, style: .continuous))
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
        if premiumManager.hasAccess(to: premiumFeature) {
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
    @Environment(\.themeAccent) private var themeAccent
    
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
            if premiumManager.hasAccess(to: premiumFeature) {
                // Feature is available
            } else {
                showingPaywall = true
            }
        }) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: iconName)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(themeAccent)
                    .frame(width: 32, height: 32)
                    .background(themeAccent.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous))
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .cardLabelStyle(color: .textPrimary)
                    
                    Text(subtitle)
                        .captionStyle()
                }
                
                Spacer()
                
                // Premium Indicator
                if !premiumManager.hasAccess(to: premiumFeature) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(themeAccent)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.financialPositive)
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
