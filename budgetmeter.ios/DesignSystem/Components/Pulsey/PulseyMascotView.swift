//
//  PulseyMascotView.swift
//  BudgetMeter
//
//  Phase 10 — Pulsey static fallback mascot (placeholder until assets land).
//

import SwiftUI

/// Visual state for Pulsey mascot placement.
enum PulseyState {
    case loading
    case success
    case empty
    case celebration
}

/// Reusable Pulsey mascot with emoji placeholder and calm breathing animation.
/// Replace the emoji with image assets when Pulsey artwork is available.
struct PulseyMascotView: View {

    var state: PulseyState = .success
    var size: CGFloat = 40

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            if reduceMotion {
                mascotContent(scale: 1.0)
            } else {
                PhaseAnimator([false, true]) { isExpanded in
                    mascotContent(scale: isExpanded ? 1.06 : 0.94)
                } animation: { _ in
                    .easeInOut(duration: 1.8)
                }
            }
        }
        .frame(width: size, height: size)
        .accessibilityLabel(accessibilityLabel)
    }

    @ViewBuilder
    private func mascotContent(scale: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(backgroundColor)
                .overlay(
                    Circle()
                        .stroke(Color.borderSubtle.opacity(0.6), lineWidth: 1)
                )

            // Static fallback — swap for Image("Pulsey...") when assets are added.
            Text(placeholderEmoji)
                .font(.system(size: size * 0.45))
        }
        .scaleEffect(scale)
    }

    private var placeholderEmoji: String {
        switch state {
        case .loading: return "✨"
        case .success: return "💜"
        case .empty: return "💜"
        case .celebration: return "✨"
        }
    }

    private var backgroundColor: Color {
        switch state {
        case .loading:
            return Color.surfaceInset.opacity(0.85)
        case .success:
            return Color.accentPrimary.opacity(0.12)
        case .empty:
            return Color.surfaceInset.opacity(0.85)
        case .celebration:
            return Color.accentPrimary.opacity(0.18)
        }
    }

    private var accessibilityLabel: String {
        switch state {
        case .loading:
            return "pulsey.accessibility.loading".localized(defaultValue: "Pulsey is loading")
        case .success:
            return "pulsey.accessibility.success".localized(defaultValue: "Pulsey, your financial companion")
        case .empty:
            return "pulsey.accessibility.empty".localized(defaultValue: "Pulsey encouraging you to get started")
        case .celebration:
            return "pulsey.accessibility.celebration".localized(defaultValue: "Pulsey celebrating a milestone")
        }
    }
}

#Preview("Pulsey States") {
    HStack(spacing: 16) {
        PulseyMascotView(state: .loading)
        PulseyMascotView(state: .success)
        PulseyMascotView(state: .empty)
        PulseyMascotView(state: .celebration)
    }
    .padding()
    .background(Color.appBackground)
}

#Preview("Dark Mode") {
    PulseyMascotView(state: .success)
        .padding()
        .background(Color.appBackground)
        .preferredColorScheme(.dark)
}
