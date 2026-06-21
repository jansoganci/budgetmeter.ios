# Auth System Analysis — BudgetMeter iOS

**Date:** 2026-06-18  
**Scope:** Read-only audit of current auth implementation vs. a standard mobile auth system  
**Code reviewed:** `CoreKit/Sources/Auth/`, `AccountBackupSettingsView.swift`, `budgetmeter_iosApp.swift`, `ContentView.swift`, `BackupService.swift`, related Supabase config and edge functions

---

## Executive Summary

BudgetMeter implements **optional, settings-gated cloud identity** — not a traditional app-wide auth gate. The app is **local-first**: users can use all core features without signing in. Sign-in exists primarily to support **Premium cloud backup/restore** via Supabase.

Compared to a standard mobile auth system, BudgetMeter has a **narrow but functional** Apple Sign In + Supabase session layer. It lacks Welcome/Login/Register screens, email/password flows, forgot-password, launch-time auth routing, post-auth onboarding, and Apple credential revocation handling.

This is **intentionally aligned** with the product model (free local use, premium cloud backup) but **misaligned** with a conventional “auth-first” mobile app UX.

---

## 1. Current Auth Architecture

### 1.1 Components

| Component | Path | Role |
|-----------|------|------|
| `AuthService` | `CoreKit/Sources/Auth/AuthService.swift` | Singleton `@MainActor` service: Apple Sign In → Supabase `signInWithIdToken`, session restore, sign-out, account deletion |
| `AuthSessionStore` | `CoreKit/Sources/Auth/AuthSessionStore.swift` | Stores **non-secret** metadata (`userID`, `email`, `lastSignedInAt`) in **UserDefaults** |
| `SupabaseConfig` | `CoreKit/Sources/Auth/SupabaseConfig.swift` | Hardcoded project URL, anon key, `isConfigured` check, edge function URL builder |
| `SupabaseClientProvider` | `CoreKit/Sources/Auth/SupabaseClientProvider.swift` | Factory for `SupabaseClient` (supabase-swift 2.47.2) |
| `AppleSignInCoordinator` | `CoreKit/Sources/Auth/AppleSignInCoordinator.swift` | Programmatic `ASAuthorizationAppleIDProvider` wrapper — **not used by any UI** |
| `AccountBackupSettingsView` | `Features/SettingsFeature/View/AccountBackupSettingsView.swift` | **Only auth UI** — Sign in with Apple, sign out, delete account, backup/restore |
| `BackupService` | `CoreKit/Sources/Backup/BackupService.swift` | Requires authenticated `userID` + Premium for cloud backup/restore |
| `FirstSignInStateMachine` | `CoreKit/Sources/Backup/FirstSignInStateMachine.swift` | Classifies local vs. cloud data overlap on first sign-in (logic only; minimal UI wiring) |
| `BiometricManager` / `BiometricAuthView` | `CoreKit/Sources/Security/`, `Features/SecurityFeature/` | **Device-local** Face ID / Touch ID gate — unrelated to cloud auth |
| `delete-account` Edge Function | `supabase/functions/delete-account/index.ts` | Deletes `user_backups` row + Supabase auth user |
| DB schema | `docs/supabase/phase9_user_backups.sql` | `user_backups` table with RLS policies |

### 1.2 What Exists

#### Session restore
- **On `AuthService` init:** `restoreCachedSession()` reads `userID`/`email` from `AuthSessionStore` and sets `isAuthenticated = true` optimistically.
- **On app launch:** `budgetmeter_iosApp.swift` calls `AuthService.shared.restoreSessionIfNeeded()` in a `.task` on `ContentView`. This validates via `client.auth.session` (Supabase SDK) and either applies the session or clears local state.
- **Token storage:** Access/refresh tokens are managed by the **Supabase Swift SDK** (typically Keychain-backed). The app does not implement custom Keychain storage; `AuthSessionStore` only caches display metadata in UserDefaults.

#### Sign-in
- **Sign in with Apple only** — via `SignInWithAppleButton` in `AccountBackupSettingsView`.
- Flow: Apple credential → `AuthService.handleAppleCredential()` → `client.auth.signInWithIdToken(provider: .apple, idToken:)` → optional `full_name` metadata update → `applySession()`.
- Entitlement `com.apple.developer.applesignin` is present in `budgetmeter.ios.entitlements`.

#### Sign-out
- `AuthService.signOut()` calls Supabase `auth.signOut()` and clears `AuthSessionStore`.
- Does **not** wipe local Core Data.

#### Account deletion
- `AuthService.deleteAccount()` gets current access token, POSTs to `delete-account` edge function, signs out, clears session.
- Edge function deletes backup row then auth user via service role.

