//
//  WelcomeView.swift
//  BudgetMeter
//
//  Created by BudgetMeter Team
//

import SwiftUI

/// First screen of onboarding flow - explains the live meter concept
struct WelcomeView: View {

    // MARK: - Properties

    let onGetStarted: () -> Void
    let onSkip: () -> Void

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background
            Color.appBackground
                .ignoresSafeArea()

            // Content
            VStack(spacing: 0) {
                // Top skip button
                HStack {
                    Spacer()
                    Button(action: onSkip) {
                        Text("onboarding.skip".localized(defaultValue: "Skip"))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.brandProgress)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }

                Spacer()

                // Main content
                ScrollView {
                    VStack(spacing: 32) {
                        // App icon or logo
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 64, weight: .medium))
                            .foregroundColor(.brandProgress)
                            .padding(.top, 20)

                        // Animated live meter
                        AnimatedLiveMeter()

                        // Title
                        Text("onboarding.welcome.title".localized(defaultValue: "Watch Your Money\nFlow in Real-Time"))
                            .font(.system(size: 28, weight: .bold))
                            .multilineTextAlignment(.center)
                            .foregroundColor(.textPrimary)
                            .padding(.horizontal, 32)

                        // Subtitle
                        Text("onboarding.welcome.subtitle".localized(defaultValue: "See your income and expenses accumulate second-by-second. It's like a speedometer for your budget."))
                            .font(.system(size: 17))
                            .multilineTextAlignment(.center)
                            .foregroundColor(.textSecondary)
                            .padding(.horizontal, 32)
                            .fixedSize(horizontal: false, vertical: true)

                        // Features
                        VStack(alignment: .leading, spacing: 16) {
                            featureRow(
                                icon: "lock.shield.fill",
                                text: "onboarding.welcome.feature1".localized(defaultValue: "No account needed")
                            )

                            featureRow(
                                icon: "iphone.and.arrow.forward",
                                text: "onboarding.welcome.feature2".localized(defaultValue: "Everything stays on device")
                            )

                            featureRow(
                                icon: "bolt.fill",
                                text: "onboarding.welcome.feature3".localized(defaultValue: "Start tracking instantly")
                            )
                        }
                        .padding(.horizontal, 32)
                        .padding(.vertical, 8)
                    }
                    .padding(.bottom, 120) // Space for button
                }

                Spacer()
            }

            // Bottom button (fixed)
            VStack {
                Spacer()

                VStack(spacing: 12) {
                    // Primary button
                    Button(action: onGetStarted) {
                        HStack(spacing: 8) {
                            Text("onboarding.welcome.button".localized(defaultValue: "Get Started"))
                                .font(.system(size: 17, weight: .semibold))

                            Image(systemName: "arrow.right")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            LinearGradient(
                                colors: [Color.brandProgress, Color.brandProgress.opacity(0.85)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(14)
                        .shadow(color: Color.brandProgress.opacity(0.3), radius: 12, x: 0, y: 6)
                    }

                    // Skip hint
                    Text("onboarding.welcome.skip_hint".localized(defaultValue: "or tap anywhere to skip"))
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
                .background(
                    LinearGradient(
                        colors: [
                            Color.appBackground.opacity(0),
                            Color.appBackground
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 150)
                    .offset(y: -100)
                )
            }
        }
        // Allow tapping anywhere to skip
        .contentShape(Rectangle())
        .highPriorityGesture(
            TapGesture(count: 2)
                .onEnded { _ in
                    onSkip()
                }
        )
    }

    // MARK: - Components

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.brandProgress)
                .frame(width: 24)

            Text(text)
                .font(.system(size: 16))
                .foregroundColor(.textPrimary)

            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    WelcomeView(
        onGetStarted: {
            print("Get Started tapped")
        },
        onSkip: {
            print("Skip tapped")
        }
    )
}
