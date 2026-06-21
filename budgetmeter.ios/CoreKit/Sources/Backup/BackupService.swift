//
//  BackupService.swift
//  BudgetMeter
//
//  Premium-gated manual cloud backup and restore via Supabase.
//

import CoreData
import Foundation
import Supabase

enum BackupServiceError: Error, Foundation.LocalizedError {
    case notConfigured
    case notAuthenticated
    case premiumRequired
    case offline
    case backupFailed
    case restoreFailed
    case noCloudBackup
    case localDataRequiresConfirmation

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return String(localized: "backup.error.not_configured", defaultValue: "Cloud backup is not configured.", table: "UI")
        case .notAuthenticated:
            return String(localized: "backup.error.not_authenticated", defaultValue: "Sign in to use cloud backup.", table: "UI")
        case .premiumRequired:
            return String(localized: "backup.error.premium_required", defaultValue: "Cloud backup requires BudgetMeter Premium.", table: "UI")
        case .offline:
            return String(localized: "backup.error.offline", defaultValue: "Cloud backup is unavailable offline.", table: "UI")
        case .backupFailed:
            return String(localized: "backup.error.failed", defaultValue: "Backup failed. Your local data is safe.", table: "UI")
        case .restoreFailed:
            return String(localized: "backup.error.restore_failed", defaultValue: "Restore failed. Your previous data was preserved.", table: "UI")
        case .noCloudBackup:
            return String(localized: "backup.error.no_cloud_backup", defaultValue: "No cloud backup found for this account.", table: "UI")
        case .localDataRequiresConfirmation:
            return String(localized: "backup.error.confirm_restore", defaultValue: "Restore will replace local data on this device.", table: "UI")
        }
    }
}

@MainActor
final class BackupService: ObservableObject {

    static let shared = BackupService()

    @Published private(set) var syncState = SyncStateStore()

    private let persistenceService: PersistenceService
    private let serializer: BackupSerializer
    private let snapshotService: LocalSnapshotService
    private let restoreImporter: RestoreImporter
    private let stateMachine: FirstSignInStateMachine
    private let clientProvider: () -> SupabaseClient?

    private let tableName = "user_backups"

    init(
        persistenceService: PersistenceService = .shared,
        serializer: BackupSerializer = BackupSerializer(),
        snapshotService: LocalSnapshotService = LocalSnapshotService(),
        restoreImporter: RestoreImporter = RestoreImporter(),
        stateMachine: FirstSignInStateMachine = FirstSignInStateMachine(),
        clientProvider: @escaping () -> SupabaseClient? = { SupabaseClientProvider.makeClient() }
    ) {
        self.persistenceService = persistenceService
        self.serializer = serializer
        self.snapshotService = snapshotService
        self.restoreImporter = restoreImporter
        self.stateMachine = stateMachine
        self.clientProvider = clientProvider
    }

    func evaluateFirstSignIn(
        isSignedIn: Bool,
        cloudBackup: CloudBackupSummary?,
        cloudKitAvailable: Bool
    ) -> (FirstSignInScenario, FirstSignInAction) {
        let context = persistenceService.viewContext
        let payload = (try? serializer.exportPayload(from: context)) ?? emptyPayload()
        let localPresence = stateMachine.hasLocalFinancialData(
            recordCount: stateMachine.localRecordCount(from: payload)
        )
        let cloudPresence: CloudDataPresence
        if let cloudBackup {
            cloudPresence = .hasBackup(updatedAt: cloudBackup.updatedAt, recordCount: cloudBackup.recordCount)
        } else {
            cloudPresence = .empty
        }

        let scenario = stateMachine.classify(
            localPresence: localPresence,
            cloudPresence: cloudPresence,
            isSignedIn: isSignedIn,
            cloudKitAvailable: cloudKitAvailable
        )
        return (scenario, stateMachine.recommendedAction(for: scenario))
    }

    func markFirstSignInCompleted() {
        syncState = updatedSyncState { $0.firstSignInCompleted = true }
    }

