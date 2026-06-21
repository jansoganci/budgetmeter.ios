# UI/UX Design Direction v1 — Decisions

**Document type:** High-level design decision record  
**Status:** v1 — direction only, not implementation  
**Purpose:** Capture BudgetMeter’s current UI/UX design direction before defining detailed v2 design-system tokens.

This document records *what* the app should feel like and *where* design choices apply. It does **not** specify exact colors, sizes, blur values, or component specs. Those belong in the next v2 technical design-system document.

---

## 1. Executive Summary

BudgetMeter is moving toward a **light/dark glass-fintech** visual identity that feels **premium but friendly**.

In simple terms:

- **Light and dark mode** are both first-class. Users should feel at home in either mode.
- **Glass surfaces** give cards a modern, iOS-native depth without sacrificing clarity.
- **Colorful accents** (Google-like vibrancy) add energy and personality on top of calm backgrounds — not as full-screen color floods.
- **Minimal copy** keeps financial UX human and low-stress.
- **Pulsey** (character 01 from the mascot board) is the **emotional support layer** — present at meaningful moments, never competing with the numbers.

The product should still feel like a serious finance tool: trustworthy, readable, and fast. The new direction adds warmth, polish, and delight without turning BudgetMeter into a toy or a casino.

---

## 2. Theme Modes

BudgetMeter supports **both dark mode and light mode**.

| Mode | Background feel | Goal |
|------|-----------------|------|
| **Dark** | Dark anthracite / graphite | Premium, calm, OLED-friendly depth |
| **Light** | Soft off-white / light gray | Clean, airy, daytime readability |

**Readability rules (both modes):**

- Primary financial numbers must stay high contrast.
- Body text and labels must remain legible without strain.
- Surfaces (background, cards, sheets) should feel stable — not shifting wildly between screens.
- Mode switching should not break layout or hierarchy.

Dark and light are **peers**, not “dark as default, light as afterthought.” Implementation details for surface tokens come in v2.

---

## 3. Color Philosophy

BudgetMeter uses **Google-like vibrant colors as accents**, not as full-screen backgrounds.

### Accent layer only

Theme and brand color affect the **accent layer**:

- CTA (call-to-action) colors
- Progress rings and bars
- Chart series and highlights
- Mascot accent tints
- Glow and highlight treatments
- Widget value / accent color

### Stable foundation

The **background and readability system** stays consistent:

- App background, card surfaces, text hierarchy, and borders should **not** become theme-dependent chaos.
- A user switching premium themes should see accent colors change — not an entirely different app layout or unreadable contrast.
- Financial meaning (positive / negative / neutral) must not rely on color alone; pair with copy, icons, and typography.

**Principle:** Color adds personality on top of a calm, readable base — it does not replace the base.

---

## 4. Default Theme

The **default theme** is BudgetMeter’s own **red / coral fintech** color.

Guidelines:

- Do **not** copy any bank or competitor brand color exactly.
- The red should feel **trustworthy**, **premium**, and **energetic** — not alarming or cheap.
- Default theme applies to accent layer items (CTAs, progress, charts, glow, mascot accents) while surfaces and typography follow the shared light/dark system.

Exact red/coral values and semantic token names are deferred to v2.

---

## 5. Premium Theme System

**Theme selection is a premium feature.**

When a user selects a premium theme, it changes **accent-layer** properties:

- Accent color
- Mascot color treatment
- Chart color palette
- Progress ring / bar color
- Glow and highlight colors

**Themes must not:**

- Break readability
- Change core surface colors in ways that harm contrast
- Redesign screen layout or component structure per theme

**Theme presets** (names, full palette sets, preview UI) will be defined in v2. v1 only establishes that themes are accent-only and premium-gated.

---

## 6. Glass Design Language

Cards and elevated surfaces should move toward a **modern iOS-style glass / liquid-glass** feeling.

| Attribute | Direction |
|-----------|-----------|
| **Strength** | Medium — visible depth, not heavy frosted obstruction |
| **Readability** | Non-negotiable; glass must not hurt legibility |
| **Financial numbers** | Clear, high contrast, never buried under blur |
| **Treatment** | Subtle blur, border, shadow, and glow |

Glass is a **surface treatment**, not a replacement for semantic structure. Text hierarchy, spacing, and card content rules stay the same across screens. Exact blur radii, opacity, and material types are v2 decisions.

---

## 7. Widget Design Direction

The home-screen widget should feel **calm**, **Apple-like**, and **premium**.

### Background

- Widget background must **not** become fully green or red based on financial status.
- **Light mode:** soft white / light gray background.
- **Dark mode:** graphite / dark anthracite background.

### Status expression

Positive, negative, and neutral status should mainly affect:

- Text color, or
- Small accent elements (e.g., a thin indicator, subtle value tint)

—not the entire widget fill.

### Content focus

- **Main widget value:** daily net pace / daily gain–loss.
- Keep layout **simple**. One clear number, minimal secondary copy.
- A **Google Stitch** concept may be created later for widget visual exploration; v1 does not lock final layout.

Widgets share the app’s calm fintech tone: informative at a glance, never shouting.

---

## 8. Pulsey Mascot

**Pulsey** (character 01 from the provided mascot board) is the main BudgetMeter mascot.

### Role

Pulsey is the **emotional support layer**, not the main UI. Financial data remains the hero; Pulsey adds warmth at the right moments.

