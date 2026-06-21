//
//  LocalSnapshotService.swift
//  BudgetMeter
//
//  Stores local backup snapshots outside the live Core Data store.
//

import Foundation

enum LocalSnapshotError: Error {
    case directoryUnavailable
    case writeFailed
    case readFailed
    case snapshotNotFound
}

struct LocalSnapshotService {

    private let fileManager: FileManager
    private let serializer: BackupSerializer

    init(fileManager: FileManager = .default, serializer: BackupSerializer = BackupSerializer()) {
        self.fileManager = fileManager
        self.serializer = serializer
    }

    func createSnapshot(
        payload: BackupPayload,
        authenticatedUserID: String? = nil,
        sessionID: UUID = UUID()
    ) throws -> LocalBackupSnapshot {
        let snapshot = LocalBackupSnapshot(
            sessionID: sessionID,
            createdAt: Date(),
            schemaVersion: payload.schemaVersion,
            appVersion: payload.appVersion,
            authenticatedUserID: authenticatedUserID,
            payload: payload
        )

        let data = try serializer.encode(payload)
        let directory = try snapshotsDirectory()
        let snapshotMetaURL = directory.appendingPathComponent("\(sessionID.uuidString).meta.json")
        let snapshotDataURL = directory.appendingPathComponent("\(sessionID.uuidString).payload.json")

        let metaData = try JSONEncoder().encode(snapshot)
        try metaData.write(to: snapshotMetaURL, options: .atomic)
        try data.write(to: snapshotDataURL, options: .atomic)

        return snapshot
    }

    func latestSnapshot() throws -> LocalBackupSnapshot? {
        let directory = try snapshotsDirectory()
        let urls = try fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ).filter { $0.pathExtension == "meta" && $0.lastPathComponent.hasSuffix(".meta.json") }

        guard !urls.isEmpty else { return nil }

        let sorted = try urls.sorted {
            let left = try $0.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate ?? .distantPast
            let right = try $1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate ?? .distantPast
            return left > right
        }

        guard let latestURL = sorted.first else { return nil }
        let data = try Data(contentsOf: latestURL)
        return try JSONDecoder().decode(LocalBackupSnapshot.self, from: data)
    }

    func loadSnapshot(sessionID: UUID) throws -> BackupPayload {
        let directory = try snapshotsDirectory()
        let snapshotDataURL = directory.appendingPathComponent("\(sessionID.uuidString).payload.json")
        guard fileManager.fileExists(atPath: snapshotDataURL.path) else {
            throw LocalSnapshotError.snapshotNotFound
        }
        let data = try Data(contentsOf: snapshotDataURL)
        return try serializer.decode(data)
    }

    private func snapshotsDirectory() throws -> URL {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        guard let base else { throw LocalSnapshotError.directoryUnavailable }

        let directory = base.appendingPathComponent(BackupConstants.snapshotDirectoryName, isDirectory: true)
        if !fileManager.fileExists(atPath: directory.path) {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        return directory
    }
}
