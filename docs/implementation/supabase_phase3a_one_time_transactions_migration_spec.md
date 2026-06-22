# Supabase Phase 3A One-Time Transactions Migration Spec

## 1. Purpose

This document defines the **exact planning/specification** for BudgetMeter Phase 3A: structured Supabase sync of **one-time income and one-time expense entries**.

It is **spec only**:

- no Swift implementation
- no SQL migration file
- no Supabase Edge Function changes
- no Core Data schema changes
- no runtime behavior changes

Phase 3A is the **first slice** of Phase 3 financial sync. It syncs only rows that are locally stored as one-time `FinancialCategory` entries, mapped to a dedicated remote table `one_time_transactions`.

Parent planning context:

- `docs/implementation/supabase_phase3_categories_transactions_sync_plan.md`

Approved direction:

- do not mirror the overloaded local `FinancialCategory` entity as one remote table
- start Phase 3 with one-time entries only
- defer `financial_categories`, seeded overrides, and recurring configuration sync to a later phase

---

## 2. Scope

### In scope

- `one_time_transactions` table design (column-level spec)
- RLS policy intent
- constraints
- indexes
- `updated_at` trigger strategy (reuse `public.set_updated_at()`)
- delete-account future update requirements
- Core Data → Supabase field mapping
- local sync metadata requirements (future Swift work)
- initial migration / first-sync strategy
- offline sync behavior (future)
- conflict resolution rules (MVP)
- test plan

### Out of scope

- `financial_categories` table
- seeded category sync
- seeded category override sync
- custom recurring category sync
- `RecurringTransaction` structured sync
- bills, subscriptions, bill payments
- `savings_goals` (Phase 2B — separate track)
- Phase 1 account/settings tables (`profiles`, `user_settings`, `notification_preferences`)
- Swift sync service implementation
- actual SQL migration authoring
- `BackupService` removal
- CloudKit deactivation

---

## 3. Current Local Model

### 3.1 Entity and selection rules

One-time income/expense entries are stored locally as **`FinancialCategory`** rows in Core Data v3.

Source schema: `budgetmeter.ios/BudgetMeter.xcdatamodeld/BudgetMeter 3.xcdatamodel/contents`

There is **no separate local transaction entity**.

A row qualifies as one-time when **either**:

- `entryKind == "oneTime"`, or
- legacy `frequency == "once"` (still recognized by `FinancialCategoryWriteSupport.isOneTimeDisplayCategory(_:)`)

Recurring rows must **not** be uploaded to `one_time_transactions`.

Selection logic in app code:

- `FinancialCategoryWriteSupport.isOneTimeDisplayCategory(_:)`
- `IncomeViewModel.loadIncomeCategories()` → `oneTimeIncomes`
- `ExpenseViewModel.loadExpenseCategories()` → `oneTimeExpenses`

### 3.2 Field usage (one-time rows)

| Local field | One-time usage | Notes |
|---|---|---|
| `type` | `"income"` or `"expense"` | Required for upload filter |
| `entryKind` | `"oneTime"` | Primary discriminator (v3) |
| `frequency` | `"once"` | Set by `FinancialCategoryWriteSupport` for one-time rows; legacy fallback discriminator |
| `amount` | one-time value | Must be `> 0` for inclusion in summaries (`FinancialSummaryBuilder`) |
| `occurrenceDate` | transaction date | Required for calculations; rows without it are skipped in summary builder |
| `customName` | display label | Primary label for user-created one-time entries |
| `uniqueID` | optional template/custom key | Custom rows: `custom_<uuid>`; rarely a seeded key if reused |
| `customIconName` | optional UI icon | Present on custom-created rows |
| `customColorHex` | optional UI color | Premium-gated locally |
| `isCustom` | usually `true` | Manual one-time entries created via `CreateCategoryModal` |
| `sourceType` | optional origin marker | Known value: `"recurringAutomation"` |
| `sourceID` | optional source link | Recurring automation UUID string; migration may prefix `recurring:` |
| `createdAt` | creation timestamp | Set on custom category create |
| `lastModified` | mutation timestamp | Set by `FinancialCategoryWriteSupport.applyMetadata` / edits |
| `isActive` | active flag | Summary builder skips `isActive == false`; defaults to `true` after v3 migration |
| `id` | local UUID | Assigned at create time for custom rows; best sync identity |

