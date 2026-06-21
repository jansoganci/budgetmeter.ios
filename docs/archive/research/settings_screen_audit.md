# Settings Screen UI/UX Audit (Current State)

Sources reviewed:
- `docs/uiux_design_direction_v1_decisions.md`
- `docs/uiux_design_system_v2_tokens.md`
- `docs/uiux_v2_implementation_plan.md`
- `budgetmeter.ios/Features/SettingsFeature/View/SettingsView.swift`
- `budgetmeter.ios/Features/SettingsFeature/ViewModel/SettingsViewModel.swift`
- Related settings views in `budgetmeter.ios/Features/SettingsFeature/View/`
- Screenshots:
  - `docs/uiux/screenshots/current/settings.light.png`
  - `docs/uiux/screenshots/current/settings.dark.png`

## 1. Current Screen Summary

Settings screen is section-based and currently has two role-dependent visual variants:

- **Light / non-premium state:** top premium upgrade banner + general/account/privacy sections.
- **Dark / premium state:** premium sections split into categories (Tracking & Goals, Customization, Security), then general/account sections.

Layout and navigation patterns are clear, card groups are readable, and row-level interaction is straightforward.

## 2. What Works

- Strong information architecture with grouped settings categories.
- Row components are consistent and reusable (`SettingsSection`, `SettingsRowContent`, `SettingsActionRow`).
- Premium gating behavior is clear via banner/section differences.
- Light/dark variants both appear stable and readable.
- Icon + title + subtitle row pattern supports quick scanning.
- Account/currency/language/appearance are easy to find.

## 3. Problems

- Visual parity between non-premium and premium experiences is uneven; they can feel like different screen designs.
- Premium banner (light mode) reads somewhat transactional, less “premium but friendly” in emotional tone.
- Dark mode section density is high; long stacked cards can feel heavy rather than calm premium.
- Some sections feel utilitarian/system-like instead of refined glass-fintech surfaces.
- Copy tone is clear but mostly functional; warmth/supportive tone is limited.
- Pulsey is absent in premium education surface (allowed in paywall/premium contexts), so brand warmth is low.
- Turkish/English mixed states (e.g., language subtitles) may look inconsistent depending on settings.
- Bottom of screen appears crowded in long lists when combined with tab bar and section spacing.

## 4. v2 Alignment Gap

Compared to v2 requirements, Settings is reasonably aligned structurally but still has polish gaps:

- **Light/dark slate canvas:** aligned in principle for both variants.
- **Glass surfaces:** token usage exists (`glassSurface`), but premium depth consistency can be improved.
- **Pulsey usage:** not mandatory in Settings list itself, but premium-related messaging could use warmer support.
- **Short human copy:** concise, but more supportive and premium-friendly language could be applied in banner/premium messaging.
- **Premium but friendly feeling:** functional and clear, yet emotionally neutral.
- **Screen consistency:** shared components are good, but premium vs non-premium visual divergence is high.
- **Accessibility / Dynamic Type:** row pattern is mostly robust; still requires large-text/clipping QA in dense grouped sections.

## 5. Design Opportunities

Potential directions (documentation only):

- Harmonize premium and non-premium visual language so both feel like same product tier system.
- Refine premium banner card hierarchy (title/value/CTA rhythm) for calmer premium intent.
- Slightly reduce vertical density in dark mode groups for better breathing room.
- Improve section title-to-card spacing rhythm for cleaner scan flow.
- Introduce warmer, humanized copy tone in premium education and support-related rows.
- Keep Settings list focused and utilitarian while allowing premium accents to feel intentional (not loud).
- Optionally run Stitch concepts for:
  1) premium banner redesign,
  2) section rhythm in dark mode,
  3) premium/non-premium parity.

## 6. Recommended Next Step

Recommended path: **Run a focused Stitch concept pass first, then execute scoped SwiftUI polish in Settings only.**

Reason:
- Core interaction model is already stable; remaining work is mostly visual hierarchy/tone refinement.
- Concept pass will help avoid over-editing many small rows without a clear target direction.

## 7. Questions / Decisions Needed

Before implementation, these should be decided:

1. Should premium and non-premium Settings share near-identical structure with only content differences?
2. Do we want a softer premium banner tone (less sales-first, more “make BudgetMeter feel yours”)?
3. Should Pulsey appear in premium banner/paywall entry context, or remain excluded from Settings?
4. Is Turkish-first wording required for all visible settings labels/subtitles in this pass?
5. Do we keep current dense grouping in dark mode, or move to slightly calmer spacing cadence?

---

### Readiness for Stitch Exploration

**Yes — Settings screen is ready for Stitch exploration.**

Rationale: Settings is functionally mature; the remaining gaps are visual parity, premium messaging tone, and spacing harmony, which are ideal for concept-first validation before implementation.
