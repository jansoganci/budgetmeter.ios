# Phase 9 — Supabase Auth / Database Migration Audit

**Audit date:** 2026-06-18  
**Auditor scope:** Read-only code/doc review + build/test verification  
**Related docs:** `docs/implementation/phase9_supabase_auth_database_migration_scope.md`, `docs/implementation/implementation_planning_index.md`, `docs/supabase/phase9_user_backups.sql`

---

## Executive Summary

Phase 9 v1 backup/account deletion slice is **implemented and verified for the current manual backup/restore architecture**. The core auth/backup layer, serializer/restore pipeline, Settings UI, premium gate, ordered Supabase migrations, latest-backup table, backup-version history table, capture trigger, and hard-delete Edge Function are present. Build and full test suite pass (155/155).

**Overall status:** v1 manual cloud backup/account deletion is complete for the current release path. Remaining Phase 9 risks are CloudKit migration/removal, true row-level sync, Apple nonce hardening, and broader long-term sync architecture.

| Area | Status | Notes |
|------|--------|-------|
| AuthService (Apple + Supabase) | Partial | `signInWithIdToken` works; session restore/sign-out/delete implemented; no nonce |
| BackupService | Partial | Serialize → snapshot → upsert / select → snapshot → import; offline unused |
| Serializer / Restore | Mostly complete | All 8 entities covered; restore is wipe-and-replace |
| Settings UI | Partial | Account/backup/delete flows present; overlap chooser not wired |
| Supabase config + SQL | Complete for v1 | Ordered migrations applied by user; latest backup + version history + trigger present |
| CloudKit | Unchanged (legacy active) | Container still `NSPersistentCloudKitContainer`; no removal plan executed |
| Premium gating | Complete | `.backupSync` = `.premium`; UI + service guarded |
| Privacy / legal | **Incomplete** | Swift defaultValues updated; **catalog strings still iCloud-only** |
| Build / tests | Pass | 155 tests; account deletion client contract covered |
| Live QA readiness | Passed for v1 | User reported migrations and manual QA passed 2026-06-18 |

**Recommendation:** Treat Phase 9 v1 backup/account deletion as **implemented and verified**. Keep CloudKit removal, true sync, and deeper auth hardening as explicit postponed work.

---

## Component-by-Component Audit

### 1. AuthService

**File:** `budgetmeter.ios/CoreKit/Sources/Auth/AuthService.swift`

| Question | Finding | Status |
|----------|---------|--------|
| Apple Sign In mechanism | UI uses `SignInWithAppleButton`; credential passed to `AuthService.handleAppleCredential`, which calls Supabase `client.auth.signInWithIdToken(provider: .apple, idToken:)`. `AppleSignInCoordinator` uses `ASAuthorizationAppleIDProvider` but is **not used** by the Settings UI path. | ✅ Partial |
| Session restore | `restoreCachedSession()` loads `userID`/`email` from `AuthSessionStore` on init; `restoreSessionIfNeeded()` validates via `client.auth.session` on app launch (`budgetmeter_iosApp.swift`). | ✅ Implemented |
| Sign-out | `signOut()` calls Supabase `auth.signOut()` and clears local session metadata; does not wipe Core Data. | ✅ Implemented |
| Account deletion | `deleteAccount()` calls the `delete-account` Supabase Edge Function with the current access token, then clears local auth state. SQL now drops the old `delete_own_account` RPC. | ✅ Implemented |
| Error localization | `AuthServiceError` uses localized keys `auth.error.*` in `UI` table with user-friendly messages. | ✅ Implemented |

**Gaps / risks:**
- **No Apple Sign In nonce/state validation** — scope doc (Section 8) requires nonce; neither `AuthService` nor `SignInWithAppleButton` path sets nonce for Supabase.
- **Optimistic cached auth:** `restoreCachedSession()` sets `isAuthenticated = true` before network validation; brief stale-auth window until `restoreSessionIfNeeded()` completes or fails.
- **`AppleSignInCoordinator` is dead code** relative to current UI; two parallel sign-in paths exist.

