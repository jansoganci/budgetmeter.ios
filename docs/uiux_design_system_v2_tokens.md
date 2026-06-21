# UI/UX Design System v2 — Tokens & Implementation Rules

**Document type:** Technical design-system specification  
**Status:** v2 — product-owner approved tokens  
**Purpose:** Translate [v1 design direction](uiux_design_direction_v1_decisions.md) into implementable UI tokens and rules.

**Upstream source of truth:** `docs/uiux_design_direction_v1_decisions.md`  
**This document defines:** exact values, semantic tokens, and implementation boundaries.

---

## Document Scope & Warnings

| Rule | Detail |
|------|--------|
| **Documentation only** | This task creates specs only. No Swift, Xcode, or UI implementation. |
| **Preserve app logic** | Future implementation must not change Core Data, auth, subscriptions, networking, or calculation engine behavior. |
| **Accent vs foundation** | Theme colors affect the accent layer only. Surfaces, text hierarchy, layout, and spacing stay stable. |
| **No neon / no candy / no enterprise dust** | Premium themes use fresh, vibrant, Google/Material-inspired accents — not muted corporate palettes or childish candy colors. |

---

## 1. Visual Direction Summary

BudgetMeter is a **light/dark glass fintech** app. It should feel **premium, calm, friendly, modern, and human** — not childish, casino-like, overly technical, or visually noisy.

| Pillar | v2 Decision |
|--------|-------------|
| **Canvas** | Slate-based fintech background in light and dark mode |
| **Surfaces** | Medium-strength glass UI on stable backgrounds |
| **Accents** | Fresh Google/Material-inspired colors (accent layer only) |
| **Default brand** | Coral red (`#FF5A5F`) — free for all users |
| **Premium** | Theme selection is premium-only (all themes except Coral Default) |
| **Financial numbers** | SF Pro **Rounded** |
| **UI text** | SF Pro (system default) |
| **Widgets** | Apple-like, calm, neutral backgrounds |
| **Mascot** | Pulsey 01 — emotional support, not primary UI |
| **Copy** | Short, human, supportive |
| **Accessibility** | WCAG AA target, Dynamic Type, multi-signal status |

---

## 2. Background Colors (Canvas Tokens)

The app canvas is **slate-based** in both modes. Backgrounds are **never theme-dependent**.

| Token | Light mode | Dark mode | Usage |
|-------|------------|-----------|-------|
| `background.main` | `#F8FAFC` | `#0F172A` | App root, scroll backgrounds, widget base |

### Rationale

**Light mode (`#F8FAFC`)** — Soft slate off-white. Feels clean, airy, and daytime-friendly. Provides enough contrast for glass cards without harsh pure white glare.

**Dark mode (`#0F172A`)** — Premium slate/navy (Tailwind slate-900 family). Feels depth-rich and fintech-polished — **not pure black**. Supports glass layering and readable text without OLED “void” harshness.

Both modes must:

- Support medium glass card surfaces on top
- Maintain stable text contrast (see §15 Accessibility)
- Stay unchanged when user switches premium theme

### Widget alignment

Widget backgrounds use the same neutral canvas values:

| Token | Light | Dark |
|-------|-------|------|
| `widget.background` | `#F8FAFC` | `#0F172A` |

Widgets never override this with status-driven full green/red fills.

---

## 3. Glass Surface System

**Strength:** Medium — premium depth without obscuring content.

### Dark mode glass card

| Property | Value |
|----------|-------|
| Fill | `rgba(30, 41, 59, 0.70)` |
| Semantic name | `surface.glass.dark` |

RGB `(30, 41, 59)` aligns with slate-800 — consistent with the dark canvas family.

### Light mode glass card

| Property | Value |
|----------|-------|
| Fill | `rgba(255, 255, 255, 0.72)` |
| Semantic name | `surface.glass.light` |

Symmetric ~70% opacity principle with dark mode. Implementation may add a subtle border (`rgba(15, 23, 42, 0.08)` light / `rgba(248, 250, 252, 0.12)` dark) and soft shadow — exact blur radius is an implementation detail, constrained by rules below.

### Glass rules

