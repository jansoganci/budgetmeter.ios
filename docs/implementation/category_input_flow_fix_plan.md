# Category Input Flow Fix Plan

**Status:** Planning only — no implementation in this document  
**Date:** 22 June 2026  
**Related findings:** `docs/premium_test_findings.md`  
**Related audits:** Income/Expense add-flow code audit (June 2026)

---

## 1. Purpose

This document plans the correct **product**, **data**, **UI**, and **technical** approach for fixing the Income/Expense category input flow in BudgetMeter iOS.

It is a **planning document only**. It does **not** implement code, change Core Data schema, or modify ViewModels/services in this phase.

Goals:

- Fix custom category creation and visibility
- Clarify one-time vs recurring behavior
- Support Unicode category names (Turkish, Arabic, Chinese, etc.) — emoji excluded from name field
- Improve duplicate detection and save error visibility
- Continue category creation smoothly into amount entry
- Preserve existing MVVM architecture, `FinancialCategory` entity, and calculation contracts

Aligned with:

- `DESIGN.md` — calm, low-friction input flows
- `docs/transformations/input_flows_transformation.md` — modal/sheet rules, preserve save logic
- `docs/transformations/income_expense_transformation.md` — shared Income/Expense hierarchy
- `docs/uiux_transformation_master_plan.md` — incremental, reviewable changes

---

## 2. Problems to Solve

| # | Problem | Current behavior / symptom |
|---|---------|---------------------------|
| P1 | **Unicode / non-English category names** | `CategoryValidationService.isValidCategoryName` allows only ASCII letters, digits, space, `-`, `(`, `)`. Turkish and many other scripts fail immediately with *"Category name contains invalid characters"*. |
| P2 | **Internal normalized category identity** | No dedicated normalized key. Duplicates compare raw `customName` + `type` + `frequency`. Custom categories set `uniqueID = nil`. Identity for calculations/backup uses `customName` or `uniqueID` ad hoc. |
| P3 | **One-time vs recurring flow confusion** | `CreateCategoryModal` uses a segmented control for entry type, but parent sections do not pass entry intent clearly. Users cannot tell which section a new item will land in. |
| P4 | **One-time frequency routing bug** | `IncomeView` / `ExpenseView` `oneTimeSection` calls `categoryList(..., frequency: "monthly", ...)`. Modal shows *"Monthly Income/Expense"* label and validates against `monthly` even for one-time creates. |
| P5 | **Recurring frequency picker + weekly section** | Recurring items inherit section frequency (daily/monthly/yearly) only. **Weekly** is supported in `FinancialCategoryWriteSupport.recurringFrequencies` and `FinancialSummaryBuilder` but **not** in `CategoryValidationService`, the create modal, or Income/Expense UI — there is no **Weekly** collapsible section today. |
| P6 | **Duplicate category rule** | Duplicates blocked by exact `customName` + `type` + `frequency`. One-time rows stored as `frequency = once` can bypass duplicate checks tied to `monthly`. Income/expense name collision is already separate by `type` (good). Product wants duplicate by **normalized name + type** only. |
| P7 | **Create → amount entry gap** | After save, modal closes and list refreshes. User must manually find the new row. Amount stays `0` until `FinancialEditSheet` is opened separately. |
| P8 | **Silent save failures** | `IncomeViewModel.updateAmount` / `ExpenseViewModel.updateAmount` (and color/delete paths) call `persistenceService.save()` without checking the `Bool` return. On failure, `PersistenceService` rolls back and posts a notification — UI shows nothing. |
| P9 | **Broken / weak alert handling** | `IncomeView` / `ExpenseView` use `.alert(isPresented: .constant(viewModel.errorMessage != nil))`, which is not a proper two-way binding and can behave inconsistently for load errors. |
| P10 | **Loading flash on refresh** | `loadIncomeCategories` / `loadExpenseCategories` set `isLoading = true` on every refresh, briefly replacing the screen with a spinner after save. Feels like failure. |

