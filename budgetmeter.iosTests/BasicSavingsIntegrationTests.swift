//
//  BasicSavingsIntegrationTests.swift
//  budgetmeter.iosTests
//
//  Phase 6 — primary savings goal selection, Home writes, and shared ETA mapping.
//

import CoreData
import XCTest
@testable import budgetmeter_ios

@MainActor
final class BasicSavingsIntegrationTests: XCTestCase {

    private var persistence: PersistenceService!
    private var context: NSManagedObjectContext!
    private var goalManager: SavingsGoalManager!
    private var builder: FinancialSummaryBuilder!
    private var calendar: Calendar!
    private let asOf = Date(timeIntervalSince1970: 1_704_067_200)

    override func setUp() {
        super.setUp()
        persistence = PersistenceService.makeInMemoryForTesting()
        context = persistence.viewContext
        goalManager = SavingsGoalManager(persistence: persistence)
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        builder = FinancialSummaryBuilder(context: context, calendar: calendar)
    }

    override func tearDown() {
        builder = nil
        calendar = nil
        goalManager = nil
        context = nil
        persistence = nil
        super.tearDown()
    }

    func test_upsertPrimaryBasicGoal_createsGoalWhenNoneExists() {
        let goal = goalManager.upsertPrimaryBasicGoal(targetAmount: 2_000, name: "Vacation")

        XCTAssertNotNil(goal)
        XCTAssertEqual(goal!.targetAmount, 2_000, accuracy: 0.01)
        XCTAssertEqual(goal!.currentAmount, 0, accuracy: 0.01)
        XCTAssertFalse(goal?.isArchived ?? true)
        XCTAssertEqual(goalManager.getPrimaryActiveGoal()?.id, goal?.id)
    }

    func test_upsertPrimaryBasicGoal_updatesExistingPrimary() {
        _ = goalManager.createGoal(name: "Existing", targetAmount: 500, currentAmount: 100)

        let updated = goalManager.upsertPrimaryBasicGoal(targetAmount: 1_500)

        XCTAssertEqual(updated!.targetAmount, 1_500, accuracy: 0.01)
        XCTAssertEqual(updated!.currentAmount, 100, accuracy: 0.01)
        XCTAssertEqual(goalManager.getActiveGoals().count, 1)
    }

    func test_primaryActiveGoal_matchesBuilderSelection() {
        insertSettings(savingsGoalAmount: 9_999)
        insertGoal(name: "Low Priority", targetAmount: 900, priority: 5, createdAt: asOf.addingTimeInterval(100))
        insertGoal(name: "Primary", targetAmount: 1_200, priority: 1, createdAt: asOf.addingTimeInterval(200))
        CoreDataMigrationTestSupport.saveContext(persistence)

        let managerPrimary = goalManager.getPrimaryActiveGoal()
        let builderPrimary = SavingsGoalManager.primaryActiveGoal(in: context)
        let summary = builder.build(selectedPeriod: .month, asOf: asOf)

        XCTAssertEqual(managerPrimary?.name, "Primary")
        XCTAssertEqual(builderPrimary?.id, managerPrimary?.id)
        XCTAssertEqual(summary.savingsTargetAmount, 1_200, accuracy: 0.01)
    }

    func test_homeQuickSave_createsPrimaryGoalUsedBySummary() {
        insertFinancialCategory(type: "income", frequency: "daily", amount: 100)
        insertFinancialCategory(type: "expense", frequency: "daily", amount: 40)
        CoreDataMigrationTestSupport.saveContext(persistence)

        let homeViewModel = HomeViewModel(
            persistenceService: persistence,
            summaryBuilder: builder,
            goalManager: goalManager
        )
        homeViewModel.updateSavingsGoal(3_000)

        let summary = builder.build(selectedPeriod: .month, asOf: asOf)

        XCTAssertNotNil(goalManager.getPrimaryActiveGoal())
        XCTAssertEqual(summary.savingsTargetAmount, 3_000, accuracy: 0.01)
        XCTAssertEqual(summary.savingsRemaining, 3_000, accuracy: 0.01)
        XCTAssertEqual(homeViewModel.primarySavingsGoalTarget, 3_000, accuracy: 0.01)
    }

    func test_sharedPaceETA_usesSummaryForPrimaryGoal() {
        insertGoal(name: "Primary", targetAmount: 1_000, currentAmount: 0, priority: 0)
        insertFinancialCategory(type: "income", frequency: "daily", amount: 100)
        insertFinancialCategory(type: "expense", frequency: "daily", amount: 50)
        CoreDataMigrationTestSupport.saveContext(persistence)

        let summary = builder.build(selectedPeriod: .month, asOf: asOf)
        let etaText = HomeDisplayMapping.formatSavingsETA(from: summary)

        XCTAssertTrue(etaText.contains("20") || etaText.lowercased().contains("day"))
        XCTAssertEqual(summary.savingsTimeToGoal?.days ?? 0, 20, accuracy: 0.01)
    }

    func test_sharedPaceETA_negativePaceUsesCalmCopy() {
        insertGoal(name: "Primary", targetAmount: 1_000, currentAmount: 0, priority: 0)
        insertFinancialCategory(type: "income", frequency: "daily", amount: 20)
        insertFinancialCategory(type: "expense", frequency: "daily", amount: 50)
        CoreDataMigrationTestSupport.saveContext(persistence)

        let summary = builder.build(selectedPeriod: .month, asOf: asOf)
        let etaText = HomeDisplayMapping.formatSavingsETA(from: summary)

        XCTAssertNil(summary.savingsTimeToGoal)
        XCTAssertTrue(etaText.lowercased().contains("pace"))
    }

