//
//  AuthSessionStore.swift
//  BudgetMeter
//
//  Stores non-secret auth metadata locally.
//

import Foundation

struct AuthSessionStore {

    private let defaults: UserDefaults

    private enum Keys {
        static let userID = "AuthSession.userID"
        static let email = "AuthSession.email"
        static let lastSignedInAt = "AuthSession.lastSignedInAt"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var userID: String? {
        get { defaults.string(forKey: Keys.userID) }
        set { defaults.set(newValue, forKey: Keys.userID) }
    }

    var email: String? {
        get { defaults.string(forKey: Keys.email) }
        set { defaults.set(newValue, forKey: Keys.email) }
    }

    var lastSignedInAt: Date? {
        get { defaults.object(forKey: Keys.lastSignedInAt) as? Date }
        set { defaults.set(newValue, forKey: Keys.lastSignedInAt) }
    }

    mutating func save(userID: String, email: String?) {
        self.userID = userID
        self.email = email
        lastSignedInAt = Date()
    }

    mutating func clear() {
        userID = nil
        email = nil
        lastSignedInAt = nil
    }
}
