# Shared Components Transformation

## 1. Purpose

This document defines the reusable UI components that should be standardized before any screen-specific redesign is implemented.

It is an implementation handoff document for Cursor/Codex. It does not implement SwiftUI code. It describes the shared component layer needed to transform BudgetMeter's existing screens into the new UI/UX direction without creating one-off card, button, row, or layout styles on each screen.

The goal is to make future screen transformation work safer, faster, and more consistent.

## 2. Component Strategy

Shared components should come before screen polish.

Screens should not each create their own card, list, header, button, badge, or chart styling. If multiple screens need the same visual behavior, the behavior should live in a shared component or shared modifier that uses BudgetMeter's existing `DesignSystem` tokens.

Component rules:

- Shared components must use `DesignSystem` tokens.
- Shared components must preserve existing app logic.
- Shared components must not own financial calculations, persistence, authentication, subscriptions, networking, or navigation decisions.
- Shared components should support light mode and dark mode equally.
- Shared components should support Dynamic Type.
- Shared components should preserve or improve accessibility labels, traits, hints, and grouping.
- Shared components should reduce visual drift between screens.

The app should feel like one product. Home, Income, Expense, Insights, Settings, Paywall, Auth, and Widgets should not look like separate design systems.

### Reuse-First Implementation Principles

Before creating new shared components, follow these rules:

1. Do not delete and rewrite existing components.
2. First inspect the current SwiftUI `DesignSystem` components.
3. Reuse existing components whenever possible.
4. Prefer wrapping existing components over creating duplicate new ones.
5. Prefer standardizing existing APIs/styles over renaming files or replacing components.
6. Only create a new component when no suitable existing component exists.
7. Do not rename existing components unless explicitly approved.
8. Keep each implementation phase small and reviewable.

### Handoff Name to Existing Candidate Mapping

Use this table during pre-phase inspection. Handoff names are design targets; existing Swift files are the first place to look before writing new code.

| Handoff name | Existing candidate to inspect first |
|---|---|
| AppBackground | `Color.appBackground` / `surfaceObsidian` usage in feature views |
| GlassCard | `glassSurface()` in `DesignSystem/Components/Surfaces/GlassSurface.swift`, `surfaceCard()` in `DesignSystem/Spacing/LayoutTokens.swift` |
| SectionHeader | `DesignSystem/Components/Sections/FinancialSection.swift` |
| BudgetHeader | `DesignSystem/Components/Cards/GreetingHeader.swift` |
| FinanceListRow | `DesignSystem/Components/Rows/FinancialRowView.swift` |
| MoneyPaceHeroCard | `DesignSystem/Components/Cards/MomentumHeroCard.swift` |
| SummaryHeroCard | `MonthSummaryCard.swift`, `HeroNetFlowCard.swift` |
| MetricCard | `CompactIntervalCard.swift`, `IntervalMetricCard.swift` |
| EmptyStateCard | `DesignSystem/Components/Rows/EmptyStateRow.swift` |
| ChartCard | `MiniBarChart.swift` + Insights chart wrappers |
| WidgetMetricCard | `WidgetShared/WidgetDesignTokens.swift` (handoff only; WidgetKit-native implementation) |

Do not start broad screen polish until Phases 1–5 are complete or each handoff name is mapped to a reuse/wrap/create decision.

## 3. Core Shared Components

### AppBackground

- **Purpose:** Provides the stable root canvas for app screens.
- **Used in screens:** Auth, Home, Income, Expense, Insights, Settings, Paywall, onboarding, empty states.
- **Visual rules:** Use `background.main.light #F8FAFC` and `background.main.dark #0F172A`. Never theme-dependent. Never pure black. Should extend under scroll views and safe areas where appropriate.
- **Data rules:** No data dependency. No business logic.
- **Accessibility rules:** Must not interfere with VoiceOver focus. Must preserve readable contrast for foreground content.
- **Do not rules:** Do not add decorative gradients, payment-card styling, banking-style backgrounds, or theme-colored full-screen fills.

### BudgetHeader