#### Auth UI placement
- Auth is **only** in Settings → Account & Backup (`SettingsView` → `NavigationLink` → `AccountBackupSettingsView`).
- **No auth UI at app launch.**

#### Integration with backup
- `BackupService` requires `userID` from auth + Premium (`.backupSync` capability).
- Backup upserts to Supabase `user_backups`; restore imports payload into Core Data.
- `FirstSignInStateMachine` evaluates local/cloud overlap after sign-in; UI shows a warning message for `.overlap` but does not implement a full chooser flow.

### 1.3 What Does NOT Exist

| Standard auth feature | BudgetMeter status |
|----------------------|-------------------|
| Welcome / Login screen at launch | ❌ Not present |
| Email/password sign-in | ❌ Not present |
| Email/password registration | ❌ Not present |
| Confirm password field | ❌ Not present |
| Forgot password / reset email | ❌ Not present |
| Email verification flow | ❌ Not present |
| `LoginView`, `RegisterView`, `WelcomeView`, `AuthView` | ❌ None found |
| Auth-gated root navigation (`ContentView` branching on auth) | ❌ `ContentView` always shows main tabs |
| Post-auth onboarding | ❌ Not present (Home has a “getting started” empty state, not auth-linked) |
| “Skip for now” local-only prompt at launch | ❌ Not needed — app is local-only by default |
| Apple Sign In credential revocation handling | ❌ No `getCredentialState(forUserID:)` checks |
| Apple Sign In nonce for Supabase | ❌ Not implemented |
| Custom Keychain token layer | ❌ Relies on Supabase SDK only |
| Explicit token refresh handling in app code | ❌ Delegated to Supabase SDK |
| `AppleSignInCoordinator` usage | ❌ Dead code — UI uses `SignInWithAppleButton` directly |

### 1.4 App Startup Flow (Actual)

```
App Launch
    │
    ├─ Unit tests? → EmptyView
    │
    ├─ Biometric enabled & not authenticated? → BiometricAuthView (device lock)
    │       └─ Success → (empty callback — ContentView not shown here; see note)
    │
    └─ Else → ContentView (main tabs, no auth check)
            └─ .task → AuthService.restoreSessionIfNeeded() (background, silent)
```

**Note:** When biometrics are required, `BiometricAuthView` is shown with an empty `onAuthenticationSuccess` closure — the main app content is not explicitly swapped in that branch in the current code. Biometric auth is a **device security** layer, separate from cloud auth.

### 1.5 Auth State Model

`AuthService` exposes:
- `isAuthenticated: Bool`
- `userID: String?`
- `email: String?`
- `isLoading: Bool`
- `errorMessage: String?`

**Consumers:** Only `AccountBackupSettingsView` and `budgetmeter_iosApp` (session restore). `ContentView` and feature ViewModels do **not** observe auth state.

---

## 2. Gap Analysis — Standard vs. BudgetMeter

### 2.1 App Launch & Session

| Standard behavior | BudgetMeter | Gap |
|-------------------|-------------|-----|
| Check stored session at launch | ✅ `restoreCachedSession()` + `restoreSessionIfNeeded()` | Minor: optimistic `isAuthenticated` before network validation |
| Route to Welcome if no session | ❌ Always shows main app | **By design** (local-first) — not a bug unless product wants auth-first |
| Route to main app if valid session | ✅ Silent restore; user already in main app | No visual “logged in” state outside Settings |
| Validate session with backend | ✅ Via `client.auth.session` | No explicit refresh/error UX at launch |

### 2.2 Sign-In Methods

| Method | Standard | BudgetMeter |
|--------|----------|-------------|
| Sign in with Apple | Primary | ✅ Only method; Settings-only |
| Email/password sign-in | Common | ❌ |
| Email/password register | Common | ❌ |
| Social (Google, etc.) | Optional | ❌ |

### 2.3 Auth Screens

| Screen | Standard | BudgetMeter |
|--------|----------|-------------|
| Welcome (first launch) | Sign in / Register / Skip | ❌ App opens to Home |
| Sign In (email/password) | Full form + forgot password link | ❌ |
| Register | Email, password, confirm, verification | ❌ |
| Forgot Password | Email + reset link confirmation | ❌ |
| Account (signed in) | Profile, sign out | ✅ Partial — email/ID display, sign out, delete |

### 2.4 Session Management

| Concern | Standard | BudgetMeter |
|---------|----------|-------------|
| Secure token storage | Keychain | Supabase SDK (internal); metadata in UserDefaults |
| Auto-refresh on expiry | Yes | Delegated to SDK; no app-level handling |
| Sign out → Welcome screen | Yes | Sign out → stays in Settings; main app unchanged |
| Revoked Apple ID handling | `credentialState` monitoring | ❌ Not implemented |

