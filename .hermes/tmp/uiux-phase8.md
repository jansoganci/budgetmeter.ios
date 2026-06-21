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

PHASE 8 — Widget Redesign

Goal:
Make widget neutral, currency-aware, and v2-compliant.

Allowed files/folders ONLY:
* BudgetMeterWidgets/
* budgetmeter.ios/WidgetShared/
* budgetmeter.ios/CoreKit/Sources/Widget/

Forbidden:
* Feature screens
* TextStyles.swift
* BrandColors.swift
* LayoutTokens.swift
* Theme files
* CurrencyHelper.swift
* Auth logic
* StoreKit/subscription logic
* Networking/sync
* CalculationEngine
* Xcode project files

Implement:

1. Use neutral widget background colors (not status-driven full green/red fills):
   * Light: `#F8FAFC`
   * Dark: `#0F172A`

2. Make widget currency-aware using the existing CurrencyHelper.

3. Keep v1 scope (systemSmall only, NetDailyPaceWidget only).

4. Keep premium gating (locked teaser + paywall deep link).

5. Keep existing deep links.

6. Do NOT expand widget families or add new widget types.

7. Update widget entry view styling to match v2 design direction:
   * Clean, minimal layout
   * Calm neutral background
   * Financial numbers in SF Pro Rounded style
   * Status text in normal system font

Acceptance criteria:
* Widget builds and renders on simulator.
* Backgrounds are neutral canvas values.
* Currency display uses system locale.
* Premium locked teaser still works.
* Deep links still route correctly.
* No feature screen files changed.

Manual QA checklist:
* Add widget to Home Screen.
* Verify background is neutral (not green/red).
* Verify currency symbol matches system locale.
* Toggle premium off → locked teaser appears.
* Tap locked teaser → paywall opens.
* Toggle premium on → net pace value displays.

After completion:
* STOP.
* Report files changed.
* Summarize exact changes.
* Report build/test result.
* Do not continue to Phase 9.