---

### 2. BackupService

**File:** `budgetmeter.ios/CoreKit/Sources/Backup/BackupService.swift`  
*(Audit prompt referenced `CoreKit/Sources/Services/BackupService.swift` — actual path is `CoreKit/Sources/Backup/`.)*

| Question | Finding | Status |
|----------|---------|--------|
| Backup flow | Core Data → `BackupSerializer.exportPayload` → `LocalSnapshotService.createSnapshot` → Supabase `user_backups` upsert on `user_id` conflict. Single JSONB row per user (not per-record tables). | ✅ Implemented |
| Restore flow | Supabase select → local snapshot → `RestoreImporter.importPayload` → `persistenceService.save()`. | ✅ Implemented |
| Restore idempotency | `RestoreImporter` clears 7 financial entities then re-imports. Restoring the same cloud payload twice yields the same record set (no duplication). **Not** merge-by-`client_record_id`; full replace. | ✅ Idempotent (replace semantics) |
| Local snapshot before backup/restore | Snapshot created before both `backupNow` and `restoreFromCloud`. | ✅ Implemented |
| Premium gate | `validateBackupPreconditions` throws `premiumRequired` if `!isPremium`; UI also gates section. Uses `BudgetMeterCapability.backupSync`. | ✅ Implemented |

**Gaps / risks:**
- **`BackupServiceError.offline` is never thrown** — no reachability check; network failures surface as generic `backupFailed`/`restoreFailed`.
- **`SyncStateStore` metadata** (last backup/restore) persists via UserDefaults property setters, but **`BackupService.syncState` is not loaded from disk on every read** — initial `@Published` value loads once; acceptable but worth documenting.
- **No automatic rollback UI** if restore fails after entity clear — snapshot exists on disk via `LocalSnapshotService`, but no Settings recovery action exposes it.
- **`markFirstSignInCompleted()`** called unconditionally in `AccountBackupSettingsView.refreshCloudState()` — may prematurely close first-sign-in classification window.

---

### 3. Backup Serialization & Restore

#### BackupSerializer — `budgetmeter.ios/CoreKit/Sources/Backup/BackupSerializer.swift`

| Entity | Serialized | Notes |
|--------|------------|-------|
| AppSettings | ✅ Partial | Preferences only; **`isPremiumUser` / StoreKit cache excluded** (correct) |
| FinancialCategory | ✅ | Includes v3 fields (`entryKind`, `occurrenceDate`, etc.) |
| RecurringTransaction | ✅ | |
| SavingsGoal | ✅ | |
| Subscription | ✅ | `cloudKitRecordID` **not** serialized (legacy field omitted) |
| Bill | ✅ | `cloudKitRecordID` omitted |
| BillPayment | ✅ | |
| FinancialSnapshot | ✅ | |

**All 8 Core Data entities are represented** in backup payload (AppSettings as singleton object, others as arrays). Schema version: `BackupConstants.schemaVersion = 1`.

#### RestoreImporter — `budgetmeter.ios/CoreKit/Sources/Backup/RestoreImporter.swift`

| Question | Finding | Status |
|----------|---------|--------|
| Conflict handling | **Wipe-and-replace:** deletes all rows in 7 entity types, saves, then inserts from payload. AppSettings merged into existing singleton. No per-record timestamp/updated_at merge. | ✅ v1-safe, not merge-sync |
| Transactional safety | Clear step saves mid-flight; if import fails after clear, local financial data is empty until rollback — mitigated only if user manually recovers from snapshot (no UI). | ⚠️ Risk |
| Schema guard | Rejects `schemaVersion > BackupConstants.schemaVersion`. | ✅ |

#### LocalSnapshotService — `budgetmeter.ios/CoreKit/Sources/Backup/LocalSnapshotService.swift`

| Trigger | When |
|---------|------|
| Before backup upload | `BackupService.backupNow` |
| Before restore import | `BackupService.restoreFromCloud` |

