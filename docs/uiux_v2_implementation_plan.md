# UI/UX v2 Implementation Plan

## 1. Executive Summary

- BudgetMeter UI/UX Design System v2 is implementable, but it must be shipped as small, isolated phases.
- Design-system primitives must be aligned before screen polish: colors, themes, typography, spacing, glass surfaces, then features.
- This is not one broad redesign. Cursor Composer 2.5 should work one phase per prompt with narrow file scope.
- Business logic must be preserved: do not change Core Data, auth provider logic, StoreKit entitlement logic, networking/sync, or calculation engine behavior.
- Currency formatting is high risk and must be isolated from visual styling. It may change display formatting only, never calculated values.
- Widget redesign is high risk and must be isolated because it uses a separate target and shared snapshot contract.
- Theme migration is high risk and must safely map old saved theme IDs to v2 IDs.
- Pulsey and onboarding must be isolated. Pulsey needs a static fallback because assets are missing; onboarding must not be forced on existing users.

## 2. Phase Overview Table

| Phase | Phase name | Goal | Risk level | Expected file scope | Composer suitability |
|---:|---|---|---|---|---|
| 1 | Current design-system audit confirmation | Verify current files and assumptions before edits | Low | Read-only repo inspection | Yes |
| 2 | Color/background/text token alignment | Align base color tokens with v2 | Medium | `budgetmeter.ios/DesignSystem/Colors/BrandColors.swift` | Yes |
| 3 | Theme preset model + migration mapping | Replace old theme IDs safely and preserve premium gating | High | `ThemeManager.swift`, `PremiumThemesView.swift`, focused tests if present | Yes |
| 4 | Typography token alignment | Align type scale and financial number font rules | Medium | `budgetmeter.ios/DesignSystem/Typography/TextStyles.swift` | Yes |
| 5 | Spacing + radius token alignment | Align spacing, sizing, and radius tokens | Medium | `budgetmeter.ios/DesignSystem/Spacing/LayoutTokens.swift` | Yes |
| 6 | Glass surface primitive + Reduce Transparency fallback | Add reusable v2 glass primitive | Medium | Design-system surface/token files only | Yes |
| 7 | Currency formatting shared contract | Centralize display formatting without changing calculations | High | `CurrencyHelper.swift`, display mappers/view models, widget writer, tests | Yes |
| 8 | Widget redesign | Make widget neutral, currency-aware, and v2-compliant | High | `BudgetMeterWidgets/`, `budgetmeter.ios/WidgetShared/`, widget service/writer | Yes |
| 9 | Paywall visual alignment | Align paywall visuals/copy while preserving purchase logic | Medium | Paywall/banner view files and localized strings | Yes |
| 10 | Pulsey static fallback architecture | Add Pulsey-ready architecture without requiring assets | Medium | New Pulsey component and approved placement files | Yes |
| 11 | New-user-only skippable onboarding | Add onboarding for new/not-completed users only | High | `budgetmeter.ios/Features/AuthFeature/`, small state helper if needed | Yes |
| 12 | Screen-by-screen polish | Apply primitives one feature folder at a time | Medium | One feature folder per prompt | Yes |
| 13 | Accessibility QA | Verify and fix contrast, Dynamic Type, Reduce Transparency, VoiceOver | High | Scoped by QA findings | Yes |

## 3. Detailed Phase Plan

### Phase 1 - Current Design-System Audit Confirmation

- **Goal:** Confirm the current implementation state before any edits.
- **Why this phase exists:** The worktree may be dirty, and Composer must not implement against stale assumptions.
- **Allowed file/folder scope:** Read-only inspection of `docs/uiux_design_direction_v1_decisions.md`, `docs/uiux_design_system_v2_tokens.md`, `budgetmeter.ios/DesignSystem/`, `budgetmeter.ios/CoreKit/Sources/Premium/ThemeManager.swift`, `budgetmeter.ios/CoreKit/Sources/Utilities/CurrencyHelper.swift`, `budgetmeter.ios/WidgetShared/`, and `BudgetMeterWidgets/`.
- **Forbidden files/folders:** All file edits. Do not modify Swift, Xcode, docs, resources, tests, or generated files.
- **Step-by-step instructions for Cursor Composer 2.5:**
  1. Read the two v1/v2 design documents.
  2. Confirm current color, typography, spacing, radius, glass/card, theme, widget, and currency files.
  3. List current old theme IDs and current widget files.
  4. List all manual currency formatting and hardcoded `$` display sites.
  5. Stop after producing an audit summary.