---

## 3. Product Decisions

### A. Category names

| Decision | Detail |
|----------|--------|
| Unicode allowed | Users may enter category names using Unicode letters from Turkish, Arabic, Chinese, and other writing systems. |
| Numbers & punctuation | Category names may include numbers, spaces, and simple punctuation (e.g. `. , - ' & ( )`). |
| Emoji in name field | **Not allowed.** The category name text field must reject emoji characters. |
| Emoji / icons | Visual expression belongs in the **existing icon picker** (`customIconName` / SF Symbol), not in the name string. |
| Display preserved | `customName` stores the user’s validated input (trimmed whitespace only; no emoji). |
| Internal key | Maintain a safe normalized identifier for duplicate checks and stable references. |
| Key format | English/ASCII-safe, slug-like where practical (e.g. `freelance`, `custom-a1b2c3`). |
| Display vs key | Normalized key must **never** replace the user-facing name in UI. |
| Duplicate key | Normalized duplicate comparison uses **text only** — emoji must not be part of the comparison key (and emoji cannot appear in names). |

**Implementation preference (no schema change):**

- Keep `customName` as display name.
- Assign `uniqueID` for custom categories to a generated internal slug/UUID (seeded categories keep canonical IDs like `rent`, `salary`).
- Duplicate checks use **normalized(customName) + type**, not raw string equality alone.
- Reject emoji at validation before save; do not strip emoji into the normalized key — block the name instead.

### B. One-time items

| Decision | Detail |
|----------|--------|
| No frequency UI | One-time flow must **not** ask the user for frequency. |
| Internal routing | `entryKind = oneTime` via `FinancialCategoryWriteSupport.applyMetadata`. |
| Internal frequency | `frequency = once` (existing model convention). |
| Helper copy | Short helper: one-time items count toward the **current month** (or selected period) — calm, non-technical. |
| Date | Keep optional occurrence date picker (already present); default to today. |

### C. Recurring items

| Decision | Detail |
|----------|--------|
| Frequency required | Recurring flow must show an explicit frequency picker. |
| Options | `daily`, `weekly`, `monthly`, `yearly` |
| Routing | Frequency drives section placement and `FinancialSummaryBuilder` interval mapping. |
| Weekly section | **Final decision:** weekly recurring categories get their own **Weekly** collapsible section. Do **not** hide weekly under Monthly or Daily. |
| Section order | Recurring sections on Income and Expense screens, in order: **1. Daily → 2. Weekly → 3. Monthly → 4. Yearly**, then One-Time. |
| Calculations | Must match existing `CalculationEngine` / `FinancialSummaryBuilder` expectations — verify weekly path only; do not change engine unless bug found. |

### D. Duplicate rule

| Rule | Detail |
|------|--------|
| Block when | Same **normalized name** + same **type** (`income` or `expense`) |
| Allow when | Same display name across income vs expense (e.g. "Transfer" income and "Transfer" expense) |
| Normalize | Case-insensitive, diacritic-insensitive, whitespace-collapsed comparison on **text characters only** |
| Do not use | Frequency as duplicate dimension (one-time vs recurring with same name should still conflict per product — **same normalized name + type** regardless of entry kind) |
| Emoji | Not part of name input; not part of normalized duplicate key |

> **Clarification:** If product later wants "Kira" as both monthly recurring and one-time surprise expense, that requires an explicit exception. Default plan: **one name per type**.

### E. Create category → amount entry

| Decision | Detail |
|----------|--------|
| Continuous flow | After successful category create, open amount entry immediately. |
| Reuse | Prefer existing `FinancialEditSheet` (same amount field, currency, save path). |
| No new model | Do not introduce a new entity or parallel backend flow. |
| Save path | Continue using `ViewModel.updateAmount` after amount entry. |

**Proposed sequence:**

1. Save category in modal  
2. Dismiss create modal  
3. Set `categoryToEdit` to the new `FinancialCategory`  
4. Present `FinancialEditSheet`  
5. On amount save → existing `updateAmount` + refresh  

