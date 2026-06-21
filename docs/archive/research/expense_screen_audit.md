# Expense Screen UI/UX Audit (Current State)

Sources reviewed:
- `docs/uiux_design_direction_v1_decisions.md`
- `docs/uiux_design_system_v2_tokens.md`
- `docs/uiux_v2_implementation_plan.md`
- `budgetmeter.ios/Features/ExpensesFeature/View/ExpenseView.swift`
- `budgetmeter.ios/Features/ExpensesFeature/ViewModel/ExpenseViewModel.swift`
- Screenshots:
  - `docs/uiux/screenshots/current/expense.light.png`
  - `docs/uiux/screenshots/current/expense.dark.png`

## 1. Current Screen Summary

Expense screen uses a structured list layout with:

- top monthly summary hero card,
- collapsible sections (Daily, Monthly, Subscriptions, Yearly, One-Time),
- row-based category editing,
- premium-gated subscriptions block when feature is locked.

Visual hierarchy is practical and readable, but dark and light examples currently represent different section states, which makes direct parity comparison harder.

## 2. What Works

- Clear financial task flow: summary first, then frequency-based sections.
- Collapsible sections improve scanability for long expense lists.
- Premium gating for subscriptions is explicit and understandable.
- Row components are consistent and edit affordances are clear.
- Accent color strategy for expenses (red/coral family) is intuitive.
- Both light and dark variants exist and maintain usable contrast.

## 3. Problems

- v2 premium glass-fintech expression is still uneven; several blocks feel closer to standard utility cards.
- In dark screenshot, visual density is high; long monthly list can feel heavy and less calm than v2 target.
- In light screenshot, sections feel safer but somewhat flat; premium depth is limited.
- Hero card and list blocks are visually similar in weight, reducing hierarchy emphasis.
- Copy localization is mixed (`Daily Expenses`, `Premium required`, etc. in English while title is Turkish `Gider`).
- CTA/add-row treatment is functional but not very “premium-friendly”; mostly utilitarian.
- Emotional support layer (Pulsey) is absent here; acceptable for data-entry focus, but personality remains low.
- Screenshots represent different content conditions (empty-ish light vs populated dark), so mode consistency cannot be fully judged yet.

## 4. v2 Alignment Gap

Compared to v2 requirements, Expense is partially aligned:

- **Light/dark slate canvas:** generally aligned, but complete parity validation needs same-state captures.
- **Glass surfaces:** present in structure but depth consistency and premium polish are not fully uniform.
- **Pulsey usage:** not mandatory on every screen; absence is valid for focused data-entry workflow.
- **Short human copy:** labels are concise, but tone/localization consistency needs improvement.
- **Premium but friendly feeling:** functional clarity is strong; emotional warmth and premium finish can be improved.
- **Screen consistency:** structure matches shared system, yet final visual polish level differs from target v2 quality.
- **Accessibility / Dynamic Type:** row/list structure is promising, but explicit large-text QA remains necessary.

## 5. Design Opportunities

Potential directions (documentation only):

- Refine hero card emphasis so summary reads as stronger anchor than section containers.
- Calibrate dark-mode density (spacing, divider softness, section rhythm) for calmer premium feel.
- Improve light-mode surface depth so screen does not feel overly flat.
- Harmonize Turkish-first copy or full localization consistency across all section labels.
- Revisit add-row and premium chip visual treatment for cleaner hierarchy.
- Use subtle accent restraint to avoid overly aggressive red saturation in dense lists.
- Optionally run Stitch concepts focused on “high-density expense list calmness” and “premium utility balance.”

## 6. Recommended Next Step

Recommended path: **Quick Stitch exploration first (2 variants), then focused SwiftUI polish on Expense only.**

Reason:
- Expense has high content density and multiple section types; small visual changes can significantly affect perceived quality.
- Concept pass will help decide calm vs dense balance before implementation.
- Then implementation can stay safely scoped to Expense feature files.

## 7. Questions / Decisions Needed

Before implementation, these should be decided:

1. Should Expense prioritize compact density or calmer spacing in dark mode?
2. Localization pass now or later: should section titles/subtitles be fully Turkish in this phase?
3. For locked subscriptions, should premium prompt remain inline row style or move to a more explicit premium card style?
4. Should one-time/surprise expense wording be simplified for consistency with other sections?
5. Do we need matched-state screenshots (same data in light and dark) before final visual decisions?

---

### Readiness for Stitch Exploration

**Yes — Expense screen is ready for Stitch exploration.**

Rationale: Core layout and interaction model are already stable; remaining issues are visual density, hierarchy polish, and tone consistency, which are ideal for concept-first refinement.
