# Savings Goals UI/UX Fix Plan

**Status:** Planning only — no implementation in this document  
**Date:** 22 June 2026  
**Related findings:** `docs/premium_test_findings.md` (§4 multiple goals — logic fixed; UI/UX issues remain)  
**Related docs:** `DESIGN.md`, `docs/uiux_design_direction_v1_decisions.md`, `docs/uiux_design_system_v2_tokens.md`, `docs/transformations/input_flows_transformation.md`, `docs/transformations/settings_transformation.md`

---

## 1. Purpose

This document analyzes and plans fixes for **remaining Savings Goals UI/UX issues** found during premium testing.

**Multiple savings goals are now technically supported** for premium users (service-layer limit + Settings list `+` button). This plan covers polish only: localization, navigation/header layout, input focus, keyboard/picker dismissal, unclear goal-card copy, and optional Home quick-action routing.

This is a **planning document only**. It does **not** implement Swift code, change Core Data, modify premium entitlements, or update localization files in this phase.

---

## 2. Problem Summary

| # | Area | Observed issue |
|---|------|----------------|
| P1 | **Home Goal quick action** | Home quick action **Goal** opens `QuickSavingsGoalInputView` (amount-only, primary goal upsert). It does **not** open the full **Add Goal** flow (`SavingsGoalInputView`) used from Settings → Tracking & Goals → Savings Goals → `+`. |
| P2 | **Savings Goals screen localization** | Settings → Tracking & Goals → Savings Goals shows **Turkish** copy when app language is set to **English**. |
| P3 | **Add Goal modal localization** | Add/edit goal sheet shows Turkish strings (e.g. *Hedef adı*, *Hedef tutar*, *Mevcut tutar*, *Hedef oluştur*, keyboard *Tamam*). |
| P4 | **Header layout** | Back button and `+` button are **not aligned on the same row** on the Savings Goals screen. |
| P5 | **Amount input focus** | Target amount field does **not focus reliably on first tap**; often works only after scrolling. |
| P6 | **Keyboard Done / Tamam** | Toolbar **Done** above the keyboard does **not dismiss** the keyboard reliably. Affects amount fields (decimal pad), not only date picker. |
| P7 | **Picker / modal dismissal** | Date picker and category menu interactions feel **stuck**; user must scroll and tap **Create Goal** to continue. |
| P8 | **Goal card copy** | Phrases like **“Hedeften önde”** / pace-related text on goal cards are **unclear** even in Turkish. Meaning for users is ambiguous. |

---

## 3. Current Architecture

### 3.1 Where screens live

| Screen | File | Entry points |
|--------|------|--------------|
| **Savings Goals list** | `Features/SavingsGoalsFeature/View/SavingsGoalsView.swift` | Settings → Premium → **Tracking & Goals** → Savings Goals (`NavigationLink` in `SettingsView.trackingAndGoalsSection`). Visible only when `premiumManager.isPremium`. |
| **Add / Edit Goal modal** | `Features/SavingsGoalsFeature/View/SavingsGoalInputView.swift` | Presented as `.sheet` from `SavingsGoalsView` (`showingAddGoal`, `goalToEdit`). |
| **Goal detail** | `Features/SavingsGoalsFeature/View/SavingsGoalDetailView.swift` | Sheet from list row tap. |
| **Home quick Goal sheet** | `Features/HomeFeature/View/QuickSavingsGoalInputView.swift` | Home quick actions grid → `HomeViewModel.showSavingsGoalEntry()` → `showingSavingsGoalSheet`. |
| **Home savings card** | `HomeView.healthAndSavingsRow` | Taps also call `showSavingsGoalEntry()`. |

### 3.2 ViewModel / service layer (context only — no changes in this plan)

