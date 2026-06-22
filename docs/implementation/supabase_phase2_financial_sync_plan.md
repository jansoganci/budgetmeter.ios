# Supabase Phase 2 Financial Sync Plan

## 1. Purpose

This document is a **planning document only** for a future Phase 2 rollout of Supabase-backed financial data sync in BudgetMeter.

It does **not**:

- implement sync
- modify Swift code
- create Supabase migrations
- change Supabase functions
- change Core Data
- alter Phase 1 Swift integration work already in progress

The goal is to define the safest architecture for moving BudgetMeter from local-only financial persistence toward account-scoped Supabase sync.

---

## 2. Current State

- Core Data remains the active local source of truth for financial data through `PersistenceService` and the `BudgetMeter` data model.
- Phase 1 Supabase work only covers account/settings data:
  - `profiles`
  - `user_settings`
  - `notification_preferences`
- Phase 1 Swift integration is being handled separately and should remain isolated from this plan.
- `BackupService` and `RestoreImporter` still exist and currently provide manual snapshot-based backup/restore.
- Financial data is **not** yet synced to structured Supabase tables.
- The app still contains CloudKit-backed Core Data plumbing (`NSPersistentCloudKitContainer`), but that is not the target architecture for future Supabase financial sync.

---

## 3. Data Inventory

Observed financial persistence is centered on the Core Data model in `budgetmeter.ios/BudgetMeter.xcdatamodeld/BudgetMeter 3.xcdatamodel/contents`, plus manual backup serialization in `BackupSerializer` / `RestoreImporter`.

Important current-state note:

- There are **no Core Data relationships declared** between the financial entities.
- Cross-record links are currently logical only, mostly by UUID or string fields.
- `FinancialCategory` is overloaded and currently represents both category-like configuration and one-time transaction-like data.

### 3.1 Entity Inventory

| Domain | Current Core Data Entity / Model | Key Fields | Current Relationships | Sync in Phase 2? | Sync Priority | Risk |
|---|---|---|---|---|---|---|
| Financial categories / recurring category rows | `FinancialCategory` | `id`, `uniqueID`, `type`, `frequency`, `amount`, `isCustom`, `customName`, `customIconName`, `customColorHex`, `entryKind`, `occurrenceDate`, `sourceType`, `sourceID`, `isActive`, `createdAt`, `lastModified` | No declared Core Data relationship. Logical ties only: seeded category identity via `uniqueID`; generated one-time rows may reference recurring source through `sourceType` / `sourceID`. | Yes, but not first | High | High |
| One-time income / expenses | `FinancialCategory` rows where `entryKind == "oneTime"` | `id`, `type`, `amount`, `occurrenceDate`, `customName`, `uniqueID`, `sourceType`, `sourceID`, `createdAt`, `lastModified`, `isActive` | No declared relationship. Optional logical link to `RecurringTransaction` through `sourceID`. | Yes | High | High |
| Recurring income / expenses | `RecurringTransaction` | `id`, `title`, `amount`, `categoryName`, `categoryType`, `frequency`, `startDate`, `endDate`, `nextDueDate`, `isActive`, `notes`, `createdAt`, `lastProcessedDate` | No declared relationship. Category is stored as strings, not FK. Creates one-time `FinancialCategory` rows during automation. | Yes | High | Medium-High |
| Savings goals | `SavingsGoal` | `id`, `name`, `targetAmount`, `currentAmount`, `targetDate`, `emoji`, `colorHex`, `priority`, `isArchived`, `archivedDate`, `completedDate`, `notes`, `category`, `monthlyContribution`, `createdAt`, `lastModified` | No declared relationship. Optional category is string only. | Yes | Highest | Medium |
| Subscriptions | `Subscription` | `id`, `name`, `amount`, `billingCycle`, `customCycleDays`, `firstBillDate`, `nextRenewalDate`, `category`, `notes`, `reminderDaysBefore`, `isActive`, `isPaused`, `createdAt`, `lastModified` | No declared relationship. Category is string only. | Yes | High | Medium |
| Bills | `Bill` | `id`, `name`, `amount`, `isRecurring`, `frequency`, `dueDate`, `originalDueDate`, `category`, `iconName`, `colorHex`, `notes`, `reminderDaysBefore`, `isPaid`, `paidDate`, `paidAmount`, `isAutoPay`, `createdAt`, `lastModified` | No declared relationship. Category is string only. Parent of bill-payment history logically, but not via Core Data relationship. | Yes | High | Medium |
| Bill payments / payment history | `BillPayment` | `id`, `billID`, `dueDate`, `paidDate`, `expectedAmount`, `actualAmount`, `notes`, `wasLate`, `daysLate`, `createdAt` | Logical parent link only: `billID -> Bill.id`. No declared relationship or cascade. | Yes | Medium | Medium-High |
| Financial snapshots / historical summaries | `FinancialSnapshot` | `id`, `date`, `snapshotType`, `totalIncome`, `totalExpense`, `balance`, `netFlow`, `savingsAmount`, `healthScore`, `savingsRate`, `categoryBreakdown`, `createdAt` | No declared relationship. Derived from current financial state. Old rows are periodically batch-deleted by retention logic. | Yes, but late | Low | Medium |
| Transaction / history records created from recurring automation | `FinancialCategory` one-time rows and `BillPayment` rows | See rows above | Logical link only through `sourceID` or `billID` | Yes | Medium | High |
| Export-related persisted metadata | `AppSettings.lastExportDate` only | `lastExportDate` | No relationship | Optional only; not core financial sync | Low | Low |
| Backup-only financial payloads | `BackupPayload` / `user_backups` / `user_backup_versions` | JSON snapshot payloads, counts, timestamps | Not structured relational sync | Keep separate from Phase 2 structured sync | N/A | Medium |

