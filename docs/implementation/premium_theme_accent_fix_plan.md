# Premium Theme Accent Fix Plan

**Status:** Planning only - no implementation in this document  
**Date:** 22 June 2026  
**Related findings:** Premium Themes audit, June 2026

---

## 1. Purpose

This document plans the correct product, design-system, and technical approach for fixing Premium Themes in BudgetMeter iOS.

It is a planning document only. It does not implement SwiftUI changes, modify `ThemeManager`, change `PremiumManager`, touch StoreKit, alter widgets, or change app logic.

The goal is to make selected premium themes visibly affect the app through controlled accent-layer styling without turning BudgetMeter into a full app reskin.

## 2. Problem Summary

Premium themes can be selected from the Premium Themes screen, and `ThemeManager` state appears to update.

The current theme is stored and published through `ThemeManager.currentTheme`, and root app surfaces observe `ThemeManager`.

However, most visible UI remains Coral Default because many shared DesignSystem components use static color tokens such as `Color.accentPrimary`, `Color.brandProgress`, and other `BrandColors` aliases.

Root cause: selected themes currently affect only a small part of the app because the runtime theme accent is not consistently connected to DesignSystem accent-layer components.

## 3. Product Decision

Premium Themes are accent-only.

They are not full app reskins.

BudgetMeter should remain calm, neutral, and finance-focused. Themes should add personality to actions, selected states, and safe decorative accents without changing the stable financial reading experience.

## 4. What Should Change

The selected theme should affect these UI layers:

- Primary CTA fill
- Selected tab tint
- Selected picker/chip state
- Selected row/checkmark states
- Settings non-destructive icon accents
- Premium badge/highlight accent
- Non-financial progress accents
- Non-status chart primary series
- Theme preview UI
- Optional mascot tint / subtle glow, if already available

## 5. What Must Not Change

These must remain semantic/static:

- App background
- Glass/card surfaces
- Text colors
- Income positive green
- Expense/negative red/coral
- Warning/caution colors
- Error/destructive colors
- Financial status colors
- Layout, spacing, radius
- Core financial meaning

## 6. Widget Decision

Widgets are out of scope for the first fix.

Widget theme sync requires separate shared persisted theme handling because the widget target cannot rely on the app runtime singleton in the same way as the main app.

Do not touch widget implementation in the first app theme fix.

## 7. App Icon Decision

App icon switching is not the main scope.

The existing app icon attempt in `ThemeManager` may remain as-is.

Do not make app icon switching a blocker for this fix. The first fix should succeed even if alternate app icons are unavailable or partially configured.

## 8. Current Architecture

Themes are defined in `CoreKit/Sources/Premium/ThemeManager.swift` as `AppTheme` cases:

- `coral_default`
- `google_blue`
- `fresh_green`
- `mint_green`
- `google_yellow`
- `google_red`
- `purple`
- `sky_cyan`
- `orange`

The selected theme is stored in Core Data on `AppSettings.selectedTheme`.

`ThemeManager.currentTheme` is `@Published`, and `ThemeManager.accentColor` resolves the current theme's primary color.

Root accent color is applied in:

- `budgetmeter_iosApp.swift`
- `ContentView.swift`

This is insufficient because most custom SwiftUI components do not inherit root accent styling. They directly use static tokens from `BrandColors.swift`, especially `Color.accentPrimary`.

Static accent usage currently appears in shared UI such as:

- `PrimaryCTAButton`
- `PremiumBadge`
- Settings rows
- Picker selected states
- Some progress and chart accents
- Several card/row components using `brandProgress` or `accentPrimary`

## 9. Proposed Architecture

Use a centralized runtime theme accent pattern in the DesignSystem.

Options:

### A. Environment value such as `themeAccent`

Best for SwiftUI. Root provides the selected accent once, and components read it through the environment. This keeps components testable and avoids hard singleton coupling.

### B. Theme-aware DesignSystem helper

Acceptable if implemented as a small centralized resolver, but it must still be reactive and easy for SwiftUI components to consume.

### C. Direct `ThemeManager.shared` reads inside components

Not recommended. This couples visual components to a global service, makes previews/tests weaker, and spreads theme logic across the UI.

Recommended option: **A, environment-driven theme accent**, optionally supported by a tiny DesignSystem helper for naming clarity.

Default behavior:

- Root injects the current theme accent.
- Components use the runtime accent only for accent-layer UI.
- Static `BrandColors` remain intact for semantic colors, surfaces, text, and financial states.

## 10. Proposed Theme Scope

Default free theme:

- `coral_default`

Premium themes:

- `google_blue`
- `fresh_green`
- `mint_green`
- `google_yellow`
- `google_red`
- `purple`
- `sky_cyan`
- `orange`

No new themes should be added in this fix.

The selected theme should only change accent-layer tokens.

## 11. Recommended Implementation Phases

### Phase 1

