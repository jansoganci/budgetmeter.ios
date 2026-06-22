//
//  CreateCategoryModal.swift
//  BudgetMeter
//
//  Modal for creating custom categories — v2 glass section layout.
//

import SwiftUI

/// Modal for creating custom categories inline from Income/Expense views
struct CreateCategoryModal: View {

    let entryIntent: FinancialCategoryEntryKind
    let defaultRecurringFrequency: String
    let type: String
    let onSave: (FinancialCategory) -> Void
    let onCancel: () -> Void

    @State private var categoryName = ""
    @State private var selectedIcon = "tag.fill"
    @State private var selectedColor: CategoryColor = .gray
    @State private var selectedRecurringFrequency: String
    @State private var occurrenceDate = Date()
    @State private var showingValidationError = false
    @State private var validationErrorMessage = ""
    @State private var inlineNameError: String?

    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var validationService = CategoryValidationService()
    @StateObject private var premiumManager = PremiumManager.shared

    init(
        entryIntent: FinancialCategoryEntryKind,
        defaultRecurringFrequency: String = "monthly",
        type: String,
        onSave: @escaping (FinancialCategory) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.entryIntent = entryIntent
        self.defaultRecurringFrequency = defaultRecurringFrequency
        self.type = type
        self.onSave = onSave
        self.onCancel = onCancel
        _selectedRecurringFrequency = State(initialValue: defaultRecurringFrequency)
    }

    private var accentColor: Color {
        type == "income" ? .financialPositive : .brandExpense
    }

    private var navigationTitle: String {
        switch entryIntent {
        case .oneTime:
            return type == "income"
                ? String(localized: "category.modal.title.one_time_income", defaultValue: "Add One-Time Income", table: "UI")
                : String(localized: "category.modal.title.one_time_expense", defaultValue: "Add One-Time Expense", table: "UI")
        case .recurring:
            return String(format: "category.modal.title.add".localized(defaultValue: "Add %@ Category"), type.capitalized)
        }
    }

