# Supabase Phase 2B Savings Goals Migration Spec

## 1. Purpose

This document defines the **exact planning/specification** for future Supabase sync of BudgetMeter savings goals.

It is **spec only**:

- no Swift implementation
- no SQL migration
- no Supabase function changes
- no Core Data changes
- no sync implementation
- no production behavior changes

The goal is to define the future `savings_goals` table, ownership rules, sync behavior, migration strategy, and test plan before any implementation begins.

---

## 2. Scope

### In scope

- `savings_goals` table design
- RLS policy intent
- constraints
- indexes
- `updated_at` trigger strategy
- delete-account future update requirements
- local Core Data mapping
- local sync metadata requirements
- initial migration strategy
- test plan

### Out of scope

- Swift implementation
- actual SQL migration
- financial categories
- one-time income/expense
- subscriptions
- bills
- bill payments
- recurring transactions
- financial snapshots
- `BackupService` removal

---

## 3. Current Local SavingsGoal Model

Current local savings-goal persistence is defined in the Core Data model and used by the savings-goal manager/view layer.

### 3.1 Core Data entity

- Entity name: `SavingsGoal`
- Source: `budgetmeter.ios/BudgetMeter.xcdatamodeld/BudgetMeter 3.xcdatamodel/contents`

### 3.2 Current fields

| Field | Core Data Type | Optional | Default | Notes |
|---|---|---|---|---|
| `id` | UUID | Yes | none | Local stable identity today. |
| `name` | String | Yes | none | Required by app behavior, but technically optional in Core Data. |
| `targetAmount` | Double | Yes | `0` | Goal target amount. |
| `currentAmount` | Double | Yes | `0` | Current saved amount. |
| `targetDate` | Date | Yes | none | Optional target date. |
| `emoji` | String | Yes | none | Optional display emoji. |
| `imageData` | Binary | Yes | none | Present locally but not used in backup payload or current sync plan. |
| `colorHex` | String | Yes | none | Optional UI color. |
| `priority` | Integer 16 | Yes | `0` | Used for deterministic ordering. |
| `isArchived` | Boolean | Yes | `false` | Archive state. |
| `archivedDate` | Date | Yes | none | Set when archived. |
| `completedDate` | Date | Yes | none | Set when goal reaches completion. |
| `notes` | String | Yes | none | Free-form notes. |
| `category` | String | Yes | none | Label only, not relational. |
| `monthlyContribution` | Double | Yes | `0` | Stored value; app also calculates required contribution dynamically. |
| `milestones` | String | Yes | none | Present locally, not included in backup payload, not actively used by manager logic. |
| `createdAt` | Date | Yes | none | Set on creation by manager. |
| `lastModified` | Date | Yes | none | Updated by manager on mutations. |
| `cloudKitRecordID` | String | Yes | none | Legacy CloudKit-era field; not needed for Supabase sync. |

### 3.3 Archive behavior

Current behavior from `SavingsGoalManager`:

- archive sets:
  - `isArchived = true`
  - `archivedDate = Date()`
  - `lastModified = Date()`
- unarchive sets:
  - `isArchived = false`
  - `archivedDate = nil`
  - `lastModified = Date()`

Archive is a business-state flag, not deletion.

### 3.4 Completion behavior

Current behavior:

- `markAsCompleted(id:)` sets:
  - `currentAmount = targetAmount`
  - `completedDate = Date()`
  - `lastModified = Date()`
- `addMoney(...)` auto-completes when `currentAmount >= targetAmount`
- `withdrawMoney(...)` clears `completedDate` if the goal falls back below target

Completion is also business state, not deletion.

### 3.5 Target date behavior

- `targetDate` is optional.
- Pace and required monthly contribution logic depend on it.
- Goals without a target date are valid locally and should remain valid remotely.

### 3.6 `lastModified` behavior

`lastModified` is already maintained on the important mutations:

- create
- update
- add money
- withdraw money
- archive
- unarchive
- complete
- quick-goal upsert

This makes `SavingsGoal` a good sync candidate.

### 3.7 Deletion behavior

Current delete behavior is hard delete:

- `SavingsGoalManager.deleteGoal(id:)` uses `context.delete(goal)`

