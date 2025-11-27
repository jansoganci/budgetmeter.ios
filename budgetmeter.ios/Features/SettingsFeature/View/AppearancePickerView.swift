//
//  AppearancePickerView.swift
//  BudgetMeter
//
//  Bottom sheet picker for selecting appearance mode (Light/Dark/System)
//

import SwiftUI

struct AppearancePickerView: View {

    let selectedAppearance: SettingsViewModel.AppearanceMode
    let onSelect: (SettingsViewModel.AppearanceMode) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                ForEach(SettingsViewModel.AppearanceMode.allCases, id: \.self) { mode in
                    Button {
                        onSelect(mode)
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: iconForMode(mode))
                                .foregroundColor(.brandProgress)
                                .frame(width: 24)

                            Text(mode.displayName)
                                .font(.body)
                                .foregroundColor(.primary)

                            Spacer()

                            if selectedAppearance == mode {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.brandProgress)
                                    .font(.system(size: 16, weight: .semibold))
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("settings.appearance.title".localized(defaultValue: "Appearance"))
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

    private func iconForMode(_ mode: SettingsViewModel.AppearanceMode) -> String {
        switch mode {
        case .light: return "sun.max"
        case .dark: return "moon"
        case .system: return "circle.lefthalf.filled"
        }
    }
}

#Preview {
    AppearancePickerView(
        selectedAppearance: .system,
        onSelect: { _ in }
    )
}
