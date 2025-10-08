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
    @State private var showingValidationError = false
    @State private var validationErrorMessage = ""
    
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var validationService = CategoryValidationService()
    
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
                            "Category Name",
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
                    Text("Category Details")
                }
                
                // Icon Selection Section
                Section {
                    IconPickerView(selectedIcon: $selectedIcon)
                } header: {
                    Text("Choose Icon")
                }
                
                // Preview Section
                Section {
                    CategoryPreviewCard(
                        name: categoryName.isEmpty ? "Category Name" : categoryName,
                        iconName: selectedIcon,
                        type: type,
                        frequency: frequency
                    )
                } header: {
                    Text("Preview")
                }
            }
            .navigationTitle("Add \(type.capitalized) Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveCategory()
                    }
                    .disabled(categoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .alert("Invalid Category", isPresented: $showingValidationError) {
                Button("OK") { }
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
        
        let result = validationService.createCustomCategory(
            name: categoryName,
            type: type,
            frequency: frequency,
            iconName: selectedIcon,
            context: viewContext
        )
        
        switch result {
        case .success(let category):
            do {
                try viewContext.save()
                onSave(category)
            } catch {
                print("❌ Failed to save custom category: \(error)")
                validationErrorMessage = "Failed to save category. Please try again."
                showingValidationError = true
            }
            
        case .failure(let error):
            validationErrorMessage = error.errorMessage ?? "Failed to create category"
            showingValidationError = true
        }
    }
}

// MARK: - Icon Picker View

struct IconPickerView: View {
    
    @Binding var selectedIcon: String
    
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
                        .background(selectedIcon == icon ? Color(hex: "4A90E2") : Color(uiColor: .secondarySystemBackground))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Category Preview Card

struct CategoryPreviewCard: View {
    
    let name: String
    let iconName: String
    let type: String
    let frequency: String
    
    private var accentColor: Color {
        switch type {
        case "income":
            return .green
        case "expense":
            return .red
        default:
            return .gray
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Icon
            Image(systemName: iconName)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(accentColor)
            
            // Name
            Text(name)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            // Amount placeholder
            HStack(spacing: 4) {
                Text("$")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("0.00")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
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

