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
* Stop after this phase.

⸻

PHASE 12 — Screen-by-Screen Polish

Goal:
Apply v2 design system tokens to all feature screens: Home, Income, Expense, Savings, Settings, and shared components.

Allowed files — ALL of these:
* budgetmeter.ios/Features/HomeFeature/View/
* budgetmeter.ios/Features/HomeFeature/ViewModel/HomeDisplayMapping.swift
* budgetmeter.ios/Features/IncomesFeature/View/
* budgetmeter.ios/Features/ExpensesFeature/View/
* budgetmeter.ios/Features/SavingsGoalsFeature/View/
* budgetmeter.ios/Features/SettingsFeature/View/
* budgetmeter.ios/DesignSystem/Components/Cards/
* budgetmeter.ios/DesignSystem/Components/Charts/
* budgetmeter.ios/DesignSystem/Components/Indicators/
* budgetmeter.ios/DesignSystem/Components/Rows/
* budgetmeter.ios/DesignSystem/Components/Sections/
* budgetmeter.ios/Features/Shared/

Forbidden:
* Core Data, auth, StoreKit, CalculationEngine, networking/sync, Xcode project files
* Widgets (already done in Phase 8)
* Paywall views (already done in Phase 9)
* Theme migration files
* CurrencyHelper.swift (already done in Phase 7)
* TextStyles.swift (already done in Phase 4)
* LayoutTokens.swift (already done in Phase 5)
* BrandColors.swift (already done in Phase 2)

Implement:

1. Apply v2 color tokens across all feature screens:
   * Use Color.appBackground instead of hardcoded colors
   * Use Color.surfaceCard / .glassSurface() for cards
   * Use Color.textPrimary / textSecondary for text
   * Use Color.brandAccent (coral) for CTAs and highlights
   * Use Color.positive / negative for financial status colors

2. Apply v2 typography:
   * Use existing semantic styles (paceHeroStyle, sectionTitleStyle, bodyStyle, captionStyle, etc.)
   * Replace hardcoded .font(.title), .font(.body), etc. with semantic styles

3. Apply .glassSurface() to card components:
   * MomentumHeroCard
   * FinancialSummaryCard
   * MonthSummaryCard
   * CompactHealthCard
   * CompactSavingsCard
   * Any other card component

4. Apply v2 spacing/radius tokens:
   * Replace hardcoded padding values with LayoutTokens
   * Ensure consistent card spacing

5. Do NOT change:
   * Business logic
   * ViewModel logic
   * Data flow
   * Navigation structure

Acceptance criteria:
* App compiles.
* All feature screens use v2 design tokens.
* .glassSurface() used on cards.
* No business logic changed.
* No Core Data, auth, or StoreKit logic touched.

Manual QA checklist:
* Home screen — hero card, savings card, sections all use v2 tokens.
* Income screen — summary cards, sections, rows look consistent.
* Expense screen — same as Income.
* Savings screen — goal cards use glass surface.
* Settings — rows, sections use v2 tokens.
* Light + dark mode both readable.
* Dynamic Type at largest size — no clipping.

Rollback note: Revert all changed view files.
