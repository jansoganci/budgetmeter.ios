//
//  SecondaryCTAButton.swift
//  BudgetMeter
//
//  Handoff secondary CTA — outline/elevated treatment, lower visual weight.
//

import SwiftUI

/// Secondary action that supports but does not compete with the primary CTA.
struct SecondaryCTAButton: View {

    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .bodyStyle(color: .textPrimary)
                .frame(maxWidth: .infinity)
                .frame(minHeight: LayoutSpacing.buttonHeight)
                .background(Color.surfaceCard)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.button, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.button, style: .continuous)
                        .stroke(Color.borderSubtle, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SecondaryCTAButton(title: "Sign in with Email", action: {})
        .padding()
        .background(Color.appBackground)
}
