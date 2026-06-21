# Auth System Implementation Plan — BudgetMeter iOS

## Goal
Create a detailed step-by-step implementation plan at `docs/auth_implementation_plan.md`. Do NOT modify any source code.

## Context
BudgetMeter iOS is a local-first finance app that currently has:
- Apple Sign In + Supabase in Settings → Account & Backup (working)
- Session restore (silent background)
- AuthService, AuthSessionStore, SupabaseClientProvider already coded
- No Welcome/Login/Register screens
- No email/password auth flow
- No auth gate at app launch

## What needs to be built (standard auth system)

The user wants:
1. **Auth required** — must sign in to use the app. No local-only mode for free users.
2. **Apple Sign In** — primary method (already works)
3. **Email/password Sign In** — secondary method
4. **Email/password Registration** — sign up with email + password + confirm
5. **Forgot Password** — reset via email
6. **Email verification** — user must verify email before accessing app
7. **Welcome screen** — first thing user sees if not logged in
8. **Auth gate** — ContentView checks auth state, shows WelcomeView or MainTabView
9. **Anti-fake-user measures** — email verification, rate limiting

## Read these files first to understand existing auth infrastructure
- CoreKit/Sources/Auth/AuthService.swift
- CoreKit/Sources/Auth/AuthSessionStore.swift  
- CoreKit/Sources/Auth/SupabaseConfig.swift
- CoreKit/Sources/Auth/SupabaseClientProvider.swift
- CoreKit/Sources/Auth/AppleSignInCoordinator.swift
- Features/SettingsFeature/View/AccountBackupSettingsView.swift
- budgetmeter_iosApp.swift
- ContentView.swift

## For each step, specify:
1. What files to create or modify
2. What the implementation should do (pseudocode)
3. Dependencies (what must be done first)
4. Estimated complexity (S/M/L)
5. Verification (how to test)

## Output structure
Write to `docs/auth_implementation_plan.md` with:
- Overview of existing auth infrastructure (what can be reused)
- Implementation order (step by step, numbered)
- Each step: files, pseudocode, deps, effort, verification
- Total estimated effort
- Risk assessment
