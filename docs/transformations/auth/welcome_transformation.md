# Welcome Transformation

## 1. Purpose

This document is an implementation handoff for transforming the BudgetMeter Welcome screen into the approved UI/UX direction.

It is not production SwiftUI code.  
It defines layout intent, component usage, copy direction, token constraints, safety boundaries, and acceptance criteria for the Welcome screen only.

## 2. Welcome Product Role

- Welcome is the first emotional impression of BudgetMeter.
- It should communicate that BudgetMeter is simple, calm, and personal.
- It should introduce the money pace concept lightly.

It must not feel like:

- a banking app
- a payment app
- a wallet app
- a crypto app
- an enterprise finance tool

## 3. Current Problem Summary

Likely current Welcome issues:

- old screen feels too plain or generic
- too much empty space
- weak premium calm fintech feeling
- weak emotional connection
- product idea may not be clear enough
- visual hierarchy may be too basic

## 4. Target Design Direction

Welcome transformation should follow:

- premium calm fintech
- light mode first
- slate/off-white canvas
- medium glass hero/card treatment
- Coral Default accent
- simple, friendly, trustworthy mood
- clear CTA hierarchy
- no dense finance visuals
- no banking/payment/wallet visuals
- no dashboard preview

## 5. Layout Hierarchy

Use this hierarchy:

1. Brand/logo area
2. Short emotional hero message
3. Optional Pulsey reserved area
4. Supportive subtitle
5. Apple sign-in action if currently present
6. Email sign-in action if currently present
7. Create account action if currently present
8. Legal text/links if currently present

## 6. Components to Use

Map Welcome to shared components:

- `AppBackground`
- `BudgetHeader` or lightweight brand header
- `GlassCard` if useful
- `PrimaryCTAButton` for main app CTA
- `SecondaryCTAButton` for secondary action
- Pulsey reserved area only if needed
- `StatusBadge` should not be needed
- `BudgetBottomTabBar` must not be used

## 7. Copy Direction

Use short, human Turkish copy.

Preferred copy:

- `BudgetMeter`
- `Paranı anlamak artık daha kolay.`
- `Bugün paran nereye gidiyor, tek bakışta gör.`

Rules:

- Keep copy short.
- Avoid financial jargon.
- Avoid bank/payment language.
- Avoid fear or pressure.

## 8. CTA Rules

- Keep existing auth actions only.
- Apple sign-in should preserve native Apple sign-in treatment if already present.
- Email sign-in should remain clear and accessible.
- Create account should remain visible but secondary if currently present.
- Do not add new auth providers.
- Do not change auth logic.
- Do not change navigation logic.

## 9. Pulsey Rule

- Pulsey may be added later as an emotional support hero element.
- Do not implement Pulsey in this phase unless explicitly requested later.
- If space is reserved, it must not break layout without Pulsey.
- Do not replace Pulsey with abstract spheres, random mascots, or generic finance illustrations.

## 10. Token Rules

Apply approved token rules:

- **background colors**
  - light: `#F8FAFC`
  - dark: `#0F172A`
- **elevated surfaces**
  - light: `#FFFFFF`
  - dark: `#1E293B`
- **text colors**
  - primary: `#0F172A` / `#F8FAFC`
  - secondary: `#64748B` / `#94A3B8`
  - tertiary: `#94A3B8` / `#64748B`
- **Coral Default accent**
  - `#FF5A5F`
- **spacing**
  - screen horizontal: `16`
  - section gap: `20`
  - card padding: `16`
  - card gap: `12`
  - button height: `52`
- **radius**
  - card: `20`
  - button: `14`
  - modal: `24`
- **typography**
  - SF Pro/system for normal UI text
  - SF Pro Rounded only where financial numbers are shown
- **glass treatment**
  - medium glass only
  - subtle border + soft shadow
  - Reduce Transparency fallback to opaque elevated surface
- **light/dark mode parity**
  - both modes remain readable and visually consistent

## 11. Stitch Reference Rules

- Stitch can guide spacing, calm mood, glass card direction, and CTA hierarchy.
- Stitch should not be copied exactly.
- Stitch abstract red sphere should not be treated as final mascot/logo.
- Final UI must follow `DESIGN.md` and shared components.

## 12. Implementation Safety Rules

- no auth logic changes
- no navigation changes
- no persistence changes
- no subscription logic changes
- no Core Data schema changes
- no new auth providers
- no new onboarding flow
- no unrelated refactors
- no fake banking/payment/wallet UI
- preserve accessibility labels where possible

## 13. Acceptance Checklist

- [ ] Welcome feels simple, calm, and premium.
- [ ] Money pace concept is lightly introduced.
- [ ] Existing auth actions are preserved.
- [ ] Apple sign-in treatment is preserved if present.
- [ ] Email sign-in remains clear.
- [ ] Create account action remains available if present.
- [ ] Pulsey is not required in this phase.
- [ ] No banking/payment/crypto/wallet UI is introduced.
- [ ] Shared tokens and components are used.
- [ ] Light and dark mode remain readable.
- [ ] Existing auth/navigation logic is preserved.
- [ ] Accessibility remains intact.
