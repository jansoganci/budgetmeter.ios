# Auth System Implementation Plan — BudgetMeter iOS

**Date:** 2026-06-18  
**Status:** Planning only — no source code changes in this document  
**Goal:** Transform BudgetMeter from optional Settings-gated sign-in to a **mandatory auth-first** app with Apple Sign In, email/password, email verification, and launch-time auth routing.

---

## Product Pivot Note

Existing product docs (`docs/archive/active/auth_plan.md`, `docs/implementation/auth_supabase_sync_plan.md`) describe **local-first, optional auth**. This plan implements the **new requirement**: sign-in is mandatory for all users; there is no local-only free mode. That change affects data seeding, onboarding, marketing copy, App Store description, and privacy disclosures. Steps below assume the new model is approved.

---

## 1. Overview — Existing Auth Infrastructure (Reusable)

### 1.1 What already exists and can be reused

| Component | Path | Reuse |
|-----------|------|-------|
| `AuthService` | `CoreKit/Sources/Auth/AuthService.swift` | Extend with email/password, verification state, hardened session restore |
| `AuthSessionStore` | `CoreKit/Sources/Auth/AuthSessionStore.swift` | Extend with `isEmailVerified`, `authProvider` metadata |
| `SupabaseConfig` | `CoreKit/Sources/Auth/SupabaseConfig.swift` | Reuse as-is; add redirect URL helper for email links |
| `SupabaseClientProvider` | `CoreKit/Sources/Auth/SupabaseClientProvider.swift` | Reuse; optionally configure `AuthClient` redirect URL |
| `AppleSignInCoordinator` | `CoreKit/Sources/Auth/AppleSignInCoordinator.swift` | Wire into Welcome screen (currently dead code) |
| `AccountBackupSettingsView` | `Features/SettingsFeature/View/AccountBackupSettingsView.swift` | Keep for backup/restore/delete; remove duplicate sign-in entry point |
| `delete-account` edge function | `supabase/functions/delete-account/index.ts` | Reuse unchanged |
| `user_backups` schema | `docs/supabase/phase9_user_backups.sql` | Reuse; RLS already scoped to `auth.uid()` |
| Localization (errors) | `Resources/UI.xcstrings` | Extend with `auth.welcome.*`, `auth.sign_in.*`, etc. |
| Supabase Swift SDK | v2.47.2 via SPM | `signIn`, `signUp`, `resetPasswordForEmail`, `resend`, `session` |

### 1.2 What exists but needs correction before auth-first launch

| Issue | Current behavior | Required change |
|-------|------------------|-----------------|
| Optimistic auth | `restoreCachedSession()` sets `isAuthenticated = true` before network validation | Introduce `AuthPhase` enum: `.unknown` → `.restoring` → `.signedOut` / `.signedIn` / `.emailVerificationRequired` |
| No email verification gate | `applySession()` treats any session as fully authenticated | Check `user.emailConfirmedAt` (or equivalent Supabase `User` field) before granting app access |
| Apple nonce missing | `signInWithIdToken` without nonce | Generate SHA-256 nonce; pass to Apple request and Supabase credentials |
| Apple credential revocation | Not checked | `getCredentialState(forUserID:)` on launch and foreground |
| Auth only in Settings | `SignInWithAppleButton` in `AccountBackupSettingsView` | Move to `WelcomeView`; Settings shows account status only |
| No launch gate | `ContentView` always shown | Root router branches on `AuthService` phase |
| Biometric before auth | `BiometricAuthView` can block before cloud auth | Reorder: cloud auth first, then device biometric lock |
| Data seeding before auth | `seedInitialDataIfNeeded()` in `budgetmeter_iosApp.init` | Defer seeding until first successful authenticated session (or bind seed to `userID`) |

### 1.3 Auth state model (target)

```swift
enum AuthPhase: Equatable {
    case unknown          // App just launched, session not yet validated
    case restoring        // Calling Supabase session API
    case signedOut        // No valid session → Welcome
    case emailVerificationRequired(email: String)  // Session exists but email unverified
    case signedIn         // Valid session + verified (or Apple, which is implicitly verified)
}

// AuthService published properties (additive)
@Published private(set) var phase: AuthPhase = .unknown
@Published private(set) var isEmailVerified: Bool = false
@Published private(set) var authProvider: AuthProvider?  // .apple | .email
```