- **Purpose:** Provides a consistent screen header pattern for identity, title, subtitle, and optional supportive visual.
- **Used in screens:** Welcome, Sign In/Register, Home, Insights, Paywall, onboarding.
- **Visual rules:** Clear title hierarchy, short subtitle, calm spacing, optional glass treatment where useful. Pulsey may appear only in approved contexts.
- **Data rules:** Displays already-prepared title/subtitle/status values only. Does not calculate financial values.
- **Accessibility rules:** Header title should be readable as a heading. Decorative icons/Pulsey should be hidden from VoiceOver unless they communicate meaning.
- **Do not rules:** Do not turn headers into marketing hero pages on utility screens. Do not place Pulsey in primary financial metric areas.

### GlassCard

- **Purpose:** Standard readable glass/elevated card surface.
- **Used in screens:** Home cards, Income/Expense sections, Insights cards, Settings groups, Paywall panels, empty states.
- **Visual rules:** Medium-strength glass, 20pt card radius, 16pt padding, 12pt internal gap, subtle border, soft shadow, Reduce Transparency fallback to elevated surface.
- **Data rules:** Pure container. Does not own data loading or business state.
- **Accessibility rules:** Must preserve text contrast. Should not group children unless the consuming screen needs grouped accessibility.
- **Do not rules:** Do not use heavy blur, neon glow, extreme translucency, or low-contrast text. Do not nest cards inside cards unless there is a real structural need.

### SummaryHeroCard

- **Purpose:** Shows one important summary value and a small amount of context.
- **Used in screens:** Income summary, Expense summary, Insights overview, savings summaries, paywall value previews if needed.
- **Visual rules:** One primary financial number, one label, optional one or two supporting values. Financial number uses SF Pro Rounded and stable digit rhythm.
- **Data rules:** Receives formatted display values or simple display props. Does not calculate totals.
- **Accessibility rules:** VoiceOver label should read the summary clearly, including currency and status where applicable.
- **Do not rules:** Do not cram multiple charts, tables, or dense analytics into the hero card. Do not use body text in SF Pro Rounded.

### MoneyPaceHeroCard

- **Purpose:** Answers BudgetMeter's core product question: "Am I moving forward or slowing down today?"
- **Used in screens:** Home primary hero area.
- **Visual rules:** Daily money pace is the visual hero. Use signed value, short status copy, icon/status signal, and calm supporting context. Positive/negative meaning must not rely on color only.
- **Data rules:** Receives already-calculated pace values and formatted currency strings. Does not change calculation behavior.
- **Accessibility rules:** VoiceOver must read daily pace, direction, and supporting status in one useful phrase.
- **Do not rules:** Do not place Pulsey on top of or inside the primary financial metric area. Do not add chart chaos or generic dashboard widgets to this card.

### MetricCard

- **Purpose:** Displays a compact supporting metric.
- **Used in screens:** Home metric grid, Income/Expense subtotals, Insights stats, Settings premium/account summaries.
- **Visual rules:** Compact card, one value, one label, optional tiny trend/status indicator. Use consistent card radius, padding, typography, and spacing.
- **Data rules:** Receives display-ready values. Does not format currency unless explicitly designed to use the shared currency display helper.
- **Accessibility rules:** Each card should expose a clear label/value pair.
- **Do not rules:** Do not create one-off metric card styles per screen. Do not use loud gradients or full-card status fills.

### FinanceListRow

- **Purpose:** Standard row for financial entries and categories.
- **Used in screens:** Income, Expense, recurring income/expense sections, subscription/bill rows where compatible.
- **Visual rules:** Clear label, amount, optional category/icon, optional frequency/status, comfortable tap target, consistent row spacing.
- **Data rules:** Uses provided category, label, amount, status, and action props. Does not mutate data directly except through existing callbacks.
- **Accessibility rules:** Row should read as a coherent item. Edit/delete/add actions need clear labels and traits.
- **Do not rules:** Do not add Pulsey, dense charts, or decorative visuals to rows. Do not hardcode currency symbols.

### SectionHeader

- **Purpose:** Introduces grouped content and optional section action.
- **Used in screens:** All sectioned screens: Home, Income, Expense, Insights, Settings, Paywall.
- **Visual rules:** Short section title, optional subtitle or trailing action, consistent spacing. Typography should be strong but not hero-sized.
- **Data rules:** Text-only or simple action. No business logic.
- **Accessibility rules:** Use heading-like semantics where appropriate. Trailing action must be reachable and labeled.
- **Do not rules:** Do not make section headers visually louder than primary financial values.

### PrimaryCTAButton

