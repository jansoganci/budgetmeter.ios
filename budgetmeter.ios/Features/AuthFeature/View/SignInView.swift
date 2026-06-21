//
//  SignInView.swift
//  BudgetMeter
//
//  Email sign-in form.
//

import SwiftUI

struct SignInView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authService = AuthService.shared
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingForgotPassword = false

    var body: some View {
        NavigationView {
            ZStack {
                AppBackground()

                ScrollView {
                    VStack(spacing: LayoutSpacing.sectionGap) {
                        AuthFormContainer(
                            title: String(localized: "auth.sign_in.title", defaultValue: "Sign In", table: "UI"),
                            subtitle: String(
                                localized: "auth.sign_in.subtitle",
                                defaultValue: "Continue tracking your money pace.",
                                table: "UI"
                            )
                        ) {
                            AuthTextFieldRow(
                                title: String(localized: "auth.sign_in.email", defaultValue: "Email", table: "UI"),
                                text: $email,
                                keyboardType: .emailAddress,
                                textContentType: .emailAddress
                            )

                            SettingsDivider()

                            AuthSecureFieldRow(
                                title: String(localized: "auth.sign_in.password", defaultValue: "Password", table: "UI"),
                                text: $password,
                                textContentType: .password
                            )
                        }

                        if let errorMessage {
                            StatusBanner(message: errorMessage, iconName: "xmark.octagon.fill", color: .financialNegative)
                        }

                        PrimaryCTAButton(
                            title: String(localized: "auth.sign_in.button", defaultValue: "Sign In", table: "UI"),
                            isLoading: isLoading,
                            isDisabled: email.isEmpty || password.isEmpty || isLoading
                        ) {
                            Task {
                                isLoading = true
                                errorMessage = nil
                                do {
                                    try await authService.signIn(email: email, password: password)
                                    dismiss()
                                } catch {
                                    errorMessage = error.localizedDescription
                                }
                                isLoading = false
                            }
                        }

                        AuthTextButton(title: String(localized: "auth.sign_in.forgot_password", defaultValue: "Forgot Password?", table: "UI")) {
                            showingForgotPassword = true
                        }
                    }
                    .padding(.horizontal, LayoutSpacing.screenPadding)
                    .padding(.vertical, Spacing.md)
                }
            }
            .navigationTitle(String(localized: "auth.sign_in.title", defaultValue: "Sign In", table: "UI"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(String(localized: "common.cancel", defaultValue: "Cancel", table: "UI")) { dismiss() }
                }
            }
            .disabled(isLoading)
            .sheet(isPresented: $showingForgotPassword) {
                ForgotPasswordView()
            }
        }
    }
}

// MARK: - Auth Design Components

struct AuthFormContainer<Content: View>: View {
    let title: String
    var subtitle: String? = nil
    @ViewBuilder let content: () -> Content

    var body: some View {
        GlassCard(padding: 0) {
            VStack(alignment: .leading, spacing: 0) {
                BudgetHeader(title: title, subtitle: subtitle)
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, Spacing.md)
                    .padding(.bottom, Spacing.sm)

                VStack(spacing: 0) {
                    content()
                }
            }
        }
    }
}

struct AuthTextFieldRow: View {
    let title: String
    @Binding var text: String
    let keyboardType: UIKeyboardType
    let textContentType: UITextContentType?

    var body: some View {
        TextField(title, text: $text)
            .keyboardType(keyboardType)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .textContentType(textContentType)
            .bodyStyle()
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .frame(minHeight: 56)
    }
}

struct AuthSecureFieldRow: View {
    let title: String
    @Binding var text: String
    let textContentType: UITextContentType?

    var body: some View {
        SecureField(title, text: $text)
            .textContentType(textContentType)
            .bodyStyle()
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .frame(minHeight: 56)
    }
}

struct AuthTextButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .cardLabelStyle(color: .brandProgress)
                .frame(minHeight: TouchTarget.minimum)
        }
        .buttonStyle(.plain)
    }
}
