//
//  GlassCard.swift
//  BudgetMeter
//
//  Handoff wrapper — medium glass or opaque elevated card surface.
//

import SwiftUI

enum GlassCardStyle {
    /// Medium-strength glass with Reduce Transparency fallback.
    case glass
    /// Opaque elevated card with border and shadow.
    case opaque
}

/// Standard readable card container delegating to `glassSurface()` or `surfaceCard()`.
struct GlassCard<Content: View>: View {

    private let style: GlassCardStyle
    private let padding: CGFloat
    private let content: Content

    init(
        style: GlassCardStyle = .glass,
        padding: CGFloat = LayoutSpacing.cardPadding,
        @ViewBuilder content: () -> Content
    ) {
        self.style = style
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        Group {
            switch style {
            case .glass:
                content
                    .padding(padding)
                    .glassSurface()
            case .opaque:
                content
                    .surfaceCard(padding: padding)
            }
        }
    }
}

#Preview("Glass") {
    GlassCard {
        Text("Glass card")
            .bodyStyle()
    }
    .padding()
    .background(Color.appBackground)
}

#Preview("Opaque") {
    GlassCard(style: .opaque) {
        Text("Opaque card")
            .bodyStyle()
    }
    .padding()
    .background(Color.appBackground)
}