### 3.3 Creation paths

**Manual user entry (primary Phase 3A target)**

- UI: `IncomeView` / `ExpenseView` one-time sections → `CreateCategoryModal` with `entryIntent: .oneTime`
- Service: `CategoryValidationService.createCustomCategory(...)` + `FinancialCategoryWriteSupport.applyMetadata(..., entryKind: .oneTime)`
- Result: new `FinancialCategory` row with `isCustom=true`, `occurrenceDate`, `amount`

**Recurring automation generated (secondary, include in Phase 3A upload rules)**

- `RecurringTransactionsViewModel` creates one-time rows with:
  - `sourceType = "recurringAutomation"`
  - `sourceID = <RecurringTransaction.id.uuidString>`
- `FinancialDataMigrationService` may set:
  - `sourceType = "recurringAutomation"`
  - `sourceID = "recurring:<uuid>"`

Phase 3A should sync these rows too (same local shape), storing metadata in `source_type` / `source_client_record_id`. Hard FK to `recurring_transactions` is **not** required in Phase 3A.

### 3.4 Deletion behavior (local today)

- One-time rows created as custom categories can be deleted via `IncomeViewModel.deleteCategory` / `ExpenseViewModel.deleteCategory` when `isCustom == true`
- Deletion is **hard delete** (`context.delete`) — no local tombstone
- Seeded recurring slots are not deletable and are out of Phase 3A scope

### 3.5 Display label resolution (local)

For mapping to remote `category_label`:

| Condition | Local label source |
|---|---|
| `customName` non-empty | use `customName` |
| else `uniqueID` present | use `DataSeedingService.displayName(for: uniqueID)` at sync time |
| else | fallback `"Unknown"` or `type` string (should not upload without resolvable label) |

For `category_key`:

| Condition | Value |
|---|---|
| `uniqueID` present and **not** prefixed `custom_` | store as `category_key` (seeded/template key) |
| `uniqueID` prefixed `custom_` or absent | `category_key = null` |

### 3.6 Related local services (reference only)

| File | Role |
|---|---|
| `FinancialCategoryWriteSupport.swift` | entry kind + occurrence metadata |
| `CategoryValidationService.swift` | custom row creation |
| `CreateCategoryModal.swift` | one-time user entry UI |
| `FinancialSummaryBuilder.swift` | one-time inclusion rules (`isActive`, `amount > 0`, `occurrenceDate`) |
| `FinancialDataMigrationService.swift` | backfills `entryKind`, automation source metadata |
| `BackupSerializer.swift` | exports all `FinancialCategory` rows (backup path ≠ structured sync) |

---

## 4. Proposed Supabase Table: `one_time_transactions`

Table name: `public.one_time_transactions`

### 4.1 Column specification

| Column | Type | Null | Default | Purpose |
|---|---|---|---|---|
| `id` | `uuid` | NO | `gen_random_uuid()` | Server row primary key |
| `user_id` | `uuid` | NO | — | Owner FK → `auth.users(id) ON DELETE CASCADE` |
| `client_record_id` | `text` | NO | — | Stable client identity for upsert/dedupe |
| `type` | `text` | NO | — | `income` or `expense` |
| `amount` | `numeric` | NO | — | One-time amount (non-negative) |
| `occurrence_date` | `timestamptz` | NO | — | When the one-time event occurred |
| `category_key` | `text` | YES | — | Optional seeded/template key (`food`, `rent`, etc.) |
| `category_label` | `text` | NO | — | Denormalized display label snapshot |
| `custom_icon_name` | `text` | YES | — | SF Symbol name snapshot |
| `custom_color_hex` | `text` | YES | — | Optional hex color snapshot |
| `source_type` | `text` | YES | — | Origin marker (e.g. `recurringAutomation`) |
| `source_client_record_id` | `text` | YES | — | Optional linked source record client id |
| `notes` | `text` | YES | — | Reserved; not populated locally today |
| `created_at` | `timestamptz` | NO | `now()` | First known creation time |
| `updated_at` | `timestamptz` | NO | `now()` | Last mutation time (trigger-maintained) |
| `deleted_at` | `timestamptz` | YES | — | Soft-delete tombstone |