- **Purpose:** Main action on a screen or card.
- **Used in screens:** Auth, onboarding, empty states, add flows, paywall, settings actions where primary.
- **Visual rules:** Theme accent fill, strong contrast, 52pt height, 14pt radius, clear action text, optional leading icon.
- **Data rules:** Calls existing action closures only. Does not own navigation or persistence logic.
- **Accessibility rules:** Must expose button label and disabled/loading state where relevant.
- **Do not rules:** Do not use unclear labels, multiple competing primary buttons, or status colors as decorative full backgrounds.

### SecondaryCTAButton

- **Purpose:** Secondary action that supports but does not compete with the primary action.
- **Used in screens:** Auth alternate actions, onboarding skip, paywall restore, settings secondary actions, empty states.
- **Visual rules:** Lower visual weight than primary button. May use outline, text, or subtle elevated treatment.
- **Data rules:** Calls existing action closures only.
- **Accessibility rules:** Must remain reachable and clearly labeled.
- **Do not rules:** Do not style secondary actions so strongly that hierarchy becomes unclear.

### StatusBadge

- **Purpose:** Shows compact status such as positive pace, slowing down, neutral, active, inactive, or warning.
- **Used in screens:** Home, Insights, Income/Expense section summaries, Settings rows, Paywall feature states.
- **Visual rules:** Small, readable, icon/text/color combination. Use `status.positive`, `status.positive.calm`, `status.negative`, or neutral slate tokens as appropriate.
- **Data rules:** Receives status enum/string from existing view models. Does not calculate status.
- **Accessibility rules:** Badge meaning must be in text, not color alone.
- **Do not rules:** Do not use color-only dots as the only status signal.

### PremiumBadge

- **Purpose:** Indicates premium-only access or premium active state.
- **Used in screens:** Premium theme cards, locked feature rows, widgets setup, Insights gates, Paywall previews.
- **Visual rules:** Subtle premium indicator. May use theme accent or restrained gold/caution token, but should not feel pushy.
- **Data rules:** Reads existing premium/access state from caller. Does not check StoreKit or mutate entitlement logic.
- **Accessibility rules:** VoiceOver should communicate "Premium" or "Premium required" clearly.
- **Do not rules:** Do not create aggressive paywall pressure. Do not alter subscription logic.

### EmptyStateCard

- **Purpose:** Provides helpful next-step guidance when content is missing.
- **Used in screens:** Home first-run state, Income/Expense empty categories, Insights no-data state, onboarding-adjacent states.
- **Visual rules:** Warm short copy, one clear action, optional Pulsey in approved supportive contexts, glass/elevated surface.
- **Data rules:** Receives empty-state copy and action. Does not seed or mutate data.
- **Accessibility rules:** Message and CTA should read clearly as one state. Decorative Pulsey should be hidden unless meaningful.
- **Do not rules:** Do not shame users. Do not show technical errors. Do not overuse Pulsey.

### ChartCard

- **Purpose:** Wraps charts in a consistent readable card.
- **Used in screens:** Insights charts, trend summaries, recap views.
- **Visual rules:** One chart idea per card, clear title, optional compact legend, restrained colors, readable labels.
- **Data rules:** Receives chart-ready data from existing view models. Does not calculate financial history.
- **Accessibility rules:** Must provide meaningful chart summary labels. Color cannot be the only indicator.
- **Do not rules:** Do not create chart chaos, dense analytics dashboards, or unlabeled visual-only charts.

### BudgetBottomTabBar

- **Purpose:** Defines a consistent main navigation treatment if a custom tab bar is approved.
- **Used in screens:** Main app shell only.
- **Visual rules:** Calm, native, clear selected state, theme accent only for selected/accent treatment.
- **Data rules:** Uses existing selected-tab/navigation state. Does not create new navigation destinations.
- **Accessibility rules:** Each tab must have a clear label and selected state.
- **Do not rules:** Do not change app information architecture unless explicitly requested. Do not invent payment/banking tabs.

### WidgetMetricCard

- **Purpose:** Design handoff concept for the widget's main daily pace metric.
- **Used in screens:** Widget transformation planning for small and medium WidgetKit layouts.
- **Visual rules:** Neutral background, one hero value, selected currency, tiny status indicator, minimal label, WidgetKit-native spacing.
- **Data rules:** Uses widget snapshot data and shared currency display contract. Does not calculate app financial values in the widget view.
- **Accessibility rules:** Widget main value should have a clear accessibility label with direction and amount.
- **Do not rules:** Do not reuse heavy in-app cards blindly. Do not use full green/red backgrounds. Do not place Pulsey on the live widget surface.

