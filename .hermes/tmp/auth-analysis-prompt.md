# Auth System Analysis — BudgetMeter iOS

## Goal
Create a detailed report at `docs/auth_system_analysis.md` comparing the CURRENT auth implementation against a STANDARD mobile auth system. DO NOT modify any source code.

## What a standard auth system looks like

A normal mobile app with auth works like this:

1. **App launch** → Check for existing session
   - Is there a stored token/session? (Keychain, UserDefaults, etc.)
   - If YES → Validate with backend → Auto-login → Go to main app
   - If NO → Go to Welcome/Login screen

2. **Welcome screen** (first launch / logged out)
   - "Sign in with Apple" button (primary)
   - "Create Account" button (email/password)
   - "Sign In" button (existing users)
   - Optionally: "Skip for now" (local-only mode)

3. **Sign In screen** (email/password)
   - Email field
   - Password field
   - "Forgot Password?" link
   - "Sign In" button
   - "Don't have an account? Register" link

4. **Register screen** (email/password)
   - Email field
   - Password field
   - Confirm password field
   - "Create Account" button
   - "Already have an account? Sign In" link
   - Email verification flow

5. **Forgot Password screen**
   - Email field
   - "Send reset link" button
   - Reset email sent confirmation

6. **Sign in with Apple**
   - Uses `ASAuthorizationAppleIDProvider`
   - On first sign-in: creates account
   - On subsequent: validates existing session
   - Returns user ID, email, name

7. **Session management**
   - Token stored securely (Keychain)
   - Auto-refresh when expired
   - Sign out clears token → returns to Welcome screen

8. **Post-auth flow**
   - If new user → Onboarding → Main app
   - If returning user → Main app
   - Premium users → Backup/restore available

## What to audit

Read ALL auth-related files:

1. **CoreKit/Sources/Auth/AuthService.swift**
   - Does it have session restore?
   - Does it handle sign-in/sign-out?
   - Does it validate existing sessions?
   - Does it store credentials securely?

2. **CoreKit/Sources/Auth/SupabaseConfig.swift**
   - Is Supabase configured?

3. **Features/SettingsFeature/View/AccountBackupSettingsView.swift**
   - What auth UI exists currently?
   - Is it only in Settings or at app launch?

4. **budgetmeter_iosApp.swift**
   - Does the app check for existing session at launch?
   - What's the startup flow?

5. **ContentView.swift**
   - Does it handle auth state? (logged in vs logged out)
   - Does it show different views based on auth state?

6. **CoreKit/Sources/Services/BackupService.swift**
   - Does it integrate with auth?

7. **Search for:**
   - Any LoginView, RegisterView, WelcomeView, AuthView
   - Any session checking logic
   - Any Keychain storage
   - Any Apple Sign In revocation handling
   - Any email/password auth flows
   - Any forgot password flows

## Output
Write to `docs/auth_system_analysis.md` with:

1. **Current auth architecture** — what exists, what doesn't
2. **Gap analysis** — what a standard app has vs what BudgetMeter has
3. **Auth flow diagram** (text-based)
4. **What needs to be built** — prioritized list
5. **Recommendation** — which auth flows to add and in what order
