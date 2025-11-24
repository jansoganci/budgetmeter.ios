//
//  AnimatedLiveMeter.swift
//  BudgetMeter
//
//  Created by BudgetMeter Team
//

import SwiftUI

/// Animated live meter demonstration for onboarding welcome screen
/// Shows the unique value proposition: real-time financial tracking
struct AnimatedLiveMeter: View {

    // MARK: - State

    @State private var currentValue: Double = 0
    @State private var isAnimating: Bool = false

    // MARK: - Constants

    private let targetValue: Double = 15.47
    private let animationDuration: Double = 3.0
    private let pulseScale: CGFloat = 1.05

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            // Animated Value
            Text(formattedValue)
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundColor(currentValue > 0 ? .brandPositive : .textSecondary)
                .scaleEffect(isAnimating ? pulseScale : 1.0)
                .animation(.easeInOut(duration: 0.3).repeatForever(autoreverses: true), value: isAnimating)

            // Label
            Text("onboarding.live_meter.label".localized(defaultValue: "Live Balance"))
                .font(.caption)
                .foregroundColor(.textSecondary)
                .textCase(.uppercase)
                .tracking(1.2)

            // Flow indicator
            if currentValue > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.caption)
                    Text("onboarding.live_meter.flowing".localized(defaultValue: "Flowing"))
                        .font(.caption)
                }
                .foregroundColor(.brandPositive)
                .transition(.opacity.combined(with: .scale))
            }
        }
        .padding(.vertical, 32)
        .padding(.horizontal, 24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.cardBackground)
                .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
        )
        .onAppear {
            startAnimation()
        }
    }

    // MARK: - Computed Properties

    private var formattedValue: String {
        CurrencyHelper.formatAmount(currentValue)
    }

    // MARK: - Animation

    private func startAnimation() {
        // Start from 0
        currentValue = 0

        // Animate to target value
        withAnimation(.easeInOut(duration: animationDuration)) {
            currentValue = targetValue
        }

        // Start pulse animation
        withAnimation {
            isAnimating = true
        }

        // Loop animation every 4 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration + 1.0) {
            loopAnimation()
        }
    }

    private func loopAnimation() {
        // Reset to 0
        withAnimation(.easeInOut(duration: 0.5)) {
            currentValue = 0
        }

        // Wait a bit, then animate again
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            withAnimation(.easeInOut(duration: animationDuration)) {
                currentValue = targetValue
            }

            // Schedule next loop
            DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration + 1.0) {
                loopAnimation()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()

        AnimatedLiveMeter()
            .padding()
    }
}
