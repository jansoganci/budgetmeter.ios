# App Store, Privacy, Auth & Security Readiness Audit

**Audit date:** 2026-06-18  
**Mode:** Read-only inspection — no code or doc fixes applied  
**Scope:** iOS project configuration, auth/Supabase, premium/StoreKit, data safety, privacy/legal, localization, widgets, tests, and referenced implementation plans  
**Test run (this audit):** `xcodebuild test` on iPhone 17 (iOS 26.5) → **155/155 passed**

---

## 1. Executive Verdict

### **NOT READY**

BudgetMeter has a **strong engineering baseline** (clean build, 155 passing unit tests, auth/backup/delete flows implemented in code, centralized premium gates, widget extension present). It is **not ready for App Store submission** as a production auth + cloud-backup release without resolving legal/privacy mismatches, incomplete data-deletion semantics, unverified Supabase security QA, and significant manual QA gaps.

**If shipping auth/cloud backup in v1:** treat as **NOT READY** until critical blockers below are fixed and verified.

**If deferring cloud backup to a post-launch update:** core local-first app may be closer to ready, but **Terms of Service / IAP copy mismatch** and **missing external privacy URL** still block a confident submission.

---

## 2. Critical Blockers

| ID | Blocker | Evidence |
|----|---------|----------|
| CB-01 | **Terms of Service contradicts actual IAP model** — catalog and UI describe **auto-renewing subscription**; app implements **lifetime non-consumable** (`com.budgetmeter.premium.lifetime`) with paywall copy “One-time purchase • Lifetime access”. | `UI.xcstrings` → `settings.terms.policy.iap.content`; `PremiumPaywallView.swift`; `PremiumManager.swift` |
| CB-02 | **No hosted external Privacy Policy URL** found in repo or in-app links. App Store Connect requires a publicly accessible privacy policy URL for apps that collect account/financial data. | In-app sheet only (`SettingsView.swift`); `docs/archive/PRIVACY_LEGAL_SUPPORT_ANALYSIS.md` notes missing external URL |
| CB-03 | **No hosted external Terms of Service URL** found. Required for paid apps / IAP. | Same as CB-02 |
| CB-04 | **Privacy Nutrition Label (`PrivacyInfo.xcprivacy`) likely inaccurate** for auth/cloud backup — declares financial info and preferences as **not linked** to user; does not declare **email / user ID** collected via Apple Sign In and Supabase. | `PrivacyInfo.xcprivacy` |
| CB-05 | **Account deletion cloud wipe — verification required.** Client + Edge Function exist; **no integration test** or documented live QA proving `user_backups`, `user_backup_versions`, and auth user are removed. | `AuthService.deleteAccount()`, `supabase/functions/delete-account/index.ts`, `AccountDeletionClientTests.swift` (HTTP contract only) |
| CB-06 | **RLS / cross-user isolation — verification required.** Policies are defined in SQL migrations but **not integration-tested** from the repo; live project apply state not verifiable from code alone. | `supabase/migrations/0001_user_backups_base.sql`, `0002_user_backup_versions.sql` |
| CB-07 | **Local “Reset all data” is incomplete** — `resetAllData()` batch-deletes only `FinancialCategory` and `AppSettings`; does **not** wipe `SavingsGoal`, `Subscription`, `Bill`, `BillPayment`, `RecurringTransaction`, `FinancialSnapshot`. Privacy policy promises “Reset all data via Settings.” | `SettingsViewModel.swift` |
| CB-08 | **Stage B manual QA not executed** — Phase 10 audit scores release readiness ~22/100; auth/sync/account-deletion manual matrices unchecked. | `docs/implementation/phase10_release_qa_audit.md` |

---

## 3. High Risks