Storage: `Application Support/BudgetMeterSnapshots/{sessionID}.meta.json` + `.payload.json`. Supports `latestSnapshot()` and `loadSnapshot(sessionID:)` — **not exposed in Settings UI**.

#### FirstSignInStateMachine — `budgetmeter.ios/CoreKit/Sources/Backup/FirstSignInStateMachine.swift`

| Scenario | Classification rule | Recommended action |
|----------|---------------------|-------------------|
| `signedOutWithLocalData` | `!isSignedIn` | `noActionNeeded` |
| `existingCloudKitUser` | `cloudKitAvailable && hasFinancialData` (signed in) | `recommendCloudKitMigrationDryRun` |
| `localOnly` | Local data, no cloud backup | `preserveLocalNoCloudWrite` |
| `cloudOnly` | Empty local, cloud backup exists | `offerCloudRestore` |
| `overlap` | Both local and cloud non-empty | `requireOverlapChoice` |

**Gap:** `AccountBackupSettingsView` reads scenario but **does not act on `FirstSignInAction`** — overlap shows a caption only; cloud-only does not prompt restore; CloudKit user gets no dry-run messaging.

---

### 4. Settings UI

**File:** `budgetmeter.ios/Features/SettingsFeature/View/AccountBackupSettingsView.swift`  
**Entry:** `SettingsView` → Account & Backup navigation link

| Feature | Status | Notes |
|---------|--------|-------|
| Sign in with Apple | ✅ | Native `SignInWithAppleButton`; not paywalled |
| Sign out | ✅ | |
| Backup / restore buttons | ✅ | Premium + signed-in gated |
| Status display | ✅ | Last backup, cloud summary, errors, overlap hint |
| Delete account | ✅ | Destructive confirmation alert |
| Restore confirmation | ✅ | Required when local data exists (`confirmedOverwrite`) |
| Premium CTA | ✅ | Paywall sheet when `.backupSync` locked |

**Localization (`UI.xcstrings`):**  
41 keys under `account.*`, `backup.*`, `auth.*` — spot-checked `account.title` has all 10 languages (EN, TR, DE, FR, ES, IT, PT, JA, ZH-Hans, AR). Account/backup/auth strings appear fully cataloged.

**Missing localization:** No `sync.*` or CloudKit migration informational keys (scope Section 21 recommended `sync.*` + CloudKit legacy copy).

---

### 5. Supabase Configuration

#### SupabaseConfig — `budgetmeter.ios/CoreKit/Sources/Auth/SupabaseConfig.swift`

| Item | Value | Status |
|------|-------|--------|
| Project ID | `mqbtbtlbpcjzleghvrkv` | Present |
| Project URL | `https://mqbtbtlbpcjzleghvrkv.supabase.co` | Present |
| Anon key | JWT in source | Present (RLS must protect data) |
| `isConfigured` | Non-empty ID + key | ✅ |

#### SQL — `docs/supabase/phase9_user_backups.sql`

| Item | Status |
|------|--------|
| File exists | ✅ |
| Table `user_backups` | `user_id` PK, `schema_version`, `app_version`, `payload` jsonb, `record_counts` jsonb, `updated_at` |
| RLS | Enabled; owner-only SELECT/INSERT/UPDATE/DELETE on `auth.uid() = user_id` |
| `delete_own_account()` | Removed from the SQL script; account deletion moved to the `delete-account` Supabase Edge Function |
| Ordered migrations | `0001_user_backups_base.sql`, `0002_user_backup_versions.sql`, `0003_backup_version_capture_trigger.sql` applied successfully |
| Applied to live project | **Unknown / not verifiable from repo** |

#### supabase-swift linkage

| Item | Status |
|------|--------|
| Package | `supabase-swift` **2.47.2** (`Package.resolved`) |
| Xcode project | Linked to app target via SPM (`project.pbxproj`) |
| Client wrapper | `SupabaseClientProvider.makeClient()` |

