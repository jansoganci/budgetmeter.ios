//
//  ChartCard.swift
//  BudgetMeter
//
//  Handoff chart container — one chart idea per card with title hierarchy.
//

import SwiftUI

/// Wraps chart content in a consistent glass/opaque card with section title.
struct ChartCard<Content: View>: View {

    let title: String
    let subtitle: String?
    let style: GlassCardStyle
    let content: Content

    init(
        title: String,
        subtitle: String? = nil,
        style: GlassCardStyle = .opaque,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.style = style
        self.content = content()
    }

    var body: some View {
        GlassCard(style: style) {
            VStack(alignment: .leading, spacing: LayoutSpacing.cardInternalGap) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(title)
                        .cardLabelStyle(color: .textPrimary)

                    if let subtitle {
                        Text(subtitle)
                            .captionStyle(color: .textSecondary)
                    }
                }

                content
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(title)
    }
}

#Preview {
    ChartCard(title: "Balance trend", subtitle: "Last 30 days") {
        MiniBarChart(data: [3, 5, 4, 7, 6, 8, 5], barColor: .accentPrimary)
            .frame(height: ChartDimensions.miniChartHeight)
    }
    .padding()
    .background(Color.appBackground)
}