### F. Error handling

| Decision | Detail |
|----------|--------|
| No silent failures | Every user-initiated save must surface failure. |
| Validation | Inline + alert for modal validation; calm copy. |
| Persistence | Propagate `PersistenceService.save()` failure to `errorMessage` or inline state. |
| Tone | Short, helpful messages — no stack traces, no blame. |
| Logic stability | Do not rewrite calculation or premium logic; minimal fixes only where bugs require it. |

**Example copy direction:**

- Validation: *"This name isn't valid. Try a shorter name without emoji or special symbols."* (Unicode letters must pass; emoji must not)
- Duplicate: *"You already have a category with this name."*
- Save: *"Couldn't save your change. Please try again."*

---

## 4. Technical Architecture Questions

Inspection of current code (June 2026):

### Which field stores user-facing category name?

| Source | Field / mechanism |
|--------|-------------------|
| Custom categories | `FinancialCategory.customName` |
| Seeded categories | Localized string via `FinancialCategory.uniqueID` → `DataSeedingService.displayName(for:)` |
| UI resolution | `DataSeedingService.displayName(for: FinancialCategory)` — custom → `customName`, else localized `uniqueID` |

### Which field behaves like internal category identity?

| Category kind | Identity field |
|---------------|----------------|
| Seeded | `uniqueID` (canonical slug, e.g. `rent`, `salary`) |
| Custom (today) | `uniqueID = nil`; identity falls back to `customName` or `id` (UUID) in summary/backup |
| Stable record ID | `id` (UUID) — persistence/backup primary key |

### Is there already a normalized key / uniqueID / customName distinction?

**Partially.**

- `uniqueID` + `customName` distinction exists for seeded vs custom.
- **No** persisted normalized duplicate key.
- `CategoryValidationService.createCustomCategory` explicitly sets `uniqueID = nil` for custom rows.
- `FinancialSummaryBuilder` uses `category.uniqueID ?? category.customName` as `categoryKey`.

**Gap:** Custom categories lack a stable ASCII internal key separate from Unicode display name.

### How does `FinancialCategoryWriteSupport.applyMetadata` set `entryKind` and `frequency`?

```text
applyMetadata(to:entryKind:recurringFrequency:occurrenceDate:)

recurring:
  entryKind = "recurring"
  frequency = recurringFrequency   // daily | weekly | monthly | yearly

oneTime:
  entryKind = "oneTime"
  frequency = "once"
  occurrenceDate = selected date
```

Also sets `isActive = true`, `lastModified = Date()`, optional `sourceType` / `sourceID`.

### How does category section routing work?

`IncomeViewModel.loadIncomeCategories` / `ExpenseViewModel.loadExpenseCategories`:

1. Fetch all rows where `type == income|expense`
2. Split:
   - **Recurring lists:** `FinancialCategoryWriteSupport.isRecurringDisplayCategory` → filter by `frequency` into **daily / weekly / monthly / yearly** arrays
   - **One-time list:** `isOneTimeDisplayCategory`

**Display filters:**

- Recurring: `entryKind != oneTime`, frequency in `{daily, weekly, monthly, yearly}`, not `once`/`recurring`
- One-time: `entryKind == oneTime` OR `frequency == once`

**Weekly routing (final decision):**

- `frequency == weekly` rows appear **only** in the **Weekly** section.
- Do **not** place weekly rows under Daily or Monthly.
- Income and Expense `sectionsStack` order: **Daily → Weekly → Monthly → Yearly → One-Time** (subscriptions remain in Expense between Monthly and Yearly only if that layout already exists — preserve Expense-specific subscription block placement without displacing Weekly; implementation should insert Weekly immediately after Daily).

**Current gap:** ViewModels today filter only `dailyIncomes`, `monthlyIncomes`, `yearlyIncomes` — no `weeklyIncomes` / `weeklyExpenses` array or Weekly section in views. Phase 2 must add both.

