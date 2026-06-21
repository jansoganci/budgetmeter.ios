//
//  StatusBadge.swift
//  BudgetMeter
//
//  Handoff status pill — text + optional icon; color is not the only signal.
//

import SwiftUI

enum StatusBadgeStyle {
    case positive
    case calmPositive
    case negative
    case negativeAlt
    case neutral

    var foregroundColor: Color {
        switch self {
        case .positive: return .financialPositive
        case .calmPositive: return .financialPositiveCalm
        case .negative: return .financialNegative
        case .negativeAlt: return .statusNegativeAlt
        case .neutral: return .financialNeutral
        }
    }

    var backgroundColor: Color {
        foregroundColor.opacity(0.12)
    }
}

/// Compact status label for pace, health, or feature state.
struct StatusBadge: View {

    let label: String
    let style: StatusBadgeStyle
    var iconName: String?

    init(label: String, style: StatusBadgeStyle, iconName: String? = nil) {
        self.label = label
        self.style = style
        self.iconName = iconName
    }

    init(paceStatus: PaceStatus, label: String) {
        self.label = label
        switch paceStatus {
        case .movingForward:
            self.style = .positive
            self.iconName = "arrow.up"
        case .slowingDown:
            self.style = .negative
            self.iconName = "arrow.down"
        case .neutral:
            self.style = .neutral
            self.iconName = "minus"
        case .insufficientData:
            self.style = .neutral
            self.iconName = "questionmark"
        }
    }

    var body: some View {
        HStack(spacing: Spacing.xs) {
            if let iconName {
                Image(systemName: iconName)
                    .font(.caption2.weight(.semibold))
                    .accessibilityHidden(true)
            }

            Text(label)
                .font(.caption.weight(.semibold))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundColor(style.foregroundColor)
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(style.backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.badge, style: .continuous))
        .accessibilityLabel(label)
    }
}

#Preview {
    VStack(spacing: Spacing.sm) {
        StatusBadge(label: "Moving forward", style: .positive, iconName: "arrow.up")
        StatusBadge(label: "Calm positive", style: .calmPositive)
        StatusBadge(label: "Slowing down", style: .negative, iconName: "arrow.down")
        StatusBadge(label: "Neutral", style: .neutral)
    }
    .padding()
    .background(Color.appBackground)
}
