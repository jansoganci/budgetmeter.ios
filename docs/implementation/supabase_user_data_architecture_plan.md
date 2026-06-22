# Supabase User Data Architecture Plan

## 1) Purpose

This document is **architecture planning only** for a future Supabase-backed user data model in BudgetMeter.

- No Swift implementation is included.
- No Supabase migration SQL is included.
- No backend/Edge Function behavior is changed.
- No Core Data schema changes are proposed for immediate execution.
- `BackupService` remains in place during transition planning.

---

## 2) Current Architecture Summary

### What is local-first today

- BudgetMeter persists app and financial data in Core Data via `PersistenceService`.
- `PersistenceService` uses `NSPersistentCloudKitContainer` and Core Data entities are marked `syncable="YES"`.
- Most user activity (income/expense edits, goals, bills, subscriptions, notification toggles, theme/currency choices) is written locally first.

### What Supabase Auth does today

- `AuthService` manages sign-in/session using Supabase Auth (Apple Sign In and email/password).
- Auth currently establishes identity and session state (`currentUserID`, `currentEmail`), plus account deletion orchestration.
- Auth does **not** currently mean all financial edits are continuously synced to structured Supabase tables.

### What Cloud Backup does today

- `BackupService` is premium-gated and manual.
- On `Back Up Now`, app exports Core Data payload (`BackupSerializer`) and upserts one JSON snapshot row to `user_backups`.
- On restore, app reads one row and performs wipe-and-replace import (`RestoreImporter`) into local Core Data.
- Local snapshots are created before backup/restore for recovery (`LocalSnapshotService`).

### What data is backed up manually today

From `BackupPayload`:

- `AppSettings` subset
- `FinancialCategory`
- `RecurringTransaction`
- `SavingsGoal`
- `Subscription`
- `Bill`
- `BillPayment`
- `FinancialSnapshot`

### Current confusion created by this model

- Users see Supabase sign-in and infer automatic cloud sync.
- "Cloud Backup" label suggests real-time multi-device persistence, but behavior is manual snapshot.
- Backup and sync mental models are mixed in one UX surface.
- CloudKit legacy presence plus Supabase backup language increases ambiguity.

---

## 3) Product Goal

Target future behavior:

- Authenticated user account per person (`auth.users.id`).
- User-specific persistent settings/profile state.
- Onboarding completion persisted per account.
- Notification preferences persisted per account.
- Financial records persisted in structured user-owned tables.
- RLS-enabled data model where users only access `auth.uid() = user_id`.
- Clear architecture boundary:
  - local cache for speed/offline resiliency
  - Supabase as account data layer (eventual source of truth)
- Remove or reduce Backup/Restore confusion by moving toward account-based persistence.

---

## 4) Key Architecture Decision

### Option A: Keep Core Data source of truth + Supabase backup only

- **Pros**
  - Minimal engineering change.
  - Lowest short-term migration risk.
  - Existing flows remain stable.
- **Cons**
  - User confusion persists (backup vs sync).
  - No true cross-device continuity.
  - Operationally limited for account-centric product direction.
- **Risk**: Medium product risk, low technical risk.
- **Complexity**: Low.
- **MVP suitability**: Short-term acceptable, long-term poor fit.

### Option B: Supabase source of truth + Core Data local cache

- **Pros**
  - Clean account model and clear ownership.
  - Better cross-device path.
  - Easier policy/RLS governance once mature.
- **Cons**
  - Requires sync, conflict, offline strategy upfront.
  - Highest immediate migration/testing cost.
  - More regression exposure if done all at once.
- **Risk**: High if big-bang.
- **Complexity**: High.
- **MVP suitability**: Good target architecture, risky immediate rollout.

### Option C: Hybrid phased migration (recommended)

- **Pros**
  - Controlled risk by moving low-risk domains first.
  - Early user value (settings/profile continuity) without immediate full financial sync.
  - Allows validation of RLS, data model, and auth-state reliability incrementally.