### Where is duplicate validation performed?

`CategoryValidationService`:

- `validateCustomCategory(name:type:frequency:context:)`
- `categoryExists(name:type:frequency:context:)` — Core Data predicate on exact `customName`, `type`, `frequency`, `isCustom == YES`

Called from `CreateCategoryModal.saveCategory()`.

### Where is amount entered after category creation?

**Today:** Only via `FinancialEditSheet`, opened when user taps a `FinanceListRow` (`categoryToEdit` binding).

**Not** after `CreateCategoryModal` save — parent `onSave` only calls `viewModel.refresh()` and dismisses modal.

### Can `FinancialEditSheet` be safely opened immediately after category creation?

**Yes, with conditions:**

| Requirement | Status |
|-------------|--------|
| Category saved to same `viewContext` | Yes — modal uses `@Environment(\.managedObjectContext)` |
| `FinancialCategory` identifiable for sheet | Yes — `sheet(item: $categoryToEdit)` requires `Identifiable` (entity has `id: UUID?`) |
| Object not faulted/deleted | Must save before binding; avoid rollback between dismiss and present |
| Premium color edit | Optional in edit sheet; amount entry does not require premium |

**Risk:** Presenting two sheets in sequence (dismiss create → present edit) needs careful SwiftUI timing (`onSave` → dismiss → `DispatchQueue.main.async` set `categoryToEdit` or single coordinator state).

### Which save methods ignore `PersistenceService.save()` result?

**In scope for this fix:**

| Location | Method | Checks return? |
|----------|--------|----------------|
| `IncomeViewModel` | `updateAmount`, `updateColor`, `deleteCategory` | No |
| `ExpenseViewModel` | `updateAmount`, `updateColor`, `deleteCategory` | No |
| `CreateCategoryModal` | `saveCategory` | Uses `try viewContext.save()` in do/catch — **partial** (does not use `PersistenceService.save()`) |

**Out of scope but noted:** Many other call sites ignore return value; this plan only fixes Income/Expense category paths.

---

## 5. Proposed Data Rules

### Display name (`customName`)

| Rule | Value |
|------|-------|
| Storage | `FinancialCategory.customName` |
| Trim | Leading/trailing whitespace only |
| Max length | 50 characters (keep existing limit) |
| Allowed chars | Unicode letters (all scripts), numbers, spaces, simple punctuation (`. , - ' & ( )`) |
| Disallow | Emoji, control characters, newlines, whitespace-only names |

### Normalized duplicate key

| Rule | Value |
|------|-------|
| Derivation | `normalize(customName)` at validation time |
| Algorithm | Unicode NFKD → strip combining marks → lowercase → collapse whitespace → trim (text only; names with emoji are rejected before normalization) |
| Comparison | Normalized key equality + `type` match |
| Emoji | Excluded from name field; never included in normalized duplicate key |
| Persistence | **Preferred:** store generated `uniqueID` slug `custom-<short-uuid>` for custom rows; use normalized form only for duplicate fetch/compare |
| Fallback | If schema change rejected: in-memory compare against all custom rows of same `type` |

### Internal slug (`uniqueID` for custom)

| Rule | Value |
|------|-------|
| Format | `custom_` + lowercase UUID segment (ASCII only) |
| Purpose | Backup keys, summary `categoryKey`, internal references |
| Seeded rows | Unchanged canonical IDs (`rent`, etc.) |

### One-time frequency mapping

| Field | Value |
|-------|-------|
| `entryKind` | `oneTime` |
| `frequency` | `once` |
| `occurrenceDate` | User-selected date (default today) |
| UI frequency | **Hidden** — do not pass section frequency into modal for one-time |

### Recurring frequency mapping

| User selection | `entryKind` | `frequency` |
|----------------|-------------|-------------|
| Daily | `recurring` | `daily` |
| Weekly | `recurring` | `weekly` |
| Monthly | `recurring` | `monthly` |
| Yearly | `recurring` | `yearly` |