| ID | Risk | Notes |
|----|------|-------|
| HR-01 | **CloudKit + Supabase dual-cloud ambiguity** — `NSPersistentCloudKitContainer` still active; no iCloud capability in checked-in entitlements; privacy copy warns “legacy iCloud may still apply.” Users may have data in three places (local, iCloud, Supabase) with unclear ownership. | `PersistenceService.swift`, entitlements files |
| HR-02 | **First sign-in overlap UX not wired** — `FirstSignInStateMachine` recommends `requireOverlapChoice` but UI only shows a caption; `markFirstSignInCompleted()` called unconditionally on every refresh, closing the classification window early. | `AccountBackupSettingsView.swift`, `FirstSignInStateMachine.swift` |
| HR-03 | **Restore failure data-loss window** — `RestoreImporter` clears 7 entity types before import; snapshot exists on disk but **no Settings UI** to recover. | `RestoreImporter.swift`, `LocalSnapshotService.swift` |
| HR-04 | **Apple Sign In nonce not implemented** — `signInWithIdToken` without nonce/state validation; Phase 9 scope requires nonce. | `AuthService.swift` |
| HR-05 | **Apple credential revocation not handled** — no `getCredentialState` monitoring; revoked Apple ID behavior undocumented/untested. | No matches beyond unused `AppleSignInCoordinator.swift` |
| HR-06 | **Account deletion does not clear local financial data** — by design per UI copy, but users may expect full erasure; must align policy + App Store account-deletion guidance. | `account.delete.message` in `AccountBackupSettingsView.swift` |
| HR-07 | **Duplicate `UI.xcstrings` in bundle resources** — app target and widget target both copy `UI.xcstrings` twice in app `project.pbxproj`; known issue KI-001. | `project.pbxproj` |
| HR-08 | **Widget Release/device signing unverified** — KI-004 open: provisioning profile for widget extension on physical device / archive not confirmed in this audit. | `docs/qa/known_issues.md` |
| HR-09 | **Premium product ID vs bundle ID mismatch risk** — product `com.budgetmeter.premium.lifetime` vs bundle `com.janstrade.budgetmeter-ios`; must match App Store Connect configuration (not verifiable from repo). | `PremiumManager.swift`, `project.pbxproj` |
| HR-10 | **No StoreKit Configuration file** in repo — sandbox purchase/restore QA depends on App Store Connect setup. | No `.storekit` in project |

---

## 4. Medium Risks

| ID | Risk | Notes |
|----|------|-------|
| MR-01 | **Offline backup behavior** — `BackupServiceError.offline` defined but never thrown; network failures collapse to generic failed errors. | `BackupService.swift` |
| MR-02 | **Email/password auth methods in `AuthService`** — not exposed in UI (good) but increases attack surface if accidentally wired; no Sign in with Apple-only enforcement at service layer. | `AuthService.swift` |
| MR-03 | **Supabase anon key embedded in client** — acceptable with RLS, but project ID/key are hardcoded; rotation requires app update. | `SupabaseConfig.swift` |
| MR-04 | **Auth session metadata in UserDefaults** — `AuthSessionStore` stores userID/email in standard UserDefaults, not Keychain. | `AuthSessionStore.swift` |
| MR-05 | **Privacy policy / Terms last-updated mismatch** — Privacy “June 2026”; Terms “September 2025” with outdated IAP section. | `SettingsView.swift`, `UI.xcstrings` |
| MR-06 | **No standalone data retention policy document** — retention implied in privacy sheet only; cloud backup versions table has no documented client-side retention/pruning. | Migrations + privacy copy |
| MR-07 | **`hardcoded_strings_audit.md` reports 115 hardcoded + 197 missing-catalog strings** — severity varies; some core paths now localized (`HomeDisplayMapping` uses catalogs). Full non-English QA not run. | `docs/hardcoded_strings_audit.md` |
| MR-08 | **Some accessibility labels remain English hardcoded** — e.g. `DailyBudgetCard` “Daily budget information”. | `DailyBudgetCard.swift` |
| MR-09 | **Edge Function CORS `Access-Control-Allow-Origin: *`** — low risk for mobile POST with Bearer token, but broad CORS on deletion endpoint. | `delete-account/index.ts` |
| MR-10 | **Logout clears auth only** — correct for local-first, but premium cloud backup remains on server; user must understand sign-out ≠ delete. | `AuthService.signOut()` |

