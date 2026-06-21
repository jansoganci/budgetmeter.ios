MASTER RULES — paste at the top of every phase prompt

BudgetMeter UI/UX v2 implementation.

Read first:

* docs/uiux_v2_implementation_plan.md
* docs/uiux_design_system_v2_tokens.md
* docs/uiux_design_direction_v1_decisions.md

Global rules:

* ONLY implement the phase written in this prompt.
* DO NOT continue to the next phase.
* ONLY touch the allowed files/folders listed in this prompt.
* DO NOT touch Core Data schema, auth provider logic, StoreKit purchase/restore/entitlement logic, CalculationEngine, networking/sync, Xcode project files, or unrelated feature files.
* Preserve existing public token/modifier names wherever possible.
* Preserve compatibility aliases.
* If file structure differs from assumptions, STOP and ask.
* After completion, provide:
    1. Files changed
    2. Exact changes
    3. Build/test result
    4. Manual QA checklist
    5. Rollback note
* Stop after this phase and wait for approval.

⸻

PHASE 7 — Currency Formatting Shared Contract

Goal:
Centralize currency display formatting without changing calculated values.

Allowed files ONLY:
* budgetmeter.ios/CoreKit/Sources/Utilities/CurrencyHelper.swift
* budgetmeter.ios/DesignSystem/Components/ (add new CurrencyText view if needed)

Forbidden:
* Feature screens
* Widgets
* TextStyles.swift
* BrandColors.swift
* LayoutTokens.swift
* Theme files
* Auth logic
* StoreKit/subscription logic
* Networking/sync
* CalculationEngine
* Xcode project files

Implement:

1. Review current CurrencyHelper.swift — understand existing format methods.
2. Add or align:
   * A shared `CurrencyText` SwiftUI view that applies v2 typography (SF Pro Rounded for amounts).
   * Support for: compact (large hero), normal (body), and caption sizes.
   * Currency symbol placement follows locale (prefix or suffix).
   * Decimal formatting: 0 decimals for whole numbers >= 100, 2 decimals for < 100.
3. Keep ALL existing CurrencyHelper methods working for backward compatibility.
4. Do NOT change CalculationEngine values.
5. Do NOT change widget formatting in this phase.
6. Do NOT change feature screen layouts.

Acceptance criteria:
* App compiles.
* CurrencyHelper existing methods still work.
* CurrencyText view exists and renders correctly.
* No feature screen files changed.
* No business logic changed.

Manual QA checklist:
* Home hero amount renders with correct font.
* Income/Expense amounts show correct decimal places.
* Settings amounts consistent.

After completion:
* STOP.
* Report files changed.
* Summarize exact changes.
* Report build/test result.
* Do not continue to Phase 8.
