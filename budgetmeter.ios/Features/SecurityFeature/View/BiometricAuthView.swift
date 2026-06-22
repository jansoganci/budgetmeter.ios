//
//  BiometricAuthView.swift
//  BudgetMeter
//
//  Created by BudgetMeter Team on 17.09.2025.
//

import SwiftUI
import LocalAuthentication

struct BiometricAuthView: View {
    @EnvironmentObject private var biometricManager: BiometricManager
    @State private var isAuthenticating = false
    @State private var showError = false
    @State private var hasAttemptedAutoAuth = false
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: biometricManager.biometricType.iconName)
                .font(.system(size: 80))
                .foregroundColor(.accentColor)
                .padding(.bottom, 20)
            
            Text("security.auth.title".localized(defaultValue: "Secure Access"))
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text(statusSubtitle)
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            Button {
                authenticateUser()
            } label: {
                HStack {
                    if isAuthenticating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: biometricManager.biometricType.iconName)
                    }
                    
                    Text(retryButtonTitle)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(isAuthenticating)
            .padding(.horizontal)
            
            VStack(spacing: 15) {
                Text("security.auth.fallback".localized(defaultValue: "Having trouble?"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Button("security.auth.passcode".localized(defaultValue: "Use Passcode")) {
                    authenticateWithPasscode()
                }
                .font(.subheadline)
                .foregroundColor(.accentColor)
                .disabled(isAuthenticating)
            }
            .padding(.bottom, 30)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .task {
            guard !hasAttemptedAutoAuth else { return }
            hasAttemptedAutoAuth = true
            authenticateUser()
        }
        .alert("security.auth.error.title".localized(defaultValue: "Authentication Error"), isPresented: $showError) {
            Button("toolbar.ok".localized(defaultValue: "OK")) {
                showError = false
            }
        } message: {
            Text(biometricManager.errorMessage ?? "security.auth.error.message".localized(defaultValue: "Authentication failed. Please try again."))
        }
    }
    
    private var statusSubtitle: String {
        if biometricManager.lastAuthenticationWasCancelled {
            return "biometric.error.user_cancel".localized(defaultValue: "Authentication was cancelled by the user")
        }
        return String(
            format: "security.auth.subtitle".localized(defaultValue: "Use %@ to access your financial data"),
            biometricManager.biometricType.displayName
        )
    }
    
    private var retryButtonTitle: String {
        if biometricManager.lastAuthenticationWasCancelled {
            return "security.auth.retry".localized(defaultValue: "Try Again")
        }
        return "security.auth.button".localized(defaultValue: "Authenticate")
    }
    
    private func authenticateUser() {
        guard !isAuthenticating else { return }
        isAuthenticating = true
        
        Task {
            let success = await biometricManager.authenticateUser()
            
            await MainActor.run {
                isAuthenticating = false
                
                if success {
                    return
                }
                
                if !biometricManager.lastAuthenticationWasCancelled {
                    showError = true
                }
            }
        }
    }
    
    private func authenticateWithPasscode() {
        guard !isAuthenticating else { return }
        isAuthenticating = true
        
        Task {
            let success = await biometricManager.authenticateWithPasscode()
            
            await MainActor.run {
                isAuthenticating = false
                
                if success {
                    return
                }
                
                if !biometricManager.lastAuthenticationWasCancelled {
                    showError = true
                }
            }
        }
    }
}

#Preview {
    BiometricAuthView()
        .environmentObject(BiometricManager.shared)
}