### Duplicate comparison rules

```text
isDuplicate(newName, type) =
  EXISTS custom category WHERE
    type == newType AND
    normalize(customName) == normalize(newName)
```

- Income "Maaş" and expense "Maaş" → **allowed**
- Income "Maaş" and income "maaş" → **blocked**
- Income "Maaş" recurring and income "Maaş" one-time → **blocked** (same type + normalized name)

---

## 6. Proposed UI Flow

### A. Add one-time income / expense

```text
User taps "Add" in One-Time section (or empty-state CTA with one-time intent)
  → CreateCategoryModal(entryIntent: .oneTime, type: income|expense)
      • Name field
      • Icon + color (color premium-gated as today)
      • Optional date picker
      • Helper: "Counted in this month."
      • NO frequency picker
      • NO misleading "Monthly Income" label
  → Save
  → Dismiss modal
  → Open FinancialEditSheet(newCategory) for amount
  → Save amount → updateAmount → refresh list
```

### B. Add recurring income / expense

```text
User taps "Add" in Daily / Weekly / Monthly / Yearly section OR explicit "Add recurring"
  → CreateCategoryModal(entryIntent: .recurring, type:, defaultFrequency: from section)
      • Name field (no emoji)
      • Frequency picker: daily | weekly | monthly | yearly
      • Pre-select frequency from section when launched from section
      • Icon + color (icon picker for visual expression — separate from name)
      • NO occurrence date (or hidden)
  → Save
  → Dismiss modal
  → Open FinancialEditSheet(newCategory)
  → Save amount → updateAmount → refresh
```

**Recurring section order on screen:** Daily → Weekly → Monthly → Yearly → One-Time

**Section launch matrix:**

| Launched from | Entry intent | Default frequency |
|---------------|--------------|-------------------|
| Daily section | recurring | daily |
| Weekly section | recurring | weekly |
| Monthly section | recurring | monthly |
| Yearly section | recurring | yearly |
| One-time section | oneTime | n/a (internal `once`) |
| Empty-state primary CTA | recurring | monthly (current default) |

### C. Edit existing item

```text
User taps FinanceListRow edit
  → FinancialEditSheet (unchanged structure)
  → Save amount / color
  → If save fails → show errorMessage or inline banner
  → Dismiss on success
```

---

## 7. Recommended Implementation Phases

### Phase 1 — Validation, identity, one-time routing (foundation)

- Unicode display-name validation (letters from all scripts; numbers and simple punctuation; **reject emoji**)
- Normalized duplicate key comparison (type-scoped; text only — no emoji in key)
- Assign internal `uniqueID` for new custom categories
- Fix one-time section → modal intent (no `monthly` frequency leak)
- Extend `CategoryValidationService` frequency allowlist to include `weekly` for recurring validation only

**Outcome:** Custom categories save and appear in correct section for one-time and section-launched recurring (weekly list wiring completes in Phase 2).

### Phase 2 — Recurring frequency UI, Weekly section, metadata wiring

- Add frequency picker to modal for recurring intent
- Hide frequency UI for one-time intent
- Add one-time helper sentence
- Pass `entryIntent` + `defaultFrequency` from `IncomeView` / `ExpenseView`
- Add **Weekly** collapsible section to Income and Expense (`weeklyIncomes` / `weeklyExpenses` in ViewModels)
- Enforce recurring section order: **Daily → Weekly → Monthly → Yearly → One-Time**
- Route `frequency == weekly` rows **only** to Weekly section (not Daily, not Monthly)

**Outcome:** Users explicitly choose recurring frequency; weekly items have a dedicated home; one-time flow is clear.

### Phase 3 — Create → amount entry transition

- After successful create, chain to `FinancialEditSheet`
- Coordinate sheet dismissal/presentation safely
- Optional: skip full-screen `isLoading` during post-create refresh

**Outcome:** Single continuous add flow ending with amount saved.

