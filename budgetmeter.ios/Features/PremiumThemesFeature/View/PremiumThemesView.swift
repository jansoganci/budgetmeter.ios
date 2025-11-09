//
//  PremiumThemesView.swift
//  BudgetMeter
//
//  Created by BudgetMeter Team on 17.09.2025.
//

import SwiftUI

struct PremiumThemesView: View {
    @StateObject private var premiumManager = PremiumManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    @State private var selectedTheme: AppTheme = .default
    @State private var showSuccessAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Premium Themes")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("Choose from beautiful color themes to personalize your BudgetMeter experience.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal)

                    // Themes Grid
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                        ForEach(AppTheme.allThemes, id: \.rawValue) { theme in
                            ThemeCard(
                                theme: theme,
                                isSelected: selectedTheme == theme,
                                isCurrent: themeManager.currentTheme == theme,
                                onSelect: { selectedTheme = theme }
                            )
                        }
                    }
                    .padding(.horizontal)

                    // Current Theme Info
                    if themeManager.currentTheme == selectedTheme {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Currently Active")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 8)
                    }

                    // Apply Button
                    Button(action: applyTheme) {
                        HStack {
                            Image(systemName: "paintbrush.fill")
                            Text("Apply Theme")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedTheme.primaryColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(themeManager.currentTheme == selectedTheme)
                    .opacity(themeManager.currentTheme == selectedTheme ? 0.5 : 1.0)
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
                .padding(.vertical)
            }
            .navigationTitle("Themes")
            .navigationBarTitleDisplayMode(.large)
            .alert("Theme Applied!", isPresented: $showSuccessAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("\(selectedTheme.displayName) theme has been applied successfully!")
            }
        }
        .onAppear {
            selectedTheme = themeManager.currentTheme
        }
    }

    // MARK: - Private Methods

    private func applyTheme() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            themeManager.applyTheme(selectedTheme)
            showSuccessAlert = true
        }

        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

struct ThemeCard: View {
    let theme: AppTheme
    let isSelected: Bool
    let isCurrent: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: theme.gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)

                    Image(systemName: theme.icon)
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                }

                // Name
                Text(theme.displayName)
                    .font(.headline)
                    .foregroundColor(.primary)

                // Current Badge
                if isCurrent {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption2)
                        Text("Active")
                            .font(.caption2)
                    }
                    .foregroundColor(.green)
                }
            }
            .frame(height: 140)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.primaryColor.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? theme.primaryColor : Color.clear,
                                lineWidth: 3
                            )
                    )
            )
            .shadow(
                color: isSelected ? theme.primaryColor.opacity(0.3) : Color.clear,
                radius: 8,
                x: 0,
                y: 4
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

#Preview {
    PremiumThemesView()
}
