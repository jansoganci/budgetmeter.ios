//
//  CompactSavingsCard.swift
//  BudgetMeter
//
//  Design System v2.1 - Compact Savings Goal Card
//  Shows savings progress in a small card for dashboard
//

import SwiftUI

// MARK: - Shared Model

struct CompactSavingsGoalItem: Identifiable, Equatable {
    let id: UUID
    let name: String?
    let emoji: String?
    let currentAmount: Double
    let targetAmount: Double
}

// MARK: - Page Content (no outer chrome)

struct CompactSavingsGoalPageContent: View {
    let goalName: String?
    let emoji: String?
    let currentAmount: Double
    let targetAmount: Double
    let currencySymbol: String

    @State private var animatedProgress: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.themeAccent) private var themeAccent

    private var progress: Double {
        guard targetAmount > 0 else { return 0 }
        let calculated = min(max(0, currentAmount) / targetAmount, 1.0)
        return reduceMotion ? calculated : animatedProgress
    }

    private var progressPercentage: Int {
        guard targetAmount > 0 else { return 0 }
        return Int(min(currentAmount / targetAmount, 1.0) * 100)
    }

    private var displayTitle: String {
        if let name = goalName?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty {
            return name
        }
        return "home.savings.title".localized(defaultValue: "Savings")
    }

    private var displayEmoji: String? {
        guard let emoji = emoji?.trimmingCharacters(in: .whitespacesAndNewlines), !emoji.isEmpty else {
            return nil
        }
        return emoji
    }

    private var formattedProgress: String {
        let currentFormatted = CompactSavingsFormatting.formatCompact(currentAmount)
        let targetFormatted = CompactSavingsFormatting.formatCompact(targetAmount)
        return "\(currencySymbol)\(currentFormatted)/\(currencySymbol)\(targetFormatted)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(alignment: .center, spacing: Spacing.xs) {
                if let displayEmoji {
                    Text(displayEmoji)
                        .font(.caption)
                } else {
                    Image(systemName: "target")
                        .font(.caption2)
                        .foregroundColor(.brandProgress)
                }

                Text(displayTitle)
                    .captionStyle()
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer(minLength: 0)

                Text("\(progressPercentage)%")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(themeAccent)
                    .lineLimit(1)
            }

            Text(formattedProgress)
                .metricCompactStyle(color: .textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .allowsTightening(true)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: CornerRadius.tiny)
                        .fill(Color.chartTrack)
                        .frame(height: ChartDimensions.compactProgressHeight)

                    RoundedRectangle(cornerRadius: CornerRadius.tiny)
                        .fill(themeAccent)
                        .frame(
                            width: geometry.size.width * progress,
                            height: ChartDimensions.compactProgressHeight
                        )
                        .animation(
                            reduceMotion ? .none : AnimationCurve.quickSpring,
                            value: animatedProgress
                        )
                }
            }
            .frame(height: ChartDimensions.compactProgressHeight)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear {
            updateAnimatedProgress()
        }
        .onChange(of: currentAmount) { _, _ in
            updateAnimatedProgress()
        }
        .onChange(of: targetAmount) { _, _ in
            updateAnimatedProgress()
        }
    }

    private func updateAnimatedProgress() {
        let targetProgress = targetAmount > 0 ? min(max(0, currentAmount) / targetAmount, 1.0) : 0
        if !reduceMotion {
            withAnimation(AnimationCurve.quickSpring) {
                animatedProgress = targetProgress
            }
        } else {
            animatedProgress = targetProgress
        }
    }
}

// MARK: - Single Goal Card

/// Compact savings goal card with horizontal progress bar
struct CompactSavingsCard: View {

    let goalName: String?
    let emoji: String?
    let currentAmount: Double
    let targetAmount: Double
    let currencySymbol: String
    let onTap: (() -> Void)?

    @State private var isPressed = false