| Rule | Requirement |
|------|-------------|
| **Not too heavy** | Blur and opacity must not frosted-out text |
| **Not too transparent** | Cards must read as distinct surfaces |
| **Financial numbers** | Always rendered at full opacity on glass or on opaque inset wells |
| **No extreme effects** | No heavy refraction, neon glow on glass, or contrast-breaking overlays |
| **Reduce Transparency** | When iOS “Reduce Transparency” is on, fall back to opaque slate surfaces (see §15) |

### Opaque fallback surfaces (accessibility / Reduce Transparency)

| Token | Light | Dark |
|-------|-------|------|
| `surface.card.opaque` | `#FFFFFF` | `#1E293B` |

Use when glass materials are disabled or contrast fails QA.

---

## 4. Text Color Tokens (Readable Hierarchy)

Text colors are **not theme-dependent**. They pair with the slate canvas for WCAG AA targets.

| Token | Light mode | Dark mode | Usage |
|-------|------------|-----------|-------|
| `text.primary` | `#0F172A` | `#F8FAFC` | Headings, primary labels, hero numbers (on appropriate contrast) |
| `text.secondary` | `#64748B` | `#94A3B8` | Captions, supporting labels |
| `text.tertiary` | `#94A3B8` | `#64748B` | Hints, disabled-adjacent copy |

Financial **status** colors (positive / negative / neutral) are separate semantic tokens — see §7 Widget and status section below. They are not premium theme accents.

---

## 5. Theme Accent Palette

Fresh, vibrant, Google/Material-inspired accents. **Not** muted, dusty, or enterprise-washed.

| Theme ID | Display name | Accent hex | Tier |
|----------|--------------|------------|------|
| `coral_default` | Coral Default | `#FF5A5F` | **Free (default)** |
| `google_blue` | Google Blue | `#4285F4` | Premium |
| `fresh_green` | Fresh Green | `#00C853` | Premium |
| `mint_green` | Mint Green | `#00BFA5` | Premium |
| `google_yellow` | Google Yellow | `#FBBC04` | Premium |
| `google_red` | Google Red | `#EA4335` | Premium |
| `purple` | Purple | `#A142F4` | Premium |
| `sky_cyan` | Sky Cyan | `#24C6DC` | Premium |
| `orange` | Orange | `#FF8A00` | Premium |

**Coral Default vs Google Red:** Coral Default and Google Red are intentionally separate. Coral Default (`#FF5A5F`) is BudgetMeter’s free default brand theme. Google Red (`#EA4335`) is a premium high-energy red accent alternative inspired by modern Material-style color systems. They should not be treated as duplicates.

### Palette rules

| Do | Don’t |
|----|-------|
| Use as CTA, chart primary, progress, glow, selected state, mascot tint, widget accent | Use as full-screen or card background fill |
| Keep colors fresh, vibrant, modern, fintech-friendly | Use neon, candy, or dull enterprise tones |
| Pair with icons/text for meaning | Rely on accent color alone for financial status |

**Fresh Green usage:** Fresh Green (`#00C853`) is intentionally vibrant, but it must be used carefully in large text areas. For calmer premium positive states, Mint Green (`#00BFA5`) may be preferred. Fresh Green is best for accents, small status indicators, progress, selected states, and short positive values.

**Coral Default** is BudgetMeter’s own energetic fintech red — trustworthy and premium, not a bank clone.

Each premium theme maps one accent hex to all accent-layer slots unless a component requires a derived tint (implementation may lighten/darken ±10% for hover/pressed states while preserving hue).

---

## 6. Theme System — Scope Matrix

### Theme changes **may** affect

| Slot | Token example |
|------|---------------|
| Primary CTA fill / label accent | `theme.accent.primary` |
| Chart primary series | `theme.accent.chartPrimary` |
| Progress ring / bar fill | `theme.accent.progress` |
| Glow / highlight | `theme.accent.glow` |
| Mascot tint overlay | `theme.accent.mascotTint` |
| Selected tab / chip / row state | `theme.accent.selected` |
| Widget value accent (optional tint) | `theme.accent.widget` |

### Theme changes **must not** affect

| Locked system | Reason |
|---------------|--------|
| `background.main` | Canvas stability |
| `text.primary` / `text.secondary` | Readability |
| Glass / opaque card surface logic | Surface hierarchy |
| Layout structure | Screen consistency |
| Spacing tokens (§9) | Rhythm parity |
| Navigation structure | iOS-native wayfinding |