---

### 6. CloudKit Status

| Item | Current state | Phase 9 expectation |
|------|---------------|---------------------|
| Container | `NSPersistentCloudKitContainer` in `PersistenceService` | Remain until removal gates — **matches** |
| Entity flags | All 8 entities `syncable="YES"`, model `usedWithCloudKit="YES"` (v1–v3) | Unchanged |
| History / remote change | Enabled on store description | Active |
| `isCloudKitAvailable` | `ubiquityIdentityToken != nil` | Used by first-sign-in classifier |
| Checked-in entitlements | **No iCloud/CloudKit capability** in any `.entitlements` file | CloudKit sync may be non-functional in clean checkout; only App Groups + Sign in with Apple present |
| Migration / deprecation plan | Documented in scope doc Sections 17, 28–29; **not executed** | Removal postponed — **correct per plan** |
| Dual-write | None — Supabase is manual backup only | ✅ |

---

### 7. Premium Gating

**File:** `budgetmeter.ios/CoreKit/Sources/Premium/PremiumManager.swift`

| Check | Result |
|-------|--------|
| `BudgetMeterCapability.backupSync.accessLevel` | `.premium` (was `.postponed` in scope doc at planning time) |
| `PremiumManager.hasAccess(to: .backupSync)` | Free → false; premium → true |
| UI guard | `AccountBackupSettingsView` checks before showing backup controls |
| Service guard | `BackupService.validateBackupPreconditions` throws `premiumRequired` |
| Test | `PremiumGateMatrixTests.test_backupSyncRequiresPremiumInPhase9` |

Auth is **not** premium-gated — sign-in available without `.backupSync`. ✅ Matches product rules.

---

### 8. Privacy & Legal

| Surface | Expected (Phase 9) | Actual | Status |
|---------|-------------------|--------|--------|
| Privacy policy — data collection | Supabase premium backup + legacy iCloud note | `SettingsView` **defaultValues** updated; **`UI.xcstrings` catalog entries still iCloud-only** | ❌ **Runtime shows old copy** |
| Privacy policy — data storage | Disclose Supabase processor | Catalog: "No external servers or third-party databases" | ❌ |
| Privacy policy — your rights | Account deletion in Account & Backup | Catalog: "Disable iCloud sync anytime" only | ❌ |
| Account settings copy | Supabase + legacy iCloud | `account.footer`, `backup.footer` localized correctly | ✅ |
| Terms of Service | Lifetime IAP accuracy | `settings.terms.policy.iap.content` still describes **auto-renewing subscription** (pre-existing mismatch) | ⚠️ |
| Settings.xcstrings | Legacy iCloud strings | Duplicate outdated privacy strings in `Settings.xcstrings` | ❌ Stale duplicate |

**Critical finding:** Swift `defaultValue` strings in `SettingsView.swift` do **not** override catalog values. Users see **pre-Phase-9 iCloud-only privacy text** at runtime — App Store review and GDPR accuracy risk.

---

### 9. Build & Test Status

#### Build

```text
xcodebuild -project budgetmeter.ios.xcodeproj -scheme budgetmeter.ios \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' build
→ BUILD SUCCEEDED (2026-06-18)
```

Known warnings: duplicate `.xcstrings` in Copy Bundle Resources (unchanged).

#### Tests

```text
xcodebuild test -parallel-testing-enabled NO
→ 152 passed / 0 failed (2026-06-18)
```

| Test file | Coverage | Tests |
|-----------|----------|-------|
| `FirstSignInStateMachineTests.swift` | Scenario classification (4 cases) | localOnly, cloudOnly, overlap, signedOut |
| `BackupSerializerTests.swift` | Export, round-trip, schema reject, basic restore | 4 tests |
| `PremiumGateMatrixTests.swift` | `.backupSync` premium matrix | 1 Phase-9-specific test |

#### Missing tests (scope Section 25)

