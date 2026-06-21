//
//  PremiumThemesView.swift
//  BudgetMeter
//
//  Premium theme picker — v2 layout with shared DesignSystem surfaces.
//

import SwiftUI

struct PremiumThemesView: View {
    @StateObject private var premiumManager = PremiumManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    @State private var selectedTheme: AppTheme = .coral_default
    @State private var showSuccessAlert = false
    @State private var showingPaywall = false

    private var canApplySelectedTheme: Bool {
        !selectedTheme.requiresPremium || premiumManager.hasAccess(to: BudgetMeterCapability.premiumThemes)
    }

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: LayoutSpacing.sectionGap) {
                    SectionHeader(
                        title: "theme.premium.title".localized(defaultValue: "Premium Themes", table: "UI"),
                        subtitle: "theme.premium.subtitle".localized(defaultValue: "Choose from beautiful color themes to personalize your BudgetMeter experience.", table: "UI")
                    )

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.lg) {
                        ForEach(AppTheme.allThemes, id: \.rawValue) { theme in
                            ThemeCard(
                                theme: theme,
                                isSelected: selectedTheme == theme,
                                isCurrent: themeManager.currentTheme == theme,
                                requiresPremium: theme.requiresPremium,
                                onSelect: { selectedTheme = theme }
                            )
                        }
                    }

                    if themeManager.currentTheme == selectedTheme {
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.financialPositive)
                            Text("theme.currently_active".localized(defaultValue: "Currently Active", table: "UI"))
                                .captionStyle(color: .textSecondary)
                        }
                    }

                    PrimaryCTAButton(
                        title: canApplySelectedTheme
                            ? "theme.apply".localized(defaultValue: "Apply Theme", table: "UI")
                            : "theme.unlock_premium".localized(defaultValue: "Unlock Premium Theme", table: "UI"),
                        isDisabled: themeManager.currentTheme == selectedTheme,
                        action: applyTheme
                    )
                }
                .padding(.horizontal, LayoutSpacing.screenPadding)
                .padding(.vertical, Spacing.md)
            }
        }
        .navigationTitle("theme.nav.title".localized(defaultValue: "Themes", table: "UI"))
        .navigationBarTitleDisplayMode(.inline)
        .alert("theme.applied.title".localized(defaultValue: "Theme Applied!", table: "UI"), isPresented: $showSuccessAlert) {
            Button("alert.ok".localized(defaultValue: "OK", table: "UI"), role: .cancel) { }
        } message: {
            Text(String(format: "theme.applied.message".localized(defaultValue: "%@ theme has been applied successfully!", table: "UI"), selectedTheme.displayName))
        }
        .sheet(isPresented: $showingPaywall) {
            PremiumPaywallView(
                feature: .premiumThemes,
                onDismiss: { showingPaywall = false },
                onPurchase: { showingPaywall = false },
                onRestore: { showingPaywall = false }
            )
        }
        .onAppear {
            selectedTheme = themeManager.currentTheme
        }
    }

    private func applyTheme() {
        guard canApplySelectedTheme else {
            showingPaywall = true
            return
        }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            themeManager.applyTheme(selectedTheme)
            showSuccessAlert = true
        }

        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

struct ThemeCard: View {
    let theme: AppTheme
    let isSelected: Bool
    let isCurrent: Bool
    let requiresPremium: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: Spacing.md) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: theme.gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)

                    Image(systemName: theme.icon)
                        .font(.system(size: 28))
                        .foregroundColor(.white)

                    if requiresPremium {
                        Image(systemName: "crown.fill")
                            .font(.caption2)
                            .foregroundColor(.white)
                            .padding(4)
                            .background(Color.black.opacity(0.25))
                            .clipShape(Circle())
                            .offset(x: 22, y: -22)
                    }
                }

                Text(theme.displayName)
                    .cardLabelStyle(color: .textPrimary)

                if isCurrent {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption2)
                        Text("theme.active".localized(defaultValue: "Active", table: "UI"))
                            .font(.caption2)
                    }
                    .foregroundColor(.financialPositive)
                }
            }
            .frame(height: CardHeight.medium)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous)
                    .fill(theme.primaryColor.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous)
                            .stroke(
                                isSelected ? theme.primaryColor : Color.clear,
                                lineWidth: 3
                            )
                    )
            )
            .shadow(
                color: isSelected ? theme.primaryColor.opacity(0.3) : Color.clear,
                radius: 8,
                x: 0,
                y: 4
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

#Preview {
    NavigationStack {
        PremiumThemesView()
    }
}