- **Cons**
  - Temporary dual-state complexity during transition.
  - Requires clear UX messaging while backup and sync coexist.
- **Risk**: Medium and manageable.
- **Complexity**: Medium-high but phaseable.
- **MVP suitability**: Best fit.

### Option D: Full real-time sync immediately

- **Pros**
  - Fastest path to final product promise if successful.
- **Cons**
  - Very high blast radius: schema, app data layer, offline, conflict, migration, CloudKit coexistence.
  - Highest chance of data-loss or trust incidents.
- **Risk**: Very high.
- **Complexity**: Very high.
- **MVP suitability**: Not recommended.

### Decision Recommendation

Adopt **Option C (Hybrid phased migration)** with long-term trajectory toward Option B.

Proposed phases:

1. profile/settings/onboarding/notification prefs
2. savings goals/subscriptions/recurring
3. categories + one-time financial entries + snapshots
4. offline/local cache hardening
5. Backup & Restore deprecation only after stability proof

---

## 5) Data Inventory

| Data Category | Current Local Source | Store in Supabase? | Table Suggestion | Privacy Sensitivity | MVP Priority |
|---|---|---|---|---|---|
| User profile identity metadata | Supabase Auth + local session cache | Yes | `profiles` | Medium | P1 |
| Onboarding completion | `@AppStorage(hasCompletedOnboarding)` | Yes | `user_settings` | Low | P1 |
| Preferred currency | `AppSettings.preferredCurrencyCode` | Yes | `user_settings` | Low | P1 |
| Selected theme | `AppSettings.selectedTheme` | Yes | `user_settings` | Low | P1 |
| Appearance mode | `UserDefaults.AppearanceMode` | Yes | `user_settings` | Low | P1 |
| Language mode | `UserDefaults.LanguageMode` | Yes | `user_settings` | Low | P1 |
| Notification preferences | `AppSettings` + `NotificationSettingsViewModel` | Yes | `notification_preferences` | Low-Medium | P1 |
| Notification schedule times | `weeklySummaryTime`, `dailyTime` in AppSettings | Yes | `notification_preferences` | Low | P1 |
| Premium preference UI state (non-entitlement) | AppSettings tutorial flags etc. | Yes (selectively) | `user_settings` | Low | P1 |
| Premium entitlement status | StoreKit + `AppSettings.isPremiumUser` cache | Keep StoreKit source | `user_entitlements_cache` optional | Medium | P2 |
| Biometric enabled flag | AppSettings + UserDefaults fallback | Optional (config only) | `user_settings` | Medium | P2 |
| Financial categories (recurring + one-time flags) | `FinancialCategory` | Yes | `financial_categories` | High | P3 |
| One-time entry semantics | `FinancialCategory.entryKind/occurrenceDate` | Yes | `one_time_entries` (or in categories) | High | P3 |
| Recurring transactions | `RecurringTransaction` | Yes | `recurring_transactions` | High | P2 |
| Savings goals | `SavingsGoal` | Yes | `savings_goals` | High | P2 |
| Subscriptions | `Subscription` | Yes | `subscriptions` | High | P2 |
| Bills | `Bill` | Yes | `bills` | High | P2/P3 |
| Bill payments/history | `BillPayment` | Yes | `bill_payments` | High | P2/P3 |
| Financial snapshots | `FinancialSnapshot` | Yes | `financial_snapshots` | High | P3 |
| Export metadata (last export date/type) | `AppSettings.lastExportDate` | Optional | `export_jobs` / `user_settings` | Medium | P4 |
| Soft delete/tombstones | Not formalized globally | Yes | per-table `deleted_at` + optional `deleted_records` | High | P3 |
| Sync metadata (device, cursor, app ver) | Limited today | Yes | `user_devices`, `sync_metadata` | Medium | P3 |

Notes:

- Keep highly sensitive financial values under strict RLS and least-privilege queries.
- Avoid storing unnecessary device-identifying attributes.
- Entitlement truth should remain StoreKit; Supabase stores only app-side feature preferences/cache where needed.

