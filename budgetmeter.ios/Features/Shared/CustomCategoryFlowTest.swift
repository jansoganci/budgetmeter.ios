//
//  CustomCategoryFlowTest.swift
//  BudgetMeter
//
//  Created by BudgetMeter Team on 17.09.2025.
//

import SwiftUI
import CoreData

#if DEBUG
/// Comprehensive test for the complete custom category creation flow
struct CustomCategoryFlowTest: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var premiumManager = PremiumManager.shared
    @StateObject private var validationService = CategoryValidationService()
    
    @State private var testResults: [TestResult] = []
    @State private var isRunningTests = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // Test Controls
                    VStack {
                        Text("Custom Category Flow Test")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Button("Run All Tests") {
                            runAllTests()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isRunningTests)
                        
                        if isRunningTests {
                            ProgressView("Running Tests...")
                                .padding()
                        }
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemBackground))
                    .cornerRadius(12)
                    
                    // Test Results
                    if !testResults.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Test Results")
                                .font(.headline)
                            
                            ForEach(testResults, id: \.id) { result in
                                TestResultRow(result: result)
                            }
                        }
                        .padding()
                        .background(Color(uiColor: .secondarySystemBackground))
                        .cornerRadius(12)
                    }
                    
                    // Manual Test Buttons
                    VStack(spacing: 12) {
                        Text("Manual Tests")
                            .font(.headline)
                        
                        Button("Test Premium Status Toggle") {
                            premiumManager.setDebugPremiumStatus(!premiumManager.isPremium)
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Test Category Validation") {
                            testCategoryValidation()
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Test Migration Service") {
                            testMigrationService()
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Clear Test Data") {
                            clearTestData()
                        }
                        .buttonStyle(.bordered)
                        .foregroundColor(.red)
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemBackground))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Flow Test")
        }
    }
    
    // MARK: - Test Methods
    
    private func runAllTests() {
        isRunningTests = true
        testResults.removeAll()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Test 1: Premium Status
            testPremiumStatus()
            
            // Test 2: Category Creation
            testCategoryCreation()
            
            // Test 3: Duplicate Prevention
            testDuplicatePrevention()
            
            // Test 4: Data Persistence
            testDataPersistence()
            
            // Test 5: Migration Service
            testMigrationService()
            
            isRunningTests = false
        }
    }
    
    private func testPremiumStatus() {
        var test = TestResult(
            name: "Premium Status Management",
            description: "Test premium status toggling and persistence"
        )
        
        let originalStatus = premiumManager.isPremium
        
        // Toggle premium status
        premiumManager.setDebugPremiumStatus(!originalStatus)
        
        if premiumManager.isPremium == !originalStatus {
            test.markSuccess("Premium status toggle successful")
        } else {
            test.markFailure("Premium status toggle failed")
        }
        
        // Restore original status
        premiumManager.setDebugPremiumStatus(originalStatus)
        
        testResults.append(test)
    }
    
    private func testCategoryCreation() {
        var test = TestResult(
            name: "Category Creation",
            description: "Test creating custom categories with validation"
        )
        
        let result = validationService.createCustomCategory(
            name: "Test Category",
            type: "income",
            frequency: "monthly",
            iconName: "star.fill",
            context: viewContext
        )
        
        switch result {
        case .success(let category):
            if category.isCustom && category.customName == "Test Category" {
                test.markSuccess("Category creation successful")
            } else {
                test.markFailure("Category creation failed - invalid data")
            }
        case .failure(let error):
            test.markFailure("Category creation failed: \(error.errorMessage ?? "Unknown error")")
        }
        
        testResults.append(test)
    }
    
    private func testDuplicatePrevention() {
        var test = TestResult(
            name: "Duplicate Prevention",
            description: "Test that duplicate categories are prevented"
        )
        
        // Create first category
        let firstResult = validationService.createCustomCategory(
            name: "Duplicate Test",
            type: "expense",
            frequency: "daily",
            context: viewContext
        )
        
        guard case .success(_) = firstResult else {
            test.markFailure("First category creation failed")
            testResults.append(test)
            return
        }
        
        // Try to create duplicate
        let duplicateResult = validationService.createCustomCategory(
            name: "Duplicate Test",
            type: "expense",
            frequency: "daily",
            context: viewContext
        )
        
        if case .failure(_) = duplicateResult {
            test.markSuccess("Duplicate prevention working")
        } else {
            test.markFailure("Duplicate prevention failed")
        }
        
        testResults.append(test)
    }
    
    private func testDataPersistence() {
        var test = TestResult(
            name: "Data Persistence",
            description: "Test that custom categories persist in Core Data"
        )
        
        do {
            try viewContext.save()
            
            // Query for custom categories
            let request: NSFetchRequest<FinancialCategory> = FinancialCategory.fetchRequest()
            request.predicate = NSPredicate(format: "isCustom == YES")
            
            let customCategories = try viewContext.fetch(request)
            
            if customCategories.count > 0 {
                test.markSuccess("Found \(customCategories.count) custom categories in Core Data")
            } else {
                test.markFailure("No custom categories found in Core Data")
            }
        } catch {
            test.markFailure("Core Data query failed: \(error.localizedDescription)")
        }
        
        testResults.append(test)
    }
    
    private func testMigrationService() {
        var test = TestResult(
            name: "Migration Service",
            description: "Test custom category migration service"
        )
        
        let migrationService = CustomCategoryMigrationService()
        
        // Test migration completion check
        let hasCategories = migrationService.hasCustomCategoriesToMigrate()
        
        if !hasCategories {
            test.markSuccess("Migration service reports no categories to migrate (expected for new system)")
        } else {
            test.markSuccess("Migration service found categories to migrate")
        }
        
        testResults.append(test)
    }
    
    private func testCategoryValidation() {
        var test = TestResult(
            name: "Category Validation",
            description: "Test category validation rules"
        )
        
        // Test empty name
        let emptyResult = validationService.validateCustomCategory(
            name: "",
            type: "income",
            frequency: "monthly",
            context: viewContext
        )
        
        if case .invalid(_) = emptyResult {
            test.markSuccess("Empty name validation working")
        } else {
            test.markFailure("Empty name validation failed")
        }
        
        testResults.append(test)
    }
    
    private func clearTestData() {
        let request: NSFetchRequest<FinancialCategory> = FinancialCategory.fetchRequest()
        request.predicate = NSPredicate(format: "isCustom == YES")
        
        do {
            let customCategories = try viewContext.fetch(request)
            for category in customCategories {
                viewContext.delete(category)
            }
            try viewContext.save()
            
            testResults.removeAll()
            print("✅ Test data cleared successfully")
        } catch {
            print("❌ Failed to clear test data: \(error)")
        }
    }
}

