# Phase 4 — DesignSystem Redesign Scope

## 1. Executive Summary

Phase 4 should turn the existing v2/v2.1 DesignSystem into the stable visual foundation for BudgetMeter's Playful Momentum FinTech redesign.

The current system is usable and partially tokenized, but it is not yet aligned tightly enough with the final product direction. It mixes app tokens, raw SwiftUI/system colors, direct fonts, direct radii, broad category colors, legacy card styles, and screen-specific styling. The first implementation step should be a small token pass, not a full screen redesign.

Recommendation: **Ready for implementation planning, not started.** First safe implementation step: add/refine semantic tokens in `DesignSystem/Colors`, `Typography`, and `Spacing` without changing feature behavior.

## 2. Current DesignSystem Inventory

Current folders:

- `DesignSystem/Colors/`
  - `BrandColors.swift`
  - `CategoryColors.swift`
- `DesignSystem/Typography/`
  - `TextStyles.swift`
- `DesignSystem/Spacing/`
  - `LayoutTokens.swift`
- `DesignSystem/Animations/`
  - `AnimationCurves.swift`
- `DesignSystem/Components/Cards/`
  - summary, health, savings, interval, daily budget, hero, premium, greeting, and momentum cards
- `DesignSystem/Components/Indicators/`
  - `TrendIndicator.swift`
  - `MomentumRingView.swift`
- `DesignSystem/Components/Charts/`
  - `MiniBarChart.swift`
- `DesignSystem/Components/Rows/`
  - financial rows, subscription rows, add rows, empty rows
- `DesignSystem/Components/Sections/`
  - `FinancialSection.swift`

Feature usage:

- Home uses DesignSystem spacing, colors, compact cards, and currently has momentum hero/ring files available.
- Income and Expenses use `FinancialSummaryCard`, `FinancialSection`, `FinancialRowView`, `AddFinancialItemRow`, and subscription rows.
- Settings mostly uses native `List` styling and many `.primary`, `.secondary`, `.red`, `.yellow`, and system backgrounds.
- Shared sheets/modals mix DesignSystem tokens with raw system colors and raw numeric radii.

## 3. Current Visual / Design Problems

- Background is true black in dark mode, not the planned obsidian/dark navy base.
- Card surfaces are slate-like but need stronger semantic layering: base, raised, inset, overlay, and sheet.
- Negative state is red, not the intended softer coral/drain language.
- Caution uses raw yellow/orange in several places instead of an amber semantic token.
- Purple and pink exist in category colors; they should remain category accents only and not become dominant brand gradients.
- Typography uses manual `sizeCategory.scaleFactor`; useful, but risky for very large Dynamic Type because many components also use fixed heights.
- Many views use direct `.font(.body)`, `.font(.caption)`, `.primary`, `.secondary`, raw `Color(uiColor:)`, and raw `cornerRadius`.
- Several cards use gradients for primary financial surfaces; critical numbers should stay on solid or near-solid readable surfaces.
- Reusable rows currently include premium/paywall logic in `AddFinancialItemRow`, which is risky for a pure design-system pass.
- Chart components are simple and animated, but not yet tied to the momentum design language.
- Empty states are functional but not yet Pulsey-aware or momentum-aware.

## 4. Existing Reusable Components

Reusable today:

- `FinancialSummaryCard`
- `HeroNetFlowCard`
- `MomentumHeroCard`
- `MomentumRingView`
- `MonthSummaryCard`
- `CompactDailyBudgetCard`
- `CompactHealthCard`
- `CompactSavingsCard`
- `HealthScoreCard`
- `SavingsGoalCard`
- `IntervalMetricCard`
- `CompactIntervalCard`
- `PremiumUpgradeBanner`
- `FinancialRowView`
- `SubscriptionRowView`
- `AddFinancialItemRow`
- `EmptyStateRow`
- `FinancialSection`
- `MiniBarChart`
- `TrendIndicator`
- `AnimationCurve`
- `Haptics`

These should be audited and refined before creating many new components.

## 5. Components That Need Redesign

Highest priority:

- `BrandColors`: align to obsidian/navy, slate, cyan/blue/indigo, emerald, amber, coral.
- `TextStyles`: create semantic pace/metric/status styles and reduce screen-level manual fonts.
- `LayoutTokens`: add surface/radius/shadow/glass tokens for dark-first hierarchy.
- `MomentumHeroCard` and `MomentumRingView`: verify Phase 3 compatibility, accessibility, text scaling, and visual restraint.
- `HeroNetFlowCard` / `CompactDailyBudgetCard`: reduce gradient dependence for critical numbers.
- `FinancialSummaryCard`: keep useful for Income/Expenses but align surfaces and typography.
- `PremiumUpgradeBanner`: avoid casino-like premium glow and keep premium visual treatment controlled.
- `FinancialSection` and rows: standardize surface, divider, icon, and text treatment.
- `MiniBarChart` / `TrendIndicator`: use semantic colors and accessible labels.

## 6. Missing Tokens / Components

Missing or underdefined:

