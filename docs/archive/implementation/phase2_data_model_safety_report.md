# Phase 2 — Data Model Safety Report

**Date:** 2026-06-16  
**Phase:** 2 — Data Model Safety (documentation only)  
**Sources:** `docs/product_decisions_v1.md`, `docs/implementation/data_model_migration_plan.md`, `docs/implementation/phase0_codebase_audit_report.md`, `docs/implementation/phase1_calculation_contract_report.md`, current CoreData model and Swift usage (read-only inspection)

---

## Executive Summary

BudgetMeter’s local store is **CoreData model version 2** (`BudgetMeter 2.xcdatamodel`), CloudKit-enabled, with **eight entities and zero relationships**. All entities are flat; links are by UUID strings only.

**Usage reality:**

| Entity | In schema | Used in app code |
| --- | --- | --- |
| `AppSettings` | Yes | **Active** — singleton app config |
| `FinancialCategory` | Yes | **Core** — income/expense pace inputs |
| `RecurringTransaction` | Yes | **Active** — premium automation pipeline |
| `FinancialSnapshot` | Yes | **Active** — history/analytics |
| `Subscription` | Yes | **Active** — expense rollup (Expenses tab) |
| `Bill` | Yes | **Active** — bill management UI |
| `SavingsGoal` | Yes | **Active** — goals feature + Home display |
| `BillPayment` | Yes | **Schema only** — no Swift reads/writes |

The Phase 1 contract requires `FinancialSummaryInput` with recurring lines, one-time lines, dedupe keys, and occurrence dates. **The current schema cannot fully support that contract** without additive changes to `FinancialCategory` and a documented migration for legacy rows.

**Live-user risk:** Appears low (minimal/no active users), but CloudKit sync is enabled and the app is technically live. Phase 2 implementation must still use **additive, lightweight migrations**, explicit migration versioning, export-before-migrate gates, and no entity deletion in v1.

**Recommendation:** **Ready for schema implementation** — decisions below are specific enough to implement. Do not start CoreData edits until pre-migration tests and a backup/export gate are in place.

---

## Contract Questions — Direct Answers

### 1. Which current entities are actually used?

| Entity | Status | Primary readers/writers |
| --- | --- | --- |
| **AppSettings** | Active | `HomeViewModel`, `SettingsViewModel`, `PremiumManager`, `ThemeManager`, `BiometricManager`, `NotificationService`, `HistoricalDataService`, `DataSeedingService`, widgets (read-only), most feature ViewModels (currency) |
| **FinancialCategory** | Active (core) | `HomeViewModel`, `IncomeViewModel`, `ExpenseViewModel`, `InsightsService`, `HistoricalDataService`, `HealthDetailsViewModel`, `DataSeedingService`, `CategoryValidationService`, `CustomCategoryMigrationService`, `DataExportService`, `NotificationService`, widgets, `BackgroundProcessingService`, `RecurringTransactionsViewModel` |
| **RecurringTransaction** | Active | `RecurringTransactionsViewModel`, `BackgroundProcessingService`, `DataExportService` |
| **FinancialSnapshot** | Active | `HistoricalDataService`, `InsightsService`, `InsightsViewModel`, `BackgroundProcessingService`, `NotificationService` |
| **Subscription** | Active | `SubscriptionManager`, `SubscriptionsViewModel`, `ExpenseViewModel`, subscription feature views |
| **Bill** | Active | `BillManager`, `BillsViewModel`, bill feature views |
| **SavingsGoal** | Active | `SavingsGoalManager`, `SavingsGoalsViewModel`, `HomeViewModel`, savings feature views |
| **BillPayment** | **Unused** | Defined in `BudgetMeter 2.xcdatamodel` only; `BillManager.markAsPaid` updates `Bill` fields directly, never creates `BillPayment` records |

**Model version:** Current store is **`BudgetMeter 2.xcdatamodel`** (per `.xccurrentversion`). Version 1 model lacks `Subscription`, `Bill`, `BillPayment`, `SavingsGoal`, and several `AppSettings` fields.

**Persistence stack:** `PersistenceService` uses `NSPersistentCloudKitContainer`, App Group path `group.com.budgetmeter.shared`, history tracking enabled. No entity-specific logic in `PersistenceService` — all access is via feature managers and ViewModels.