## 4. Token Usage Rules

Shared components must use `DESIGN.md` and the v2 token documents as the source of truth. Do not invent new token systems.

### Background Colors

- Use `background.main.light #F8FAFC`.
- Use `background.main.dark #0F172A`.
- Backgrounds are not theme-dependent.

### Elevated Surface Colors

- Use `surface.elevated.light #FFFFFF`.
- Use `surface.elevated.dark #1E293B`.
- Use these for opaque fallback and elevated surfaces.

### Text Colors

- Use `text.primary` for primary labels and important values.
- Use `text.secondary` for supporting labels.
- Use `text.tertiary` for hints and disabled-adjacent copy.
- Text colors are not theme-dependent.

### Accent Colors

- Coral Default `#FF5A5F` is the free/default brand accent.
- Premium theme accents are accent-only.
- Accent may affect CTA fill, selected state, progress, chart primary series, mascot tint, glow/accent highlights, and optional widget accent.

### Status Colors

- Positive: `#00C853`.
- Calm positive: `#00BFA5`.
- Negative: `#FF5A5F`.
- Alternative red: `#EA4335`.
- Neutral: slate/gray system token.
- Status must not be color-only.

### Spacing

- Screen horizontal: 16.
- Dashboard horizontal: 20 when needed.
- Section gap: 20.
- Card padding: 16.
- Card gap: 12.
- Row height: 48.
- Button height: 52.
- Modal padding: 24.
- Widget padding: 16.

### Radius

- Card radius: 20.
- Button radius: 14.
- Modal radius: 24.
- Widget radius: 22.

### Typography

- Financial numbers use SF Pro Rounded.
- Normal UI text uses SF Pro/system default.
- Financial numbers should use stable digit rhythm.
- Support Dynamic Type and avoid clipping.

### Glass Treatment

- Use medium-strength glass.
- Use subtle border and soft shadow.
- Use opaque fallback for Reduce Transparency.
- Do not use heavy blur, neon glow, or unreadable translucency.

## 5. 5-Phase Implementation Strategy

Shared component work is split into five small, reviewable phases. Complete and approve each phase before starting the next. Do not implement all phases in one pass.

The previous flat 1–13 component order is superseded by this phased plan. Component priority is now expressed through Phases 2–5 below.

### 5.1 Pre-Phase Inspection Rule

Before **every** implementation phase, Cursor/Composer must output:

- A list of existing candidate components and files (use the mapping table in §2).
- A decision per component: **reuse**, **wrap**, **standardize**, or **create new**.
- An explicit list of files and areas that will **not** be touched.

No Swift implementation work may begin until this inspection is documented for the current phase.

### 5.2 Implementation Boundaries

**This document**

- This markdown file does not modify Swift code or Xcode project files.
- It defines handoff rules and phase scope only.

**Xcode and new Swift files**

- Later implementation phases may add new files under `DesignSystem/Components/`.
- Those files may require adding target membership in `budgetmeter.ios.xcodeproj`. That is an implementation-phase task, not a documentation task.
- Each phase that adds files must report target membership changes explicitly in its completion summary.

**WidgetDesignTokens**

- `budgetmeter.ios/WidgetShared/WidgetDesignTokens.swift` lives in a separate widget target context.
- Do **not** merge widget tokens into app `BrandColors` unless target/shared-framework boundaries are verified first.
- Phase 1 may align token **values** conceptually. Cross-target unification is a separate, explicitly scoped task.

**Token fixes vs shared components**

- Phase 1 (token gap fixes) must complete and be approved before any shared component Swift work (Phases 2–5).
- Shared components must be implemented in small batches—one phase at a time—not all at once.

### Phase 1 — Token Gap Fixes Only

| | |
|---|---|
| **Scope** | Token files only |
| **Goal** | Close small gaps in colors, status, text, and glass-related token constants |
| **Allowed files** | `DesignSystem/Colors/BrandColors.swift`, `DesignSystem/Typography/TextStyles.swift`, `DesignSystem/Spacing/LayoutTokens.swift` (glass token constants only if needed) |
| **Example goals** | Add `financialPositiveCalm` (`#00BFA5`), align `textTertiary`, optional `statusNegativeAlt` (`#EA4335`), document WCAG light-mode coral/green where intentional |
| **Forbidden** | Screen changes, shared component creation, feature views, `ThemeManager`, widgets, Core Data, auth, StoreKit |
| **Xcode** | Avoid project file changes in this phase |
| **Gate** | Build + test. Stop after Phase 1. Wait for approval before Phase 2 |