    func test_savingsGoalsViewModel_canAddAnotherGoal_respectsFreeBoundary() {
        _ = goalManager.createGoal(name: "Only Goal", targetAmount: 500)
        let viewModel = SavingsGoalsViewModel(
            persistenceService: persistence,
            goalManager: goalManager,
            summaryBuilder: builder
        )

        XCTAssertEqual(viewModel.canAddAnotherGoal, PremiumManager.shared.isPremium)
    }

    func test_createGoal_blocksSecondNonArchivedGoalForFreeUsers() {
        _ = insertSettings()
        let first = goalManager.createGoal(name: "First", targetAmount: 500)
        let second = goalManager.createGoal(name: "Second", targetAmount: 900)

        XCTAssertNotNil(first)
        XCTAssertNil(second)
        XCTAssertEqual(goalManager.getActiveGoals().count, 1)
    }

    func test_createGoal_allowsMultipleGoalsForPremiumUsers() {
        let settings = insertSettings()
        settings.isPremiumUser = true
        CoreDataMigrationTestSupport.saveContext(persistence)

        let first = goalManager.createGoal(name: "First", targetAmount: 500)
        let second = goalManager.createGoal(name: "Second", targetAmount: 900)

        XCTAssertNotNil(first)
        XCTAssertNotNil(second)
        XCTAssertEqual(goalManager.getActiveGoals().count, 2)
    }

    func test_primaryGoal_prefersInProgressOverCompleted() {
        _ = insertSettings(savingsGoalAmount: 2_500)
        let completed = insertGoal(
            name: "Completed",
            targetAmount: 800,
            currentAmount: 800,
            priority: 0,
            createdAt: asOf
        )
        completed.completedDate = asOf

        _ = insertGoal(
            name: "In Progress",
            targetAmount: 1_500,
            currentAmount: 200,
            priority: 5,
            createdAt: asOf.addingTimeInterval(200)
        )
        CoreDataMigrationTestSupport.saveContext(persistence)

        let primary = goalManager.getPrimaryActiveGoal()
        let summary = builder.build(selectedPeriod: .month, asOf: asOf)

        XCTAssertEqual(primary?.name, "In Progress")
        XCTAssertEqual(summary.savingsTargetAmount, 1_500, accuracy: 0.01)
    }

    func test_primaryGoal_nilPriorityAndCreatedAtSortAfterDefinedValues() {
        _ = insertSettings(savingsGoalAmount: 9_999)
        let defined = insertGoal(
            name: "Defined",
            targetAmount: 700,
            currentAmount: 100,
            priority: 0,
            createdAt: asOf
        )
        let nilMetadata = insertGoal(
            name: "Nil Metadata",
            targetAmount: 1_200,
            currentAmount: 100,
            priority: 5,
            createdAt: asOf.addingTimeInterval(100)
        )
        nilMetadata.setPrimitiveValue(nil, forKey: "priority")
        nilMetadata.createdAt = nil
        CoreDataMigrationTestSupport.saveContext(persistence)

        let primary = goalManager.getPrimaryActiveGoal()
        let summary = builder.build(selectedPeriod: .month, asOf: asOf)

        XCTAssertEqual(primary?.id, defined.id)
        XCTAssertEqual(summary.savingsTargetAmount, defined.targetAmount, accuracy: 0.01)
    }

    func test_savingsGoalsViewModel_sharedPaceETAText_onlyForPrimaryGoal() {
        insertGoal(name: "Primary", targetAmount: 1_000, priority: 0)
        insertGoal(name: "Secondary", targetAmount: 500, priority: 2)
        insertFinancialCategory(type: "income", frequency: "daily", amount: 100)
        insertFinancialCategory(type: "expense", frequency: "daily", amount: 50)
        CoreDataMigrationTestSupport.saveContext(persistence)

        let viewModel = SavingsGoalsViewModel(
            persistenceService: persistence,
            goalManager: goalManager,
            summaryBuilder: builder
        )

        guard let primary = viewModel.primaryGoal else {
            XCTFail("Expected primary goal")
            return
        }
        let secondary = viewModel.activeGoals.first { !viewModel.isPrimaryGoal($0) }

        XCTAssertNotNil(viewModel.sharedPaceETAText(for: primary))
        if let secondary {
            XCTAssertNil(viewModel.sharedPaceETAText(for: secondary))
        }
    }

    // MARK: - Helpers

    @discardableResult
    private func insertSettings(savingsGoalAmount: Double = 0) -> AppSettings {
        CoreDataMigrationTestSupport.insertAppSettings(in: context, savingsGoalAmount: savingsGoalAmount)
    }

    @discardableResult
    private func insertGoal(
        name: String,
        targetAmount: Double,
        currentAmount: Double = 0,
        priority: Int16 = 0,
        createdAt: Date? = nil
    ) -> SavingsGoal {
        let goal = SavingsGoal(context: context)
        goal.id = UUID()
        goal.name = name
        goal.targetAmount = targetAmount
        goal.currentAmount = currentAmount
        goal.isArchived = false
        goal.priority = priority
        goal.createdAt = createdAt ?? asOf
        return goal
    }

    @discardableResult
    private func insertFinancialCategory(type: String, frequency: String, amount: Double) -> FinancialCategory {
        CoreDataMigrationTestSupport.insertFinancialCategory(
            in: context,
            type: type,
            frequency: frequency,
            amount: amount,
            entryKind: "recurring"
        )
    }
}
