//
//  BiometricAuthView.swift
//  BudgetMeter
//
//  Created by BudgetMeter Team on 17.09.2025.
//

import SwiftUI
import LocalAuthentication

struct BiometricAuthView: View {
    @StateObject private var biometricManager = BiometricManager.shared
    @State private var isAuthenticating = false
    @State private var showError = false
    
    let onAuthenticationSuccess: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Biometric Icon
            Image(systemName: biometricManager.biometricType.iconName)
                .font(.system(size: 80))
                .foregroundColor(.accentColor)
                .padding(.bottom, 20)
            
            // Title
            Text("security.auth.title".localized(defaultValue: "Secure Access"))
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            // Subtitle
            Text(String(format: "security.auth.subtitle".localized(defaultValue: "Use %@ to access your financial data"), biometricManager.biometricType.displayName))
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            // Authenticate Button
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
                    
                    Text("security.auth.button".localized(defaultValue: "Authenticate"))
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
            
            // Fallback Options
            VStack(spacing: 15) {
                Text("security.auth.fallback".localized(defaultValue: "Having trouble?"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Button("security.auth.passcode".localized(defaultValue: "Use Passcode")) {
                    // Fallback to passcode authentication
                    authenticateWithPasscode()
                }
                .font(.subheadline)
                .foregroundColor(.accentColor)
            }
            .padding(.bottom, 30)
        }
        .padding()
        .background(Color(.systemBackground))
        .alert("security.auth.error.title".localized(defaultValue: "Authentication Error"), isPresented: $showError) {
            Button("toolbar.ok".localized(defaultValue: "OK")) {
                showError = false
            }
        } message: {
            Text(biometricManager.errorMessage ?? "security.auth.error.message".localized(defaultValue: "Authentication failed. Please try again."))
        }
    }
    
    private func authenticateUser() {
        isAuthenticating = true
        
        Task {
            let success = await biometricManager.authenticateUser()
            
            await MainActor.run {
                isAuthenticating = false
                
                if success {
                    onAuthenticationSuccess()
                } else {
                    showError = true
                }
            }
        }
    }
    
    private func authenticateWithPasscode() {
        isAuthenticating = true
        
        Task {
            let success = await biometricManager.authenticateUser(reason: "Use your passcode to access your financial data")
            
            await MainActor.run {
                isAuthenticating = false
                
                if success {
                    onAuthenticationSuccess()
                } else {
                    showError = true
                }
            }
        }
    }
}

#Preview {
    BiometricAuthView {
        print("Authentication successful")
    }
}