### 2. Which entities map to the new FinancialSummaryInput model?

From Phase 1 `FinancialSummaryInput`:

| Input bucket | Source entities | Current mapping quality |
| --- | --- | --- |
| `recurringIncomeLines` | `FinancialCategory` (`type=income`, recurring) | **Partial** — only `daily`/`monthly`/`yearly`; `frequency=recurring` excluded |
| `recurringExpenseLines` | `FinancialCategory` (`type=expense`, recurring) | **Partial** — same gap |
| | `Subscription` (active, not paused) | **Good** — separate entity, own cycle fields |
| | `Bill` (recurring, active/unpaid template) | **Partial** — not in pace pipeline today |
| | `RecurringTransaction` | **Indirect** — should feed builder as rule source, not as duplicate `FinancialCategory` spikes |
| `oneTimeIncomeLines` | *None today* | **Missing** — no dated one-time records |
| `oneTimeExpenseLines` | *None today* | **Missing** |
| | Legacy `FinancialCategory` with `frequency=recurring` | **Misclassified** — automation artifacts |
| `savingsTargetAmount` / `savingsCurrentAmount` | `SavingsGoal` + legacy `AppSettings.savingsGoalAmount` | **Dual source** |
| `currencyCode` | `AppSettings.preferredCurrencyCode` | **Good** |
| `cumulativeBaseline` / session | `AppSettings.cumulativeTotal`, live timer | **Good** (meta, not pace lines) |
| Historical comparison | `FinancialSnapshot` | **Read-only** — not input lines |

**Not mapped to input lines (meta/automation only):** `BillPayment` (unused), `AppSettings` premium/notification fields, `RecurringTransaction` schedule fields (map to lines via builder rules).

### 3. What fields are missing for the Phase 1 contract?

**On `FinancialCategory` (highest priority):**

| Missing field | Purpose |
| --- | --- |
| `entryKind` | `"recurring"` vs `"oneTime"` (product split) |
| `occurrenceDate` | Date for one-time entries; period bucketing |
| `sourceType` | `category`, `subscription`, `bill`, `recurringAutomation` |
| `sourceID` | Stable UUID string for dedupe (link to Subscription/Bill/RecurringTransaction) |
| `isActive` | Exclude archived/inactive lines from pace |
| `lastModified` | Migration ordering, sync conflict hints |

**Optional v1 (can derive in builder if omitted):**

| Field | Alternative |
| --- | --- |
| `linkedSubscriptionID` | Use `sourceType` + `sourceID` only |
| `linkedBillID` | Same |

**On `Subscription` / `Bill` (dedupe support):**

| Missing field | Purpose |
| --- | --- |
| `paceIncluded` or `mirrorsCategoryID` | Prevent double-count when user also entered same cost in `FinancialCategory` |
| `stableSourceKey` | Already have `id` UUID — sufficient if builder uses `subscription:<uuid>` / `bill:<uuid>` |

**On `RecurringTransaction`:**

| Missing field | Purpose |
| --- | --- |
| `sourceID` exposed to builder | Already has `id` |
| `generatedEntryPolicy` | Whether automation creates `FinancialCategory` rows or only virtual lines (product: prefer virtual) |

**On `SavingsGoal`:**

| Missing field | Purpose |
| --- | --- |
| `isPrimary` | Explicit v1 basic goal flag (or use sort rule) |

**On `AppSettings`:**

| Missing field | Purpose |
| --- | --- |
| `dataMigrationVersion` | Track local data migrations (can use UserDefaults instead) |

**System-level gaps:**

- No Core Data relationships (not blocking v1 if builder uses UUID keys).
- No occurrence/history entity for one-time transactions.
- `DataExportService` comment notes `FinancialCategory` has no date field — confirms one-time gap.

### 4. What is the simplest safe local data model for v1?

**Decision: extend existing entities; do not introduce a new money-line entity in v1.**

```
AppSettings          → app meta, currency, cumulative, deprecated savings fallback
FinancialCategory    → all user-entered income/expense + one-time records (extended)
Subscription         → recurring expense source (premium management)
Bill                 → recurring expense source + calendar due state (premium management)
RecurringTransaction → automation schedule (premium); builder reads directly
SavingsGoal          → savings targets (one primary for v1 free)
FinancialSnapshot    → historical aggregates (output cache, not input)
BillPayment          → postpone implementation
```