### 3.2 Key Observations From Current Code

1. `FinancialCategory` is not a clean remote-table mirror candidate.
   - It mixes seeded category identity, custom category metadata, recurring amount configuration, and one-time entries.
2. Current delete behavior is mostly hard delete.
   - `SavingsGoal`, `Subscription`, `Bill`, `RecurringTransaction`, and custom `FinancialCategory` rows are deleted locally with `context.delete(...)`.
3. Some entities already track modification timestamps well.
   - Good: `SavingsGoal`, `Subscription`, `Bill`, `FinancialCategory`
   - Weak: `RecurringTransaction`, `BillPayment`, `FinancialSnapshot`
4. Some parent-child links are only logical.
   - `BillPayment.billID`
   - `FinancialCategory.sourceID`
5. Backup payloads already expose a useful record identity concept:
   - `clientRecordID`
   - `updatedAt`
   - This is the best starting point for future sync identity.

---

## 4. Proposed Phase 2 Scope

### Recommended safest sync order

Based on the current codebase, the safest order is:

1. `savings_goals`
2. `subscriptions`
3. `bills`
4. `bill_payments`
5. `recurring_transactions`
6. `financial_categories`
7. `one_time_transactions`
8. `financial_snapshots`

### Why this order is safer than syncing categories first

- `SavingsGoal` is the cleanest first financial entity:
  - standalone
  - stable UUID already exists
  - explicit `createdAt` / `lastModified`
  - no foreign keys
  - archive/completion states already exist
- `Subscription` is next safest:
  - standalone
  - existing `lastModified`
  - no dependent child table
- `Bill` is manageable before `BillPayment`:
  - parent row has good timestamps
  - child payment history can layer on later
- `RecurringTransaction` is more complex than it looks:
  - it generates one-time `FinancialCategory` rows
  - it lacks a dedicated `lastModified`
  - category links are string-based
- `FinancialCategory` should **not** move first:
  - it is overloaded locally
  - seeded categories exist on every install
  - syncing too early risks duplicate seeded rows and cross-device divergence
- `FinancialSnapshot` should be last:
  - it is derived data
  - it has retention cleanup logic
  - it can be rebuilt if necessary

### Scope recommendation

Phase 2 should begin with entities that are:

- user-owned
- low-relationship
- timestamp-friendly
- not generated from other financial records

That means `savings_goals` should be the first synced financial table.

---

## 5. Proposed Supabase Tables

Do **not** write SQL yet. This section defines the intended table design only.

### 5.1 Common table rules for all Phase 2 financial tables

Every Phase 2 financial table should include:

- `id uuid` as server row ID
- `user_id uuid not null`
- `client_record_id text not null`
- `created_at timestamptz not null`
- `updated_at timestamptz not null`
- `deleted_at timestamptz null`
- optional `sync_version bigint` only if optimistic versioning becomes necessary

Common constraints and indexes:

- unique: `(user_id, client_record_id)`
- index: `(user_id, updated_at desc)`
- index: `(user_id, deleted_at)`
- RLS enabled
- no anonymous access

### 5.2 `savings_goals`

- Purpose: persist account-owned savings goals with archive and completion state.
- Key columns:
  - `id`
  - `user_id`
  - `client_record_id`
  - `name`
  - `target_amount`
  - `current_amount`
  - `target_date`
  - `emoji`
  - `color_hex`
  - `priority`
  - `is_archived`
  - `archived_date`
  - `completed_date`
  - `notes`
  - `category_label`
  - `monthly_contribution`
  - `created_at`
  - `updated_at`
  - `deleted_at`
- Ownership: `user_id` references `auth.users(id)`.
- Relationships / FKs: none initially.
- Unique constraints:
  - `(user_id, client_record_id)`
- Indexes:
  - `(user_id, updated_at desc)`
  - `(user_id, is_archived)`
  - `(user_id, target_date)`