| Component | Role |
|-----------|------|
| `SavingsGoalsViewModel` | Loads goals, `activeGoals` / `completedGoals`, `canAddAnotherGoal` → `SavingsGoalManager.canCreateAdditionalGoal()`, pace/ETA helpers for cards. |
| `SavingsGoalManager` | CRUD, premium limit enforcement, pace status (`SavingsGoalPaceStatus`). |
| `HomeViewModel.updateSavingsGoal(_:)` | Calls `upsertPrimaryBasicGoal` — updates **primary** goal target only. |

### 3.3 Home Goal quick action (current behavior)

```
Home quick action "Goal" / "Set Goal"
  → HomeViewModel.showingSavingsGoalSheet = true
  → QuickSavingsGoalInputView(currentGoal: primary target amount)
  → onSave: HomeViewModel.updateSavingsGoal(amount)
  → SavingsGoalManager.upsertPrimaryBasicGoal(...)
```

- **Single-field** amount entry for the **primary** savings goal.
- Does **not** collect name, emoji, category, notes, or target date.
- Does **not** create a **second** goal for premium users.

### 3.4 Multiple goals from Settings (current behavior)

```
Settings (premium) → SavingsGoalsView
  → toolbar "+" 
  → if canAddAnotherGoal: SavingsGoalInputView(goal: nil)
  → else: PremiumPaywallView
  → SavingsGoalManager.createGoal(...)
```

List shows `activeGoals` and `completedGoals` in scroll sections. Premium limit is enforced in manager + UI.

### 3.5 Localization (current — root cause of P2/P3)

**Two different localization APIs are in use:**

| API | Used by | Respects `LocalizationManager`? |
|-----|---------|----------------------------------|
| `"key".localized(defaultValue:table: "UI")` | `SettingsView`, `HomeView`, most Settings strings | **Yes** — `LocalizationManager.shared` + language bundle |
| `String(localized: "key", defaultValue: "...", table: "UI")` | **Entire Savings Goals feature** (`SavingsGoalsView`, `SavingsGoalInputView`, `SavingsGoalDetailView`, `SavingsGoalManager` pace strings) | **No** — Swift String Catalog / system locale path |

**Keys exist in `UI.xcstrings`** with full `en` + `tr` translations (e.g. `savings.list.title`, `savings.goal_name`, `savings.target_amount`, `form.done`). English values are present. Turkish appears at runtime because the Savings Goals views bypass `LocalizationManager` when the device or catalog resolution prefers Turkish while in-app language is English.

**Category picker labels** in `SavingsGoalInputView` are **hardcoded English** strings (`"Travel"`, `"Education"`, …) — not localized at all.

**Home savings strings** use `Home.xcstrings` + `.localized()` (e.g. `home.quick_actions.goal`).

**ETA / pace strings** split across:
- `UI.xcstrings` — `savings.pace.*`, `savings.save_month`, etc.
- `Localizable.xcstrings` — `savings.eta.at_pace`, `savings.eta.negative_pace` (used by `HomeDisplayMapping` via `String(localized:)` without table)

### 3.6 Amount input / focus (current)

| Location | Focus handling |
|----------|----------------|
| `FinancialAmountField` | Optional `FocusState<Bool>.Binding` via `focused:` initializer |
| `SavingsGoalInputView` | `@FocusState` enum covers **goal name** and **notes only** |
| `SavingsGoalInputView` target/current amount | `FinancialAmountField` called **without** `focused:` binding |
| `FinancialEditSheet` (reference) | `@FocusState isAmountFocused` + `focused: $isAmountFocused` + keyboard Done clears focus |

**Likely cause of P5:** amount fields have no `FocusState`; first tap may be absorbed by `ScrollView` / `GlassCard` hit testing.

### 3.7 Keyboard toolbar Done / Tamam (current)

Defined in `SavingsGoalInputView` toolbar:

```swift
ToolbarItemGroup(placement: .keyboard) {
    Button(String(localized: "form.done", defaultValue: "Done", table: "UI")) {
        focusedField = nil  // only .goalName / .notes
    }
}
```