### Phase 2 — Foundation Components

| | |
|---|---|
| **Scope** | Inspect and reuse/wrap existing background, glass, and section header patterns |
| **Components** | AppBackground, GlassCard, SectionHeader |
| **Approach** | Prefer wrapping existing `glassSurface()` / `surfaceCard()` and `Color.appBackground` patterns instead of replacing underlying modifiers |
| **Allowed files** | New files under `DesignSystem/Components/` (Layout, Surfaces, Headers) plus minimal edits to existing surface modifiers if standardization is required |
| **Forbidden** | Screen rewrites, button/badge/card work, auth/paywall/navigation changes |
| **Gate** | Build + test. Report target membership if new files added. Stop after Phase 2. Wait for approval before Phase 3 |

### Phase 3 — Button + Badge Components

| | |
|---|---|
| **Scope** | Primary/secondary CTA and status/premium badge patterns |
| **Components** | PrimaryCTAButton, SecondaryCTAButton, StatusBadge, PremiumBadge |
| **Approach** | Reuse existing button and badge patterns in feature views if present; wrap or standardize rather than duplicate |
| **Allowed files** | New files under `DesignSystem/Components/Buttons/` and `DesignSystem/Components/Badges/` (or equivalent) |
| **Forbidden** | Purchase, auth, navigation, entitlement, or StoreKit logic changes |
| **Gate** | Build + test. Stop after Phase 3. Wait for approval before Phase 4 |

### Phase 4 — Card + Row Components

| | |
|---|---|
| **Scope** | Summary, metric, list row, and empty-state card patterns |
| **Components** | MetricCard, SummaryHeroCard, FinanceListRow, EmptyStateCard |
| **Reuse candidates** | `FinancialRowView`, `FinancialSection`, `MonthSummaryCard`, `HealthScoreCard`, `PremiumUpgradeBanner` |
| **Approach** | Do not delete existing cards. Wrap or standardize APIs where suitable |
| **Allowed files** | New files under `DesignSystem/Components/Cards/` and `DesignSystem/Components/Rows/` plus targeted edits to listed reuse candidates |
| **Forbidden** | Home, Income, or Expense screen rewrites; deletion of existing card/row components |
| **Gate** | Build + test. Stop after Phase 4. Wait for approval before Phase 5 |

### Phase 5 — Specialized Components

| | |
|---|---|
| **Scope** | Screen headers, money-pace hero, chart wrappers, widget handoff concept |
| **Components** | BudgetHeader, MoneyPaceHeroCard, ChartCard, WidgetMetricCard (handoff) |
| **Reuse candidates** | `MomentumHeroCard`, `GreetingHeader`, `MiniBarChart`, Insights chart wrappers, `WidgetDesignTokens` concepts |
| **Approach** | Adapt existing specialized components; `WidgetMetricCard` remains a design handoff concept—the live widget must stay WidgetKit-native |
| **Allowed files** | New or updated files under `DesignSystem/Components/` for in-app components; widget handoff notes only unless a separate widget task is explicitly scoped |
| **Forbidden** | Blind reuse of full in-app cards inside WidgetKit; Pulsey on live widget surface |
| **Gate** | Build + test. Stop after Phase 5 before any screen transformation work |

Do not start broad screen polish until Phases 1–5 are complete or each handoff name has an approved reuse/wrap/create decision.

## 6. Screen Mapping

### Auth Screens

Use:

- AppBackground
- BudgetHeader
- GlassCard
- PrimaryCTAButton
- SecondaryCTAButton
- EmptyStateCard where needed

Auth screens should feel trustworthy, clear, and low friction.

### Home

Use:

- AppBackground
- BudgetHeader where appropriate
- MoneyPaceHeroCard
- MetricCard
- SummaryHeroCard where needed
- SectionHeader
- FinanceListRow for recent/secondary financial rows if present
- EmptyStateCard
- StatusBadge

Home must keep the daily money pace hero metric clear.

### Income

Use:

- AppBackground
- SummaryHeroCard
- SectionHeader
- GlassCard
- FinanceListRow
- MetricCard
- PrimaryCTAButton / SecondaryCTAButton
- EmptyStateCard
- StatusBadge

