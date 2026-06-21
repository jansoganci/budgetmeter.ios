//
//  PremiumUpgradeBanner.swift
//  BudgetMeter
//
//  Non-intrusive, dismissable premium upgrade banner (v2 glass styling)
//

import SwiftUI

/// Premium upgrade banner with v2 glass surface and compact CTA
struct PremiumUpgradeBanner: View {

    // MARK: - Properties

    let onUpgradeTapped: () -> Void

    @AppStorage("premiumUpgradeBannerDismissed") private var isDismissed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let featureHighlights = [
        String(localized: "premium.banner.feature.subscriptions", defaultValue: "Subscription tracking", table: "UI"),
        String(localized: "premium.banner.feature.bills", defaultValue: "Bill reminders", table: "UI"),
        String(localized: "premium.banner.feature.savings", defaultValue: "Savings goals", table: "UI")
    ]

    // MARK: - Body

    var body: some View {
        if isDismissed {
            EmptyView()
        } else {
            bannerContent
        }
    }

    private var bannerContent: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(alignment: .top, spacing: Spacing.sm) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(String(localized: "premium.banner.title", defaultValue: "Go Premium", table: "UI"))
                        .sectionTitleStyle()

                    Text(String(
                        localized: "premium.banner.subtitle",
                        defaultValue: "Themes, widgets, and deeper insights — all included.",
                        table: "UI"
                    ))
                    .captionStyle(color: .textSecondary)
                }

                Spacer(minLength: Spacing.sm)

                Button {
                    if reduceMotion {
                        isDismissed = true
                    } else {
                        withAnimation(AnimationCurve.buttonPress) {
                            isDismissed = true
                        }
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.textTertiary)
                        .frame(width: TouchTarget.minimum, height: TouchTarget.minimum)
                }
                .accessibilityLabel(
                    String(localized: "premium.banner.dismiss", defaultValue: "Dismiss", table: "UI")
                )
            }

            VStack(alignment: .leading, spacing: Spacing.xs) {
                ForEach(featureHighlights, id: \.self) { feature in
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "checkmark")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.financialPositive)
                        Text(feature)
                            .captionStyle(color: .textPrimary)
                    }
                }

                Text(String(localized: "premium.banner.feature.more", defaultValue: "And 6 more…", table: "UI"))
                    .captionStyle(color: .textSecondary)
            }

            Text(String(localized: "premium.banner.onetime", defaultValue: "One-time purchase · No subscription", table: "UI"))
                .badgeStyle(color: .textTertiary)

            Button {
                Haptics.medium()
                onUpgradeTapped()
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(String(localized: "premium.banner.cta", defaultValue: "Upgrade", table: "UI"))
                            .buttonTextStyle(color: .white)

                        Text(String(localized: "premium.banner.price", defaultValue: "$4.99 · Lifetime", table: "UI"))
                            .captionStyle(color: .white.opacity(0.85))
                    }

                    Spacer()

                    Image(systemName: "arrow.right")
                        .font(.body.weight(.semibold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.md)
                .background(Color.accentPrimary)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.button, style: .continuous))
            }
            .buttonStyle(PremiumBannerButtonStyle())
        }
        .padding(Spacing.lg)
        .glassSurface()
        .accessibilityElement(children: .contain)
        .accessibilityLabel(
            String(
                localized: "premium.banner.accessibility",
                defaultValue: "Go Premium. Themes, widgets, and deeper insights. One-time purchase. Tap Upgrade to continue.",
                table: "UI"
            )
        )
    }
}

// MARK: - Button Style

private struct PremiumBannerButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(reduceMotion ? 1.0 : (configuration.isPressed ? 0.98 : 1.0))
            .animation(reduceMotion ? .none : AnimationCurve.buttonPress, value: configuration.isPressed)
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
    .background(Color.surfaceObsidian)
}

#Preview("Dark Mode") {
    VStack(spacing: Spacing.xl) {
        PremiumUpgradeBanner {
            print("Upgrade tapped")
        }
    }
    .padding()
    .background(Color.surfaceObsidian)
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