---

## 5. Low Risks

| ID | Risk | Notes |
|----|------|-------|
| LR-01 | **Unused `AppleSignInCoordinator`** — dead parallel sign-in path. | `AppleSignInCoordinator.swift` |
| LR-02 | **Debug premium toggle in DEBUG builds** — acceptable; must not ship in Release. | `SettingsView.swift` `#if DEBUG` |
| LR-03 | **Home health navigation TODO** — non-blocking placeholder comment. | `HomeView.swift` |
| LR-04 | **Preview-only hardcoded strings** — KI-006. | DesignSystem previews |
| LR-05 | **Widget fixed font sizes** — `minimumScaleFactor` used but no explicit Dynamic Type styles in widget. | `NetDailyPaceWidget.swift` |
| LR-06 | **CLAUDE.md outdated** — still says “zero external dependencies”; project uses `supabase-swift` 2.47.2. | `Package.resolved` |

---

## 6. Missing Legal / Privacy Documents

| Document | Status |
|----------|--------|
| Hosted Privacy Policy URL | **Missing** |
| Hosted Terms of Service URL | **Missing** |
| Standalone data retention policy | **Missing** |
| Standalone account deletion policy | **Partial** — in-app copy only (`account.delete.message`, privacy “Your Rights”) |
| Cookie policy | N/A (no web) |
| GDPR/CCPA-specific addendum | **Missing** |
| Subprocessor list (Supabase) | **Partial** — named in in-app privacy sheet only |
| Apple Sign In / account deletion help article | **Missing** |

**In-app only (present):** Privacy Policy sheet and Terms of Service sheet in `SettingsView.swift`, localized via `UI.xcstrings` (privacy content updated for Supabase + legacy iCloud).

---

## 7. Missing App Store Requirements

| Requirement | Status |
|-------------|--------|
| External privacy policy URL | **Missing** |
| External terms URL (paid app) | **Missing** |
| Account deletion in app (account creation apps) | **Present** — Settings → Account & Backup → Delete Account |
| Restore Purchases | **Present** — `PremiumPaywallView` → `PremiumManager.restorePurchases()` |
| Sign in with Apple capability | **Present** in entitlements |
| App Privacy Details accuracy | **At risk** — see CB-04 |
| Screenshots / metadata | **Not in repo** (expected) |
| Age rating / financial disclaimer | **Partial** — financial disclaimer in Terms sheet |
| Export compliance | **Not verified** |
| Widget extension archive signing | **Verification required** (KI-004) |

---

## 8. Auth / Account Deletion Findings

### Implemented ✅

| Item | Finding |
|------|---------|
| Apple Sign In UI | `SignInWithAppleButton` in `AccountBackupSettingsView`; scopes `.email`, `.fullName` |
| Supabase auth | `signInWithIdToken` with Apple provider |
| Session restore | `restoreSessionIfNeeded()` on app launch (`budgetmeter_iosApp.swift`); refresh on expired session |
| Sign out | Supabase `signOut()` + `clearSessionState()`; **does not wipe Core Data** |
| Account deletion UI | Destructive confirmation alert; explains cloud vs local |
| Account deletion client | POST to `delete-account` Edge Function with Bearer + anon apikey |
| Edge Function | Validates user JWT; deletes `user_backup_versions`, `user_backups`, then `auth.admin.deleteUser` |
| First sign-in safety (logic) | `FirstSignInStateMachine` classifies local/cloud/overlap; sign-in does **not** auto-upload or auto-restore |
| Tests | `AccountDeletionClientTests` (3), `FirstSignInStateMachineTests` (4) |

### Gaps / verification required ⚠️

