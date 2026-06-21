//
//  WidgetSnapshotStoreTests.swift
//  budgetmeter.iosTests
//
//  Phase 8 — widget snapshot storage contract tests.
//

import XCTest
@testable import budgetmeter_ios

final class WidgetSnapshotStoreTests: XCTestCase {

    private var defaults: UserDefaults!
    private var store: WidgetSnapshotStore!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "WidgetSnapshotStoreTests")!
        defaults.removePersistentDomain(forName: "WidgetSnapshotStoreTests")
        store = WidgetSnapshotStore(userDefaults: defaults)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: "WidgetSnapshotStoreTests")
        defaults = nil
        store = nil
        super.tearDown()
    }

    func test_saveAndLoad_roundTripsSnapshot() {
        let snapshot = makeSnapshot(isPremium: true, displayState: .unlocked)
        store.save(snapshot)

        let loaded = store.load()
        XCTAssertEqual(loaded, snapshot)
    }

    func test_load_returnsNilWhenMissing() {
        XCTAssertNil(store.load())
    }

    func test_load_returnsNilForSchemaMismatch() {
        var snapshot = makeSnapshot(isPremium: true, displayState: .unlocked)
        let mismatched = WidgetSnapshot(
            schemaVersion: 999,
            netDailyPace: snapshot.netDailyPace,
            paceStatus: snapshot.paceStatus,
            displayValue: snapshot.displayValue,
            displayStatusCopy: snapshot.displayStatusCopy,
            currencyCode: snapshot.currencyCode,
            currencySymbol: snapshot.currencySymbol,
            isPremium: snapshot.isPremium,
            generatedAt: snapshot.generatedAt,
            staleAfter: snapshot.staleAfter,
            isLockedTeaser: snapshot.isLockedTeaser,
            lockedTeaserTitle: snapshot.lockedTeaserTitle,
            lockedTeaserSubtitle: snapshot.lockedTeaserSubtitle,
            deepLinkURL: snapshot.deepLinkURL,
            hasFinancialInput: snapshot.hasFinancialInput,
            displayState: snapshot.displayState,
            missingMessage: snapshot.missingMessage,
            staleMessage: snapshot.staleMessage
        )
        store.save(mismatched)
        XCTAssertNil(store.load())
    }

    func test_clear_removesSnapshot() {
        store.save(makeSnapshot(isPremium: false, displayState: .lockedTeaser))
        store.clear()
        XCTAssertNil(store.load())
    }

    func test_isStale_detectedFromStaleAfter() {
        let generatedAt = Date(timeIntervalSince1970: 1_000)
        let snapshot = WidgetSnapshot(
            schemaVersion: WidgetConstants.schemaVersion,
            netDailyPace: 10,
            paceStatus: "movingForward",
            displayValue: "+$10/day",
            displayStatusCopy: "Moving forward +$10/day",
            currencyCode: "USD",
            currencySymbol: "$",
            isPremium: true,
            generatedAt: generatedAt,
            staleAfter: generatedAt.addingTimeInterval(-60),
            isLockedTeaser: false,
            lockedTeaserTitle: "Premium Widget",
            lockedTeaserSubtitle: "Unlock",
            deepLinkURL: WidgetConstants.unlockedDeepLink,
            hasFinancialInput: true,
            displayState: .unlocked,
            missingMessage: "Open app",
            staleMessage: "Stale"
        )

        XCTAssertTrue(snapshot.isStale)
        XCTAssertEqual(snapshot.resolvedDisplayState, .stale)
    }

    private func makeSnapshot(isPremium: Bool, displayState: WidgetDisplayState) -> WidgetSnapshot {
        let generatedAt = Date()
        return WidgetSnapshot(
            schemaVersion: WidgetConstants.schemaVersion,
            netDailyPace: 12,
            paceStatus: "movingForward",
            displayValue: "+$12/day",
            displayStatusCopy: "Moving forward +$12/day",
            currencyCode: "USD",
            currencySymbol: "$",
            isPremium: isPremium,
            generatedAt: generatedAt,
            staleAfter: generatedAt.addingTimeInterval(WidgetConstants.staleInterval),
            isLockedTeaser: !isPremium,
            lockedTeaserTitle: "Premium Widget",
            lockedTeaserSubtitle: "Unlock net daily pace",
            deepLinkURL: isPremium ? WidgetConstants.unlockedDeepLink : WidgetConstants.lockedDeepLink,
            hasFinancialInput: true,
            displayState: displayState,
            missingMessage: "Open BudgetMeter to refresh",
            staleMessage: "Open BudgetMeter for the latest pace"
        )
    }
}
