//
//  MomentumRingView.swift
//  BudgetMeter
//
//  Phase 3/4 — Momentum ring indicator for Home pace status.
//

import SwiftUI

/// Circular momentum ring showing financial pace direction.
struct MomentumRingView: View {

    let paceStatus: PaceStatus
    let progress: Double
    let lineWidth: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(
        paceStatus: PaceStatus,
        progress: Double = 0.72,
        lineWidth: CGFloat = 10
    ) {
        self.paceStatus = paceStatus
        self.progress = min(max(progress, 0.05), 1.0)
        self.lineWidth = lineWidth
    }

    private var ringColor: Color {
        Color.color(for: paceStatus)
    }

    private var trackColor: Color {
        Color.chartTrack
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(trackColor, lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    ringColor,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            Image(systemName: iconName)
                .font(.system(size: lineWidth * 1.4, weight: .semibold))
                .foregroundColor(ringColor)
        }
        .accessibilityHidden(true)
    }

    private var iconName: String {
        switch paceStatus {
        case .movingForward: return "arrow.up.right"
        case .slowingDown: return "arrow.down.right"
        case .neutral: return "arrow.right"
        case .insufficientData: return "minus"
        }
    }
}

#Preview {
    HStack(spacing: 24) {
        MomentumRingView(paceStatus: .movingForward)
            .frame(width: 88, height: 88)
        MomentumRingView(paceStatus: .slowingDown)
            .frame(width: 88, height: 88)
    }
    .padding()
    .background(Color.appBackground)
    .preferredColorScheme(.dark)
}