**Access rule:** `canAccessApp = phase == .signedIn` (Apple users skip email verification pending; email users must have `emailConfirmedAt != nil`).

---

## 2. Target Architecture

```
App Launch
    │
    ├─ Unit tests → EmptyView
    │
    └─ RootAuthView (new)
            │
            ├─ phase == .unknown | .restoring → SplashView (loading)
            │
            ├─ phase == .signedOut → WelcomeView
            │       ├─ Sign in with Apple
            │       ├─ Sign In (email) → SignInView
            │       └─ Create Account → RegisterView
            │
            ├─ phase == .emailVerificationRequired → EmailVerificationPendingView
            │
            └─ phase == .signedIn
                    │
                    ├─ Biometric enabled? → BiometricAuthView → MainTabView
                    └─ Else → MainTabView (current ContentView tabs)
```

`MainTabView` can remain the existing `ContentView` body or be extracted to a renamed struct; the plan keeps tab code in `ContentView.swift` and wraps it from `RootAuthView`.

---

## 3. Supabase Dashboard Prerequisites (Step 0)

These are configuration tasks, not iOS code, but they block email flows.

| Task | Where | Notes |
|------|-------|-------|
| Enable Email provider | Supabase Dashboard → Authentication → Providers | Enable email sign-up and sign-in |
| Confirm email | Auth → Settings | Turn **on** “Confirm email” |
| Site URL / redirect URLs | Auth → URL Configuration | Add `budgetmeter://auth/callback` (and dev URL if needed) |
| Email templates | Auth → Email Templates | Customize confirm + reset templates with BudgetMeter branding |
| Rate limits | Auth → Rate Limits | Use defaults or tighten: sign-up, sign-in, password reset, email send |
| Apple provider | Auth → Providers → Apple | Already working; verify Services ID + secret rotation |
| Custom SMTP (optional) | Project Settings → Auth | Recommended for production deliverability |

**Anti-fake-user (server-side, Step 0):**

- Email confirmation **required** before session is considered valid (enforce in `AuthService`, not only UI).
- Supabase built-in rate limiting on auth endpoints.
- Optional later: Cloudflare Turnstile or Supabase captcha on sign-up (document as P2 if not in v1).

---

## 4. Implementation Order

### Step 1 — Harden `AuthService` session model

**Complexity:** M  
**Dependencies:** None (first code step)

**Files to modify:**
- `CoreKit/Sources/Auth/AuthService.swift`
- `CoreKit/Sources/Auth/AuthSessionStore.swift`

**Files to create:**
- `CoreKit/Sources/Auth/AuthPhase.swift` (or nest in AuthService file)
- `CoreKit/Sources/Auth/AuthProvider.swift`

**Implementation (pseudocode):**

```swift
// AuthSessionStore — add keys
var isEmailVerified: Bool?
var authProviderRaw: String?

// AuthService.init
phase = .unknown
// Do NOT set isAuthenticated from cache alone

func restoreSessionIfNeeded() async {
    phase = .restoring
    guard let client else { phase = .signedOut; return }
    do {
        let session = try await client.auth.session
        applySession(user: session.user, provider: inferredProvider(session.user))
    } catch {
        clearSessionState()
        phase = .signedOut
    }
}

func applySession(user: User, provider: AuthProvider) {
    let verified = user.emailConfirmedAt != nil || provider == .apple
    userID = user.id.uuidString
    email = user.email
    isEmailVerified = verified
    authProvider = provider
    isAuthenticated = verified
  phase = verified ? .signedIn : .emailVerificationRequired(email: user.email ?? "")
    sessionStore.save(...)
}

func clearSessionState() {
    isAuthenticated = false
    isEmailVerified = false
    authProvider = nil
    phase = .signedOut
    sessionStore.clear()
}
```

