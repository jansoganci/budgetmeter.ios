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
            List {
                Section {
                    ForEach(sortedLanguages, id: \.self) { language in
                        languageRow(for: language)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("settings.language.picker.title".localized(defaultValue: "Language"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("toolbar.done".localized(defaultValue: "Done")) {
                        dismiss()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func languageRow(for language: SettingsViewModel.LanguageMode) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(language.displayName)
                    .font(.body)
                    .foregroundColor(.primary)
                Text(language.rawValue.uppercased())
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if selectedLanguage == language {
                Image(systemName: "checkmark")
                    .foregroundColor(Color(hex: "4A90E2"))
                    .font(.system(size: 16, weight: .semibold))
                    .accessibilityHidden(true)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect(language)
            dismiss()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel(for: language))
        .accessibilityValue(selectedLanguage == language ? "settings.language.row.accessibility_selected".localized(defaultValue: "Selected") : "")
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