    func backupNow(isPremium: Bool, userID: String?) async throws {
        try validateBackupPreconditions(isPremium: isPremium, userID: userID)

        guard let client = clientProvider(), let userID, let userUUID = UUID(uuidString: userID) else {
            throw BackupServiceError.notConfigured
        }

        syncState = updatedSyncState { $0.status = .backingUp; $0.resetErrors() }

        do {
            let context = persistenceService.viewContext
            let payload = try serializer.exportPayload(from: context)
            _ = try snapshotService.createSnapshot(payload: payload, authenticatedUserID: userID)

            let row = CloudBackupRow(
                userId: userUUID,
                schemaVersion: payload.schemaVersion,
                appVersion: payload.appVersion,
                payload: payload,
                recordCounts: payload.recordCounts,
                updatedAt: Date()
            )

            try await client.from(tableName)
                .upsert(row, onConflict: "user_id")
                .execute()

            syncState = updatedSyncState {
                $0.lastBackupDate = Date()
                $0.firstBackupCompleted = true
                $0.status = .idle
            }
        } catch {
            syncState = updatedSyncState {
                $0.status = .failed
                $0.lastErrorMessage = BackupServiceError.backupFailed.errorDescription
            }
            throw BackupServiceError.backupFailed
        }
    }

    func fetchCloudBackupSummary(userID: String?) async throws -> CloudBackupSummary? {
        guard let client = clientProvider(), let userID, let userUUID = UUID(uuidString: userID) else {
            throw BackupServiceError.notConfigured
        }

        let rows: [CloudBackupRow] = try await client.from(tableName)
            .select()
            .eq("user_id", value: userUUID.uuidString)
            .limit(1)
            .execute()
            .value

        guard let row = rows.first else { return nil }

        return CloudBackupSummary(
            updatedAt: row.updatedAt ?? row.payload.exportedAt,
            recordCount: row.recordCounts.totalRecords,
            appVersion: row.appVersion
        )
    }

    func restoreFromCloud(
        isPremium: Bool,
        userID: String?,
        confirmedOverwrite: Bool
    ) async throws {
        try validateBackupPreconditions(isPremium: isPremium, userID: userID)

        guard let client = clientProvider(), let userID else {
            throw BackupServiceError.notConfigured
        }

        let context = persistenceService.viewContext
        let localPayload = try serializer.exportPayload(from: context)
        if localPayload.recordCounts.totalRecords > 0, !confirmedOverwrite {
            throw BackupServiceError.localDataRequiresConfirmation
        }

        syncState = updatedSyncState { $0.status = .restoring; $0.resetErrors() }

        do {
            let rows: [CloudBackupRow] = try await client.from(tableName)
                .select()
                .eq("user_id", value: userID)
                .limit(1)
                .execute()
                .value

            guard let row = rows.first else {
                syncState = updatedSyncState {
                    $0.status = .failed
                    $0.lastErrorMessage = BackupServiceError.noCloudBackup.errorDescription
                }
                throw BackupServiceError.noCloudBackup
            }

            _ = try snapshotService.createSnapshot(payload: localPayload, authenticatedUserID: userID)

            try restoreImporter.importPayload(row.payload, into: context)
            persistenceService.save()

            syncState = updatedSyncState {
                $0.lastRestoreDate = Date()
                $0.status = .idle
            }
        } catch let error as BackupServiceError {
            syncState = updatedSyncState {
                $0.status = .failed
                $0.lastErrorMessage = error.errorDescription
            }
            throw error
        } catch {
            syncState = updatedSyncState {
                $0.status = .failed
                $0.lastErrorMessage = BackupServiceError.restoreFailed.errorDescription
            }
            throw BackupServiceError.restoreFailed
        }
    }

    private func validateBackupPreconditions(isPremium: Bool, userID: String?) throws {
        guard SupabaseConfig.isConfigured, clientProvider() != nil else {
            throw BackupServiceError.notConfigured
        }

        guard isPremium else {
            throw BackupServiceError.premiumRequired
        }

        guard userID != nil else {
            throw BackupServiceError.notAuthenticated
        }
    }

    private func updatedSyncState(_ update: (inout SyncStateStore) -> Void) -> SyncStateStore {
        var state = syncState
        update(&state)
        return state
    }

    private func emptyPayload() -> BackupPayload {
        BackupPayload(
            schemaVersion: BackupConstants.schemaVersion,
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
    }
}

struct CloudBackupSummary: Equatable {
    let updatedAt: Date
    let recordCount: Int
    let appVersion: String
}