**Verification:**
- Unit test: cached UserDefaults without valid Supabase session → ends at `.signedOut`, not `.signedIn`.
- Unit test: mock user with `emailConfirmedAt == nil` → `.emailVerificationRequired`.
- Unit test: Apple provider user → `.signedIn` immediately.
- Manual: sign in via Settings, kill app, relaunch → correct phase after restore.

---

### Step 2 — Apple Sign In security hardening

**Complexity:** M  
**Dependencies:** Step 1

**Files to modify:**
- `CoreKit/Sources/Auth/AuthService.swift`
- `CoreKit/Sources/Auth/AppleSignInCoordinator.swift`

**Files to create:**
- `CoreKit/Sources/Auth/AppleSignInNonce.swift` — `randomNonceString()`, `sha256(_:)`

**Implementation (pseudocode):**

```swift
// AppleSignInCoordinator.signIn()
let nonce = randomNonceString()
let hashed = sha256(nonce)
request.nonce = hashed

// AuthService.handleAppleCredential
let session = try await client.auth.signInWithIdToken(
    credentials: OpenIDConnectCredentials(
        provider: .apple,
        idToken: idToken,
        nonce: nonce  // raw nonce, not hash
    )
)

// On launch / willEnterForeground
if authProvider == .apple, let appleUserID = sessionStore.appleUserID {
    let state = await provider.getCredentialState(forUserID: appleUserID)
    if state == .revoked || state == .notFound {
        try? await signOut()
    }
}
```

Store `appleUserID` from `credential.user` in `AuthSessionStore` on successful Apple sign-in.

**Verification:**
- Sign in with Apple → Supabase session created (no “invalid nonce” error).
- Revoke app in Apple ID settings → next foreground → signed out, Welcome shown.
- Unit test nonce generation (length, uniqueness).

---

### Step 3 — Email/password auth methods in `AuthService`

**Complexity:** M  
**Dependencies:** Step 1, Supabase dashboard Step 0

**Files to modify:**
- `CoreKit/Sources/Auth/AuthService.swift`

**Implementation (pseudocode):**

```swift
enum AuthServiceError {
    // add: invalidEmail, weakPassword, emailNotVerified,
    //      emailAlreadyRegistered, invalidCredentials, rateLimited, passwordResetSent
}

func signUp(email: String, password: String) async throws {
    guard let client else { throw .notConfigured }
    isLoading = true; defer { isLoading = false }
    let response = try await client.auth.signUp(email: email, password: password)
    if let user = response.user {
        applySession(user: user, provider: .email)
        // phase will be .emailVerificationRequired if confirm email enabled
    }
}

func signIn(email: String, password: String) async throws {
    let session = try await client.auth.signIn(email: email, password: password)
    applySession(user: session.user, provider: .email)
}

func resendVerificationEmail() async throws {
    try await client.auth.resend(email: email, type: .signup)
}

func resetPassword(email: String) async throws {
    try await client.auth.resetPasswordForEmail(
        email,
        redirectTo: SupabaseConfig.passwordResetRedirectURL
    )
}

func updatePassword(_ newPassword: String) async throws {
    try await client.auth.update(user: UserAttributes(password: newPassword))
}
```

Map Supabase error codes to localized `AuthServiceError` messages.

**Verification:**
- Register new email → user created, verification email received, phase = `.emailVerificationRequired`.
- Sign in unverified → blocked at app level (stay on verification screen).
- Sign in verified → `.signedIn`.
- Reset password email received; deep link opens app (Step 8).
- Unit tests with mocked `AuthClient` if extractable; otherwise integration tests against Supabase staging.

---

### Step 4 — Create `AuthFeature` module (UI)

**Complexity:** L  
**Dependencies:** Steps 1–3

**Files to create:**

```
Features/AuthFeature/
├── ViewModel/
│   └── AuthFlowViewModel.swift      # Form validation, calls AuthService
└── View/
    ├── RootAuthView.swift           # Switches on AuthService.phase
    ├── SplashView.swift             # Logo + ProgressView while restoring
    ├── WelcomeView.swift            # Branding, Apple button, email CTAs
    ├── SignInView.swift             # Email + password, forgot link, back
    ├── RegisterView.swift           # Email + password + confirm password
    ├── ForgotPasswordView.swift     # Email field, send reset link
    ├── EmailVerificationPendingView.swift  # Resend, check status, sign out
    └── Components/
        ├── AuthTextField.swift      # Reusable styled field
        ├── AuthPrimaryButton.swift
        └── PasswordStrengthHint.swift  # Min 8 chars, etc.
```