- **Acceptance criteria:** No files changed; audit lists exact files to touch in later phases.
- **Manual QA checklist:** Run `git status --short` before and after; confirm no new changes.
- **Rollback note:** None. This phase is read-only.

### Phase 2 - Color/Background/Text Token Alignment

- **Goal:** Align base color, background, text, status, and default accent tokens with v2.
- **Why this phase exists:** Existing screens already consume semantic colors, so primitive token changes should happen before screen polish.
- **Allowed file/folder scope:** `budgetmeter.ios/DesignSystem/Colors/BrandColors.swift`.
- **Forbidden files/folders:** Feature screens, widgets, theme manager, currency files, Xcode project files, Core Data files.
- **Step-by-step instructions for Cursor Composer 2.5:**
  1. Update app background to light `#F8FAFC` and dark `#0F172A`.
  2. Update text tokens to v2: primary `#0F172A/#F8FAFC`, secondary `#64748B/#94A3B8`, tertiary `#94A3B8/#64748B`.
  3. Add or align status colors: positive `#00C853`, negative `#FF5A5F`, neutral slate.
  4. Align default accent to Coral Default `#FF5A5F`.
  5. Preserve compatibility aliases used by existing code.
- **Acceptance criteria:** App compiles; existing color aliases still resolve; no screen files changed.
- **Manual QA checklist:** Check Home, Income, Expenses, Settings in light and dark mode for obvious readability regressions.
- **Rollback note:** Revert only `BrandColors.swift`.

### Phase 3 - Theme Preset Model + Migration Mapping

- **Goal:** Replace old theme presets with v2 theme IDs and safe migration.
- **Why this phase exists:** Existing users may have old saved theme IDs, and invalid values must safely fall back.
- **Allowed file/folder scope:** `budgetmeter.ios/CoreKit/Sources/Premium/ThemeManager.swift`, `budgetmeter.ios/Features/PremiumThemesFeature/View/PremiumThemesView.swift`, focused theme tests if they already exist.
- **Forbidden files/folders:** StoreKit purchase logic, premium entitlement matrix behavior, Core Data schema/model files, Xcode project, widgets.
- **Step-by-step instructions for Cursor Composer 2.5:**
  1. Define v2 themes: `coral_default`, `google_blue`, `fresh_green`, `mint_green`, `google_yellow`, `google_red`, `purple`, `sky_cyan`, `orange`.
  2. Apply migration mapping: `default` -> `coral_default`, `ocean` -> `google_blue`, `forest` -> `mint_green`, `sunset` -> `orange`, `purple` -> `purple`, `midnight` -> `sky_cyan`, unknown/invalid -> `coral_default`.
  3. Make only Coral Default free.
  4. Keep all other themes premium-gated through the existing premium capability.
  5. Do not touch StoreKit entitlement or purchase/restore logic.
  6. Update the theme picker UI only as needed to show the v2 presets.
- **Acceptance criteria:** Old saved theme IDs resolve safely; invalid IDs fall back to Coral Default; premium themes remain locked for non-premium users.
- **Manual QA checklist:** Test default theme, one migrated old ID, one invalid ID, and one premium theme selection as non-premium.
- **Rollback note:** Revert theme manager and premium themes view changes.

### Phase 4 - Typography Token Alignment

