MASTER RULES — paste at the top of every phase prompt

BudgetMeter UI/UX v2 implementation.

Read first:
* docs/uiux_v2_implementation_plan.md
* docs/uiux_design_system_v2_tokens.md
* docs/uiux_design_direction_v1_decisions.md

Global rules:
* ONLY implement the phase written in this prompt. DO NOT continue to the next phase.
* ONLY touch the allowed files/folders listed in this prompt.
* DO NOT touch Core Data schema, auth provider logic, StoreKit purchase/restore/entitlement logic, CalculationEngine, networking/sync, Xcode project files, or unrelated feature files.
* Preserve existing public token/modifier names wherever possible.
* Preserve compatibility aliases.
* If file structure differs from assumptions, STOP and ask.
* After completion, provide: 1. Files changed 2. Exact changes 3. Build/test result 4. Manual QA checklist 5. Rollback note
* Stop after this phase and wait for approval.

⸻

PHASE 9 — Paywall Visual Alignment

Goal:
Align paywall visuals and copy while preserving ALL existing purchase and entitlement logic.

Allowed files ONLY:
* budgetmeter.ios/Features/PremiumFeature/View/PremiumPaywallView.swift
* budgetmeter.ios/Features/PremiumFeature/View/PremiumFeatureView.swift
* budgetmeter.ios/DesignSystem/Components/Cards/PremiumUpgradeBanner.swift
* Resources/UI.xcstrings (add/update premium.* keys only)

Forbidden:
* StoreKit purchase/restore logic
* PremiumManager entitlement matrix
* PremiumManager.swift
* Theme migration files
* Widgets
* Auth files
* Core Data files
* Xcode project files

Implement:

1. Update PremiumPaywallView.swift to align with v2 design:
   * Use v2 color tokens (brand accent, surface, text colors)
   * Use .glassSurface() modifier on feature cards
   * Clean, minimal layout with clear CTA hierarchy
   * Keep ALL existing purchase/restore/dismiss logic intact
   * Do NOT change StoreKit product IDs, purchase calls, or restore flow

2. Update PremiumFeatureView.swift (gated feature wrapper):
   * Apply v2 styling to the locked feature overlay
   * Use neutral lock icon + upgrade CTA

3. Update PremiumUpgradeBanner.swift:
   * Apply v2 card styling
   * Non-intrusive, dismissable design

4. Update UI.xcstrings premium.* keys:
   * Review and clean up existing premium.* localization keys
   * Add any missing v2 copy keys
   * Preserve existing translations

Acceptance criteria:
* App compiles.
* Purchase/restore flow behavior is IDENTICAL to before.
* Paywall uses v2 visual tokens.
* Premium gate behavior unchanged.
* No StoreKit/entitlement logic changed.

Manual QA checklist:
* Open paywall from Settings.
* Verify visual alignment (glass cards, v2 colors).
* Tap Upgrade — purchase flow starts (sandbox).
* Tap Restore — restore flow runs.
* Tap dismiss — paywall closes.
* Premium feature locked state shows upgrade CTA.

Rollback note: Revert only the 3 view files and UI.xcstrings changes.
