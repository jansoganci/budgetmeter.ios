//
//  ForgotPasswordView.swift
//  BudgetMeter
//
//  Password reset request form.
//

import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authService = AuthService.shared
    @State private var email = ""
    @State private var isLoading = false
    @State private var message: String?
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            ZStack {
                AppBackground()

                ScrollView {
                    VStack(spacing: LayoutSpacing.sectionGap) {
                        AuthFormContainer(
                            title: String(localized: "auth.forgot_password.title", defaultValue: "Forgot Password", table: "UI"),
                            subtitle: String(
                                localized: "auth.forgot_password.subtitle",
                                defaultValue: "Enter your email to regain access to your account.",
                                table: "UI"
                            )
                        ) {
                            AuthTextFieldRow(
                                title: String(localized: "auth.sign_in.email", defaultValue: "Email", table: "UI"),
                                text: $email,
                                keyboardType: .emailAddress,
                                textContentType: .emailAddress
                            )
                        }

                        if let message {
                            StatusBanner(message: message, iconName: "checkmark.circle.fill", color: .financialPositive)
                        }

                        if let errorMessage {
                            StatusBanner(message: errorMessage, iconName: "xmark.octagon.fill", color: .financialNegative)
                        }

                        PrimaryCTAButton(
                            title: String(localized: "auth.forgot_password.send", defaultValue: "Send Reset Link", table: "UI"),
                            isLoading: isLoading,
                            isDisabled: email.isEmpty || isLoading
                        ) {
                            Task {
                                isLoading = true
                                errorMessage = nil
                                message = nil
                                do {
                                    try await authService.resetPassword(email: email)
                                    message = String(localized: "auth.forgot_password.sent", defaultValue: "If this email is registered, you'll receive a reset link.", table: "UI")
                                } catch {
                                    errorMessage = error.localizedDescription
                                }
                                isLoading = false
                            }
                        }
                    }
                    .padding(.horizontal, LayoutSpacing.screenPadding)
                    .padding(.vertical, Spacing.md)
                }
            }
            .navigationTitle(String(localized: "auth.forgot_password.title", defaultValue: "Forgot Password", table: "UI"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(String(localized: "common.cancel", defaultValue: "Cancel", table: "UI")) { dismiss() }
                }
            }
            .disabled(isLoading)
        }
    }
}
