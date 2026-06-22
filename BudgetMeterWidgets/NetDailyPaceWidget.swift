//
//  NetDailyPaceWidget.swift
//  BudgetMeterWidgets
//
//  Net daily pace widget — systemSmall + systemMedium.
//

import WidgetKit
import SwiftUI

private enum WidgetCopy {
    static func paceLabel(locale: Locale) -> String {
        String(localized: "widget.pace.label", defaultValue: "Today's pace", table: "UI", locale: locale)
    }

    static func lockedTitle(locale: Locale) -> String {
        String(localized: "widget.locked.title", defaultValue: "Premium Widget", table: "UI", locale: locale)
    }

    static func lockedSubtitle(locale: Locale) -> String {
        String(
            localized: "widget.locked.subtitle",
            defaultValue: "Unlock net daily pace on your Home Screen",
            table: "UI",
            locale: locale
        )
    }

    static func missingMessage(locale: Locale) -> String {
        String(
            localized: "widget.missing.message",
            defaultValue: "Open BudgetMeter to refresh",
            table: "UI",
            locale: locale
        )
    }

    static func staleMessage(locale: Locale) -> String {
        String(
            localized: "widget.stale.message",
            defaultValue: "Open BudgetMeter for the latest pace",
            table: "UI",
            locale: locale
        )
    }

    static func lockedCTA(locale: Locale) -> String {
        String(localized: "widget.locked.cta", defaultValue: "Upgrade to unlock", table: "UI", locale: locale)
    }

    static func goalPrefix(locale: Locale) -> String {
        String(localized: "home.quick_actions.goal", defaultValue: "Goal", table: "Home", locale: locale)
    }

    static func noGoal(locale: Locale) -> String {
        String(localized: "widget.goal.none", defaultValue: "No goal", table: "UI", locale: locale)
    }
}

// MARK: - Widget

struct NetDailyPaceWidget: Widget {
    let kind: String = WidgetConstants.netDailyPaceWidgetKind

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NetDailyPaceProvider()) { entry in
            NetDailyPaceWidgetEntryView(entry: entry)
        }
        .configurationDisplayName(
            String(localized: "widget.pace.title", defaultValue: "Net Daily Pace", table: "UI")
        )
        .description(
            String(
                localized: "widget.pace.description",
                defaultValue: "See whether you're moving forward or slowing down",
                table: "UI"
            )
        )
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Timeline Entry

struct NetDailyPaceEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot?
    let displayState: WidgetDisplayState
    let title: String
    let primaryLine: String
    let secondaryLine: String
    let goalLine: String
    let deepLinkURL: URL?
    let accessibilityLabel: String
    let paceStatus: String
    let usesHeroTypography: Bool
}

// MARK: - Provider

struct NetDailyPaceProvider: TimelineProvider {
    private let store = WidgetSnapshotStore()
    private var fallbackLocale: Locale { .current }

