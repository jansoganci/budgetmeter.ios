//
//  AccountDeletionClientTests.swift
//  budgetmeter.iosTests
//
//  Verifies account deletion uses the Supabase Edge Function contract.
//

import Foundation
import XCTest
@testable import budgetmeter_ios

final class AccountDeletionClientTests: XCTestCase {

    func test_deleteAccount_postsToEdgeFunctionWithBearerTokenAndAnonKey() async throws {
        let session = MockAccountDeletionURLSession(statusCode: 200)
        let client = EdgeFunctionAccountDeletionClient(
            functionURL: URL(string: "https://example.supabase.co/functions/v1/delete-account")!,
            session: session
        )

        try await client.deleteAccount(accessToken: "test-token")

        let request = try XCTUnwrap(session.lastRequest)
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.url?.absoluteString, "https://example.supabase.co/functions/v1/delete-account")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-token")
        XCTAssertEqual(request.value(forHTTPHeaderField: "apikey"), SupabaseConfig.anonKey)
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
    }

    func test_deleteAccount_rejectsNonSuccessStatus() async throws {
        let session = MockAccountDeletionURLSession(statusCode: 401)
        let client = EdgeFunctionAccountDeletionClient(
            functionURL: URL(string: "https://example.supabase.co/functions/v1/delete-account")!,
            session: session
        )

        do {
            try await client.deleteAccount(accessToken: "expired-token")
            XCTFail("Expected account deletion to fail for non-2xx response")
        } catch let error as AccountDeletionClientError {
            XCTAssertEqual(error, .requestFailed(statusCode: 401))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_deleteAccount_rejectsNonHTTPResponse() async throws {
        let session = MockAccountDeletionURLSession(response: URLResponse())
        let client = EdgeFunctionAccountDeletionClient(
            functionURL: URL(string: "https://example.supabase.co/functions/v1/delete-account")!,
            session: session
        )

        do {
            try await client.deleteAccount(accessToken: "test-token")
            XCTFail("Expected account deletion to fail for invalid response")
        } catch let error as AccountDeletionClientError {
            XCTAssertEqual(error, .invalidResponse)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

private final class MockAccountDeletionURLSession: AccountDeletionURLSessionProtocol {
    private(set) var lastRequest: URLRequest?
    private let response: URLResponse

    init(statusCode: Int) {
        response = HTTPURLResponse(
            url: URL(string: "https://example.supabase.co/functions/v1/delete-account")!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
    }

    init(response: URLResponse) {
        self.response = response
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        lastRequest = request
        return (Data(), response)
    }
}
