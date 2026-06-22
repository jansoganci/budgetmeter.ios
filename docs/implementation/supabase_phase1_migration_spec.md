# Supabase Phase 1 Migration Specification

## Implementation Status

- Phase 1 migrations created:
  - `supabase/migrations/0004_phase1_profiles_settings_notifications.sql`
  - `supabase/migrations/0005_phase1_updated_at_triggers.sql`
- RLS implemented for:
  - `profiles`
  - `user_settings`
  - `notification_preferences`
- Shared `updated_at` trigger function implemented and attached to all three Phase 1 tables.
- Delete-account cleanup updated to remove:
  - `notification_preferences`
  - `user_settings`
  - `profiles`
  - (and existing backup tables), before auth user deletion.
- Swift integration started for account/settings tables.
- Financial data migration not started yet.

## Swift Integration Status

- Phase 1 Swift service added for `profiles`, `user_settings`, and `notification_preferences`.
- Sign-in bootstrap added to load/create Phase 1 account rows.
- `user_settings` sync started for onboarding, currency, theme, appearance, and language.
- `notification_preferences` sync started for account-level notification intent and times.
- Financial sync not started.
- `BackupService` is still retained.

## 1) Purpose

This document defines the **exact Phase 1 Supabase migration specification** before any SQL is written.

It specifies:

- table schemas
- constraints
- RLS policy intent
- user ownership enforcement
- timestamp trigger strategy
- index strategy
- delete-account update requirements
- security/functional/performance tests

This is planning/spec only; no migration SQL or runtime implementation is included.

---

## 2) Scope

## In Scope

- `profiles`
- `user_settings`
- `notification_preferences`
- `updated_at` trigger strategy
- RLS policy design
- minimal index design
- delete-account function update requirements
- Phase 1 test plan

## Out of Scope

- financial transactions
- financial categories
- savings goals
- subscriptions
- bills / bill payments
- recurring transactions
- full sync queue infrastructure
- `BackupService` removal
- CloudKit deactivation/removal

---

## 3) Existing Supabase State

Current repository Supabase state (from `supabase/migrations/*` and `supabase/functions/delete-account/index.ts`):

- Existing tables:
  - `user_backups` (latest manual backup row)
  - `user_backup_versions` (history snapshots)
- Existing RLS:
  - owner-only CRUD with `auth.uid() = user_id` on backup tables
- Existing trigger pattern:
  - `capture_user_backup_version()` manages `updated_at`, `created_at`, version insertions
- Existing account deletion:
  - Edge Function deletes `user_backup_versions`, then `user_backups`, then auth user

What must be added for Phase 1:

- new tables:
  - `profiles`
  - `user_settings`
  - `notification_preferences`
- RLS policies for each Phase 1 table
- shared `updated_at` trigger function usage plan
- delete-account function expansion to include new Phase 1 tables

---

## 4) Proposed Table: `profiles`

## Schema Plan

- `user_id uuid primary key references auth.users(id) on delete cascade`
- `email text null`
- `display_name text null`
- `provider text null` (optional; informational only)
- `created_at timestamptz not null default now()`
- `updated_at timestamptz not null default now()`

## Constraints

- PK uniqueness on `user_id` (one profile row per auth user)
- optional check on `provider` allowed values (e.g. `apple`, `email`) if used
- `created_at` immutable by convention (no update path from client)

## Indexes

- PK index on `user_id` is sufficient for Phase 1
- no extra `updated_at` index required initially

## RLS Policy Intent

- SELECT: user can read only own row
- INSERT: user can insert only own row
- UPDATE: user can update only own row and cannot transfer ownership
- DELETE: user delete optional (can be disallowed; account deletion handles cleanup)

## Row Creation Strategy

Two options:

1. Client upsert after sign-in
2. DB trigger on auth user creation

Recommended safest MVP approach:

- **Client upsert on sign-in** (idempotent) with strict RLS.
- Rationale: simpler rollout, explicit app control, no auth trigger complexity in Phase 1.

---

## 5) Proposed Table: `user_settings`

## Schema Plan

- `user_id uuid primary key references auth.users(id) on delete cascade`
- `onboarding_completed boolean not null default false`
- `preferred_currency_code text not null default 'USD'`
- `selected_theme text not null default 'default'`
- `appearance_mode text not null default 'system'`
- `language_code text not null default 'en'`
- `biometric_enabled boolean null` (optional; see below)
- `premium_theme_choice text null` (optional cached preference only)
- `created_at timestamptz not null default now()`
- `updated_at timestamptz not null default now()`