### Implementation note

Store selected theme ID in app settings. Resolve accent hex at runtime into semantic slots. Widget extension reads the same theme ID for accent-only styling.

---

## 7. Currency Formatting

**The app must never hardcode `$`.** All financial values use the **user-selected currency** with correct locale formatting.

| User currency | Symbol / format example |
|---------------|-------------------------|
| USD | `$1,234.56` |
| EUR | `€1.234,56` or locale-appropriate |
| GBP | `£1,234.56` |
| TRY | `₺1.234,56` |
| Other | ISO 4217 code + `NumberFormatter` / `FormatStyle.Currency` for locale |

### Rules

- Apply in **app UI**, **widgets**, **exports**, and **recaps**
- Respect user locale for grouping separators and decimal separators
- Negative values: use locale-aware minus or parentheses — never invent custom formats
- Zero and empty states: show formatted zero or em dash per screen spec — still no hardcoded `$`
- Widget main value (daily net pace / daily gain–loss) uses the same currency pipeline as Home

### Token / API guidance (future implementation)

```
CurrencyDisplay.format(amount: Decimal, currencyCode: String, locale: Locale) -> String
```

Single shared formatter — Views and Widgets must not duplicate symbol logic.

---

## 8. Widget Design System

Widgets are **calm, Apple-like, simple, and premium**. They inform at a glance without shouting.

### Background

| Mode | Background token | Rule |
|------|------------------|------|
| Light | `#F8FAFC` | Neutral slate off-white |
| Dark | `#0F172A` | Neutral slate navy |

**Optional elevated widget surface:**

| Token | Light | Dark |
|-------|-------|------|
| `widget.background.elevated` | `#FFFFFF` | `#1E293B` |

- The **default** widget background follows the app canvas (`#F8FAFC` / `#0F172A`).
- The **elevated** widget surface may be used if the widget needs stronger separation from the iOS Home Screen wallpaper.
- Widget backgrounds must **still remain neutral**.
- Full green/red widget backgrounds **remain forbidden**.

**Never** use full green or red widget backgrounds for positive/negative status.

### Primary content

| Element | Spec |
|---------|------|
| **Main value** | Daily net pace / daily gain–loss |
| **Currency** | User-selected format (§7) |
| **Typography** | SF Pro Rounded, 28–32pt range (see §9 Typography) |
| **Padding** | 16pt (`spacing.widget.padding`) |
| **Corner radius** | 22pt (`radius.widget`) |

### Status expression

Status affects **text and small indicators only** — not background fill.

| Status | Text color | Indicator |
|--------|------------|-----------|
| **Positive** | `#00C853` (Fresh Green) | Small up arrow / chevron (optional) |
| **Negative** | `#FF5A5F` (Coral Default) or `#EA4335` (Google Red) | Small down arrow / chevron (optional) |
| **Neutral** | `#64748B` (light) / `#94A3B8` (dark) | None or dash |

**Status positive usage:** Fresh Green (`#00C853`) is the default positive accent for short values, small indicators, progress, and selected states. If Fresh Green feels too intense on large financial values, Mint Green (`#00BFA5`) may be used instead for a calmer premium positive state.

Always pair color with **sign (+/−)** or **arrow icon** — color alone is insufficient (§15).

### Theme on widget

- Background and text hierarchy: **fixed**
- Optional accent on value or thin progress arc: **theme accent** (`theme.accent.widget`)
- Premium themes do not unlock different widget layouts in v2 — accent tint only

### Tone

One hero number, minimal secondary label (e.g. “Today’s pace”). No charts, no Pulsey on the live widget surface (locked teaser artwork is a future premium marketing optional).

---

## 9. Typography

### Font families

| Role | Font | Usage |
|------|------|-------|
| **Financial numbers** | SF Pro **Rounded** | Hero pace, card metrics, widget value, chart axis labels for amounts |
| **All other UI** | SF Pro (system) | Titles, body, buttons, captions, settings |

Do not use Rounded for paragraph body text. Do not use custom third-party fonts.

### Type scale