- **Does not clear focus** on target/current amount fields (no focus binding).
- Decimal pad fields therefore ignore Done — matches P6.
- `QuickSavingsGoalInputView` uses `"toolbar.done".localized()` and **does** bind `FinancialAmountField(focused: $isInputFocused)` — Home quick sheet likely works better than Add Goal modal.

### 3.8 Goal card copy (current)

Generated in `SavingsGoalsView` `GoalCard` + `SavingsGoalsViewModel`:

| Copy | Source | Default EN | TR (UI.xcstrings) |
|------|--------|------------|-------------------|
| Pace status | `SavingsGoalManager.isPaceStatus` → `SavingsGoalPaceStatus.displayText` | `savings.pace.ahead` → **"Ahead of pace!"** | **"Hedeften önde!"** |
| | | `savings.pace.on_pace` → **"On pace"** | **"Hedefte"** |
| | | `savings.pace.behind` → **"Behind pace"** | **"Hedeften geride"** |
| Monthly save hint | `requiredMonthlyText` → `savings.save_month` | "Save %@/month" | localized |
| Shared ETA (primary only) | `sharedPaceETAText` → `HomeDisplayMapping.formatSavingsETA` | `savings.eta.at_pace` in Localizable | varies |

**Intended meaning (technical):** pace status compares **actual saved amount** vs **expected amount at this point in time** toward a **target date** (heuristic in `SavingsGoalManager.isPaceStatus`). It is **not** “before target date” in a calendar sense.

**User-facing problem:** “Ahead of pace” / “Hedeften önde” does not explain *what* pace means (saving rate vs deadline).

### 3.9 Navigation / header (current)

- `SettingsView` uses `NavigationView` (inline title).
- `SavingsGoalsView` wraps content in a **nested `NavigationStack`** with `.navigationBarTitleDisplayMode(.large)`.
- `SavingsGoalInputView` sheet uses **another** `NavigationView` (inline title, Cancel leading).

Nested navigation containers are a common cause of **misaligned back chevron vs trailing toolbar** on pushed screens (P4).

---

## 4. Product Decisions Needed

| Question | Options | Notes |
|----------|---------|-------|
| **Home Goal quick action** | A) Keep amount-only primary upsert for everyone  
B) Premium → full `SavingsGoalInputView`; Free → `QuickSavingsGoalInputView`  
C) Premium → navigate to Savings Goals + auto-open add sheet  
D) Everyone → full add flow | B is lowest risk; preserves Home primary card behavior |
| **Home “My Savings Goal”** | Keep primary upsert for Home card / quick edit vs replace entirely | Home card should still reflect **primary** goal; no multi-goal Home redesign |
| **Goal card deadline copy** | Keep pace heuristic vs simplify to date-only copy vs hide pace on cards | Recommend clearer pace labels + optional helper tone |
| **Localization strategy** | Migrate Savings Goals to `.localized(table: "UI")` only vs unify all `String(localized:)` app-wide | This pass: **Savings Goals feature only** |
| **Category picker** | Localize hardcoded category names vs remove category field | Low usage; localize keys in `UI.xcstrings` |

---

## 5. Recommended Product Decisions

1. **Home Goal quick action (premium):** Open the **same `SavingsGoalInputView(goal: nil)`** sheet used by Savings Goals `+`, when `PremiumManager` grants `multipleSavingsGoals` **and** `canCreateAdditionalGoal()` is true.  
2. **Home Goal quick action (free / at limit):** Keep **`QuickSavingsGoalInputView`** for fast primary target edit (one basic goal).  
3. **Home primary display:** **No redesign.** Home continues to show **one primary goal** summary; do not add multi-goal list to Home.  
4. **Localization:** All Savings Goals screens/modals use **`LocalizationManager`** via `"key".localized(defaultValue:table: "UI")` (or shared helper). English-first keys with full 10-language catalog entries.  
5. **Pace copy:** Replace vague “ahead of pace” / “hedeften önde” with **plain language**, e.g.  
   - EN: **“Saving faster than planned”** / **“On track for your date”** / **“Behind your plan”**  
   - Clarify this is about **progress toward a target date**, not calendar “before the deadline.”  