**v1 canonical flow:**

1. `FinancialSummaryBuilder` reads entities → builds `FinancialSummaryInput` in memory.  
2. No duplicate storage of computed pace.  
3. Subscriptions/bills contribute **virtual recurring lines** in the builder unless explicitly linked to a category row (dedupe).  
4. One-time entries live on `FinancialCategory` with `entryKind=oneTime` + `occurrenceDate`.

This is the smallest change set that satisfies Phase 1 without a greenfield schema.

### 5. How should one-time vs recurring be represented?

**Storage decision (v1):**

| Kind | Representation |
| --- | --- |
| **Recurring income/expense** | `FinancialCategory` with `entryKind = "recurring"` (default for legacy rows) AND `frequency` in `daily` \| `weekly` \| `monthly` \| `yearly` |
| **One-time income/expense** | `FinancialCategory` with `entryKind = "oneTime"`, required `occurrenceDate`, `frequency` optional or `"once"` |
| **Subscription** | `Subscription` entity → builder maps to recurring expense line (`sourceType=subscription`) |
| **Recurring bill** | `Bill` with `isRecurring=true` → builder maps to recurring expense line |
| **Recurring automation** | `RecurringTransaction` → builder maps by schedule; **stop creating orphan `FinancialCategory` rows** in new code |

**Default for legacy rows:** If `entryKind` is nil after migration → treat as **`recurring`** (preserves current pace behavior for seeded categories).

**Product alignment:** Matches `docs/product_decisions_v1.md` — recurring normalizes to baseline; one-time affects period only.

### 6. How should occurrence dates be represented?

| Record type | Occurrence / schedule field | Used for |
| --- | --- | --- |
| One-time `FinancialCategory` | `occurrenceDate` (new, required when `entryKind=oneTime`) | Period totals, charts, biggest drain |
| Recurring `FinancialCategory` | Existing `frequency` + `amount` | Baseline pace normalization |
| `Subscription` | `firstBillDate`, `nextRenewalDate`, `billingCycle` | Recurring pace + premium renewal UI |
| `Bill` | `dueDate`, `originalDueDate`, `frequency` | Recurring pace + calendar due UI |
| `RecurringTransaction` | `startDate`, `nextDueDate`, `endDate` | Automation schedule |
| `BillPayment` (future) | `paidDate` | Payment history — postponed |

**Fallback for migrated legacy `frequency=recurring` rows:** Set `occurrenceDate = createdAt ?? lastProcessedDate ?? migrationDate` and `entryKind=oneTime` if no linked `RecurringTransaction`; otherwise delete orphan row and use RT in builder.

### 7. How should subscriptions and bills roll into regular expenses?

**Rollup decision (matches Phase 1 + product decisions):**

1. **Builder-owned rollup** — subscriptions and bills are **first-class recurring expense sources**, not optional add-ons in `ExpenseViewModel` only.  
2. **Normalization** — map each active subscription/bill to a `RecurringMoneyLine` with real cycle → daily via `CalculationEngine` constants.  
3. **No mandatory mirror row** — do not require a duplicate `FinancialCategory` for every subscription/bill.  
4. **Optional user mirror** — if user entered rent in `FinancialCategory` AND created a `Bill` for same cost, **dedupe by `sourceID` or manual link** (prefer subscription/bill entity, suppress category duplicate).  
5. **Calendar bill UI** (`getTotalDueThisMonth`) stays separate from pace — it is a management view, not the pace engine.

**v1 free tier:** User can enter subscription/bill cost as basic `FinancialCategory` **or** use premium Subscription/Bill features — builder merges both with dedupe.

### 8. How should duplicate records be avoided?

**Dedupe key format:**

```
{sourceType}:{uuid}
```

Examples: `category:<FinancialCategory.id>`, `subscription:<Subscription.id>`, `bill:<Bill.id>`, `recurring:<RecurringTransaction.id>`.

**Rules:**

| Scenario | Rule |
| --- | --- |
| Subscription + same amount in category | If `FinancialCategory.sourceID` points to subscription → count once. If no link but same name+amount+cycle → flag for manual review in migration; default: prefer subscription entity. |
| Bill + category duplicate | Prefer `bill:<id>` when `Bill.isRecurring` and amounts match. |
| RecurringTransaction automation | **Do not** also count generated `FinancialCategory` rows — either link via `sourceID=recurring:<rt.id>` or migrate/delete orphans. |
| Seeded categories | Each has unique `uniqueID`; no dedupe across seeds unless user entered overlapping custom data. |

