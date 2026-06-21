# P1 Task 2: Localize Auth/Backup/Account Strings

## Problem
The Phase 9 Auth/Backup/Account settings screens have hardcoded English strings.

## What to fix

1. Read and analyze these files:
   - Features/SettingsFeature/View/AccountBackupSettingsView.swift (or similar account settings view)
   - CoreKit/Sources/Auth/AuthService.swift (error messages)
   - CoreKit/Sources/Services/BackupService.swift (status/error messages)
   - Any other auth/backup related views

2. Find ALL user-facing hardcoded English strings and replace with `String(localized: "account.KEY" or "backup.KEY" or "auth.KEY", defaultValue: "English", table: "UI")`

3. Key strings to localize:
   - "Sign in with Apple" / "Sign Out" / "Sign Out ?" / "Delete Account"
   - Account section titles, descriptions
   - Backup status messages ("Last backup: never", "Backing up...", "Backup complete!")
   - Restore confirmation dialogs
   - Auth error messages
   - Privacy policy, terms of service references

4. Add all new keys to `Resources/UI.xcstrings`

## Verification
```sh
xcodebuild -project budgetmeter.ios.xcodeproj -scheme budgetmeter.ios -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' build
```
Build must succeed.