- **Goal:** Align typography tokens with v2 rules.
- **Why this phase exists:** Financial values need SF Pro Rounded, while normal UI text should remain SF Pro.
- **Allowed file/folder scope:** `budgetmeter.ios/DesignSystem/Typography/TextStyles.swift`.
- **Forbidden files/folders:** Feature layouts, widgets, currency formatting, theme files.
- **Step-by-step instructions for Cursor Composer 2.5:**
  1. Add or align semantic styles for hero financial, hero financial max, widget number, screen title, section title, card title, body, caption, and button.
  2. Use SF Pro Rounded only for financial numbers.
  3. Use SF Pro/system default for normal UI text.
  4. Preserve existing compatibility modifiers so current callers compile.
  5. Do not edit feature layouts in this phase.
- **Acceptance criteria:** App compiles; existing style methods still work; money styles use rounded and monospaced digits where appropriate.
- **Manual QA checklist:** Inspect Home hero value, dashboard metric cards, Settings rows, and paywall text at normal and large text sizes.
- **Rollback note:** Revert only `TextStyles.swift`.

### Phase 5 - Spacing + Radius Token Alignment

- **Goal:** Align spacing, height, padding, and radius tokens with v2.
- **Why this phase exists:** Layout rhythm should be centralized before glass and screen polish.
- **Allowed file/folder scope:** `budgetmeter.ios/DesignSystem/Spacing/LayoutTokens.swift`.
- **Forbidden files/folders:** Feature screens, widgets, typography files, color files, business logic.
- **Step-by-step instructions for Cursor Composer 2.5:**
  1. Add or align screen horizontal padding to 16pt.
  2. Add dashboard horizontal padding as optional 20pt.
  3. Set section gap to 20pt, card padding to 16pt, card gap to 12pt.
  4. Set row height to 48pt, button height to 52pt, modal padding to 24pt, widget padding to 16pt.
  5. Set card radius to 20pt, button radius to 14pt, modal radius to 24pt, widget radius to 22pt.
  6. Preserve compatibility names used by existing code.
- **Acceptance criteria:** App compiles; existing token names still resolve; no feature screen files changed.
- **Manual QA checklist:** Check Home, Income, Expenses, Settings for obvious clipping or oversized controls.
- **Rollback note:** Revert only `LayoutTokens.swift`.

### Phase 6 - Glass Surface Primitive + Reduce Transparency Fallback

- **Goal:** Create a reusable v2 glass card/surface primitive with Reduce Transparency fallback.
- **Why this phase exists:** Glass should be a design-system primitive, not one-off screen styling.
- **Allowed file/folder scope:** `budgetmeter.ios/DesignSystem/Spacing/LayoutTokens.swift` or a new file under `budgetmeter.ios/DesignSystem/Components/Surfaces/`.
- **Forbidden files/folders:** Feature-wide screen migrations, widgets, currency files, theme migration files.
- **Step-by-step instructions for Cursor Composer 2.5:**
  1. Add a reusable glass surface/card modifier or component.
  2. Use medium glass values from v2: light rgba white around 0.72, dark slate around 0.70.
  3. Add subtle border and shadow.
  4. Support `accessibilityReduceTransparency` and fall back to opaque surface card values.
  5. Do not migrate all existing screens in this phase.
- **Acceptance criteria:** New primitive compiles; existing `surfaceCard` behavior remains available; Reduce Transparency fallback exists.
- **Manual QA checklist:** Preview or inspect the primitive in light/dark and with Reduce Transparency enabled.
- **Rollback note:** Remove the new primitive or revert the single modified design-system file.

### Phase 7 - Currency Formatting Shared Contract

