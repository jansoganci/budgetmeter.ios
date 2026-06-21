//
//  WelcomeView.swift
//  BudgetMeter
//
//  Mandatory auth entry screen with Apple and email sign-in options.
//

import AuthenticationServices
import SwiftUI

struct WelcomeView: View {
    @StateObject private var authService = AuthService.shared
    @State private var showingSignIn = false
    @State private var showingRegister = false

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: Spacing.xl) {
                Spacer(minLength: Spacing.xl)

                GlassCard {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        BudgetHeader(
                            title: String(localized: "auth.welcome.title", defaultValue: "BudgetMeter", table: "UI"),
                            subtitle: String(
                                localized: "auth.welcome.subtitle",
                                defaultValue: "Understanding your money is easier now.",
                                table: "UI"
                            )
                        )

                        Text(
                            String(
                                localized: "auth.welcome.support",
                                defaultValue: "See where your money goes today, in one glance.",
                                table: "UI"
                            )
                        )
                        .bodyStyle(color: .textSecondary)

                        Color.clear
                            .frame(minHeight: 48)
                            .accessibilityHidden(true)
                    }
                }

                Spacer()

                VStack(spacing: Spacing.md) {
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        Task { await handleAppleSignIn(result) }
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.button, style: .continuous))
                    .accessibilityLabel(String(localized: "auth.welcome.sign_in_apple", defaultValue: "Sign in with Apple", table: "UI"))

                    SecondaryCTAButton(
                        title: String(localized: "auth.welcome.sign_in_email", defaultValue: "Sign in with Email", table: "UI")
                    ) {
                        showingSignIn = true
                    }

                    AuthTextButton(title: String(localized: "auth.welcome.create_account", defaultValue: "Create Account", table: "UI")) {
                        showingRegister = true
                    }
                }
            }
            .padding(.horizontal, LayoutSpacing.screenPadding)
            .padding(.vertical, Spacing.xxl)
        }
        .sheet(isPresented: $showingSignIn) {
            SignInView()
        }
        .sheet(isPresented: $showingRegister) {
            RegisterView()
        }
    }

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) async {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else { return }
            try? await authService.handleAppleCredential(credential)
        case .failure:
            break
        }
    }
}
