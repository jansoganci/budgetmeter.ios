MASTER RULES — paste at the top of every phase prompt

BudgetMeter UI/UX v2 implementation.

Read first:
* docs/uiux_v2_implementation_plan.md
* docs/uiux_design_system_v2_tokens.md
* docs/uiux_design_direction_v1_decisions.md

Global rules:
* ONLY implement this phase. DO NOT continue.
* ONLY touch allowed files.
* DO NOT touch Core Data, auth, StoreKit, CalculationEngine, networking/sync, Xcode project files.
* Preserve existing names.
* If file structure differs, STOP and ask.
* After completion: files changed, exact changes, build/test result, QA checklist, rollback note.

⸻

PHASE 13 — Accessibility QA

Goal:
Verify and fix contrast, Dynamic Type, Reduce Transparency, and VoiceOver across all screens.

Allowed files — ALL feature view files (fixes only):
* budgetmeter.ios/Features/HomeFeature/View/
* budgetmeter.ios/Features/IncomesFeature/View/
* budgetmeter.ios/Features/ExpensesFeature/View/
* budgetmeter.ios/Features/SavingsGoalsFeature/View/
* budgetmeter.ios/Features/SettingsFeature/View/
* budgetmeter.ios/DesignSystem/Components/
* budgetmeter.ios/DesignSystem/Colors/BrandColors.swift (contrast fixes only)
* budgetmeter.ios/DesignSystem/Typography/TextStyles.swift (Dynamic Type fixes only)

Forbidden:
* Core Data, auth, StoreKit, CalculationEngine, networking/sync, Xcode project files
* Business logic changes
* Layout refactors
* New features

Implement these accessibility fixes:

1. **Color contrast**: Ensure all text/background combinations meet WCAG AA (4.5:1 for normal text, 3:1 for large text). Fix any low-contrast combinations in BrandColors.swift.

2. **Dynamic Type**: Verify all text styles use SwiftUI Dynamic Type (not hardcoded point sizes). Add `.dynamicTypeSize(...)` support where missing. Ensure no text clipping at AX5 (largest accessibility size).

3. **Reduce Transparency**: Verify all `.glassSurface()` usage falls back to solid colors when Reduce Transparency is enabled (already implemented in Phase 6, verify it works).

4. **VoiceOver**: Add `.accessibilityLabel()` and `.accessibilityValue()` to:
   * All card components (hero card, summary cards, goal cards)
   * All chart/indicator components
   * All buttons (especially icon-only buttons)
   * Financial values (read as complete phrases, not just numbers)

5. **Reduce Motion**: Verify animations respect `@Environment(\.accessibilityReduceMotion)`. Pulsey animation already does this — check other animations.

Acceptance criteria:
* App compiles.
* Text contrast meets WCAG AA minimum.
* All text uses Dynamic Type.
* Glass surfaces fall back solid when Reduce Transparency is on.
* VoiceOver reads all key UI elements.
* Animations respect Reduce Motion.
* No business logic changed.

Manual QA checklist:
* Enable VoiceOver — navigate Home, Income, Expense, Settings.
* Enable Reduce Transparency — verify glass cards become solid.
* Enable Reduce Motion — verify no unwanted animations.
* Set Dynamic Type to largest — verify no clipping.
* Check light + dark mode contrast.

Rollback note: Revert accessibility-specific changes to view files.
