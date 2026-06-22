//
//  PrimaryCTAButton.swift
//  BudgetMeter
//
//  Handoff primary CTA — theme accent fill, 52pt height target.
//

import SwiftUI

/// Main action button. Styling aligned with auth CTAs; lives in DesignSystem for shared use.
struct PrimaryCTAButton: View {

    let title: String
    var isLoading: Bool = false
    var isDisabled: Bool = false
    let action: () -> Void

    @Environment(\.themeAccent) private var themeAccent

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.85)
                }

                Text(title)
                    .buttonTextStyle(color: .white)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: LayoutSpacing.buttonHeight)
            .background(isDisabled ? Color.financialNeutral : themeAccent)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.button, style: .continuous))
        }
        .disabled(isDisabled || isLoading)
        .buttonStyle(.plain)
        .accessibilityHint(isLoading ? String(localized: "auth.loading", defaultValue: "Please wait", table: "UI") : "")
    }
}

#Preview {
    VStack(spacing: Spacing.md) {
        PrimaryCTAButton(title: "Continue", action: {})
        PrimaryCTAButton(title: "Loading", isLoading: true, action: {})
        PrimaryCTAButton(title: "Disabled", isDisabled: true, action: {})
    }
    .padding()
    .background(Color.appBackground)
}