- RLS:
  - owner-only select/insert/update/delete
  - update policy must include both `USING` and `WITH CHECK`

### 5.3 `subscriptions`

- Purpose: persist subscription records and renewal-related metadata.
- Key columns:
  - `id`
  - `user_id`
  - `client_record_id`
  - `name`
  - `amount`
  - `currency_code` nullable at first if app remains single-user currency driven
  - `billing_cycle`
  - `custom_cycle_days`
  - `first_bill_date`
  - `next_renewal_date`
  - `category_label`
  - `notes`
  - `reminder_days_before`
  - `is_active`
  - `is_paused`
  - `created_at`
  - `updated_at`
  - `deleted_at`
- Relationships / FKs: none initially.
- Unique constraints:
  - `(user_id, client_record_id)`
- Indexes:
  - `(user_id, updated_at desc)`
  - `(user_id, is_active)`
  - `(user_id, next_renewal_date)`
- RLS: owner-only CRUD.

### 5.4 `bills`

- Purpose: persist bills, including recurring bill templates and current payment state.
- Key columns:
  - `id`
  - `user_id`
  - `client_record_id`
  - `name`
  - `amount`
  - `currency_code` nullable initially
  - `is_recurring`
  - `frequency`
  - `due_date`
  - `original_due_date`
  - `category_label`
  - `icon_name`
  - `color_hex`
  - `notes`
  - `reminder_days_before`
  - `is_paid`
  - `paid_date`
  - `paid_amount`
  - `is_auto_pay`
  - `created_at`
  - `updated_at`
  - `deleted_at`
- Relationships / FKs: parent of `bill_payments`.
- Unique constraints:
  - `(user_id, client_record_id)`
- Indexes:
  - `(user_id, updated_at desc)`
  - `(user_id, due_date)`
  - `(user_id, is_paid)`
  - `(user_id, deleted_at)`
- RLS: owner-only CRUD.

### 5.5 `bill_payments`

- Purpose: persist bill payment history as child rows of bills.
- Key columns:
  - `id`
  - `user_id`
  - `client_record_id`
  - `bill_id uuid not null`
  - `bill_client_record_id text` optional but useful for reconciliation/debugging
  - `due_date`
  - `paid_date`
  - `expected_amount`
  - `actual_amount`
  - `notes`
  - `was_late`
  - `days_late`
  - `created_at`
  - `updated_at`
  - `deleted_at`
- Ownership:
  - `user_id` required on child row even with FK to `bills`
- Relationships / FKs:
  - `bill_id references bills(id) on delete restrict` preferred for safety
- Unique constraints:
  - `(user_id, client_record_id)`
- Indexes:
  - `(user_id, updated_at desc)`
  - `(user_id, bill_id)`
  - `(user_id, paid_date)`
- RLS:
  - owner-only CRUD
  - insert/update must also enforce bill ownership, not just child row ownership

### 5.6 `recurring_transactions`

- Purpose: persist explicit recurring transaction schedules currently modeled by `RecurringTransaction`.
- Key columns:
  - `id`
  - `user_id`
  - `client_record_id`
  - `title`
  - `amount`
  - `currency_code` nullable initially
  - `category_name`
  - `category_type`
  - `frequency`
  - `start_date`
  - `end_date`
  - `next_due_date`
  - `is_active`
  - `notes`
  - `last_processed_date`
  - `created_at`
  - `updated_at`
  - `deleted_at`
- Relationships / FKs:
  - no hard FK to category table in MVP
  - optional later FK if category model is normalized
- Unique constraints:
  - `(user_id, client_record_id)`
- Indexes:
  - `(user_id, updated_at desc)`
  - `(user_id, next_due_date)`
  - `(user_id, is_active)`
  - `(user_id, category_type)`
- RLS: owner-only CRUD.

### 5.7 `financial_categories`

- Purpose: persist category-like configuration rows that should survive across devices.
- Scope recommendation:
  - sync custom categories
  - sync user-modified seeded category rows
  - avoid blindly syncing every zero-amount seeded row on day one
- Key columns:
  - `id`
  - `user_id`
  - `client_record_id`
  - `category_key` nullable for custom-only rows
  - `type`
  - `frequency`
  - `amount`
  - `is_custom`
  - `custom_name`
  - `custom_icon_name`
  - `custom_color_hex`
  - `is_active`
  - `created_at`
  - `updated_at`
  - `deleted_at`
- Relationships / FKs: none in MVP.
- Unique constraints:
  - `(user_id, client_record_id)`
  - optional `(user_id, category_key, type, frequency)` for seeded rows after data-cleanup rules are finalized
- Indexes:
  - `(user_id, updated_at desc)`
  - `(user_id, type)`
  - `(user_id, is_active)`
  - `(user_id, category_key)`
- RLS: owner-only CRUD.

### 5.8 `one_time_transactions`

