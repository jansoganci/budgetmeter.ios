//
//  GreetingHeader.swift
//  BudgetMeter
//
//  Design System v2.1 - Time-based Greeting Header
//  Displays personalized greeting based on time of day
//

import SwiftUI

/// Time-based greeting header with icon
/// Shows "Good morning/afternoon/evening/night" based on current hour
struct GreetingHeader: View {

    // MARK: - Properties

    /// The greeting text to display
    let greeting: String

    /// SF Symbol name for the icon
    let iconName: String

    // MARK: - Environment

    @Environment(\.sizeCategory) var sizeCategory

    // MARK: - Computed Properties

    private var iconColor: Color {
        switch iconName {
        case "sun.max.fill": return .yellow
        case "sun.min.fill": return .orange
        case "sunset.fill": return .orange
        case "moon.stars.fill": return .purple
        default: return .brandProgress
        }
    }

    // MARK: - Initialization

    init(greeting: String, iconName: String) {
        self.greeting = greeting
        self.iconName = iconName
    }

    /// Convenience initializer that calculates greeting from current time
    init() {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            self.greeting = String(localized: "home.greeting.morning", defaultValue: "Good morning!")
            self.iconName = "sun.max.fill"
        case 12..<17:
            self.greeting = String(localized: "home.greeting.afternoon", defaultValue: "Good afternoon!")
            self.iconName = "sun.min.fill"
        case 17..<21:
            self.greeting = String(localized: "home.greeting.evening", defaultValue: "Good evening!")
            self.iconName = "sunset.fill"
        default:
            self.greeting = String(localized: "home.greeting.night", defaultValue: "Good night!")
            self.iconName = "moon.stars.fill"
        }
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: iconName)
                .font(.system(size: 22 * sizeCategory.scaleFactor, weight: .medium))
                .foregroundColor(iconColor)

            Text(greeting)
                .font(.system(size: 20 * sizeCategory.scaleFactor, weight: .semibold))
                .foregroundColor(.textPrimary)

            Spacer()
        }
        .padding(.vertical, Spacing.xs)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(greeting)
    }
}

// MARK: - Preview

#Preview("Morning") {
    VStack(spacing: Spacing.lg) {
        GreetingHeader(greeting: "Good morning!", iconName: "sun.max.fill")
        GreetingHeader(greeting: "Good afternoon!", iconName: "sun.min.fill")
        GreetingHeader(greeting: "Good evening!", iconName: "sunset.fill")
        GreetingHeader(greeting: "Good night!", iconName: "moon.stars.fill")
    }
    .padding()
    .background(Color.appBackground)
}

#Preview("Auto Time") {
    GreetingHeader()
        .padding()
        .background(Color.appBackground)
}

#Preview("Dark Mode") {
    VStack(spacing: Spacing.lg) {
        GreetingHeader(greeting: "Good morning!", iconName: "sun.max.fill")
        GreetingHeader(greeting: "Good evening!", iconName: "sunset.fill")
    }
    .padding()
    .background(Color.appBackground)
    .preferredColorScheme(.dark)
}
