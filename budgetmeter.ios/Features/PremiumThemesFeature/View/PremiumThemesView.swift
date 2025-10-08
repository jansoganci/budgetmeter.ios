//
//  PremiumThemesView.swift
//  BudgetMeter
//
//  Created by BudgetMeter Team on 17.09.2025.
//

import SwiftUI

struct PremiumThemesView: View {
    @StateObject private var premiumManager = PremiumManager.shared
    @State private var selectedTheme = "default"
    
    let themes = [
        Theme(name: "Default", color: Color.blue, icon: "paintbrush"),
        Theme(name: "Ocean", color: Color.cyan, icon: "drop"),
        Theme(name: "Forest", color: Color.green, icon: "leaf"),
        Theme(name: "Sunset", color: Color.orange, icon: "sun.max"),
        Theme(name: "Purple", color: Color.purple, icon: "sparkles"),
        Theme(name: "Midnight", color: Color.indigo, icon: "moon.stars")
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Premium Themes")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Choose from beautiful color themes and custom app icons to personalize your BudgetMeter experience.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 20) {
                    ForEach(themes, id: \.name) { theme in
                        ThemeCard(
                            theme: theme,
                            isSelected: selectedTheme == theme.name,
                            onSelect: { selectedTheme = theme.name }
                        )
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                Button("Apply Theme") {
                    // TODO: Implement theme application
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.horizontal)
            }
            .padding()
            .navigationTitle("Themes")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct ThemeCard: View {
    let theme: Theme
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 10) {
                Image(systemName: theme.icon)
                    .font(.system(size: 40))
                    .foregroundColor(theme.color)
                
                Text(theme.name)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            .frame(height: 120)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(theme.color.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? theme.color : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

struct Theme {
    let name: String
    let color: Color
    let icon: String
}

#Preview {
    PremiumThemesView()
}
