# Insights Screen UI/UX Audit (Current State)

Sources reviewed:
- `docs/uiux_design_direction_v1_decisions.md`
- `docs/uiux_design_system_v2_tokens.md`
- `docs/uiux_v2_implementation_plan.md`
- `budgetmeter.ios/Features/InsightsFeature/View/InsightsView.swift`
- `budgetmeter.ios/Features/InsightsFeature/ViewModel/InsightsViewModel.swift`
- Related chart views in `budgetmeter.ios/Features/InsightsFeature/View/Charts/`
- Screenshots:
  - `docs/uiux/screenshots/current/insgiht.1.light.png`
  - `docs/uiux/screenshots/current/insight.2.light.png`
  - `docs/uiux/screenshots/current/insight.before.premium.light.png`

## 1. Current Screen Summary

Insights screen currently has three visible UI states:

- **Standard insights overview (light):** top metric cards + chart sections below.
- **Deeper chart/list state (light):** spending breakdown list and month comparison card.
- **Premium-locked state (light):** centered premium upsell card with CTA.

The structure is feature-complete and understandable, but visual language feels closer to utility analytics than the target v2 premium glass-fintech expression.

## 2. What Works

- Clear sectioning: quick insight cards first, detailed charts afterward.
- Card-based composition is consistent with app architecture and reusable components.
- Premium gating logic is visible and understandable in locked state.
- Messaging intent in locked card is direct and action-oriented.
- Charts/list modules are modular (`SpendingBreakdownView`, `MonthComparisonView`, `BalanceTrendView`), good for incremental polish.
- Information hierarchy in data state is generally readable.

## 3. Problems

- Visual feel is still “functional dashboard” more than “premium glass-fintech.”
- Light-mode surfaces appear flat in places; depth hierarchy between cards and page background is limited.
- Premium locked card reads generic and static; lacks stronger premium personality.
- Mixed language/copy tone in screenshots (`Insights`, Turkish premium text) creates consistency drift.
- Top insight cards are useful but can feel cramped/compact versus calmer premium spacing goals.
- Data-empty conditions in charts look technically clear but emotionally dry.
- No Pulsey/emotional support layer in key empty/locked moments (could be optional, but currently no warmth).
- Only light screenshots are provided; dark-mode contrast and parity are not yet verified.

## 4. v2 Alignment Gap

Compared to v2 requirements, Insights is partially aligned:

- **Light/dark slate canvas:** light appears aligned; dark mode still unverified for this screen.
- **Medium glass surfaces:** some card styling exists, but premium glass consistency is not yet strong.
- **Pulsey usage:** not mandatory on every screen, but v2 allows supportive use in premium/empty states; currently absent.
- **Short human copy:** concise in parts, but tone remains product-functional rather than warm/supportive.
- **Premium but friendly feeling:** premium intent exists, emotional friendliness and polish are limited.
- **Screen consistency:** component structure matches system, yet final styling quality is below v2 target level.
- **Accessibility / Dynamic Type:** architecture seems adaptable, but explicit large text + chart accessibility validation is still needed.

## 5. Design Opportunities

Potential directions (documentation only):

- Strengthen card depth hierarchy (glass border/shadow/contrast tuning) to match v2 premium feel.
- Rebalance top insight cards with slightly calmer spacing and clearer headline/value rhythm.
- Upgrade premium-locked state from static box to more intentional premium education panel.
- Improve copy tone in insight summaries and lock state to be warmer and less mechanical.
- Introduce optional supportive visual element (Pulsey or equivalent soft accent) in locked/empty scenarios.
- Standardize language strategy (TR-first localized UI consistency).
- Optionally run Stitch concepts for:
  1) insights overview hierarchy,
  2) chart card treatment,
  3) premium lock panel variants.

## 6. Recommended Next Step

Recommended path: **Run Stitch exploration first, then implement a scoped Insights polish pass.**

Reason:
- Insights has multiple content states (data-rich, sparse, premium-locked), and visual consistency decisions are better validated quickly in concept phase.
- A concept-first step helps avoid fragmented UI updates across cards/charts/paywall state.

## 7. Questions / Decisions Needed

Before implementation, these should be decided:

1. Should Insights remain mostly utilitarian analytics, or move closer to Home-style premium visual richness?
2. In premium-locked state, do we want a compact inline lock card or a stronger hero-style premium panel?
3. Should Pulsey appear in Insights locked/empty states, or stay excluded for data focus?
4. Do we enforce Turkish-first localized labels in this pass?
5. Do we require dark-mode screenshots for all 3 states before implementation decisions?

---

### Readiness for Stitch Exploration

**Yes — Insights screen is ready for Stitch exploration.**

Rationale: Existing structure and modules are stable; primary gaps are visual hierarchy, premium expression, and tone consistency across states, which are ideal for concept-driven refinement before implementation.