### 4.2 Design notes

- **Do not store localized catalog strings for seeded keys remotely** beyond `category_label` snapshot; `category_key` is the stable template reference when known.
- **No `currency_code` in Phase 3A MVP** — app uses account-level preferred currency today. Column may be added in a later migration if row-level currency becomes necessary.
- **No FK to `financial_categories`** in Phase 3A — category table does not exist yet.
- **No FK to `recurring_transactions`** in Phase 3A — store optional string metadata only.

---

## 5. Constraints

### 5.1 Required constraints

| Constraint | Definition | Rationale |
|---|---|---|
| Primary key | `id` | standard server row id |
| Owner FK | `user_id REFERENCES auth.users(id) ON DELETE CASCADE` | account-scoped ownership |
| Unique client identity | `UNIQUE (user_id, client_record_id)` | cross-device dedupe / upsert key |
| Type enum check | `type IN ('income', 'expense')` | matches local `FinancialCategory.type` |
| Non-negative amount | `amount >= 0` | aligns with local edit validation (`amount >= 0`) |
| Non-blank label | `btrim(category_label) <> ''` | every transaction must be displayable |
| Client record id non-blank | `btrim(client_record_id) <> ''` | prevent empty upsert keys |

### 5.2 Optional / deferred constraints

| Constraint | Recommendation |
|---|---|
| `custom_color_hex` format | **Optional safe check** if added: `custom_color_hex ~ '^[0-9A-Fa-f]{6}$'` OR `custom_color_hex IS NULL` |
| `source_type` enum | **Do not over-constrain in MVP.** Only known production value today is `recurringAutomation`. Allow null and future string values. |
| `occurrence_date` range | **Defer** — no business rule requiring future/past-only dates today |
| `category_key` format | **Defer strict enum** — keys come from seed catalog and legacy migrations; validate non-blank when present only |

### 5.3 Upload eligibility rules (application-level, pre-insert)

A local `FinancialCategory` row should be considered for `one_time_transactions` upload only if:

1. `FinancialCategoryWriteSupport.isOneTimeDisplayCategory(row) == true`
2. `type` is `income` or `expense`
3. `occurrenceDate` is non-null
4. stable `client_record_id` can be resolved (see §11)
5. resolved `category_label` is non-blank

Rows with `amount == 0` may still exist locally; recommend **upload them** if otherwise valid (user may edit later). Summary UI hides zero amounts, but sync should preserve row existence.

Rows with `isActive == false` should either:

- be uploaded with a tombstone if locally deleted/inactivated, or
- be excluded if local hard delete already occurred

**MVP recommendation:** treat local hard delete as remote `deleted_at = now()` tombstone when sync is enabled; inactive but not deleted rows remain synced.

---

## 6. RLS Policy Intent

RLS must be **enabled** on `public.one_time_transactions`.

### 6.1 Policy matrix (intent)

| Operation | Role | Rule |
|---|---|---|
| SELECT | `authenticated` | `auth.uid() = user_id` |
| INSERT | `authenticated` | `WITH CHECK (auth.uid() = user_id)` |
| UPDATE | `authenticated` | `USING (auth.uid() = user_id) AND WITH CHECK (auth.uid() = user_id)` |
| DELETE | none for MVP | use soft delete via `deleted_at` update only |

### 6.2 Explicit exclusions

- **No anonymous** (`anon`) SELECT/INSERT/UPDATE/DELETE policies
- **No service role** access from client app
- **No client hard DELETE** policy in MVP

### 6.3 Soft delete via UPDATE

Deleting a one-time entry in sync means:

```text
UPDATE one_time_transactions
SET deleted_at = now()
WHERE user_id = auth.uid() AND client_record_id = :id
```

