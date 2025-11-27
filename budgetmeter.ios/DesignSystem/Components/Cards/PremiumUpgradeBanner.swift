//
//  PremiumUpgradeBanner.swift
//  BudgetMeter
//
//  Attractive banner for non-premium users to encourage upgrade
//

import SwiftUI

/// Premium upgrade banner with brand colors and CTA
struct PremiumUpgradeBanner: View {

    // MARK: - Properties

    let onUpgradeTapped: () -> Void

    // Feature highlights to show
    private let featureHighlights = [
        "premium.banner.feature.subscriptions".localized(defaultValue: "Subscription tracking"),
        "premium.banner.feature.bills".localized(defaultValue: "Bill reminders"),
        "premium.banner.feature.savings".localized(defaultValue: "Savings goals")
    ]

    // MARK: - Body

    var body: some View {
        Button(action: {
            Haptics.medium()
            onUpgradeTapped()
        }) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                // Header with crown icon
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.orange)

                    Text("premium.banner.title".localized(defaultValue: "Unlock Premium"))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Spacer()
                }

                // Subtitle with feature count
                Text("premium.banner.subtitle".localized(defaultValue: "Get access to all 9 powerful features:"))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)

                // Feature list
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    ForEach(featureHighlights, id: \.self) { feature in
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.subheadline)
                                .foregroundColor(.brandPositive)
                            Text(feature)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                        }
                    }

                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.subheadline)
                            .foregroundColor(.brandPositive)
                        Text("premium.banner.feature.more".localized(defaultValue: "And 6 more..."))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                }

                // One-time purchase highlight
                Text("premium.banner.onetime".localized(defaultValue: "One-time purchase. No subscription."))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.brandPositive)
                    .padding(.top, Spacing.xs)

                // CTA Button with price
                HStack {
                    Spacer()

                    VStack(spacing: 2) {
                        Text("premium.banner.cta".localized(defaultValue: "Upgrade Now"))
                            .font(.headline)
                            .fontWeight(.bold)

                        Text("premium.banner.price".localized(defaultValue: "$4.99 — Lifetime Access"))
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, Spacing.xl)
                    .padding(.vertical, Spacing.md)
                    .background(Color.brandProgress)
                    .cornerRadius(CornerRadius.button)

                    Spacer()
                }
                .padding(.top, Spacing.sm)
            }
            .padding(Spacing.lg)
            .background(Color.cardBackground)
            .cornerRadius(CornerRadius.card)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.card)
                    .stroke(Color.brandProgress.opacity(0.3), lineWidth: 1)
            )
            .shadow(
                color: Color.black.opacity(0.08),
                radius: 8,
                x: 0,
                y: 4
            )
        }
        .buttonStyle(PremiumBannerButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("premium.banner.accessibility".localized(defaultValue: "Unlock Premium features for $4.99 one-time purchase. Tap to upgrade."))
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Button Style

private struct PremiumBannerButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview("Premium Banner") {
    VStack(spacing: Spacing.xl) {
        PremiumUpgradeBanner {
            print("Upgrade tapped")
        }
    }
    .padding()
    .background(Color.appBackground)
}

#Preview("Dark Mode") {
    VStack(spacing: Spacing.xl) {
        PremiumUpgradeBanner {
            print("Upgrade tapped")
        }
    }
    .padding()
    .background(Color.appBackground)
    .preferredColorScheme(.dark)
}

#Preview("In List Context") {
    List {
        Section {
            PremiumUpgradeBanner {
                print("Upgrade tapped")
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
        }

        Section {
            Text("Other content")
        }
    }
}