- Purpose: persist one-time income/expense rows currently stored as `FinancialCategory` with `entryKind = oneTime`.
- Key columns:
  - `id`
  - `user_id`
  - `client_record_id`
  - `type`
  - `amount`
  - `currency_code` nullable initially
  - `occurrence_date`
  - `category_key` nullable
  - `category_label`
  - `source_type`
  - `source_client_record_id` nullable
  - `notes` nullable if added later locally
  - `created_at`
  - `updated_at`
  - `deleted_at`
- Relationships / FKs:
  - no FK required in MVP
  - optional later FK to `recurring_transactions` via source mapping if the model is normalized
- Unique constraints:
  - `(user_id, client_record_id)`
- Indexes:
  - `(user_id, updated_at desc)`
  - `(user_id, occurrence_date desc)`
  - `(user_id, type, occurrence_date desc)`
  - `(user_id, category_key)`
- RLS: owner-only CRUD.

### 5.9 `financial_snapshots`

- Purpose: persist historical daily/monthly summary snapshots for cross-device insight continuity.
- Key columns:
  - `id`
  - `user_id`
  - `client_record_id`
  - `snapshot_type`
  - `snapshot_date`
  - `total_income`
  - `total_expense`
  - `balance`
  - `net_flow`
  - `savings_amount`
  - `health_score`
  - `savings_rate`
  - `category_breakdown_json`
  - `created_at`
  - `updated_at`
  - `deleted_at`
- Relationships / FKs: none.
- Unique constraints:
  - `(user_id, client_record_id)`
  - optional `(user_id, snapshot_type, snapshot_date)` if only one daily/monthly row should exist
- Indexes:
  - `(user_id, updated_at desc)`
  - `(user_id, snapshot_type, snapshot_date desc)`
- RLS: owner-only CRUD.

---

## 6. Core Data to Supabase Mapping

| Core Data Entity | Supabase Table | Key Field Mapping | Notes |
|---|---|---|---|
| `SavingsGoal` | `savings_goals` | `id` or future sync UUID -> `client_record_id`; `name -> name`; `targetAmount -> target_amount`; `currentAmount -> current_amount`; `targetDate -> target_date`; `isArchived -> is_archived`; `archivedDate -> archived_date`; `completedDate -> completed_date`; `monthlyContribution -> monthly_contribution`; `lastModified -> updated_at`; `createdAt -> created_at` | Best first sync candidate. |
| `Subscription` | `subscriptions` | `id -> client_record_id`; `name -> name`; `amount -> amount`; `billingCycle -> billing_cycle`; `customCycleDays -> custom_cycle_days`; `firstBillDate -> first_bill_date`; `nextRenewalDate -> next_renewal_date`; `category -> category_label`; `isActive -> is_active`; `isPaused -> is_paused`; `lastModified -> updated_at`; `createdAt -> created_at` | Category is string only today. |
| `Bill` | `bills` | `id -> client_record_id`; `name -> name`; `amount -> amount`; `isRecurring -> is_recurring`; `frequency -> frequency`; `dueDate -> due_date`; `originalDueDate -> original_due_date`; `category -> category_label`; `isPaid -> is_paid`; `paidDate -> paid_date`; `paidAmount -> paid_amount`; `isAutoPay -> is_auto_pay`; `lastModified -> updated_at`; `createdAt -> created_at` | Parent for bill payments. |
| `BillPayment` | `bill_payments` | `id -> client_record_id`; `billID -> parent bill mapping`; `dueDate -> due_date`; `paidDate -> paid_date`; `expectedAmount -> expected_amount`; `actualAmount -> actual_amount`; `wasLate -> was_late`; `daysLate -> days_late`; `createdAt -> created_at` | Needs remote parent resolution from bill identity. |
| `RecurringTransaction` | `recurring_transactions` | `id -> client_record_id`; `title -> title`; `amount -> amount`; `categoryName -> category_name`; `categoryType -> category_type`; `frequency -> frequency`; `startDate -> start_date`; `endDate -> end_date`; `nextDueDate -> next_due_date`; `isActive -> is_active`; `notes -> notes`; `lastProcessedDate -> last_processed_date`; `createdAt -> created_at` | Current model lacks `lastModified`; future sync metadata will need to supply remote `updated_at`. |
| `FinancialCategory` recurring/config rows | `financial_categories` | `id or derived key -> client_record_id`; `uniqueID -> category_key`; `type -> type`; `frequency -> frequency`; `amount -> amount`; `isCustom -> is_custom`; `customName -> custom_name`; `customIconName -> custom_icon_name`; `customColorHex -> custom_color_hex`; `isActive -> is_active`; `lastModified -> updated_at`; `createdAt -> created_at` | Sync only after seeded/custom dedupe rules are defined. |
| `FinancialCategory` one-time rows | `one_time_transactions` | `id -> client_record_id`; `type -> type`; `amount -> amount`; `occurrenceDate -> occurrence_date`; `uniqueID/customName -> category_key/category_label`; `sourceType -> source_type`; `sourceID -> source_client_record_id`; `lastModified -> updated_at`; `createdAt -> created_at` | Same local entity, separate remote table. |
| `FinancialSnapshot` | `financial_snapshots` | `id -> client_record_id`; `date -> snapshot_date`; `snapshotType -> snapshot_type`; `totalIncome -> total_income`; `totalExpense -> total_expense`; `balance -> balance`; `netFlow -> net_flow`; `savingsAmount -> savings_amount`; `healthScore -> health_score`; `savingsRate -> savings_rate`; `categoryBreakdown -> category_breakdown_json`; `createdAt -> created_at` | Derived data; sync late. |
| `AppSettings.lastExportDate` | none initially | Optional future mapping to `user_settings.last_export_at` or separate export table | Not required for Phase 2 financial sync MVP. |