| Token | Size (pt) | Weight | Font | Usage |
|-------|-----------|--------|------|-------|
| `type.heroFinancial` | 36–40 | Semibold / Bold | SF Pro Rounded | Home pace, primary dashboard number |
| `type.heroFinancialMax` | 44 (max) | Bold | SF Pro Rounded | Single exceptional hero only — avoid overuse |
| `type.widgetNumber` | 28–32 | Semibold | SF Pro Rounded | Widget main value |
| `type.screenTitle` | 28–34 | Bold | SF Pro | Large navigation titles |
| `type.sectionTitle` | 18–22 | Semibold | SF Pro | Section headers |
| `type.cardTitle` | 16–18 | Semibold | SF Pro | Card headers |
| `type.body` | 15–17 | Regular | SF Pro | Body copy |
| `type.caption` | 12–13 | Regular | SF Pro | Labels, hints |
| `type.button` | 16–17 | Semibold | SF Pro | Button labels |

### Typography rules

- **Dynamic Type:** All text styles must scale with user content size settings
- **No clipping:** Avoid fixed-height containers that truncate scaled text; prefer `minimumScaleFactor` only as last resort on hero numbers
- **Financial numbers:** Friendly, clear, premium — Rounded conveys approachability without sacrificing legibility
- **UI text:** Native iOS feel — default SF Pro tracking and line heights

---

## 10. Spacing System

Baseline spacing rhythm (pt):

| Token | Value | Usage |
|-------|-------|-------|
| `spacing.screen.horizontal` | **16** | Default horizontal screen padding |
| `spacing.screen.horizontal.dashboard` | **20** | Optional for Home / dashboard-only screens |
| `spacing.section.gap` | **20** | Vertical gap between major sections |
| `spacing.card.padding` | **16** | Card internal padding |
| `spacing.card.gap` | **12** | Gap between elements inside a card |
| `spacing.row.height` | **48** | Standard list / settings row touch target |
| `spacing.button.height` | **52** | Primary button height |
| `spacing.modal.padding` | **24** | Sheet and modal inner padding |
| `spacing.widget.padding` | **16** | Widget content inset |

**Default remains 16pt** horizontal padding. Dashboard screens may opt into 20pt where density benefits hero layout.

---

## 11. Radius System

| Token | Value (pt) | Usage |
|-------|------------|-------|
| `radius.card` | **20** | Glass cards, dashboard cards |
| `radius.button` | **14** | Buttons, chips, compact actions |
| `radius.modal` | **24** | Sheets, modals, paywall panels |
| `radius.widget` | **22** | iOS widget container — native, friendly |

Radii keep the app **friendly and modern** while remaining fintech-appropriate. Widget radius aligns with iOS widget conventions (continuous corner feel).

---

## 12. Pulsey Mascot

### Identity

| Property | Value |
|----------|-------|
| **Character** | Pulsey 01 |
| **Role** | Emotional support layer, friendly financial companion |
| **Not** | Primary UI, data visualization, or transaction workflow |

Pulsey must **never compete with financial data** or sit on top of hero numbers.

### Pulsey **appears in**

| Context | Notes |
|---------|-------|
| Splash / launch animation | 3 seconds, Lottie preferred |
| Welcome screen | Brand introduction |
| Onboarding | Skippable flow, guide role |
| Paywall | Premium education |
| Premium theme preview | Themed accent pairing |
| Empty states | Encouragement |
| Small win / success states | Light celebration |
| Weekly / progress recap | Momentum storytelling |
| Important error modals | Reassurance — not minor toasts |

**Paywall placement:** Pulsey must appear on the paywall, preferably in the header or hero area. Pulsey should support the premium explanation, not decorate every feature row. Do not place Pulsey next to every premium feature item.

### Pulsey **does NOT appear in**

| Context | Reason |
|---------|--------|
| Transaction lists | Data density |
| Income / expense input forms | Speed and focus |
| Charts | Data clarity |
| Main Settings screen | Utility tone |
| Every card | Visual noise |
| On top of primary financial numbers | Hierarchy violation |
| Every screen | Selective presence only |

### Placement sizing (implementation guidance)

| Context | Suggested footprint |
|---------|---------------------|
| Splash | Center stage, max 120–160pt logical height |
| Empty / success / error | 80–100pt, beside or above copy |
| Onboarding | 100–120pt, below title |
| Paywall | 80pt, decorative corner or header |

