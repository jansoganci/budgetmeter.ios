//
//  DateFormattingHelper.swift
//  BudgetMeter
//
//  Created by BudgetMeter Team
//

import Foundation

/// Centralized date formatting utility with cached formatters for performance optimization.
/// DateFormatter creation is expensive (~10-50ms each), so we cache them in a singleton.
final class DateFormattingHelper {
    static let shared = DateFormattingHelper()

    private init() {}

    // MARK: - Cached Date Formatters

    /// Short date: "1/15/25"
    private lazy var shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()

    /// Medium date: "Jan 15, 2025"
    private lazy var mediumDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    /// Long date: "January 15, 2025"
    private lazy var longDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter
    }()

    /// Medium date, no time: "Jan 15, 2025"
    private lazy var mediumDateNoTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    /// Medium date with short time: "Jan 15, 2025 at 3:30 PM"
    private lazy var mediumDateShortTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    /// Short time only: "3:30 PM"
    private lazy var shortTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

    /// Compact month/day: "Jan 15"
    private lazy var compactMonthDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    /// Compact month/year: "Jan 2025"
    private lazy var compactMonthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter
    }()

    /// ISO8601 for JSON/API
    private lazy var iso8601Formatter = ISO8601DateFormatter()

    // MARK: - Public Formatting Methods

    /// Format date with short style: "1/15/25"
    func formatShort(_ date: Date) -> String {
        shortDateFormatter.string(from: date)
    }

    /// Format date with medium style: "Jan 15, 2025"
    func formatMedium(_ date: Date) -> String {
        mediumDateFormatter.string(from: date)
    }

    /// Format date with long style: "January 15, 2025"
    func formatLong(_ date: Date) -> String {
        longDateFormatter.string(from: date)
    }

    /// Format date with medium style, no time: "Jan 15, 2025"
    func formatMediumNoTime(_ date: Date) -> String {
        mediumDateNoTimeFormatter.string(from: date)
    }

    /// Format date with medium style and short time: "Jan 15, 2025 at 3:30 PM"
    func formatMediumWithTime(_ date: Date) -> String {
        mediumDateShortTimeFormatter.string(from: date)
    }

    /// Format time only with short style: "3:30 PM"
    func formatTime(_ date: Date) -> String {
        shortTimeFormatter.string(from: date)
    }

    /// Format date as compact month/day: "Jan 15"
    func formatMonthDay(_ date: Date) -> String {
        compactMonthDayFormatter.string(from: date)
    }

    /// Format date as compact month/year: "Jan 2025"
    func formatMonthYear(_ date: Date) -> String {
        compactMonthYearFormatter.string(from: date)
    }

    /// Format date as ISO8601 string for JSON/API: "2025-01-15T15:30:00Z"
    func formatISO8601(_ date: Date) -> String {
        iso8601Formatter.string(from: date)
    }
}