Add a runtime theme accent token/pattern.

Keep static `BrandColors` intact for semantic colors.

### Phase 2

Migrate only core accent-layer components:

- `PrimaryCTAButton`
- `PremiumBadge`
- Selected tab tint if needed
- Settings non-destructive icon accents
- Selected picker/chip states

### Phase 3

Migrate non-financial progress/chart accents where safe.

Do not change financial status charts or colors where green/red encode meaning.

### Phase 4

Run manual QA and dark mode contrast checks.

Verify that the app feels visibly themed but still calm and neutral.

### Phase 5

Optional follow-up: plan widget theme sync separately.

Do not implement widget changes in the first pass.

## 12. Recommended Files to Change Per Phase

### Phase 1

Likely files:

- `CoreKit/Sources/Premium/ThemeManager.swift` only if adding a passive exported type is unavoidable; otherwise avoid changing it.
- `DesignSystem/Colors/BrandColors.swift` or a new DesignSystem theme-token file to define the runtime accent environment/helper.
- `budgetmeter_iosApp.swift` and/or `ContentView.swift` to inject the runtime accent into the SwiftUI environment.

Reason: establish one reactive source of truth for accent-layer UI.

### Phase 2

Likely files:

- `DesignSystem/Components/Buttons/PrimaryCTAButton.swift` for primary CTA fill.
- `DesignSystem/Components/Badges/PremiumBadge.swift` for premium highlight accent.
- `Features/SettingsFeature/View/SettingsView.swift` for non-destructive settings icon accents.
- Settings picker views such as appearance, language, and currency pickers for selected state accents.
- `ContentView.swift` only if selected tab tint needs adjustment beyond the existing root `.accentColor`.

Reason: make the most visible app accents update first.

### Phase 3

Likely files:

- Safe progress components that use `Color.accentPrimary` or `Color.brandProgress` for non-financial progress.
- Safe chart components where the primary series is not encoding positive/negative/caution meaning.
- Selected row/checkmark components that are purely selection UI.

Reason: extend theme visibility without corrupting financial semantics.

### Phase 4

No planned source changes unless QA finds defects.

Run app-level manual checks in light and dark mode.

### Phase 5

Likely future files:

- `WidgetShared/WidgetDesignTokens.swift`
- widget snapshot/shared persistence code
- widget rendering files

Reason: widget theme sync needs separate shared persisted theme design and is intentionally excluded from the first fix.

## 13. Do-Not-Touch List

Do not change:

- StoreKit purchase flow
- `PremiumManager` entitlement logic
- DEBUG premium override behavior
- Core Data schema
- Paywall purchase/restore logic
- Navigation
- Financial calculation logic
- Income/expense semantic colors
- Widget implementation in the first pass
- Broad UI redesign/layout changes

## 14. Risks

- Partial migration causing visual inconsistency
- Too much color making the app noisy
- Dark mode contrast issues
- Confusing financial meaning
- Hardcoded colors remaining
- Unnecessary StoreKit/premium side effects
- Widget target limitations

## 15. Test Plan

Manual checks:

- Select Purple theme.
- Select Blue theme.
- Restart app and verify selected theme persists.
- Verify primary CTA changes.
- Verify selected tab tint changes.
- Verify settings icon accent changes.
- Verify premium badge/highlights change.
- Verify background/cards/text do not change.
- Verify income green and expense red still remain semantic.
- Verify dark mode contrast.
- Verify Premium Mode off still gates Premium Themes correctly.
- Verify Premium Mode on allows selecting themes.

Automated checks if practical:

- Add a focused test for theme ID persistence if not already covered.
- Add snapshot or lightweight UI checks only after the runtime token pattern is stable.

## 16. Acceptance Criteria

- [ ] Selected premium theme is visibly reflected in accent-layer UI.
- [ ] App remains calm and neutral.
- [ ] Financial semantic colors are preserved.
- [ ] No full reskin behavior is introduced.
- [ ] No StoreKit changes are made.
- [ ] No `PremiumManager` entitlement changes are made.
- [ ] No widget changes are made in the first pass.
- [ ] Selected theme persists after restart.
- [ ] Build and tests pass.

## 17. Implementation Complexity

This is a medium design-system refactor.

It is not a deep StoreKit or entitlement fix because `ThemeManager`, persistence, publishing, and root observation already exist.

It is more than a small fix because many visible components currently use static `BrandColors` tokens directly, and the app needs a consistent runtime accent pattern.

Safe for Cursor Auto:

- Narrow replacements after the runtime accent API is already defined.
- Simple component migrations such as `PrimaryCTAButton` and `PremiumBadge`.

Should use Composer/Codex-level reasoning:

- Designing the runtime environment/token pattern.
- Deciding whether a color usage is accent-layer or financial-semantic.
- Migrating charts/progress components without breaking financial meaning.
- Reviewing dark mode contrast and product consistency.
