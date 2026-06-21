  # BudgetMeter iOS - DESIGN.md

  Version: v2.0  
  Date: 2026-06-21  
  Audience: Google Stitch, AI UI generation, product design handoff, SwiftUI implementation planning

  ## 1. Purpose of This File

  This file is the source of truth for Google Stitch and AI-generated UI concepts for BudgetMeter iOS.

  If Stitch output conflicts with this file, this file wins.

  Stitch concepts are inspiration only. Production implementation must use the existing SwiftUI `DesignSystem` tokens and components. Stitch must not invent production code, business logic, data models, navigation behavior, or new token systems.

  Use this file to generate focused visual concepts that are practical for a SwiftUI iOS app and consistent with BudgetMeter's approved v2 design direction.

  ## 2. Product Definition

  BudgetMeter is a personal finance "money pace" app.

  It helps users understand whether their money is moving forward or slowing down. The product is centered on daily financial pace, income, expenses, savings, and calm financial awareness.

  BudgetMeter is for quick understanding, not financial overwhelm. The core question the app answers is:

  > Am I okay today, and is my money moving forward or slowing down?

  BudgetMeter is NOT:

  - a payment app
  - a bank app
  - a crypto app
  - a stock trading app
  - a dense accounting app
  - a subscription/payment tracker only
  - a generic dashboard-heavy finance app

  ## 3. User Pain Point

  People often avoid finance apps because they feel complicated, shameful, technical, or stressful. Many finance products make users feel like they need to understand accounting before they can understand their own money.

  BudgetMeter should avoid that failure mode. Users do not want dense accounting dashboards. They want a fast emotional and practical answer:

  - "Am I okay today?"
  - "Is my money moving forward or slowing down?"
  - "What changed?"
  - "What small step helps me stay in control?"

  BudgetMeter should reduce anxiety, not increase it.

  ## 4. Product Promise

  Core promise:

  > BudgetMeter makes your money pace easy to understand.

  The app should help users:

  - understand daily money direction
  - notice small wins
  - avoid panic
  - stay in control
  - track income and expenses without stress
  - see progress in simple language

  ## 5. Visual Identity

  BudgetMeter should feel like premium calm fintech:

  - light/dark glass UI
  - friendly and human
  - modern and native to iOS
  - polished but not sterile
  - warm but not childish
  - useful before decorative

  BudgetMeter must NOT feel:

  - childish
  - casino-like
  - generic banking
  - overly serious corporate finance
  - neon
  - noisy
  - dashboard-heavy
  - technical or developer-oriented

  ## 6. Core Design Principles

  - Pace-first clarity: daily money direction is the hero.
  - Fewer words, clearer numbers: short copy and strong hierarchy.
  - Data before decoration: financial information always beats visual flourish.
  - Calm before excitement: even negative states should feel manageable.
  - Glass is subtle, not distracting.
  - Color is accent, not background chaos.
  - Pulsey supports emotion but never replaces financial clarity.
  - Every screen must be understandable in 3 seconds.
  - Financial status must use multiple signals: text, sign, icon, and color where useful.
  - Light and dark mode are equal-quality experiences.

  ## 7. Non-Negotiable Color Tokens

  ### Canvas

  | Token | Value |
  |---|---|
  | `background.main.light` | `#F8FAFC` |
  | `background.main.dark` | `#0F172A` |

  Rules:

  - Do not use pure black as the app background.
  - Backgrounds never change by theme.
  - Backgrounds must stay calm enough for glass surfaces and high-contrast numbers.

  ### Text

  | Token | Value |
  |---|---|
  | `text.primary.light` | `#0F172A` |
  | `text.primary.dark` | `#F8FAFC` |
  | `text.secondary.light` | `#64748B` |
  | `text.secondary.dark` | `#94A3B8` |
  | `text.tertiary.light` | `#94A3B8` |
  | `text.tertiary.dark` | `#64748B` |

  Rules:

  - Text hierarchy never changes by theme.
  - Primary financial numbers must remain high contrast.
  - Supporting labels must be readable, never washed out.

  ### Fallback / Elevated Surfaces

  | Token | Value |
  |---|---|
  | `surface.elevated.light` | `#FFFFFF` |
  | `surface.elevated.dark` | `#1E293B` |

  Use these for opaque cards, Reduce Transparency fallback, and elevated widget surfaces.

  ### Status

  | Token | Value | Use |
  |---|---|---|
  | `status.positive` | `#00C853` | Moving forward, gain, under budget, positive pace |
  | `status.positive.calm` | `#00BFA5` | Calmer positive state for larger values |
  | `status.negative` | `#FF5A5F` | Slowing down, loss, over pace |
  | `status.negative.alt` | `#EA4335` | Premium/high-energy red accent alternative |
  | `status.neutral` | slate/gray system token | Flat, no change, insufficient data |

  Status color alone is never enough. Pair status with signs, short text, and icons where appropriate.

  ### Theme Accent Palette

  | Theme ID | Accent |
  |---|---|
  | `coral_default` | `#FF5A5F` |
  | `google_blue` | `#4285F4` |
  | `fresh_green` | `#00C853` |
  | `mint_green` | `#00BFA5` |
  | `google_yellow` | `#FBBC04` |
  | `google_red` | `#EA4335` |
  | `purple` | `#A142F4` |
  | `sky_cyan` | `#24C6DC` |
  | `orange` | `#FF8A00` |

  Clarifications:

  - Coral Default is the free/default brand theme.
  - Google Red is a separate premium high-energy red theme.
  - Theme colors are accent-only.
  - Background and text hierarchy never change by theme.
  - Do not invent new colors for Stitch concepts unless explicitly requested.

  ## 8. Theme Rules

  Theme may affect:

  - CTA color
  - selected state
  - progress fill
  - chart primary series
  - mascot tint
  - glow/accent highlights
  - optional widget accent

  Theme must not affect:

  - app background
  - text hierarchy
  - layout structure
  - spacing
  - radius
  - core card readability
  - navigation structure

  Themes should feel like personality applied to a stable system, not separate apps.

  ## 9. Glass / Card System

  BudgetMeter uses medium-strength glass. Glass should create premium iOS depth without making the interface hard to read.

  Rules:

  - Readability first.
  - Use subtle border.
  - Use soft shadow.
  - No extreme blur.
  - No over-glowing cards.
  - No neon refraction.
  - No busy backgrounds behind financial numbers.
  - Financial numbers must render at full opacity.
  - Reduce Transparency fallback is required.

  Card values:

  | Token | Value |
  |---|---|
  | `radius.card` | `20` |
  | `spacing.card.padding` | `16` |
  | `spacing.card.gap` | `12` |
  | `surface.elevated.light` | `#FFFFFF` |
  | `surface.elevated.dark` | `#1E293B` |

  Glass intent:

  - Light glass: white around 72% opacity over `#F8FAFC`.
  - Dark glass: slate around 70% opacity over `#0F172A`.
  - Border should be very subtle.
  - Shadow should lift the surface but not create heavy depth.

  ## 10. Typography System

  ### Font Families

  | Role | Font |
  |---|---|
  | Financial numbers | SF Pro Rounded |
  | Normal UI | SF Pro / system default |

  ### Type Scale

  | Token | Size range |
  |---|---|
  | `heroFinancial` | `36-40` |
  | `heroFinancialMax` | `44` |
  | `widgetNumber` | `28-32` |
  | `screenTitle` | `28-34` |
  | `sectionTitle` | `18-22` |
  | `cardTitle` | `16-18` |
  | `body` | `15-17` |
  | `caption` | `12-13` |
  | `button` | `16-17` |

  Rules:

  - Do not use Rounded for body paragraphs.
  - Financial numbers should use stable digit rhythm.
  - Financial numbers should feel friendly, clear, and premium.
  - Normal UI text should feel native to iOS.
  - Support Dynamic Type.
  - Avoid fixed-height containers that clip scaled text.

  ## 11. Spacing and Radius

  ### Spacing

  | Token | Value |
  |---|---:|
  | `spacing.screen.horizontal` | `16` |
  | `spacing.screen.horizontal.dashboard` | `20` |
  | `spacing.section.gap` | `20` |
  | `spacing.card.padding` | `16` |
  | `spacing.card.gap` | `12` |
  | `spacing.row.height` | `48` |
  | `spacing.button.height` | `52` |
  | `spacing.modal.padding` | `24` |
  | `spacing.widget.padding` | `16` |

  ### Radius

  | Token | Value |
  |---|---:|
  | `radius.card` | `20` |
  | `radius.button` | `14` |
  | `radius.modal` | `24` |
  | `radius.widget` | `22` |

  Rules:

  - Default screen padding is 16pt.
  - Dashboard screens may use 20pt horizontal padding.
  - Do not create dense accounting layouts.
  - Touch targets must remain comfortable.

  ## 12. Currency Rules

  - Never hardcode `$`.
  - Always use the user-selected currency.
  - Currency applies to app UI, widgets, summaries, charts, recaps, and exports.
  - Stitch must not create mockups with hardcoded USD unless explicitly requested.
  - Keep currency examples generic or use multiple currencies when showing financial mockups.

  Examples:

  | Currency | Symbol |
  |---|---|
  | TRY | `₺` |
  | USD | `$` |
  | EUR | `€` |
  | GBP | `£` |

  Formatting should respect locale-aware grouping, decimal separators, signs, and negative values.

  ## 13. Pulsey Mascot Rules

  Pulsey is BudgetMeter's emotional support layer.

  Pulsey helps the app feel warm, supportive, and memorable, but Pulsey is not the main UI. Financial data remains the hero.

  Pulsey appears in:

  - splash
  - welcome
  - onboarding
  - empty states
  - success/small win states
  - paywall hero/header

  Pulsey must not appear in:

  - dense transaction lists
  - charts
  - widget live surface
  - primary financial metric area
  - every card
  - settings main list

  Rules:

  - Pulsey should be tasteful, warm, and premium.
  - No childish mascot overload.
  - No random abstract glowing sphere replacing Pulsey.
  - If Pulsey is used, it should support emotional clarity.
  - Pulsey must never sit on top of or compete with primary financial numbers.
  - Static Pulsey fallback is acceptable; Lottie can come later.

  Suggested footprint:

  - Splash: 120-160pt logical height.
  - Empty/success/error: 80-100pt.
  - Onboarding: 100-120pt.
  - Paywall: about 80pt in hero/header.

  ## 14. Widget Rules

  BudgetMeter widgets are standard iOS Home Screen widgets. Design for small and medium first.

  Widget principles:

  - Neutral background only.
  - No full green/red backgrounds.
  - One hero number.
  - Minimal supporting label.
  - User-selected currency.
  - Status via text, icon, or small indicator.
  - Calm, Apple-like, glanceable.
  - No charts unless explicitly requested for a future concept.
  - No Pulsey on the live widget surface.

  Widget backgrounds:

  | Token | Value |
  |---|---|
  | `widget.background.light` | `#F8FAFC` |
  | `widget.background.dark` | `#0F172A` |
  | `widget.background.elevated.light` | `#FFFFFF` |
  | `widget.background.elevated.dark` | `#1E293B` |

  Widget content:

  - Main value: daily net pace / daily gain-loss.
  - Typography: SF Pro Rounded, 28-32pt.
  - Padding: 16pt.
  - Radius: 22pt.
  - Status must use text/icon/sign plus color where useful.

  ## 15. Screen Intent

  ### Welcome

  - Build trust.
  - Explain money pace simply.
  - Introduce warmth and Pulsey.
  - Auth actions remain clear.

  ### Home

  - Answer: "Am I moving forward or slowing down today?"
  - Daily pace is primary.
  - Recent activity and categories are secondary.
  - No dense dashboard.

  ### Income

  - Fast income entry.
  - Low cognitive load.
  - Clear recurring and one-time income grouping.
  - No mascot distraction.

  ### Expense

  - Fast expense entry.
  - Supportive, not shameful.
  - Clear recurring, subscription, and one-time expense grouping.
  - Avoid panic language.

  ### Insights

  - Simple trends.
  - No chart chaos.
  - Charts should explain, not overwhelm.

  ### Settings

  - Clean control center.
  - Utility tone.
  - No Pulsey on the main settings list.

  ### Sign In / Register

  - Confidence.
  - Clarity.
  - Low friction.
  - Security should feel calm, not alarming.

  ### Paywall

  - Clear premium value story.
  - No pressure.
  - Pulsey may appear in hero/header.
  - Explain themes, widgets, and deeper insights plainly.

  ### Widget

  - Glanceable daily pace.
  - One hero value.
  - Calm status signal.

  ## 16. Copy Tone

  Rules:

  - human
  - short
  - warm
  - non-shaming
  - non-technical
  - avoid accounting jargon
  - no stack traces or API language
  - no blame

  Good examples:

  - "Paranı anlamak artık daha kolay."
  - "Bugün paran yavaşlıyor."
  - "İyi gidiyorsun."
  - "Küçük adımlar fark yaratır."
  - "Kontrol hâlâ sende."
  - "You're moving forward."
  - "Small steps count."
  - "You're still in control."

  Bad examples:

  - "Cash outflow recorded."
  - "Budget threshold breached."
  - "Critical financial failure."
  - "You overspent badly."
  - "Financial threshold violation."

  ## 17. Stitch Generation Rules

  When using Google Stitch or another AI UI generation tool:

  - Work screen-by-screen.
  - Do not redesign the whole app at once.
  - Do not create unrelated screens.
  - Do not create payment, banking, crypto, stock trading, or accounting UI.
  - Do not invent new colors.
  - Do not invent new typography.
  - Do not create tab bars or navigation structures unless requested.
  - Keep existing information architecture unless asked otherwise.
  - Produce 1 focused concept by default.
  - Produce 2-3 variants only when asked.
  - Do not generate production code.
  - Keep designs SwiftUI-feasible.
  - Use attached screenshots as current-state references, not final design.
  - Keep financial numbers dominant and readable.
  - Do not replace BudgetMeter's pace-first model with a generic finance dashboard.
  - Do not make every surface colorful.
  - Do not use decorative gradients as the main identity.

  ## 18. Additional Stitch Instructions

  - Prioritize dark mode references if screenshots/design files include both modes.
  - Attached brand/logo images are examples of visual identity.
  - Attached screenshots show current implementation state.
  - Improve screenshots using this `DESIGN.md`; do not copy them exactly.
  - If requested to redesign a screen, stay within that screen.
  - If the request is unclear, ask before generating unrelated app screens.
  - If Pulsey assets are not attached, leave a tasteful Pulsey placeholder area only when the screen allows Pulsey.
  - If currency is shown, avoid hardcoded USD unless the prompt specifically requests USD.
  - If showing positive/negative money status, include sign/text/icon support, not color alone.

  ## 19. Implementation Handoff Rules

  Stitch output is inspiration. Cursor or SwiftUI implementation must use the existing SwiftUI `DesignSystem` tokens and components.

  Implementation rules:

  - Use existing tokens before creating new ones.
  - No new tokens unless approved.
  - No business logic changes from Stitch concepts.
  - No Core Data changes from visual redesign.
  - No auth changes from visual redesign.
  - No StoreKit/subscription entitlement changes from visual redesign.
  - No networking/sync changes from visual redesign.
  - No calculation engine changes from visual redesign.
  - Preserve user-selected currency behavior.
  - Preserve premium gating behavior.
  - Preserve existing navigation unless an implementation task explicitly changes it.

  ## 20. Current Implementation State

  Current audit reference: `docs/uiux_v2_completion_audit.md`.

  The current implementation is high-completion but not debt-free. The audit reports approximately 88.5% UI/UX v2 completion.

  Strongly implemented areas:

  - v2 color and theme foundation
  - typography foundation
  - glass surface primitive
  - currency display contract
  - neutral widget baseline
  - paywall alignment
  - Pulsey fallback foundation
  - onboarding foundation

  Remaining debt:

  - some token naming consistency
  - some screen polish consistency
  - some accessibility coverage consistency
  - some legacy-styled feature surfaces

  Design generation should reduce consistency debt, not create more.

  ## Appendix - Related Documents

  - `docs/uiux_design_direction_v1_decisions.md`
  - `docs/uiux_design_system_v2_tokens.md`
  - `docs/uiux_v2_implementation_plan.md`
  - `docs/uiux_v2_completion_audit.md`
