//
//  FinancialCategoryWriteSupport.swift
//  BudgetMeter
//
//  Entry-kind metadata and display filters for FinancialCategory rows.
//

import Foundation
import CoreData

enum FinancialCategoryEntryKind: String {
    case recurring = "recurring"
    case oneTime = "oneTime"
}

enum FinancialCategoryWriteSupport {

    static let recurringFrequencies: Set<String> = ["daily", "weekly", "monthly", "yearly"]

    static func applyMetadata(
        to category: FinancialCategory,
        entryKind: FinancialCategoryEntryKind,
        recurringFrequency: String,
        occurrenceDate: Date = Date(),
        sourceType: String? = nil,
        sourceID: String? = nil
    ) {
        category.entryKind = entryKind.rawValue
        category.isActive = true
        category.lastModified = Date()

        if let sourceType {
            category.sourceType = sourceType
        }
        if let sourceID {
            category.sourceID = sourceID
        }

        switch entryKind {
        case .recurring:
            category.frequency = recurringFrequency
        case .oneTime:
            category.frequency = "once"
            category.occurrenceDate = occurrenceDate
        }
    }

    static func touchModified(_ category: FinancialCategory) {
        category.lastModified = Date()
        category.isActive = true

        let kind = normalized(category.entryKind)
        if kind.isEmpty {
            category.entryKind = FinancialCategoryEntryKind.recurring.rawValue
        }
    }

    static func isRecurringDisplayCategory(_ category: FinancialCategory) -> Bool {
        if normalized(category.entryKind) == FinancialCategoryEntryKind.oneTime.rawValue {
            return false
        }
        let frequency = normalized(category.frequency)
        if frequency == "recurring" || frequency == "once" {
            return false
        }
        return recurringFrequencies.contains(frequency)
    }

    static func isOneTimeDisplayCategory(_ category: FinancialCategory) -> Bool {
        if normalized(category.entryKind) == FinancialCategoryEntryKind.oneTime.rawValue {
            return true
        }
        return normalized(category.frequency) == "once"
    }

    private static func normalized(_ value: String?) -> String {
        value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}