### Mapping notes

- Local IDs:
  - Most entities already have `id: UUID`.
  - `FinancialCategory` also has `uniqueID`, which matters for seeded categories.
- Remote IDs:
  - Supabase should have both a server `id` and a stable `client_record_id`.
- Category references:
  - Current category references are mostly string-based, not relational.
- Recurring references:
  - one-time generated rows currently point to recurring sources through `sourceType` / `sourceID`.
- Date fields:
  - Keep all timestamps in UTC remotely.
- Currency fields:
  - Local entities generally do not store row-level currency today; the app largely relies on app-level preferred currency.
  - Remote schema should allow a future `currency_code` column where financially useful.
- Archived/deleted state:
  - `SavingsGoal` already supports archive state.
  - Other entities currently hard-delete and will need future tombstone handling.

---

## 7. Sync Identity Strategy

### Core rule

Local Core Data object IDs are **not** sufficient for cross-device sync.

Phase 2 should use:

- stable `client_record_id` on every synced local record
- server-side `id`
- unique constraint on `(user_id, client_record_id)`

### Recommended matching strategy

For every synced row:

- local record keeps a stable `client_record_id`
- remote row keeps:
  - `id`
  - `user_id`
  - `client_record_id`

Matching should always be by:

- `user_id + client_record_id`

### Analysis of current model readiness

#### Entities that already have usable UUID-style local identity

- `SavingsGoal.id`
- `Subscription.id`
- `Bill.id`
- `BillPayment.id`
- `RecurringTransaction.id`
- `FinancialSnapshot.id`
- `FinancialCategory.id`

These can usually seed `client_record_id` later.

#### Where current UUIDs are not enough

`FinancialCategory` seeded rows are the main problem.

- Seeded rows get a local `id = UUID()` at install time.
- Different devices will generate different local UUIDs for the same seeded category.
- Matching seeded categories across devices by local `id` would create duplicates.

### Recommended identity rule by data type

- User-created standalone records:
  - use existing local UUID as `client_record_id`
- Seeded `FinancialCategory` rows:
  - derive stable identity from logical key, for example:
    - `seed:<type>:<uniqueID>:<frequency>`
- Custom categories:
  - use existing UUID-backed `id` as `client_record_id`
- One-time transactions:
  - use current row `id` as `client_record_id`
- Bill payments:
  - use payment `id` as `client_record_id`, and resolve parent by bill identity

### Migration implication

Most models already contain enough identity data to support a future migration, but Phase 2 will still need a local metadata addition later so the app can persist:

- `client_record_id`
- sync state
- remote timestamps

`FinancialCategory` will require the most careful migration because seeded row identity cannot rely on current random local UUIDs.

---

## 8. Offline Sync Strategy

### MVP sync flow

1. user edits local Core Data first
2. local record is marked dirty / pending sync
3. when internet is available, app uploads changed rows
4. Supabase returns canonical `updated_at`
5. local record is marked synced
6. failed upload remains pending
7. retry later

### Minimum local sync metadata needed

Per synced record, the future local model should carry:

- `client_record_id`
- `sync_status`
  - example values: `pending`, `synced`, `failed`, `deleted_pending`
- `last_synced_at`
- `remote_updated_at`
- `deleted_at` or `is_deleted`
- optional `sync_error`

### Additional recommendation

For relationship-bearing child rows, future local storage should also preserve stable parent identity, not just object references. Example:

- `BillPayment` should be able to resolve its parent bill by stable client identity

### Phase 1 pattern worth reusing

Phase 1 already uses a lightweight local-mutation-vs-server-timestamp pattern in `SupabaseAccountDataService`.

That pattern should be extended in a stronger way for Phase 2:

- track per-record pending state
- store last server timestamp
- do not rely only on `UserDefaults` keys for financial records

---

## 9. Conflict Resolution Strategy

### Conflict options considered

- last-write-wins
- server `updated_at`
- client-side `client_updated_at`
- per-field merge
- user-visible conflict resolution