Pull queries must include recently tombstoned rows (by `updated_at` cursor), not only `deleted_at IS NULL` rows.

---

## 7. User ID Enforcement

### 7.1 Strategy

- `user_id` is **required** on every row
- Client inserts/updates must set `user_id` to the authenticated user
- RLS policies enforce `auth.uid() = user_id`

### 7.2 Recommended hardening (optional trigger, pre-SQL decision)

Optional `BEFORE INSERT OR UPDATE` trigger:

- reject when `NEW.user_id IS DISTINCT FROM auth.uid()`
- reject `user_id` changes on UPDATE (`OLD.user_id = NEW.user_id`)

This protects against client bugs even if RLS is misconfigured.

### 7.3 Spoofing and ownership transfer prevention

- Users cannot create rows for another account (INSERT policy + optional trigger)
- Users cannot reassign rows by changing `user_id` on UPDATE
- `client_record_id` uniqueness is scoped per `user_id`, so cross-user collisions are harmless

---

## 8. `updated_at` Strategy

Reuse existing shared trigger function from Phase 1 migration `0005_phase1_updated_at_triggers.sql`:

- Function: `public.set_updated_at()`
- Behavior: `NEW.updated_at = now()` before update

Planned attachment for Phase 3A migration (future SQL, not in this doc):

```text
BEFORE UPDATE ON public.one_time_transactions
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at()
```

Notes:

- Inserts rely on column default `now()` for initial `updated_at`
- Client should **not** attempt to set `updated_at` manually except during controlled migration imports
- Soft-delete updates must bump `updated_at` via trigger so tombstones appear in incremental pull

---

## 9. Index Strategy

### 9.1 Required indexes

| Index | Purpose |
|---|---|
| `UNIQUE (user_id, client_record_id)` | upsert + dedupe (also satisfies unique constraint) |
| `(user_id, updated_at DESC)` | incremental sync pull since cursor |
| `(user_id, deleted_at)` | tombstone filtering / cleanup queries |
| `(user_id, occurrence_date DESC)` | recent history lists |
| `(user_id, type, occurrence_date DESC)` | typed history queries (income vs expense) |
| `(user_id, category_key)` | optional analytics/filter by template key |

### 9.2 Index notes

- Use `DESC` on time columns for pull/history patterns
- Partial indexes (e.g. `WHERE deleted_at IS NULL`) are optional optimization later — not required for MVP spec
- No index on `source_client_record_id` until recurring sync phase proves query need

---

## 10. Core Data Mapping

Local source: **`FinancialCategory`** rows where `isOneTimeDisplayCategory == true`.

| FinancialCategory field | `one_time_transactions` column | Notes |
|---|---|---|
| `id` | `client_record_id` | `id.uuidString`; see §11 for backfill |
| `type` | `type` | must be `income` or `expense` |
| `amount` | `amount` | numeric cast |
| `occurrenceDate` | `occurrence_date` | store as UTC timestamptz |
| `uniqueID` (non-`custom_`) | `category_key` | seeded/template key only |
| `uniqueID` (`custom_*`) or absent | `category_key = null` | custom entries are not template keys |
| `customName` or resolved display name | `category_label` | denormalized snapshot; required |
| `customIconName` | `custom_icon_name` | nullable |
| `customColorHex` | `custom_color_hex` | nullable |
| `sourceType` | `source_type` | pass through when present |
| `sourceID` | `source_client_record_id` | normalize `recurring:<uuid>` → `<uuid>` |
| — | `notes` | null in Phase 3A (no local field) |
| `createdAt` | `created_at` | fallback to `lastModified` or upload time if null |
| `lastModified` | `updated_at` on initial import | thereafter maintained by trigger |
| local hard delete event | `deleted_at` | new remote behavior; not stored locally today |
| `entryKind`, `frequency` | — | routing/filter only; not stored remotely |
| `isCustom` | — | implied by `category_key` nullability + label source |
| `isActive` | — | local summary filter; deletion maps to `deleted_at` |

### 10.1 Reverse mapping (remote → local)

On pull, future Swift sync creates/updates local `FinancialCategory` rows with:

