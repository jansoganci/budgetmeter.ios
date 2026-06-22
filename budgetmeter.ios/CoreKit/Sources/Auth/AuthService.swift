//
//  AuthService.swift
//  BudgetMeter
//
//  Manages Supabase Auth sessions and Apple Sign In.
//

import AuthenticationServices
import Foundation
import Supabase

enum AuthPhase: Equatable {
    case unknown
    case restoring
    case signedOut
    case signedIn
}

enum AuthProvider: Equatable {
    case apple
    case email
}

enum AccountDeletionClientError: Error, Equatable {
    case invalidResponse
    case requestFailed(statusCode: Int)
}

protocol AccountDeletionClientProtocol {
    func deleteAccount(accessToken: String) async throws
}

protocol AccountDeletionURLSessionProtocol {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: AccountDeletionURLSessionProtocol {}

struct EdgeFunctionAccountDeletionClient: AccountDeletionClientProtocol {
    private let functionURL: URL
    private let session: AccountDeletionURLSessionProtocol

    init(
        functionURL: URL = SupabaseConfig.edgeFunctionURL(named: "delete-account"),
        session: AccountDeletionURLSessionProtocol = URLSession.shared
    ) {
        self.functionURL = functionURL
        self.session = session
    }

    func deleteAccount(accessToken: String) async throws {
        var request = URLRequest(url: functionURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = Data("{}".utf8)

        let (_, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AccountDeletionClientError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw AccountDeletionClientError.requestFailed(statusCode: httpResponse.statusCode)
        }
    }
}

enum AuthServiceError: Error, Foundation.LocalizedError {
    case notConfigured
    case notAuthenticated
    case signInFailed
    case signOutFailed
    case accountDeletionFailed

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return String(localized: "auth.error.not_configured", defaultValue: "Cloud sign-in is not configured.", table: "UI")
        case .notAuthenticated:
            return String(localized: "auth.error.not_authenticated", defaultValue: "You are not signed in.", table: "UI")
        case .signInFailed:
            return String(localized: "auth.error.sign_in_failed", defaultValue: "Sign in failed. Please try again.", table: "UI")
        case .signOutFailed:
            return String(localized: "auth.error.sign_out_failed", defaultValue: "Sign out failed. Please try again.", table: "UI")
        case .accountDeletionFailed:
            return String(localized: "auth.error.delete_failed", defaultValue: "Account deletion failed. Please try again.", table: "UI")
        }
    }
}

@MainActor
final class AuthService: ObservableObject {

    static let shared = AuthService()

    @Published private(set) var phase: AuthPhase = .unknown
    @Published private(set) var authProvider: AuthProvider?
    @Published private(set) var currentUserID: String?
    @Published private(set) var currentEmail: String?
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    var isAuthenticated: Bool { phase == .signedIn }

    private var sessionStore: AuthSessionStore
    private let clientProvider: () -> SupabaseClient?
    private let accountDeletionClient: AccountDeletionClientProtocol
    private var client: SupabaseClient? { clientProvider() }

    init(
        sessionStore: AuthSessionStore = AuthSessionStore(),
        clientProvider: @escaping () -> SupabaseClient? = { SupabaseClientProvider.makeClient() },
        accountDeletionClient: AccountDeletionClientProtocol = EdgeFunctionAccountDeletionClient()
    ) {
        self.sessionStore = sessionStore
        self.clientProvider = clientProvider
        self.accountDeletionClient = accountDeletionClient
        phase = .unknown
        Task { await restoreSessionIfNeeded() }
    }

    func restoreSessionIfNeeded() async {
        phase = .restoring

        guard let client else {
            clearSessionState()
            return
        }

        do {
            let session = try await client.auth.session
            applySession(user: session.user, provider: inferredProvider(from: session.user))
        } catch {
            if let cachedSession = client.auth.currentSession, cachedSession.isExpired {
                do {
                    let refreshedSession = try await client.auth.refreshSession()
                    applySession(user: refreshedSession.user, provider: inferredProvider(from: refreshedSession.user))
                    return
                } catch {
                    clearSessionState()
                    return
                }
            }

            clearSessionState()
        }
    }

