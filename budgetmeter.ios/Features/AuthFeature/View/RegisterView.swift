//
//  RegisterView.swift
//  BudgetMeter
//
//  Account registration form.
//

import SwiftUI

struct RegisterView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authService = AuthService.shared
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingVerification = false

    var body: some View {
        NavigationView {
            ZStack {
                AppBackground()

                ScrollView {
                    VStack(spacing: LayoutSpacing.sectionGap) {
                        AuthFormContainer(
                            title: String(localized: "auth.register.title", defaultValue: "Create Account", table: "UI"),
                            subtitle: String(
                                localized: "auth.register.subtitle",
                                defaultValue: "Start tracking your money more calmly.",
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
                                textContentType: .newPassword
                            )

                            SettingsDivider()

                            AuthSecureFieldRow(
                                title: String(localized: "auth.register.confirm_password", defaultValue: "Confirm Password", table: "UI"),
                                text: $confirmPassword,
                                textContentType: .newPassword
                            )
                        }

                        if let errorMessage {
                            StatusBanner(message: errorMessage, iconName: "xmark.octagon.fill", color: .financialNegative)
                        }

                        PrimaryCTAButton(
                            title: String(localized: "auth.register.button", defaultValue: "Create Account", table: "UI"),
                            isLoading: isLoading,
                            isDisabled: email.isEmpty || password.isEmpty || confirmPassword.isEmpty || isLoading
                        ) {
                            guard password == confirmPassword else {
                                errorMessage = String(localized: "auth.register.password_mismatch", defaultValue: "Passwords do not match", table: "UI")
                                return
                            }
                            Task {
                                isLoading = true
                                errorMessage = nil
                                do {
                                    try await authService.signUp(email: email, password: password)
                                    dismiss()
                                } catch {
                                    errorMessage = error.localizedDescription
                                }
                                isLoading = false
                            }
                        }

                        AuthTextButton(
                            title: String(
                                localized: "auth.register.sign_in_link",
                                defaultValue: "Already have an account? Sign in",
                                table: "UI"
                            )
                        ) {
                            dismiss()
                        }
                    }
                    .padding(.horizontal, LayoutSpacing.screenPadding)
                    .padding(.vertical, Spacing.md)
                }
            }
            .navigationTitle(String(localized: "auth.register.title", defaultValue: "Create Account", table: "UI"))
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
