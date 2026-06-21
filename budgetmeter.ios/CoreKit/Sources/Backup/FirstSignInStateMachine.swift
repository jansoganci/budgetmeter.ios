//
//  FirstSignInStateMachine.swift
//  BudgetMeter
//
//  Classifies first sign-in scenarios and returns safe next actions.
//

import Foundation

enum LocalDataPresence: Equatable {
    case empty
    case hasFinancialData
}

enum CloudDataPresence: Equatable {
    case empty
    case hasBackup(updatedAt: Date, recordCount: Int)
}

enum FirstSignInScenario: Equatable {
    case localOnly
    case cloudOnly
    case overlap
    case signedOutWithLocalData
    case existingCloudKitUser
}

enum FirstSignInAction: Equatable {
    case preserveLocalNoCloudWrite
    case offerCloudRestore
    case requireOverlapChoice
    case noActionNeeded
    case recommendCloudKitMigrationDryRun
}

struct FirstSignInStateMachine {

    func classify(
        localPresence: LocalDataPresence,
        cloudPresence: CloudDataPresence,
        isSignedIn: Bool,
        cloudKitAvailable: Bool
    ) -> FirstSignInScenario {
        if !isSignedIn {
            switch localPresence {
            case .empty:
                return .signedOutWithLocalData
            case .hasFinancialData:
                return .signedOutWithLocalData
            }
        }

        if cloudKitAvailable, case .hasFinancialData = localPresence {
            return .existingCloudKitUser
        }

        switch (localPresence, cloudPresence) {
        case (.empty, .empty):
            return .localOnly
        case (.hasFinancialData, .empty):
            return .localOnly
        case (.empty, .hasBackup):
            return .cloudOnly
        case (.hasFinancialData, .hasBackup):
            return .overlap
        }
    }

    func recommendedAction(for scenario: FirstSignInScenario) -> FirstSignInAction {
        switch scenario {
        case .localOnly:
            return .preserveLocalNoCloudWrite
        case .cloudOnly:
            return .offerCloudRestore
        case .overlap:
            return .requireOverlapChoice
        case .signedOutWithLocalData:
            return .noActionNeeded
        case .existingCloudKitUser:
            return .recommendCloudKitMigrationDryRun
        }
    }

    func localRecordCount(from payload: BackupPayload) -> Int {
        payload.recordCounts.totalRecords
    }

    func hasLocalFinancialData(recordCount: Int) -> LocalDataPresence {
        recordCount > 0 ? .hasFinancialData : .empty
    }
}