That is acceptable locally today, but not appropriate for future multi-device sync. Phase 2B should plan for soft delete via `deleted_at` remotely and tombstone-based sync behavior.

### 3.8 Files likely involved later

These files are likely to be involved in a future implementation, but are **not** to be changed now:

- `budgetmeter.ios/CoreKit/Sources/Services/SavingsGoalManager.swift`
- `budgetmeter.ios/Features/SavingsGoalsFeature/ViewModel/SavingsGoalsViewModel.swift`
- `budgetmeter.ios/Features/SavingsGoalsFeature/View/SavingsGoalInputView.swift`
- `budgetmeter.ios/Features/SavingsGoalsFeature/View/SavingsGoalDetailView.swift`
- `budgetmeter.ios/CoreKit/Sources/Backup/BackupSerializer.swift`
- `budgetmeter.ios/CoreKit/Sources/Backup/RestoreImporter.swift`
- `supabase/functions/delete-account/index.ts`
- future Supabase financial sync service files

---

## 4. Proposed Supabase Table: `savings_goals`

This section defines the future schema plan only.

### 4.1 Required columns

- `id uuid primary key default gen_random_uuid()`
- `user_id uuid not null references auth.users(id) on delete cascade`
- `client_record_id text not null`
- `name text not null`
- `target_amount numeric not null`
- `current_amount numeric not null default 0`
- `target_date date null`
- `emoji text null`
- `color_hex text null`
- `priority integer null`
- `is_archived boolean not null default false`
- `archived_date timestamptz null`
- `completed_date timestamptz null`
- `notes text null`
- `category_label text null`
- `monthly_contribution numeric null`
- `created_at timestamptz not null default now()`
- `updated_at timestamptz not null default now()`
- `deleted_at timestamptz null`

### 4.2 Additional field analysis

Current local-only fields that should **not** be added to the initial remote schema:

- `imageData`
  - binary UI/media data
  - not present in backup payload
  - increases migration and storage risk
- `milestones`
  - present in Core Data but not represented in backup payload or manager logic
  - unclear product contract
- `cloudKitRecordID`
  - legacy field, not relevant to Supabase

### 4.3 Additional columns not required now

Not required in the first migration spec:

- `sync_version`
  - useful later if optimistic conflict tooling is needed
  - not necessary for MVP Phase 2B
- row-level `currency_code`
  - current app mostly uses account-level preferred currency
  - savings goals do not currently store per-goal currency

### 4.4 Data type notes

- `target_amount`, `current_amount`, and `monthly_contribution` should be `numeric`, not float, to avoid financial rounding drift.
- `target_date` should be a `date`, not `timestamptz`, because the app uses it as a calendar date rather than an instant in time.
- `archived_date` and `completed_date` should be `timestamptz`, because they represent mutation events.

---

## 5. Constraints

### Required constraints

- unique `(user_id, client_record_id)`
- `target_amount >= 0`
- `current_amount >= 0`
- `monthly_contribution >= 0` if not null
- `btrim(name) <> ''`

### Safe optional constraints

- `color_hex` format check only if kept permissive enough for existing app values
  - example intent: allow `#RRGGBB` and `#RRGGBBAA`
- `priority >= 0` if enforced

### Constraints that should stay loose for MVP

- Do **not** over-constrain `priority` beyond non-negative unless product semantics are finalized.
- Do **not** require `completed_date` when `current_amount >= target_amount`.
  - Current app can move above/below target via ordinary updates.
- Do **not** require `archived_date` whenever `is_archived = true`.
  - It is desirable, but the migration should tolerate imperfect legacy/import cases if needed.

### Recommended logic checks

Useful but still conservative:

- if `deleted_at is not null`, row is considered deleted regardless of archive/completion state
- `name` cannot be empty after trimming
- non-negative numeric values only

### Why not constrain more aggressively

Current local app is flexible:

- many fields are optional in Core Data
- completion can be reversed by withdrawal
- archive is independent from completion

The remote schema should preserve that flexibility instead of enforcing a stricter model than the app already uses.

---

## 6. RLS Policy Intent

### Requirements

- RLS enabled
- authenticated users can `SELECT` only their own savings goals
- authenticated users can `INSERT` only their own savings goals
- authenticated users can `UPDATE` only their own savings goals
- authenticated users can soft-delete only their own savings goals if client delete is allowed
- no anonymous access
- no cross-user access

