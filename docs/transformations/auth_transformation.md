# Auth Transformation

## 1. Purpose

This document is an implementation handoff for transforming BudgetMeter auth screens into the approved UI/UX direction.

It is not production SwiftUI code.  
It defines transformation intent, shared component usage, safety boundaries, and acceptance criteria for:

- Welcome
- Sign In
- Register / Create Account

## 2. Auth Product Role

Auth screens are the first impression of BudgetMeter.

They must feel:

- calm
- trustworthy
- simple
- premium

They must not feel like:

- a bank app
- a payment app
- a wallet app
- a crypto app
- an enterprise finance tool

## 3. Shared Auth Rules

- Use `AppBackground` as the stable full-screen canvas.
- Use `BudgetHeader` where appropriate for title/subtitle and auth context.
- Use `GlassCard` for form and primary auth content containers.
- Use `PrimaryCTAButton` for main actions.
- Use `SecondaryCTAButton` for secondary actions.
- Keep existing authentication flow and providers exactly as implemented.
- Do not change auth logic.
- Do not change navigation logic.
- Do not create new user fields unless already present.
- Do not add payment, wallet, dashboard, banking, or transaction visuals.

## 4. Welcome Screen Transformation

### Current problem summary

- Clear actions exist, but the screen feels visually sparse and slightly detached between hero and CTA area.
- Premium glass-fintech expression is weaker than target direction.
- Emotional warmth is limited for a first-touch screen.

### Target design direction

- Trust-first welcome with calm premium tone.
- Strong but simple brand intro.
- Better vertical rhythm between hero and action group.
- Keep practical auth actions obvious and low-friction.

### Layout hierarchy

1. `BudgetHeader` zone (brand + short supportive subtitle)
2. Hero visual area (reserved for future Pulsey-ready composition)
3. Primary auth action group (Apple first, Email second)
4. Secondary account action (Create Account)

### Components to use

- `AppBackground`
- `BudgetHeader`
- `GlassCard`
- `PrimaryCTAButton` (Apple Sign In)
- `SecondaryCTAButton` (Email Sign In, Create Account style depending on hierarchy)

### Copy direction

Preferred copy:

- `BudgetMeter`
- `Paranı anlamak artık daha kolay.`
- `Bugün paran nereye gidiyor, tek bakışta gör.`

Tone rules:

- short
- warm
- non-technical
- confidence-building

### What must change

- Improve layout balance and reduce dead vertical space.
- Strengthen premium calm feel using token-aligned surface treatment.
- Clarify CTA grouping without changing auth behavior.
- Reserve clear space for future Pulsey placement.

### What must not change

- Do not implement Pulsey yet unless existing assets are available and specifically requested later.
- Keep current actions if present: Apple sign-in, email sign-in, create account.
- Do not modify provider logic, callbacks, or route logic.

### Acceptance checklist

- [ ] Welcome feels calm, premium, and readable.
- [ ] CTA order remains clear and familiar.
- [ ] Existing actions remain available.
- [ ] Hero and CTA spacing feels intentional.
- [ ] Pulsey is not required in this phase; future slot is documented.
- [ ] No auth logic or navigation behavior changed.

## 5. Sign In Screen Transformation

### Current problem summary

- Functional structure is solid, but screen feels visually generic and sparse.
- Limited premium identity continuity from Welcome.
- Form and action area can feel separated from a cohesive header narrative.

### Target design direction

- Focused, low-friction sign-in surface.
- Strong readability and clear field/action hierarchy.
- Calm premium styling with minimal decorative noise.

### Layout hierarchy

1. `BudgetHeader` (screen title + short helper line)
2. `GlassCard` form container (email/password)
3. Primary sign-in CTA
4. Secondary links (forgot password, create account/back) based on existing flow

### Components to use

- `AppBackground`
- `BudgetHeader`
- `GlassCard`
- `PrimaryCTAButton`
- `SecondaryCTAButton`

### Copy direction

Preferred copy:

- `Giriş yap`
- `Paranın temposunu takip etmeye devam et.`

Tone rules:

- reassuring
- short
- direct

### What must change

- Tighten vertical rhythm for a more complete, less empty layout.
- Improve visual confidence of primary action.
- Align sign-in container styling with shared token system.

### What must not change

- Keep existing email/password auth flow.
- Keep forgot password link if currently present.
- Keep create account/back link if currently present.
- Do not add social login options unless already present.
- Do not modify auth validation or network/auth backend behavior.

### Acceptance checklist

- [ ] Sign In is low-friction and clear.
- [ ] Existing sign-in fields and flow are unchanged.
- [ ] Existing helper links are preserved where present.
- [ ] Visual hierarchy is clear at a glance.
- [ ] No new providers or auth steps added.

## 6. Register Screen Transformation

### Current problem summary