- **Goal:** Centralize display formatting without changing calculated values.
- **Why this phase exists:** Currency formatting is high risk and currently duplicated across view models, display mappers, and widgets.
- **Allowed file/folder scope:** `budgetmeter.ios/CoreKit/Sources/Utilities/CurrencyHelper.swift`, `budgetmeter.ios/Features/HomeFeature/ViewModel/HomeDisplayMapping.swift`, scoped Home/Income/Expense/Insights view models, `budgetmeter.ios/CoreKit/Sources/Widget/WidgetSnapshotWriter.swift`, relevant existing tests.
- **Forbidden files/folders:** `CalculationEngine`, Core Data model/migrations, visual styling files, theme files, paywall visuals.
- **Step-by-step instructions for Cursor Composer 2.5:**
  1. Add a shared display API equivalent to `CurrencyDisplay.format(amount: Decimal, currencyCode: String, locale: Locale) -> String`.
  2. Keep numeric calculations unchanged.
  3. Replace manual display-only symbol/sign/grouping logic with shared helpers.
  4. Keep text-field numeric formatting separate from currency display formatting.
  5. Remove hardcoded `$` from production display code.
  6. Ensure widgets use the same display contract through snapshot generation.
- **Acceptance criteria:** No calculated values change; selected currency appears consistently; no new hardcoded `$` in production display code; tests cover at least USD, EUR, and TRY display examples.
- **Manual QA checklist:** Check Home pace, Income totals, Expense totals, Insights charts, and widget snapshot output with USD/EUR/TRY.
- **Rollback note:** Revert currency helper, display mapper/view model, widget writer, and related test changes from this phase only.

### Phase 8 - Widget Redesign

- **Goal:** Redesign the widget to match v2 calm neutral rules.
- **Why this phase exists:** Current widget uses full green/red/blue gradient backgrounds, which v2 explicitly forbids.
- **Allowed file/folder scope:** `BudgetMeterWidgets/`, `budgetmeter.ios/WidgetShared/`, `budgetmeter.ios/CoreKit/Sources/Widget/`.
- **Forbidden files/folders:** Main app screen styling, calculation engine, StoreKit/premium purchase logic, auth logic.
- **Step-by-step instructions for Cursor Composer 2.5:**
  1. Use neutral widget background: light `#F8FAFC`, dark `#0F172A`.
  2. Remove full green/red/blue gradient status backgrounds.
  3. Use daily net pace as the main value.
  4. Use user-selected currency from the shared display contract.
  5. Express status through text color plus arrow/icon, not full background fill.
  6. Preserve locked, stale, missing, insufficient-data, and unlocked states.
  7. Keep widget padding at 16pt and radius at 22pt where applicable.
- **Acceptance criteria:** Widget has no full status gradient backgrounds; locked/stale/missing states still work; widget value uses selected currency.
- **Manual QA checklist:** Preview unlocked positive, unlocked negative, neutral, locked, stale, missing, light mode, dark mode, and large text.
- **Rollback note:** Revert only widget target, widget shared, and widget writer/service changes.

### Phase 9 - Paywall Visual Alignment

- **Goal:** Align paywall visuals and copy with v2 while preserving purchase behavior.
- **Why this phase exists:** Paywall is a key premium surface and will later host Pulsey.
- **Allowed file/folder scope:** `budgetmeter.ios/Features/PremiumFeature/View/PremiumPaywallView.swift`, `budgetmeter.ios/DesignSystem/Components/Cards/PremiumUpgradeBanner.swift`, relevant localized UI strings if needed.
- **Forbidden files/folders:** StoreKit purchase/restore logic, premium entitlement matrix, theme migration, widgets, currency implementation.
- **Step-by-step instructions for Cursor Composer 2.5:**
  1. Apply v2 copy direction: "Make BudgetMeter feel yours. Unlock themes, widgets, and deeper insights."
  2. Use v2 surface/accent primitives.
  3. Reserve a Pulsey header or hero slot, but do not require Pulsey assets.
  4. Do not place Pulsey next to every premium feature item.
  5. Do not touch purchase, restore, entitlement, or product-loading logic.
- **Acceptance criteria:** Purchase and restore callbacks remain unchanged; paywall builds without Pulsey assets; visuals use v2 tokens/primitives.
- **Manual QA checklist:** Open paywall from premium feature gates, widget gate, and theme gate; verify buttons still work.
- **Rollback note:** Revert paywall/banner/localized string changes from this phase.

### Phase 10 - Pulsey Static Fallback Architecture