### 2.5 Post-Auth Flow

| Standard | BudgetMeter |
|----------|-------------|
| New user → Onboarding → Main app | ❌ No auth-linked onboarding |
| Returning user → Main app | ✅ (app was already open) |
| Premium → Backup available | ✅ Gated: Premium + signed in |

### 2.6 Security Gaps (Auth-Specific)

1. **No Apple Sign In nonce** — Supabase/Apple best practice for `signInWithIdToken` not followed.
2. **No credential revocation listener** — User can appear signed in locally while Apple credential is revoked until next `restoreSessionIfNeeded()` failure.
3. **Anon key in source** — Expected for mobile clients but should be paired with RLS (schema exists; production apply unverified in this audit).
4. **`AppleSignInCoordinator` unused** — Duplicate sign-in path; maintenance risk.

---

## 3. Auth Flow Diagrams

### 3.1 Current Flow (As Implemented)

```
┌─────────────────────────────────────────────────────────────────┐
│                         APP LAUNCH                               │
└────────────────────────────┬────────────────────────────────────┘
                             │
              ┌──────────────┴──────────────┐
              │ Biometric lock enabled?      │
              └──────────────┬──────────────┘
                    yes │         │ no
                        ▼         ▼
              ┌─────────────┐  ┌──────────────────────────────────┐
              │ Biometric   │  │ ContentView (5 tabs — always)     │
              │ AuthView      │  │   .task: restoreSessionIfNeeded() │
              └─────────────┘  └──────────────────────────────────┘
                                        │
                        (silent — no UI change on auth result)
                                        │
        User navigates: Settings → Account & Backup
                                        │
              ┌─────────────────────────┴─────────────────────────┐
              │                                                 │
        Not authenticated                               Authenticated
              │                                                 │
              ▼                                                 ▼
   ┌──────────────────────┐                    ┌────────────────────────────┐
   │ SignInWithAppleButton │                    │ Show email/ID, Sign Out     │
   │ (Settings only)       │                    │ Delete Account (danger)     │
   └──────────┬───────────┘                    │ Backup/Restore (if Premium) │
              │                                 └────────────────────────────┘
              ▼
   ┌──────────────────────┐
   │ Apple credential      │
   │ → Supabase idToken    │
   │ → applySession()      │
   └──────────┬───────────┘
              │
              ▼
   ┌──────────────────────┐
   │ FirstSignInStateMachine│
   │ (overlap warning only) │
   └──────────────────────┘
```

### 3.2 Standard Mobile Auth Flow (Reference)

```
APP LAUNCH
    │
    ├─ Valid session? ──yes──► Validate with backend ──ok──► MAIN APP
    │                              │
    │                              fail ──► WELCOME
    │
    └─ no session ──► WELCOME
                          │
            ┌─────────────┼─────────────┐
            ▼             ▼             ▼
      Sign in Apple   Register     Skip (local)
            │             │
            ▼             ▼
      SUPABASE AUTH   Email verify
            │             │
            └──────┬──────┘
                   ▼
            New user? ──yes──► ONBOARDING
                   │
                   no ──► MAIN APP
```

### 3.3 Sign-Out Flow (Current)

```
AccountBackupSettingsView → Sign Out
    │
    ▼
AuthService.signOut()
    │
    ├─ Supabase auth.signOut()
    └─ AuthSessionStore.clear()
    │
    ▼
User remains in Settings; main app fully usable (local data intact)
```

---

## 4. What Needs to Be Built (Prioritized)

Priorities assume **keeping local-first product model** unless product explicitly wants auth-first UX.

### P0 — Security & correctness (before production cloud backup)

| # | Item | Rationale |
|---|------|-----------|
| 1 | Apple Sign In **nonce** in `handleAppleCredential` / button request | Supabase security requirement; prevents replay |
| 2 | **Credential state check** on launch and before backup (`ASAuthorizationAppleIDProvider.getCredentialState`) | Detect revoked Apple IDs |
| 3 | Fix **optimistic auth** — don’t set `isAuthenticated = true` until `client.auth.session` succeeds, or show loading state | Avoids false “signed in” UI |
| 4 | Remove or wire **`AppleSignInCoordinator`** | Eliminate dead duplicate path |
| 5 | Verify Supabase schema + RLS applied in production | Backup security contract |

### P1 — First sign-in / backup UX (Phase 9 completion)

