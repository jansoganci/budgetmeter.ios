//
//  SyncStateStore.swift
//  BudgetMeter
//
//  Persists local backup/sync metadata.
//

import Foundation

enum BackupSyncStatus: String, Codable, Equatable {
    case idle
    case backingUp
    case restoring
    case failed
    case offline
}

struct SyncStateStore {

    private let defaults: UserDefaults

    private enum Keys {
        static let lastBackupDate = "SyncState.lastBackupDate"
        static let lastRestoreDate = "SyncState.lastRestoreDate"
        static let lastErrorMessage = "SyncState.lastErrorMessage"
        static let status = "SyncState.status"
        static let firstSignInCompleted = "SyncState.firstSignInCompleted"
        static let firstBackupCompleted = "SyncState.firstBackupCompleted"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var lastBackupDate: Date? {
        get { defaults.object(forKey: Keys.lastBackupDate) as? Date }
        set { defaults.set(newValue, forKey: Keys.lastBackupDate) }
    }

    var lastRestoreDate: Date? {
        get { defaults.object(forKey: Keys.lastRestoreDate) as? Date }
        set { defaults.set(newValue, forKey: Keys.lastRestoreDate) }
    }

    var lastErrorMessage: String? {
        get { defaults.string(forKey: Keys.lastErrorMessage) }
        set { defaults.set(newValue, forKey: Keys.lastErrorMessage) }
    }

    var status: BackupSyncStatus {
        get {
            guard let raw = defaults.string(forKey: Keys.status),
                  let value = BackupSyncStatus(rawValue: raw) else {
                return .idle
            }
            return value
        }
        set { defaults.set(newValue.rawValue, forKey: Keys.status) }
    }

    var firstSignInCompleted: Bool {
        get { defaults.bool(forKey: Keys.firstSignInCompleted) }
        set { defaults.set(newValue, forKey: Keys.firstSignInCompleted) }
    }

    var firstBackupCompleted: Bool {
        get { defaults.bool(forKey: Keys.firstBackupCompleted) }
        set { defaults.set(newValue, forKey: Keys.firstBackupCompleted) }
    }

    mutating func resetErrors() {
        lastErrorMessage = nil
        if status == .failed || status == .offline {
            status = .idle
        }
    }
}