## Column Analysis

| Column | Purpose | Default | Nullability | Allowed Values / Constraint | Current App Source |
|---|---|---|---|---|---|
| `onboarding_completed` | Persist onboarding completion per account | `false` | Not null | boolean | `@AppStorage("hasCompletedOnboarding")` |
| `preferred_currency_code` | Currency preference | `USD` | Not null | ISO code whitelist check | `AppSettings.preferredCurrencyCode` |
| `selected_theme` | Theme key preference | `default` | Not null | app-supported theme set check | `AppSettings.selectedTheme` |
| `appearance_mode` | light/dark/system mode | `system` | Not null | check in (`light`,`dark`,`system`) | `UserDefaults.AppearanceMode` |
| `language_code` | UI language | `en` | Not null | check against supported locales | `UserDefaults.LanguageMode` / localization manager |
| `biometric_enabled` | account-level preference mirror (optional) | `null` | Nullable | boolean if present | `AppSettings.isBiometricEnabled` + local fallback logic |
| `premium_theme_choice` | optional UX preference cache | `null` | Nullable | text check if used | theme manager / premium UI state |

## Include vs Exclude in Phase 1

- Include now:
  - onboarding/currency/theme/appearance/language
- Include cautiously:
  - `biometric_enabled` as preference mirror only (not security truth)
- Exclude now:
  - broad accessibility flags unless currently needed in account sync
- Note:
  - StoreKit entitlement remains authoritative; `user_settings` should not become purchase authority.

---

## 6) Proposed Table: `notification_preferences`

## Schema Plan

- `user_id uuid primary key references auth.users(id) on delete cascade`
- `daily_encouragement_enabled boolean not null default false`
- `weekly_summary_enabled boolean not null default false`
- `milestones_enabled boolean not null default true`
- `spending_alerts_enabled boolean not null default true`
- `daily_time time null`
- `weekly_summary_time time null`
- `permission_status text null` (optional; see analysis)
- `created_at timestamptz not null default now()`
- `updated_at timestamptz not null default now()`

## Permission Status Storage Analysis

Should iOS permission status be stored in Supabase?

- Recommendation: **Do not make it authoritative account data in Phase 1**.
- Reason: notification authorization is device-level OS state, not account-global truth.
- If stored, use only as advisory telemetry/debug field (nullable), never as scheduling authority.

## Account-Level vs Device-Level

Account-level preferences (store in Supabase):

- enabled/disabled intent toggles
- preferred reminder times

Device-local state (keep local):

- actual OS permission authorization status
- per-device notification delivery outcomes

---

## 7) RLS Policy Matrix

Policy intent (SQL-like, not final SQL):

## `profiles`

- SELECT: `auth.uid() = user_id`
- INSERT: `auth.uid() = user_id`
- UPDATE: `auth.uid() = user_id` and `new.user_id = old.user_id`
- DELETE: optional; if allowed, only own row

## `user_settings`

- SELECT: own row only
- INSERT: only for own `auth.uid()`
- UPDATE: own row only; no ownership change
- DELETE: usually not needed for client; can be disallowed (cleanup via account deletion)

## `notification_preferences`

- SELECT: own row only
- INSERT: only own row
- UPDATE: own row only; no ownership change
- DELETE: usually not needed for client; can be disallowed

Global requirements:

- no anonymous access
- no cross-user row operations
- no permissive wildcard policies

---

## 8) User ID Enforcement Strategy

Decisions:

- **DB should default `user_id` to `auth.uid()`** where possible.
- Client may send `user_id`, but policies must reject mismatches.
- Add explicit prevention of ownership change during update.

Recommended implementation pattern:

1. `user_id` PK/FK in each table.
2. INSERT policy with `with check (auth.uid() = user_id)`.
3. Optional `before insert/update` guard trigger to hard-reject mismatched `user_id`.
4. UPDATE policy requiring `auth.uid() = user_id` and preventing `user_id` mutation.

Handling mismatches:

- mismatched `user_id` insert/update fails with RLS/policy violation.
- nil/absent user context fails because `auth.uid()` is null.

---

## 9) Updated At Trigger Strategy

Recommendation:

- Use **one shared `set_updated_at()` trigger function** reused across Phase 1 tables.
- Attach per-table `before update` trigger.

Behavior:

- `created_at`: set once on insert via default now(), never modified.
- `updated_at`: server-side set on any successful update.

Why server-side timestamps:

- avoids untrusted client clock skew
- gives deterministic conflict ordering for LWW
- reduces client complexity

---

## 10) Index Strategy

Phase 1 exact index set:

- PK indexes on `user_id` for all three tables (sufficient for app access pattern).
- No extra secondary indexes required at launch.
- Add `updated_at` index only if observability/admin queries require it after measurement.

Guidance:

- avoid unnecessary indexes in single-row-per-user tables.
- prioritize write simplicity and predictable PK lookups.

Future financial indexes (later, not Phase 1):

- `(user_id, updated_at)`
- `(user_id, deleted_at)`
- `(user_id, type)`
- `(user_id, date/due_date)`
- `(user_id, client_record_id)`
- `(user_id, is_active)`

---

## 11) Delete Account Function Update Plan

Current function deletes:

1. `user_backup_versions`
2. `user_backups`
3. auth user

Required Phase 1 update plan (later implementation):

1. delete `notification_preferences` for current user
2. delete `user_settings` for current user
3. delete `profiles` for current user
4. keep deleting `user_backup_versions`
5. keep deleting `user_backups`
6. delete auth user last

Safety requirements:

- filter every delete by authenticated `user.id`
- idempotent behavior for retries
- no broad delete queries
- service-role use restricted to trusted function path

---

## 12) App Integration Plan Preview (No Implementation)

Planned app flow later:

- On sign-in:
  - resolve auth session
  - upsert/load `profiles`, `user_settings`, `notification_preferences`
- On settings change:
  - update local state immediately
  - push Supabase when online
- On reinstall + sign-in:
  - fetch and rehydrate settings from Supabase
- Offline:
  - keep local source active
  - sync pending changes when connectivity returns

Phase 1 does not implement full financial sync queue behavior.

---

## 13) Security Test Plan

Required tests:

1. User A cannot select User B `profiles`.
2. User A cannot select/update User B `user_settings`.
3. User A cannot insert `notification_preferences` using User B `user_id`.
4. Anonymous role cannot read/write any Phase 1 table.
5. Ownership cannot be changed by update.
6. Delete account removes only current user rows.

---

## 14) Functional Test Plan

Required tests:

1. Sign-in creates or loads Phase 1 rows idempotently.
2. Onboarding completion persists across sessions/devices.
3. Currency preference persists.
4. Theme preference persists.
5. Language preference persists.
6. Appearance mode persists.
7. Notification preferences persist.
8. Reinstall + sign-in restores account settings.

---

## 15) Performance Test Plan

Phase 1 performance checks:

1. Single-row lookup by `user_id` remains fast.
2. No full-table scans in normal app queries.
3. PK index usage verified in query plans.
4. No unnecessary joins for Phase 1 settings fetch/update.
5. Write latency remains stable with minimal index footprint.

---

## 16) Risks / Open Questions

Must be resolved before SQL implementation:

1. Final allowed values for:
   - `selected_theme`
   - `language_code`
   - `preferred_currency_code` validation strategy
2. Whether client-side DELETE is permitted on Phase 1 tables or server-only cleanup.
3. Whether `permission_status` is needed at all in cloud table.
4. Whether to include `biometric_enabled` in cloud settings now or postpone.
5. Final upsert ownership enforcement shape (policy-only vs policy + trigger).
6. Whether profile bootstrap should be client-upsert only or include auth trigger.

---

## 17) Final Recommendation

Readiness:

- **Phase 1 migration is ready to implement after this spec**, pending final sign-off on open questions above.

Exact next migration file(s) to create (implementation step, later):

1. `supabase/migrations/0004_phase1_profiles_settings_notifications.sql`
   - create three tables, constraints, RLS, indexes
2. `supabase/migrations/0005_phase1_updated_at_triggers.sql`
   - shared trigger function + table trigger bindings

Recommended execution model:

- SQL/RLS implementation can be done by **Codex** with review.
- If you want maximum safety on RLS correctness and migration order, use **Codex + stronger-model review pass** before applying to production.

Must not be touched yet:

- financial migration tables/policies
- `BackupService` removal
- CloudKit removal
- full sync queue implementation
- broad app behavior changes beyond Phase 1 settings scope