Exact asset dimensions finalized when Lottie/static assets land.

---

## 13. Pulsey Animation

| Rule | Value |
|------|-------|
| **Preferred format** | Lottie (`.json`) |
| **Splash duration** | **3 seconds** |
| **Motion tone** | Calm, warm, premium |
| **Avoid** | Excessive bouncing, squash-stretch comedy, childish loops |
| **Static fallback** | Use static Pulsey illustration where animation adds no value (e.g. simple empty state) |

### App launch flow

1. App opens.
2. Show 3-second Pulsey splash animation.
3. If the user is new, show Welcome / Onboarding.
4. If the user is returning, continue to Home.

**Clarifications:**

- Splash and Welcome are **separate moments**.
- Splash is a short brand animation.
- Welcome / Onboarding is only for first-time or not-yet-onboarded users.

Splash must not block app launch beyond the agreed duration; transition to main UI should feel seamless.

---

## 14. Pulsey & UX Copy — Approved Examples

Use as **directional copy** — localize for all supported app languages in implementation.

### Welcome

> **Welcome to BudgetMeter.**  
> Let's make your money easier to understand.

### Onboarding — Screen 1

> **See your money pace.**  
> Know if you're moving forward or slowing down.

### Onboarding — Screen 2

> **Track without stress.**  
> Simple numbers, no finance jargon.

### Onboarding — Screen 3

> **Stay in control.**  
> Small steps can change your month.

### Onboarding rules

Onboarding must be shown only to new or not-yet-onboarded users. It must always be skippable. Skipping onboarding must take the user forward without blocking core app usage.

### Paywall

> **Make BudgetMeter feel yours.**  
> Unlock themes, widgets, and deeper insights.

### Empty state

> **Nothing here yet.**  
> Add your first item when you're ready.

### Important error

> **Something went wrong.**  
> Your data is safe. Let's try again.

### Small win

> **Nice progress.**  
> You're moving in the right direction.

### Weekly recap

> **Here's your week.**  
> Small changes are starting to show.

---

## 15. Copy Tone Rules

| Principle | Guidance |
|-----------|----------|
| **Never technical** | No stack traces, error codes, or API language in user copy |
| **Human-friendly** | Write like a calm friend, not an accountant |
| **Warm & supportive** | Acknowledge effort; avoid blame |
| **Short** | Headline + one supporting line max in modals |
| **Non-shaming** | Bad financial days are normal |
| **No jargon** | Avoid “cash outflow,” “threshold breached,” etc. |

### Bad examples (do not ship)

- “You overspent badly.”
- “Critical financial failure.”
- “Budget threshold breached.”
- “Cash outflow recorded.”

### Good examples

- “You're close to your limit.”
- “Let's slow things down.”
- “Expense tracked.”
- “You're still in control.”

---

## 16. Accessibility Requirements

All v2 UI implementation must meet these **required** standards:

| Requirement | Implementation |
|-------------|----------------|
| **WCAG AA contrast** | Text and interactive elements ≥ 4.5:1 (normal text); large text ≥ 3:1 |
| **Dynamic Type** | All styles scale; layouts adapt at accessibility sizes |
| **Color + icon + text** | Financial status never conveyed by color alone |
| **Reduce Transparency** | Fall back to `surface.card.opaque` when enabled |
| **VoiceOver** | Labels on charts, hero values, widget main number, and CTAs |
| **Layout adaptation** | At large content sizes, prefer `VStack` over cramped `HStack`; allow wrapping |

### Financial status multi-signal pattern

```
[icon] [signed value] [short label]
  ↑         ↑              ↑
arrow    +₺120          "Today's pace"
color    formatted       VoiceOver reads full phrase
```

### QA checkpoints

- Test light/dark × all 9 theme accents for CTA contrast
- Test widget at largest accessibility size
- Test with Reduce Transparency and Bold Text enabled

---

## 17. Semantic Token Reference (Quick Lookup)

### Surfaces

| Token | Light | Dark |
|-------|-------|------|
| `background.main` | `#F8FAFC` | `#0F172A` |
| `surface.glass.*` | `rgba(255,255,255,0.72)` | `rgba(30,41,59,0.70)` |
| `surface.card.opaque` | `#FFFFFF` | `#1E293B` |

