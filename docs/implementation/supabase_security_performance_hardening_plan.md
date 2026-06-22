# Supabase Security & Performance Hardening Plan

## 1) Executive Summary

This document defines **pre-implementation hardening requirements** for Phase 1 of BudgetMeter's Supabase user-data architecture.

Target outcomes:

- secure per-user data boundaries from day one
- strict RLS on every user-owned table from day one
- minimal-but-correct indexing from day one
- sync-safety metadata sufficient for settings sync from day one
- no cross-user access paths
- no big-bang financial migration in this phase

This is planning only. No SQL, Swift, Core Data, or backend behavior changes are included here.

---

## 2) Phase 1 Scope Confirmation

## In scope (Phase 1 tables only)

- `profiles`
- `user_settings`
- `notification_preferences`

Phase 1 account/settings payload includes:

- onboarding completion
- theme
- currency
- language
- appearance
- notification toggles and schedule preferences
- related settings-level metadata

## Explicitly out of scope (Phase 1)

- financial transactions and financial categories migration
- savings goals
- bills / bill payments
- subscriptions
- recurring transactions
- full offline financial sync engine
- removal or replacement of `BackupService`
- CloudKit deactivation/removal

---

## 3) RLS Security Model

Mandatory requirements for all user-owned tables:

1. `user_id uuid not null` column exists.
2. RLS is enabled (`alter table ... enable row level security`).
3. No permissive public/anon policies.
4. CRUD policies enforce ownership by `auth.uid()`.
5. Service-role access is only used in trusted server-side functions.

Policy patterns (planning examples only):

- **SELECT**
  - `using (auth.uid() = user_id)`
- **INSERT**
  - `with check (auth.uid() = user_id)`
- **UPDATE**
  - `using (auth.uid() = user_id) with check (auth.uid() = user_id)`
- **DELETE** (if allowed for table)
  - `using (auth.uid() = user_id)`

Additional safety:

- Deny anonymous role access by default.
- Avoid broad policies like `using (true)`.
- Keep service-role keys out of client code paths.

---

## 4) User ID Safety

Key question: should client send `user_id`?

Recommended safest pattern:

1. **Database defaults `user_id` to `auth.uid()`** on insert for user-owned tables.
2. Client may send `user_id`, but policy + server enforcement must still validate ownership.
3. Add insert/update safeguards (policy and optional trigger) to reject mismatched `user_id`.

Practical rules:

- If `user_id` is `nil` -> insert should fail unless default fills it via `auth.uid()`.
- If `user_id != auth.uid()` -> fail with RLS/policy violation.
- Updates attempting to change row ownership should fail.

Preferred implementation posture:

- **Client should not need to set `user_id` explicitly** for normal writes.
- Ownership is derived from authenticated JWT context.

---

## 5) Table Constraints (Phase 1)

## `profiles`

Constraints:

- one row per auth user
- `user_id` primary key and FK to `auth.users(id)` with cascade delete
- `created_at` required with default now()
- `updated_at` required with default now()
- `email` can be nullable (Apple private relay / missing email scenarios)
- optional length checks for display fields

## `user_settings`

Constraints:

- one row per auth user (`user_id` pk/fk)
- `onboarding_completed boolean not null default false`
- `created_at` and `updated_at` required
- enum/check constraints recommended for:
  - `preferred_currency_code` (ISO code whitelist or reference table)
  - `selected_theme` (known values)
  - `appearance_mode` (light/dark/system)
  - `language_code` (supported app locales)
- boolean preference fields should be non-null with defaults

## `notification_preferences`

Constraints:

- one row per auth user (`user_id` pk/fk)
- all toggle fields non-null booleans with explicit defaults
- `created_at` and `updated_at` required
- `weekly_summary_time` and `daily_time` validated as valid `time` values
- optional `notification_permission_status` should be constrained to known values if stored

---

## 6) Index Strategy

## Phase 1 (required now)

- PK indexes on `user_id` (covers main lookup pattern)
- No extra `user_id` index needed if `user_id` is PK
- Optional `updated_at` index only if real query workload needs:
  - admin/ops recency scans
  - reconciliation jobs

Phase 1 guidance:

- keep index set minimal
- avoid speculative indexes without query evidence

## Future financial tables (recommended pattern, later)

- `(user_id, updated_at)`
- `(user_id, deleted_at)`
- `(user_id, type)`
- `(user_id, date)` / `(user_id, due_date)`
- `(user_id, client_record_id)` unique or near-unique mapping support
- `(user_id, is_active)` for recurring/subscription states

Required now vs later:

- **Now**: only what supports Phase 1 read/write paths.
- **Later**: domain-specific composite indexes introduced with each financial phase.

---

## 7) Updated At / Audit Strategy

Recommended production-safe timestamp handling:

- `created_at` set by DB default (`now()`) on insert.
- `updated_at` maintained server-side via trigger on update.
- Do not trust client clocks for authoritative row-version ordering.

`last_synced_at` placement:

- keep device-local `last_synced_at` in app state for UX/debug.
- do not require global DB `last_synced_at` in Phase 1.

Audit logging:

- full audit log table is not required in Phase 1.
- ensure standard timestamps + optional structured server logs are sufficient initially.
- revisit audit events for financial phases.

---

## 8) Sync Metadata Strategy

Minimal metadata for Phase 1 settings sync:

- authoritative server `updated_at`
- optional `client_updated_at` only for diagnostics (not authority)
- optional `sync_version` integer for future conflict tooling

Local app-side state (recommended now):

- pending sync flag per settings domain
- last successful sync timestamp
- last sync error (for UI/debug, optional)

Reserve for later (financial phases):

- richer per-record sync cursors
- device-scoped sync metadata tables
- tombstone lifecycle controls
- replay queues and reconciliation primitives