---

## 6) Proposed Supabase Schema (Planning)

## Core account/settings tables

### `profiles`

- **Purpose**: Lightweight user profile row keyed by auth user.
- **Key columns**
  - `user_id uuid pk references auth.users(id) on delete cascade`
  - `email text`
  - `display_name text`
  - `created_at timestamptz`
  - `updated_at timestamptz`
- **Indexes**
  - PK on `user_id`
  - optional index on `updated_at`
- **Unique constraints**
  - `user_id` unique/PK
- **RLS**
  - CRUD only for own `user_id`.

### `user_settings`

- **Purpose**: Account-scoped non-financial app preferences.
- **Key columns**
  - `user_id uuid pk`
  - `onboarding_completed boolean`
  - `preferred_currency_code text`
  - `selected_theme text`
  - `appearance_mode text`
  - `language_code text`
  - `biometric_enabled boolean` (optional)
  - tutorial flags (`has_seen_subscription_tutorial`, etc.)
  - `created_at`, `updated_at`
- **Indexes**
  - PK on `user_id`
- **Unique constraints**
  - one row per user
- **RLS**
  - own row only.

### `notification_preferences`

- **Purpose**: Durable notification flags and schedule preferences.
- **Key columns**
  - `user_id uuid pk`
  - `weekly_summary_enabled boolean`
  - `weekly_summary_time time`
  - `milestones_enabled boolean`
  - `spending_alerts_enabled boolean`
  - `daily_encouragement_enabled boolean`
  - `daily_time time`
  - `last_weekly_summary timestamptz`
  - `last_milestone_check timestamptz`
  - `created_at`, `updated_at`
- **Indexes**
  - PK on `user_id`
- **RLS**
  - own row only.

## Financial domain tables

### `financial_categories`

- **Purpose**: Account-owned categories and amounts (recurring + one-time metadata).
- **Key columns**
  - `id uuid pk`
  - `user_id uuid not null`
  - `client_record_id text` (mapping local UUID/uniqueID)
  - `type text` (`income`/`expense`)
  - `amount numeric`
  - `frequency text`
  - `entry_kind text` (`recurring`/`oneTime`)
  - `occurrence_date date`
  - `is_custom boolean`
  - `custom_name text`
  - `custom_icon_name text`
  - `custom_color_hex text`
  - `source_type text`
  - `source_id text`
  - `is_active boolean`
  - `created_at`, `updated_at`, `deleted_at`
- **Indexes**
  - `(user_id, type, frequency)`
  - `(user_id, entry_kind, occurrence_date)`
  - `(user_id, deleted_at)`
- **Unique constraints**
  - `(user_id, client_record_id)` optional
  - optional unique normalized custom names per type if desired.
- **RLS**
  - strict `auth.uid() = user_id`.

### `recurring_transactions`

- **Purpose**: Structured recurring automation records.
- **Key columns**
  - `id uuid pk`
  - `user_id uuid`
  - `title text`
  - `amount numeric`
  - `category_name text`
  - `category_type text`
  - `frequency text`
  - `start_date date`
  - `end_date date`
  - `next_due_date date`
  - `is_active boolean`
  - `notes text`
  - `last_processed_date timestamptz`
  - `created_at`, `updated_at`, `deleted_at`
- **Indexes**
  - `(user_id, next_due_date)`
  - `(user_id, is_active)`
- **RLS**
  - own rows only.

### `one_time_entries` (optional explicit table)

- **Purpose**: Canonical one-time event rows (if separated from `financial_categories`).
- **Key columns**
  - `id uuid pk`
  - `user_id uuid`
  - `financial_category_id uuid` (fk optional)
  - `kind text` (`income`/`expense`)
  - `amount numeric`
  - `occurred_at date`
  - `notes text`
  - `source_type text`, `source_id text`
  - `created_at`, `updated_at`, `deleted_at`
- **Indexes**
  - `(user_id, occurred_at)`
  - `(user_id, kind)`