### Status (non-theme)

| Token | Hex | Usage |
|-------|-----|-------|
| `status.positive` | `#00C853` | Gain, under budget, up pace |
| `status.negative` | `#FF5A5F` | Loss, over pace (coral) |
| `status.neutral` | slate gray | Flat / no change |

### Theme accent

Resolved from §5 palette via `theme.accent.*` slots (§6).

---

## 18. Implementation Readiness

### Recommended implementation order

1. **Color and theme tokens** — Canvas, text, accent palette, theme resolver
2. **Typography tokens** — SF Pro Rounded financial styles + Dynamic Type
3. **Spacing and radius tokens** — LayoutTokens alignment
4. **Glass surface components** — Card modifiers with Reduce Transparency fallback
5. **Theme preset system** — Premium gating + persistence + preview
6. **Widget redesign** — Neutral background, currency, status indicators
7. **Pulsey asset integration** — Lottie splash, static states
8. **Screen polish** — Apply tokens across features per v1 consistency rules
9. **Accessibility QA** — Contrast, VoiceOver, Dynamic Type pass

### Out of scope for design-token work

When implementing visuals, **do not modify**:

- Core Data schema or migrations
- Auth / Supabase logic
- Subscription / entitlement logic
- Networking and sync
- `CalculationEngine` or financial math
- Business rules in ViewModels (except display formatting calls)

Display formatting may **call** shared currency/theme helpers — it must not **change** calculated values.

---

## 19. v1 → v2 Traceability

| v1 decision (direction) | v2 token (this doc) |
|-------------------------|---------------------|
| Light/dark peers | §2 `#F8FAFC` / `#0F172A` |
| Medium glass | §3 opacity 0.70–0.72 |
| Google-like accents | §5 nine-color palette |
| Coral default brand | `#FF5A5F` free tier |
| Premium themes accent-only | §6 scope matrix |
| SF Pro Rounded numbers | §9 typography |
| Calm widgets | §8 neutral background rules |
| Pulsey emotional layer | §12–13 placement rules |
| 3s splash Lottie | §13 animation |
| Skippable onboarding | §14 copy slots |
| No hex in v1 | **Resolved in this document** |

---

## 20. Final Summary — Approved v2 Decisions

1. **Canvas:** Light `#F8FAFC`, dark `#0F172A` — slate fintech, not pure black.
2. **Glass:** Medium strength; dark card `rgba(30,41,59,0.70)`; readable numbers always.
3. **Themes:** 9 fresh vibrant accents; Coral Default free; all others premium; accent layer only.
4. **Currency:** Never hardcode `$`; user currency everywhere including widgets.
5. **Widgets:** Neutral background; daily net pace hero; status via text/small icon; 22pt radius; 16pt padding.
6. **Type:** SF Pro Rounded for money; SF Pro for UI; documented pt scale with Dynamic Type.
7. **Space & radius:** 16pt default horizontal padding; card 20pt; button 14pt; modal 24pt; button height 52pt.
8. **Pulsey 01:** Emotional support in splash, welcome, onboarding, paywall, empty/success/recap, important errors — nowhere else.
9. **Motion:** Lottie preferred; 3s calm splash; static where animation unnecessary.
10. **Copy:** Approved examples in §14; warm, short, non-technical, non-shaming.
11. **Accessibility:** WCAG AA, Dynamic Type, multi-signal status, Reduce Transparency fallback, VoiceOver.
12. **Implementation:** Token order in §18; preserve all business logic.

---

## Related Documents

| Document | Relationship |
|----------|--------------|
| [uiux_design_direction_v1_decisions.md](uiux_design_direction_v1_decisions.md) | Directional source of truth (do not overwrite) |
| [archive/uiux_core_screen_alignment_plan.md](archive/uiux_core_screen_alignment_plan.md) | Screen alignment implementation plan |
| [brand_gamification_decisions.md](brand_gamification_decisions.md) | Legacy brand notes; defer to v1/v2 where conflicts exist |
| [general_rulebook.mdx](general_rulebook.mdx) | Engineering conventions |

---

*Last updated: v2 token specification — documentation only, no implementation.*
