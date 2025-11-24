//
//  OnboardingContainerView.swift
//  BudgetMeter
//
//  Created by BudgetMeter Team
//

import SwiftUI

/// Container view that coordinates the onboarding flow
struct OnboardingContainerView: View {

    // MARK: - Properties

    @StateObject private var viewModel = OnboardingViewModel()
    @StateObject private var onboardingManager = OnboardingManager.shared

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()

            // Screen navigation
            Group {
                switch viewModel.currentScreen {
                case 0:
                    WelcomeView(
                        onGetStarted: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                viewModel.currentScreen = 1
                            }
                        },
                        onSkip: handleSkip
                    )
                    .transition(.asymmetric(
                        insertion: .opacity,
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))

                case 1:
                    QuickSetupView(
                        viewModel: viewModel,
                        onSkip: handleSkip,
                        onComplete: handleComplete
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .opacity
                    ))

                default:
                    // Should never reach here
                    EmptyView()
                }
            }
            .animation(.easeInOut(duration: 0.3), value: viewModel.currentScreen)
        }
    }

    // MARK: - Actions

    private func handleSkip() {
        // Mark onboarding as complete with skipped flag
        onboardingManager.markOnboardingComplete(skipped: true)
    }

    private func handleComplete() {
        // Mark onboarding as complete (not skipped)
        onboardingManager.markOnboardingComplete(skipped: false)
    }
}

// MARK: - Preview

#Preview {
    OnboardingContainerView()
}