**New fields enabling dedupe:** `FinancialCategory.sourceType`, `FinancialCategory.sourceID` (optional, set when row mirrors or is generated from another entity).

### 9. What should happen to `frequency = "recurring"` legacy rows?

**Created by:** `RecurringTransactionsViewModel.createTransactionFromRecurring` and `BackgroundProcessingService.createTransactionFromRecurring`.

**Problem:** Home/Income/Expense filters only `daily`/`monthly`/`yearly` — these rows are **invisible to pace** but accumulate in CoreData.

**Migration plan (non-destructive):**

| Step | Action |
| --- | --- |
| 1 | Export/debug dump before migration (support gate) |
| 2 | Fetch all `FinancialCategory` where `frequency == "recurring"` |
| 3 | For each row, try match to `RecurringTransaction` by amount + type + approximate date |
| 4a | **If matched:** set `sourceType=recurringAutomation`, `sourceID=recurring:<rt.id>`, `entryKind=oneTime`, `occurrenceDate=createdAt`, then **exclude from recurring baseline** OR delete row if RT alone feeds builder (preferred: delete orphan after linking policy) |
| 4b | **If unmatched orphan:** set `entryKind=oneTime`, `occurrenceDate=createdAt`, map `frequency` to inferred cycle if amount pattern suggests recurring user intent, else keep as one-time spike |
| 5 | Update automation code (later) to stop creating new `frequency=recurring` categories |
| 6 | Set `UserDefaults` / `AppSettings` migration flag `financialDataMigrationVersion = 1` |

**Do not silently delete** without export gate, even with low user counts.

### 10. What should happen to dual savings sources: `AppSettings.savingsGoalAmount` vs `SavingsGoal`?

**v1 source-of-truth decision:**

| Priority | Source | Use |
| --- | --- | --- |
| 1 | **Primary active `SavingsGoal`** | Target amount, current amount, Home basic ETA |
| 2 | `AppSettings.savingsGoalAmount` | Legacy fallback only |

**Primary goal selection rule:** First active non-archived `SavingsGoal` sorted by `createdAt` ascending (or lowest `priority` if set). Product v1 free = **one** basic goal — UI should gate multiple goals in Phase 6/7, not schema.

**Migration:**

```
IF AppSettings.savingsGoalAmount > 0 AND no active SavingsGoal:
    CREATE SavingsGoal(name: "My Goal", targetAmount: savingsGoalAmount, currentAmount: 0)
    Optionally SET AppSettings.savingsGoalAmount = 0 after copy (or leave for rollback)
```

**Home ETA:** Always `CalculationEngine.targetTime(remaining, netRecurringDaily/24)` from shared summary — never `SavingsGoalManager.calculateRequiredMonthlyContribution` for basic Home card.

**Postpone:** Removing `AppSettings.savingsGoalAmount` attribute (keep until CloudKit/Supabase migration complete).

### 11. What CoreData changes are actually required?

**Model version 3 (additive lightweight migration):**

**`FinancialCategory` — add attributes:**

| Attribute | Type | Default | Notes |
| --- | --- | --- | --- |
| `entryKind` | String | `"recurring"` | `recurring` \| `oneTime` |
| `occurrenceDate` | Date | optional | Required when oneTime |
| `sourceType` | String | optional | Dedupe / lineage |
| `sourceID` | String | optional | `{type}:{uuid}` |
| `isActive` | Boolean | `YES` | Soft-disable without delete |
| `lastModified` | Date | optional | Set on write |

**No required changes to:** `Subscription`, `Bill`, `SavingsGoal`, `FinancialSnapshot`, `RecurringTransaction`, `AppSettings` for v1 pace contract (optional `SavingsGoal.isPrimary` can wait).

**`BillPayment`:** No v1 changes — entity remains dormant.

**CloudKit:** New attributes must be optional or have defaults for lightweight migration. Plan CloudKit schema deploy before shipping.

**Migration mapping model:** Create `BudgetMeter 3.xcdatamodel` with additive fields only; set as current version; use inferred mapping.