Principle:

- avoid overengineering Phase 1; implement only metadata required for settings safety.

---

## 9) Conflict Resolution Strategy

## Phase 1 settings

Recommended: **simple last-write-wins (LWW)**.

- Server `updated_at` is tie-break authority.
- If two devices update settings:
  - latest committed row wins
  - app rehydrates from server on next sync pull.

Reinstall behavior:

- after sign-in, app pulls `profiles` + `user_settings` + `notification_preferences`
- local cache is overwritten by server canonical state for these domains

## Future financial data

Financial records need stronger planning later because:

- edits may be multi-record and semantically linked
- deletes/tombstones can conflict with late updates
- derived aggregates and history consistency matter more

Future phases should evaluate per-entity conflict rules beyond plain LWW where needed.

---

## 10) Offline Behavior Strategy

Phase 1 target behavior:

1. Update local settings immediately for responsive UX.
2. If online, push to Supabase right away.
3. If offline, mark settings as dirty/pending.
4. On reconnect, push latest local settings.
5. Pull server state, reconcile, and clear pending state.

Required local state fields:

- `isPendingSync` (or equivalent per domain)
- `lastSuccessfulSyncAt`
- `lastSyncError` (optional but useful)

Scope guard:

- this is settings-only offline sync behavior
- do not extend to full financial offline sync in Phase 1

---

## 11) Delete Account Safety

Current state:

- existing `delete-account` Edge Function deletes:
  - `user_backup_versions`
  - `user_backups`
  - auth user

Future requirements (Phase 1 expansion):

- delete `profiles`
- delete `user_settings`
- delete `notification_preferences`
- preserve order and avoid orphan rows
- later phases must include all financial tables

Deletion strategy:

- continue using trusted service-role Edge Function for account deletion.
- perform explicit table deletions before `auth.admin.deleteUser`.
- keep idempotent behavior (safe if partially retried).

Test requirements:

- verify all Phase 1 rows removed for target user
- verify no cross-user rows touched
- verify auth user removed
- verify local app transitions to signed-out state

---

## 12) Privacy / Compliance Notes

As architecture evolves toward financial cloud persistence:

- update App Store privacy labels to match actual transmitted/stored data.
- avoid unnecessary PII and device fingerprinting fields.
- do not store excessive device identifiers.
- treat notification preferences as account-level preference data.
- treat future financial tables as sensitive personal data:
  - strict RLS
  - minimal query scope
  - clear retention/deletion behavior

Also ensure privacy-policy copy does not imply realtime sync before it exists.

---

## 13) Edge Function vs Direct Supabase Access

## Phase 1 recommendation

Use **direct Swift Supabase client access** for standard settings/profile CRUD, protected by strict RLS.

Why:

- simplest secure implementation for Phase 1
- low latency and low backend complexity
- easy to reason about with ownership policies

Use Edge Functions where privileged behavior is needed:

- account deletion (already present)
- bulk migration/import jobs
- privileged cleanup tasks
- future reconciliation/admin workflows

Recommended model for Phase 1:

- **Hybrid**, but mostly direct client + RLS for regular reads/writes.

---

## 14) Testing Matrix

## Security tests

- User A cannot select User B `profiles` row.
- User A cannot select User B `user_settings` row.
- User A cannot select User B `notification_preferences` row.
- User A cannot update/delete User B rows in all Phase 1 tables.
- User A cannot insert rows with `user_id = UserB`.
- Anonymous session cannot read/write Phase 1 tables.

## Functionality tests

- Sign-in creates or loads Phase 1 rows.
- Onboarding completion persists and restores.
- Notification preferences persist and restore.
- Theme/currency/language/appearance persist and restore.
- Reinstall + sign-in rehydrates settings correctly.
- Offline settings changes sync on reconnect.
- Delete account removes all Phase 1 rows and auth user.

## Performance tests

- Fetch by `user_id` is consistently fast.
- No full-table scans for standard app flows.
- Query plans use PK/index paths as expected.
- No unnecessary indexes causing write overhead in Phase 1.

---

## 15) Implementation Readiness Checklist

Before Phase 1 coding starts, all must be true:

- [ ] Phase 1 schema shape approved (`profiles`, `user_settings`, `notification_preferences`)
- [ ] RLS policy patterns approved for CRUD ownership
- [ ] `updated_at` server-side strategy approved (trigger/default approach)
- [ ] User ID anti-spoofing strategy approved
- [ ] Swift sync flow (online + offline pending state) approved
- [ ] Delete-account expansion plan approved for new tables
- [ ] Test plan approved (security + functionality + performance)
- [ ] Rollback and incident response notes documented

---

## 16) Recommended Phase 1 Implementation Scope

Readiness status:

- **Architecture is ready for Phase 1 implementation planning gate**, pending explicit schema/RLS review sign-off.

Exact next implementation step:

1. Draft Phase 1 migration spec (not code yet) for:
   - `profiles`
   - `user_settings`
   - `notification_preferences`
   - constraints + RLS + timestamp trigger pattern
2. Review and approve policy matrix and test cases.
3. Then implement in small commits with security tests first.

Files/migrations to create next (implementation phase, later):

- new Supabase migrations for Phase 1 tables/policies/triggers
- Swift settings sync service layer (new abstraction)
- targeted updates in:
  - `AuthService`
  - `OnboardingViewModel`
  - `SettingsViewModel`
  - `NotificationSettingsViewModel`
- update `supabase/functions/delete-account/index.ts` to include Phase 1 tables

Still do **not** touch yet:

- financial-table migrations
- `BackupService` removal
- CloudKit removal
- full financial offline sync engine
- broad runtime behavior changes outside Phase 1 scope