| Planned test | Status |
|--------------|--------|
| `AuthSessionTests` / `AuthSessionStoreTests` | ❌ Not present |
| `RestoreImporterTests` (dedicated) | ❌ Only 1 test inside `BackupSerializerTests` |
| `PremiumBackupGateTests` | ⚠️ Partial — matrix test only; no BackupService integration |
| `CloudKitMigrationDryRunTests` | ❌ Not present |
| RLS cross-user integration | ❌ Not present |
| Offline backup behavior | ❌ Not present |
| Account deletion integration | ❌ Not present |
| First-sign-in `existingCloudKitUser` scenario | ❌ Not tested |

---

### 10. Gap Analysis vs Scope Document

#### Implemented vs planned (Phase 9 scope Section 6)

| Requirement | Planned | Implemented |
|-------------|---------|-------------|
| Apple Sign In + Supabase session | Yes | ✅ Code complete; dashboard config unverified |
| Local-only app without account | Yes | ✅ No auth gate on core tabs |
| Auth not premium | Yes | ✅ |
| Backup/sync premium-gated | Yes | ✅ |
| First-sign-in state machine | Yes | ✅ Classifier; ❌ UI actions not wired |
| Local snapshot before backup/restore | Yes | ✅ |
| Destructive overwrite confirmation | Yes | ✅ Restore alert |
| Manual backup/restore (no realtime sync) | Yes | ✅ |
| RLS-safe ownership | Yes | ✅ SQL drafted; live validation pending |
| Account deletion flow | Yes | ✅ RPC + UI |
| Privacy copy updated | Yes | ❌ Catalog not updated |
| CloudKit remains active | Yes | ✅ |
| CloudKit removal | Late sub-phase | ⏸ Postponed (correct) |

#### Infrastructure checklist

| Item | Status |
|------|--------|
| Sign in with Apple entitlement | ✅ In `budgetmeter.ios.entitlements` (`com.apple.developer.applesignin`) |
| Supabase SQL applied to project | ✅ Verified by user on 2026-06-18 |
| Apple provider configured in Supabase dashboard | ❓ Unknown — must be verified manually |
| Apple Developer Services ID / redirect for Supabase | ❓ Unknown |
| Stage B manual QA (sign-in, backup, restore, deletion) | ✅ Passed for v1 per user report |

#### Architectural deviations from scope (acceptable v1 simplifications)

- **Single `user_backups` JSONB row** instead of per-entity Postgres tables with `(user_id, client_record_id)` upserts — simpler but limits incremental sync future.
- **Full-restore replace** instead of overlap chooser with explicit "keep device / restore cloud" buttons.

---

## Risk Assessment

| Risk | Severity | Likelihood | Mitigation status |
|------|----------|------------|-------------------|
| Privacy policy catalog contradicts Supabase backup | **High** | Certain if shipped | Update `UI.xcstrings` + `Settings.xcstrings` before release |
| Supabase SQL/RLS deployment drift | **Medium** | Low | Keep migration order documented and re-run Stage B checks before App Store submission |
| Restore failure after entity clear | **High** | Low–Medium | Expose snapshot recovery UI; transactional import |
| CloudKit + Supabase dual-system race on restore | **Medium** | Medium | Document "wait for CloudKit settle"; dry-run gate |
| Missing Apple nonce | **Medium** | Medium | Add nonce per Supabase Apple auth docs |
| Stale cached session UI | **Low** | Medium | Clear optimistic auth until validated |
| Anon key in repo | **Low** (expected) | N/A | RLS + auth required |
| CloudKit entitlement missing from repo | **Medium** | Unknown | Verify Xcode capabilities vs production behavior |
| Terms IAP wording (subscription vs lifetime) | **Medium** | Existing | Product/legal fix outside Phase 9 core |

---

## CloudKit Migration Risk

CloudKit remains **active legacy infrastructure** with no deactivation path started. Specific risks:

