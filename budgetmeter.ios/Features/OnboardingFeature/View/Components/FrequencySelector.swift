//
//  FrequencySelector.swift
//  BudgetMeter
//
//  Created by BudgetMeter Team
//

import SwiftUI

/// Segmented control-style frequency selector for onboarding
/// Allows user to choose between Daily, Monthly, Yearly
struct FrequencySelector: View {

    // MARK: - Properties

    @Binding var selectedFrequency: OnboardingViewModel.Frequency

    // MARK: - Body

    var body: some View {
        HStack(spacing: 0) {
            ForEach(OnboardingViewModel.Frequency.allCases, id: \.self) { frequency in
                frequencyButton(for: frequency)
            }
        }
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(10)
    }

    // MARK: - Components

    private func frequencyButton(for frequency: OnboardingViewModel.Frequency) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedFrequency = frequency
            }
        }) {
            HStack(spacing: 6) {
                Image(systemName: frequency.icon)
                    .font(.system(size: 14, weight: .medium))

                Text(frequency.displayName)
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(selectedFrequency == frequency ? .white : .primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                selectedFrequency == frequency ?
                    Color.brandProgress : Color.clear
            )
            .cornerRadius(8)
            .padding(4)
        }
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var frequency: OnboardingViewModel.Frequency = .monthly

        var body: some View {
            VStack(spacing: 24) {
                FrequencySelector(selectedFrequency: $frequency)
                    .padding()

                Text("Selected: \(frequency.displayName)")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.appBackground)
        }
    }

    return PreviewWrapper()
}