- `entryKind = "oneTime"`
- `frequency = "once"`
- `type`, `amount`, `occurrenceDate`, `customName` (from `category_label`), icon/color fields
- `isCustom = true` for imported rows (safe default)
- `uniqueID` optional: set to `category_key` when present, else generate `custom_<uuid>`
- preserve `client_record_id` ↔ local `id` mapping via sync metadata layer

Local Core Data schema changes for reverse mapping are **future implementation work**, not part of this spec’s code changes.

### 10.2 Local sync metadata requirements (future Swift)

Phase 3A requires future local metadata per synced one-time row.

| Field | Purpose |
|---|---|
| `client_record_id` | stable upsert key (mirrors remote) |
| `sync_status` | `pending`, `synced`, `failed`, `deleted_pending` |
| `last_synced_at` | last successful push/pull |
| `remote_updated_at` | last known server timestamp |
| `deleted_at` | local tombstone mirror (optional but recommended) |
| `sync_error` | optional last error code/message |

**Storage location (decide before Swift implementation):** because `FinancialCategory` is shared with recurring/category rows, prefer a **sidecar sync metadata store** keyed by `client_record_id` (Option B) over adding sync columns directly to `FinancialCategory` (Option A) until broader category sync lands. This spec does not authorize Core Data changes.

---

## 11. Sync Identity

### 11.1 Primary rule

Use local `FinancialCategory.id.uuidString` as `client_record_id`.

Reason:

- one-time rows are user/event-created, not seeded catalog slots
- each row already receives `UUID()` at creation in `CategoryValidationService`
- matches backup serializer behavior (`BackupSerializer.clientRecordID(for: category.id, ...)`)

### 11.2 Legacy / missing `id` backfill (required before first upload)

If a one-time row lacks `id`:

1. assign new `UUID()` locally
2. persist Core Data save
3. use that UUID string as `client_record_id`

This backfill is **implementation-phase** work; spec requirement only.

### 11.3 `source_client_record_id` normalization

| Local `sourceID` | Remote `source_client_record_id` |
|---|---|
| `"recurring:<uuid>"` | `<uuid>` |
| `"<uuid>"` | `<uuid>` |
| null/empty | null |

Do not store Core Data `objectID` URI strings remotely.

---

## 12. Initial Migration Strategy

### 12.1 Case A — local one-time rows exist, remote empty

1. User signs in (Phase 1 bootstrap unrelated).
2. Enumerate eligible local one-time rows (§5.3).
3. Assign/backfill `client_record_id` where needed.
4. Upsert each row to `one_time_transactions`.
5. Mark local sync metadata as synced (future Swift).

### 12.2 Case B — remote rows exist, local empty (reinstall)

1. Local seed / app launch creates no one-time rows initially.
2. Pull all non-deleted remote rows (or incremental since epoch).
3. Insert local `FinancialCategory` one-time rows mapped from remote payload.
4. Preserve `client_record_id` ↔ local `id` mapping.

### 12.3 Case C — both local and remote exist

1. Pull remote changes since last cursor.
2. For each remote row:
   - if local match on `client_record_id`: compare `updated_at`, apply last-write-wins
   - if no local match: insert local row
3. Upload local rows with pending sync state not present remotely or locally newer by rules in §14.
4. Never duplicate on `(user_id, client_record_id)`.

### 12.4 Duplicate prevention

- Remote: unique `(user_id, client_record_id)`
- Local: maintain explicit `client_record_id` mapping per one-time row
- Do not key duplicates by `category_label` or `occurrence_date` alone

### 12.5 BackupService interaction

Manual backup/restore may import `FinancialCategory` rows independently of structured sync.

Rule for future implementation:

- structured sync identity (`client_record_id`) wins over backup restore collisions when both exist
- backup remains fallback; Phase 3A does not remove it

---

## 13. Offline Sync Behavior

Future Swift behavior (spec only):