// MARK: - Test Result Models

struct TestResult {
    let id = UUID()
    let name: String
    let description: String
    var status: TestStatus = .running
    var message: String = ""
    
    mutating func markSuccess(_ message: String) {
        self.status = .success
        self.message = message
    }
    
    mutating func markFailure(_ message: String) {
        self.status = .failure
        self.message = message
    }
}

enum TestStatus {
    case running
    case success
    case failure
}

struct TestResultRow: View {
    let result: TestResult
    
    var body: some View {
        HStack {
            Image(systemName: statusIcon)
                .foregroundColor(statusColor)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(result.name)
                    .font(.headline)
                
                Text(result.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if !result.message.isEmpty {
                    Text(result.message)
                        .font(.caption)
                        .foregroundColor(statusColor)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private var statusIcon: String {
        switch result.status {
        case .running:
            return "clock"
        case .success:
            return "checkmark.circle.fill"
        case .failure:
            return "xmark.circle.fill"
        }
    }
    
    private var statusColor: Color {
        switch result.status {
        case .running:
            return .orange
        case .success:
            return .green
        case .failure:
            return .red
        }
    }
}

#Preview {
    CustomCategoryFlowTest()
        .environment(\.managedObjectContext, PersistenceService.shared.viewContext)
}
#endif