**Also modify:**
- `budgetmeter.ios.xcodeproj/project.pbxproj` — add new files to target

**WelcomeView (pseudocode):**

```swift
VStack {
    Logo + tagline
    SignInWithAppleButton → handleAppleSignIn (reuse AccountBackupSettingsView logic)
    Button("Sign in with Email") → navigation to SignInView
    Button("Create Account") → navigation to RegisterView
}
// NO "Skip" or "Continue without account" button
```

**RegisterView validation:**
- Email format check (client-side)
- Password ≥ 8 characters (match Supabase policy)
- `password == confirmPassword`
- Disable submit while `authService.isLoading`

**SignInView:**
- Email, password, SecureField
- NavigationLink to ForgotPasswordView
- Link to RegisterView

**EmailVerificationPendingView:**
- Show email address
- “Resend verification email” → `authService.resendVerificationEmail()`
- “I’ve verified” → `await authService.restoreSessionIfNeeded()` (refresh user)
- Sign out

**Verification:**
- UI tests or snapshot tests for each screen (light/dark).
- Manual full flow: Welcome → Register → verification pending → verify email → main app.
- Manual: Welcome → Apple → main app (no verification screen).
- VoiceOver labels on all buttons and fields.

---

### Step 5 — Root auth gate in app entry

**Complexity:** M  
**Dependencies:** Step 4

**Files to modify:**
- `budgetmeter_iosApp.swift`
- `ContentView.swift` (minimal — may only add comment; routing is above it)

**Files to create:**
- `Features/AuthFeature/View/RootAuthView.swift` (if not created in Step 4)

**Implementation (pseudocode):**

```swift
// budgetmeter_iosApp.swift body
WindowGroup {
    Group {
        if isRunningUnitTests { EmptyView() }
        else { RootAuthView() }
    }
    .environmentObject(AuthService.shared)
    ...
}

// RootAuthView.swift
@EnvironmentObject var authService: AuthService
@EnvironmentObject var biometricManager: BiometricManager

var body: some View {
    switch authService.phase {
    case .unknown, .restoring:
        SplashView()
    case .signedOut:
        WelcomeView()
    case .emailVerificationRequired:
        EmailVerificationPendingView()
    case .signedIn:
        if biometricManager.shouldRequireAuthentication() {
            BiometricAuthView { /* authenticated */ }
        } else {
            ContentView()
                .environment(\.managedObjectContext, ...)
        }
    }
}
.task {
    await authService.restoreSessionIfNeeded()
}
```

Remove the duplicate `.task { restoreSessionIfNeeded() }` from the old `ContentView` attachment point.

**Verification:**
- Fresh install → Splash → Welcome (never see tabs).
- Valid session → Splash → Main tabs.
- Sign out from Settings → return to Welcome.
- Biometric lock only appears after cloud auth succeeds.

---

### Step 6 — Defer data seeding until authenticated

**Complexity:** M  
**Dependencies:** Step 5

**Files to modify:**
- `budgetmeter_iosApp.swift` — remove or guard `seedInitialDataIfNeeded()` from `init`
- `CoreKit/Sources/Persistence/DataSeedingService.swift` (or equivalent) — accept `userID` or run once per authenticated user
- `AuthService.swift` — call seeding hook in `applySession` when `phase == .signedIn` and `!sessionStore.hasSeededForUser(userID)`

**Implementation (pseudocode):**

```swift
// After first .signedIn transition
if !sessionStore.hasSeeded(for: userID) {
    DataSeedingService().seedInitialDataIfNeeded()
    sessionStore.markSeeded(for: userID)
}
```

**Rationale:** Mandatory auth means every user has an identity before data exists. Prevents orphan local data with no account.

**Verification:**
- New account → default categories appear after sign-in.
- Same account on second device → seeding skipped if already seeded locally for that user.
- Existing installs upgrading: document migration in Step 12.

---

### Step 7 — Localization