### 12. What can be postponed?

| Item | Postpone to |
| --- | --- |
| `BillPayment` implementation & relationships | Post-v1 / premium bill history |
| Core Data entity relationships | Optional forever if UUID keys suffice |
| New `FinancialEntry` entity | Avoid in v1 — extend `FinancialCategory` |
| Removing `AppSettings.savingsGoalAmount` | Phase 9+ / Supabase migration |
| CloudKit removal | Phase 9 |
| Supabase schema / RLS / sync | Phase 9 |
| `linkedCategoryID` on Subscription/Bill | Phase 5+ if dedupe heuristics insufficient |
| `SavingsGoal.isPrimary` flag | Phase 6 — use sort rule first |
| Entity deletion (CustomCategory remnants) | Already migrated via UserDefaults flag |
| Weekly frequency on Income/Expense UI buckets | Phase 5 — schema can accept `weekly` in `frequency` early |

### 13. What migration risks remain if user data is minimal?

| Risk | Severity (minimal users) | Mitigation |
| --- | --- | --- |
| Lightweight migration failure | Low | Additive optional fields only; test on copy of store |
| CloudKit sync conflict after schema bump | Medium | Deploy CloudKit schema; test on dev container first |
| Orphan `frequency=recurring` cleanup | Medium | Export before delete; default to oneTime reclassification not delete |
| Dual savings migration creates duplicate goals | Low | Idempotent migration: check existing goals first |
| Dedupe false positive (merged distinct entries) | Low | Conservative dedupe: only when `sourceID` explicit |
| App Group store path mismatch | Medium | Verify entitlements before widget phase — not schema blocker |
| User with only seeded categories | Very low | `entryKind` default `recurring` preserves behavior |
| DataExport omits Subscription/Bill/SavingsGoal | Low | Extend export in Phase 5+ — not blocking pace |

**Even with minimal users:** treat migration as **idempotent**, **versioned**, and **logged**. Never destructive first pass.

### 14. What tests are needed before schema changes?

| ID | Test | Purpose |
| --- | --- | --- |
| M1 | Lightweight migration opens v2 store with v3 model | No crash, defaults applied |
| M2 | Legacy category rows get `entryKind=recurring` | Pace unchanged |
| M3 | `frequency=recurring` migration scenarios | Matched RT, orphan, empty |
| M4 | Savings migration AppSettings → SavingsGoal | Idempotent |
| M5 | Builder maps categories + subscriptions without double count | Dedupe |
| M6 | Builder maps bills as recurring expense | Rollup |
| M7 | One-time row affects period only, not baseline | After schema |
| M8 | CloudKit-exported store migrates locally | Optional integration |
| M9 | Export JSON before/after migration | Manual recovery gate |
| M10 | Rollback plan: migration version flag disables re-run | Safety |

**Prerequisite:** Wire `budgetmeter.iosTests` into Xcode scheme (Phase 2 implementation step 1 — requires project edit when approved).

**Fixtures needed:** In-memory `NSPersistentContainer` with v2 seed data → migrate → assert v3.

### 15. What exact implementation sequence should Phase 2 use later?

**Phase 2 implementation (when code changes are approved):**

```
Step 1  — Xcode: add/verify unit test target; in-memory CoreData test harness
Step 2  — Create BudgetMeter 3.xcdatamodel (additive fields on FinancialCategory only)
Step 3  — Set current model version; lightweight migration mapping
Step 4  — Add FinancialDataMigrationService (UserDefaults version key = 1)
          4a  Default entryKind on existing FinancialCategory rows
          4b  Reclassify frequency=recurring rows (Section 9)
          4c  Consolidate AppSettings savings → SavingsGoal if needed
Step 5  — Unit tests M1–M7 pass on in-memory stores
Step 6  — Manual QA: fresh install, upgrade from v2 store, CloudKit dev account
Step 7  — Implement FinancialSummaryBuilder (Phase 1 calc) reading new fields
Step 8  — Stop creating frequency=recurring categories in RT automation
Step 9  — Update HistoricalDataService snapshot inputs to use builder (Phase 3 prep)
Step 10 — Document migration release notes; keep export-before-upgrade path
```

**Explicitly not in Phase 2 implementation:** Home UI redesign, widget target, Supabase, premium gate changes, BillPayment, entity deletion.