6. **Keyboard Done:** Dismisses keyboard / clears **all** field focus. **Does not** submit the form.  
7. **Picker Done / dismissal:** Tapping Done or outside closes keyboard; pickers should not leave the form in a blocked state. Category menu + compact date picker should resign amount focus on open.

---

## 6. Proposed UI/UX Fix Scope

### In scope (this pass)

| Item | Fix |
|------|-----|
| Localization | Migrate Savings Goals views + pace strings to `LocalizationManager`; audit `UI.xcstrings` / `Localizable.xcstrings` keys |
| Header alignment | Remove nested nav conflict; align large-title + trailing `+` with system back button |
| Home Goal routing | Premium add flow → `SavingsGoalInputView` when safe (see §5) |
| Input focus | Wire `FocusState` to amount fields; match `FinancialEditSheet` pattern |
| Keyboard Done | Clear all focus bindings including amount fields |
| Picker dismissal | Resign focus before picker interaction; `scrollDismissesKeyboard`; avoid focus traps in `ScrollView` |
| Card copy | Rewrite `savings.pace.*` (+ optional ETA strings) for clarity |

### Out of scope (explicit)

- Home dashboard redesign or multi-goal Home list  
- New `SavingsGoal` data model fields  
- Premium entitlement / `PremiumManager` definition changes  
- Widget changes  
- Financial calculation / pace heuristic changes (copy-only unless product requests formula change)  
- Savings Goal gamification, notifications, Insights integration  
- `SavingsGoalDetailView` full redesign (only touch if needed for same localization/focus patterns)

---

## 7. Recommended Implementation Phases

### Phase 1 — Localization audit and keys

- Inventory all Savings Goals user-facing strings.  
- Replace `String(localized:table: "UI")` with `"key".localized(defaultValue:table: "UI")` in Savings Goals feature files.  
- Add/fix keys in `UI.xcstrings` (and `Localizable.xcstrings` for ETA strings used on cards).  
- Localize category picker options (`savings.category.travel`, etc.).  
- Verify English + Turkish + spot-check other supported languages.

### Phase 2 — Header alignment cleanup

- Remove **nested** `NavigationStack` inside pushed `SavingsGoalsView` OR push without inner stack (use parent `NavigationView` from Settings).  
- Standardize: large title for list, inline title for add/edit sheet.  
- Ensure trailing `+` and back chevron share one navigation bar (no duplicate bars).

### Phase 3 — Keyboard / focus / Done in Add Goal modal

- Add `@FocusState` for target amount (and optionally current amount).  
- Pass `focused:` into `FinancialAmountField` for both amount fields.  
- Keyboard Done clears **all** focus states.  
- Optional: auto-focus target amount on appear (mirror `FinancialEditSheet` delayed focus) — validate it does not fight scroll.  
- Add `.scrollDismissesKeyboard(.interactively)` on `ScrollView`.

### Phase 4 — Picker dismissal cleanup

- On category `Picker` tap / date toggle: `focusedField = nil`; clear amount focus.  
- Review `.pickerStyle(.menu)` inside `ScrollView` — if still sticky, consider inline wheel in expanded section or confirmation pattern.  
- Ensure keyboard toolbar is attached to the same navigation container as the sheet content.

### Phase 5 — Home quick action routing

- In `HomeViewModel` / `HomeView`, branch sheet content:  
  - Premium + can create → present `SavingsGoalInputView(goal: nil)`  
  - Else → `QuickSavingsGoalInputView` (existing)  