### Recommended MVP rule

Use **last-write-wins** for most Phase 2 financial fields, with explicit tombstone protection.

Recommended behavior:

- compare remote `updated_at` vs local pending mutation timestamp
- newer write wins
- never silently resurrect or delete rows without checking tombstones

### Why not per-field merge in MVP

- The current data model is not normalized enough for safe field-level merging.
- `FinancialCategory` in particular is too overloaded for silent smart merges.
- Multi-device financial merges are high-trust operations; simple deterministic rules are safer first.

### Future improvement path

Later improvements can add:

- `client_updated_at`
- record versioning
- user-visible conflict review for destructive edge cases

---

## 10. Delete / Archive Strategy

### Required behavior

- use soft delete with `deleted_at`
- use tombstones for sync propagation
- allow hard delete only after retention/cleanup conditions are satisfied

### Why soft delete is necessary

Current local code hard-deletes many financial rows. That is unsafe for cross-device sync because:

- another device may still hold an older copy
- a deleted row may otherwise reappear on next merge

### Recommended rules

- Local delete:
  - mark row deleted locally
  - set `deleted_at`
  - sync tombstone to Supabase
- Remote delete:
  - remote row receives `deleted_at`
  - other devices apply delete locally rather than hard-deleting immediately
- Hard delete:
  - allowed only in later cleanup passes
  - never in initial sync path

### Archive behavior

- Preserve separate archive semantics where the product already has them.
- `SavingsGoal.isArchived` should remain a business-state field and should **not** be treated as deletion.

### Delete-account behavior

- delete all financial rows by `user_id`
- preserve safe child-before-parent order where FKs exist
- delete auth user last

---

## 11. RLS and Security

### Required rules

- every financial table must include `user_id`
- RLS enabled on every financial table
- user can only access own records
- no anonymous access
- no cross-user relationships
- insert/update/delete policies must all be explicit

### Policy intent

For every financial table:

- `SELECT`:
  - allow only rows where `(select auth.uid()) = user_id`
- `INSERT`:
  - allow only rows where inserted `user_id` matches `auth.uid()`
- `UPDATE`:
  - allow only rows owned by current user
  - require `WITH CHECK` so ownership cannot be changed
- `DELETE`:
  - owner-only if client-side delete is permitted

### Special warning

**Foreign keys alone are not enough; relationship ownership must also be enforced.**

Examples:

- A `bill_payments.bill_id` FK to `bills.id` is not sufficient by itself.
- The write path must also ensure that the referenced bill belongs to the same `user_id`.

### Additional requirements

- do not rely on client-supplied ownership without policy enforcement
- no cross-user linking in child tables
- no public views over exposed financial tables
- no `SECURITY DEFINER` shortcuts for client-facing data access

---

## 12. Index and Performance Plan

### Common indexes

Most financial tables should have:

- `(user_id, updated_at desc)`
- `(user_id, deleted_at)`
- `(user_id, client_record_id)`

### Table-specific recommendations

#### `savings_goals`

- `(user_id, updated_at desc)`
- `(user_id, is_archived)`
- `(user_id, target_date)`

#### `subscriptions`

- `(user_id, updated_at desc)`
- `(user_id, is_active)`
- `(user_id, next_renewal_date)`

#### `bills`

- `(user_id, updated_at desc)`
- `(user_id, due_date)`
- `(user_id, is_paid)`
- `(user_id, is_recurring)`

#### `bill_payments`

- `(user_id, updated_at desc)`
- `(user_id, bill_id)`
- `(user_id, paid_date)`

#### `recurring_transactions`

- `(user_id, updated_at desc)`
- `(user_id, next_due_date)`
- `(user_id, is_active)`
- `(user_id, category_type)`

#### `financial_categories`

- `(user_id, updated_at desc)`
- `(user_id, category_key)`
- `(user_id, type)`
- `(user_id, is_active)`

#### `one_time_transactions`

- `(user_id, updated_at desc)`
- `(user_id, occurrence_date desc)`
- `(user_id, category_key)`
- `(user_id, type, occurrence_date desc)`

#### `financial_snapshots`

- `(user_id, updated_at desc)`
- `(user_id, snapshot_type, snapshot_date desc)`

### Why this matters

These indexes cover the dominant expected sync/query patterns:

- fetch changed rows by user
- fetch active rows by user
- fetch date-based financial lists
- resolve row identity by `client_record_id`
- filter tombstoned rows efficiently

---

## 13. Migration Strategy From Existing Local Data

### First principles

- do not overwrite remote data blindly
- do not duplicate local seeded/config rows
- do not remove Backup & Restore during migration

### Recommended first sign-in behavior after Phase 2 launches

1. detect authenticated user
2. inspect local financial data presence
3. inspect remote table presence for that user
4. choose initial sync strategy

### Recommended initial sync rules