**Complexity:** M  
**Dependencies:** Step 4 (strings finalized)

**Files to modify:**
- `Resources/UI.xcstrings` (primary)
- Optionally `Resources/Localizable.xcstrings` for shared strings

**Keys to add (minimum set):**

| Key | English default |
|-----|-----------------|
| `auth.welcome.title` | Welcome to BudgetMeter |
| `auth.welcome.subtitle` | Sign in to track your finances securely |
| `auth.welcome.sign_in_email` | Sign in with Email |
| `auth.welcome.create_account` | Create Account |
| `auth.sign_in.title` | Sign In |
| `auth.sign_in.forgot_password` | Forgot password? |
| `auth.register.title` | Create Account |
| `auth.register.confirm_password` | Confirm Password |
| `auth.register.password_mismatch` | Passwords do not match |
| `auth.forgot.title` | Reset Password |
| `auth.forgot.sent` | Check your email for a reset link |
| `auth.verify.title` | Verify your email |
| `auth.verify.message` | We sent a link to %@ |
| `auth.verify.resend` | Resend email |
| `auth.verify.check_again` | I've verified my email |
| `auth.error.invalid_credentials` | Invalid email or password |
| `auth.error.email_not_verified` | Please verify your email first |
| `auth.error.rate_limited` | Too many attempts. Try again later. |
| `auth.error.weak_password` | Password must be at least 8 characters |

Provide translations for all 10 supported languages per project convention.

**Verification:**
- Build with Turkish/German locale → all auth screens translated.
- No hardcoded English in AuthFeature views (grep audit).

---

### Step 8 — Deep links for email confirmation and password reset

**Complexity:** M  
**Dependencies:** Steps 3, 5, Supabase URL config

**Files to modify:**
- `budgetmeter_iosApp.swift` — extend `handleDeepLink`
- `CoreKit/Sources/Auth/SupabaseConfig.swift` — `static let authCallbackURL`, `passwordResetRedirectURL`
- `Info.plist` — URL scheme `budgetmeter` (verify existing)

**Files to create:**
- `CoreKit/Sources/Auth/AuthDeepLinkHandler.swift`

**Implementation (pseudocode):**

```swift
// URL examples from Supabase:
// budgetmeter://auth/callback#access_token=...&type=signup
// budgetmeter://auth/callback?type=recovery&...

func handleAuthURL(_ url: URL) async {
    guard url.host == "auth" else { return }
    // Use client.auth.session(from: url) or SDK equivalent
    await authService.handleDeepLink(url)
    await authService.restoreSessionIfNeeded()
}
```

For password reset, after token exchange show a `ResetPasswordView` (can be Step 4 add-on) to enter new password via `updatePassword`.

**Verification:**
- Tap confirm link in Mail app → app opens → phase becomes `.signedIn`.
- Tap reset link → app opens → set new password → sign in works.
- Invalid/expired link → user-friendly error on Welcome.

---

### Step 9 — Refactor Settings account UI

**Complexity:** S  
**Dependencies:** Step 5

**Files to modify:**
- `Features/SettingsFeature/View/AccountBackupSettingsView.swift`
- `Resources/UI.xcstrings` — update `account.footer` copy

**Implementation:**
- Remove `SignInWithAppleButton` from Settings (auth only via Welcome).
- When not authenticated, show empty state: “You're signed out” with button **Go to Sign In** that resets session (user is already on Welcome from root gate — this state should be rare).
- Keep sign out, delete account, backup sections for authenticated users.
- Update footer: remove “Sign in is free. Cloud backup requires Premium.” → “Cloud backup requires Premium.”

**Verification:**
- Signed-in user sees email, sign out, backup, delete — no Apple button.
- Sign out → root gate shows Welcome immediately.

---

### Step 10 — `AuthFlowViewModel` and form validation

**Complexity:** S  
**Dependencies:** Step 4

**Files to create:**
- `Features/AuthFeature/ViewModel/AuthFlowViewModel.swift`

**Implementation (pseudocode):**