- Reuse `SavingsGoalManager.canCreateAdditionalGoal()` for consistency.  
- After full goal create from Home, call `HomeViewModel.refresh()` so primary card updates.

### Phase 6 — Goal card copy + manual QA / tests

- Update `savings.pace.ahead` / `on_pace` / `behind` strings in `UI.xcstrings`.  
- Review `sharedPaceETAText` visibility on cards (primary goal only — keep as-is).  
- Manual QA matrix (§10).  
- Update/add tests only where pure logic is affected (routing guards); UI tests optional.

---

## 8. Recommended Files to Change Per Phase

| Phase | Files | Why |
|-------|-------|-----|
| **1** | `Features/SavingsGoalsFeature/View/SavingsGoalsView.swift` | List/empty/card strings → `.localized()` |
| | `Features/SavingsGoalsFeature/View/SavingsGoalInputView.swift` | Form labels, CTA, errors, categories |
| | `Features/SavingsGoalsFeature/View/SavingsGoalDetailView.swift` | Detail/add/withdraw copy |
| | `CoreKit/Sources/Services/SavingsGoalManager.swift` | `SavingsGoalPaceStatus.displayText` localization API |
| | `Features/HomeFeature/ViewModel/HomeDisplayMapping.swift` | ETA strings on goal cards (if shown) |
| | `Resources/UI.xcstrings` | Savings + form + pace keys |
| | `Resources/Localizable.xcstrings` | `savings.eta.*` keys |
| **2** | `Features/SavingsGoalsFeature/View/SavingsGoalsView.swift` | Navigation structure, title mode, toolbar |
| | `Features/SettingsFeature/View/SettingsView.swift` | Only if parent nav wrapper must change |
| **3** | `Features/SavingsGoalsFeature/View/SavingsGoalInputView.swift` | FocusState, keyboard toolbar, scroll keyboard |
| | `Features/Shared/FinancialAmountField.swift` | Only if shared tap target / `contentShape` fix needed |
| **4** | `Features/SavingsGoalsFeature/View/SavingsGoalInputView.swift` | Picker/focus interaction |
| **5** | `Features/HomeFeature/View/HomeView.swift` | Sheet branching |
| | `Features/HomeFeature/ViewModel/HomeViewModel.swift` | Optional helper for which sheet to show |
| **6** | `Resources/UI.xcstrings` | Pace copy rewrite |
| | `budgetmeter.iosTests/BasicSavingsIntegrationTests.swift` | Optional routing/limit regression tests |

**Do not change in this effort:** `PremiumManager.swift`, `BudgetMeter.xcdatamodeld`, widget targets, theme files.

---

## 9. Risk Assessment

| Issue | Risk | Rationale |
|-------|------|-----------|
| P2/P3 Localization | **Low** | String API swap + catalog verification; no logic change |
| P8 Card copy | **Low** | Copy-only in `UI.xcstrings` |
| P4 Header alignment | **Medium** | Navigation structure change can affect Settings push/pop |
| P5 Amount focus | **Medium** | Focus + ScrollView interactions vary by iOS version |
| P6 Keyboard Done | **Low–Medium** | Well-established `FocusState` pattern exists in `FinancialEditSheet` |
| P7 Picker dismissal | **Medium** | SwiftUI menu/date pickers inside scroll sheets are finicky |
| P1 Home routing | **Medium** | Must not break free one-goal flow or primary Home card |
| Premium limit regression | **High** (if broken) | Phase 5 must still call `canCreateAdditionalGoal()` / paywall paths |

---

## 10. Test Plan

### Manual checks