---

## Current Entity Inventory

**Active model:** `BudgetMeter 2.xcdatamodel` (`usedWithCloudKit="YES"`)

| Entity | Attributes (count) | Relationships | CloudKit |
| --- | --- | --- | --- |
| AppSettings | 24 | 0 | syncable |
| FinancialCategory | 10 | 0 | syncable |
| RecurringTransaction | 13 | 0 | syncable |
| FinancialSnapshot | 12 | 0 | syncable |
| Subscription | 15 | 0 | syncable |
| Bill | 18 | 0 | syncable |
| BillPayment | 10 | 0 | syncable |
| SavingsGoal | 18 | 0 | syncable |

**Version 1 model** (`BudgetMeter.xcdatamodel`) contains only: AppSettings, FinancialCategory, RecurringTransaction, FinancialSnapshot.

---

## Entity Usage Map

| Entity | Read | Write | In pace today | In Phase 1 input |
| --- | --- | --- | --- | --- |
| AppSettings | Many | Settings, Home, Premium | Meta | Meta |
| FinancialCategory | Many | Income, Expense, seeding, RT automation | Partial | Primary lines |
| RecurringTransaction | RT feature, background | RT feature, background | Indirect (broken) | Schedule source |
| FinancialSnapshot | Insights, history | Background | Output cache | Comparison read |
| Subscription | Subscriptions, Expenses | SubscriptionManager | Expenses only | Recurring expense |
| Bill | Bills | BillManager | **No** | Recurring expense |
| BillPayment | — | — | — | Postponed |
| SavingsGoal | Savings, Home | SavingsGoalManager | Display only | Savings meta |

---

## Mapping to Phase 1 FinancialSummaryInput

| FinancialSummaryInput field | Entity / field source |
| --- | --- |
| `currencyCode` | `AppSettings.preferredCurrencyCode` |
| `asOf` | Generated at build time |
| `selectedPeriod` | UI state (not persisted) |
| `recurringIncomeLines[]` | `FinancialCategory` (`type=income`, `entryKind=recurring`, `frequency` valid) |
| `recurringExpenseLines[]` | `FinancialCategory` (`type=expense`, recurring) + `Subscription` + recurring `Bill` |
| `oneTimeIncomeLines[]` | `FinancialCategory` (`entryKind=oneTime`, `occurrenceDate`) — **after schema** |
| `oneTimeExpenseLines[]` | Same |
| `savingsTargetAmount` | Primary `SavingsGoal.targetAmount` → fallback `AppSettings.savingsGoalAmount` |
| `savingsCurrentAmount` | Primary `SavingsGoal.currentAmount` → default `0` |
| `cumulativeBaseline` | `AppSettings.cumulativeTotal` |
| `sessionElapsedSeconds` | Runtime (not CoreData) |

**RecurringTransaction → lines:** Builder emits virtual line from RT fields; does not read generated `FinancialCategory` orphans.

---

## Missing Fields / Schema Gaps

| Gap | Blocks | v1 required? |
| --- | --- | --- |
| No `entryKind` | One-time vs recurring | **Yes** |
| No `occurrenceDate` | Period one-time, charts | **Yes** |
| No `sourceType` / `sourceID` | Dedupe, automation cleanup | **Yes** |
| No `isActive` on category | Soft delete | Recommended |
| `frequency=recurring` legacy | Correct pace | Migration required |
| Bills not in builder | Home vs Bills disagree | Builder change, not schema |
| BillPayment unused | Payment history | No (v1) |
| No entity relationships | Join queries | No — UUID keys OK |
| Export lacks Subscription/Bill | Backup completeness | Phase 5+ |

---

## Recommended v1 Local Model

**Principle:** Smallest additive change to `FinancialCategory` + builder logic; keep all eight entities; no deletions.

**Canonical storage roles:**

- **Pace inputs:** Extended `FinancialCategory` + `Subscription` + recurring `Bill` + schedule from `RecurringTransaction`
- **Pace outputs / cache:** `FinancialSnapshot` (regenerated from builder)
- **Savings:** Single primary `SavingsGoal`
- **App config:** `AppSettings`
- **Unused placeholder:** `BillPayment`

**FinancialCategory after v3:**