1. **Local write first** — user edits Core Data immediately (current UX unchanged).
2. **Mark pending sync** — row flagged dirty in sync metadata layer.
3. **Upload when online** — upsert to `one_time_transactions` using `client_record_id`.
4. **On success** — store remote `updated_at`, clear pending state.
5. **On failure** — keep local data, log safely, retry later (Phase 3A MVP may use simple retry; full queue deferred).
6. **Delete locally** — translate to remote soft delete (`deleted_at`) rather than hard DELETE.
7. **Pull on sign-in / foreground** — merge remote changes since last cursor.

Sign-in bootstrap must **not block app launch** on sync failure (same non-blocking pattern as Phase 1 account settings sync).

---

## 14. Conflict Resolution

### MVP rules

| Scenario | Resolution |
|---|---|
| Same row edited on two devices | last-write-wins using server `updated_at` |
| Local pending upload vs remote row | compare timestamps; newer `updated_at` wins |
| Remote tombstone vs stale local active row | **`deleted_at` wins** — local row removed/hidden |
| Duplicate create same `client_record_id` | upsert merges into single row (unique constraint) |

### Non-goals (Phase 3A)

- field-level merge
- conflict UI
- automatic duplicate merge by label/date
- resurrection of tombstoned rows without explicit user action

---

## 15. Delete Account Update Plan

Future update to `supabase/functions/delete-account/index.ts` (not in this spec phase) must hard-delete:

```text
one_time_transactions WHERE user_id = :auth_user_id
```

Recommended ordering relative to other tables:

1. child/history tables first if FKs added later
2. **`one_time_transactions`** (Phase 3A)
3. Phase 2B **`savings_goals`** (already in current function)
4. Phase 1 **`notification_preferences`**, **`user_settings`**, **`profiles`**
5. backup tables **`user_backup_versions`**, **`user_backups`**
6. auth user deletion

Phase 3A adds a new table cleanup step; it does not modify the function in this planning phase.

---

## 16. Testing Plan

### 16.1 RLS / security

- [ ] user A can SELECT own `one_time_transactions`
- [ ] user A cannot SELECT user B rows
- [ ] user A cannot INSERT row with `user_id = user_B`
- [ ] user A cannot UPDATE user B row
- [ ] anonymous client cannot read/write
- [ ] UPDATE denied without SELECT policy regression (0-row update fails safely)

### 16.2 CRUD sync behavior (future Swift/integration tests)

- [ ] create one-time **income** locally → remote row inserted
- [ ] create one-time **expense** locally → remote row inserted
- [ ] update **amount** locally → remote `amount` + `updated_at` change
- [ ] update **occurrence_date** locally → remote date changes
- [ ] local delete → remote `deleted_at` set (no hard DELETE)
- [ ] remote tombstone pull removes/hides local row

### 16.3 Migration / recovery

- [ ] local exists / remote empty → upload all eligible rows once
- [ ] remote exists / local empty (reinstall) → local rows recreated
- [ ] both exist → no duplicate rows for same `client_record_id`
- [ ] sign-in bootstrap succeeds when Supabase unavailable (local data intact)

### 16.4 Offline

- [ ] offline create → pending state → uploads on reconnect
- [ ] offline delete → tombstone uploads on reconnect
- [ ] failed upload retains local row and pending state

### 16.5 Automation metadata (secondary)

- [ ] row with `source_type = recurringAutomation` uploads successfully
- [ ] `sourceID` normalized to `source_client_record_id`

### 16.6 Isolation from other phases

- [ ] Phase 1 account settings sync unaffected
- [ ] Phase 2B savings goals sync unaffected
- [ ] recurring `FinancialCategory` rows not uploaded to `one_time_transactions`
- [ ] BackupService backup/restore still works

---

## 17. Risks / Open Questions

Blockers to resolve **before SQL migration implementation**:

1. **Sync metadata storage on overloaded entity** — sidecar vs Core Data column addition (§17).
2. **Zero-amount one-time rows** — confirm upload vs skip (spec recommends upload).
3. **Automation-generated rows** — included in Phase 3A MVP; confirm product expectation.
4. **Timezone normalization** — confirm `occurrence_date` stored UTC with local calendar date preserved correctly for insights.
5. **Tombstone retention window** — how long deleted rows remain pullable for other devices.
6. **Hard delete local rows created before sync** — if row deleted offline before first upload, remote never created; acceptable.
7. **Pull into local Core Data** — reverse mapping creates `isCustom=true` rows always; confirm acceptable for rehydrated history.

