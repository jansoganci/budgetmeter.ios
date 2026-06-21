# Auth Implementation — Steps 11-13: Integration

BudgetMeter iOS project at /Users/jans/Desktop/nexus/budgetmeter.ios.

## Step 11: Defer data seeding until after auth

In `budgetmeter_iosApp.swift`, the `init` currently calls `seedInitialDataIfNeeded()` and other setup. Move these to happen AFTER successful authentication.

Modify `budgetmeter_iosApp.swift`:
- Remove `seedInitialDataIfNeeded()`, `performMigrationIfNeeded()`, `scheduleBackgroundProcessing()` from init
- In `RootAuthView.swift`, when phase transitions to `.signedIn`, call these setup functions once

In `RootAuthView.swift`, add:
```swift
.onChange(of: authService.phase) { oldPhase, newPhase in
    if newPhase == .signedIn && oldPhase != .signedIn {
        // First time signing in this session — run setup
        DataSeedingService().seedInitialDataIfNeeded()
        CustomCategoryMigrationService().performMigrationIfNeeded()
        BackgroundProcessingService.shared.scheduleBackgroundProcessing()
    }
}
```

## Step 12: Localization

Add auth-related keys to `Resources/UI.xcstrings`:
- auth.welcome.title = "BudgetMeter"
- auth.welcome.subtitle = "Track your money pace"
- auth.welcome.sign_in_apple = "Sign in with Apple"
- auth.welcome.sign_in_email = "Sign in with Email"
- auth.welcome.create_account = "Create Account"
- auth.sign_in.title = "Sign In"
- auth.sign_in.email = "Email"
- auth.sign_in.password = "Password"
- auth.sign_in.button = "Sign In"
- auth.sign_in.forgot_password = "Forgot Password?"
- auth.register.title = "Create Account"
- auth.register.confirm_password = "Confirm Password"
- auth.register.button = "Create Account"
- auth.register.password_mismatch = "Passwords do not match"
- auth.forgot_password.title = "Reset Password"
- auth.forgot_password.send = "Send Reset Link"
- auth.forgot_password.sent = "If this email is registered, you'll receive a reset link."
- auth.splash.loading = "Loading..."

Then update all views to use `String(localized: "auth.KEY", defaultValue: "...", table: "UI")` instead of hardcoded strings.

## Step 13: Settings cleanup

In `Features/SettingsFeature/View/SettingsView.swift`:
- The Account section should now only show account STATUS (signed in as email@example.com), not the sign-in button
- Sign in with Apple button should be removed from AccountBackupSettingsView since it's now in WelcomeView
- AccountBackupSettingsView should keep: backup/restore UI, sign out button, delete account

## Verification
```sh
xcodebuild -project budgetmeter.ios.xcodeproj -scheme budgetmeter.ios -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' build
```
