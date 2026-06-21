# UI/UX Transformation Master Plan

## 1. Purpose

This document is the master transformation plan for applying BudgetMeter's new UI/UX direction to the existing iOS app screens.

This is not a visual inspiration document. It is an implementation handoff plan for Cursor/Codex. It explains how to translate approved design direction, Google Stitch references, and existing SwiftUI screens into a consistent production UI without rewriting the app blindly.

The goal is to guide safe, incremental transformation:

- use the current SwiftUI app as the implementation base
- preserve existing app logic and navigation
- introduce shared components before screen-by-screen polish
- keep diffs reviewable
- avoid unrelated refactors
- align every screen with `DESIGN.md`

## 2. Product Positioning

BudgetMeter is a money pace app.

It answers:

> Am I moving forward or slowing down today?

BudgetMeter helps users understand daily financial direction through income, expenses, savings, pace, and calm financial awareness. It should make money feel understandable without becoming a dense finance product.

BudgetMeter is NOT:

- a payment app
- a banking app
- a crypto app
- a wallet app
- an accounting ledger
- a dense analytics dashboard

Any transformation that makes BudgetMeter look like a bank, payment wallet, trading app, accounting system, or dashboard-heavy analytics product is outside the design direction.

## 3. Transformation Strategy

The transformation strategy is:

- Stitch outputs are visual references only.
- Existing SwiftUI screens are the implementation base.
- `DESIGN.md` is the source of truth for product positioning, tokens, tone, screen intent, widget rules, Pulsey rules, and generation constraints.
- Shared components should be created or standardized before screen-by-screen redesign.
- Screens should be transformed gradually, not rewritten blindly.
- Each screen transformation should preserve existing data flow, navigation, persistence, auth flow, premium gating, and accessibility behavior where possible.
- Cursor/Codex should work in focused phases with narrow file scope and explicit acceptance criteria.

The correct workflow is:

1. Audit existing tokens and screen structure.
2. Standardize shared components.
3. Transform one screen or feature area at a time.
4. Validate light mode, dark mode, Dynamic Type, VoiceOver, and currency display.
5. Move to the next screen only after the current screen is coherent.

## 4. Global Design Principles

All transformed screens must follow these principles:

- premium calm fintech
- simple before decorative
- data before decoration
- financial clarity first
- no visual noise
- no fake banking/payment UI
- no dense dashboards
- light/dark mode parity
- accessibility must remain intact
- color is accent, not background chaos
- glass is subtle and readable
- every screen should be understandable in 3 seconds
- Pulsey supports emotion but must not compete with financial data

## 5. Shared Component System

Shared components should be created or standardized before broad screen polish. These names are design handoff names; implementation may map them to existing SwiftUI component names when appropriate.

### AppBackground

- **Purpose:** Provides the stable app canvas for every screen.
- **Used in:** All full-screen views, scroll containers, widgets where applicable.
- **Design rules:** Use `background.main.light #F8FAFC` and `background.main.dark #0F172A`. Never theme-dependent. Never pure black.

### BudgetHeaderGlassCard

- **Purpose:** Reusable top-of-screen glass header for important screen context.
- **Used in:** Welcome, Home, Insights summaries, paywall header, optional Settings account header.
- **Design rules:** Medium glass, 20pt radius, 16pt padding, subtle border, no busy decoration, strong title hierarchy.

### SummaryHeroCard

- **Purpose:** Highlights the most important summary value on a screen.
- **Used in:** Income summary, Expense summary, Insights overview, savings summary.
- **Design rules:** One primary number, one concise label, optional secondary metric. Financial number uses SF Pro Rounded.

### MoneyPaceHeroCard

- **Purpose:** Answers the core Home question: "Am I moving forward or slowing down today?"
- **Used in:** Home primary hero area.
- **Design rules:** Daily pace is the hero. Use sign, text, and color. Do not place Pulsey on top of or inside the primary metric area.

### MetricCard

- **Purpose:** Displays a compact supporting metric.
- **Used in:** Home secondary metrics, Income/Expense totals, Insights quick stats, Settings premium status if needed.
- **Design rules:** Small repeated card, consistent padding/radius, one value and one label, no decorative overload.

### FinanceListRow

- **Purpose:** Standard row for income/expense categories, recurring items, and financial list entries.
- **Used in:** Income, Expense, recurring/subscription areas.
- **Design rules:** Fast scanning, clear label, dynamic currency, optional icon/category marker, enough tap target height, no mascot.

### SectionHeader

- **Purpose:** Introduces grouped content.
- **Used in:** Every screen with sections.
- **Design rules:** Short label, optional small subtitle/action, consistent spacing, no oversized typography.

### PrimaryCTAButton

- **Purpose:** Main action on a screen.
- **Used in:** Auth, onboarding, empty states, paywall, add flows.
- **Design rules:** Theme accent fill, 52pt height, 14pt radius, clear verb, strong contrast.

### SecondaryCTAButton

- **Purpose:** Secondary or lower-priority action.
- **Used in:** Auth alternate actions, onboarding skip, paywall restore, empty states.
- **Design rules:** Calm styling, clear label, no competing visual weight with primary CTA.

### StatusBadge

- **Purpose:** Shows small financial or system status.
- **Used in:** Home pace status, Insights status, premium state, settings rows where useful.
- **Design rules:** Status cannot rely on color only. Pair icon/text/color. Keep compact.

### PremiumBadge

- **Purpose:** Indicates premium-only access or premium state.
- **Used in:** Premium theme cards, widgets setup, locked sections, paywall previews.
- **Design rules:** Subtle, not aggressive. Should explain premium status without pressure.