Non-blockers (can defer to Swift implementation):

- partial indexes on active rows
- `currency_code` column
- strict `source_type` check constraint
- conflict UI

---

## 18. Final Recommendation

### Is Phase 3A ready for SQL migration implementation after this spec?

**Yes — with conditions.**

Phase 3A is ready for the **next step: authoring a SQL migration file** (`0006` or next sequence) once:

1. sync metadata storage approach (§10.2) is chosen
2. zero-amount upload rule (§5.3) is product-approved
3. tombstone retention window (§18) is decided

### Recommended implementation sequence after SQL

1. SQL migration + RLS + trigger + indexes
2. delete-account function update (separate small change)
3. Swift read/write service for `one_time_transactions` only
4. sign-in bootstrap pull/merge (non-blocking)
5. local write → pending → upload path
6. soft-delete tombstone support
7. integration tests from §16

### Explicitly defer

- `financial_categories` table and seeded override sync
- recurring transaction structured sync
- Core Data schema migration (separate approved spec)
- BackupService removal

---

## Implementation Status

| Item | Status |
|---|---|
| Migration file | Created — `supabase/migrations/0007_phase3a_one_time_transactions.sql` |
| Table `public.one_time_transactions` | Created (via migration) |
| Constraints | Added — unique `(user_id, client_record_id)`, type check, non-negative amount, non-blank label/client_record_id |
| Indexes | Added — `(user_id, updated_at desc)`, `(user_id, deleted_at)`, `(user_id, occurrence_date desc)`, `(user_id, type, occurrence_date desc)`, `(user_id, category_key)`; unique index via constraint |
| RLS | Enabled — authenticated SELECT/INSERT/UPDATE own rows only; no anon; no client DELETE |
| `updated_at` trigger | Added — reuses `public.set_updated_at()` |
| `delete-account` cleanup | Updated — deletes `one_time_transactions` by `user_id` before auth user deletion |
| Swift sync | Implemented — `SupabaseOneTimeTransactionSyncService` |
| Core Data changes | Implemented — sidecar entity `OneTimeTransactionSyncMetadata` (model v5) |
| `custom_color_hex` format constraint | Deferred — local app stores palette keys (e.g. `blue`), not hex-only values |

---

## Swift Integration Status

| Item | Status |
|---|---|
| Sync service | Added — `SupabaseOneTimeTransactionSyncService.swift` |
| Local metadata | Added — sidecar `OneTimeTransactionSyncMetadata` keyed by `client_record_id` |
| Sign-in bootstrap | Added — runs after Phase 1 + Phase 2B, non-blocking |
| Create/update/delete sync | Wired — create/update mark pending; one-time delete uses tombstone |
| Category sync | Not started |
| Recurring sync | Not started |
| BackupService | Retained — tombstoned one-time rows excluded from backup export |
| CloudKit | Retained — sidecar metadata entity is `syncable="NO"` (Supabase sync state only) |

---

## Document Status

| Item | Status |
|---|---|
| Document type | Planning + database implementation spec |
| Phase | 3A (`one_time_transactions`) |
| SQL migration | Created (`0007_phase3a_one_time_transactions.sql`) |
| Swift sync | Implemented |
| Core Data changes | Sidecar metadata entity (model v5) |
| Supabase function changes | `delete-account` updated for table cleanup |
| Depends on | Phase 1 auth/session; independent of Phase 2B deliverable timing |
| Parent plan | `supabase_phase3_categories_transactions_sync_plan.md` |

---

## Appendix — Known `source_type` Values (Current Codebase)

| Value | Origin |
|---|---|
| `recurringAutomation` | `RecurringTransactionsViewModel`, `FinancialDataMigrationService` |

No other `sourceType` string literals were found in production Swift paths at spec time. Do not enum-constrain in SQL until more values are introduced deliberately.
