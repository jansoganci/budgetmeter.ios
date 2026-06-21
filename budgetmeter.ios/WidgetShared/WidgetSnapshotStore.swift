//
//  WidgetSnapshotStore.swift
//  BudgetMeter
//
//  Reads and writes the shared widget snapshot via App Group storage.
//

import Foundation

struct WidgetSnapshotStore {
    private let defaults: UserDefaults?
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(appGroupID: String = WidgetConstants.appGroupID) {
        defaults = UserDefaults(suiteName: appGroupID)
    }

    init(userDefaults: UserDefaults) {
        defaults = userDefaults
    }

    func save(_ snapshot: WidgetSnapshot) {
        guard let defaults else { return }
        guard let data = try? encoder.encode(snapshot) else { return }
        defaults.set(data, forKey: WidgetConstants.snapshotStorageKey)
    }

    func load() -> WidgetSnapshot? {
        guard let defaults else { return nil }
        guard let data = defaults.data(forKey: WidgetConstants.snapshotStorageKey) else { return nil }
        guard let snapshot = try? decoder.decode(WidgetSnapshot.self, from: data) else { return nil }
        guard snapshot.schemaVersion == WidgetConstants.schemaVersion else { return nil }
        return snapshot
    }

    func clear() {
        defaults?.removeObject(forKey: WidgetConstants.snapshotStorageKey)
    }
}