### Phase 4 — Save error propagation + alert cleanup

- Check `PersistenceService.save()` in Income/Expense ViewModel write paths
- Map failures to `errorMessage` with calm copy
- Replace `.constant(errorMessage != nil)` with proper `@State` or `alert(item:)`
- Align `CreateCategoryModal` to use `PersistenceService.save()` for consistency (optional minimal change)

**Outcome:** No silent failures; reliable error alerts.

### Phase 5 — Tests and regression

- Unit tests: normalization, duplicate rules, metadata mapping
- Extend `IncomeExpenseFlowTests` for weekly + Unicode names
- Manual QA matrix (Section 11)
- Build + full test suite

---

## 8. Recommended Files to Change Per Phase

### Phase 1

| File | Why |
|------|-----|
| `CoreKit/Sources/Utilities/CategoryValidationService.swift` | Unicode validation (no emoji), normalized duplicate logic, weekly frequency allowlist, custom `uniqueID` assignment |
| `Features/Shared/CreateCategoryModal.swift` | Accept `entryIntent`, stop using misleading section frequency for one-time |
| `Features/IncomesFeature/View/IncomeView.swift` | Pass correct intent/frequency into modal; fix `oneTimeSection` frequency arg |
| `Features/ExpensesFeature/View/ExpenseView.swift` | Same as Income |
| `Features/Shared/CreateCategoryModal.swift` (`FinancialCategoryWriteSupport`) | Confirm weekly frequency in display filters (no change expected if filters already correct) |

### Phase 2

| File | Why |
|------|-----|
| `Features/Shared/CreateCategoryModal.swift` | Frequency picker UI, one-time helper, conditional sections |
| `Features/IncomesFeature/View/IncomeView.swift` | `presentCreateModal(entryIntent:defaultFrequency:)` API; add **Weekly** section in `sectionsStack` (after Daily) |
| `Features/ExpensesFeature/View/ExpenseView.swift` | Same; insert Weekly after Daily, preserve subscription section placement |
| `DesignSystem/Components/Rows/AddFinancialItemRow.swift` | Optional: pass intent label ("Add weekly expense", etc.) |
| `Features/IncomesFeature/ViewModel/IncomeViewModel.swift` | Add `weeklyIncomes`, `categoriesForFrequency("weekly")`, section title/subtotal helpers |
| `Features/ExpensesFeature/ViewModel/ExpenseViewModel.swift` | Add `weeklyExpenses` and matching helpers |

### Phase 3

| File | Why |
|------|-----|
| `Features/IncomesFeature/View/IncomeView.swift` | Chain `categoryToEdit` after create `onSave` |
| `Features/ExpensesFeature/View/ExpenseView.swift` | Same |
| `Features/Shared/CreateCategoryModal.swift` | Return created category in `onSave` callback (already typed) |
| `Features/IncomesFeature/ViewModel/IncomeViewModel.swift` | Optional: `refreshWithoutFullScreenLoading()` |
| `Features/ExpensesFeature/ViewModel/ExpenseViewModel.swift` | Same |

### Phase 4

| File | Why |
|------|-----|
| `Features/IncomesFeature/ViewModel/IncomeViewModel.swift` | Check save result; set `errorMessage` |
| `Features/ExpensesFeature/ViewModel/ExpenseViewModel.swift` | Same |
| `Features/IncomesFeature/View/IncomeView.swift` | Fix alert binding |
| `Features/ExpensesFeature/View/ExpenseView.swift` | Fix alert binding |
| `Features/Shared/FinancialEditSheet.swift` | Optional: display save error from parent |
| `Features/Shared/CreateCategoryModal.swift` | Unify save through `PersistenceService` if desired |

### Phase 5

| File | Why |
|------|-----|
| `budgetmeter.iosTests/IncomeExpenseFlowTests.swift` | New flow coverage |
| New test file e.g. `CategoryValidationServiceTests.swift` | Normalization + duplicate unit tests |
| `Resources/*.xcstrings` | Only strings added for new helper/error copy (minimal keys) |

