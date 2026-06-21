//
//  LanguagePickerView.swift
//  BudgetMeter
//
//  Created by BudgetMeter Team on 18.09.2025.
//

import SwiftUI

struct LanguagePickerView: View {
    let languages: [SettingsViewModel.LanguageMode]
    let selectedLanguage: SettingsViewModel.LanguageMode
    let onSelect: (SettingsViewModel.LanguageMode) -> Void

    @Environment(\.dismiss) private var dismiss
    
    // Alphabetically sorted languages by display name
    private var sortedLanguages: [SettingsViewModel.LanguageMode] {
        languages.sorted { $0.displayName < $1.displayName }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                ScrollView {
                    SettingsSection {
                        ForEach(Array(sortedLanguages.enumerated()), id: \.element) { index, language in
                            languageRow(for: language)

                            if index != sortedLanguages.count - 1 {
                                SettingsDivider()
                            }
                        }
                    }
                    .padding(.horizontal, LayoutSpacing.screenPadding)
                    .padding(.vertical, Spacing.md)
                }
            }
            .navigationTitle("settings.language.picker.title".localized(defaultValue: "Language", table: "UI"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("toolbar.done".localized(defaultValue: "Done", table: "UI")) {
                        dismiss()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func languageRow(for language: SettingsViewModel.LanguageMode) -> some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: "globe")
                .font(.system(size: 19, weight: .medium))
                .foregroundColor(.accentPrimary)
                .frame(width: 32, height: 32)
                .background(Color.accentPrimary.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(language.displayName)
                    .bodyStyle()
                Text(language.rawValue.uppercased())
                    .captionStyle()
            }

            Spacer()

            if selectedLanguage == language {
                Image(systemName: "checkmark")
                    .foregroundColor(.accentPrimary)
                    .font(.system(size: 16, weight: .semibold))
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .frame(minHeight: LayoutSpacing.rowHeight)
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect(language)
            dismiss()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel(for: language))
        .accessibilityValue(selectedLanguage == language ? "settings.language.row.accessibility_selected".localized(defaultValue: "Selected", table: "UI") : "")
    }

    private func accessibilityLabel(for language: SettingsViewModel.LanguageMode) -> String {
        return language.displayName
    }
}

#Preview {
    LanguagePickerView(
        languages: SettingsViewModel.LanguageMode.allCases,
        selectedLanguage: .english,
        onSelect: { _ in }
    )
}
