//
//  SectionHeader.swift
//  BudgetMeter
//
//  Handoff component — simple section title with optional subtitle and trailing action.
//

import SwiftUI

/// Introduces grouped content. Distinct from collapsible `FinancialSection`.
struct SectionHeader<Trailing: View>: View {

    let title: String
    let subtitle: String?
    let trailing: Trailing?

    init(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing()
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(title)
                    .sectionTitleStyle()

                if let subtitle {
                    Text(subtitle)
                        .captionStyle(color: .textSecondary)
                }
            }

            Spacer(minLength: Spacing.sm)

            if let trailing {
                trailing
            }
        }
        .accessibilityElement(children: .combine)
    }
}

extension SectionHeader where Trailing == EmptyView {
    init(title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.trailing = nil
    }
}

#Preview {
    VStack(spacing: LayoutSpacing.sectionGap) {
        SectionHeader(title: "Recurring income", subtitle: "Monthly totals")
        SectionHeader(title: "Settings") {
            Button("Edit") {}
                .captionStyle(color: .accentPrimary)
        }
    }
    .padding()
    .background(Color.appBackground)
}