```
Existing: amount, type, frequency, uniqueID, customName, isCustom, id, createdAt, ...
New:      entryKind, occurrenceDate, sourceType, sourceID, isActive, lastModified
```

---

## One-Time vs Recurring Model Decision

| Decision | Choice |
| --- | --- |
| Storage location | Same entity (`FinancialCategory`) with `entryKind` discriminator |
| Legacy default | `entryKind = recurring` when nil |
| One-time required fields | `occurrenceDate`, `amount`, `type` |
| Recurring required fields | `frequency` ∈ {daily, weekly, monthly, yearly}, `amount`, `type` |
| Subscriptions/bills | Separate entities → virtual recurring lines in builder |
| Automation | RT feeds builder directly; stop duplicating into FC |

---

## Bills/Subscriptions Rollup Decision

| Decision | Choice |
| --- | --- |
| Roll into pace? | **Yes** — via `FinancialSummaryBuilder` |
| Storage duplicate required? | **No** |
| Expense tab local math | **Remove** — read summary output (Phase 5) |
| Calendar due totals | Stay on `BillManager` for Bills UI only |
| Normalization owner | `CalculationEngine` only |
| Dedupe | `sourceID` keys; subscription/bill wins over orphan category |

---

## Savings Source-of-Truth Decision

| Layer | Source |
| --- | --- |
| v1 basic target | Primary active `SavingsGoal` |
| Legacy fallback | `AppSettings.savingsGoalAmount` until migrated |
| Current saved | `SavingsGoal.currentAmount` (default 0) |
| Time to target | Shared summary net hourly pace → `CalculationEngine.targetTime` |
| Target-date monthly requirement | Premium `SavingsGoalManager` — not Home basic |
| Multiple goals | Premium — gate in UI Phase 6/7; schema already supports multiple rows |

---

## Legacy Data Handling

| Legacy pattern | Handling |
| --- | --- |
| Seeded categories (`uniqueID` presets) | `entryKind=recurring`, unchanged pace |
| Custom categories | Same |
| `frequency=recurring` FC rows | Migration Section 9 |
| `AppSettings.savingsGoalAmount` | Copy to `SavingsGoal` if empty |
| v1 store without Subscription/Bill entities | Already on v2 — N/A for new installs |
| CustomCategory entity (pre-v2) | Already handled by `CustomCategoryMigrationService` |
| CloudKit records for removed fields | N/A — additive only |

---

## Required CoreData Changes

**Minimum v3 (required for contract):**

1. Add six attributes to `FinancialCategory` (see Section 11).  
2. New model version file + lightweight migration.  
3. `FinancialDataMigrationService` on first launch after upgrade.  

**Not required for v3:**

- New entities  
- Relationships  
- BillPayment changes  
- AppSettings attribute removal  

---

## Changes to Postpone

See Section 12. Summary: BillPayment, Supabase, CloudKit removal, entity deletion, new FinancialEntry entity, AppSettings savings field removal, widget/App Group work.

---

## Test Requirements

See Section 14. **Gate:** no schema merge until M1–M5 pass on in-memory stores.

---

## Implementation Sequence

See Section 15. Ten-step ordered sequence from test target → model v3 → migration service → builder → automation fix.

---

## Recommendation

| Verdict | Detail |
| --- | --- |
| **Phase 2 planning** | **Complete** — all 15 questions answered with concrete decisions |
| **Ready for schema implementation?** | **Yes** — proceed with additive `FinancialCategory` fields + versioned migration service |
| **Blockers before coding** | Approve Xcode test target + model version edit; run export-before-migrate on any real device store |
| **Next doc step** | Phase 2 implementation may begin; Phase 3 (Home) waits on builder + migration passing tests |

**Status rationale (not Blocked):** Product decisions, Phase 1 contract, and current entity audit converge on a single v1 approach (extend `FinancialCategory`, builder rollup, savings consolidation, legacy RT row migration). No unresolved product fork remains.

---

## Related Documents

- `docs/implementation/phase1_calculation_contract_report.md` — `FinancialSummaryInput` / builder contract  
- `docs/implementation/data_model_migration_plan.md` — migration planning scope  
- `docs/implementation/phase0_codebase_audit_report.md` — current usage audit  
- `docs/product_decisions_v1.md` — product rules for recurring/one-time/savings  

---

*End of Phase 2 report. No application source, CoreData, or Xcode files were modified.*
