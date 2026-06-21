# Income Screen UI/UX Audit (Current State)

Sources reviewed:
- `docs/uiux_design_direction_v1_decisions.md`
- `docs/uiux_design_system_v2_tokens.md`
- `docs/uiux_v2_implementation_plan.md`
- `budgetmeter.ios/Features/IncomesFeature/View/IncomeView.swift`
- `budgetmeter.ios/Features/IncomesFeature/ViewModel/IncomeViewModel.swift`
- Screenshots:
  - `docs/uiux/screenshots/current/income.light.png`
  - `docs/uiux/screenshots/current/income.dark.png`

## 1. Current Screen Summary

Current Income screen structure is clear and modular:

- Large monthly summary hero card at top (`FinancialSummaryCard`)
- Collapsible income sections (Daily, Monthly, Yearly, One-Time)
- Row-based category list with edit icons and add-item row
- Light and dark variants exist and overall hierarchy remains consistent across modes

Visual flow is list-centric and practical, with strongest emphasis on the summary card and Daily section.

## 2. What Works

- Information architecture is strong and task-oriented (summary first, then section-based entry).
- Collapsible sections reduce overload and support progressive disclosure.
- Light/dark parity is better here than Welcome/Home (both screenshots available for same screen).
- Green income accent usage communicates positive flow quickly.
- Row components are consistent and readable; edit affordances are visible.
- Premium indicator in light mode (`PREMIUM` chip in add row) is understandable and non-disruptive.

## 3. Problems

- Glass-fintech premium feel is present but still somewhat flat in multiple blocks (especially list container surfaces).
- Hero card and section containers feel visually close to “clean utility list” rather than richer premium financial cockpit.
- Accent intensity in dark mode is high in places; can drift toward busy instead of calm premium.
- Copy language mix is inconsistent (`Income` labels mostly English while app context is Turkish in screenshot title `Gelir`).
- CTA/add rows are functional but personality is limited; no emotional support layer (Pulsey not used, which may be acceptable but reduces warmth).
- Vertical rhythm is efficient but slightly rigid; sections can feel mechanically stacked.
- Typography hierarchy for secondary metadata (`₺1.3K/DAY`, `₺475K/YEAR`, sources) is legible but could be refined for calmer premium tone.

## 4. v2 Alignment Gap

Compared to v2 requirements, Income is moderately aligned with clear improvement opportunities:

- **Light/dark slate canvas:** aligned in principle; both variants exist and are coherent.
- **Glass surfaces:** partially aligned; medium-glass premium depth could be more consistent.
- **Pulsey usage:** not required for every screen, so absence is acceptable; still no emotional warmth layer on this path.
- **Short human copy:** mostly concise, but localization/copy consistency needs polish.
- **Premium but friendly feeling:** functionally strong, emotionally cooler than target tone.
- **Screen consistency:** generally follows shared component system, but visual richness differs from desired v2 polish level.
- **Accessibility / Dynamic Type:** row layout likely resilient, but explicit large-text and contrast QA still needed.

## 5. Design Opportunities

Potential directions (documentation only):

- Increase perceived premium quality of hero + section containers via more refined glass treatment consistency.
- Soften and unify section separators/dividers to reduce “form-like” feel.
- Tighten typography hierarchy for summary metadata and section subtitles.
- Harmonize localized copy language (Turkish-first or fully localized consistent strategy).
- Add subtle warmth through microcopy and supporting accents without adding visual noise.
- Revisit add-row emphasis strategy so primary input actions feel modern and intentional.
- Optionally run Stitch concept pass to compare “utility-first” vs “premium-glass” variants before coding.

## 6. Recommended Next Step

Recommended path: **Direct SwiftUI polish is feasible, but a quick Stitch comparison (2 variants) is still beneficial before implementation.**

Reason:
- Income screen already has strong structural clarity; this is mostly a visual-finishing problem.
- A brief concept pass can quickly validate how far to push premium/glass treatment without harming readability.
- Then implementation can remain tightly scoped to Income feature files only.

## 7. Questions / Decisions Needed

Before implementation, these should be decided:

1. Localization priority: should Income copy be fully Turkish in this pass, or handled in a later localization pass?
2. Should Income remain mostly utilitarian, or should it move closer to Home’s richer premium expression?
3. Add-row emphasis: keep current simple rows, or elevate primary “add income” interactions visually?
4. In dark mode, should green accent intensity be softened for calmer premium balance?
5. Should Pulsey remain absent on Income (data-entry flow), as a strict focus decision?

---

### Readiness for Stitch Exploration

**Yes — Income screen is ready for Stitch exploration.**

Rationale: Core layout is already stable; remaining gaps are visual tone, glass depth consistency, and hierarchy polish, which are ideal for concept-first validation.