```swift
@MainActor
final class AuthFlowViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var formError: String?

    var canSubmitSignIn: Bool { email.isValidEmail && password.count >= 8 }
    var canSubmitRegister: Bool { canSubmitSignIn && password == confirmPassword }

    func signIn() async { ... authService.signIn(...) }
    func register() async { ... authService.signUp(...) }
    func sendPasswordReset() async { ... }
}
```

**Verification:**
- Register with mismatched passwords → inline error, no API call.
- Empty fields → submit disabled.

---

### Step 11 — Tests

**Complexity:** M  
**Dependencies:** Steps 1–3, 10

**Files to create:**
- `budgetmeter.iosTests/AuthServiceTests.swift`
- `budgetmeter.iosTests/AuthFlowViewModelTests.swift`
- `budgetmeter.iosTests/AuthPhaseRoutingTests.swift`

**Files to modify:**
- `budgetmeter.iosTests/AccountDeletionClientTests.swift` — ensure still passes

**Test cases:**

| Test | Type |
|------|------|
| `applySession` sets correct phase for unverified email | Unit |
| `applySession` sets `.signedIn` for Apple | Unit |
| `restoreSessionIfNeeded` failure clears cache | Unit |
| Email validation / password match | Unit |
| Register → verification required phase | Integration (staging) |
| Delete account still works when auth required | Integration |

**Verification:**
- `xcodebuild test` green on CI simulator.

---

### Step 12 — Existing user migration (upgrade path)

**Complexity:** M  
**Dependencies:** Step 5

**Problem:** Current production users have local Core Data and no Supabase account. Mandatory auth blocks them until they sign in.

**Files to create:**
- `CoreKit/Sources/Auth/LegacyLocalUserMigration.swift`

**Files to modify:**
- `RootAuthView` or `WelcomeView` — one-time migration banner
- `AuthSessionStore` — `legacyLocalDataDetected` flag

**Implementation (pseudocode):**

```swift
// On first launch after upgrade
if PersistenceService.shared.hasLocalFinancialData && !authService.isAuthenticated {
    showMigrationMessage = true
    // Copy: "Create an account to continue. Your existing data will stay on this device."
}

// On first successful sign-in
FirstSignInStateMachine.evaluate(...)  // existing overlap logic
// Surface overlap chooser if local + cloud conflict (tie to P1 from auth_system_analysis)
```

**Verification:**
- Simulator with seeded local data, no auth → Welcome with migration message → sign in → data still present.
- Overlap scenario → user chooses backup or restore (future enhancement if chooser not built).

---

### Step 13 — Anti-fake-user hardening (client + server)

**Complexity:** M  
**Dependencies:** Steps 0, 3, 4

**Server (Supabase):**
- Confirm email required (Step 0)
- Rate limits on sign-up, sign-in, password reset
- Optional: disable disposable email domains via Supabase hook or edge function

**Client:**
- No app access until `phase == .signedIn`
- Client-side email format validation
- Password minimum length enforcement
- Do not expose detailed errors (“user not found” vs “wrong password” → generic message)

**Files to modify:**
- `AuthService.swift` — error mapping
- `RegisterView.swift` — password rules UI

**Optional (P2):**
- `supabase/functions/validate-signup/index.ts` — server-side email domain blocklist
- Captcha on registration

**Verification:**
- Unverified user cannot reach tabs (attempt deep link → still blocked).
- Rapid repeated sign-in attempts → rate limit message.
- Sign up with `test@mailinator.com` → blocked if domain policy enabled.

---

### Step 14 — Documentation and product copy updates

**Complexity:** S  
**Dependencies:** All above

**Files to modify:**
- `CLAUDE.md` — auth-first architecture
- `docs/auth_system_analysis.md` — addendum pointing to this plan
- App Store privacy questionnaire notes
- Settings → privacy section if it mentions “optional sign-in”

**Verification:**
- Internal docs consistent with mandatory auth behavior.

---

## 5. Step Summary Table

