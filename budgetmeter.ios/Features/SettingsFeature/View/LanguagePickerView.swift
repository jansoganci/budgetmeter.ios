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

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(languages, id: \.self) { language in
                        languageRow(for: language)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("settings.language.picker.title".localized(defaultValue: "Language"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    @ViewBuilder
    private func languageRow(for language: SettingsViewModel.LanguageMode) -> some View {
        Button {
            onSelect(language)
            dismiss()
        } label: {
            HStack(spacing: 12) {
                Text(language.flag)
                    .font(.title2)
                    .frame(width: 32, alignment: .leading)

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
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .accessibilityLabel(accessibilityLabel(for: language))
        .accessibilityValue(selectedLanguage == language ? "settings.language.row.accessibility_selected".localized(defaultValue: "Selected") : "")
    }

    private func accessibilityLabel(for language: SettingsViewModel.LanguageMode) -> String {
        let format = "settings.language.accessibility_format".localized(defaultValue: "%@ %@")
        return String(format: format, language.flag, language.displayName)
    }
}

#Preview {
    LanguagePickerView(
        languages: SettingsViewModel.LanguageMode.allCases,
        selectedLanguage: .english,
        onSelect: { _ in }
    )
}