#### Case A: Local data exists, remote is empty

- upload local data as initial cloud state
- mark uploaded rows as synced

#### Case B: Remote data exists, local is empty

- pull remote data into local store

#### Case C: Local data exists and remote data exists

- do **not** blindly merge
- run entity-specific merge rules
- prefer explicit review or guarded import behavior for risky domains

### Duplicate prevention requirements

- enforce `(user_id, client_record_id)` remotely
- derive stable seeded category identity
- avoid treating seeded categories from two devices as different user-created records

### Transition safeguard

Keep Backup & Restore available throughout the migration period so a user can recover if initial sync behavior is wrong.

---

## 14. Backup & Restore Transition

- Backup & Restore should stay until financial sync is stable.
- It should remain the fallback recovery path during Phase 2 rollout.
- Current backup logic should **not** be removed as part of Phase 2 planning.
- Once structured sync is proven reliable, the UI can later be renamed or reduced to reflect its recovery role instead of implying primary continuity.

Recommended product transition:

1. keep backup as-is during early financial sync rollout
2. validate restore and delete-account behavior against synced data
3. only later reduce backup prominence

---

## 15. Delete Account Update Requirements

Future delete-account work must:

- delete all Phase 2 financial tables by `user_id`
- preserve safe delete order
- avoid broad, unscoped deletes
- be idempotent
- delete auth user last

Recommended delete order once Phase 2 exists:

1. `bill_payments`
2. `one_time_transactions`
3. `financial_snapshots`
4. `recurring_transactions`
5. `bills`
6. `subscriptions`
7. `financial_categories`
8. `savings_goals`
9. Phase 1 tables and backup tables
10. auth user last

Exact order can vary with final foreign keys, but child rows must always be removed before parent rows.

---

## 16. Testing Plan

### Security tests

- RLS tests on every financial table
- user A cannot read user B financial data
- user A cannot update or delete user B financial data
- child-table ownership tests
  - example: user A cannot insert `bill_payments` linked to user B bill

### Sync behavior tests

- local create syncs to Supabase
- local update syncs
- local delete syncs as `deleted_at`
- offline create syncs when online later
- failed upload remains pending and retries
- reinstall + sign-in pulls financial data
- duplicate prevention for initial sync
- seeded-category identity does not create duplicates

### Relationship tests

- `BillPayment` resolves only to user-owned bill
- one-time recurring-generated rows preserve recurring source identity

### Migration / transition tests

- first signed-in upload when remote empty
- guarded behavior when remote already has rows
- Backup & Restore still works during transition
- delete account removes all financial data

### Derived data tests

- financial snapshots sync correctly when included
- snapshot retention cleanup does not break sync state

---

## 17. Risk Assessment

### Data loss

Highest risk if hard deletes remain in place without tombstones.

### Duplicate records

Highest risk in:

- seeded `FinancialCategory` rows
- initial migration from local-only to remote
- multi-device first-sync scenarios

### Broken relationships

Highest risk in:

- `BillPayment.billID`
- recurring-generated one-time rows using `sourceID`

### Multi-device conflicts

Likely around:

- savings goal amount updates
- subscription edits
- bill paid/unpaid toggles
- recurring schedule edits

### Offline queue bugs

Risk increases if pending-state metadata is bolted on inconsistently across entities.

### RLS misconfiguration

High severity because this data is sensitive financial information.

### Migration mistakes

Particularly dangerous for:

- seeded categories
- remote-existing plus local-existing first sync

### App Store privacy implications

Syncing structured financial data to Supabase likely affects data handling disclosures and privacy review. Product/legal review should confirm:

- what financial data is stored remotely
- retention/deletion guarantees
- cross-device account behavior language

### Performance at scale

Likely manageable for MVP if:

- sync is incremental by `updated_at`
- indexes are in place
- snapshots are synced late or selectively

---

## 18. Recommended Implementation Phases

### Phase 2A: local sync metadata foundation

- Scope:
  - add per-record sync metadata plan to local financial entities
  - define stable `client_record_id` strategy
  - define tombstone behavior
- Files likely touched later:
  - Core Data model
  - backup payload contracts
  - serializers/importers
  - future sync state services
- Migration needed later: Yes
- Tests:
  - identity migration
  - dirty/pending state persistence
  - tombstone handling
- Risk: High because it touches every later sync stage

### Phase 2B: `savings_goals` table + sync

- Scope:
  - remote table
  - RLS
  - create/update/archive/delete sync
  - initial migration behavior
- Files likely touched later:
  - Supabase migrations
  - delete-account cleanup
  - savings goal manager / view model integration
  - sync service
- Migration needed later: Yes
- Tests:
  - CRUD sync
  - archive vs delete
  - initial upload/download
- Risk: Medium

### Phase 2C: `subscriptions` table + sync

- Scope:
  - remote table
  - sync lifecycle for active/paused state