- **RLS**
  - own rows only.

### `savings_goals`

- **Purpose**: User savings goals and progress.
- **Key columns**
  - `id uuid pk`
  - `user_id uuid`
  - `name text`
  - `target_amount numeric`
  - `current_amount numeric`
  - `target_date date`
  - `emoji text`
  - `color_hex text`
  - `priority smallint`
  - `is_archived boolean`
  - `archived_date timestamptz`
  - `completed_date timestamptz`
  - `notes text`
  - `category text`
  - `monthly_contribution numeric`
  - `created_at`, `updated_at`, `deleted_at`
- **Indexes**
  - `(user_id, is_archived, completed_date)`
  - `(user_id, target_date)`
- **RLS**
  - own rows only.

### `subscriptions`

- **Purpose**: Subscription lifecycle and renewal reminder data.
- **Key columns**
  - `id uuid pk`
  - `user_id uuid`
  - `name text`
  - `amount numeric`
  - `billing_cycle text`
  - `custom_cycle_days smallint`
  - `first_bill_date date`
  - `next_renewal_date date`
  - `category text`
  - `notes text`
  - `reminder_days_before smallint`
  - `is_active boolean`
  - `is_paused boolean`
  - `created_at`, `updated_at`, `deleted_at`
- **Indexes**
  - `(user_id, next_renewal_date)`
  - `(user_id, is_active, is_paused)`
- **RLS**
  - own rows only.

### `bills`

- **Purpose**: Bill tracking state.
- **Key columns**
  - `id uuid pk`
  - `user_id uuid`
  - `name text`
  - `amount numeric`
  - `is_recurring boolean`
  - `frequency text`
  - `due_date date`
  - `original_due_date date`
  - `category text`
  - `icon_name text`
  - `color_hex text`
  - `notes text`
  - `reminder_days_before smallint`
  - `is_paid boolean`
  - `paid_date timestamptz`
  - `paid_amount numeric`
  - `is_auto_pay boolean`
  - `created_at`, `updated_at`, `deleted_at`
- **Indexes**
  - `(user_id, due_date)`
  - `(user_id, is_paid, due_date)`
- **RLS**
  - own rows only.

### `bill_payments`

- **Purpose**: Payment history rows.
- **Key columns**
  - `id uuid pk`
  - `user_id uuid`
  - `bill_id uuid` (fk to `bills`)
  - `due_date date`
  - `paid_date timestamptz`
  - `expected_amount numeric`
  - `actual_amount numeric`
  - `notes text`
  - `was_late boolean`
  - `days_late smallint`
  - `created_at`, `updated_at`, `deleted_at`
- **Indexes**
  - `(user_id, bill_id, created_at desc)`
  - `(user_id, paid_date)`
- **RLS**
  - own rows only.

### `financial_snapshots`

- **Purpose**: Historical aggregate snapshots for insights.
- **Key columns**
  - `id uuid pk`
  - `user_id uuid`
  - `snapshot_type text`
  - `date date`
  - `total_income numeric`
  - `total_expense numeric`
  - `balance numeric`
  - `net_flow numeric`
  - `savings_amount numeric`
  - `health_score smallint`
  - `savings_rate numeric`
  - `category_breakdown jsonb`
  - `created_at`, `updated_at`, `deleted_at`
- **Indexes**
  - `(user_id, date desc)`
  - `(user_id, snapshot_type, date desc)`
- **RLS**
  - own rows only.

## Sync/ops helper tables

### `user_devices` (optional)

- **Purpose**: per-device sync diagnostics and cursors.
- **Key columns**
  - `id uuid pk`
  - `user_id uuid`
  - `device_label text`
  - `platform text`
  - `app_version text`
  - `last_seen_at timestamptz`
  - `created_at`, `updated_at`
- **Indexes**
  - `(user_id, last_seen_at desc)`
- **RLS**
  - own rows only.

### `deleted_records` or per-table tombstones

