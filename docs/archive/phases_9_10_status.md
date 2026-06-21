# Phase 9 & 10 Status Report

**Date:** 2026-06-18  
**Sources:** `implementation_planning_index.md`, `phase9_supabase_auth_database_migration_audit.md`, `phase10_release_qa_audit.md`, `release_tracker.md`, `known_issues.md`, `release_readiness_plan.md`

---

## Phase 9 — Supabase Auth / Database Migration

**Overall:** ~65–70% complete (v1 slice landed in code; not release-ready for live cloud backup)

### ✅ Completed

- **AuthService** — Apple Sign In via Supabase `signInWithIdToken`; session restore on launch; sign-out; account deletion via Edge Function; localized auth errors
- **BackupService** — Serialize → local snapshot → Supabase upsert; restore with overwrite confirmation; premium + signed-in preconditions
- **Serializer / restore** — All 8 Core Data entities in backup payload; wipe-and-replace restore; schema version guard; snapshots before backup/restore
- **FirstSignInStateMachine** — Scenario classifier (local-only, cloud-only, overlap, signed-out)
- **Settings UI** — Account & Backup screen: Sign in with Apple, backup/restore, delete account, premium paywall CTA
- **Premium gating** — `.backupSync` requires premium; auth is free
- **Infrastructure in repo** — `SupabaseConfig`, `phase9_user_backups.sql` (RLS), `supabase-swift` 2.47.2, Sign in with Apple entitlement
- **Localization** — 41 `account.*` / `backup.*` / `auth.*` keys in `UI.xcstrings` (10 languages)
- **Build / tests** — Build succeeds; **152/152** unit tests pass (serializer, state machine, premium gate)

### 🟡 Partially done

- **AuthService** — No Apple Sign In nonce; optimistic cached session before network validation; unused `AppleSignInCoordinator`
- **BackupService** — `offline` error never thrown; no Settings UI to recover from failed restore via local snapshot
- **First-sign-in UX** — State machine classifies overlap/cloud-only/CloudKit scenarios but UI does not act on `FirstSignInAction` (no overlap chooser, no cloud-only restore prompt)
- **Supabase ops** — SQL and config in repo; live apply, Apple provider, and two-user RLS QA unverified in audits (KI-008 marked resolved in `known_issues.md` — Stage B QA still pending)
- **Privacy / legal** — Account/backup copy localized; audit flagged stale privacy catalog strings (KI-009 marked resolved in `known_issues.md` — verify at runtime)
- **CloudKit** — Still active (`NSPersistentCloudKitContainer`); removal correctly postponed; no migration dry-run pipeline
- **Test coverage** — 8 Phase 9 tests only; no auth session, RestoreImporter suite, BackupService integration, RLS, or account-deletion integration tests

### ❌ Not started / remaining

- Wire first-sign-in actions in `AccountBackupSettingsView` (overlap choice, cloud restore prompt, CloudKit migration notice)
- Apple Sign In nonce per Supabase guidance
- Offline reachability detection and `BackupSyncStatus.offline` surfacing
- Snapshot recovery action in Settings
- Stage B manual QA (Script E): sign-in, backup, restore, deletion, RLS security matrix
- CloudKit migration dry-run and deactivation (post–Stage B gates)
- Missing test suites: `AuthSessionStore`, `RestoreImporter`, `BackupService` preconditions, RLS cross-user

---

## Phase 10 — Release QA

**Overall:** Release readiness **22 / 100** — strong automated baseline; manual QA barely started

### ✅ Completed

- **G0 baseline** — App build **PASS**; **152/152** tests **PASS** (2026-06-18)
- **Widget extension** — `BudgetMeterWidgets` scheme builds on simulator (KI-003 resolved)
- **Automated coverage (Phases 1–8)** — Calculation, migration, Home, income/expense, savings, premium gates, widget snapshot/deep-link tests all pass
- **Stage A checklist (2/65)** — PF-08 (`.backupSync` gate); L10N-A01 (catalogs build)

### 🟡 Partially done

- **G4 Widget QA** — 15 unit tests pass; simulator build pass; manual matrix W-01–W-18 and Script D **not run**
- **KI-004** — Widget device/Release archive provisioning still needs verification
- **Known issues** — KI-005, KI-008, KI-009 marked resolved in `known_issues.md`; KI-001, KI-002, KI-004, KI-006, KI-007 still open
- **Release build** — Debug simulator verified; Release configuration build and PF-06 (no DEBUG toggle) **not run**

### ❌ Not started / remaining

| Gate | Status |
|------|--------|
| G1 Stage A core QA | 3% (2/65 items); **0/5 manual scripts run** |
| G2 Migration QA | Script B + FIX-V2/V3 fixtures not run |
| G3 Premium/StoreKit | Script C on physical device not run |
| G5 Localization / accessibility | L10N-A02–A05, A11Y-A01–A05, 10-language matrix |
| G6 Device matrix | Not run |
| G7 Performance smoke | Not run |
| G8 Stage B auth/sync | 0/40 items; blocked until Stage A signed |
| G9 App Store readiness | Archive, screenshots, metadata, privacy labels |
| G10 Go/no-go | No decision documented |

**Manual scripts:** A (first-time user), B (upgrade), C (StoreKit), D (widget), E (auth/sync) — all **NOT RUN**

---

## Release blockers (summary)

1. **Stage A manual QA has not started** — Biggest blocker. Scripts A–D and 63/65 checklist items remain. Automated tests alone do not satisfy Phase 10 exit criteria.

2. **StoreKit sandbox untested** — Script C on a physical device required before premium claims or G3 sign-off.

3. **Migration safety unvalidated** — Script B with FIX-V2/V3 fixtures not run (G2).

4. **If Stage B ships in v1** — Script E + full auth/sync checklist (40 items) after Stage A; verify Supabase/Apple config end-to-end despite KI-008 resolution note.

5. **App Store path incomplete** — Release archive, widget provisioning on device (KI-004), G9 assets, and G10 go/no-go all pending.

6. **Phase 9 code gaps** — First-sign-in UX wiring, nonce, offline handling, and integration tests should close before marketing cloud backup.

**Product decision needed:** Confirm whether Stage B (auth/sync) ships in v1. If **no**, G8/KI-008 block only cloud backup; local-first release can proceed after Stage A. If **yes**, Phase 9 remaining work + Script E are on the critical path.

**Gates passed:** 1/11 (G0 only) · **Estimated readiness:** Not ready to ship
