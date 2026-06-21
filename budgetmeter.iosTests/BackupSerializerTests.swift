//
//  BackupSerializerTests.swift
//  budgetmeter.iosTests
//
//  Phase 9 backup payload contract tests.
//

import CoreData
import XCTest
@testable import budgetmeter_ios

final class BackupSerializerTests: XCTestCase {

    private var persistenceService: PersistenceService!
    private var serializer: BackupSerializer!

    override func setUp() {
        super.setUp()
        persistenceService = PersistenceService.makeInMemoryForTesting()
        serializer = BackupSerializer()
    }

    func test_exportPayload_fromSeededContext_hasSchemaVersion() throws {
        seedSampleCategory()

        let payload = try serializer.exportPayload(from: persistenceService.viewContext)

        XCTAssertEqual(payload.schemaVersion, BackupConstants.schemaVersion)
        XCTAssertEqual(payload.financialCategories.count, 1)
        XCTAssertGreaterThanOrEqual(payload.recordCounts.totalRecords, 1)
    }

    func test_roundTrip_preservesFinancialCategoryFields() throws {
        seedSampleCategory()

        let exported = try serializer.exportPayload(from: persistenceService.viewContext)
        let roundTripped = try serializer.roundTrip(exported)

        XCTAssertEqual(roundTripped.financialCategories.count, exported.financialCategories.count)
        XCTAssertEqual(roundTripped.financialCategories.first?.amount, exported.financialCategories.first?.amount)
        XCTAssertEqual(roundTripped.financialCategories.first?.clientRecordID, exported.financialCategories.first?.clientRecordID)
    }

    func test_decode_rejectsUnsupportedSchemaVersion() throws {
        let payload = BackupPayload(
            schemaVersion: BackupConstants.schemaVersion + 10,
            appVersion: "1.0",
            exportedAt: Date(),
            recordCounts: BackupRecordCounts(
                financialCategories: 0,
                recurringTransactions: 0,
                savingsGoals: 0,
                subscriptions: 0,
                bills: 0,
                billPayments: 0,
                financialSnapshots: 0
            ),
            appSettings: nil,
            financialCategories: [],
            recurringTransactions: [],
            savingsGoals: [],
            subscriptions: [],
            bills: [],
            billPayments: [],
            financialSnapshots: []
        )

        let data = try serializer.encode(payload)

        XCTAssertThrowsError(try serializer.decode(data)) { error in
            XCTAssertEqual(error as? BackupSerializerError, .unsupportedSchemaVersion(payload.schemaVersion))
        }
    }

    func test_restoreImporter_replacesFinancialCategories() throws {
        seedSampleCategory()
        let exported = try serializer.exportPayload(from: persistenceService.viewContext)

        let importer = RestoreImporter()
        try importer.importPayload(exported, into: persistenceService.viewContext)

        let request: NSFetchRequest<FinancialCategory> = FinancialCategory.fetchRequest()
        let categories = try persistenceService.viewContext.fetch(request)
        XCTAssertEqual(categories.count, 1)
        XCTAssertEqual(categories.first?.amount, 1200)
    }

    private func seedSampleCategory() {
        let context = persistenceService.viewContext
        let category = FinancialCategory(context: context)
        category.id = UUID()
        category.uniqueID = category.id?.uuidString
        category.amount = 1200
        category.type = "income"
        category.frequency = "monthly"
        category.entryKind = "recurring"
        category.isActive = true
        category.createdAt = Date()
        category.lastModified = Date()
        persistenceService.save()
    }
}
