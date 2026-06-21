# Auth Implementation — Steps 6-9: SignIn, Register, ForgotPassword, VerificationPending

BudgetMeter iOS project at /Users/jans/Desktop/nexus/budgetmeter.ios.

## Context
WelcomeView and auth gate exist. Now fill in the actual auth forms.

## Step 6: SignInView.swift

Replace the placeholder at `Features/AuthFeature/View/SignInView.swift`:

```swift
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
            Form {
                Section("Sign In") {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    SecureField("Password", text: $password)
                }
                
                if let errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Button("Sign In") {
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
                .disabled(email.isEmpty || password.isEmpty || isLoading)
                
                Button("Forgot Password?") {
                    showingForgotPassword = true
                }
                .font(.caption)
            }
            .navigationTitle("Sign In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .disabled(isLoading)
            .sheet(isPresented: $showingForgotPassword) {
                ForgotPasswordView()
            }
        }
    }
}
```

## Step 7: RegisterView.swift

Replace the placeholder at `Features/AuthFeature/View/RegisterView.swift`:

```swift
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
            Form {
                Section("Create Account") {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    SecureField("Password", text: $password)
                    SecureField("Confirm Password", text: $confirmPassword)
                }
                
                if let errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Button("Create Account") {
                    guard password == confirmPassword else {
                        errorMessage = "Passwords do not match"
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
                .disabled(email.isEmpty || password.isEmpty || confirmPassword.isEmpty || isLoading)
            }
            .navigationTitle("Create Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .disabled(isLoading)
        }
    }
}
```

## Step 8: ForgotPasswordView.swift

Create `Features/AuthFeature/View/ForgotPasswordView.swift`:

```swift
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
            Form {
                Section("Reset Password") {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
                
                if let message {
                    Text(message)
                        .foregroundColor(.green)
                        .font(.caption)
                }
                if let errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Button("Send Reset Link") {
                    Task {
                        isLoading = true
                        errorMessage = nil
                        message = nil
                        do {
                            try await authService.resetPassword(email: email)
                            message = "If this email is registered, you'll receive a reset link."
                        } catch {
                            errorMessage = error.localizedDescription
                        }
                        isLoading = false
                    }
                }
                .disabled(email.isEmpty || isLoading)
            }
            .navigationTitle("Reset Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .disabled(isLoading)
        }
    }
}
```

## Step 9: VerificationPendingView (optional, skip for now)

This shows "Check your email to verify" after registration. Can be added later if Supabase email verification is enabled. Skip for now.

## Also: Add navigation from WelcomeView to SignInView/RegisterView
WelcomeView already has the sheet calls for showingSignIn and showingRegister. Those should work with the real views now.

## Verification
Build must succeed.
```sh
xcodebuild -project budgetmeter.ios.xcodeproj -scheme budgetmeter.ios -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' build
```