| Step | Title | Effort | Depends on |
|------|-------|--------|------------|
| 0 | Supabase dashboard config | S | — |
| 1 | Harden AuthService session model | M | 0 |
| 2 | Apple nonce + credential revocation | M | 1 |
| 3 | Email/password API in AuthService | M | 0, 1 |
| 4 | AuthFeature UI screens | L | 1–3 |
| 5 | Root auth gate | M | 4 |
| 6 | Defer data seeding to authenticated user | M | 5 |
| 7 | Localization (10 languages) | M | 4 |
| 8 | Email deep links (verify + reset) | M | 3, 5 |
| 9 | Refactor Settings account UI | S | 5 |
| 10 | AuthFlowViewModel validation | S | 4 |
| 11 | Unit + integration tests | M | 1–3, 10 |
| 12 | Legacy local user migration | M | 5 |
| 13 | Anti-fake-user hardening | M | 0, 3, 4 |
| 14 | Docs + product copy | S | All |

---

## 6. Total Estimated Effort

| Category | Steps | Person-days (estimate) |
|----------|-------|------------------------|
| Supabase config | 0 | 0.5 |
| Core auth service | 1–3, 13 | 3–4 |
| UI feature module | 4, 5, 9, 10 | 4–5 |
| Data + migration | 6, 12 | 2 |
| Deep links | 8 | 1–1.5 |
| Localization | 7 | 1.5–2 |
| Tests | 11 | 2 |
| Docs | 14 | 0.5 |
| **Total** | | **~15–18 person-days** |

Assumes one senior iOS developer familiar with the codebase. Add 3–5 days for QA pass, TestFlight, and App Store review iteration.

---

## 7. Risk Assessment

| Risk | Severity | Mitigation |
|------|----------|------------|
| **Product regression** — forcing auth may reduce installs/conversion vs local-first | High | Clear Welcome copy; keep Apple one-tap; measure funnel in analytics |
| **Existing users locked out** with local data | High | Step 12 migration UX; preserve data on sign-in; overlap chooser |
| **Email deliverability** — verification emails in spam | Medium | Custom SMTP; resend button; clear instructions |
| **Apple relay emails** — `privaterelay.appleid.com` still valid | Low | Treat as verified; show in account settings |
| **Biometric + auth ordering bugs** | Medium | Step 5 explicit ordering; test all combinations |
| **Supabase rate limits block legitimate users** | Low | Tune limits; friendly error messages |
| **Deep link fragility** — iOS kills app during mail handoff | Medium | `session(from:)` + manual “I've verified” refresh |
| **Scope creep** — social login, MFA, magic links | Medium | Explicitly out of scope for v1 |
| **Legal/privacy** — mandatory account for finance app | Medium | Update privacy policy; disclose Supabase data processor |
| **Offline use case lost** | High | Product decision accepted; document no offline-without-session mode |
| **Duplicate sign-in paths** | Low | Remove Settings sign-in in Step 9; use coordinator in Welcome only |
| **Test flakiness** on live Supabase | Medium | Staging project for integration tests; mock AuthClient in unit tests |

---

## 8. Out of Scope (v1)

- Google / social sign-in providers
- Magic link (passwordless email) sign-in
- MFA / TOTP
- “Skip for now” / guest mode
- Auth-linked onboarding wizard (beyond data seeding)
- Full overlap chooser UI (reuse caption-only warning unless Step 12 expanded)
- Moving Supabase anon key out of source (acceptable for mobile; RLS protects data)

---

## 9. Suggested Implementation Sprints

**Sprint 1 (foundation):** Steps 0–3 — service layer complete, testable without UI  
**Sprint 2 (UI + gate):** Steps 4–5, 7, 9–10 — users can sign in at launch  
**Sprint 3 (polish + ship):** Steps 6, 8, 11–14 — migration, deep links, QA  

---

## 10. Definition of Done

- [ ] App cannot reach main tabs without authenticated, verified session
- [ ] Apple Sign In works from Welcome screen
- [ ] Email register → verification email → confirm → access granted
- [ ] Email sign-in and forgot-password flows work
- [ ] Sign out returns to Welcome
- [ ] Session restores silently on relaunch
- [ ] Settings no longer primary sign-in entry point
- [ ] All auth strings localized (10 languages)
- [ ] Unit tests for phase routing and validation
- [ ] Supabase rate limits and email confirmation enabled
- [ ] Legacy local data migration path documented and tested

---

*This document is planning output only. No application source code was modified.*