- **Goal:** Add Pulsey-ready architecture that works before assets and Lottie are available.
- **Why this phase exists:** Pulsey assets are not in the repo, and Lottie can be added later.
- **Allowed file/folder scope:** New component under `budgetmeter.ios/DesignSystem/Components/Pulsey/`, approved placement files such as `SplashView`, `WelcomeView`, `PremiumPaywallView`, and selected empty states.
- **Forbidden files/folders:** Income/expense input forms, transaction lists, charts, main Settings screen, widget live surface, Xcode project, package/dependency files unless separately approved.
- **Step-by-step instructions for Cursor Composer 2.5:**
  1. Create a `PulseyView` or equivalent component.
  2. Support static image fallback first.
  3. Make the component safe when no asset exists: hide gracefully or render a neutral placeholder without breaking the build.
  4. Leave Lottie integration as a future extension point.
  5. Place Pulsey only in approved contexts.
- **Acceptance criteria:** App builds without Pulsey assets; no Lottie dependency required; Pulsey does not appear in forbidden contexts.
- **Manual QA checklist:** Check splash, welcome, paywall, and one empty state in light/dark.
- **Rollback note:** Remove the Pulsey component and approved placements.

### Phase 11 - New-User-Only Skippable Onboarding

- **Goal:** Add onboarding only for new or not-yet-onboarded users.
- **Why this phase exists:** Existing users must not be forced into onboarding after v2 ships.
- **Allowed file/folder scope:** `budgetmeter.ios/Features/AuthFeature/`, a small onboarding state helper if needed, localized UI strings.
- **Forbidden files/folders:** Auth provider logic, Supabase logic, StoreKit logic, Core Data schema/migrations, calculation engine.
- **Step-by-step instructions for Cursor Composer 2.5:**
  1. Confirm the safest existing persistence pattern for onboarding completion.
  2. Add onboarding completion state without forcing existing users into onboarding.
  3. Show onboarding only to new/not-yet-onboarded users.
  4. Add Skip and Continue paths.
  5. Persist completion when skipped or finished.
  6. Do not alter sign-in provider behavior.
- **Acceptance criteria:** Existing users continue to normal app flow; new/not-completed users see skippable onboarding; skipping onboarding allows core app usage.
- **Manual QA checklist:** Test fresh install, existing signed-in user, signed-out flow, skip, completion, and relaunch.
- **Rollback note:** Revert onboarding views/state helper and routing changes from this phase.

### Phase 12 - Screen-by-Screen Polish

- **Goal:** Apply v2 primitives to screens in small, reviewable prompts.
- **Why this phase exists:** Broad screen polish is where Composer is most likely to create large risky diffs.
- **Allowed file/folder scope:** One feature folder per prompt only, in this exact order:
  1. `budgetmeter.ios/Features/HomeFeature/`
  2. `budgetmeter.ios/Features/IncomesFeature/`
  3. `budgetmeter.ios/Features/ExpensesFeature/`
  4. `budgetmeter.ios/Features/AuthFeature/`
  5. `budgetmeter.ios/Features/InsightsFeature/`
  6. `budgetmeter.ios/Features/SettingsFeature/`
- **Forbidden files/folders:** Multiple feature folders in one prompt, currency changes, widget changes, theme migration, business logic, calculation engine.
- **Step-by-step instructions for Cursor Composer 2.5:**
  1. Work on one feature folder only.
  2. Replace one-off colors/cards/buttons with design-system tokens and primitives.
  3. Avoid changing view model behavior.
  4. Do not introduce new one-off styles.
  5. Stop after each feature folder and provide a diff summary.
- **Acceptance criteria:** Target feature compiles; no business behavior changes; styling uses shared primitives where available.
- **Manual QA checklist:** Navigate the target feature in light/dark, large Dynamic Type, and Reduce Transparency where relevant.
- **Rollback note:** Revert only the feature folder touched in that sub-phase.

### Phase 13 - Accessibility QA