### Policy intent by operation

#### `SELECT`

- allow only rows where `(select auth.uid()) = user_id`

#### `INSERT`

- allow only rows where inserted `user_id` belongs to current authenticated user

#### `UPDATE`

- allow only rows owned by current user
- must include both:
  - `USING`
  - `WITH CHECK`
- prevents ownership transfer on update

#### `DELETE`

Preferred MVP posture:

- **do not allow client hard delete**
- use soft delete through `UPDATE deleted_at = now()`
- reserve hard delete for:
  - account deletion
  - trusted cleanup/admin paths if ever needed

### Recommendation

For Phase 2B MVP:

- enable RLS
- permit owner-only `SELECT`, `INSERT`, `UPDATE`
- do **not** expose client hard `DELETE`

---

## 7. User ID Enforcement

### Default behavior

Recommended:

- `user_id` defaults to `auth.uid()` in the future migration

### Insert protection

Insert must prevent spoofing:

- if client omits `user_id`, DB default should fill it from authenticated context
- if client provides mismatched `user_id`, RLS `WITH CHECK` must reject it

### Update protection

Update must prevent ownership transfer:

- owner-only `USING`
- owner-only `WITH CHECK`
- `user_id` should never change through normal client writes

### Trigger enforcement

Trigger enforcement for ownership is optional, not required for MVP, if:

- RLS policies are strict
- client hard delete is disallowed

Recommended posture:

- rely on strict RLS first
- add ownership trigger only if later testing shows a meaningful gap or complexity around defaults

---

## 8. `updated_at` Strategy

Use the existing shared trigger pattern already introduced in:

- `supabase/migrations/0005_phase1_updated_at_triggers.sql`

Current shared function:

- `public.set_updated_at()`

### Phase 2B requirement

Future migration should:

- reuse `public.set_updated_at()` if it still exists
- attach a new `before update` trigger to `public.savings_goals`

### Server timestamp rules

- server controls `updated_at`
- `created_at` is set once and remains stable
- client must not be treated as authoritative for remote `updated_at`

This matches the Phase 1 timestamp model and keeps conflict handling consistent.

---

## 9. Index Strategy

### Required indexes

1. unique `(user_id, client_record_id)`
2. `(user_id, updated_at desc)`
3. `(user_id, deleted_at)`
4. `(user_id, is_archived)`
5. `(user_id, target_date)`

### Why each index is needed

#### unique `(user_id, client_record_id)`

- identity matching for sync
- duplicate prevention
- required for safe local/remote reconciliation

#### `(user_id, updated_at desc)`

- incremental sync pull by most recently changed rows
- reconciliation and sync catch-up scans

#### `(user_id, deleted_at)`

- efficient tombstone fetches
- sync cleanup queries
- avoids full-table scans for deleted rows

#### `(user_id, is_archived)`

- supports archive filtering
- matches current app behavior of active vs archived goal views

#### `(user_id, target_date)`

- supports target-date sorting/filtering
- useful for pace/deadline-oriented screens

### Not required initially

- no separate index on `completed_date` yet
- no index on `priority` yet

Those can be added later if production query patterns justify them.

---

## 10. Core Data to Supabase Mapping

| Local `SavingsGoal` field | Supabase column | Notes |
|---|---|---|
| `id` | `client_record_id` | Existing local UUID is the best seed for stable sync identity. |
| remote row id | `id` | New server-generated row ID, distinct from client identity. |
| `name` | `name` | Remote should require non-blank value. |
| `targetAmount` | `target_amount` | Convert `Double` to `numeric`. |
| `currentAmount` | `current_amount` | Convert `Double` to `numeric`. |
| `targetDate` | `target_date` | Store as calendar date. |
| `emoji` | `emoji` | Optional text. |
| `colorHex` | `color_hex` | Optional text; keep format flexible. |
| `priority` | `priority` | Local Int16 to remote integer. |
| `isArchived` | `is_archived` | Archive business state. |
| `archivedDate` | `archived_date` | Archive event timestamp. |
| `completedDate` | `completed_date` | Completion event timestamp. |
| `notes` | `notes` | Optional free text. |
| `category` | `category_label` | String label only; no FK. |
| `monthlyContribution` | `monthly_contribution` | Convert `Double` to `numeric`. |
| `createdAt` | `created_at` | Preserve original creation time where available. |
| `lastModified` | local comparison source; maps operationally to `updated_at` | Remote `updated_at` remains server-controlled. |
| future local tombstone | `deleted_at` | Not present in current local model; required for sync-safe deletes later. |