    private var previewFrequencyLabel: String {
        switch entryIntent {
        case .oneTime:
            return String(localized: "financial.entry.one_time", defaultValue: "One-Time", table: "UI")
        case .recurring:
            return selectedRecurringFrequency.capitalized
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                AppBackground()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: LayoutSpacing.sectionGap) {
                        if entryIntent == .oneTime {
                            oneTimeHelperSection
                        }

                        if entryIntent == .recurring {
                            frequencySection
                        }

                        detailsSection
                        iconSection
                        colorSection
                        previewSection

                        PrimaryCTAButton(
                            title: "category.modal.save".localized(defaultValue: "Save"),
                            isDisabled: categoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                            action: saveCategory
                        )
                    }
                    .padding(.horizontal, LayoutSpacing.screenPadding)
                    .padding(.vertical, Spacing.md)
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("category.modal.cancel".localized(defaultValue: "Cancel")) {
                        onCancel()
                    }
                }
            }
            .alert("category.modal.invalid_title".localized(defaultValue: "Invalid Category"), isPresented: $showingValidationError) {
                Button("alert.ok".localized(defaultValue: "OK")) { }
            } message: {
                Text(validationErrorMessage)
            }
        }
        .presentationDragIndicator(.visible)
    }

    private var oneTimeHelperSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeader(title: String(localized: "financial.entry.type_header", defaultValue: "Entry Type", table: "UI"))

            GlassCard {
                VStack(alignment: .leading, spacing: LayoutSpacing.cardInternalGap) {
                    Text(entryKindOneTimeLabel)
                        .statusTitleStyle()

                    Text(
                        String(
                            localized: "financial.entry.one_time_helper",
                            defaultValue: "One-time items are counted in the current month.",
                            table: "UI"
                        )
                    )
                    .captionStyle(color: .textSecondary)

                    DatePicker(
                        String(localized: "financial.entry.occurrence_date", defaultValue: "Date"),
                        selection: $occurrenceDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                }
            }
        }
    }

    private var frequencySection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeader(title: String(localized: "category.modal.frequency_header", defaultValue: "Frequency", table: "UI"))

            GlassCard {
                Picker(
                    String(localized: "category.modal.frequency_picker", defaultValue: "Frequency", table: "UI"),
                    selection: $selectedRecurringFrequency
                ) {
                    Text(String(localized: "frequency.daily", defaultValue: "Daily", table: "UI")).tag("daily")
                    Text(String(localized: "frequency.weekly", defaultValue: "Weekly", table: "UI")).tag("weekly")
                    Text(String(localized: "frequency.monthly", defaultValue: "Monthly", table: "UI")).tag("monthly")
                    Text(String(localized: "frequency.yearly", defaultValue: "Yearly", table: "UI")).tag("yearly")
                }
                .pickerStyle(.segmented)
                .tint(accentColor)
            }
        }
    }

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeader(title: "category.modal.details_header".localized(defaultValue: "Category Details"))

            GlassCard {
                VStack(alignment: .leading, spacing: LayoutSpacing.cardInternalGap) {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("category.modal.name_placeholder".localized(defaultValue: "Category Name"))
                            .statusTitleStyle(color: .textSecondary)

                        TextField(
                            "category.modal.name_placeholder".localized(defaultValue: "Category Name"),
                            text: $categoryName
                        )
                        .textFieldStyle(.plain)
                        .bodyStyle()
                        .padding(Spacing.md)
                        .background(Color.surfaceInset)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
                        .onSubmit { saveCategory() }
                        .onChange(of: categoryName) { _, _ in
                            inlineNameError = nil
                        }

                        if let inlineNameError {
                            Text(inlineNameError)
                                .captionStyle(color: .financialNegative)
                        }
                    }
                }
            }
        }
    }

    private var iconSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeader(title: "category.modal.choose_icon".localized(defaultValue: "Choose Icon"))

            GlassCard {
                IconPickerView(selectedIcon: $selectedIcon, accentColor: accentColor)
            }
        }
    }

    private var colorSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeader(title: "category.modal.choose_color".localized(defaultValue: "Choose Color")) {
                if !premiumManager.hasAccess(to: BudgetMeterCapability.customCategories) {
                    PremiumBadge(locked: true)
                }
            }

            GlassCard {
                ColorPickerGrid(
                    selectedColor: $selectedColor,
                    isPremium: premiumManager.hasAccess(to: BudgetMeterCapability.customCategories)
                )
            }
        }
    }

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeader(title: "category.modal.preview".localized(defaultValue: "Preview"))

            CategoryPreviewCard(
                name: categoryName.isEmpty ? "category.modal.name_placeholder".localized(defaultValue: "Category Name") : categoryName,
                iconName: selectedIcon,
                color: selectedColor.color,
                frequency: previewFrequencyLabel
            )
        }
    }

    private var entryKindOneTimeLabel: String {
        type == "income"
            ? String(localized: "financial.entry.one_time_income", defaultValue: "One-Time Income")
            : String(localized: "financial.entry.surprise_expense", defaultValue: "Surprise Expense")
    }

    private func saveCategory() {
        let recurringFrequency = entryIntent == .recurring ? selectedRecurringFrequency : defaultRecurringFrequency

        let validationResult = validationService.validateCustomCategory(
            name: categoryName,
            type: type,
            entryKind: entryIntent,
            recurringFrequency: entryIntent == .recurring ? recurringFrequency : nil,
            context: viewContext
        )

        if case .invalid(let errorMessage) = validationResult {
            validationErrorMessage = errorMessage
            inlineNameError = errorMessage
            showingValidationError = true
            return
        }

        let colorToSave: String? = premiumManager.hasAccess(to: BudgetMeterCapability.customCategories) ? selectedColor.rawValue : nil

        let result = validationService.createCustomCategory(
            name: categoryName,
            type: type,
            entryKind: entryIntent,
            recurringFrequency: recurringFrequency,
            iconName: selectedIcon,
            colorHex: colorToSave,
            context: viewContext
        )

        switch result {
        case .success(let category):
            FinancialCategoryWriteSupport.applyMetadata(
                to: category,
                entryKind: entryIntent,
                recurringFrequency: recurringFrequency,
                occurrenceDate: occurrenceDate
            )

            if PersistenceService.shared.save() {
                if entryIntent == .oneTime {
                    SupabaseOneTimeTransactionSyncService.shared.registerLocalOneTimeRow(category)
                } else {
                    SupabaseFinancialCategorySyncService.shared.registerLocalCustomCategory(category)
                }
                onSave(category)
            } else {
                validationErrorMessage = String(
                    localized: "category.modal.save_error",
                    defaultValue: "Couldn't save your change. Please try again.",
                    table: "UI"
                )
                inlineNameError = validationErrorMessage
                showingValidationError = true
            }

        case .failure(let error):
            validationErrorMessage = error.errorMessage ?? "category.modal.create_error".localized(defaultValue: "Failed to create category")
            inlineNameError = validationErrorMessage
            showingValidationError = true
        }
    }
}

