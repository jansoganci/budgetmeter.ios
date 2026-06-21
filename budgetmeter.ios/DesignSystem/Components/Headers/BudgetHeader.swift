//
//  BudgetHeader.swift
//  BudgetMeter
//
//  Handoff screen header — title/subtitle or time-based greeting via GreetingHeader.
//

import SwiftUI

/// Consistent screen header. Does not place Pulsey in financial metric areas.
struct BudgetHeader<Trailing: View>: View {

    enum Mode {
        case title(title: String, subtitle: String?)
        case timeBasedGreeting
    }

    private let mode: Mode
    private let trailing: Trailing?

    init(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.mode = .title(title: title, subtitle: subtitle)
        self.trailing = trailing()
    }

    /// Uses existing `GreetingHeader` time-based greeting.
    init(timeBasedGreeting: Bool = true, @ViewBuilder trailing: () -> Trailing) {
        self.mode = .timeBasedGreeting
        self.trailing = trailing()
    }

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Group {
                switch mode {
                case .title(let title, let subtitle):
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(title)
                            .sectionTitleStyle()

                        if let subtitle {
                            Text(subtitle)
                                .captionStyle(color: .textSecondary)
                        }
                    }

                case .timeBasedGreeting:
                    GreetingHeader()
                }
            }

            Spacer(minLength: Spacing.sm)

            if let trailing {
                trailing
            }
        }
        .padding(.vertical, Spacing.xs)
    }
}

extension BudgetHeader where Trailing == EmptyView {
    init(title: String, subtitle: String? = nil) {
        self.mode = .title(title: title, subtitle: subtitle)
        self.trailing = nil
    }

    init(timeBasedGreeting: Bool = true) {
        self.mode = .timeBasedGreeting
        self.trailing = nil
    }
}

#Preview("Title") {
    BudgetHeader(title: "Insights", subtitle: "Parandaki değişimi sade şekilde gör.")
        .padding()
        .background(Color.appBackground)
}

#Preview("Greeting") {
    BudgetHeader(timeBasedGreeting: true)
        .padding()
        .background(Color.appBackground)
}