- **Purpose**: conflict-safe deletion propagation.
- **Approach**
  - Prefer per-table `deleted_at` in MVP.
  - Optional centralized audit tombstone table in later phase.

---

## 7) RLS / Security Model

Core rules:

- Every user-owned table includes `user_id uuid not null`.
- RLS enabled on all user-owned tables.
- User policies enforce `auth.uid() = user_id`.
- Service-role access only from trusted backend/Edge Functions.
- No public anonymous cross-user financial access.

Policy pattern (example, not implementation):

- **SELECT**: `using (auth.uid() = user_id)`
- **INSERT**: `with check (auth.uid() = user_id)`
- **UPDATE**: `using (auth.uid() = user_id) with check (auth.uid() = user_id)`
- **DELETE**: `using (auth.uid() = user_id)`

Delete account implications:

- Keep account deletion server-side privileged flow (existing Edge Function model is directionally correct).
- Ensure cascade/ordered deletion across all user-owned tables.
- Ensure `auth.users` removal and associated data wipe are consistent and auditable.

---

## 8) Backend/API Strategy

### Option 1: Swift client direct to Supabase tables

- **Pros**
  - Fast iteration.
  - Lower backend surface area.
  - Works well with strict RLS.
- **Cons**
  - Client owns more query logic.
  - Harder to enforce complex business workflows centrally.
- **Security**
  - Good if RLS complete and verified.
- **Complexity**
  - Low-medium.
- **Offline**
  - Needs local queue/caching strategy in app.
- **Privacy/App Store**
  - Clear if disclosures and data flow docs are accurate.

### Option 2: Edge Functions as full API layer

- **Pros**
  - Centralized business logic and validation.
  - Easier to evolve contracts.
- **Cons**
  - Higher ops complexity and latency.
  - More backend maintenance from day 1.
- **Security**
  - Strong, but service-role misuse risk if not strict.
- **Complexity**
  - Medium-high.
- **Offline**
  - Same app-side queue need.

### Option 3: Hybrid (recommended)

- **Direct client + RLS** for standard user CRUD.
- **Edge Functions** for privileged/cross-table operations:
  - account deletion
  - migration/import jobs
  - complex reconciliation tools
  - future admin/ops workflows

Recommendation:

- Use **Hybrid** for BudgetMeter MVP migration safety and long-term maintainability.

---

## 9) Sync Strategy

Candidate strategies:

- Online-only writes (simpler, weak offline UX).
- Local-first with sync queue (strong UX, more complexity).

Recommended MVP behavior:

1. **Phase 1-2**: online-first for migrated settings domains, with local fallback cache.
2. **Phase 3+ financial domains**:
   - local write + queued cloud sync when online
   - per-record `updated_at`
   - soft deletes via `deleted_at` tombstones
   - deterministic last-write-wins for MVP
   - conflict banner/logging for suspicious overlaps

Conflict principles (MVP):

- Single-user personal finance app: prefer simple LWW with timestamp and source metadata.
- Keep per-record `updated_at`, `deleted_at`.
- Track `client_record_id` and `last_synced_at` in sync metadata.
- Avoid destructive automatic merges during initial migration.

Multi-device considerations:

- If two devices edit same row, newest `updated_at` wins.
- Keep user-visible "last synced" status.
- Add audit telemetry for conflict frequency before advanced merge logic.

---

## 10) Migration Strategy

Safe migration path for existing local users:

1. Keep existing local Core Data untouched at first sign-in.
2. After sign-in, offer explicit action:
   - "Use this device data for your account" (upload)
   - or "Use account data on this device" (download when available)
3. Never auto-overwrite without confirmation.
4. Keep local snapshot safeguards before major import/export transitions.
5. During transition, preserve manual backup availability as fallback.
6. Include rollback path:
   - local snapshot restore
   - last known cloud snapshot pull
   - clear error messaging.

Handling existing manual backups:

- Treat `user_backups` as legacy recovery source.
- If structured sync not initialized, allow import-from-backup as one-time seeding tool.
- Do not delete legacy backup data until sync path proves stable in production.

