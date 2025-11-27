//
//  CreateCategoryModal.swift
//  BudgetMeter
//
//  Created by BudgetMeter Team on 17.09.2025.
//

import SwiftUI

/// Modal for creating custom categories inline from Income/Expense views
struct CreateCategoryModal: View {
    
    // MARK: - Properties
    
    let frequency: String
    let type: String
    let onSave: (FinancialCategory) -> Void
    let onCancel: () -> Void
    
    @State private var categoryName = ""
    @State private var selectedIcon = "tag.fill"
    @State private var selectedColor: CategoryColor = .gray
    @State private var showingValidationError = false
    @State private var validationErrorMessage = ""

    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var validationService = CategoryValidationService()
    @StateObject private var premiumManager = PremiumManager.shared
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            Form {
                // Category Info Section
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        // Frequency and Type Info
                        HStack {
                            Label("\(frequency.capitalized) \(type.capitalized)", systemImage: "info.circle")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        
                        // Name Input
                        TextField(
                            "category.modal.name_placeholder".localized(defaultValue: "Category Name"),
                            text: $categoryName
                        )
                        .textFieldStyle(.roundedBorder)
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
                    }
                } header: {
                    Text("category.modal.details_header".localized(defaultValue: "Category Details"))
                }
                
                // Icon Selection Section
                Section {
                    IconPickerView(selectedIcon: $selectedIcon, accentColor: selectedColor.color)
                } header: {
                    Text("category.modal.choose_icon".localized(defaultValue: "Choose Icon"))
                }

                // Color Selection Section (Premium)
                Section {
                    ColorPickerGrid(
                        selectedColor: $selectedColor,
                        isPremium: premiumManager.isPremium
                    )
                } header: {
                    HStack {
                        Text("category.modal.choose_color".localized(defaultValue: "Choose Color"))
                        if !premiumManager.isPremium {
                            Text("category.modal.premium".localized(defaultValue: "Premium"))
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.brandProgress)
                                .cornerRadius(4)
                        }
                    }
                }

                // Preview Section
                Section {
                    CategoryPreviewCard(
                        name: categoryName.isEmpty ? "category.modal.name_placeholder".localized(defaultValue: "Category Name") : categoryName,
                        iconName: selectedIcon,
                        color: selectedColor.color,
                        frequency: frequency
                    )
                } header: {
                    Text("category.modal.preview".localized(defaultValue: "Preview"))
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
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("category.modal.save".localized(defaultValue: "Save")) {
                        saveCategory()
                    }
                    .disabled(categoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .alert("category.modal.invalid_title".localized(defaultValue: "Invalid Category"), isPresented: $showingValidationError) {
                Button("alert.ok".localized(defaultValue: "OK")) { }
            } message: {
                Text(validationErrorMessage)
            }
        }
    }
    
    // MARK: - Actions
    
    private func saveCategory() {
        let validationResult = validationService.validateCustomCategory(
            name: categoryName,
            type: type,
            frequency: frequency,
            context: viewContext
        )
        
        if case .invalid(let errorMessage) = validationResult {
            validationErrorMessage = errorMessage
            showingValidationError = true
            return
        }
        
        // Only save color for premium users
        let colorToSave: String? = premiumManager.isPremium ? selectedColor.rawValue : nil

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
            do {
                try viewContext.save()
                onSave(category)
            } catch {
                print("❌ Failed to save custom category: \(error)")
                validationErrorMessage = "category.modal.save_error".localized(defaultValue: "Failed to save category. Please try again.")
                showingValidationError = true
            }
            
        case .failure(let error):
            validationErrorMessage = error.errorMessage ?? "category.modal.create_error".localized(defaultValue: "Failed to create category")
            showingValidationError = true
        }
    }
}

// MARK: - Icon Picker View

struct IconPickerView: View {

    @Binding var selectedIcon: String
    var accentColor: Color = .brandProgress

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
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
            ForEach(icons, id: \.self) { icon in
                Button(action: { selectedIcon = icon }) {
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(selectedIcon == icon ? .white : .primary)
                        .frame(width: 40, height: 40)
                        .background(selectedIcon == icon ? accentColor : Color(uiColor: .secondarySystemBackground))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Color Picker Grid

struct ColorPickerGrid: View {

    @Binding var selectedColor: CategoryColor
    let isPremium: Bool

    @State private var showingPaywall = false

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
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
        .padding(.vertical, 8)
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
        VStack(spacing: 8) {
            // Icon
            Image(systemName: iconName)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(color)

            // Name
            Text(name)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            // Frequency badge
            Text(frequency.capitalized)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color(uiColor: .tertiarySystemBackground))
                .cornerRadius(4)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Preview

#Preview {
    CreateCategoryModal(
        frequency: "monthly",
        type: "expense",
        onSave: { _ in },
        onCancel: { }
    )
}