| Item | Finding |
|------|---------|
| Apple nonce | **Not implemented** |
| Apple token revoke | **Not handled or documented** |
| Overlap chooser | **Not wired** — warning text only |
| Cloud-only first sign-in | **No auto-prompt** to restore |
| Delete account local data | **Intentionally preserved** — must match policy |
| Delete account integration test | **Missing** |
| Live Edge Function deploy | **Not verifiable from repo** |
| Email auth | Code exists; **not in UI** |

---

## 9. Supabase / Security Findings

### Positive ✅

| Item | Finding |
|------|---------|
| User scoping | Tables use `user_id uuid references auth.users` |
| RLS | Enabled on `user_backups` and `user_backup_versions` with `auth.uid() = user_id` for CRUD |
| No service role in app | Service role only in Edge Function env (`SUPABASE_SERVICE_ROLE_KEY`) |
| No device-id ownership | Backup keyed to authenticated `user_id` |
| Account deletion path | Edge Function (not exposed SECURITY DEFINER RPC) |
| Anon key in client | Expected; RLS must enforce boundaries |

### Risks ⚠️

| Item | Finding |
|------|---------|
| RLS live enforcement | **Verification required** — no automated cross-user test |
| Migrations applied to production | **Unknown** from repo |
| JSONB payload sensitivity | Full financial export in `payload` — high value target if RLS misconfigured |
| Version history growth | `user_backup_versions` append-only via trigger; no documented purge policy |
| CORS on delete function | `Access-Control-Allow-Origin: *` |
| Project credentials in source | `SupabaseConfig.swift` contains project ID + anon JWT |

---

## 10. StoreKit / Premium Findings

### Positive ✅

| Item | Finding |
|------|---------|
| Restore purchases | `AppStore.sync()` + `Transaction.currentEntitlements` |
| Centralized gates | `BudgetMeterCapability` / `PremiumManager.hasAccess(to:)` |
| Free core usable | Home, income, expense, one savings goal, basic recurring = free |
| No external payment | StoreKit only |
| Lifetime product | `com.budgetmeter.premium.lifetime` non-consumable |
| Paywall copy | “One-time purchase • Lifetime access” |
| Premium not in cloud backup | `BackupSerializer` excludes `isPremiumUser` |
| Tests | `PremiumGateMatrixTests` including `.backupSync` |

### Issues ❌

| Item | Finding |
|------|---------|
| Terms IAP section | Describes **subscription** model — **misleading / rejection risk** |
| Product ID ↔ App Store Connect | **Not verifiable** in repo |
| StoreKit sandbox QA | **Not documented as complete** |
| Widgets premium gate | Locked teaser + paywall deep link — OK; manual QA pending |

---

## 11. Data Migration Findings

| Area | Risk | Details |
|------|------|---------|
| CoreData | Medium | Model v3 exists; `FinancialDataMigrationService` present; migration tests exist |
| CloudKit coexistence | **High** | `NSPersistentCloudKitContainer` + App Group store; no iCloud entitlement in repo; sync state unclear on clean install |
| Supabase backup | Medium | Manual backup/restore v1; wipe-and-replace restore |
| Logout | Low | Local data retained |
| Delete account | Medium | Cloud removed (if Edge Function succeeds); local retained |
| Offline | Medium | App remains local-first; backup fails without clear offline error |
| `resetAllData` | **High** | Incomplete entity wipe (see CB-07) |
| Upgrade path | Medium | Restore clears entities mid-flight — snapshot recovery not user-facing |

---

## 12. Localization / Accessibility Findings

| Area | Status |
|------|--------|
| Auth/backup/account strings | Cataloged in `UI.xcstrings` (10 languages spot-checked for `account.*`, `backup.*`, `auth.*`) |
| Privacy policy strings | Updated in `UI.xcstrings` for Supabase disclosure |
| Terms IAP strings | **Wrong content** (subscription) in all languages |
| Duplicate catalogs | `Settings.xcstrings` duplicates privacy keys; app bundles 8 `.xcstrings` with duplicate `UI.xcstrings` entries |
| Hardcoded English | Audit doc lists gaps; `HomeDisplayMapping` now localized |
| VoiceOver | Widget has `accessibilityLabel`; some cards use hardcoded English labels |
| Dynamic Type | Mixed — hero/cards use semantic fonts in places; widget uses fixed sizes with scaling |
| Financial readability | Pace copy localized; currency formatting via helpers |
| RTL (Arabic) | Catalog entries present; **manual RTL QA not run** |