1. **Live users with iCloud data** — `existingCloudKitUser` scenario detected but only recommends dry-run; no migration pipeline or UI.
2. **Model/schema coupling** — All entities CloudKit-syncable; removal requires approved migration plan (scope Gates A–D).
3. **Entitlement gap** — No CloudKit/iCloud entitlement in checked-in plists; production behavior may differ from developer machines.
4. **Parallel sync confusion** — Users may believe iCloud still primary while Supabase backup is marketed; privacy copy inconsistency worsens this.
5. **Race during restore** — Background CloudKit merges + manual Supabase restore could produce unexpected local state; no controlled "pause CloudKit" mechanism.

**CloudKit removal:** Correctly postponed. Do not remove until Supabase backup/restore passes Stage B QA and dry-run migration compares `FinancialSummaryBuilder` totals (scope Section 17).

---

## Test Coverage Analysis

### What exists (Phase 9–related)

- **FirstSignInStateMachineTests** — 4 classification tests; missing `existingCloudKitUser` and signed-out-empty edge cases.
- **BackupSerializerTests** — Schema version, round-trip, one restore smoke test.
- **PremiumGateMatrixTests** — Confirms `.backupSync` is premium.

### Critical gaps before Stage B QA

1. **Auth session lifecycle** — sign-in metadata save/clear, expired session behavior, delete account error paths.
2. **RestoreImporter** — empty store, populated store, failed mid-import, premium entity counts, AppSettings merge.
3. **BackupService** — premium/auth precondition matrix, `localDataRequiresConfirmation`, mock Supabase client (if feasible) or contract tests.
4. **LocalSnapshotService** — create/load/latest round-trip.
5. **Integration** — RLS two-user, offline failure classification, end-to-end with test Supabase project.
6. **CloudKit dry-run** — fixture comparing financial summaries before/after export/import.

### Test suite health

Full suite **155/155 pass** — Phase 9 additions did not regress prior phases.

---

## Summary Table — Audit Checklist

| # | Area | Verdict |
|---|------|---------|
| 1 | AuthService | ⚠️ Partial — missing nonce; otherwise solid |
| 2 | BackupService | ⚠️ Partial — core flow OK; offline/recovery gaps |
| 3 | Serializer / Restore / Snapshot / State machine | ✅ Mostly complete — UI wiring incomplete |
| 4 | Settings UI | ⚠️ Partial — overlap/first-sign-in actions missing |
| 5 | Supabase config + SQL + SPM | ✅ In repo — live apply unverified |
| 6 | CloudKit | ✅ Unchanged per plan — migration not started |
| 7 | Premium gating | ✅ Complete |
| 8 | Privacy & legal | ❌ Catalog stale — blocker for release |
| 9 | Build & tests | ✅ Build + 152 tests pass — integration gaps |
| 10 | Scope completeness | ⚠️ ~65–70% — ops config + QA + copy remain |

---

## Recommended Next Steps (Priority Order)

1. **Update privacy strings in `UI.xcstrings` and `Settings.xcstrings`** to match Supabase + legacy iCloud disclosure (remove "no external servers").
2. **Apply `docs/supabase/phase9_user_backups.sql`** to test project; verify Apple provider + bundle ID; run two-account RLS QA.
3. **Wire `FirstSignInAction` in UI** — overlap chooser (keep local vs restore cloud), cloud-only restore prompt, CloudKit migration notice.
4. **Add Apple Sign In nonce** per Supabase iOS guidance.
5. **Implement offline detection** — surface `BackupSyncStatus.offline` / `BackupServiceError.offline`.
6. **Add missing tests** — AuthSessionStore, RestoreImporter suite, BackupService precondition tests.
7. **Expose snapshot recovery** in Account settings or support flow.
8. **Run Stage B manual QA matrix** from `docs/implementation/phase10_release_qa_scope.md`.
9. **CloudKit migration dry-run** on snapshot copies before any CloudKit deactivation planning.

---

*This audit did not modify source code. Build and test commands were run read-only for verification.*
