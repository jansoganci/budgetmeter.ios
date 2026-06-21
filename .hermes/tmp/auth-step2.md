# Auth Implementation — Step 2: AuthService Hardening

BudgetMeter iOS project at /Users/jans/Desktop/nexus/budgetmeter.ios.

Read the full plan at docs/auth_implementation_plan.md for context.

## What to do

Modify `CoreKit/Sources/Auth/AuthService.swift` to support mandatory auth with proper session lifecycle.

### 1. Add AuthPhase enum (in AuthService.swift or new file)

```swift
enum AuthPhase: Equatable {
    case unknown          // App just launched, session not yet validated
    case restoring        // Calling Supabase session API
    case signedOut        // No valid session → Welcome
    case signedIn         // Valid session + verified
}
```

### 2. Add published properties to AuthService

```swift
@Published private(set) var phase: AuthPhase = .unknown
@Published private(set) var authProvider: AuthProvider?  // .apple | .email
@Published private(set) var currentUserID: String?
@Published private(set) var currentEmail: String?

enum AuthProvider {
    case apple
    case email
}
```

### 3. Rework init/restore flow

- Remove optimistic `restoreCachedSession()` that sets isAuthenticated before network check
- On init: set phase to `.unknown`, then call `restoreSessionIfNeeded()`
- `restoreSessionIfNeeded()`:
  - Set phase = `.restoring`
  - Call `client.auth.session` (Supabase SDK)
  - If session exists and valid → phase = `.signedIn`, store userID/email/provider
  - If session exists but expired → try refresh
  - If no session → phase = `.signedOut`
  - On network error → phase stays `.signedOut` (fail closed, not open)

### 4. Update Apple sign-in handler

- After successful Apple sign-in: set phase = `.signedIn`, provider = `.apple`
- Keep existing handleAppleCredential flow

### 5. Add email/password methods (stubs for now)

```swift
func signIn(email: String, password: String) async throws
func signUp(email: String, password: String) async throws
func resetPassword(email: String) async throws
func signOut() async
```

For signIn/signUp: call `client.auth.signIn` / `client.auth.signUp`, on success set phase = `.signedIn`
For signOut: call `client.auth.signOut()`, set phase = `.signedOut`, clear all state

### 6. Keep existing methods intact
- deleteAccount()
- handleAppleCredential()
- All backup-related methods

## Build with iPhone 16, iOS 26
```sh
xcodebuild -project budgetmeter.ios.xcodeproj -scheme budgetmeter.ios -destination 'platform=iOS Simulator,name=iPhone 16,OS=26.5' build
```