### EmptyStateCard

- **Purpose:** Gives supportive guidance when no data exists.
- **Used in:** Home first-run empty state, Income/Expense empty groups, Insights no-data state.
- **Design rules:** Warm copy, one clear action, optional Pulsey if the context is emotionally supportive. No shame.

### ChartCard

- **Purpose:** Wraps charts in a consistent readable surface.
- **Used in:** Insights charts and any future trend views.
- **Design rules:** No chart chaos. Chart must explain one idea. Use labels, accessible descriptions, and restrained colors.

### BudgetBottomTabBar

- **Purpose:** Represents the app's main navigation treatment when custom tab styling is needed.
- **Used in:** Main app shell if a custom tab treatment is explicitly approved.
- **Design rules:** Preserve existing navigation structure unless explicitly requested. Do not invent new tabs. Selected state may use theme accent.

### WidgetMetricCard

- **Purpose:** Defines the visual unit for WidgetKit daily pace layouts.
- **Used in:** Small and medium widgets.
- **Design rules:** Neutral background, one hero number, selected currency, status via text/icon/small indicator only. No full green/red backgrounds.

## 6. Screen Transformation Documents

Create future per-screen transformation documents only when requested. Do not create them as part of this master plan.

Future documents:

- `docs/transformations/auth_transformation.md`
- `docs/transformations/home_transformation.md`
- `docs/transformations/income_transformation.md`
- `docs/transformations/expense_transformation.md`
- `docs/transformations/insights_transformation.md`
- `docs/transformations/settings_transformation.md`
- `docs/transformations/paywall_transformation.md`
- `docs/transformations/widget_transformation.md`

Each screen document should include:

- current problems
- target layout hierarchy
- reusable components
- token usage
- interaction rules
- what must change
- what must not change
- acceptance checklist

Each screen document should be implementation-oriented, not moodboard-oriented.

## 7. Screen Priority Order

Use this implementation order:

1. Design tokens audit
2. Shared components
3. Welcome / Sign In / Register
4. Home
5. Income and Expense using one shared structure
6. Insights
7. Settings
8. Paywall
9. Widget
10. Accessibility QA

Do not start with broad screen polish before the token/component audit is complete. Do not polish all screens in one prompt.

## 8. Income and Expense Alignment Rule

Income and Expense must use the same layout system.

Income visual structure should be the base. Expense should reuse the same structure with expense-specific labels, red/coral accent, and expense data.

Rules:

- Same section rhythm.
- Same row structure.
- Same card system.
- Same add/edit interaction pattern where possible.
- Same empty-state structure.
- Different labels, content, and status color only where semantically needed.
- Income uses positive/income treatment.
- Expense uses expense/coral negative treatment.

Do not allow Income and Expense to drift into two different products.

## 9. Widget Rule

The Stitch widget output should not be used as production direction.

Widget should be redesigned directly in SwiftUI WidgetKit.

Small and Medium widget layouts should be built separately. Do not stretch one layout blindly into another size.

Widget must be:

- simple
- neutral
- glanceable
- WidgetKit-native
- focused on one hero metric: daily money pace
- dynamic-currency aware

Widget must not:

- use full green/red backgrounds
- show dense charts by default
- use Pulsey on the live widget surface
- look like a payment card, wallet, bank balance widget, crypto widget, or trading widget

## 10. Pulsey Rule

Pulsey is an emotional support layer, not a core data component.

Pulsey may appear in:

- Welcome
- onboarding
- empty states
- success moments
- paywall hero/header

Pulsey must not appear in:

- primary financial metric areas
- transaction lists
- charts
- widget live surface
- every card
- settings main list

Pulsey should make the experience warmer without reducing financial clarity. If Pulsey placement competes with a number, chart, or fast-entry task, remove Pulsey from that context.

## 11. Implementation Safety Rules

Strict implementation rules:

- no unrelated refactors
- no business logic changes
- no currency hardcoding
- no fake data model changes unless requested
- preserve existing navigation
- preserve existing authentication flow
- preserve existing persistence/data flow
- preserve accessibility labels where possible
- use existing `DesignSystem` tokens whenever available
- do not rename files unless explicitly requested
- do not modify Core Data schema unless explicitly requested
- do not modify StoreKit/subscription entitlement logic
- do not modify networking/sync behavior
- do not modify calculation engine behavior
- do not introduce payment/banking/crypto/wallet concepts
- do not generate production code from Stitch without adapting it to the existing SwiftUI architecture

Each implementation prompt should define:

- exact files allowed
- exact files forbidden
- target components
- acceptance criteria
- manual QA checklist
- rollback scope

## 12. Acceptance Checklist

Before considering the transformation complete, verify:

- [ ] all screens feel like the same app
- [ ] light and dark mode both work
- [ ] currency is dynamic
- [ ] cards use shared components
- [ ] Income and Expense are visually aligned
- [ ] Widget is simple and WidgetKit-native
- [ ] no banking/payment/crypto/wallet UI was introduced
- [ ] typography follows `DESIGN.md`
- [ ] spacing follows `DESIGN.md`
- [ ] radius follows `DESIGN.md`
- [ ] colors follow `DESIGN.md`
- [ ] Pulsey appears only in approved contexts
- [ ] primary financial metrics remain clear and readable
- [ ] accessibility labels and Dynamic Type behavior are preserved or improved
- [ ] no unrelated app logic changed during visual transformation

## Related Source Documents

- `DESIGN.md`
- `docs/uiux_design_direction_v1_decisions.md`
- `docs/uiux_design_system_v2_tokens.md`
- `docs/uiux_v2_implementation_plan.md`