---

## 9. Do-Not-Touch List

| Area | Reason |
|------|--------|
| **Core Data schema** (`BudgetMeter.xcdatamodeld`) | Use existing `customName`, `uniqueID`, `entryKind`, `frequency` unless proven insufficient |
| **Premium entitlement matrix** (`PremiumManager`, `BudgetMeterCapability`) | Gate behavior is correct; only UI entry points change |
| **StoreKit / IAP** | Unrelated |
| **BackupService / backup payloads** | Ensure serializer already carries `customName` + `uniqueID`; no backup rewrite |
| **CalculationEngine** | Read-only verification for weekly routing; no formula changes unless bug confirmed |
| **DataSeedingService seed catalog** | Predefined categories unchanged |
| **Unrelated UI redesign** | No hero/layout overhaul beyond modal fields needed for this fix |
| **Broad localization pass** | Add only new strings for helper/error copy |
| **RecurringTransactionsFeature** | Separate feature; out of scope unless shared validation extracted |
| **CloudKit / PersistenceService stack** | Do not change container configuration |

---

## 10. Risk Assessment

### Small / safe (Cursor Auto acceptable after plan approval)

| Change | Risk |
|--------|------|
| Emoji rejection in name field | Low |
| Alert binding fix | Low |
| One-time section frequency argument fix | Low |
| Helper text in modal | Low |
| Checking `save()` return in ViewModels | Low |

### Medium risk (Composer 2.5 recommended)

| Change | Risk |
|--------|------|
| Normalized duplicate logic | Medium — edge cases (combining marks, Turkish İ/i) |
| Custom `uniqueID` assignment | Medium — backup/restore compatibility |
| Recurring frequency picker + section defaults | Medium — UI state |
| Create → edit sheet chaining | Medium — SwiftUI sheet timing |
| Weekly section + ViewModel arrays | Medium — new UI section and filter arrays |

### High risk (Composer / Codex-level reasoning)

| Change | Risk |
|--------|------|
| Core Data schema addition (if normalization persisted as new attribute) | High — migration |
| Changing duplicate rule across existing user data | High — may expose legacy duplicates |
| CalculationEngine changes for weekly | High — pace contract impact |

**Recommendation:**

- Phases 1, 4 (validation + errors): **Composer 2.5** for first pass; Auto for isolated copy/bindings after pattern established.
- Phases 2–3 (UI flow): **Composer 2.5** minimum.
- Phase 5: run full CI; investigate any `FinancialSummaryBuilder` weekly gap with read-only audit first.

---

## 11. Test Plan

### Automated

| Test | Phase |
|------|-------|
| `normalize("Maaş")` equals `normalize("maas")` for duplicate | 1 |
| Turkish name passes validation | 1 |
| Emoji in name field rejected | 1 |
| Duplicate blocked: same type + normalized name | 1 |
| Duplicate allowed: income vs expense same name | 1 |
| `applyMetadata` one-time → `entryKind=oneTime`, `frequency=once` | 1 |
| `applyMetadata` recurring weekly → `frequency=weekly` | 1 |
| ViewModel loads weekly into **Weekly** section only | 2 |
| Weekly row does not appear under Daily or Monthly | 2 |
| `IncomeExpenseFlowTests` extended for Unicode create | 5 |

### Manual QA matrix