---

## 11) What Happens To Backup & Restore

Transition recommendation:

- Keep Backup & Restore in product during migration phases.
- Re-label copy to reduce sync confusion (manual backup wording).
- As structured sync matures and data-loss risk is low:
  - demote backup UI prominence
  - eventually deprecate manual snapshot UX.
- Do not remove backup logic until:
  - sync reliability KPIs pass
  - migration cohorts pass
  - incident rate is acceptable.

---

## 12) User Experience Changes

Users should understand:

- Sign-in links data to their account identity.
- Data can follow them across devices once sync-enabled domains are active.
- Local storage may still be used for speed/offline.
- During transition, backup/restore and sync are different:
  - Sync: ongoing account persistence
  - Backup: manual recovery snapshot (legacy fallback)

UX clarity requirements:

- explicit status ("Synced", "Waiting to sync", "Last synced")
- no "instant cloud" promises unless true
- calm, non-technical copy in settings and onboarding.

---

## 13) Implementation Phases (Planning)

### Phase 0 — Architecture finalization

- **Goal**: Approve target data model, RLS strategy, migration order.
- **Files likely touched later**: planning docs only now.
- **Backend work later**: schema/RLS design reviews.
- **Swift work later**: none now.
- **Tests**: architecture checklist.
- **Risk**: low.

### Phase 1 — Profile/settings foundations

- **Goal**: Persist profile, onboarding completion, settings, notifications per user.
- **Likely iOS files**
  - `AuthService`
  - `OnboardingViewModel`
  - `SettingsViewModel`
  - `NotificationSettingsViewModel`
- **Backend/Supabase later**
  - `profiles`, `user_settings`, `notification_preferences` + RLS.
- **Tests**
  - sign-in bootstrap row creation
  - settings roundtrip
  - onboarding persistence.
- **Risk**: low-medium.

### Phase 2 — Goals/subscriptions/recurring sync

- **Goal**: Move medium-complexity financial domains.
- **Likely iOS files**
  - `SavingsGoalManager`
  - `SubscriptionManager`
  - `RecurringTransactionsViewModel` / manager layer
- **Backend later**
  - `savings_goals`, `subscriptions`, `recurring_transactions`.
- **Tests**
  - CRUD parity local vs cloud
  - multi-device basic checks.
- **Risk**: medium.

### Phase 3 — Categories and one-time financial entries

- **Goal**: Sync main income/expense category records and one-time events.
- **Likely iOS files**
  - `IncomeViewModel`
  - `ExpenseViewModel`
  - `CreateCategoryModal`
  - `FinancialCategoryWriteSupport`
- **Backend later**
  - `financial_categories` (+ optional `one_time_entries`).
- **Tests**
  - recurring/one-time separation integrity
  - duplicate/validation behavior.
- **Risk**: medium-high.

### Phase 4 — Bills/payments/snapshots + sync metadata

- **Goal**: Complete financial domain coverage and operational sync observability.
- **Likely iOS files**
  - `BillManager`, `BillsViewModel`
  - snapshot generation services.
- **Backend later**
  - `bills`, `bill_payments`, `financial_snapshots`, `user_devices/sync_metadata`.
- **Tests**
  - payment history integrity
  - derived snapshot consistency.
- **Risk**: medium-high.

### Phase 5 — Sync-first UX and resiliency

- **Goal**: add offline queue hardening, conflict handling, and user sync status UI.
- **Likely iOS files**
  - settings/account sync status surfaces
  - persistence/sync coordinator components.
- **Backend later**
  - optional conflict tooling / helper functions.
- **Tests**
  - offline -> reconnect replay
  - conflict and tombstone behavior.
- **Risk**: high.

### Phase 6 — Backup model transition

- **Goal**: Deprecate manual backup prominence after sync reliability is proven.
- **Likely iOS files**
  - `AccountBackupSettingsView`
  - `BackupService` integration points (transition mode only).