// MARK: - Icon Picker View

struct IconPickerView: View {

    @Binding var selectedIcon: String
    var accentColor: Color = .accentPrimary

    private let icons = [
        "tag.fill", "house.fill", "car.fill", "fork.knife", "gamecontroller.fill",
        "tv.fill", "music.note", "book.fill", "heart.fill", "star.fill",
        "bolt.fill", "lightbulb.fill", "wifi", "phone.fill", "envelope.fill",
        "briefcase.fill", "graduationcap.fill", "stethoscope", "cross.fill", "pawprint.fill",
        "dumbbell.fill", "cup.and.saucer", "airplane", "gift.fill", "chart.line.uptrend.xyaxis",
        "laptopcomputer", "desktopcomputer", "play.rectangle.fill", "mic.fill", "link",
        "trophy.fill", "crown.fill", "shield.fill", "building.2.fill", "fuelpump.fill"
    ]

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: Spacing.md) {
            ForEach(icons, id: \.self) { icon in
                Button(action: { selectedIcon = icon }) {
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(selectedIcon == icon ? .white : .textPrimary)
                        .frame(width: 40, height: 40)
                        .background(
                            selectedIcon == icon
                                ? accentColor
                                : Color.surfaceInset
                        )
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Color Picker Grid

struct ColorPickerGrid: View {

    @Binding var selectedColor: CategoryColor
    let isPremium: Bool

    @State private var showingPaywall = false

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: Spacing.md) {
            ForEach(CategoryColor.allCases) { color in
                Button(action: {
                    if isPremium {
                        selectedColor = color
                        Haptics.light()
                    } else {
                        showingPaywall = true
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(color.color)
                            .frame(width: 44, height: 44)

                        if selectedColor == color && isPremium {
                            Circle()
                                .strokeBorder(Color.white, lineWidth: 3)
                                .frame(width: 44, height: 44)

                            Image(systemName: "checkmark")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        }

                        if !isPremium {
                            Circle()
                                .fill(Color.black.opacity(0.3))
                                .frame(width: 44, height: 44)

                            Image(systemName: "lock.fill")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .sheet(isPresented: $showingPaywall) {
            PremiumPaywallView(
                onDismiss: { showingPaywall = false },
                onPurchase: { showingPaywall = false },
                onRestore: { showingPaywall = false }
            )
        }
    }
}

// MARK: - Category Preview Card

struct CategoryPreviewCard: View {

    let name: String
    let iconName: String
    let color: Color
    let frequency: String

    var body: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: iconName)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(color)

            Text(name)
                .captionStyle(color: .textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            Text(frequency)
                .badgeStyle(color: .textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.md)
        .glassSurface()
    }
}

#Preview {
    CreateCategoryModal(
        entryIntent: .recurring,
        defaultRecurringFrequency: "monthly",
        type: "expense",
        onSave: { _ in },
        onCancel: { }
    )
}