- semantic surface tokens: app background, raised card, inset surface, sheet surface, overlay/glass surface
- semantic financial states: moving forward, slowing down, neutral, insufficient data, caution
- coral drain token distinct from destructive red
- amber caution token distinct from yellow warning
- border/stroke tokens for dark surfaces
- typography tokens for pace hero, live metric, section title, compact value, footnote, badge
- button variants: primary, secondary, destructive, quiet icon, locked/premium
- status badge component
- metric value component with monospaced digits and sign handling
- section header component
- reusable sheet container/input surface styling
- reusable empty state pattern with optional Pulsey slot
- glass token rules limited to sheets, overlays, navigation, and secondary surfaces

## 7. Recommended v1 Token System

### Colors

- `surfaceObsidian`: dark navy/obsidian app base
- `surfaceCard`: slate card surface
- `surfaceRaised`: slightly brighter elevated slate
- `surfaceInset`: darker inset input/progress surface
- `surfaceOverlay`: modal/sheet overlay surface
- `accentPrimary`: cyan/blue
- `accentSecondary`: indigo, restrained
- `financialPositive`: emerald
- `financialCaution`: amber
- `financialNegative`: coral
- `financialNeutral`: blue-gray/slate
- `textPrimary`, `textSecondary`, `textTertiary`
- `borderSubtle`, `borderFocus`, `dividerSubtle`
- `chartTrack`, `chartPositive`, `chartCaution`, `chartNegative`

Keep category purple/pink available only as category colors, not as the dominant app theme.

### Typography

- `paceHero`: largest Home pace number, monospaced digits
- `metricLarge`: important card values
- `metricMedium`: secondary metrics
- `metricCompact`: rows/cards
- `statusTitle`: pace/status copy
- `sectionTitle`
- `body`
- `caption`
- `badge`

Financial values should use monospaced digits. Long localized status copy must wrap without overlapping values.

### Spacing

Keep the 4/8/12/16/24/32 scale. Add semantic aliases:

- `screenPadding`
- `sectionGap`
- `cardPadding`
- `cardInternalGap`
- `rowGap`
- `controlGap`

### Radius

Use restrained radii:

- cards: 12 or 16, but avoid overly pill-like repeated surfaces
- buttons: 10 or 12
- badges/chips/progress: 6 or 8
- charts: 2 or 4

### Shadows / Glass

- Dark mode should rely more on border, elevation color, and subtle shadow than heavy glow.
- Glass is allowed only for sheets, overlays, navigation, or secondary surfaces.
- Critical financial numbers should appear on solid or near-solid surfaces.
- Premium visuals should not use gold/casino glow.

### Semantic Financial States

- `movingForward`: emerald + upward icon/copy
- `slowingDown`: coral + downward/slowdown icon/copy
- `neutral`: cyan/slate + steady icon/copy
- `insufficientData`: text secondary + setup icon/copy
- `caution`: amber + attention icon/copy

Color must be paired with copy and iconography.

## 8. Recommended Component Scope

### Cards

- Base card surface modifier
- Hero momentum card
- Compact metric card
- Summary card
- Insight/drain card
- Savings progress card
- Premium banner card

### Buttons

- Primary action
- Secondary action
- Destructive action
- Quiet icon button
- Locked/premium action

### Metric Displays

- Signed money value
- Unit label, e.g. `/day`, `/min`
- Live small metric
- Compact amount formatter surface

### Pace / Status Indicators

- Momentum ring
- Status badge
- Biggest drain indicator
- Trend indicator

### Empty States

- Generic empty state
- Home getting-started empty state
- Optional Pulsey slot for later, not required in Phase 4 first pass

### Sheets

- Sheet background/surface
- Input field surface
- Toolbar/action button styling

### Section Headers

- Standard section title
- Optional subtitle/action
- Disclosure header for income/expense sections

## 9. Home Dependency

What Phase 3 needs from DesignSystem:

- stable colors for pace states
- monospaced pace number styling
- `MomentumHeroCard` / `MomentumRingView` or equivalent audited components
- card surface and border tokens
- status/biggest-drain/savings row styling
- accessibility-safe text scaling for the hero

What should wait until after Phase 3:

- broad screen-by-screen visual cleanup
- Settings list redesign
- premium theme redesign
- advanced chart styles
- Pulsey empty-state artwork
- large theme/personalization changes
- full Income/Expense redesign beyond token adoption

## 10. Accessibility Requirements

Contrast:

- Text and critical money values must meet readable contrast on dark surfaces.
- Accent text on colored surfaces must be checked, especially amber/coral/cyan.
- Avoid low-opacity text for financial values.

Dynamic Type:

- Do not rely on fixed card heights for long localized copy or accessibility sizes.
- Hero numbers must scale down safely and wrap supporting copy.
- Buttons and rows must preserve at least 44pt touch targets.

Color Is Not The Only Signal:

- Pace state must use copy, icon, and layout in addition to color.
- Trends should expose direction text, not only green/red.
- Locked/premium states need labels/icons, not color alone.

VoiceOver Label Strategy:

- Cards should combine children only when the combined label is clearer.
- Financial values should include sign, currency, and unit.
- Momentum ring should be hidden if the hero label already describes state.
- Charts should summarize direction and number of points, not every point.
- Buttons need action-oriented labels and concise hints.