- **Backend later**
  - legacy backup retention policy decisions.
- **Tests**
  - migration cohort success
  - rollback paths still valid.
- **Risk**: medium.

---

## 14) Files Likely Involved (Future Work)

## iOS / Swift layers

- `budgetmeter.ios/CoreKit/Sources/Auth/AuthService.swift`
- `budgetmeter.ios/CoreKit/Sources/Persistence/PersistenceService.swift`
- `budgetmeter.ios/CoreKit/Sources/Services/SavingsGoalManager.swift`
- `budgetmeter.ios/CoreKit/Sources/Services/SubscriptionManager.swift`
- `budgetmeter.ios/CoreKit/Sources/Services/BillManager.swift`
- `budgetmeter.ios/CoreKit/Sources/Utilities/FinancialCategoryWriteSupport.swift`
- `budgetmeter.ios/Features/SettingsFeature/ViewModel/SettingsViewModel.swift`
- `budgetmeter.ios/Features/SettingsFeature/ViewModel/NotificationSettingsViewModel.swift`
- `budgetmeter.ios/Features/OnboardingFeature/ViewModel/OnboardingViewModel.swift`
- `budgetmeter.ios/Features/SettingsFeature/View/AccountBackupSettingsView.swift`
- `budgetmeter.ios/CoreKit/Sources/Backup/BackupService.swift` (transition period only)
- Supabase client abstraction layer (new, recommended)

## Supabase surface

- `supabase/migrations/*` (future structured tables + RLS)
- `supabase/functions/delete-account/index.ts` (future expansion for new tables)
- optional additional Edge Functions for migration/reconciliation tooling.

---

## 15) Testing Plan

## Security / RLS

- User A cannot read User B rows in every user-owned table.
- User A cannot update/delete User B rows.
- Anonymous user cannot access authenticated user data.

## Auth/bootstrap

- Sign-in creates/loads `profiles` and `user_settings`.
- Sign-out does not leak another user's cached data.

## Settings persistence

- Onboarding completion persists across reinstall/sign-in.
- Notification settings persist and rehydrate correctly.
- Theme/currency/language settings roundtrip correctly.

## Financial persistence

- CRUD parity checks for each migrated table.
- Multi-device smoke test (create on device A, visible on device B).
- Soft delete behavior (`deleted_at`) validated.

## Lifecycle

- Reinstall + sign-in restores account data.
- Delete account removes auth user and all user-owned rows.

## Offline (if enabled in phase)

- Local queue stores pending writes while offline.
- Reconnect replay order and idempotency validated.

## Migration

- Existing local-only user can upload device data safely.
- Existing cloud data is not accidentally overwritten.
- Manual backup fallback still works during transition.

---

## 16) Risks

- Data loss from incorrect migration order or destructive merge.
- Privacy/security exposure from incomplete RLS coverage.
- Cross-user access risk if any table misses `user_id` or policy.
- Duplicate records from weak client/server identity mapping.
- Sync conflicts producing surprising values.
- Offline queue complexity and replay bugs.
- Schema evolution overhead and backward compatibility.
- App Store privacy disclosure mismatch vs actual data behavior.
- User confusion if backup/sync messaging remains ambiguous during transition.

---

## 17) Final Recommendation

Recommended path:

- **Migrate now, but in phased form (Option C)**.
- **Move first**: `profiles`, `user_settings`, `notification_preferences`, onboarding state.
- **Move second**: `savings_goals`, `subscriptions`, `recurring_transactions`.
- **Move third**: categories + one-time entries + bills/payments + snapshots.
- Keep manual Backup & Restore as transition fallback until sync stability is proven.

What should not be touched yet:

- No immediate `BackupService` removal.
- No CloudKit hard removal before migration validation.
- No big-bang full real-time sync rollout.

Execution model recommendation:

- This planning and schema strategy is suitable for **Codex-level architecture/design work**.
- Actual implementation should be staged with review gates and likely use stronger-model review for schema, RLS, and migration safety checks before production rollout.