---

## 13. Widget Findings

| Item | Status |
|------|--------|
| Extension target | `BudgetMeterWidgets` scheme builds on simulator (per Phase 10 audit) |
| App Group | `group.com.budgetmeter.shared` in app + widget entitlements |
| Data source | `WidgetSnapshotStore` → App Group `UserDefaults` |
| Premium locked state | Locked teaser + `budgetmeter://premium/widgets` deep link |
| Deep link routing | `budgetmeter_iosApp.handleDeepLink` → `ContentView` shows widget paywall |
| Stale/missing states | Implemented |
| Tests | `WidgetSnapshotWriterTests`, `WidgetSnapshotStoreTests`, `WidgetDeepLinkRoutingTests` |
| Device/archive signing | **Verification required** (KI-004) |
| Core Data in App Group | SQLite store shared with widgets — ensure widget cannot read raw DB (uses snapshot only — OK) |

---

## 14. Exact Files Inspected

### iOS configuration
- `budgetmeter.ios.xcodeproj/project.pbxproj`
- `budgetmeter.ios/Info.plist`
- `budgetmeter.ios/budgetmeter.ios.entitlements`
- `BudgetMeterWidgets/BudgetMeterWidgets.entitlements`
- `BudgetMeterWidgets/Info.plist`
- `budgetmeter.ios/PrivacyInfo.xcprivacy`
- `budgetmeter.ios.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`

### App entry & navigation
- `budgetmeter.ios/budgetmeter_iosApp.swift`
- `budgetmeter.ios/ContentView.swift`

### Auth & Supabase
- `budgetmeter.ios/CoreKit/Sources/Auth/AuthService.swift`
- `budgetmeter.ios/CoreKit/Sources/Auth/AuthSessionStore.swift`
- `budgetmeter.ios/CoreKit/Sources/Auth/SupabaseConfig.swift`
- `budgetmeter.ios/CoreKit/Sources/Auth/SupabaseClientProvider.swift`
- `budgetmeter.ios/CoreKit/Sources/Auth/AppleSignInCoordinator.swift`
- `supabase/functions/delete-account/index.ts`
- `supabase/migrations/0001_user_backups_base.sql`
- `supabase/migrations/0002_user_backup_versions.sql`
- `supabase/migrations/0003_backup_version_capture_trigger.sql`
- `docs/supabase/phase9_user_backups.sql`

### Backup & persistence
- `budgetmeter.ios/CoreKit/Sources/Backup/BackupService.swift`
- `budgetmeter.ios/CoreKit/Sources/Backup/BackupSerializer.swift`
- `budgetmeter.ios/CoreKit/Sources/Backup/RestoreImporter.swift`
- `budgetmeter.ios/CoreKit/Sources/Backup/FirstSignInStateMachine.swift`
- `budgetmeter.ios/CoreKit/Sources/Backup/LocalSnapshotService.swift`
- `budgetmeter.ios/CoreKit/Sources/Persistence/PersistenceService.swift`

### Premium & settings UI
- `budgetmeter.ios/CoreKit/Sources/Premium/PremiumManager.swift`
- `budgetmeter.ios/Features/PremiumFeature/View/PremiumPaywallView.swift`
- `budgetmeter.ios/Features/SettingsFeature/View/SettingsView.swift`
- `budgetmeter.ios/Features/SettingsFeature/View/AccountBackupSettingsView.swift`
- `budgetmeter.ios/Features/SettingsFeature/ViewModel/SettingsViewModel.swift`