Income should establish the shared Income/Expense structure.

### Expense

Use the same structure as Income:

- AppBackground
- SummaryHeroCard
- SectionHeader
- GlassCard
- FinanceListRow
- MetricCard
- PrimaryCTAButton / SecondaryCTAButton
- EmptyStateCard
- StatusBadge

Only labels, accent color, and data type should differ from Income.

### Insights

Use:

- AppBackground
- BudgetHeader
- SummaryHeroCard
- MetricCard
- ChartCard
- SectionHeader
- EmptyStateCard
- StatusBadge

Insights should show simple trends, not chart chaos.

### Settings

Use:

- AppBackground
- SectionHeader
- GlassCard
- FinanceListRow-style settings row where appropriate
- PremiumBadge
- SecondaryCTAButton where needed

Settings should remain a clean control center. Pulsey should not appear on the main settings list.

### Paywall

Use:

- AppBackground
- BudgetHeader
- GlassCard
- SummaryHeroCard where useful
- PrimaryCTAButton
- SecondaryCTAButton
- PremiumBadge
- MetricCard for compact benefits if needed

Paywall may include Pulsey in the hero/header only. Purchase/restore logic must remain unchanged.

### Widget

Use the WidgetMetricCard handoff concept only.

Actual implementation must be native WidgetKit with separate small and medium layouts.

## 7. Income and Expense Shared Structure

Income and Expense must share:

- card layout
- section structure
- list row style
- add action treatment
- empty state pattern

Only these should differ:

- labels
- accent color
- data type
- income-specific or expense-specific copy

Income visual structure should be the base. Expense should reuse that structure with expense-specific labels, red/coral accent, and expense data.

Do not allow Income and Expense to drift into unrelated layouts.

## 8. Widget Component Rule

WidgetMetricCard is only a design handoff concept.

The actual widget must be implemented in WidgetKit with small and medium layouts. Small and medium should be designed separately, not produced by stretching one layout.

Do not reuse full in-app card components blindly inside WidgetKit if they make the widget heavy, unreadable, or non-native.

Widget must remain:

- simple
- neutral
- glanceable
- focused on one hero metric: daily money pace
- user-selected currency aware

Widget must not use full green/red backgrounds or Pulsey on the live widget surface.

## 9. Implementation Safety Rules

Strict rules:

- no business logic changes
- no navigation changes
- no persistence changes
- no auth changes
- no subscription logic changes
- no Core Data schema changes
- no currency hardcoding
- no unrelated refactors
- no fake banking/payment/wallet UI
- preserve accessibility where possible
- use existing `DesignSystem` tokens whenever available
- preserve existing data flow and callbacks
- preserve premium gating behavior
- do not delete existing `DesignSystem` components
- prefer wrap/reuse over duplicate component APIs
- complete pre-phase inspection (§5.1) before any Swift work in a phase
- complete Phase 1 token fixes before Phases 2–5 shared component work
- do not merge `WidgetDesignTokens` into app tokens without target boundary verification
- do not rename files or components unless explicitly approved
- do not create screen-specific transformation docs as part of shared component work
- implement one phase at a time; stop and wait for approval between phases

## 10. Acceptance Checklist

- [ ] Pre-phase inspection completed (reuse/wrap/standardize/create decisions documented).
- [ ] Phase scope stayed within allowed files for the current phase.
- [ ] No existing components deleted or renamed without approval.
- [ ] `WidgetDesignTokens` not merged without target boundary check.
- [ ] Components use shared tokens.
- [ ] Light mode works.
- [ ] Dark mode works.
- [ ] Dynamic Type is respected.
- [ ] VoiceOver labels are preserved or improved.
- [ ] Income and Expense can share the same component structure.
- [ ] Home hero metric remains clear.
- [ ] Widget remains simple and glanceable.
- [ ] No visual system drift exists between screens.
- [ ] No currency symbols are hardcoded.
- [ ] No fake banking/payment/wallet UI is introduced.
- [ ] No app logic, navigation, persistence, auth, subscription, or Core Data behavior changes are required by the component plan.

## Related Source Documents

- `DESIGN.md`
- `docs/uiux_transformation_master_plan.md`
- `docs/uiux_design_direction_v1_decisions.md`
- `docs/uiux_design_system_v2_tokens.md`
- `docs/uiux_v2_implementation_plan.md`
