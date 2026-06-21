//
//  CreateCategoryModal.swift
//  BudgetMeter
//
//  Modal for creating custom categories — v2 glass section layout.
//

import SwiftUI

/// Modal for creating custom categories inline from Income/Expense views
struct CreateCategoryModal: View {

    let frequency: String
    let type: String
    let onSave: (FinancialCategory) -> Void
    let onCancel: () -> Void

    @State private var categoryName = ""
    @State private var selectedIcon = "tag.fill"
    @State private var selectedColor: CategoryColor = .gray
    @State private var selectedEntryKind: FinancialCategoryEntryKind = .recurring
    @State private var occurrenceDate = Date()
    @State private var showingValidationError = false
    @State private var validationErrorMessage = ""
    @State private var inlineNameError: String?

    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var validationService = CategoryValidationService()
    @StateObject private var premiumManager = PremiumManager.shared

    private var accentColor: Color {
        type == "income" ? .financialPositive : .brandExpense
    }

    var body: some View {
        NavigationView {
            ZStack {
                AppBackground()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: LayoutSpacing.sectionGap) {
                        entryTypeSection
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
            .navigationTitle(String(format: "category.modal.title.add".localized(defaultValue: "Add %@ Category"), type.capitalized))
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

    private var entryTypeSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeader(title: "financial.entry.type_header".localized(defaultValue: "Entry Type"))

            GlassCard {
                VStack(spacing: LayoutSpacing.cardInternalGap) {
                    Picker(
                        String(localized: "financial.entry.kind", defaultValue: "Entry Type"),
                        selection: $selectedEntryKind
                    ) {
                        Text(entryKindRecurringLabel)
                            .tag(FinancialCategoryEntryKind.recurring)
                        Text(entryKindOneTimeLabel)
                            .tag(FinancialCategoryEntryKind.oneTime)
                    }
                    .pickerStyle(.segmented)
                    .tint(accentColor)

                    if selectedEntryKind == .oneTime {
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
    }

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeader(title: "category.modal.details_header".localized(defaultValue: "Category Details"))

            GlassCard {
                VStack(alignment: .leading, spacing: LayoutSpacing.cardInternalGap) {
                    Label("\(frequency.capitalized) \(type.capitalized)", systemImage: "info.circle")
                        .captionStyle(color: .textSecondary)

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
                        .onSubmit {
                            if validationService.validateCustomCategory(
                                name: categoryName,
                                type: type,
                                frequency: frequency,
                                context: viewContext
                            ).isValid {
                                saveCategory()
                            }
                        }
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
                frequency: frequency
            )
        }
    }

    private var entryKindRecurringLabel: String {
        type == "income"
            ? String(localized: "financial.entry.recurring_income", defaultValue: "Recurring Income")
            : String(localized: "financial.entry.regular_expense", defaultValue: "Regular Expense")
    }

    private var entryKindOneTimeLabel: String {
        type == "income"
            ? String(localized: "financial.entry.one_time_income", defaultValue: "One-Time Income")
            : String(localized: "financial.entry.surprise_expense", defaultValue: "Surprise Expense")
    }

    private func saveCategory() {
        let validationResult = validationService.validateCustomCategory(
            name: categoryName,
            type: type,
            frequency: frequency,
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
            frequency: frequency,
            iconName: selectedIcon,
            colorHex: colorToSave,
            context: viewContext
        )

        switch result {
        case .success(let category):
            FinancialCategoryWriteSupport.applyMetadata(
                to: category,
                entryKind: selectedEntryKind,
                recurringFrequency: frequency,
                occurrenceDate: occurrenceDate
            )

            do {
                try viewContext.save()
                onSave(category)
            } catch {
                print("❌ Failed to save custom category: \(error)")
                validationErrorMessage = "category.modal.save_error".localized(defaultValue: "Failed to save category. Please try again.")
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

            Text(frequency.capitalized)
                .badgeStyle(color: .textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.md)
        .glassSurface()
    }
}

#Preview {
    CreateCategoryModal(
        frequency: "monthly",
        type: "expense",
        onSave: { _ in },
        onCancel: { }
    )
}

// MARK: - Phase 5 Write / Display Support

enum FinancialCategoryEntryKind: String {
    case recurring = "recurring"
    case oneTime = "oneTime"
}

enum FinancialCategoryWriteSupport {

    static let recurringFrequencies: Set<String> = ["daily", "weekly", "monthly", "yearly"]

    static func applyMetadata(
        to category: FinancialCategory,
        entryKind: FinancialCategoryEntryKind,
        recurringFrequency: String,
        occurrenceDate: Date = Date(),
        sourceType: String? = nil,
        sourceID: String? = nil
    ) {
        category.entryKind = entryKind.rawValue
        category.isActive = true
        category.lastModified = Date()

        if let sourceType {
            category.sourceType = sourceType
        }
        if let sourceID {
            category.sourceID = sourceID
        }

        switch entryKind {
        case .recurring:
            category.frequency = recurringFrequency
        case .oneTime:
            category.frequency = "once"
            category.occurrenceDate = occurrenceDate
        }
    }

    static func touchModified(_ category: FinancialCategory) {
        category.lastModified = Date()
        category.isActive = true

        let kind = normalized(category.entryKind)
        if kind.isEmpty {
            category.entryKind = FinancialCategoryEntryKind.recurring.rawValue
        }
    }

    static func isRecurringDisplayCategory(_ category: FinancialCategory) -> Bool {
        if normalized(category.entryKind) == FinancialCategoryEntryKind.oneTime.rawValue {
            return false
        }
        let frequency = normalized(category.frequency)
        if frequency == "recurring" || frequency == "once" {
            return false
        }
        return recurringFrequencies.contains(frequency)
    }

    static func isOneTimeDisplayCategory(_ category: FinancialCategory) -> Bool {
        if normalized(category.entryKind) == FinancialCategoryEntryKind.oneTime.rawValue {
            return true
        }
        return normalized(category.frequency) == "once"
    }

    private static func normalized(_ value: String?) -> String {
        value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}
