Fix the privacy copy in BudgetMeter iOS. The project is at /Users/jans/Desktop/nexus/budgetmeter.ios.

## Context
Phase 9 added Supabase Auth/Backup support. But the privacy/cloud storage copy in Settings still describes iCloud-only storage — "No external servers or third-party databases" and similar iCloud-only claims. This is now WRONG because we use Supabase for premium backup.

## What to fix

1. Find the privacy/cloud storage copy in Settings views and .xcstrings files
2. Update to describe:
   - Free users: fully local, no cloud storage
   - Premium users: encrypted cloud backup via Supabase
   - Legacy iCloud (CloudKit) infrastructure still present for existing users, being migrated away from

3. Check these files:
   - Resources/Settings.xcstrings — look for privacy/cloud/iCloud keys
   - Resources/UI.xcstrings — look for backup/cloud/iCloud keys
   - Features/SettingsFeature/ — any view that shows privacy policy copy
   - Search for "iCloud", "cloud", "No external servers", "third-party" in all Swift and xcstrings files

4. The updated copy should be accurate but not overly technical. Something like:
   - "Your data is stored locally on your device. Premium users can optionally back up to Supabase, a secure cloud database."
   - Or reference the existing privacy policy for full details.

## Verification
```sh
xcodebuild -project budgetmeter.ios.xcodeproj -scheme budgetmeter.ios -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' build
```
Build must succeed.
