//
//  NetDailyPaceWidget.swift
//  BudgetMeterWidgets
//
//  Net daily pace widget — systemSmall + systemMedium.
//

import WidgetKit
import SwiftUI

private enum WidgetCopy {
    static var paceLabel: String {
        String(localized: "widget.pace.label", defaultValue: "Today's pace", table: "UI")
    }

    static var lockedTitle: String {
        String(localized: "widget.locked.title", defaultValue: "Premium Widget", table: "UI")
    }

    static var lockedSubtitle: String {
        String(
            localized: "widget.locked.subtitle",
            defaultValue: "Unlock net daily pace on your Home Screen",
            table: "UI"
        )
    }

    static var missingMessage: String {
        String(
            localized: "widget.missing.message",
            defaultValue: "Open BudgetMeter to refresh",
            table: "UI"
        )
    }

    static var staleMessage: String {
        String(
            localized: "widget.stale.message",
            defaultValue: "Open BudgetMeter for the latest pace",
            table: "UI"
        )
    }

    static var lockedCTA: String {
        String(localized: "widget.locked.cta", defaultValue: "Upgrade to unlock", table: "UI")
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
    let deepLinkURL: URL?
    let accessibilityLabel: String
    let paceStatus: String
    let usesHeroTypography: Bool
}

// MARK: - Provider

struct NetDailyPaceProvider: TimelineProvider {
    private let store = WidgetSnapshotStore()