- **Goal:** Validate and fix v2 accessibility requirements.
- **Why this phase exists:** Accessibility must be verified after primitives and screens are integrated.
- **Allowed file/folder scope:** Files identified by QA findings; prefer `DesignSystem/` fixes before individual screen fixes.
- **Forbidden files/folders:** Calculation engine, auth provider logic, StoreKit entitlement logic, networking/sync, unrelated feature behavior.
- **Step-by-step instructions for Cursor Composer 2.5:**
  1. Check WCAG AA contrast in light/dark and all theme accents.
  2. Test largest Dynamic Type sizes and fix clipping.
  3. Test Reduce Transparency fallback.
  4. Add or fix VoiceOver labels on charts, hero values, widget main number, and CTAs.
  5. Ensure financial status is never color-only; pair color with sign, icon, and text.
- **Acceptance criteria:** No critical clipping in primary flows; Reduce Transparency uses opaque surfaces; key values and CTAs have useful VoiceOver labels.
- **Manual QA checklist:** Home, Income, Expenses, Insights charts, Settings, Paywall, Onboarding, and Widget.
- **Rollback note:** Revert individual accessibility fixes that cause regressions.

## 4. Cursor Composer 2.5 Prompt Rules

- Use one phase per prompt.
- Include exact allowed files/folders in every prompt.
- Include exact forbidden files/folders in every prompt.
- Do not allow unrelated code changes.
- Do not allow broad refactors.
- Tell Composer to stop if file structure differs from assumptions.
- Require Composer to provide a file-by-file diff summary.
- Require build/test after each phase, or a clear reason if not run.
- Require Composer to ask before touching uncertain files.
- For currency and widget phases, explicitly forbid visual or unrelated logic changes.
- For screen polish, work on one feature folder per prompt.

## 5. Risk Register

| Risk | Why it matters | Mitigation | Phase |
|---|---|---|---|
| Currency display regression | Money can look wrong even when calculations are correct | Isolate display formatting and add examples/tests | 7 |
| Old theme ID migration | Existing saved settings may point to removed theme IDs | Use explicit migration mapping and invalid fallback | 3 |
| Premium gating regression | Free users could access premium themes/widgets or premium users could be blocked | Do not touch StoreKit/entitlement logic; only consume existing gates | 3, 8 |
| Widget shared storage mismatch | Widget may not receive selected currency or theme | Verify shared snapshot/app group contract in widget phase | 8 |
| Glass readability/performance | Overuse of blur/material can reduce contrast or hurt performance | Add reusable primitive and Reduce Transparency fallback before migration | 6, 13 |
| Dynamic Type clipping | Large text can break card/widget layouts | QA after primitives and screen polish | 13 |
| Missing Pulsey assets | Build or UI could depend on unavailable assets | Static fallback architecture; no required Lottie dependency | 10 |
| Existing users forced into onboarding | Existing users would experience a release regression | Completion state and existing-user-safe routing | 11 |
| Broad Composer diffs | Hard to review, hard to roll back | One phase per prompt, exact scope | All |
| One-off styling | Design system becomes inconsistent again | Primitives first; screen polish later | 2, 4, 5, 6, 12 |

## 6. Dependencies and Blockers

- **Pulsey assets missing:** Does not block early phases. Phase 10 must support static fallback and build safely without assets.
- **Lottie package unknown:** Defer. Do not add a Lottie dependency until explicitly approved in a future phase.
- **Onboarding state key needs confirmation:** Blocks Phase 11 only. Confirm existing persistence pattern before implementation.
- **Widget shared theme/currency access needs confirmation:** Handled in Phase 8. Verify current snapshot/app group contract before redesign.
- **Currency formatter duplication:** Phase 7 must solve carefully by centralizing display formatting only.
- **Dirty worktree:** Implementation prompts must avoid unrelated files and require file-by-file diff summaries.

## 7. Final Recommendation

Start with **Phase 1 - Current design-system audit confirmation** only.

Implementation should not begin with screen polish. The safest first step is a read-only confirmation of current token files, theme files, widget files, and currency formatting call sites. That gives Cursor Composer 2.5 a reliable, narrow map before any code changes are requested.