| # | Item | Rationale |
|---|------|-----------|
| 6 | **Overlap chooser UI** — backup local vs. restore cloud vs. keep separate | `FirstSignInStateMachine` recommends `requireOverlapChoice` but UI only shows a caption |
| 7 | **Cloud-only restore prompt** on first sign-in when local is empty | `offerCloudRestore` action not surfaced as guided flow |
| 8 | Post-sign-in **status feedback** at app level (optional toast/banner) | User may not visit Settings again |
| 9 | Offline / error handling for `restoreSessionIfNeeded` | Silent failure today |

### P2 — Standard auth screens (only if product pivots to auth-first or wants email users)

| # | Item | Rationale |
|---|------|-----------|
| 10 | Welcome screen (Sign in with Apple, optional Skip) | Standard first-launch UX; optional for local-first |
| 11 | Email/password **Sign In** screen | Users without Apple ID |
| 12 | Email/password **Register** + verification | Account creation without Apple |
| 13 | **Forgot Password** screen | Password recovery |
| 14 | Root **auth routing** in `budgetmeter_iosApp` / `ContentView` | Only needed if sign-in becomes mandatory |

### P3 — Polish & operations

| # | Item | Rationale |
|---|------|-----------|
| 15 | Auth-linked **onboarding** for new cloud users | Standard post-register flow |
| 16 | Centralized **auth state** in app root (`@EnvironmentObject AuthService`) | If more features need auth awareness |
| 17 | Session expiry UX (re-prompt Sign in with Apple) | Better than silent backup failure |
| 18 | Privacy catalog alignment (iCloud → Supabase copy) | Legal/consistency (noted in Phase 9 audit) |

---

## 5. Recommendation

### Product stance: keep optional auth (recommended)

BudgetMeter’s **local-first, premium-cloud-backup** model does **not** require a full standard auth shell at launch. Forcing Welcome/Login before Home would conflict with the stated product decisions in `docs/implementation/auth_supabase_sync_plan.md` (“free users can use the app locally”).

**Recommended order of work:**

1. **Harden existing Apple + Supabase path (P0)**  
   Nonce, credential revocation checks, session restore correctness, remove dead coordinator. This is required regardless of UX direction.

2. **Complete backup-first-sign-in UX (P1)**  
   Wire `FirstSignInStateMachine` actions into real UI (overlap modal, restore prompt). This is the highest-value user-facing gap for current architecture.

3. **Do not build email/password unless product requires it (defer P2)**  
   Apple Sign In satisfies App Store guidelines for apps that offer third-party sign-in. Email/password adds surface area (verification, reset, breach handling) without clear product need for a finance app that already works offline.

4. **Optional: lightweight Welcome (P2, trimmed)**  
   If first-launch education is desired, a single screen explaining “Use locally free” + “Sign in for cloud backup (Premium)” with **Skip** is sufficient — not a full auth gate.

5. **Never conflate biometric and cloud auth**  
   `BiometricAuthView` secures device access; `AuthService` secures cloud identity. Keep these separate in documentation and UX.

### When to add standard auth screens

Add Welcome + Sign In + Register + Forgot Password **only if**:
- Cloud sync becomes core (not premium-only), or
- Cross-platform (web/Android) accounts are planned with email login, or
- App Store / regulatory requirements demand non-Apple account creation.

Until then, invest in **Settings-embedded Apple Sign In + backup flows** already started in `AccountBackupSettingsView`.

---

## Appendix: File Inventory

### Auth module (`CoreKit/Sources/Auth/`)
- `AuthService.swift` — session, Apple sign-in, sign-out, delete
- `AuthSessionStore.swift` — UserDefaults metadata
- `SupabaseConfig.swift` — project credentials
- `SupabaseClientProvider.swift` — client factory
- `AppleSignInCoordinator.swift` — unused programmatic Apple Sign In

### UI touchpoints
- `Features/SettingsFeature/View/AccountBackupSettingsView.swift` — sole cloud auth UI
- `Features/SettingsFeature/View/SettingsView.swift` — navigation link only
- `budgetmeter_iosApp.swift` — silent `restoreSessionIfNeeded()`
- `ContentView.swift` — no auth branching

### Tests
- `budgetmeter.iosTests/AccountDeletionClientTests.swift`
- `budgetmeter.iosTests/FirstSignInStateMachineTests.swift`
- No dedicated `AuthService` integration tests found

### Search results (negative)
- No `LoginView`, `RegisterView`, `WelcomeView`, `AuthView`
- No `Keychain` usage in auth code (only UserDefaults + Supabase SDK)
- No `forgotPassword`, `signUp`, `signInWithPassword`, `resetPassword`
- No `credentialState` / revocation handling
- `AppleSignInCoordinator` referenced only in its own file

---

*This document is a read-only audit. No source code was modified.*