    func placeholder(in context: Context) -> NetDailyPaceEntry {
        makeEntry(
            from: WidgetSnapshot(
                schemaVersion: WidgetConstants.schemaVersion,
                netDailyPace: 12,
                paceStatus: "movingForward",
                displayValue: "+$12/day",
                displayStatusCopy: "Moving forward +$12/day",
                currencyCode: "USD",
                currencySymbol: "$",
                isPremium: true,
                generatedAt: Date(),
                staleAfter: Date().addingTimeInterval(WidgetConstants.staleInterval),
                isLockedTeaser: false,
                lockedTeaserTitle: WidgetCopy.lockedTitle,
                lockedTeaserSubtitle: WidgetCopy.lockedSubtitle,
                deepLinkURL: WidgetConstants.unlockedDeepLink,
                hasFinancialInput: true,
                displayState: .unlocked,
                missingMessage: WidgetCopy.missingMessage,
                staleMessage: WidgetCopy.staleMessage
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
        guard let snapshot else {
            let missing = WidgetCopy.missingMessage
            return NetDailyPaceEntry(
                date: date,
                snapshot: nil,
                displayState: .missing,
                title: WidgetCopy.paceLabel,
                primaryLine: missing,
                secondaryLine: "",
                deepLinkURL: URL(string: WidgetConstants.unlockedDeepLink),
                accessibilityLabel: "\(WidgetCopy.paceLabel). \(missing)",
                paceStatus: "insufficientData",
                usesHeroTypography: false
            )
        }

        let state = snapshot.resolvedDisplayState
        switch state {
        case .lockedTeaser:
            return NetDailyPaceEntry(
                date: date,
                snapshot: snapshot,
                displayState: .lockedTeaser,
                title: snapshot.lockedTeaserTitle,
                primaryLine: snapshot.lockedTeaserSubtitle,
                secondaryLine: WidgetCopy.lockedCTA,
                deepLinkURL: URL(string: snapshot.deepLinkURL),
                accessibilityLabel: "\(snapshot.lockedTeaserTitle). \(snapshot.lockedTeaserSubtitle). \(WidgetCopy.lockedCTA)",
                paceStatus: snapshot.paceStatus,
                usesHeroTypography: false
            )
        case .stale:
            return NetDailyPaceEntry(
                date: date,
                snapshot: snapshot,
                displayState: .stale,
                title: WidgetCopy.paceLabel,
                primaryLine: snapshot.staleMessage,
                secondaryLine: "",
                deepLinkURL: URL(string: snapshot.deepLinkURL),
                accessibilityLabel: "\(WidgetCopy.paceLabel). \(snapshot.staleMessage)",
                paceStatus: "insufficientData",
                usesHeroTypography: false
            )
        case .insufficientData:
            let shortStatus = WidgetDisplayCopy.shortPaceStatusCopy(paceStatus: snapshot.paceStatus)
            return NetDailyPaceEntry(
                date: date,
                snapshot: snapshot,
                displayState: .insufficientData,
                title: WidgetCopy.paceLabel,
                primaryLine: shortStatus,
                secondaryLine: "",
                deepLinkURL: URL(string: snapshot.deepLinkURL),
                accessibilityLabel: "\(WidgetCopy.paceLabel). \(shortStatus)",
                paceStatus: snapshot.paceStatus,
                usesHeroTypography: false
            )
        case .missing:
            return NetDailyPaceEntry(
                date: date,
                snapshot: snapshot,
                displayState: .missing,
                title: WidgetCopy.paceLabel,
                primaryLine: snapshot.missingMessage,
                secondaryLine: "",
                deepLinkURL: URL(string: snapshot.deepLinkURL),
                accessibilityLabel: "\(WidgetCopy.paceLabel). \(snapshot.missingMessage)",
                paceStatus: snapshot.paceStatus,
                usesHeroTypography: false
            )
        case .unlocked:
            let locale = Locale.current
            let currencyCode = snapshot.currencyCode
            let primaryLine = WidgetCurrencyFormatting.signedDailyPace(
                snapshot.netDailyPace,
                currencyCode: currencyCode,
                locale: locale
            )
            let secondaryLine = WidgetDisplayCopy.shortPaceStatusCopy(paceStatus: snapshot.paceStatus)
            return NetDailyPaceEntry(
                date: date,
                snapshot: snapshot,
                displayState: .unlocked,
                title: WidgetCopy.paceLabel,
                primaryLine: primaryLine,
                secondaryLine: secondaryLine,
                deepLinkURL: URL(string: snapshot.deepLinkURL),
                accessibilityLabel: "\(secondaryLine). \(primaryLine)",
                paceStatus: snapshot.paceStatus,
                usesHeroTypography: true
            )
        }
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
        .padding(WidgetDesignTokens.padding)
        .widgetURL(entry.deepLinkURL)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(entry.accessibilityLabel)
        .containerBackground(for: .widget) {
            WidgetDesignTokens.background(for: colorScheme)
        }
    }

    private var smallLayout: some View {
        VStack(alignment: .leading, spacing: 6) {
            headerRow

            Spacer(minLength: 0)

            primaryText
                .font(.system(size: heroNumberSize, weight: .semibold, design: .rounded))
                .minimumScaleFactor(0.7)
                .lineLimit(2)

            if !entry.secondaryLine.isEmpty {
                Text(entry.secondaryLine)
                    .font(.caption)
                    .foregroundStyle(secondaryTextColor)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
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
    NetDailyPaceEntry(
        date: Date(),
        snapshot: nil,
        displayState: .unlocked,
        title: WidgetCopy.paceLabel,
        primaryLine: "+$12/day",
        secondaryLine: "Moving forward",
        deepLinkURL: URL(string: WidgetConstants.unlockedDeepLink),
        accessibilityLabel: "Moving forward. +$12/day",
        paceStatus: "movingForward",
        usesHeroTypography: true
    )
    NetDailyPaceEntry(
        date: Date(),
        snapshot: nil,
        displayState: .lockedTeaser,
        title: WidgetCopy.lockedTitle,
        primaryLine: WidgetCopy.lockedSubtitle,
        secondaryLine: WidgetCopy.lockedCTA,
        deepLinkURL: URL(string: WidgetConstants.lockedDeepLink),
        accessibilityLabel: WidgetCopy.lockedSubtitle,
        paceStatus: "insufficientData",
        usesHeroTypography: false
    )
}

#Preview(as: .systemMedium) {
    NetDailyPaceWidget()
} timeline: {
    NetDailyPaceEntry(
        date: Date(),
        snapshot: nil,
        displayState: .unlocked,
        title: WidgetCopy.paceLabel,
        primaryLine: "+₺120/gün",
        secondaryLine: "İleri gidiyorsun",
        deepLinkURL: URL(string: WidgetConstants.unlockedDeepLink),
        accessibilityLabel: "İleri gidiyorsun. +₺120/gün",
        paceStatus: "movingForward",
        usesHeroTypography: true
    )
}
