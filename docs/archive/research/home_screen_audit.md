# Home Screen UI/UX Audit (Current State)

Sources reviewed:
- `docs/uiux_design_direction_v1_decisions.md`
- `docs/uiux_design_system_v2_tokens.md`
- `docs/uiux_v2_implementation_plan.md`
- `budgetmeter.ios/Features/HomeFeature/View/HomeView.swift`
- `budgetmeter.ios/Features/HomeFeature/ViewModel/HomeViewModel.swift`
- Screenshots:
  - `docs/uiux/screenshots/current/home.light.png`
  - `docs/uiux/screenshots/current/home.dark.png`

## 1. Current Screen Summary

Current Home has two noticeably different visual states:

- **Data state (dark screenshot):** Compact dashboard with greeting, large momentum hero, month summary cards, health/savings row, quick actions, and tab bar.
- **Empty state (light screenshot):** Large centered onboarding-style block with icon, title/subtitle, and two wide CTAs.

Hierarchy is generally clear in both states, but the two experiences feel like different products in mood and surface language.

## 2. What Works

- Core information architecture in data state is strong: pace-first hero followed by monthly summary and quick actions.
- Financial signal visibility is high (pace, income, expense, net, health, savings).
- CTA priority in empty state is understandable (`Add Your First Income` first).
- Existing token usage is already partly aligned (`Color.appBackground`, semantic text styles, spacing/radius tokens, glass-like cards).
- Accessibility intent is visible (labels/hints on actions, dynamic typography support in design system).
- Pulsey is present in Home (decorative indicator and empty state), which supports v2 emotional layer direction.

## 3. Problems

- **State inconsistency:** Empty state and populated dashboard do not feel visually unified (tone, spacing density, and card language differ).
- **Excessive vertical spacing in empty state:** Similar to Welcome, too much unused space weakens premium density.
- **Mixed personality:** Dark dashboard feels rich and energetic, while light empty state feels closer to generic setup screen.
- **Glass perception is uneven:** Some cards feel premium, others still look like flat rounded panels.
- **Copy tone drift:** Empty state subtitle includes awkward line break and dry wording (`Track your money flow in real-time...`), less warm than v2 copy tone goals.
- **Accent semantics in dark state can feel loud:** Positive/negative colors are readable, but some sections risk “busy” feel versus calm premium target.
- **Quick actions density:** Large button blocks in dark mode compete with dashboard cards for attention.
- **Dark and light parity not fully validated per state:** We only have dark for populated state and light for empty state, so full matrix is incomplete.

## 4. v2 Alignment Gap

Compared to v2 requirements, Home is partially aligned but still has gaps:

- **Light/dark slate canvas:** Present in principle, but visual parity should be validated in both states for both modes.
- **Medium glass system:** Used in parts, yet depth/border/shadow consistency is not fully uniform.
- **Pulsey usage:** Present (good), but placement style and scale consistency can be tuned for calmer premium expression.
- **Short human copy:** Some copy is functional rather than warm/supportive; microcopy needs tone alignment.
- **Premium but friendly feeling:** Data state is close; empty state still reads somewhat generic.
- **Screen consistency:** Home is baseline reference, but internal sub-states (empty vs populated) need tighter coherence.
- **Accessibility/Dynamic Type:** Foundations exist; still needs explicit QA for clipping and visual hierarchy at large sizes.

## 5. Design Opportunities

Potential directions (documentation only, no implementation):

- Harmonize empty state and populated state under one shared Home visual language.
- Refine empty state vertical rhythm to reduce dead space and improve premium density.
- Keep pace hero as core anchor, but reduce visual competition from lower cards/buttons.
- Calibrate glass surfaces for more consistent depth (especially in light mode).
- Tighten quick-actions hierarchy so they support, not dominate, core financial insight.
- Improve Turkish copy warmth and natural flow in empty state and pace-support text.
- Validate a calmer dark-mode pass to maintain readability without over-saturation.
- Optionally create Stitch concepts specifically for **Home empty state vs populated state coherence**.

## 6. Recommended Next Step

Recommended path: **Run Stitch exploration first for Home state-coherence**, then implement one selected direction.

Reason:
- Home has multiple sub-states and high component density.
- Visual decisions (hero weight, quick actions prominence, empty-state tone) benefit from rapid concept comparison before code changes.
- This reduces rework during phase-based implementation.

## 7. Questions / Decisions Needed

Before implementation, these should be decided:

1. Should Home empty state be visually close to Welcome, or clearly distinct but still same design language?
2. In Home dark populated state, should quick actions stay large cards or become more compact controls?
3. Pulsey in Home: keep always visible in hero, or only contextual (empty/success highlights)?
4. Should month summary cards remain equal prominence, or should net/pace card gain stronger priority?
5. Do we require full screenshot matrix before implementation (`home.light populated` + `home.dark empty`)?

---

### Readiness for Stitch Exploration

**Yes — Home screen is ready for Stitch exploration.**

Rationale: The main gaps are visual hierarchy balance, state consistency, and tone calibration (not core logic), which are ideal for concept-first refinement.