### Explicit exclusions from initial remote schema

| Local field | Action | Reason |
|---|---|---|
| `imageData` | exclude | Binary UI/media payload, not in current backup contract. |
| `milestones` | exclude | Dormant/unclear field, not used in active manager logic. |
| `cloudKitRecordID` | exclude | Legacy field, not part of Supabase identity strategy. |

---

## 11. Local Sync Metadata Requirements

### Minimum future local metadata needed

Per synced savings goal, future local state should support:

- `client_record_id`
- `sync_status`
- `last_synced_at`
- `remote_updated_at`
- `deleted_at` tombstone
- optional `sync_error`

### Can existing `id` be reused as `client_record_id`?

Yes, for `SavingsGoal`, that is the recommended starting point.

Reason:

- local manager already assigns `UUID()` on create
- backup serializer already uses goal `id` as `clientRecordID`
- goals are user-created, not seeded per install

### Does Core Data need a lightweight migration later?

Yes, if sync metadata is stored directly on the entity.

Current `SavingsGoal` does not have:

- `client_record_id`
- tombstone state
- sync state fields
- remote timestamp fields

### Where should sync metadata live?

Two options:

#### Option A: add sync metadata columns directly to `SavingsGoal`

Pros:

- simple fetch/update path
- easier per-record sync logic
- fewer joins/lookups

Cons:

- requires Core Data model migration

#### Option B: separate local sync metadata table/entity

Pros:

- financial domain model stays cleaner

Cons:

- more coordination complexity
- harder lookup logic
- extra failure modes on row linkage

### Recommended safest approach

Use **Option A** later:

- add sync metadata directly to `SavingsGoal`

Reason:

- `SavingsGoal` is a low-relationship entity
- direct metadata reduces implementation complexity
- lower risk than building an indirection layer for the first synced financial entity

---

## 12. Initial Migration Strategy

### Case A: local savings goals exist, remote empty

- upload local goals as initial cloud state
- preserve original `createdAt` if available
- use local UUID-derived `client_record_id`
- mark local rows synced after success

### Case B: remote exists, local empty

- download remote goals into local Core Data
- create local rows using remote `client_record_id` mapping
- preserve archive/completion state

### Case C: both local and remote exist

- do **not** blindly merge
- match by `(user_id, client_record_id)` remotely and `client_record_id` locally
- compare:
  - local `lastModified`
  - remote `updated_at`
- avoid creating duplicates for the same logical goal

### Duplicate prevention rule

`client_record_id` is the primary dedupe key.

This is much safer for savings goals than for seeded categories because savings goals are purely user-created rows.

### Backup fallback

Keep `BackupService` available during the transition. It remains the recovery path if first-sync behavior is wrong.

---

## 13. Offline Sync Behavior

Planned MVP behavior:

1. save locally first
2. mark record pending sync
3. upload when online
4. on success:
   - store `remote_updated_at`
   - store `last_synced_at`
   - mark synced
5. on failure:
   - keep pending
   - optionally record `sync_error`
6. retry later

No implementation is included in this document.

---

## 14. Conflict Resolution

### MVP rule

Use last-write-wins with tombstone protection.

Recommended comparison:

- local side: `lastModified`
- remote side: `updated_at`

### Special rules

- `deleted_at` tombstones take precedence over silent resurrection
- archive state is **not** deletion
- completed state is **not** deletion

### Why this is acceptable for savings goals

- entity is standalone
- no child tables
- low relationship complexity
- mutation semantics are understandable and user-visible

---

## 15. Delete / Archive Behavior

### Archive

- archive uses `is_archived`
- archive timestamp uses `archived_date`
- archive remains a normal synced update

### Completion

- completion uses `completed_date`
- completion remains a normal synced update

### Delete

- client sync path should use `deleted_at`
- client hard delete should not be used in MVP sync flow

### Account deletion

- account deletion can hard-delete all `savings_goals` rows by `user_id`