- Files likely touched later:
  - Supabase migrations
  - delete-account cleanup
  - subscription manager / view model integration
  - sync service
- Migration needed later: Yes
- Tests:
  - create/update/pause/resume/delete
  - next-renewal state sync
- Risk: Medium

### Phase 2D: `bills` then `bill_payments`

- Scope:
  - bill parent rows first
  - payment history second
  - ownership-safe child linking
- Files likely touched later:
  - Supabase migrations
  - delete-account cleanup
  - bill manager / bill views
  - payment-history logic
- Migration needed later: Yes
- Tests:
  - bill CRUD
  - payment history creation
  - parent/child ownership rules
- Risk: Medium-High

### Phase 2E: `recurring_transactions`

- Scope:
  - recurring schedule sync
  - process-due behavior compatibility
- Files likely touched later:
  - Supabase migrations
  - recurring transaction view model
  - background processing service
  - sync service
- Migration needed later: Yes
- Tests:
  - create/update/delete
  - active toggle
  - next-due updates
  - recurring automation interaction
- Risk: Medium-High

### Phase 2F: `financial_categories` and `one_time_transactions`

- Scope:
  - split current local `FinancialCategory` behaviors into safer remote sync rules
  - seeded/custom dedupe rules
  - one-time financial entry sync
- Files likely touched later:
  - Core Data migration code
  - category validation/write support
  - income/expense view models
  - export/summary mapping
  - Supabase migrations
- Migration needed later: Yes, and likely the trickiest one
- Tests:
  - seeded identity matching
  - custom category sync
  - one-time create/update/delete
  - duplicate prevention across devices
- Risk: High

### Phase 2G: `financial_snapshots`, migration hardening, backup transition

- Scope:
  - sync derived historical data only after primary entities are stable
  - harden first-sync migration and recovery flows
  - keep backup as fallback
- Files likely touched later:
  - historical data service
  - Supabase migrations
  - delete-account cleanup
  - backup/recovery UX
- Migration needed later: Yes
- Tests:
  - snapshot retention behavior
  - reinstall recovery
  - backup fallback continuity
- Risk: Medium

---

## 19. Final Recommendation

### Safest first financial entity to sync

`savings_goals`

Reason:

- standalone
- no child table
- stable local UUID
- existing `createdAt` / `lastModified`
- existing archive/completion semantics

### Data that should **not** move first

Do **not** start with:

- `FinancialCategory`
- one-time transaction rows stored inside `FinancialCategory`
- `FinancialSnapshot`

Reason:

- `FinancialCategory` is overloaded and seeded per install
- one-time entries depend on that overloaded model
- snapshots are derived and lower-value than source records

### Ownership of the future implementation work

Recommended division:

- Supabase schema/RLS/delete-account design:
  - **stronger-model reviewed work**
- Swift/Core Data sync integration:
  - **Codex or Cursor can implement**, but only after schema and identity strategy are reviewed
- Current Phase 1 Swift integration:
  - leave with **Cursor** as already assigned

### Exact next action after this planning document

The next step should **not** be full sync implementation.

Recommended next prompt:

> Create a Phase 2B `savings_goals` Supabase migration specification and test plan only. Do not write SQL yet. Do not modify Swift. Include table schema, RLS policy intent, delete-account updates, local sync metadata requirements, and rollout risks.

That keeps Phase 2 moving while preserving isolation from the active Phase 1 Swift integration work.

---

## 20. Implementation Status (Updated June 2026)

| Entity | SQL Migration | Swift Sync | Status |
|---|---|---|---|
| `savings_goals` | `0006_phase2b_savings_goals.sql` | `SupabaseSavingsGoalSyncService` | **Complete** (Phase 2B) |
| `subscriptions` | `0008_phase2c_subscriptions_bills_recurring.sql` | `SupabaseSubscriptionSyncService` | **Complete** (Phase 2C) |
| `bills` | `0008_phase2c_subscriptions_bills_recurring.sql` | `SupabaseBillSyncService` | **Complete** (Phase 2C) |
| `bill_payments` | `0008_phase2c_subscriptions_bills_recurring.sql` | `SupabaseBillPaymentSyncService` | **Complete** (Phase 2C) |
| `recurring_transactions` | `0008_phase2c_subscriptions_bills_recurring.sql` | `SupabaseRecurringTransactionSyncService` | **Complete** (Phase 2C) |
| `financial_categories` | — | — | Phase 3 (deferred) |
| `one_time_transactions` | `0007_phase3a_one_time_transactions.sql` | Phase 3A track | Separate from Phase 2 |
| `financial_snapshots` | — | — | Deferred |

Core Data model **v6** adds sync metadata on Subscription, Bill, BillPayment, and RecurringTransaction. Sign-in bootstrap runs `SupabasePhase2FinancialSyncBootstrap` after savings goals. BackupService and CloudKit retained.
