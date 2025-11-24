//
//  QuickSetupView.swift
//  BudgetMeter
//
//  Created by BudgetMeter Team
//

import SwiftUI

/// Second screen of onboarding flow - optional income setup
struct QuickSetupView: View {

    // MARK: - Properties

    @ObservedObject var viewModel: OnboardingViewModel
    let onSkip: () -> Void
    let onComplete: () -> Void

    @FocusState private var isInputFocused: Bool

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
                        // Icon
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.system(size: 64, weight: .medium))
                            .foregroundColor(.brandPositive)
                            .padding(.top, 20)

                        // Title
                        Text("onboarding.setup.title".localized(defaultValue: "What's Your Income?"))
                            .font(.system(size: 28, weight: .bold))
                            .multilineTextAlignment(.center)
                            .foregroundColor(.textPrimary)
                            .padding(.horizontal, 32)

                        // Subtitle
                        Text("onboarding.setup.subtitle".localized(defaultValue: "This helps us show you a more accurate live meter. Don't worry, you can skip this or change it later."))
                            .font(.system(size: 17))
                            .multilineTextAlignment(.center)
                            .foregroundColor(.textSecondary)
                            .padding(.horizontal, 32)
                            .fixedSize(horizontal: false, vertical: true)

                        // Input card
                        VStack(spacing: 20) {
                            // Amount input
                            VStack(alignment: .leading, spacing: 8) {
                                Text("onboarding.setup.amount_label".localized(defaultValue: "Amount"))
                                    .font(.caption)
                                    .foregroundColor(.textSecondary)
                                    .textCase(.uppercase)
                                    .tracking(1.2)

                                HStack(spacing: 12) {
                                    Text(CurrencyHelper.currencySymbol)
                                        .font(.system(size: 24, weight: .semibold))
                                        .foregroundColor(.textSecondary)

                                    TextField(
                                        "0",
                                        text: $viewModel.incomeAmount
                                    )
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.textPrimary)
                                    .keyboardType(.decimalPad)
                                    .focused($isInputFocused)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.cardBackground)
                                )
                            }

                            // Frequency selector
                            VStack(alignment: .leading, spacing: 8) {
                                Text("onboarding.setup.frequency_label".localized(defaultValue: "Frequency"))
                                    .font(.caption)
                                    .foregroundColor(.textSecondary)
                                    .textCase(.uppercase)
                                    .tracking(1.2)

                                FrequencySelector(selectedFrequency: $viewModel.selectedFrequency)
                            }

                            // Auto-calculation hint
                            if let hint = calculationHint {
                                HStack(spacing: 8) {
                                    Image(systemName: "lightbulb.fill")
                                        .font(.caption)
                                        .foregroundColor(.brandProgress)

                                    Text(hint)
                                        .font(.caption)
                                        .foregroundColor(.textSecondary)
                                }
                                .padding(.top, 4)
                            }
                        }
                        .padding(.horizontal, 32)
                        .padding(.vertical, 24)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.cardBackground)
                                .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
                        )
                        .padding(.horizontal, 20)

                        // Privacy note
                        HStack(spacing: 8) {
                            Image(systemName: "lock.shield.fill")
                                .font(.caption)
                                .foregroundColor(.brandProgress)

                            Text("onboarding.setup.privacy_note".localized(defaultValue: "Stored only on your device"))
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                        }
                    }
                    .padding(.bottom, 180) // Space for buttons
                }

                Spacer()
            }

            // Bottom buttons (fixed)
            VStack {
                Spacer()

                VStack(spacing: 12) {
                    // Primary button - Save & Go
                    Button(action: handleSaveAndGo) {
                        HStack(spacing: 8) {
                            Text(hasValidInput ? "onboarding.setup.save_button".localized(defaultValue: "Save & Go") : "onboarding.setup.continue_button".localized(defaultValue: "Continue"))
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

                    // Secondary button - Skip
                    Button(action: onSkip) {
                        Text("onboarding.setup.skip_button".localized(defaultValue: "Skip for Now"))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.textSecondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                    }
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
        .onTapGesture {
            // Dismiss keyboard when tapping outside
            isInputFocused = false
        }
    }

    // MARK: - Computed Properties

    private var hasValidInput: Bool {
        guard let amount = Double(viewModel.incomeAmount) else { return false }
        return amount > 0
    }

    private var calculationHint: String? {
        guard let amount = Double(viewModel.incomeAmount), amount > 0 else { return nil }

        let dailyAmount: Double
        let monthlyAmount: Double
        let yearlyAmount: Double

        switch viewModel.selectedFrequency {
        case .daily:
            dailyAmount = amount
            monthlyAmount = amount * 30.4375
            yearlyAmount = amount * 365.25

        case .monthly:
            dailyAmount = amount / 30.4375
            monthlyAmount = amount
            yearlyAmount = amount * 12

        case .yearly:
            dailyAmount = amount / 365.25
            monthlyAmount = amount / 12
            yearlyAmount = amount
        }

        // Show most useful conversion hint
        switch viewModel.selectedFrequency {
        case .daily:
            return String(
                format: "onboarding.setup.hint_daily".localized(defaultValue: "That's ~%@ per month"),
                CurrencyHelper.formatAmount(monthlyAmount)
            )

        case .monthly:
            return String(
                format: "onboarding.setup.hint_monthly".localized(defaultValue: "That's ~%@ per day"),
                CurrencyHelper.formatAmount(dailyAmount)
            )

        case .yearly:
            return String(
                format: "onboarding.setup.hint_yearly".localized(defaultValue: "That's ~%@ per month"),
                CurrencyHelper.formatAmount(monthlyAmount)
            )
        }
    }

    // MARK: - Actions

    private func handleSaveAndGo() {
        isInputFocused = false

        if hasValidInput {
            viewModel.saveIncomeIfProvided()
        }

        onComplete()
    }
}

// MARK: - Preview

#Preview {
    QuickSetupView(
        viewModel: OnboardingViewModel(),
        onSkip: {
            print("Skip tapped")
        },
        onComplete: {
            print("Complete tapped")
        }
    )
}