---

## 16. Delete Account Update Plan

Future delete-account work should:

- delete `savings_goals` rows by `user_id`
- do so before auth user deletion
- remain idempotent
- avoid broad unscoped delete queries
- preserve existing Phase 1 and backup cleanup behavior

Recommended placement in future delete order:

1. `savings_goals`
2. existing Phase 1 tables and backup tables according to final cleanup order
3. auth user last

Because `savings_goals` has no child rows, it is straightforward to add to account deletion safely.

---

## 17. Swift Integration Preview

This is not implementation, only a preview of future responsibilities.

Future savings-goal sync service should:

- load remote savings goals after sign-in
- upload local unsynced savings goals
- sync create/update/archive/delete
- resolve remote changes into local Core Data
- preserve `BackupService` as fallback during transition

Expected responsibilities later:

- initial bootstrap reconciliation
- per-record upload/download
- pending-sync retry handling
- tombstone handling
- duplicate prevention using `client_record_id`

Phase 1 Swift integration must remain untouched while this spec is being prepared.

---

## 18. Test Plan

### Security tests

- User A cannot read User B savings goals
- User A cannot insert with User B `user_id`
- User A cannot update User B row
- anonymous users cannot access `savings_goals`

### Functional tests

- create savings goal syncs
- update amount syncs
- archive syncs
- completion syncs
- soft delete syncs
- reinstall + sign-in restores goals
- offline create syncs when online later
- duplicate prevention via `client_record_id`

### Migration tests

- local-only to remote
- remote-only to local
- both local and remote
- archived goals preserved
- completed goals preserved
- target-date and note fields preserved

### Timestamp/identity tests

- server updates `updated_at` on write
- `created_at` remains stable
- same `client_record_id` does not create duplicate rows

---

## 19. Risks / Open Questions

These items should be settled before writing the real migration or Swift sync code:

1. exact local sync metadata storage
   - direct fields on `SavingsGoal` vs separate metadata entity
2. hard delete vs soft delete UI behavior
   - current UI language says permanent delete, but sync needs tombstones
3. amount precision
   - confirm numeric precision/scale expectations for savings amounts
4. existing UUID format
   - likely safe, but verify no malformed legacy rows exist
5. date timezone handling
   - `target_date` should be date-only; mutation timestamps should be UTC-aware server values
6. sync retry mechanism
   - background retry, sign-in retry, or app-launch retry strategy still needs design
7. local fields excluded from remote
   - `imageData`, `milestones`, `cloudKitRecordID` should stay excluded unless product requirements change

---

## 20. Final Recommendation

### Is `savings_goals` ready for migration implementation after this spec?

Yes, `savings_goals` is the best-prepared first Phase 2 financial table **from an architecture standpoint**.

It is ready for:

- migration design review
- RLS review
- implementation planning

It is **not** ready for direct implementation until the remaining open questions above are explicitly accepted.

### Exact next step after this spec

Next step:

- create the actual Phase 2B SQL migration draft and RLS policy draft for `savings_goals`
- keep it isolated from Swift work
- review before execution

### Recommended owner for the next implementation step

- Supabase migration + RLS draft:
  - **stronger-model reviewed**
- Swift/Core Data sync implementation after schema approval:
  - **Codex or Cursor**

### What must not be touched yet

- current Phase 1 Swift integration work
- Swift savings-goal sync implementation
- Core Data schema changes
- Supabase Edge Functions
- production delete behavior
- other financial entities

This spec should be treated as the handoff point for the future `savings_goals` migration design, not as permission to start broad Phase 2 sync work.

---

## Swift Integration Status

Implementation status as of 22 June 2026:

- Core Data sync metadata added to `SavingsGoal`
  - `syncStatus`
  - `lastSyncedAt`
  - `remoteUpdatedAt`
  - `deletedAt`
  - `lastSyncError`
- Supabase savings-goal sync service added
- sign-in bootstrap sync added after existing Phase 1 account/settings bootstrap
- create/update/archive/complete/delete sync wiring started in `SavingsGoalManager`
- local delete now uses tombstone-oriented behavior for savings goals
- `BackupService` retained
- manual Backup & Restore retained
- other financial data is still **not** synced

Current implementation remains limited to Phase 2B savings goals only.
