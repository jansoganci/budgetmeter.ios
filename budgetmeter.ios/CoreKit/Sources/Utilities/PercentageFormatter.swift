//
//  PercentageFormatter.swift
//  BudgetMeter
//
//  Created by BudgetMeter Team
//

import Foundation

/// Locale-aware percentage formatter for consistent percentage display across the app
struct PercentageFormatter {
    
    /// Formats a percentage value (0-100) with locale-aware formatting
    /// - Parameters:
    ///   - value: The percentage value (0-100, e.g., 50 for 50%)
    ///   - locale: Optional locale to use (defaults to app's selected locale)
    ///   - minimumFractionDigits: Minimum decimal places (default: 0)
    ///   - maximumFractionDigits: Maximum decimal places (default: 1)
    /// - Returns: Formatted percentage string (e.g., "50%", "50.5%")
    static func format(
        _ value: Double,
        locale: Locale? = nil,
        minimumFractionDigits: Int = 0,
        maximumFractionDigits: Int = 1
    ) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = minimumFractionDigits
        formatter.maximumFractionDigits = maximumFractionDigits
        formatter.locale = locale ?? LocalizationManager.shared.currentLocale
        
        // Convert 0-100 range to 0-1 range for NumberFormatter
        let normalizedValue = value / 100.0
        return formatter.string(from: NSNumber(value: normalizedValue)) ?? "\(Int(value))%"
    }
    
    /// Formats a percentage value as an integer (no decimals)
    /// - Parameters:
    ///   - value: The percentage value (0-100, e.g., 50 for 50%)
    ///   - locale: Optional locale to use (defaults to app's selected locale)
    /// - Returns: Formatted percentage string (e.g., "50%")
    static func formatInteger(
        _ value: Double,
        locale: Locale? = nil
    ) -> String {
        return format(value, locale: locale, minimumFractionDigits: 0, maximumFractionDigits: 0)
    }
    
    /// Formats a percentage value with one decimal place
    /// - Parameters:
    ///   - value: The percentage value (0-100, e.g., 50.5 for 50.5%)
    ///   - locale: Optional locale to use (defaults to app's selected locale)
    /// - Returns: Formatted percentage string (e.g., "50.5%")
    static func formatOneDecimal(
        _ value: Double,
        locale: Locale? = nil
    ) -> String {
        return format(value, locale: locale, minimumFractionDigits: 1, maximumFractionDigits: 1)
    }
    
    /// Formats a percentage change with sign (+ or -)
    /// - Parameters:
    ///   - value: The percentage change value (can be negative, e.g., -5.5 for -5.5%)
    ///   - locale: Optional locale to use (defaults to app's selected locale)
    /// - Returns: Formatted percentage string with sign (e.g., "+5.5%", "-5.5%")
    static func formatChange(
        _ value: Double,
        locale: Locale? = nil
    ) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        formatter.positivePrefix = formatter.plusSign
        formatter.locale = locale ?? LocalizationManager.shared.currentLocale
        
        // Convert 0-100 range to 0-1 range for NumberFormatter
        let normalizedValue = value / 100.0
        return formatter.string(from: NSNumber(value: normalizedValue)) ?? (value >= 0 ? "+\(Int(value))%" : "\(Int(value))%")
    }
}