    func placeholder(in context: Context) -> NetDailyPaceEntry {
        makeEntry(
            from: WidgetSnapshot(
                schemaVersion: WidgetConstants.schemaVersion,
                appLanguageCode: fallbackLocale.identifier,
                netDailyPace: 12,
                paceStatus: "movingForward",
                displayValue: "+$12/day",
                displayStatusCopy: "Moving forward +$12/day",
                currencyCode: "USD",
                currencySymbol: "$",
                savingsTargetAmount: 100,
                savingsCurrentAmount: 64,
                isPremium: true,
                generatedAt: Date(),
                staleAfter: Date().addingTimeInterval(WidgetConstants.staleInterval),
                isLockedTeaser: false,
                lockedTeaserTitle: WidgetCopy.lockedTitle(locale: fallbackLocale),
                lockedTeaserSubtitle: WidgetCopy.lockedSubtitle(locale: fallbackLocale),
                deepLinkURL: WidgetConstants.unlockedDeepLink,
                hasFinancialInput: true,
                displayState: .unlocked,
                missingMessage: WidgetCopy.missingMessage(locale: fallbackLocale),
                staleMessage: WidgetCopy.staleMessage(locale: fallbackLocale)
            ),
            date: Date()
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (NetDailyPaceEntry) -> Void) {
        completion(makeEntry(from: store.load(), date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NetDailyPaceEntry>) -> Void) {
        let currentDate = Date()
        let snapshot = store.load()
        let entry = makeEntry(from: snapshot, date: currentDate)
        let nextUpdate = snapshot?.staleAfter
            ?? currentDate.addingTimeInterval(WidgetConstants.fallbackRefreshInterval)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func makeEntry(from snapshot: WidgetSnapshot?, date: Date) -> NetDailyPaceEntry {
        let locale = localeForSnapshot(snapshot)
        guard let snapshot else {
            let missing = WidgetCopy.missingMessage(locale: locale)
            return NetDailyPaceEntry(
                date: date,
                snapshot: nil,
                displayState: .missing,
                title: WidgetCopy.paceLabel(locale: locale),
                primaryLine: missing,
                secondaryLine: "",
                goalLine: WidgetCopy.noGoal(locale: locale),
                deepLinkURL: URL(string: WidgetConstants.unlockedDeepLink),
                accessibilityLabel: "\(WidgetCopy.paceLabel(locale: locale)). \(missing)",
                paceStatus: "insufficientData",
                usesHeroTypography: false
            )
        }

        let state = snapshot.resolvedDisplayState
        let goalLine = goalLine(for: snapshot, locale: locale)
        switch state {
        case .lockedTeaser:
            return NetDailyPaceEntry(
                date: date,
                snapshot: snapshot,
                displayState: .lockedTeaser,
                title: snapshot.lockedTeaserTitle,
                primaryLine: snapshot.lockedTeaserSubtitle,
                secondaryLine: WidgetCopy.lockedCTA(locale: locale),
                goalLine: goalLine,
                deepLinkURL: URL(string: snapshot.deepLinkURL),
                accessibilityLabel: "\(snapshot.lockedTeaserTitle). \(snapshot.lockedTeaserSubtitle). \(WidgetCopy.lockedCTA(locale: locale)). \(goalLine)",
                paceStatus: snapshot.paceStatus,
                usesHeroTypography: false
            )
        case .stale:
            return NetDailyPaceEntry(
                date: date,
                snapshot: snapshot,
                displayState: .stale,
                title: WidgetCopy.paceLabel(locale: locale),
                primaryLine: snapshot.staleMessage,
                secondaryLine: "",
                goalLine: goalLine,
                deepLinkURL: URL(string: snapshot.deepLinkURL),
                accessibilityLabel: "\(WidgetCopy.paceLabel(locale: locale)). \(snapshot.staleMessage). \(goalLine)",
                paceStatus: "insufficientData",
                usesHeroTypography: false
            )
        case .insufficientData:
            let shortStatus = WidgetDisplayCopy.shortPaceStatusCopy(paceStatus: snapshot.paceStatus, locale: locale)
            return NetDailyPaceEntry(
                date: date,
                snapshot: snapshot,
                displayState: .insufficientData,
                title: WidgetCopy.paceLabel(locale: locale),
                primaryLine: shortStatus,
                secondaryLine: "",
                goalLine: goalLine,
                deepLinkURL: URL(string: snapshot.deepLinkURL),
                accessibilityLabel: "\(WidgetCopy.paceLabel(locale: locale)). \(shortStatus). \(goalLine)",
                paceStatus: snapshot.paceStatus,
                usesHeroTypography: false
            )
        case .missing:
            return NetDailyPaceEntry(
                date: date,
                snapshot: snapshot,
                displayState: .missing,
                title: WidgetCopy.paceLabel(locale: locale),
                primaryLine: snapshot.missingMessage,
                secondaryLine: "",
                goalLine: goalLine,
                deepLinkURL: URL(string: snapshot.deepLinkURL),
                accessibilityLabel: "\(WidgetCopy.paceLabel(locale: locale)). \(snapshot.missingMessage). \(goalLine)",
                paceStatus: snapshot.paceStatus,
                usesHeroTypography: false
            )
        case .unlocked:
            let currencyCode = snapshot.currencyCode
            let primaryLine = WidgetCurrencyFormatting.signedDailyPace(
                snapshot.netDailyPace,
                currencyCode: currencyCode,
                locale: locale
            )
            let secondaryLine = WidgetDisplayCopy.shortPaceStatusCopy(paceStatus: snapshot.paceStatus, locale: locale)
            return NetDailyPaceEntry(
                date: date,
                snapshot: snapshot,
                displayState: .unlocked,
                title: WidgetCopy.paceLabel(locale: locale),
                primaryLine: primaryLine,
                secondaryLine: secondaryLine,
                goalLine: goalLine,
                deepLinkURL: URL(string: snapshot.deepLinkURL),
                accessibilityLabel: "\(secondaryLine). \(primaryLine). \(goalLine)",
                paceStatus: snapshot.paceStatus,
                usesHeroTypography: true
            )
        }
    }

    private func localeForSnapshot(_ snapshot: WidgetSnapshot?) -> Locale {
        guard let code = snapshot?.appLanguageCode, !code.isEmpty else { return .current }
        return Locale(identifier: code)
    }

    private func goalLine(for snapshot: WidgetSnapshot, locale: Locale) -> String {
        guard snapshot.savingsTargetAmount > 0 else {
            return WidgetCopy.noGoal(locale: locale)
        }

        let rawProgress = (snapshot.savingsCurrentAmount / snapshot.savingsTargetAmount) * 100
        let progress = max(0, min(100, Int(rawProgress.rounded())))
        return "\(WidgetCopy.goalPrefix(locale: locale)) \(progress)%"
    }
}

// MARK: - Entry View

struct NetDailyPaceWidgetEntryView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.widgetFamily) private var widgetFamily

    let entry: NetDailyPaceProvider.Entry

    var body: some View {
        Group {
            switch widgetFamily {
            case .systemMedium:
                mediumLayout
            default:
                smallLayout
            }
        }
        .padding(widgetFamily == .systemSmall ? 10 : WidgetDesignTokens.padding)
        .widgetURL(entry.deepLinkURL)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(entry.accessibilityLabel)
        .containerBackground(for: .widget) {
            WidgetDesignTokens.background(for: colorScheme)
        }
    }

    private var smallLayout: some View {
        VStack(alignment: .leading, spacing: 4) {
            smallHeaderRow

            Text(entry.goalLine)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(secondaryTextColor)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .allowsTightening(true)

            Spacer(minLength: 0)

            primaryText
                .font(.system(size: smallHeroNumberSize, weight: .semibold, design: .rounded))
                .minimumScaleFactor(0.52)
                .lineLimit(1)
                .allowsTightening(true)

            if !entry.secondaryLine.isEmpty {
                Text(entry.secondaryLine)
                    .font(.caption2)
                    .foregroundStyle(secondaryTextColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .allowsTightening(true)
            }
        }
    }

    private var mediumLayout: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                headerRow

                primaryText
                    .font(.system(size: heroNumberSize, weight: .semibold, design: .rounded))
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            if !entry.secondaryLine.isEmpty {
                Text(entry.secondaryLine)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(statusSupportingColor)
                    .multilineTextAlignment(.trailing)
                    .lineLimit(3)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: 120, alignment: .trailing)
            }
        }
    }

    private var primaryText: some View {
        Text(entry.primaryLine)
            .foregroundStyle(primaryTextColor)
    }

    private var smallHeaderRow: some View {
        HStack(spacing: 4) {
            Text(entry.title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(secondaryTextColor)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .allowsTightening(true)

            Spacer(minLength: 0)

            if entry.displayState == .lockedTeaser {
                Image(systemName: "lock.fill")
                    .font(.caption2)
                    .foregroundStyle(WidgetDesignTokens.lockedAccent)
            }
        }
    }

    private var headerRow: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
                .font(.caption2)
                .foregroundStyle(headerIconColor)

            Text(entry.title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(secondaryTextColor)
                .lineLimit(1)

            Spacer(minLength: 0)

            if entry.displayState == .lockedTeaser {
                Image(systemName: "lock.fill")
                    .font(.caption2)
                    .foregroundStyle(WidgetDesignTokens.lockedAccent)
            }
        }
    }

    private var heroNumberSize: CGFloat {
        if entry.usesHeroTypography {
            return widgetFamily == .systemMedium
                ? WidgetDesignTokens.widgetNumberSizeMedium
                : WidgetDesignTokens.widgetNumberSize
        }
        return widgetFamily == .systemMedium ? 20 : 17
    }

    private var smallHeroNumberSize: CGFloat {
        if entry.usesHeroTypography {
            return max(24, WidgetDesignTokens.widgetNumberSize - 2)
        }
        return 18
    }

    private var primaryTextColor: Color {
        switch entry.displayState {
        case .unlocked:
            return WidgetDesignTokens.statusColor(for: entry.paceStatus, colorScheme: colorScheme)
        case .lockedTeaser:
            return WidgetDesignTokens.textPrimary(for: colorScheme)
        default:
            return WidgetDesignTokens.textPrimary(for: colorScheme)
        }
    }

    private var secondaryTextColor: Color {
        WidgetDesignTokens.textSecondary(for: colorScheme)
    }

    private var statusSupportingColor: Color {
        switch entry.displayState {
        case .unlocked:
            return WidgetDesignTokens.statusColor(for: entry.paceStatus, colorScheme: colorScheme)
        case .lockedTeaser:
            return WidgetDesignTokens.lockedAccent
        default:
            return secondaryTextColor
        }
    }

    private var headerIconColor: Color {
        switch entry.displayState {
        case .lockedTeaser:
            return WidgetDesignTokens.lockedAccent
        case .missing, .stale:
            return secondaryTextColor
        case .unlocked:
            return WidgetDesignTokens.statusColor(for: entry.paceStatus, colorScheme: colorScheme)
        case .insufficientData:
            return secondaryTextColor
        }
    }

    private var iconName: String {
        switch entry.displayState {
        case .lockedTeaser: return "crown.fill"
        case .missing, .stale: return "arrow.clockwise"
        case .insufficientData: return "chart.line.uptrend.xyaxis"
        case .unlocked:
            switch entry.paceStatus {
            case "movingForward": return "arrow.up.right"
            case "slowingDown": return "arrow.down.right"
            case "neutral": return "arrow.right"
            default: return "chart.line.uptrend.xyaxis"
            }
        }
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    NetDailyPaceWidget()
} timeline: {
    let previewLocale = Locale(identifier: "en")
    NetDailyPaceEntry(
        date: Date(),
        snapshot: nil,
        displayState: .unlocked,
        title: WidgetCopy.paceLabel(locale: previewLocale),
        primaryLine: "+$12/day",
        secondaryLine: "Moving forward",
        goalLine: "Goal 64%",
        deepLinkURL: URL(string: WidgetConstants.unlockedDeepLink),
        accessibilityLabel: "Moving forward. +$12/day",
        paceStatus: "movingForward",
        usesHeroTypography: true
    )
    NetDailyPaceEntry(
        date: Date(),
        snapshot: nil,
        displayState: .lockedTeaser,
        title: WidgetCopy.lockedTitle(locale: previewLocale),
        primaryLine: WidgetCopy.lockedSubtitle(locale: previewLocale),
        secondaryLine: WidgetCopy.lockedCTA(locale: previewLocale),
        goalLine: WidgetCopy.noGoal(locale: previewLocale),
        deepLinkURL: URL(string: WidgetConstants.lockedDeepLink),
        accessibilityLabel: WidgetCopy.lockedSubtitle(locale: previewLocale),
        paceStatus: "insufficientData",
        usesHeroTypography: false
    )
}

#Preview(as: .systemMedium) {
    NetDailyPaceWidget()
} timeline: {
    let previewLocale = Locale(identifier: "tr")
    NetDailyPaceEntry(
        date: Date(),
        snapshot: nil,
        displayState: .unlocked,
        title: WidgetCopy.paceLabel(locale: previewLocale),
        primaryLine: "+₺120/gün",
        secondaryLine: "İleri gidiyorsun",
        goalLine: "Hedef 64%",
        deepLinkURL: URL(string: WidgetConstants.unlockedDeepLink),
        accessibilityLabel: "İleri gidiyorsun. +₺120/gün",
        paceStatus: "movingForward",
        usesHeroTypography: true
    )
}