- Register is structurally clear but visually plain and sparse.
- It needs stronger premium calm consistency with Sign In and Welcome.
- Layout can be denser without increasing cognitive load.

### Target design direction

- Friendly, confident account creation flow.
- Same structural system as Sign In, with register-specific content only.
- Readable form rhythm with clear primary action.

### Layout hierarchy

1. `BudgetHeader` (register title + short reassurance subtitle)
2. `GlassCard` form container (existing register fields only)
3. Primary register CTA
4. Secondary link to sign-in/back and legal text block (if currently present)

### Components to use

- `AppBackground`
- `BudgetHeader`
- `GlassCard`
- `PrimaryCTAButton`
- `SecondaryCTAButton`

### Copy direction

Preferred copy:

- `Hesap oluştur`
- `Paranı daha sakin takip etmeye başla.`

Tone rules:

- supportive
- simple
- non-judgmental

### What must change

- Align register visual language with shared auth pattern.
- Improve spacing rhythm and card cohesion.
- Keep legal and supportive text readable but secondary.

### What must not change

- Keep existing register fields only.
- Do not add extra onboarding steps here.
- Keep sign in/back link if currently present.
- Keep terms/privacy note if currently present.
- Do not modify registration business logic.

### Acceptance checklist

- [ ] Register matches Sign In structure and style quality.
- [ ] Existing fields are preserved (no additions).
- [ ] Existing legal/support links remain where present.
- [ ] Primary action is clear and accessible.
- [ ] No auth logic or flow changes introduced.

## 7. Visual Direction from Stitch

- Stitch outputs are direction references for spacing, calm mood, glass form-card direction, and button hierarchy.
- Stitch outputs must not be copied pixel-perfect.
- Final implementation must follow `DESIGN.md` and shared component standards.
- Pulsey will be added later by the app team and is not required in this auth transformation phase.

## 8. Component Mapping

### Welcome

- `AppBackground`: required
- `BudgetHeader`: required
- `GlassCard`: required (hero/content container)
- `PrimaryCTAButton`: required
- `SecondaryCTAButton`: required
- `StatusBadge`: not required by default
- `EmptyStateCard`: only if the screen includes a no-data/supportive variant

### Sign In

- `AppBackground`: required
- `BudgetHeader`: required
- `GlassCard`: required (form container)
- `PrimaryCTAButton`: required
- `SecondaryCTAButton`: required (forgot/back/create links as style mapping)
- `StatusBadge`: optional (only if explicit auth-status messaging is shown)
- `EmptyStateCard`: not required in normal sign-in flow

### Register

- `AppBackground`: required
- `BudgetHeader`: required
- `GlassCard`: required (form container)
- `PrimaryCTAButton`: required
- `SecondaryCTAButton`: required (sign-in/back link style mapping)
- `StatusBadge`: optional, only if needed for explicit validation/status UI
- `EmptyStateCard`: not required in normal register flow

## 9. Token Rules

Apply auth transformations using approved token rules:

- **Background colors**
  - light: `#F8FAFC`
  - dark: `#0F172A`
- **Elevated surfaces**
  - light: `#FFFFFF`
  - dark: `#1E293B`
- **Text colors**
  - primary: `#0F172A` / `#F8FAFC`
  - secondary: `#64748B` / `#94A3B8`
  - tertiary: `#94A3B8` / `#64748B`
- **Coral Default accent**
  - `#FF5A5F` as default brand accent
- **Card radius**
  - `20`
- **Button radius**
  - `14`
- **Spacing**
  - screen horizontal `16`
  - section gap `20`
  - card padding `16`
  - card gap `12`
  - button height `52`
- **Typography**
  - SF Pro for normal UI text
  - SF Pro Rounded only for financial numbers (generally limited in auth)
- **Glass treatment**
  - medium-strength glass only
  - subtle border + soft shadow
  - Reduce Transparency fallback to opaque elevated surface
- **Light/Dark parity**
  - both modes must receive equal polish and readability quality

## 10. Implementation Safety Rules

- no auth logic changes
- no navigation changes
- no persistence changes
- no subscription logic changes
- no Core Data changes
- no new auth providers
- no new fields unless already present
- no currency hardcoding
- no unrelated refactors
- no fake banking/payment/wallet UI
- preserve accessibility labels where possible

## 11. Final Acceptance Checklist

- [ ] Welcome, Sign In, and Register feel like the same app.
- [ ] Auth screens follow `DESIGN.md`.
- [ ] Shared components are used.
- [ ] Light and dark mode are supported.
- [ ] Existing auth flow is preserved.
- [ ] Existing navigation is preserved.
- [ ] Buttons are clear and accessible.
- [ ] Forms are readable and low-friction.
- [ ] No banking/payment/crypto/wallet UI is introduced.
- [ ] Pulsey is not required for this phase.
