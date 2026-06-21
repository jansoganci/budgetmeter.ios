//
//  GlassSurface.swift
//  BudgetMeter
//
//  Design System v2 — Glass card surface with Reduce Transparency fallback
//

import SwiftUI

struct GlassSurfaceModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    func body(content: Content) -> some View {
        if reduceTransparency {
            content
                .background(GlassSurfaceStyle.opaqueFallback)
                .clipShape(RoundedRectangle(cornerRadius: GlassSurfaceStyle.cornerRadius, style: .continuous))
        } else {
            content
                .background(
                    .ultraThinMaterial,
                    in: RoundedRectangle(cornerRadius: GlassSurfaceStyle.cornerRadius, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: GlassSurfaceStyle.cornerRadius, style: .continuous)
                        .stroke(
                            colorScheme == .dark
                                ? GlassSurfaceStyle.borderDark
                                : GlassSurfaceStyle.borderLight,
                            lineWidth: GlassSurfaceStyle.borderLineWidth
                        )
                )
        }
    }
}

extension View {
    func glassSurface() -> some View {
        modifier(GlassSurfaceModifier())
    }
}
