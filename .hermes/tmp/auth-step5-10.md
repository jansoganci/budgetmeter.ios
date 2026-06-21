# Auth Implementation — Steps 5+10: WelcomeView + RootAuthView Gate

BudgetMeter iOS project at /Users/jans/Desktop/nexus/budgetmeter.ios.

## Context
AuthService now has AuthPhase (unknown/restoring/signedOut/signedIn). We need the auth gate UI.

## Step 5: WelcomeView

Create `Features/AuthFeature/View/WelcomeView.swift` with:

```swift
struct WelcomeView: View {
    @StateObject private var authService = AuthService.shared
    @State private var showingSignIn = false
    @State private var showingRegister = false
    
    var body: some View {
        VStack(spacing: Spacing.xl) {
            // App icon / branding
            Image(systemName: "chart.pie.fill")
                .font(.system(size: 64))
                .foregroundColor(.brandProgress)
            
            Text("BudgetMeter")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Track your money pace")
                .foregroundColor(.textSecondary)
            
            Spacer()
            
            // Sign in with Apple button
            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                await authService.handleAppleCredential(result)
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 50)
            .padding(.horizontal)
            
            // Sign in with Email
            Button("Sign in with Email") {
                showingSignIn = true
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.cardBackground)
            .cornerRadius(CornerRadius.button)
            .padding(.horizontal)
            
            // Create Account
            Button("Create Account") {
                showingRegister = true
            }
            .foregroundColor(.brandProgress)
            
            // Skip login (dev only? or remove entirely?)
            // Not adding skip for now - user wants mandatory auth
        }
        .padding(.vertical, Spacing.xxl)
        .sheet(isPresented: $showingSignIn) {
            SignInView()
        }
        .sheet(isPresented: $showingRegister) {
            RegisterView()
        }
    }
}
```

## Step 10: RootAuthView Gate

Create `Features/AuthFeature/View/RootAuthView.swift`:

```swift
struct RootAuthView: View {
    @StateObject private var authService = AuthService.shared
    
    var body: some View {
        switch authService.phase {
        case .unknown, .restoring:
            SplashView()  // Loading indicator
        case .signedOut:
            WelcomeView()
        case .signedIn:
            ContentView()  // Main app tabs
        }
    }
}

struct SplashView: View {
    var body: some View {
        VStack {
            ProgressView()
            Text("Loading...")
                .foregroundColor(.textSecondary)
        }
    }
}
```

Then modify `budgetmeter_iosApp.swift`:
- Replace `ContentView()` with `RootAuthView()`
- The app entry point should no longer seed data before auth
- Move seeding to after successful authentication

## Create the AuthFeature module folder structure
```
Features/AuthFeature/
  View/
    WelcomeView.swift
    RootAuthView.swift
    SplashView.swift
  ViewModel/
    (optional, can skip for now)
```

## Verification
Build with iPhone 16 simulator:
```sh
xcodebuild -project budgetmeter.ios.xcodeproj -scheme budgetmeter.ios -destination 'platform=iOS Simulator,name=iPhone 16,OS=26.5' build
```
If iPhone 16 not available, use any available iPhone simulator.