### Where Pulsey should appear

| Context | Use |
|---------|-----|
| Welcome screen | Brand introduction |
| Launch / splash | ~3 second animation |
| Onboarding | Guided first-run experience |
| Important error modals | Supportive, non-technical reassurance |
| Empty states | Encouragement when there is no data yet |
| Success / small win states | Light celebration |
| Paywall | Friendly premium education |
| Premium theme preview | Themed accent pairing |
| Weekly / progress recap | Momentum storytelling |
| Possible locked widget teaser | Optional future premium hint |

### Where Pulsey should not dominate

- Not on every screen
- Not inside or on top of primary financial pace numbers
- Not during fast transaction entry flows
- Not as a distraction from charts, tables, or settings

Pulsey should feel **calm, positive, and trustworthy** — cute but not childish. Asset format, sizes, and animation specs are v2.

---

## 9. Animation Direction

| Decision | Direction |
|----------|-----------|
| **Splash duration** | 3 seconds |
| **Preferred format** | Lottie (unless implementation proves otherwise) |
| **Tone** | Lightweight, calm, premium |
| **Avoid** | Excessive, bouncy, or childish motion |

Animations support the brand — they do not slow core tasks (logging income/expense, checking pace). Motion specs and asset pipeline details belong in v2.

---

## 10. Onboarding Direction

- Onboarding is shown to **new users**.
- Onboarding must be **skippable** at all times.
- **Pulsey** appears in onboarding as the friendly guide.
- **Detailed onboarding screens** (step count, copy, inputs) are decided later; v1 only commits to presence, skippability, and mascot use.

---

## 11. Error / Empty / Success States

### Errors

- Error modals: **simple**, **iOS-like**, **calm**.
- Pulsey appears only for **important** errors — not every minor validation or toast.
- Copy: **short**, **supportive**, **non-technical**.

### Empty states

- May use Pulsey more freely.
- Explain what is missing and what the user can do next — without jargon.

### Success states

- May use Pulsey for small wins and milestones.
- Keep celebration proportional; avoid casino-like effects.

All three state types share the same glass/surface language as the rest of the app.

---

## 12. Copy / UX Tone

BudgetMeter copy should never feel technical or blame-oriented.

| Do | Don’t |
|----|-------|
| Human-friendly, warm, supportive | Finance jargon and accounting speak |
| Short messages | Long explanations in modals |
| Make data feel simple | Overwhelm with metrics |
| Respect user control | Blame or shame for bad days |

**Example tone (not final copy):**

- “You’re moving forward.”
- “Small steps count.”
- “You’re still in control.”
- “Let’s slow the drain.”
- “Nice progress today.”

Copy guidelines apply app-wide: home, widgets, onboarding, paywall, errors, and recaps.

---

## 13. Screen Consistency

All screens must follow the **same** design direction defined in this document.

### Current visual baseline

- **Home, Income, and Expenses** are the established reference for layout, cards, typography, and spacing.
- **Welcome, Auth, Sign In, Insights, and Settings** have been aligned closer to that baseline (see `docs/uiux_core_screen_alignment_plan.md` for implementation planning).

### Shared system (future components must use)

- Background (light/dark surfaces)
- Glass cards
- Typography scale
- Buttons
- Modals and sheets
- Empty, loading, and error states
- Premium / paywall presentation

New features and refactors should extend this system — not introduce one-off styling.

---

## 14. What v1 Does NOT Decide

v1 is intentionally high-level. The following are **explicitly out of scope** for this document:

- Exact hex colors
- Exact font sizes
- Exact component sizes (heights, padding tokens, corner radii)
- Exact glass blur values and material definitions
- Exact premium theme preset names
- Exact chart palette per theme
- Exact widget final layout
- Exact onboarding screen list and flow
- Exact Pulsey asset dimensions, Lottie files, or animation keyframes

Implementers should not infer precise values from this document. Wait for v2 tokens or design specs.

---

## 15. Next Step: v2 Technical Design System Decisions

The **next document** should translate these v1 decisions into implementable design-system rules:

| Area | v2 should define |
|------|------------------|
| **Color** | Semantic color tokens; light/dark surface pairs |
| **Themes** | Premium theme presets and accent mappings |
| **Typography** | Type scale, weights, and financial number styles |
| **Layout** | Component sizes, spacing scale, corner radii |
| **Glass** | Blur strength, border, shadow, glow values |
| **Widget** | Background, text, and accent colors; layout grid |
| **Pulsey** | Allowed sizes, placements, and context rules |
| **Onboarding** | Screen structure, skip behavior, copy slots |
| **Modals** | Standard alert/sheet/error patterns |

Suggested follow-up doc name: `docs/uiux_design_system_v2_tokens.md` (or equivalent).

Until v2 exists, engineering and design should treat this v1 document as the **directional source of truth** for UI/UX intent — not as a spec sheet.

---

## Related Documents

| Document | Relationship |
|----------|--------------|
| `docs/uiux_core_screen_alignment_plan.md` | Screen-level alignment to Home/Income/Expenses baseline |
| `docs/brand_gamification_decisions.md` | Earlier brand/mascot decisions; v1 supersedes where direction evolved |
| `docs/design_rulebook.mdx` | Legacy detailed specs; reconcile with v2 tokens |
| `docs/roadmap.v2.mdx` | Product roadmap context |

---

*Last updated: v1 decision record — documentation only, no implementation.*
