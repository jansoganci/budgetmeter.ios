# Phase 9 — Supabase Auth / Database Migration Audit Prompt

## Goal
Create a comprehensive audit document at `docs/implementation/phase9_supabase_auth_database_migration_audit.md` that analyzes the current Phase 9 implementation status. DO NOT modify any source code — this is a read-only audit.

## Background
Read first: `docs/implementation/implementation_planning_index.md` (Phase 9 section) and `docs/implementation/phase9_supabase_auth_database_migration_scope.md`

## What to audit

### 1. AuthService
Read `CoreKit/Sources/Auth/AuthService.swift`:
- How does Apple Sign In work? Is it using `ASAuthorizationAppleIDProvider` + Supabase `signInWithIdToken`?
- Is session restore implemented?
- Is sign-out implemented?
- Is account deletion implemented? Does it call `delete_own_account` RPC?
- Are all auth error messages user-friendly and localized?

### 2. BackupService
Read `CoreKit/Sources/Services/BackupService.swift`:
- How does backup work? Serialize CoreData → JSON → Supabase upsert?
- How does restore work? Supabase select → JSON → CoreData import?
- Is the restore importer idempotent? (restoring twice doesn't duplicate data)
- Is there a local snapshot before backup?
- Is the backup premium-gated via `BudgetMeterCapability.backupSync`?

### 3. Backup Serialization & Restore
Read the serializer/restore files:
- `BackupSerializer` — what entities are serialized? All 8 CoreData entities?
- `RestoreImporter` — how does it handle existing data conflicts?
- `LocalSnapshotService` — when are local snapshots taken?
- `FirstSignInStateMachine` — what states does it handle?

### 4. Settings UI
Read `Features/SettingsFeature/View/AccountBackupSettingsView.swift`:
- Sign-in/Sign-out UI
- Backup/Restore buttons and status display
- Delete account confirmation
- Are all strings localized? (check UI.xcstrings for account.*, backup.*, auth.* keys)

### 5. Supabase Configuration
Read:
- `CoreKit/Sources/Auth/SupabaseConfig.swift` — does it have the correct project URL and anon key?
- `docs/supabase/phase9_user_backups.sql` — does it exist? What schema/RLS does it define?
- Is `supabase-swift` properly linked in the Xcode project?

### 6. CloudKit Status
- Is `NSPersistentCloudKitContainer` still active?
- Are all CoreData entities still marked `usedWithCloudKit=YES`?
- Is there a migration/deprecation plan documented?

### 7. Premium Gating
- Is `.backupSync` properly gated in `BudgetMeterCapability` as `.premium`?
- Are backup/restore actions guarded with `hasAccess(to: .backupSync)`?

### 8. Privacy & Legal
- Is the privacy policy copy updated? (no longer says iCloud-only)
- Does account settings mention Supabase + legacy iCloud?
- Are Terms of Service references correct?

### 9. Build & Test Status
- Does `xcodebuild build -scheme budgetmeter.ios` succeed?
- What tests exist for Phase 9? (FirstSignInStateMachineTests, BackupSerializerTests)
- Are there gaps in test coverage? (AuthSessionTests, RestoreImporterTests, PremiumBackupGateTests)

### 10. Gap Analysis vs Scope
Compare against the scope doc:
- What was planned vs what's actually implemented?
- What's missing?
- Is the Apple Sign In entitlement configured in the project?
- Has the Supabase SQL been applied?
- Has Apple Sign In been configured in Supabase dashboard and Apple Developer?

## Output
Write everything to `docs/implementation/phase9_supabase_auth_database_migration_audit.md` as a structured audit report with:
- Executive summary
- Component-by-component audit table
- Gap analysis
- Risk assessment
- CloudKit migration risk
- Test coverage analysis
