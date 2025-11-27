//
//  CategoryColors.swift
//  BudgetMeter
//
//  Design System v2.1 - Category Color Palette
//  Color-coded icons for financial categories
//

import SwiftUI

// MARK: - Category Color Palette

/// Predefined color palette for financial categories
/// Used for both predefined (fixed) and custom (user-selectable) categories
enum CategoryColor: String, CaseIterable, Identifiable {
    case blue
    case green
    case purple
    case orange
    case red
    case pink
    case teal
    case gray

    var id: String { rawValue }

    /// Display name for color picker UI
    var displayName: String {
        switch self {
        case .blue: return String(localized: "color.blue", defaultValue: "Blue")
        case .green: return String(localized: "color.green", defaultValue: "Green")
        case .purple: return String(localized: "color.purple", defaultValue: "Purple")
        case .orange: return String(localized: "color.orange", defaultValue: "Orange")
        case .red: return String(localized: "color.red", defaultValue: "Red")
        case .pink: return String(localized: "color.pink", defaultValue: "Pink")
        case .teal: return String(localized: "color.teal", defaultValue: "Teal")
        case .gray: return String(localized: "color.gray", defaultValue: "Gray")
        }
    }

    /// SwiftUI Color (adapts to light/dark mode)
    var color: Color {
        switch self {
        case .blue:
            return Color(light: Color(hex: "3B82F6"), dark: Color(hex: "60A5FA"))
        case .green:
            return Color(light: Color(hex: "10B981"), dark: Color(hex: "34D399"))
        case .purple:
            return Color(light: Color(hex: "8B5CF6"), dark: Color(hex: "A78BFA"))
        case .orange:
            return Color(light: Color(hex: "F59E0B"), dark: Color(hex: "FBBF24"))
        case .red:
            return Color(light: Color(hex: "EF4444"), dark: Color(hex: "F87171"))
        case .pink:
            return Color(light: Color(hex: "EC4899"), dark: Color(hex: "F472B6"))
        case .teal:
            return Color(light: Color(hex: "14B8A6"), dark: Color(hex: "2DD4BF"))
        case .gray:
            return Color(light: Color(hex: "6B7280"), dark: Color(hex: "9CA3AF"))
        }
    }

    /// Initialize from a color name string
    static func from(_ name: String?) -> CategoryColor {
        guard let name = name else { return .gray }
        return CategoryColor(rawValue: name.lowercased()) ?? .gray
    }
}

// MARK: - Predefined Category Colors

/// Fixed color assignments for predefined categories
/// These cannot be changed by users - provides visual consistency
enum PredefinedCategoryColor {

    /// Returns the fixed color for a predefined category
    static func color(for uniqueID: String) -> CategoryColor {
        // Income Categories
        let incomeColors: [String: CategoryColor] = [
            // Daily Income
            "salary": .blue,
            "freelance": .orange,
            "investment": .green,
            "other_income": .gray,

            // Monthly Income
            "monthly_salary": .blue,
            "rental_income": .purple,
            "passive_income": .green,
            "bonus": .teal,
            "commission": .orange,
            "online_business": .purple,
            "education": .blue,
            "consulting": .teal,
            "social_media": .pink,
            "youtube": .red,
            "blog": .orange,
            "podcast": .purple,
            "online_course": .blue,
            "affiliate": .green,
            "other_monthly": .gray,

            // Yearly Income
            "yearly_bonus": .teal,
            "investment_return": .green,
            "real_estate_sale": .purple,
            "car_sale": .orange,
            "inheritance": .purple,
            "gift": .pink,
            "prize": .teal,
            "royalty": .blue,
            "patent": .orange,
            "other_yearly": .gray
        ]

        // Expense Categories
        let expenseColors: [String: CategoryColor] = [
            // Daily Expenses
            "food": .orange,
            "tea_coffee": .teal,
            "cigarettes": .gray,
            "transportation": .blue,
            "other": .gray,

            // Monthly Expenses
            "rent": .purple,
            "electricity": .orange,
            "water": .blue,
            "natural_gas": .orange,
            "internet": .blue,
            "phone": .teal,
            "hoa_fees": .purple,
            "maintenance_fees": .gray,
            "car_fuel": .orange,
            "social_security": .red,
            "school_fee": .blue,
            "loan_payment": .red,
            "credit_card": .red,
            "gym_monthly": .green,
            "streaming_services": .pink,

            // Yearly Expenses
            "car_maintenance": .orange,
            "car_insurance": .blue,
            "vehicle_tax": .gray,
            "comprehensive_insurance": .blue,
            "vehicle_inspection": .gray,
            "property_insurance": .purple,
            "health_insurance": .red,
            "property_tax": .purple,
            "vacation": .teal,
            "gym_yearly": .green
        ]

        // Check income first, then expense
        if let color = incomeColors[uniqueID] {
            return color
        }
        if let color = expenseColors[uniqueID] {
            return color
        }

        // Default fallback
        return .gray
    }
}

// MARK: - Category Color Helper Extension

extension DataSeedingService {

    /// Returns the Color for a category (predefined or custom)
    static func color(for category: FinancialCategory) -> Color {
        if category.isCustom {
            // Custom category: use stored color name or default to gray
            let colorName = category.customColorHex ?? "gray"
            return CategoryColor.from(colorName).color
        } else {
            // Predefined category: use fixed color mapping
            let uniqueID = category.uniqueID ?? ""
            return PredefinedCategoryColor.color(for: uniqueID).color
        }
    }

    /// Returns the CategoryColor enum for a category
    static func categoryColor(for category: FinancialCategory) -> CategoryColor {
        if category.isCustom {
            let colorName = category.customColorHex ?? "gray"
            return CategoryColor.from(colorName)
        } else {
            let uniqueID = category.uniqueID ?? ""
            return PredefinedCategoryColor.color(for: uniqueID)
        }
    }
}