    init(
        goalName: String? = nil,
        emoji: String? = nil,
        currentAmount: Double,
        targetAmount: Double,
        currencySymbol: String = "$",
        onTap: (() -> Void)? = nil
    ) {
        self.goalName = goalName
        self.emoji = emoji
        self.currentAmount = max(0, currentAmount)
        self.targetAmount = max(0, targetAmount)
        self.currencySymbol = currencySymbol
        self.onTap = onTap
    }

    var body: some View {
        CompactSavingsGoalPageContent(
            goalName: goalName,
            emoji: emoji,
            currentAmount: currentAmount,
            targetAmount: targetAmount,
            currencySymbol: currencySymbol
        )
        .frame(minHeight: CardHeight.metric)
        .padding(Spacing.md)
        .glassSurface()
        .pressEffect(isPressed: $isPressed, haptic: onTap != nil)
        .onTapGesture {
            if let action = onTap {
                Haptics.medium()
                action()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(onTap != nil ? [.isButton] : [])
    }

    private var accessibilityLabel: String {
        let title = displayTitle
        let current = CompactSavingsFormatting.formatFull(currentAmount, currencySymbol: currencySymbol)
        let target = CompactSavingsFormatting.formatFull(targetAmount, currencySymbol: currencySymbol)
        let percent = targetAmount > 0 ? Int(min(currentAmount / targetAmount, 1.0) * 100) : 0
        return "\(title): \(current) of \(target), \(percent)% complete"
    }

    private var displayTitle: String {
        if let name = goalName, !name.isEmpty {
            if let emoji = emoji, !emoji.isEmpty {
                return "\(emoji) \(name)"
            }
            return name
        }
        return String(localized: "home.savings.title", defaultValue: "Savings")
    }
}

// MARK: - Carousel Card (single shell, swipe inside)

/// One glass card on Home; swipe between goals inside the card.
struct CompactSavingsCarouselCard: View {
    let goals: [CompactSavingsGoalItem]
    let currencySymbol: String
    let fallbackTargetAmount: Double
    let onTap: (() -> Void)?

    @State private var selectedPage = 0
    @State private var isPressed = false
    @Environment(\.themeAccent) private var themeAccent

    private var displayGoals: [CompactSavingsGoalItem] {
        goals.isEmpty
            ? [CompactSavingsGoalItem(id: UUID(), name: nil, emoji: nil, currentAmount: 0, targetAmount: 0)]
            : goals
    }

    var body: some View {
        VStack(spacing: Spacing.xs) {
            TabView(selection: $selectedPage) {
                ForEach(displayGoals) { goal in
                    goalPage(for: goal)
                        .tag(pageIndex(for: goal))
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: carouselPageHeight)

            if displayGoals.count > 1 {
                pageIndicator
            }
        }
        .frame(minHeight: CardHeight.metric)
        .padding(Spacing.md)
        .glassSurface()
        .pressEffect(isPressed: $isPressed, haptic: onTap != nil)
        .onTapGesture {
            if let action = onTap {
                Haptics.medium()
                action()
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(carouselAccessibilityLabel)
        .accessibilityAddTraits(onTap != nil ? [.isButton] : [])
        .onChange(of: goals.count) { _, newCount in
            guard newCount > 0 else {
                selectedPage = 0
                return
            }
            selectedPage = min(selectedPage, newCount - 1)
        }
    }

    private var carouselPageHeight: CGFloat {
        displayGoals.count > 1 ? 74 : 78
    }

    private var pageIndicator: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(0..<displayGoals.count, id: \.self) { index in
                Circle()
                    .fill(index == selectedPage ? themeAccent : Color.chartTrack)
                    .frame(width: 6, height: 6)
                    .animation(.easeInOut(duration: 0.2), value: selectedPage)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityHidden(true)
    }

    private func pageIndex(for goal: CompactSavingsGoalItem) -> Int {
        displayGoals.firstIndex(where: { $0.id == goal.id }) ?? 0
    }

    private func goalPage(for goal: CompactSavingsGoalItem) -> some View {
        CompactSavingsGoalPageContent(
            goalName: goal.name,
            emoji: goal.emoji,
            currentAmount: goal.currentAmount,
            targetAmount: resolvedTargetAmount(for: goal),
            currencySymbol: currencySymbol
        )
        .padding(.horizontal, Spacing.xs)
    }

    private func resolvedTargetAmount(for goal: CompactSavingsGoalItem) -> Double {
        goal.targetAmount > 0 ? goal.targetAmount : fallbackTargetAmount
    }

    private var carouselAccessibilityLabel: String {
        guard displayGoals.indices.contains(selectedPage) else {
            return String(localized: "home.savings.title", defaultValue: "Savings")
        }
        let goal = displayGoals[selectedPage]
        let target = resolvedTargetAmount(for: goal)
        let title: String
        if let name = goal.name, !name.isEmpty {
            title = goal.emoji.map { "\($0) \(name)" } ?? name
        } else {
            title = String(localized: "home.savings.title", defaultValue: "Savings")
        }
        let current = CompactSavingsFormatting.formatFull(goal.currentAmount, currencySymbol: currencySymbol)
        let targetText = CompactSavingsFormatting.formatFull(target, currencySymbol: currencySymbol)
        let percent = target > 0 ? Int(min(goal.currentAmount / target, 1.0) * 100) : 0
        if displayGoals.count > 1 {
            return String(
                format: String(
                    localized: "home.savings.carousel.page_accessibility",
                    defaultValue: "Savings goal %d of %d: %@, %@ of %@, %d%% complete",
                    table: "Home"
                ),
                selectedPage + 1,
                displayGoals.count,
                title,
                current,
                targetText,
                percent
            )
        }
        return "\(title): \(current) of \(targetText), \(percent)% complete"
    }
}

// MARK: - Formatting

private enum CompactSavingsFormatting {
    static func formatCompact(_ value: Double) -> String {
        if value >= 10000 {
            return String(format: "%.0fK", value / 1000)
        }
        if value >= 1000 {
            return String(format: "%.1fK", value / 1000)
        }
        return String(format: "%.0f", value)
    }

    static func formatFull(_ value: Double, currencySymbol: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        formatter.groupingSeparator = ","
        return "\(currencySymbol)\(formatter.string(from: NSNumber(value: value)) ?? "0")"
    }
}

// MARK: - Preview

#Preview("With Goal Name") {
    VStack(spacing: Spacing.lg) {
        CompactSavingsCard(
            goalName: "Vacation Fund",
            emoji: "🏖️",
            currentAmount: 2500,
            targetAmount: 5000
        )
    }
    .padding()
    .background(Color.appBackground)
}

#Preview("Carousel In One Card") {
    HStack(spacing: Spacing.md) {
        CompactHealthCard(score: 78)
        CompactSavingsCarouselCard(
            goals: [
                CompactSavingsGoalItem(
                    id: UUID(),
                    name: "Vacation",
                    emoji: "🏖️",
                    currentAmount: 2500,
                    targetAmount: 5000
                ),
                CompactSavingsGoalItem(
                    id: UUID(),
                    name: "Emergency",
                    emoji: "🚨",
                    currentAmount: 800,
                    targetAmount: 1000
                )
            ],
            currencySymbol: "$",
            fallbackTargetAmount: 0,
            onTap: {}
        )
    }
    .padding()
    .background(Color.appBackground)
}

#Preview("Dark Mode Carousel") {
    HStack(spacing: Spacing.md) {
        CompactHealthCard(score: 62)
        CompactSavingsCarouselCard(
            goals: [
                CompactSavingsGoalItem(
                    id: UUID(),
                    name: "New Car",
                    emoji: "🚗",
                    currentAmount: 12000,
                    targetAmount: 30000
                ),
                CompactSavingsGoalItem(
                    id: UUID(),
                    name: "House",
                    emoji: "🏠",
                    currentAmount: 45000,
                    targetAmount: 200000
                )
            ],
            currencySymbol: "$",
            fallbackTargetAmount: 0,
            onTap: {}
        )
    }
    .padding()
    .background(Color.appBackground)
    .preferredColorScheme(.dark)
}