| # | Scenario | Expected |
|---|----------|----------|
| M1 | App language **English** → Savings Goals list | All English (title, Active Goals, empty state, + accessibility) |
| M2 | App language **English** → Add Goal modal | English labels: Goal Name, Target Amount, Current Amount, Create Goal, Done |
| M3 | App language **Turkish** → same screens | Turkish catalog strings (not mixed English) |
| M4 | Savings Goals header | Back chevron and `+` on **same navigation bar row** |
| M5 | Add Goal → tap Target Amount **once** | Keyboard opens on first tap (no scroll required) |
| M6 | Amount keyboard visible → tap **Done** | Keyboard dismisses; field unfocused |
| M7 | Open category picker | Can select category; form remains usable |
| M8 | Enable target date → compact date picker | Can change date without trapping focus |
| M9 | Create Goal | Saves successfully; appears in correct list section |
| M10 | Premium + 1 goal → Home Goal quick action | Opens **full Add Goal** sheet (if Phase 5 implemented) |
| M11 | Free + 1 goal → Home Goal quick action | Opens **QuickSavingsGoalInputView** (amount only) or paywall if at limit |
| M12 | Premium + 2 goals in list | Both visible; `+` still works |
| M13 | Free + 1 goal → Settings Savings Goals `+` | Paywall (not second goal) |
| M14 | Goal card with target date | Pace text is **understandable** (new copy) |
| M15 | Home screen | Still shows **one** primary goal summary — no multi-goal Home UI |

### Automated (recommended)

- Existing `BasicSavingsIntegrationTests` — keep passing (premium limit, list count).  
- Optional new test: Home routing helper returns correct sheet type given premium + goal count (if extracted to testable function).

---

## 11. Acceptance Criteria

- [ ] Savings Goals **list screen** respects in-app language (English when English selected).  
- [ ] **Add Goal** modal fully localized via `LocalizationManager` + `UI.xcstrings`.  
- [ ] **Goal card pace copy** is understandable (EN + TR at minimum).  
- [ ] **Header:** back and `+` aligned on one navigation bar.  
- [ ] **Target amount** focuses on first tap in Add Goal modal.  
- [ ] **Keyboard Done** dismisses keyboard for amount fields (does not submit form).  
- [ ] **Category and date pickers** no longer trap the user; form recoverable without workaround scroll + Create Goal.  
- [ ] **Create / edit / delete** goal still works.  
- [ ] **Multiple goals** still work for premium; **one goal limit** for free.  
- [ ] **Home** not redesigned; primary goal behavior preserved.  
- [ ] **Home Goal quick action** routes correctly per §5 (if Phase 5 included).  
- [ ] **No** Core Data schema changes.  
- [ ] **No** premium entitlement regression.  
- [ ] Build passes; existing savings-related unit tests pass.

---

## Appendix A — Key code references

| Topic | Location |
|-------|----------|
| Savings list + `+` | `SavingsGoalsView.swift` |
| Add Goal form | `SavingsGoalInputView.swift` |
| Home quick Goal | `HomeView.swift` → `QuickSavingsGoalInputView.swift` |
| Primary goal upsert | `HomeViewModel.updateSavingsGoal` → `SavingsGoalManager.upsertPrimaryBasicGoal` |
| Premium limit | `SavingsGoalManager.canCreateAdditionalGoal()` |
| Pace copy | `SavingsGoalPaceStatus.displayText` in `SavingsGoalManager.swift` |
| Focus reference | `FinancialEditSheet.swift` |
| Localization manager | `LocalizationManager.swift` |
| Settings entry | `SettingsView.trackingAndGoalsSection` |

## Appendix B — Suggested pace copy (draft)

| Key | Current EN | Proposed EN | Meaning |
|-----|------------|-------------|---------|
| `savings.pace.ahead` | Ahead of pace! | **Saving faster than planned** | Current savings ahead of time-based plan |
| `savings.pace.on_pace` | On pace | **On track for your date** | Within ~10% of expected progress |
| `savings.pace.behind` | Behind pace | **Behind your plan** | More than ~10% below expected progress |

Add short TR equivalents that mention **plan / hedef tarih** explicitly, not ambiguous “hedeften önce/önde”.

---

*End of planning document.*