### Widgets
- `BudgetMeterWidgets/NetDailyPaceWidget.swift`
- `budgetmeter.ios/CoreKit/Sources/Widget/WidgetSnapshotService.swift`
- `budgetmeter.ios/CoreKit/Sources/Widget/WidgetSnapshotWriter.swift`
- `budgetmeter.ios/WidgetShared/WidgetSnapshotStore.swift`
- `budgetmeter.ios/WidgetShared/WidgetConstants.swift`

### Localization & privacy strings
- `budgetmeter.ios/Resources/UI.xcstrings` (privacy, terms, auth, backup keys)
- `budgetmeter.ios/Resources/Settings.xcstrings`

### Tests
- `budgetmeter.iosTests/AccountDeletionClientTests.swift`
- `budgetmeter.iosTests/FirstSignInStateMachineTests.swift`
- `budgetmeter.iosTests/PremiumGateMatrixTests.swift`
- `budgetmeter.iosTests/BackupSerializerTests.swift`
- `budgetmeter.iosTests/WidgetDeepLinkRoutingTests.swift`
- (Full suite: 15 test files, 155 tests executed)

### Planning & QA docs
- `docs/implementation/implementation_planning_index.md`
- `docs/implementation/auth_supabase_sync_plan.md`
- `docs/implementation/phase9_supabase_auth_database_migration_scope.md`
- `docs/implementation/phase9_supabase_auth_database_migration_audit.md`
- `docs/implementation/premium_entitlement_plan.md`
- `docs/implementation/phase7_premium_cleanup_scope.md` (referenced via index)
- `docs/implementation/widgets_plan.md` (referenced via index)
- `docs/implementation/phase8_widget_v1_scope.md` (referenced via index)
- `docs/implementation/release_phase_plan.md`
- `docs/implementation/localization_accessibility_qa_plan.md`
- `docs/implementation/phase10_release_qa_audit.md`
- `docs/qa/known_issues.md`
- `docs/hardcoded_strings_audit.md`
- `docs/archive/product_decisions_v1.md` (`docs/product_decisions_v1.md` **not found** at requested path)
- `docs/archive/PRIVACY_LEGAL_SUPPORT_ANALYSIS.md`

---

## 15. Exact Files That Likely Need Fixes Later

| Priority | File(s) |
|----------|---------|
| P0 | `budgetmeter.ios/Resources/UI.xcstrings` — `settings.terms.policy.iap.content` (+ all locales) |
| P0 | Hosted legal pages (new, outside repo) — privacy + terms URLs for App Store Connect |
| P0 | `budgetmeter.ios/PrivacyInfo.xcprivacy` — linked data types for auth/email |
| P0 | `budgetmeter.ios/Features/SettingsFeature/ViewModel/SettingsViewModel.swift` — complete `resetAllData()` |
| P1 | `budgetmeter.ios/Features/SettingsFeature/View/AccountBackupSettingsView.swift` — wire overlap/cloud-only first-sign-in actions |
| P1 | `budgetmeter.ios/CoreKit/Sources/Auth/AuthService.swift` — Apple nonce; consider removing unused email auth |
| P1 | `supabase/functions/delete-account/index.ts` — deploy + live QA checklist |
| P1 | `budgetmeter.ios.xcodeproj/project.pbxproj` — remove duplicate `UI.xcstrings` copy phases |
| P2 | `budgetmeter.ios/CoreKit/Sources/Backup/BackupService.swift` — offline detection |
| P2 | `budgetmeter.ios/CoreKit/Sources/Backup/RestoreImporter.swift` + Settings UI — snapshot recovery |
| P2 | `budgetmeter.ios/CoreKit/Sources/Persistence/PersistenceService.swift` — CloudKit migration/entitlement decision |
| P2 | `budgetmeter.ios/CoreKit/Sources/Auth/AuthSessionStore.swift` — Keychain for session metadata |
| P3 | `budgetmeter.ios/CoreKit/Sources/Auth/AppleSignInCoordinator.swift` — remove or consolidate |
| P3 | `budgetmeter.ios/DesignSystem/Components/Cards/DailyBudgetCard.swift` — localize accessibility strings |

