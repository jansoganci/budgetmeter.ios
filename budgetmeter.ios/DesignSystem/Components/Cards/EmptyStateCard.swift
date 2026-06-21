//
//  EmptyStateCard.swift
//  BudgetMeter
//
//  Handoff empty state — glass card with message and optional primary CTA.
//

import SwiftUI

/// Supportive empty state inside a glass card.
struct EmptyStateCard: View {

    enum ContentMode {
        case custom(message: String)
        case financialSection(frequency: String, type: String)
    }

    private let contentMode: ContentMode
    private let actionTitle: String?
    private let action: (() -> Void)?

    init(
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.contentMode = .custom(message: message)
        self.actionTitle = actionTitle
        self.action = action
    }

    init(
        frequency: String,
        type: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.contentMode = .financialSection(frequency: frequency, type: type)
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: LayoutSpacing.cardInternalGap) {
                switch contentMode {
                case .custom(let message):
                    Text(message)
                        .bodyStyle(color: .textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                case .financialSection(let frequency, let type):
                    EmptyStateRow(frequency: frequency, type: type)
                }

                if let actionTitle, let action {
                    PrimaryCTAButton(title: actionTitle, action: action)
                }
            }
        }
    }
}

#Preview("Custom message") {
    EmptyStateCard(
        message: "Henüz yeterli veri yok. Birkaç gelir ve gider ekledikten sonra içgörülerin burada görünür.",
        actionTitle: "Add income",
        action: {}
    )
    .padding()
    .background(Color.appBackground)
}

#Preview("Financial section") {
    EmptyStateCard(frequency: "monthly", type: "income")
        .padding()
        .background(Color.appBackground)
}
