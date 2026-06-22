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
    @Environment(\.themeAccent) private var themeAccent

    var body: some View {
        NavigationView {
            ZStack {
                AppBackground()

                ScrollView {
                    SettingsSection {
                        ForEach(Array(SettingsViewModel.AppearanceMode.allCases.enumerated()), id: \.element) { index, mode in
                            Button {
                                onSelect(mode)
                                dismiss()
                            } label: {
                                HStack(spacing: Spacing.md) {
                                    Image(systemName: iconForMode(mode))
                                        .font(.body.weight(.medium))
                                        .foregroundColor(themeAccent)
                                        .frame(width: 32, height: 32)
                                        .background(themeAccent.opacity(0.12))
                                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous))
                                        .accessibilityHidden(true)

                                    Text(mode.displayName)
                                        .bodyStyle()

                                    Spacer()

                                    if selectedAppearance == mode {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(themeAccent)
                                            .font(.body.weight(.semibold))
                                            .accessibilityHidden(true)
                                    }
                                }
                                .padding(.horizontal, Spacing.md)
                                .padding(.vertical, Spacing.sm)
                                .frame(minHeight: LayoutSpacing.rowHeight)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(mode.displayName)
                            .accessibilityValue(
                                selectedAppearance == mode
                                    ? "settings.appearance.selected".localized(defaultValue: "Selected", table: "UI")
                                    : ""
                            )
                            .accessibilityAddTraits(selectedAppearance == mode ? [.isSelected] : [])

                            if index != SettingsViewModel.AppearanceMode.allCases.count - 1 {
                                SettingsDivider()
                            }
                        }
                    }
                    .padding(.horizontal, LayoutSpacing.screenPadding)
                    .padding(.vertical, Spacing.md)
                }
            }
            .navigationTitle("settings.appearance.title".localized(defaultValue: "Appearance", table: "UI"))
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