| # | Scenario | Expected |
|---|----------|----------|
| M1 | Turkish category name (e.g. `Maaş`, `Çay`) | Saves, displays correctly |
| M2 | Arabic category name | Saves, displays correctly |
| M3 | Chinese category name | Saves, displays correctly |
| M3b | Emoji in name field (e.g. `Coffee ☕`) | Rejected with calm validation message; user picks icon separately |
| M4 | Duplicate name same type | Clear error, no second row |
| M5 | Same name income + expense | Both allowed |
| M6 | One-time income | No frequency UI; appears in One-Time section |
| M7 | One-time expense | Same |
| M8 | Recurring income daily/weekly/monthly/yearly | Appears in matching section (Weekly only for weekly); pace updates |
| M9 | Recurring expense daily/weekly/monthly/yearly | Same |
| M9b | Section order on Income/Expense | Daily → Weekly → Monthly → Yearly → One-Time |
| M10 | Create → amount sheet opens automatically | Amount saves to new row |
| M11 | Airplane mode / forced save failure | User sees error, data not silently lost |
| M12 | Edit seeded category (Rent, Salary) | Still works |
| M13 | DEBUG Premium off → Add row | Paywall (unchanged) |
| M14 | DEBUG Premium on → full flow | End-to-end success |

### Regression

- Run `xcodebuild test` — all existing tests pass
- Home meter updates after amount entry
- Widget snapshot refresh still fires (no crash)

---

## 12. Acceptance Criteria

- [ ] Users can create category names in Turkish, Arabic, Chinese, and other Unicode scripts
- [ ] Emoji is **not** allowed in the category name text field
- [ ] Icons/emoji remain in the separate icon picker, not in `customName`
- [ ] User-facing names are preserved exactly in UI (`customName`) after validation
- [ ] Internal duplicate comparison uses stable normalized text rules (case/diacritic insensitive; no emoji in key)
- [ ] Custom categories receive stable internal `uniqueID` without overwriting display name
- [ ] One-time flow does **not** ask for frequency
- [ ] One-time helper text explains monthly counting behavior
- [ ] Recurring flow asks for frequency (daily / weekly / monthly / yearly)
- [ ] One-time items route to One-Time section (`entryKind=oneTime`, `frequency=once`)
- [ ] Recurring items route to correct section by frequency
- [ ] Weekly recurring items appear **only** in the **Weekly** section (not Daily, not Monthly)
- [ ] Recurring section order is Daily → Weekly → Monthly → Yearly → One-Time
- [ ] Duplicate handling blocks same normalized name within same type only
- [ ] Income and expense may share the same display name
- [ ] After create, amount entry opens automatically via `FinancialEditSheet`
- [ ] Save failures show calm, readable errors (no silent rollback)
- [ ] Alert presentation works reliably on Income and Expense screens
- [ ] Seeded default categories still edit and calculate correctly
- [ ] No Core Data schema change required (or documented waiver if added)
- [ ] Premium gating on Add row unchanged
- [ ] `xcodebuild build` succeeds
- [ ] Unit tests pass (including new validation tests)

---

## Appendix A — Current vs Proposed Modal Parameters

| Parameter | Current | Proposed |
|-----------|---------|----------|
| `frequency` | Section string (buggy for one-time) | `defaultFrequency` for recurring only |
| `entryIntent` | Inferred from segmented control | Passed from parent section + control |
| `onSave` | `refresh()` only | `refresh()` + open edit sheet with category |
| Duplicate key | `customName` + `type` + `frequency` | `normalize(customName)` + `type` |

## Appendix B — Weekly recurring UI (resolved)

**Final product decision:**

Weekly recurring categories get their own **Weekly** collapsible section on Income and Expense screens.

| Rule | Detail |
|------|--------|
| Placement | Dedicated Weekly section — **not** under Monthly, **not** under Daily |
| Section order | 1. Daily → 2. Weekly → 3. Monthly → 4. Yearly → (Expense subscriptions if present) → One-Time |
| ViewModel | Add `weeklyIncomes` / `weeklyExpenses` arrays; filter `frequency == "weekly"` |
| Modal | Frequency picker includes weekly; launching Add from Weekly section defaults to weekly |
| Calculations | Existing `FinancialSummaryBuilder` weekly interval support — verify only; no engine change unless bug found |

---

## COMPLETED

THIS PROBLEM SOLVED. IT'S FIXED COMPLETLY.

---

*End of planning document. Implementation must follow phased PRs aligned with `docs/uiux_transformation_master_plan.md` incremental rules.*