---

## 16. Recommended Fix Order

1. **Legal / App Store Connect** — publish hosted Privacy Policy + Terms URLs; fix Terms IAP copy to lifetime non-consumable in all locales.
2. **Privacy manifest** — update `PrivacyInfo.xcprivacy` to match Apple Sign In + Supabase backup (linked financial data when cloud backup used).
3. **Local data reset** — make `resetAllData()` wipe all user entities or update privacy copy to match actual behavior.
4. **Supabase ops QA** — apply migrations, deploy `delete-account`, run cross-user RLS tests, run live delete-account test on staging project.
5. **Auth hardening** — Apple Sign In nonce; document/test credential revocation behavior.
6. **First-sign-in UX** — implement overlap chooser and cloud-only restore prompt; stop unconditional `markFirstSignInCompleted()`.
7. **Restore safety** — expose local snapshot recovery in Settings after failed restore.
8. **Build hygiene** — dedupe `.xcstrings` in `project.pbxproj`; verify widget archive signing on device.
9. **Stage A/B manual QA** — execute Phase 10 scripts (StoreKit sandbox, migration fixtures, auth flows).
10. **Localization pass** — address remaining hardcoded strings per `hardcoded_strings_audit.md`; RTL/VoiceOver sweep.

---

## 17. What Can Wait Until After App Store Submission

| Item | Rationale |
|------|-----------|
| CloudKit removal / migration execution | Documented as post-Supabase; legacy note in privacy is acceptable short-term if iCloud sync inactive |
| Email/password auth removal (if unused) | Not exposed in UI |
| `AppleSignInCoordinator` cleanup | Dead code only |
| Offline-specific backup error types | UX polish |
| `user_backup_versions` retention/pruning policy | Operational; not blocking v1 manual backup |
| Preview-only hardcoded strings | Not shipped |
| RevenueCat / ads-free postponed capability | `.postponed` in matrix |
| Pulsey / gamification polish | Product scope |
| Full RTL manual matrix | Can ship EN-first only if business accepts; 10-language catalogs exist |

**Cannot wait if shipping auth/cloud in v1:** CB-01 through CB-08, HR-02, HR-05, HR-06 (policy clarity).

---

## 18. Final Go / No-Go Recommendation

### **NO-GO** for App Store submission with **auth + Supabase cloud backup** enabled for users.

### **NO-GO** for paid IAP submission until **Terms of Service IAP section** and **external legal URLs** are fixed.

### **CONDITIONAL GO** for a **local-first-only** release (no cloud backup marketing, auth optional/hidden) **only after**:
- Terms/privacy legal fixes (CB-01–03)
- Privacy manifest update (CB-04)
- `resetAllData` fix or copy correction (CB-07)
- StoreKit sandbox purchase + restore verified on device
- Widget extension archive signing verified (HR-08)

---

## Audit Checklist Summary

| # | Area | Result |
|---|------|--------|
| 1 | Auth readiness | **Partial** — core flows coded; nonce, overlap UX, revoke handling, live QA missing |
| 2 | Privacy readiness | **Partial** — in-app sheets updated; external URLs, retention policy, manifest gaps |
| 3 | Supabase security | **Partial** — RLS defined; live verification required |
| 4 | StoreKit / Premium | **Partial** — restore + gates OK; Terms mismatch critical |
| 5 | Data safety | **At risk** — incomplete local reset; restore rollback; CloudKit coexistence |
| 6 | App Store Review risks | **High** — legal/IAP mismatch, privacy manifest, unverified delete path |
| 7 | Localization / accessibility | **Partial** — auth strings good; Terms wrong; manual a11y QA pending |
| 8 | Widget readiness | **Partial** — code + unit tests pass; device signing + manual QA pending |

---

*End of audit. No code or documentation was modified except creation of this report.*