## 11. Localization Impact

- Financial status copy can be longer in other languages; hero layout must allow wrapping.
- Unit labels (`/day`, `/min`, `/month`, `/year`) need localizable alternatives.
- Avoid constructing complex sentences from fragments unless localization-safe.
- Button labels and badges must handle long text without clipping.
- Section headers should allow two-line labels where needed.

Do not update localization files during the documentation-only prep step.

## 12. Files Likely To Touch In Phase 4

Likely allowed implementation files:

- `budgetmeter.ios/DesignSystem/Colors/BrandColors.swift`
- `budgetmeter.ios/DesignSystem/Colors/CategoryColors.swift`
- `budgetmeter.ios/DesignSystem/Typography/TextStyles.swift`
- `budgetmeter.ios/DesignSystem/Spacing/LayoutTokens.swift`
- `budgetmeter.ios/DesignSystem/Animations/AnimationCurves.swift`
- `budgetmeter.ios/DesignSystem/Components/Cards/*.swift`
- `budgetmeter.ios/DesignSystem/Components/Indicators/*.swift`
- `budgetmeter.ios/DesignSystem/Components/Charts/*.swift`
- `budgetmeter.ios/DesignSystem/Components/Rows/*.swift`
- `budgetmeter.ios/DesignSystem/Components/Sections/*.swift`
- selected Home files only if Phase 3 needs token adoption
- selected Income/Expense/Settings files only after shared tokens/components are stable
- `budgetmeter.ios/Resources/*.xcstrings` only when localization copy is intentionally added in an implementation step

## 13. Files Not Allowed To Touch In Phase 4

Do not touch:

- `budgetmeter.ios/BudgetMeter.xcdatamodeld/**`
- CoreData schema/model versions
- `budgetmeter.ios/CoreKit/Sources/Auth/**`
- Supabase/Auth files
- `budgetmeter.ios/Widgets/**`
- widget targets or App Group setup
- premium gates, StoreKit, paywall, or entitlement logic
- CloudKit setup/removal behavior
- `budgetmeter.ios/CoreKit/Sources/Persistence/PersistenceService.swift`
- calculation formulas or summary builder behavior
- Xcode project files
- app business logic or data migrations

## 14. Step-By-Step Phase 4 Implementation Sequence

1. Freeze the v1 token names and map old tokens to new semantic tokens.
2. Update color tokens only, preserving existing public names where possible.
3. Add typography aliases for pace, metric, section, caption, and badge use.
4. Add surface/radius/shadow/glass aliases without changing feature logic.
5. Audit and adjust `MomentumHeroCard` / `MomentumRingView` for Phase 3 needs.
6. Refine base cards and metric displays.
7. Refine row and section components.
8. Refine button variants and sheet/input surfaces.
9. Refine chart/status indicators.
10. Adopt updated components in Home first, then Income/Expenses, then Settings.
11. Run build and targeted visual/accessibility QA after each adoption step.

## 15. What To Postpone

- Full theme marketplace
- premium theme architecture changes
- app icon variants
- Pulsey variants
- Pulsey-heavy Home design
- full Settings redesign
- advanced charting/history visuals
- dashboard customization
- unlimited color editing
- broad localization rewrite
- Supabase/Auth screens
- widget visuals
- CloudKit or persistence changes

## 16. Build / Test Requirements

Minimum implementation checks:

- Build after token changes.
- Build after component changes.
- Build after each feature-screen adoption pass.
- Run relevant unit tests when component changes touch ViewModel-facing display formatting.
- Manual visual QA in dark mode first.
- Spot-check light mode only to ensure no unreadable regressions.
- Dynamic Type spot checks: Large, Accessibility Large.
- Reduce Motion spot check for animated cards/rings/charts.

Expected build command:

```sh
xcodebuild -project budgetmeter.ios.xcodeproj -scheme budgetmeter.ios -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' build
```

Use full tests when practical:

```sh
xcodebuild -project budgetmeter.ios.xcodeproj -scheme budgetmeter.ios -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' test
```

Known pre-existing warnings/test drift should be documented separately from Phase 4 regressions.

## 17. Success Criteria

Phase 4 is complete when:

- v1 semantic color tokens are defined and used by core components.
- Typography aliases cover pace, metrics, status, section headers, captions, and badges.
- Spacing/radius/surface/shadow rules are documented in code tokens.
- Momentum hero/ring components are ready for Phase 3 Home.
- Core cards, rows, buttons, indicators, and sheets have consistent dark-first styling.
- Financial states use color plus copy/icon support.
- Critical financial values remain readable on solid or near-solid surfaces.
- Dynamic Type does not break key Home, Income, Expense, or Settings surfaces.
- Build passes.
- Any remaining visual debt is documented and scoped to later phases.

## 18. Recommendation

Status: **Ready for implementation planning, not started.**

First safe implementation step:

Define v1 semantic tokens in the DesignSystem while preserving existing token names as compatibility aliases. This keeps Phase 4 low-risk and gives Phase 3 Home a stable visual contract before broader UI adoption.
