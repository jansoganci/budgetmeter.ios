//
//  FirstSignInStateMachineTests.swift
//  budgetmeter.iosTests
//
//  Phase 9 first sign-in safety contract tests.
//

import XCTest
@testable import budgetmeter_ios

final class FirstSignInStateMachineTests: XCTestCase {

    private let stateMachine = FirstSignInStateMachine()

    func test_localOnlyScenario_preservesLocalDataAction() {
        let scenario = stateMachine.classify(
            localPresence: .hasFinancialData,
            cloudPresence: .empty,
            isSignedIn: true,
            cloudKitAvailable: false
        )

        XCTAssertEqual(scenario, .localOnly)
        XCTAssertEqual(stateMachine.recommendedAction(for: scenario), .preserveLocalNoCloudWrite)
    }

    func test_cloudOnlyScenario_offersRestore() {
        let scenario = stateMachine.classify(
            localPresence: .empty,
            cloudPresence: .hasBackup(updatedAt: Date(), recordCount: 3),
            isSignedIn: true,
            cloudKitAvailable: false
        )

        XCTAssertEqual(scenario, .cloudOnly)
        XCTAssertEqual(stateMachine.recommendedAction(for: scenario), .offerCloudRestore)
    }

    func test_overlapScenario_requiresChoice() {
        let scenario = stateMachine.classify(
            localPresence: .hasFinancialData,
            cloudPresence: .hasBackup(updatedAt: Date(), recordCount: 3),
            isSignedIn: true,
            cloudKitAvailable: false
        )

        XCTAssertEqual(scenario, .overlap)
        XCTAssertEqual(stateMachine.recommendedAction(for: scenario), .requireOverlapChoice)
    }

    func test_signedOutWithLocalData_noActionNeeded() {
        let scenario = stateMachine.classify(
            localPresence: .hasFinancialData,
            cloudPresence: .empty,
            isSignedIn: false,
            cloudKitAvailable: false
        )

        XCTAssertEqual(scenario, .signedOutWithLocalData)
        XCTAssertEqual(stateMachine.recommendedAction(for: scenario), .noActionNeeded)
    }
}