    func handleAppleCredential(_ credential: ASAuthorizationAppleIDCredential) async throws {
        guard let client else { throw AuthServiceError.notConfigured }

        guard let tokenData = credential.identityToken,
              let idToken = String(data: tokenData, encoding: .utf8) else {
            throw AuthServiceError.signInFailed
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let session = try await client.auth.signInWithIdToken(
                credentials: OpenIDConnectCredentials(
                    provider: .apple,
                    idToken: idToken
                )
            )

            if let fullName = credential.fullName {
                let nameParts = [fullName.givenName, fullName.middleName, fullName.familyName]
                    .compactMap { $0 }
                if !nameParts.isEmpty {
                    _ = try? await client.auth.update(
                        user: UserAttributes(
                            data: [
                                "full_name": .string(nameParts.joined(separator: " "))
                            ]
                        )
                    )
                }
            }

            applySession(user: session.user, provider: .apple)
        } catch {
            errorMessage = AuthServiceError.signInFailed.errorDescription
            throw AuthServiceError.signInFailed
        }
    }

    func signIn(email: String, password: String) async throws {
        guard let client else { throw AuthServiceError.notConfigured }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let session = try await client.auth.signIn(email: email, password: password)
            applySession(user: session.user, provider: .email)
        } catch {
            errorMessage = AuthServiceError.signInFailed.errorDescription
            throw AuthServiceError.signInFailed
        }
    }

    func signUp(email: String, password: String) async throws {
        guard let client else { throw AuthServiceError.notConfigured }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let response = try await client.auth.signUp(email: email, password: password)
            guard let session = response.session else {
                throw AuthServiceError.signInFailed
            }
            applySession(user: session.user, provider: .email)
        } catch let error as AuthServiceError {
            throw error
        } catch {
            errorMessage = AuthServiceError.signInFailed.errorDescription
            throw AuthServiceError.signInFailed
        }
    }

    func resetPassword(email: String) async throws {
        guard let client else { throw AuthServiceError.notConfigured }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        try await client.auth.resetPasswordForEmail(email)
    }

    func signOut() async {
        guard let client else {
            clearSessionState()
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            try await client.auth.signOut()
        } catch {
            errorMessage = AuthServiceError.signOutFailed.errorDescription
        }

        clearSessionState()
    }

    func deleteAccount() async throws {
        guard let client else { throw AuthServiceError.notConfigured }
        guard isAuthenticated else { throw AuthServiceError.notAuthenticated }

        isLoading = true
        defer { isLoading = false }

        do {
            let session = try await client.auth.session
            try await accountDeletionClient.deleteAccount(accessToken: session.accessToken)
            try? await client.auth.signOut()
            clearSessionState()
        } catch {
            errorMessage = AuthServiceError.accountDeletionFailed.errorDescription
            throw AuthServiceError.accountDeletionFailed
        }
    }

    private func applySession(user: User, provider: AuthProvider) {
        currentUserID = user.id.uuidString
        currentEmail = user.email
        authProvider = provider
        phase = .signedIn
        sessionStore.save(userID: user.id.uuidString, email: user.email)

        Task {
            await SupabaseAccountDataService.shared.bootstrapSignedInAccount(
                profileEmail: user.email,
                provider: provider == .apple ? "apple" : "email"
            )
            await SupabaseSavingsGoalSyncService.shared.bootstrapSignedInAccount()
            await SupabasePhase2FinancialSyncBootstrap.shared.bootstrapSignedInAccount()
            await SupabaseOneTimeTransactionSyncService.shared.bootstrapSignedInAccount()
            await SupabaseFinancialCategorySyncService.shared.bootstrapSignedInAccount()
        }
    }

    private func clearSessionState() {
        phase = .signedOut
        authProvider = nil
        currentUserID = nil
        currentEmail = nil
        sessionStore.clear()
    }

    private func inferredProvider(from user: User) -> AuthProvider {
        if let identities = user.identities,
           identities.contains(where: { $0.provider == "apple" }) {
            return .apple
        }
        return .email
    }
}
